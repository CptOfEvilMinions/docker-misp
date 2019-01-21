FROM ubuntu:18.04

############################################################
# ARGs and ENV vars
############################################################
# User supplied inputs
ARG MYSQL_MISP_PASSWORD=ChangeThisDefaultPassworda9564ebc3289b7a14551baf8ad5ec60a
ARG POSTFIX_RELAY_HOST=localhost
ARG MISP_FQDN=localhost
ARG MISP_EMAIL=admin@localhost

# GPG
ENV gpg_key_type="1"
ENV gpg_key_length="4096"
ENV gpg_subkey_type="1"
ENV gpg_subkey_length="4096"
ENV gpg_name_real="MISP"
ENV gpg_name_email="admin@hackinglab.local"
ENV gpg_expire_date="0"

############################################################
# Install/Setup LAMP
############################################################
ENV DEBIAN_FRONTEND noninteractive

# Install the dependencies
RUN apt-get update && \
    apt-get install -y supervisor cron logrotate \
    syslog-ng-core postfix curl gcc git gnupg-agent \
    make python python3 openssl redis-server sudo vim \
    zip wget mariadb-client mariadb-server apache2 \
    apache2-doc apache2-utils libapache2-mod-php php \
    php-cli php-gnupg php-dev php-json php-mysql php-opcache \
    php-readline php-redis php-xml php-mbstring rng-tools \
    python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev \
    python-setuptools libpq5 libjpeg-dev

# Edit the php.ini file to adjust initial PHP settings to MISP recommended settings
RUN sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.2/apache2/php.ini && \
    sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/7.2/apache2/php.ini && \
    sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 50M/" /etc/php/7.2/apache2/php.ini && \
    sed -i "s/post_max_size = 8M/post_max_size = 50M/" /etc/php/7.2/apache2/php.ini


# Set Syslog-ng output to /dev/log
RUN sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf

# Set SMTP relayhost
RUN postconf -e "relayhost = $POSTFIX_RELAY_HOST"

# Disable daemon mode for Redis
RUN sed -i "s/daemonize yes/daemonize no/" /etc/redis/redis.conf

#echo "test -e /var/run/mysqld || install -m 755 -o mysql -g root -d /var/run/mysqld" && \
RUN test -e /var/run/mysqld || install -m 755 -o mysql -g root -d /var/run/mysqld

# Enable modules, settings, and default of SSL in Apache
RUN a2dismod status && \
    a2enmod ssl rewrite headers&& \
    a2ensite 000-default && \
    a2ensite default-ssl && \
    mkdir -p /var/www/MISP /root/.config /root/.git

############################################################
# MISP code
############################################################
# Download MISP using git in the /var/www/ directory.
RUN cd /var/www/MISP && \
    chown -R www-data:www-data /var/www/MISP /root/.config /root/.git&& \
    sudo -u www-data -H git clone https://github.com/MISP/MISP.git /var/www/MISP && \
    sudo -u www-data -H git submodule update --init --recursive && \
    sudo -u www-data -H git submodule foreach --recursive git config core.filemode false && \
    sudo -u www-data -H git config core.filemode false    

# Install Mixbox
RUN cd /var/www/MISP/app/files/scripts && sudo -u www-data -H git clone https://github.com/CybOXProject/mixbox.git
RUN cd /var/www/MISP/app/files/scripts/mixbox && sudo python3 setup.py install

# Install CyBox
RUN cd /var/www/MISP/app/files/scripts && sudo -u www-data -H git clone https://github.com/CybOXProject/python-cybox.git
RUN cd /var/www/MISP/app/files/scripts/python-cybox && sudo python3 setup.py install

# Install STIXX
RUN cd /var/www/MISP/app/files/scripts && sudo -u www-data -H git clone https://github.com/STIXProject/python-stix.git
RUN cd  /var/www/MISP/app/files/scripts/python-stix && sudo python3 setup.py install

# Install MAEC
RUN cd /var/www/MISP/app/files/scripts && sudo -u www-data -H git clone https://github.com/MAECProject/python-maec.git
RUN cd /var/www/MISP/app/files/scripts/python-maec && sudo python3 setup.py install

# Install CTI
RUN cd /var/www/MISP/cti-python-stix2 && sudo python3 setup.py install

# Git submodule init
RUN cd /var/www/MISP && sudo -u www-data -H git submodule init && sudo -u www-data -H git submodule update

# Install jsonschema and pymisp
RUN sudo pip3 install jsonschema && sudo pip3 install pymisp

# Install PyMISP
RUN cd /var/www/MISP/PyMISP && python3 setup.py install

## Install STIX2
RUN sudo pip3 install --upgrade pip && sudo pip3 install stix2

# Download MISP-modules
RUN cd /usr/local/src && sudo -H git clone https://github.com/MISP/misp-modules.git
 
# Install MISP modules
RUN cd /usr/local/src/misp-modules && sudo pip3 install -I -r REQUIREMENTS && sudo pip3 install -I .

# Insall CyBox
RUN sudo pip3 uninstall -y cybox

############################################################
# CakePHP
############################################################
RUN cd /var/www/MISP/app && \
    mkdir /var/www/.composer && chown -R www-data:www-data /var/www/.composer && \
    sudo -u www-data -H wget https://getcomposer.org/download/1.2.1/composer.phar -O composer.phar && \
    sudo -u www-data -H php composer.phar require kamisama/cake-resque:4.1.2 && \
    sudo -u www-data -H php composer.phar config vendor-dir Vendor && \
    sudo -u www-data -H php composer.phar install && \
    sudo phpenmod redis && \
    sudo -u www-data -H cp -fa /var/www/MISP/INSTALL/setup/config.php /var/www/MISP/app/Plugin/CakeResque/Config/config.php

############################################################
# Perms
############################################################
RUN sudo chown -R www-data:www-data /var/www/MISP && \
    sudo chmod -R 750 /var/www/MISP && \
    sudo chmod -R g+ws /var/www/MISP/app/tmp && \
    sudo chmod -R g+ws /var/www/MISP/app/files && \
    sudo chmod -R g+ws /var/www/MISP/app/files/scripts/tmp

############################################################
# Install/Setup Apache
############################################################
# Copy SSL certs
COPY certs/misp.key /etc/ssl/private/misp.key
COPY certs/misp.crt /etc/ssl/private/misp.crt

# Copy VirutalHost configs
COPY conf/misp-apache.conf /etc/apache2/sites-available/000-default.conf
COPY conf/misp-https-apache.conf /etc/apache2/sites-available/default-ssl.conf

    # echo "<VirtualHost *:80>" > /etc/apache2/sites-available/000-default.conf && \
    # echo "ServerName $MISP_FQDN" >> /etc/apache2/sites-available/000-default.conf && \
    # echo "Redirect permanent / https://$MISP_FQDN" >> /etc/apache2/sites-available/000-default.conf && \
    # echo "LogLevel warn" >> /etc/apache2/sites-available/000-default.conf && \
    # echo "ErrorLog /var/log/apache2/misp_error.log" >> /etc/apache2/sites-available/000-default.conf && \
    # echo "CustomLog /var/log/apache2/misp_access.log combined" >> /etc/apache2/sites-available/000-default.conf && \
    # echo "ServerSignature Off" >> /etc/apache2/sites-available/000-default.conf && \
    # echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf && \

    # echo "<VirtualHost *:443>" > /etc/apache2/sites-available/default-ssl.conf && \
    # echo "ServerAdmin $MISP_EMAIL" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "ServerName $MISP_FQDN" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "DocumentRoot /var/www/MISP/app/webroot" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "<Directory /var/www/MISP/app/webroot>" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "Options -Indexes" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "AllowOverride all" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "</Directory>" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "SSLEngine On" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "SSLCertificateFile /etc/ssl/private/misp.crt" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "SSLCertificateKeyFile /etc/ssl/private/misp.key" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "#SSLCertificateChainFile /etc/ssl/private/misp-chain.crt" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "LogLevel warn" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "ErrorLog /var/log/apache2/misp_ssl_error.log" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "CustomLog /var/log/apache2/misp_ssl_access.log combined" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "ServerSignature Off" >> /etc/apache2/sites-available/default-ssl.conf && \
    # echo "</VirtualHost>" >> /etc/apache2/sites-available/default-ssl.conf && \

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

############################################################
# MISP configuration
############################################################
# Move defaults configs to primary configs
RUN sudo -u www-data cp -a /var/www/MISP/app/Config/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.php && \
    sudo -u www-data cp -a /var/www/MISP/app/Config/database.default.php /var/www/MISP/app/Config/database.php && \
    sudo -u www-data cp -a /var/www/MISP/app/Config/core.default.php /var/www/MISP/app/Config/core.php && \
    sudo -u www-data cp -a /var/www/MISP/app/Config/config.default.php /var/www/MISP/app/Config/config.php

RUN sed -i -e 's/db login/misp/g' /var/www/MISP/app/Config/database.php ; \
    sed -i -e "s/db password/${MYSQL_MISP_PASSWORD}/g" /var/www/MISP/app/Config/database.php ; \
    sed -i -E "s/'salt'(\s+)=>\s''/'salt' => '`openssl rand -base64 32 | tr \'/\' \'0\'`'/" /var/www/MISP/app/Config/config.php ; \
    sed -i -E "s/'baseurl'(\s+)=>\s''/'baseurl' => 'https:\/\/${MISP_FQDN}'/" /var/www/MISP/app/Config/config.php ; \
    sed -i -e "s/email@address.com/${MISP_EMAIL}/" /var/www/MISP/app/Config/config.php ; \
    sed -i -e "s/bind 127.0.0.1 ::1/bind 0.0.0.0/" /etc/redis/redis.conf ; \
    sudo chown -R www-data:www-data /var/www/MISP/app/Config ; \
    sudo chmod -R 750 /var/www/MISP/app/Config ; \
    sudo pip3 install --upgrade pip ; \
    sudo pip3 install pyzmq ; \
    sudo pip3 install redis ; \
    sudo -u www-data -H wget http://downloads.sourceforge.net/project/ssdeep/ssdeep-2.13/ssdeep-2.13.tar.gz ; \
    tar zxvf ssdeep-2.13.tar.gz && cd ssdeep-2.13 && ./configure && make && sudo make install ; \
    sudo pecl install ssdeep ; \
    sudo echo "extension=ssdeep.so" > /etc/php/7.2/mods-available/ssdeep.ini ; \
    sudo phpenmod ssdeep ;

# MySQL init DB
COPY mysql-init.sh /init-db

# Replace MySQL password
RUN sed -i "s#\$MYSQL_MISP_PASSWORD#$MYSQL_MISP_PASSWORD#g" /init-db
RUN chmod 755 /init-db

RUN sudo -u www-data -H mkdir /var/www/MISP/.gnupg ; \
    chmod 700 /var/www/MISP/.gnupg ; \
    echo "Key-Type: 1" > /tmp/config_gpg ; \
    echo "Key-Length: 4096" >> /tmp/config_gpg ; \
    echo "Subkey-Type: 1" >> /tmp/config_gpg ; \
    echo "Subkey-Length: 4096" >> /tmp/config_gpg ; \
    echo "Name-Real: MISP" >> /tmp/config_gpg ; \
    echo "Name-Email: $MISP_EMAIL" >> /tmp/config_gpg ; \
    echo "Expire-Date: 0" >> /tmp/config_gpg ; \
    chmod 700 /tmp/config_gpg ; \
    sudo rm -f /dev/random ; \
    sudo mknod -m 0666 /dev/random c 1 9 ; \
    sudo echo RNGDOPTIONS="--random-device /dev/urandom --rng-device /dev/urandom" | sudo tee /etc/default/rng-tools ; \
    sudo echo HRNGDEVICE=/dev/urandom | sudo tee /etc/default/rng-tools ; \
    sudo /etc/init.d/rng-tools restart ; \
    sudo rngd -f -r /dev/urandom ; \
    chown www-data /tmp/config_gpg ; \
    sudo -u www-data sh -c "gpg --batch --homedir /var/www/MISP/.gnupg --gen-key /tmp/config_gpg" ; \
    sudo -u www-data sh -c "gpg --homedir /var/www/MISP/.gnupg --export --armor $MISP_EMAIL > /var/www/MISP/app/webroot/gpg.asc" ; \
    sudo /etc/init.d/rng-tools stop ; \
    sudo apt-get remove --purge -y rng-tools

# Setup GPG config
#RUN sudo -u www-data -H mkdir /var/www/MISP/.gnupg && chmod 700 /var/www/MISP/.gnupg
#COPY config_gpg /tmp/config_gpg
#RUN sed -i "s#^Key-Type: .*#Key-Type: ${gpg_key_type}#" /tmp/config_gpg
#RUN sed -i "s#^Key-Length: .*#Key-Length: ${gpg_key_length}#" /tmp/config_gpg
#RUN sed -i "s#^Subkey-Type: .*#Subkey-Type: ${gpg_subkey_type}#" /tmp/config_gpg
#RUN sed -i "s#^Subkey-Length: .*#Subkey-Length: ${gpg_subkey_length}#" /tmp/config_gpg
#RUN sed -i "s#^Name-Real: .*#Name-Real: ${gpg_name_real}#" /tmp/config_gpg
#RUN sed -i "s#^Name-Email: .*#Name-Email: ${gpg_name_email}#" /tmp/config_gpg
#RUN sed -i "s#^Expire-Date: .*#Expire-Date: ${gpg_expire_date}#" /tmp/config_gpg

#RUN cat /tmp/config_gpg
    # echo "Key-Type: 1" > /tmp/config_gpg && \
    # echo "Key-Length: 4096" >> /tmp/config_gpg && \
    # echo "Subkey-Type: 1" >> /tmp/config_gpg && \
    # echo "Subkey-Length: 4096" >> /tmp/config_gpg && \
    # echo "Name-Real: MISP" >> /tmp/config_gpg && \
    # echo "Name-Email: $MISP_EMAIL" >> /tmp/config_gpg && \
    # echo "Expire-Date: 0" >> /tmp/config_gpg && \

#RUN chmod 700 /tmp/config_gpg 
#RUN sudo rm -f /dev/random && sudo mknod -m 0666 /dev/random c 1 9
#RUN sudo echo RNGDOPTIONS="--random-device /dev/urandom --rng-device /dev/urandom" | sudo tee /etc/default/rng-tools 
#RUN sudo echo HRNGDEVICE=/dev/urandom | sudo tee /etc/default/rng-tools 
#RUN sudo /etc/init.d/rng-tools restart 
#RUN sudo rngd -f -r /dev/urandom 
#RUN chown www-data /tmp/config_gpg 
#RUN sudo -u www-data sh -c "gpg --batch --homedir /var/www/MISP/.gnupg --gen-key /tmp/config_gpg" 
#RUN sudo -u www-data sh -c "gpg --homedir /var/www/MISP/.gnupg --export --armor $MISP_EMAIL > /var/www/MISP/app/webroot/gpg.asc" 
#RUN sudo /etc/init.d/rng-tools stop
#RUN sudo apt-get remove --purge -y rng-tools

############################################################
# Logrotate
############################################################
COPY conf/misp-logrotate /etc/logrotate.d/misp
RUN chmod 0640 /etc/logrotate.d/misp

############################################################
# Supervisor
############################################################
COPY supervisord.conf /etc/supervisor/conf.d/

#>&2 echo "The default user = "admin@admin.test" | The default password = admin" && \
# To change it:
#echo "/var/www/MISP/app/Console/cake Password 'admin@admin.test' '@dmin1!'" >> /root/init-db && \

WORKDIR /var/www/MISP

# 80/443 - MISP web server, 3306 - mysql, 6379 - redis, 50000 - MISP ZeroMQ
EXPOSE 80 443 3306 6379 50000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
