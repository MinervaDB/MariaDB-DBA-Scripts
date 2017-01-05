#!/bin/bash

########################################################################
#                                                                      #
# Script for purge log files                                           #
#                                                                      #
# Written by: YJ                                                       #
# Version: 0.1                                                         #
# Released: 2017-01-03                                                 #
#                                                                      #
# Tested with MariaDB 10.0.28                                          #
#                                                                      #
# Usage: sh mariadb_log_purge.sh [OPTIONS]                             #
#                                                                      #
# The following options may be given as the first argument:            #
# --err    purge error log                                             #
# --slow   purge slow log                                              #
#                                                                      #
########################################################################

####################################
# Set Environments
####################################

DB_NAME='LGUERP_PROD'

RESERVE_DAYS=4 #DON'T  BE SET LESS THAN 1

ERROR_LOG_HOME="/logs001/masvc01/${DB_NAME}/error"
ERROR_LOG_NAME='mysqld.err'

SLOW_LOG_HOME="/logs001/masvc01/${DB_NAME}/slow"
SLOW_LOG_NAME='mysvc01-slow.log'




####################################
# execute purge job
####################################

case "${1}" in
"--err")
  LOG_HOME=${ERROR_LOG_HOME}
  LOG_NAME=${ERROR_LOG_NAME}
  ;;
"--slow")
  LOG_HOME=${SLOW_LOG_HOME}
  LOG_NAME=${SLOW_LOG_NAME}
  ;;
*)
  echo ""
  echo "Usage: sh mariadb_log_purge.sh [OPTIONS] "
  echo ""
  echo "The following options may be given as the first argument: "
  echo "--err    purge error log"
  echo "--slow   purge slow log"
  echo ""
  exit 0;;
esac

# check dir exists and is writable
if test ! -d $LOG_HOME -o ! -w $LOG_HOME
then
  echo $LOG_HOME ' does not exist or is not writable'
  exit 1
fi

cp ${LOG_HOME}/${LOG_NAME} "${LOG_HOME}/${LOG_NAME}.`date +%Y%m%d_%H`"
echo '' > ${LOG_HOME}/${LOG_NAME}

for OLD_NAME in $(find ${LOG_HOME} -maxdepth 1 -type f -mtime +${RESERVE_DAYS})
do
  echo "rm -rf ${OLD_NAME}"
  #rm -rf ${OLD_NAME}
done
