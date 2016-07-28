#########################################################################
#                                                                       #
# .bash_profile sample                                                  #
#                                                                       #
#########################################################################

# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH

export TEMPDIR=/tmp
export EDITOR=vi

export MARIADB_BASE=/engn001/mysvc01/mariadb-10.0.20

PATH=$PATH:$MARIADB_BASE/bin:.
export PATH

stty erase ^H

PS1="[\u@\h:"'$PWD'"]\n$ "; export PS1

alias mysql3306='$MARIADB_BASE/bin/mysql -S /engn001/mysvc01/LGERP/mysqld.sock --comments -A -uroot -p'

alias nmon='/engn001/mysvc01/script/nmon_x86_64_centos6'
