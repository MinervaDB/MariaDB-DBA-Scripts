# mariadb-dba-scripts
The script files for the DBAs to support MySQL.

### mysql_start.sh, mysql_stop.sh

These are SAMPLE scripts for DB start and stop.

* Usage
* 
```
$ ./mysql_start.sh

$ ./mysql_stop.sh
```

### mysql_get_config.sh

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
