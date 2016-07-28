#!/bin/sh

#########################################################################
#                                                                       #
# stop DB SAMPLE                                                        #
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
# Usage: ./mysql_stop.sh                                                #
#                                                                       #
#########################################################################

/engn001/mysvc01/mariadb-10.1.14/bin/mysqladmin -uroot -pPWD -S /engn001/mysvc01/SVCTEST01/mysqld.sock shutdown
