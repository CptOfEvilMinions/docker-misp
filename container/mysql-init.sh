#!/bin/bash
if [ ! -f /var/lib/mysql/.db_initialized ]; then
    sudo chown -R mysql:mysql /var/lib/mysql
    sudo -u mysql -H /usr/bin/mysql_install_db --user=mysql
    chown -R mysql:mysql /var/lib/mysql
    cd '/usr' && /usr/bin/mysqld_safe --datadir='/var/lib/mysql' &
    sleep 5

    mysql -uroot -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    mysql -uroot -e "DELETE FROM mysql.user WHERE User=''"
    mysql -uroot -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
    mysql -uroot -e "FLUSH PRIVILEGES;"
    mysql -uroot -e "create database misp"
    mysql -uroot -e "grant usage on *.* to misp@localhost identified by '$MYSQL_MISP_PASSWORD'"
    mysql -uroot -e "grant all privileges on misp.* to misp@localhost"
    mysql -uroot -e "flush privileges;"

    sudo -u www-data -H sh -c "mysql -u misp -p$MYSQL_MISP_PASSWORD misp < /var/www/MISP/INSTALL/MYSQL.sql"

    touch /var/lib/mysql/.db_initialized
    chown -R mysql:mysql /var/lib/mysql
fi

rm -f /init-db