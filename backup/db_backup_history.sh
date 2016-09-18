#!/bin/bash

# Load Profile
. /engn101/script/db_backup_profile

JOB_TIMESTAMP=`date +'%Y-%m-%d_%H-%M-%S'`

backup_history() {
	echo "=============================================="
	echo "== innobackupex(xtrabackup) history "
	echo "=============================================="
	find ${BACKUP_DIR} -name xtrabackup_checkpoints -print | sort | while read bkinfo; do
                bkpath=${bkinfo%/xtrabackup_checkpoints}
                bkname=${bkpath##/*/}
                bklogbin=`cat ${bkpath}/xtrabackup_binlog_info`
		du -sh ${bkpath}
                echo "--------------------------"
		cat ${bkinfo}
		echo "backup log_bin = ${bklogbin}"
		cat ${bkpath}/xtrabackup_info | grep -E 'start_time|end_time'
		bkstatus=`tail -n1 ${BACKUP_LOG_DIR}/${bkname}.log`
		if [[ $bkstatus == *"innobackupex: completed OK"* ]]; then
			echo "Backup completed OK!"
		else
			echo "Do not know backup status!"
		fi
		echo "=============================================="
	done;
}

backup_history
