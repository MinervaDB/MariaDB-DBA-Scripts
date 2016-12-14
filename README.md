# mariadb-dba-scripts
The script files for the DBAs to support MySQL/MariaDB.

## mysql_start.sh, mysql_stop.sh

These are SAMPLE scripts for DB start and stop.

* Usage

```
$ ./mysql_start.sh

$ ./mysql_stop.sh
```

## mysql_get_config.sh

getting MySQL/MariaDB configuration

This script only get the environment information. When you create a new script to use environmental information, including this script.

* Usage

```
$ ./mysql_get_config.sh

Using basedir: /engn001/mysvc01/mariadb-10.1.14

Would you like to provide a different basedir?: [y/N] y
basedir: /engn001/mysvc01/mariadb-10.0.20

Could not auto detect login info!
Found potential sockets: /engn001/mysvc01/SVCTEST01/mysqld.sock
/engn001/mysvc01/SVCTEST02/mysqld.sock
/engn001/mysvc01/SVCTEST03/mysqld.sock
/engn001/mysvc01/SVCTEST04/mysqld.sock

Using: /engn001/mysvc01/SVCTEST01/mysqld.sock

Would you like to provide a different socket?: [y/N] y
Socket: /engn001/mysvc01/SVCTEST03/mysqld.sock

Please input username and password to connect to DB
User: root
Password: 
#####################################
#
# MySQL/MariaDB version: 10.1.14-MariaDB
# basedir: /engn001/mysvc01/mariadb-10.0.20
# socket: /engn001/mysvc01/SVCTEST03/mysqld.sock
#
#####################################
```
---------------------------------------

## mariadb_backup.sh

이 스크립트는 MariaDB 데이터베이스를 디스크로 백업하거나 디스크에 있는 백업을 확인하는데 이용할 수 있다.

This script can be used to back up the MariaDB database to disk or to check for backups on disk.

백업 이력은 ${LOG_HOME}/backup_all_history.log에 한 줄씩 추가되면서 기록된다. 이 파일은 csv로 받아서 사용할 수도 있다.

The backup history is recorded by adding one line to $ {LOG_HOME} /backup_all_history.log. This file can also be used with csv.

### Configuration

이 스크립트를 사용하려면 스크립트 안에 환경설정 정보를 등록해야 한다.

To use this script, you must register the configuration information in the script.

```
####################################
# Set Environments
####################################

DB_NAME='TESTDB'
MY_CNF="/engn001/masvc01/${DB_NAME}/my.cnf"

RESERVE_DAYS=3 #DON'T  BE SET LESS THAN 1

OS_USER='masvc01'
DB_USER='backupuser'
DB_PWD='backupuser_password'
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
```

### Usage 

```
$ sh mariadb_backup.sh

Usage: sh mariadb_backup.sh [OPTIONS]

The following options may be given as the first argument:
--full      Full Backup
--incre     Incremental Backup
--binlog    Binary Log Backup
--engine    Engine Backup
--delete    Delete Old Backups
--list      Show list of backups on disk
```
### Full Backup example

```
$ sh backup.sh --full
==============================================
== TESTDB Full Backup
== Started : 2016/12/14 16:36:04
==============================================
161214 16:36:04  version_check Connecting to MySQL server with DSN 'dbi:mysql:;mysql_read_default_group=xtrabackup;port=3406;mysql_socket=/engn001/masvc01/TESTDB/mysqld.sock' as 'root'  (using password: YES).
161214 16:36:04  version_check Connected to MySQL server
... skip ...
161214 16:36:57 completed OK!
==============================================
== End    : 2016/12/14 16:36:57
== Backup : /bkup001/masvc01/TESTDB/TESTDB_full_20161214_1636
==============================================
```
### Incremental Backup example

```
$ sh backup.sh --incre
==============================================
== Started : 2016/12/14 16:52:13
== TESTDB Incremental Backup
==============================================
161214 16:52:13  version_check Connecting to MySQL server with DSN 'dbi:mysql:;mysql_read_default_group=xtrabackup;port=3406;mysql_socket=/engn001/masvc01/TESTDB/mysqld.sock' as 'root'  (using password: YES).
161214 16:52:13  version_check Connected to MySQL server
... skip ...
xtrabackup: Transaction log of lsn (23470074976) to (23488291255) was copied.
161214 16:53:38 completed OK!
==============================================
== End    : 2016/12/14 16:53:38
== Backup : /bkup001/masvc01/TESTDB/TESTDB_incre_20161214_1652
==============================================
```
### Binlog Backup example

```
$ sh backup.sh --binlog
==============================================
== Started : 2016/12/14 16:54:08
== TESTDB Binlog Backup
==============================================
sending incremental file list
./
mariadb-bin.000115
mariadb-bin.000116
mariadb-bin.000117
mariadb-bin.index

sent 40705417 bytes  received 91 bytes  81411016.00 bytes/sec
total size is 4751901052  speedup is 116.74
==============================================
== End    : 2016/12/14 16:54:08
== Backup : /bkup001/masvc01/TESTDB/binary_backup
==============================================
```
### Engine Backup example

```
$ sh backup.sh --engine
==============================================
== TESTDB Engine Backup
== Started : 2016/12/14 17:10:48
==============================================
==============================================
== End    : 2016/12/14 17:10:49
== Backup : /bkup001/masvc01/TESTDB/engine_backup_201612141710
== Log    : /bkup001/masvc01/TESTDB/backup_log/backup.db.20161214171048.log
== All backup history : /bkup001/masvc01/TESTDB/backup_log/backup_all_history.log
==============================================
```
### Delete Backups example

```
$ sh backup.sh --delete
==============================================
== TESTDB Delete Backups
== Started : 2016/12/14 17:03:06
==============================================
==============================================
== End    : 2016/12/14 17:03:06
== Log    : /bkup001/masvc01/TESTDB/backup_log/backup.db.20161214170306.log
== All backup history : /bkup001/masvc01/TESTDB/backup_log/backup_all_history.log
==============================================
```
### Show List of backups example

```
$ sh backup.sh --list
==============================================
== TESTDB Show List of backups on disk
== Started : 2016/12/14 17:28:55
==============================================
th: /bkup001/masvc01/TESTDB/TESTDB_full_20161214_1636/
####################
backup_type = log-applied
start_time = 2016-12-14 16:36:04
end_time = 2016-12-14 16:36:52
binlog_pos = filename 'mariadb-bin.000116', position '64833', GTID of the last change '0-1-24238939'
partial = N
incremental = N
####################
# Path: /bkup001/masvc01/TESTDB/TESTDB_incre_20161214_1652/
####################
backup_type = incremental
start_time = 2016-12-14 16:52:13
end_time = 2016-12-14 16:53:38
binlog_pos = filename 'mariadb-bin.000117', position '207503', GTID of the last change '0-1-24246886'
partial = N
incremental = Y
####################
# Path: /bkup001/masvc01/TESTDB/binary_backup (Backuped Binlog)
####################
mariadb-bin.000094  mariadb-bin.000098  mariadb-bin.000102  mariadb-bin.000106  mariadb-bin.000110  mariadb-bin.000114  mariadb-bin.index
mariadb-bin.000095  mariadb-bin.000099  mariadb-bin.000103  mariadb-bin.000107  mariadb-bin.000111  mariadb-bin.000115
mariadb-bin.000096  mariadb-bin.000100  mariadb-bin.000104  mariadb-bin.000108  mariadb-bin.000112  mariadb-bin.000116
mariadb-bin.000097  mariadb-bin.000101  mariadb-bin.000105  mariadb-bin.000109  mariadb-bin.000113  mariadb-bin.000117
==============================================
== End    : 2016/12/14 17:28:55
== Log    : /bkup001/masvc01/TESTDB/backup_log/backup.db.20161214172855.log
== All backup history : /bkup001/masvc01/TESTDB/backup_log/backup_all_history.log
==============================================
```
