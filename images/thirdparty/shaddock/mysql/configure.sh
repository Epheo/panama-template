#!/bin/bash
s='crudini --set /etc/mysql/my.cnf' # substitute
$s mysqld bind-address 0.0.0.0
$s mysqld default-storage-engine innodb
$s mysqld innodb_file_per_table on
$s mysqld max_connections 4096
$s mysqld collation-server utf8_general_ci
$s mysqld character-set-server utf8

VOLUME_HOME="/var/lib/mysql"

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    echo "=> Done!"  

    /usr/bin/mysqld_safe &

    RET=1
    while [[ RET -ne 0 ]]; do
        echo "=> Waiting for confirmation of MySQL service startup"
        sleep 5
        mysql -uroot -e 'status'
        RET=$?
    done

    mysql -uroot -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASS'"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION"

    echo "==================================================================="
    echo "You can now connect to this MySQL Server using:"
    echo ""
    echo "    mysql -u $MYSQL_USER -p $MYSQL_PASS -h <host> -P <port>"
    echo ""
    echo "MySQL user 'root' has no password but only allows local connections"

    mysqladmin -uroot shutdown
else
    echo "=> Using an existing volume of MySQL"
fi

exec mysqld_safe
