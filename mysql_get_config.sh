#!/bin/bash
# if you want to debug script, you can use -x option like : !/bin/bash -x

#########################################################################
#                                                                       #
# getting MySQL/MariaDB configuration                                   #
# This script only get the environment information. When you create     #
# a new script to use environmental information, including this script. #
#                                                                       #
# Written by: YJ                                                        #
# QnA to : https://github.com/good-dba/mariadb-dba-scripts              #
# Inspired by: https://launchpad.net/mysql-tuning-primer                #
# Version: 0.1                                                          #
# Released: 2016-07-28                                                  #
#                                                                       #
# Tested on MariaDB 10.x                                                #
#                                                                       #
#########################################################################
#                                                                       #
# Usage: ./mysql_get_config.sh                                          #
#                                                                       #
#########################################################################
#                                                                       #
# Set this socket variable ONLY if you have multiple instances running  #
# or we are unable to find your socket, and you don't want to to be     #
# prompted for input each time you run this script.                     #
#                                                                       #
#########################################################################
socket=

get_system_info () {

## -- Get system information -- ##

    export OS=$(uname)

    # Get information for various UNIXes
    if [ "$OS" = 'Darwin' ]; then
        ps_socket=$(netstat -ln | awk '/mysql(.*)?\.sock/ { print $9 }' | head -1)
        found_socks=$(netstat -ln | awk '/mysql(.*)?\.sock/ { print $9 }')
        export physical_memory=$(sysctl -n hw.memsize)
        export duflags=''
    elif [ "$OS" = 'FreeBSD' ] || [ "$OS" = 'OpenBSD' ]; then
        ## On FreeBSD must be root to locate sockets.
        ps_socket=$(netstat -ln | awk '/mysql(.*)?\.sock/ { print $9 }' | head -1)
        found_socks=$(netstat -ln | awk '/mysql(.*)?\.sock/ { print $9 }')
        export physical_memory=$(sysctl -n hw.realmem)
        export duflags=''
    elif [ "$OS" = 'Linux' ] ; then
        ## Includes SWAP
        ## export physical_memory=$(free -b | grep -v buffers |  awk '{ s += $2 } END { printf("%.0f\n", s ) }')
        ps_socket=$(netstat -ln | awk '/mysql(.*)?\.sock/ { print $9 }' | head -1)
        found_socks=$(netstat -ln | awk '/mysql(.*)?\.sock/ { print $9 }')
        export physical_memory=$(awk '/^MemTotal/ { printf("%.0f", $2*1024 ) }' < /proc/meminfo)
        export duflags='-b'
    elif [ "$OS" = 'SunOS' ] ; then
        ps_socket=$(netstat -an | awk '/mysql(.*)?.sock/ { print $5 }' | head -1)
        found_socks=$(netstat -an | awk '/mysql(.*)?.sock/ { print $5 }')
        export physical_memory=$(prtconf | awk '/^Memory\ size:/ { print $3*1048576 }')
    fi
    if [ -z $(which bc) ] ; then
        echo "Error: Command line calculator 'bc' not found!"
        exit
    fi
}

check_for_socket () {

## -- Find the location of the mysql.sock file -- ##

    if [ -z "$socket" ] ; then #-- 	True of the length if "STRING" is zero.
        # Use ~/my.cnf version
        if [ -f ~/.my.cnf ] ; then #-- True if FILE exists and is a regular file.
            cnf_socket=$(grep ^socket ~/.my.cnf | awk -F \= '{ print $2 }' | head -1)
        fi
        if [ -S "$cnf_socket" ] ; then #-- True if FILE exists and is a socket.
            socket=$cnf_socket
        elif [ -S /var/lib/mysql/mysql.sock ] ; then
            socket=/var/lib/mysql/mysql.sock
        elif [ -S /var/run/mysqld/mysqld.sock ] ; then
            socket=/var/run/mysqld/mysqld.sock
        elif [ -S /tmp/mysql.sock ] ; then
            socket=/tmp/mysql.sock
        else
            if [ -S "$ps_socket" ] ; then
            socket=$ps_socket
            fi
        fi
    fi
    if [ -S "$socket" ] ; then
        echo UP > /dev/null
    else
        echo "No valid socket file \"$socket\" found!"
        echo "The mysqld process is not running or it is installed in a custom location."
        echo "If you are sure mysqld is running, set the the socket= variable at the top of this script"
        exit 1
    fi
}

check_basedir () {

## -- find the MySQL/MariaDB basedir -- ##

    type mysql &>/dev/null ||  { # || : If the exit status of the first command is not 0, then execute the second command
        printf "\n"
        echo "Could not auto detect basedir!!"
        printf "\n"
        read -p "Would you like to provide a basedir?: [y/N] " REPLY
            case $REPLY in
                yes | y | Y | YES)
                read -p "basedir: " basedir
                ;;
                *)
                exit 1
                ;;
            esac
    }

    type mysql &>/dev/null && { # && : If the exit status of the first command is 0, then execute the second command
        basedir=`type -p mysql | awk '{ sub("/bin/mysql", ""); print }'`
        echo ""
        echo "Using basedir: $basedir"
        echo ""
        read -p "Would you like to provide a different basedir?: [y/N] " REPLY
            case $REPLY in
                yes | y | Y | YES)
                read -p "basedir: " basedir
                ;;
            esac
    }

    if [ -d $basedir ] ; then
        mysql=$basedir/bin/mysql
        mysqldump=$basedir/bin/mysqldump
        mysqladmin=$basedir/bin/mysqladmin
    else
        echo "basedir is not a valid directory"
        exit 1
    fi

}

check_mysql_login () {

## -- Test for running mysql -- ##

    is_up=$($mysqladmin ping 2>&1)
    if [ "$is_up" = "mysqld is alive" ] ; then
        echo UP > /dev/null
    elif [ "$is_up" != "mysqld is alive" ] ; then
        printf "\n"
        if [ -z $prompted ] ; then
            login_failed
        else
            return 1
        fi
    else
        echo "Unknow exit status"
        exit -1
    fi
}

login_failed () {

    echo "Could not auto detect login info!"
    echo "Found potential sockets: $found_socks"
    printf "\n"
    echo "Using: $socket"

    ##-- set socket file
    echo ""
    read -p "Would you like to provide a different socket?: [y/N] " REPLY
        case $REPLY in
            yes | y | Y | YES)
            read -p "Socket: " socket
            ;;
        esac

    ##-- set mysql evironment
    echo ""
    echo "Please input username and password to connect to DB"
    read -p "User: " user
    read -srp "Password: " pass
    if [ -z $pass ] ; then
        export mysql="$mysql -S$socket -u$user"
        export mysqladmin="$mysqladmin -S$socket -u$user"
        export mysqldump="$mysqladmin -S$socket -u$user"
    else
        export mysql="$mysql -S$socket -u$user -p$pass"
        export mysqladmin="$mysqladmin -S$socket -u$user -p$pass"
        export mysqldump="$mysqldump -S$socket -u$user -p$pass"
    fi

}

login_validation () {

## -- Check for login validation -- ##

    check_basedir              # determine the mysql basedir
    check_for_socket           # determine the socket location
    check_mysql_login          # determine if mysql is accepting login
    #export mysql_version=$($mysql -Bse "SELECT SUBSTRING_INDEX(VERSION(), '-', 1)")
    export mysql_version=$($mysql -Bse "SELECT VERSION()")

}


## ---------- ##
## -- Main -- ##
## ---------- ##

get_system_info

login_validation

clear
echo "#####################################"
echo "#"
echo "# MySQL/MariaDB version: $mysql_version"
echo "# basedir: $basedir"
echo "# socket: $socket"
echo "#"
echo "#####################################"
