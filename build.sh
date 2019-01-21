#!/bin/bash
#mysql_pass=$(openssl rand -hex 32)
mysql_pass="password123"
echo $mysql_pass

echo "Build container"
docker build \
    --build-arg MYSQL_MISP_PASSWORD=$mysql_pass \
    --build-arg POSTFIX_RELAY_HOST=smtp.hackinglab.local \
    --build-arg MISP_FQDN=misp.hackinglab.local \
    --build-arg MISP_EMAIL=admin@hackinglab.local \
    -t misp container

#echo "Create volume misp-db"
#docker volume create misp-db

#echo "Init database"
#docker run -it --rm -v misp-db:/var/lib/mysql harvarditsecurity/misp /init-db

echo "MySQL password"
echo $mysql_pass
