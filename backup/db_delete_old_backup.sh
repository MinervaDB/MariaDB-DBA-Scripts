# Load Profile
. /engn101/script/db_backup_profile

JOB_TIMESTAMP=`date +'%Y-%m-%d_%H-%M-%S'`

delete_old_backup() {

	echo "-- Finding directory that has modified before 22 days, and delete it"
	find ${BACKUP_DIR} -type d -mtime +22 -ls -exec rm -rf {} \;

	echo "-- delete backup directories before the most recent two full backup."
	bkcount=0
	find ${BACKUP_DIR} -name xtrabackup_checkpoints | sort -r | while read bkinfo; do
		bkpath=${bkinfo%/xtrabackup_checkpoints}
		bkname=${bkpath##/*/}

		if [[ ${bkpath} == *"_full_backup" ]] || [ ${bkcount} -ge ${BACKUP_KEEP_COUNT} ] ; then 
			bkcount=$((bkcount+1))
		fi
		if [ ${bkcount} -gt ${BACKUP_KEEP_COUNT} ] ; then
			echo "rm -rf ${bkpath}"
			rm -rf ${bkpath}
		fi
	done;

}

echo "=============================================="
echo "== Delete old backup "
echo "=============================================="
delete_old_backup
