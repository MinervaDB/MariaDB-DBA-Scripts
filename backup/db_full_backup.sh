#!/bin/bash

# Load Profile
. /engn101/script/db_backup_profile


LAST_BACKUP=""
LAST_LOGBIN=""

set_recent_backup_info() {

	# find recent backup name
	bkinfo=`find ${BACKUP_DIR} -name xtrabackup_checkpoints -print | sort | tail -n1`
	LAST_BACKUP=${bkinfo%/xtrabackup_checkpoints}

	# find binary log name in recent backup
	if [ "${LAST_BACKUP}" != "" ]; then
		LAST_LOGBIN=$(cat ${LAST_BACKUP}/xtrabackup_binlog_info | awk '{print $1}')
	fi

}

additional_binary_backup() {

	if [ "${LAST_BACKUP}" == "" ] || [ "${LAST_LOGBIN}" == "" ] ; then
		echo "there is not no backup before this backup."
	else

		# backup binary log between backup and current backup
		cat ${MARAIDB_LOGBIN}/mariadb-bin.index | while read binfile; do
		if [[ ${binfile} == *${LAST_LOGBIN}* ]]; then
			LAST_LOGBIN_point="Y"
			if [ ! -d ${LAST_BACKUP}/SERVICEDB_additional_binary_backup ]; then
				mkdir ${LAST_BACKUP}/SERVICEDB_additional_binary_backup
			fi
			echo "additional backup binary Log (between backup and current)"
			echo "           into ${LAST_BACKUP}/SERVICEDB_additional_binary_backup"
			echo "------------------------"
		fi
		if [[ ${LAST_LOGBIN_point} = "Y" ]]; then
			echo ${binfile}
			cp ${binfile} ${LAST_BACKUP}/SERVICEDB_additional_binary_backup
		fi
		done

	fi

}

full_backup() {

	JOB_TIMESTAMP=`date +'%Y-%m-%d_%H-%M-%S'`
	BACKUP_NAME=${JOB_TIMESTAMP}_full_backup
	echo "Backupdir=${BACKUP_DIR}/${BACKUP_NAME}"
	echo "Backuplog=${BACKUP_LOG_DIR}/${BACKUP_NAME}.log"

	# execute full backup
	innobackupex \
 	--defaults-file=${MY_CNF}\
 	--user=${BACKUP_USER}\
 	--password=${BACKUP_PWD}\
 	--no-timestamp \
 	--parallel=8 \
 	${BACKUP_DIR}/${BACKUP_NAME} \
 	&>> ${BACKUP_LOG_DIR}/${BACKUP_NAME}.log

	# show backup result
	cat ${BACKUP_DIR}/${BACKUP_NAME}/xtrabackup_checkpoints
	bklogbin=`cat ${BACKUP_DIR}/${BACKUP_NAME}/xtrabackup_binlog_info`
	echo "backup log_bin = ${bklogbin}"
	bkstatus=`tail -n1 ${BACKUP_LOG_DIR}/${BACKUP_NAME}.log`
	if [[ $bkstatus == *"innobackupex: completed OK"* ]]; then
		echo "Backup completed OK!"
	else
		echo "Do not know backup status!"
	fi
	du -sh ${BACKUP_DIR}/${BACKUP_NAME} | awk '{print "total : "$1}'
}

echo "=============================================="
echo "== SERVICEDB DB Full Backup"
echo "=============================================="
date +'Start: %Y/%m/%d %H:%M:%S'

# Recent backup meta is assigned to the variable.
set_recent_backup_info

# execute real full backup
full_backup

# this is backed up between recent backup binary log and current binary log.
#additional_binary_backup

date +'Stop: %Y/%m/%d %H:%M:%S'
