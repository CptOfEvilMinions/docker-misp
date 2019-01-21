# Docker MISP Container

This is an easy and highly customizable Docker container with MISP -
Malware Information Sharing Platform & Threat Sharing (http://www.misp-project.org)

Our goal was to provide a way to setup + run MISP in less than a minute!

We follow the official MISP installation steps everywhere possible,
while adding automation around tedious manual steps and configurations.

We have done this without sacrificing options and the ability to
customize MISP for your unique environment! Some examples include:
auto changing the salt hash, auto initializing the database, auto generating GPG
keys, auto generating working + secure configs, and adding custom
passwords/domain names/email addresses/ssl certificates.

The misp-modules extensions functionality has been included and can be
accessed from http://[dockerhostip]:6666/modules.
(thanks to Conrad)

## Latest Update: 1-15-2019

Following the Official MISP Ubuntu 18.04 LTS build instructions.

Latest Upstream Change Included: a62bca4e169c919413bba4e6ce978e30aae9183e

Github repo + build script here:
https://github.com/harvard-itsecurity/docker-misp
(note: after a git pull, update ```build.sh``` with your own passwords/FQDN, and then build the image)

## Build Docker container

We always recommend building your own Docker MISP image using our "build.sh" script.
This allows you to change all the passwords and customize a few config options.

### Generate OpenSSL cert

1. `openssl req -newkey rsa:4096 -nodes -x509 -days 3650 -subj "/C=US/ST=New York/L=Brooklyn/O=Example Brooklyn Company/CN=examplebrooklyn.com" -keyout container/certs/misp.key -out container/certs/misp.crt`

### Building MISP Docker image

1. `git clone https://github.com/harvard-itsecurity/docker-misp.git`
1. `cd docker-misp`
1. `docker build --build-arg MYSQL_MISP_PASSWORD=<MySQL MISP user password> --build-arg POSTFIX_RELAY_HOST=<SMTP Relay host FQDN> --build-arg MISP_FQDN=<FQDN> --build-arg MISP_EMAIL=admin@<domain> -t harvarditsecurity/misp container`

### Initialize MISP database

1. `docker volume create misp-db`
1. `docker run -it --rm -v misp-db:/var/lib/mysql misp /init-db`

### Start the stack

1. `docker-compose up -d`

## Access Web URL

1. Browse to `https://<FQDN for MISP>`
    1. Username: admin@admin.test
    1. Password: admin
1. change the password! :)
1. ![MISP Change passwd](.img/misp-change-passwd.png)

## Contributions

* Conrad Crampton: @radder5 - RNG Tools and MISP Modules

* Jeremy Barlow: @jbarlow-mcafee - Cleanup, configs, conveniences, python 2 vs 3 compatibility

* Matt Saunders: @matt-saunders - Fixed all install warnings and errors

## Help/Questions/Comments

For help or more info, feel free to contact Ventz Petkov: ventz_petkov@harvard.edu

## Resources/Sources

* [OpenSSL Essentials: Working with SSL Certificates, Private Keys and CSRs](https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs)
*
