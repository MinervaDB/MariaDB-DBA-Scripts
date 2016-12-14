#!/bin/bash

########################################################################
#                                                                      #
# Scripts for DB Backup using XtraBackup                               #
#                                                                      #
# Written by: YJ                                                       #
# QnA to : https://github.com/good-dba/mariadb-dba-scripts             #
# Version: 0.1                                                         #
# Released: 2016-12-14                                                 #
#                                                                      #
# Tested with XtraBackup 2.4 on MariaDB 10.0.28                        #
#                                                                      #
# Usage: sh mariadb_backup.sh [OPTIONS]                                #
#                                                                      #
# The following options may be given as the first argument:            #
# --full      Full Backup                                              #
# --incre     Incremental Backup                                       #
# --binlog    Binary Log Backup                                        #
# --engine    Engine Backup                                            #
# --delete    Delete Old Backups                                       #
# --list      Show list of backups on disk                             #
#                                                                      #
########################################################################

####################################
# Set Environments
####################################

DB_NAME='LGUERP_TEST'
MY_CNF="/engn001/masvc01/${DB_NAME}/my.cnf"

RESERVE_DAYS=3 #DON'T  BE SET LESS THAN 1

OS_USER='masvc01'
DB_USER='backupuser'
DB_PWD='backupuser_pwd'
SOCKET="/engn001/masvc01/${DB_NAME}/mysqld.sock"

ENGINE_HOME='/engn001/masvc01/mariadb-10.0.28'
XTRABACKUP_HOME='/engn001/masvc01/percona-xtrabackup-2.4'

LOGBIN_HOME="/logs001/masvc01/${DB_NAME}/binary"

BACKUP_HOME="/bkup001/masvc01/${DB_NAME}"
LOG_HOME="/bkup001/masvc01/${DB_NAME}/backup_log"
LOG_FILE="${LOG_HOME}/backup.db.`date +%Y%m%d%H%M%S`.log"
LOG_HISTORY="${LOG_HOME}/backup_all_history.log"

MYSQL="${ENGINE_HOME}/bin/mysql --user=${DB_USER} --password=${DB_PWD} --socket=${SOCKET}"
MYSQLDUMP="${ENGINE_HOME}/bin/mysqldump --user=${DB_USER} --password=${DB_PWD} --socket=${SOCKET}"
MYSQLADMIN="${ENGINE_HOME}/bin/mysqladmin --user=${DB_USER} --password=${DB_PWD} --socket=${SOCKET}"
XTRABACKUP="${XTRABACKUP_HOME}/bin/xtrabackup --defaults-file=${MY_CNF} --user=${DB_USER} --password=${DB_PWD}"



####################################
# Function: Write Backup history
####################################
fn_write_history() {
  if [ ! -f ${LOG_HISTORY} ]
  then
    echo "DB_NAME,DB_USER,START_TIME,END_TIME,LAP_SECONDS,BACKUP_SIZE,BACKUP_TYPE,BACKUP_PATH,BACKUP_LOG" > ${LOG_HISTORY}
  fi
  echo ${1} &>> ${LOG_HISTORY}
}

####################################
# Function: Full Backup
####################################
fn_full_backup() {

  REC_START_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  START_TIME=`date +%s`

  # flush binary logs
  ${MYSQL} --skip-column-names --batch -e "FLUSH BINARY LOGS" 2>&1 | tee -a $LOG_FILE

  # full backup
  BACKUP_NAME=${DB_NAME}_full_`date +'%Y%m%d_%H%M'`
  ${XTRABACKUP} --backup --no-timestamp --no-lock --target-dir=${BACKUP_HOME}/${BACKUP_NAME} 2>&1 | tee -a $LOG_FILE

  # apply logs only
  ${XTRABACKUP} --prepare --apply-log-only --target-dir=${BACKUP_HOME}/${BACKUP_NAME}        2>&1 | tee -a $LOG_FILE

  REC_END_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  END_TIME=`date +%s`
  LAP_TIME=`expr $END_TIME - $START_TIME`

  BACKUPTYPE=`grep backup_type ${BACKUP_HOME}/${BACKUP_NAME}/xtrabackup_checkpoints | awk '{print $3}'`
  BACKUPSIZE=`du -sm ${BACKUP_HOME}/${BACKUP_NAME} | awk '{print $1}'`

  fn_write_history "${DB_NAME},${DB_USER},${REC_START_TIME},${REC_END_TIME},${LAP_TIME},${BACKUPSIZE},${BACKUPTYPE},${BACKUP_HOME}/${BACKUP_NAME},${LOG_FILE}"

}

####################################
# Function: Incremental Backup
####################################
fn_incremental_backup() {

  # Get Lastest Backup Directory (this is a basedir)
  LATEST_BACKUP=`find ${BACKUP_HOME} -name xtrabackup_info -type f -exec grep innodb_to_lsn {} + | sort -t "=" -k2 -n | tail -n1 | cut -d ":" -f 1`
  LATEST_BACKUP=`echo ${LATEST_BACKUP/"/xtrabackup_info"//}`

  REC_START_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  START_TIME=`date +%s`

  # flush binary logs
  ${MYSQL} --skip-column-names --batch -e "FLUSH BINARY LOGS" 2>&1 | tee -a $LOG_FILE

  # incremental backup
  BACKUP_NAME=${DB_NAME}_incre_`date +'%Y%m%d_%H%M'`
  ${XTRABACKUP} --backup --no-timestamp --no-lock --target-dir=${BACKUP_HOME}/${BACKUP_NAME} --incremental-basedir=${LATEST_BACKUP} 2>&1 | tee -a $LOG_FILE

  REC_END_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  END_TIME=`date +%s`
  LAP_TIME=`expr $END_TIME - $START_TIME`

  BACKUPTYPE=`grep backup_type ${BACKUP_HOME}/${BACKUP_NAME}/xtrabackup_checkpoints | awk '{print $3}'`
  BACKUPSIZE=`du -sm ${BACKUP_HOME}/${BACKUP_NAME} | awk '{print $1}'`

  fn_write_history "${DB_NAME},${DB_USER},${REC_START_TIME},${REC_END_TIME},${LAP_TIME},${BACKUPSIZE},${BACKUPTYPE},${BACKUP_HOME}/${BACKUP_NAME},${LOG_FILE}"

}

####################################
# Function: Binary Log Backup
####################################
fn_binlog_backup() {

  REC_START_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  START_TIME=`date +%s`

  BACKUP_NAME='binary_backup'
  if [ ! -d ${BACKUP_HOME}/${BACKUP_NAME} ]
  then
    mkdir ${BACKUP_HOME}/${BACKUP_NAME}                   | tee -a  $LOG_FILE
  fi

  rsync -av ${LOGBIN_HOME}/ ${BACKUP_HOME}/${BACKUP_NAME} | tee -a  $LOG_FILE
  
  REC_END_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  END_TIME=`date +%s`
  LAP_TIME=`expr $END_TIME - $START_TIME`

  BACKUPTYPE='binary'
  BACKUPSIZE=`du -sm ${BACKUP_HOME}/${BACKUP_NAME} | awk '{print $1}'`

  fn_write_history "${DB_NAME},${DB_USER},${REC_START_TIME},${REC_END_TIME},${LAP_TIME},${BACKUPSIZE},${BACKUPTYPE},${BACKUP_HOME}/${BACKUP_NAME},${LOG_FILE}"
}

####################################
# Function: Engine Backup
####################################
fn_engine_backup() {

  REC_START_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  START_TIME=`date +%s`

  BACKUP_NAME="engine_backup_`date +%Y%m%d%H%M`"
  mkdir ${BACKUP_HOME}/${BACKUP_NAME}                  | tee -a  $LOG_FILE
  cp -R $ENGINE_HOME ${BACKUP_HOME}/${BACKUP_NAME}     | tee -a  $LOG_FILE
  cp -R $XTRABACKUP_HOME ${BACKUP_HOME}/${BACKUP_NAME} | tee -a  $LOG_FILE

  REC_END_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  END_TIME=`date +%s`
  LAP_TIME=`expr $END_TIME - $START_TIME`

  BACKUPTYPE='engine'
  BACKUPSIZE=`du -sm ${BACKUP_HOME}/${BACKUP_NAME} | awk '{print $1}'`

  fn_write_history "${DB_NAME},${DB_USER},${REC_START_TIME},${REC_END_TIME},${LAP_TIME},${BACKUPSIZE},${BACKUPTYPE},${BACKUP_HOME}/${BACKUP_NAME},${LOG_FILE}"
}

####################################
# Function: Delete Backups
####################################
fn_delete_backups() {

  REC_START_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  START_TIME=`date +%s`

  for BACKUP_NAME in $(find ${BACKUP_HOME} -maxdepth 1 -type d -mtime +${RESERVE_DAYS})
  do
    echo "rm -rf ${BACKUP_NAME}" | tee -a $LOG_FILE
    rm -rf ${BACKUP_NAME}        | tee -a $LOG_FILE
  done

  for BACKUP_NAME in $(find ${BACKUP_HOME}//binary_backup -type f -mtime +${RESERVE_DAYS})
  do
    echo "rm -rf ${BACKUP_NAME}" | tee -a $LOG_FILE
    rm -rf ${BACKUP_NAME}        | tee -a $LOG_FILE
  done

  REC_END_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  END_TIME=`date +%s`
  LAP_TIME=`expr $END_TIME - $START_TIME`

  BACKUPTYPE='delete'
  BACKUPSIZE=0

  fn_write_history "${DB_NAME},${DB_USER},${REC_START_TIME},${REC_END_TIME},${LAP_TIME},${BACKUPSIZE},${BACKUPTYPE},${BACKUP_HOME}/${BACKUP_NAME},${LOG_FILE}"
}

####################################
# Function: show list of backups on disk
####################################
fn_list_backups() {

  for BACKUP_NAME in $(find ${BACKUP_HOME} -name xtrabackup_info -type f -exec grep innodb_to_lsn {} + | sort -t "=" -k2 -n | cut -d ":" -f 1)
  do
    echo "####################"
    echo '# Path: '${BACKUP_NAME/"/xtrabackup_info"//}
    echo "####################"
    grep "backup_type =" ${BACKUP_NAME/"/xtrabackup_info"//}xtrabackup_checkpoints
    grep -E 'start_time =|end_time =|partial =|incremental =|binlog_pos =' ${BACKUP_NAME}
  done

  if [ -d ${BACKUP_HOME}/binary_backup ]
  then
    echo "####################"
    echo "# Path: ${BACKUP_HOME}/binary_backup (Backuped Binlog)"
    echo "####################"
    ls ${BACKUP_HOME}/binary_backup
  fi
  #LATEST_BACKUP=`echo ${LATEST_BACKUP/"/xtrabackup_info"//}`

}



####################################
# Pre-check before backup
####################################

# check OPTIONS
case "${1}" in
"--full") ;;
"--incre") ;;
"--binlog") ;;
"--engine") ;;
"--delete") ;;
"--list") ;;
*)
  echo ""
  echo "Usage: sh mariadb_backup.sh [OPTIONS] "
  echo ""
  echo "The following options may be given as the first argument: "
  echo "--full      Full Backup "
  echo "--incre     Incremental Backup "
  echo "--binlog    Binary Log Backup "
  echo "--engine    Engine Backup "
  echo "--delete    Delete Old Backups "
  echo "--list      Show list of backups on disk"
  echo ""
  exit 0;;
esac

#echo "==============================================" 2>&1 | tee -a $LOG_FILE
#echo "== ${DB_NAME} Backup"                           2>&1 | tee -a $LOG_FILE
#echo "== Started : `date +'%Y/%m/%d %H:%M:%S'`"       2>&1 | tee -a $LOG_FILE
#echo "== Log     : ${LOG_FILE}"                       2>&1 | tee -a $LOG_FILE
#echo "==============================================" 2>&1 | tee -a $LOG_FILE

# check base dir exists and is writable
if test ! -d $BACKUP_HOME -o ! -w $BACKUP_HOME
then
  echo $BACKUP_HOME ' does not exist or is not writable' 2>&1 | tee -a $LOG_FILE
  exit 1
fi

# check if mysql service up
if [ -z "`${MYSQLADMIN} status | grep 'Uptime'`" ]
then
  echo "Failed : MySQL does not appear to be running." 2>&1 | tee -a $LOGFILE
  exit 1
fi

# check if pasword correct
if ! `echo 'exit' | ${MYSQL}`
then
  echo "Failed : mysql username or password is incorrect" 2>&1 | tee -a $LOGFILE
  exit 1
fi

# execute job
echo "==============================================" 2>&1 | tee -a $LOG_FILE
case "${1}" in
"--full")
  echo "== ${DB_NAME} Full Backup"                      2>&1 | tee -a $LOG_FILE
  echo "== Started : `date +'%Y/%m/%d %H:%M:%S'`"       2>&1 | tee -a $LOG_FILE
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  fn_full_backup
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  echo "== End    : `date +'%Y/%m/%d %H:%M:%S'`"        2>&1 | tee -a $LOG_FILE
  echo "== Backup : $BACKUP_HOME/$BACKUP_NAME"          2>&1 | tee -a $LOG_FILE
  ;;
"--incre")
  echo "== ${DB_NAME} Incremental Backup"               2>&1 | tee -a $LOG_FILE
  echo "== Started : `date +'%Y/%m/%d %H:%M:%S'`"       2>&1 | tee -a $LOG_FILE
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  fn_incremental_backup
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  echo "== End    : `date +'%Y/%m/%d %H:%M:%S'`"        2>&1 | tee -a $LOG_FILE
  echo "== Backup : $BACKUP_HOME/$BACKUP_NAME"          2>&1 | tee -a $LOG_FILE
  ;;
"--binlog") 
  echo "== ${DB_NAME} Binlog Backup"                    2>&1 | tee -a $LOG_FILE
  echo "== Started : `date +'%Y/%m/%d %H:%M:%S'`"       2>&1 | tee -a $LOG_FILE
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  fn_binlog_backup
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  echo "== End    : `date +'%Y/%m/%d %H:%M:%S'`"        2>&1 | tee -a $LOG_FILE
  echo "== Backup : $BACKUP_HOME/$BACKUP_NAME"          2>&1 | tee -a $LOG_FILE
  ;;
"--engine") 
  echo "== ${DB_NAME} Engine Backup"                    2>&1 | tee -a $LOG_FILE
  echo "== Started : `date +'%Y/%m/%d %H:%M:%S'`"       2>&1 | tee -a $LOG_FILE
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  fn_engine_backup
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  echo "== End    : `date +'%Y/%m/%d %H:%M:%S'`"        2>&1 | tee -a $LOG_FILE
  echo "== Backup : $BACKUP_HOME/$BACKUP_NAME"          2>&1 | tee -a $LOG_FILE
  ;;
"--delete") 
  echo "== ${DB_NAME} Delete Backups"                   2>&1 | tee -a $LOG_FILE
  echo "== Started : `date +'%Y/%m/%d %H:%M:%S'`"       2>&1 | tee -a $LOG_FILE
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  fn_delete_backups
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  echo "== End    : `date +'%Y/%m/%d %H:%M:%S'`"        2>&1 | tee -a $LOG_FILE
  ;;
"--list")
  echo "== ${DB_NAME} Show List of backups on disk"     2>&1 | tee -a $LOG_FILE
  echo "== Started : `date +'%Y/%m/%d %H:%M:%S'`"       2>&1 | tee -a $LOG_FILE
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  fn_list_backups
  echo "==============================================" 2>&1 | tee -a $LOG_FILE
  echo "== End    : `date +'%Y/%m/%d %H:%M:%S'`"        2>&1 | tee -a $LOG_FILE
  ;;
esac

echo "== Log    : $LOG_FILE"
echo "== All backup history : ${LOG_HISTORY}"
echo "==============================================" 2>&1 | tee -a $LOG_FILE
