#!/bin/sh

#########################################################################
#                                                                       #
# start DB SAMPLE                                                       #
#                                                                       #
# Written by: YJ                                                        #
# QnA to : https://github.com/good-dba/mariadb-dba-scripts              #
# Version: 0.1                                                          #
# Released: 2016-07-28                                                  #
#                                                                       #
# Tested on MariaDB 10.x                                                #
#                                                                       #
#########################################################################
#                                                                       #
# Usage: ./mysql_start.sh                                               #
#                                                                       #
#########################################################################

cd /engn001/mysvc01/mariadb-10.0.20
./bin/mysqld_safe --defaults-file=/engn001/mysvc01/SVCTEST01/my.cnf --user=USERNAME &
