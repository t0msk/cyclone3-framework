# Cyclone3 Framework

> developed since 2002, released under [GPLv2](LICENSE.md) in 2006

Cyclone3 is extremely flexible and mature open source framework designed to develop content management systems, custom intranet applications, CLI and async job applications writen in Perl.

## Basic features

- multi-engine
*framework supports multiple engines for different kind of processes: generating webpages, async jobs, cli commands,...*
- multi content-type CMS
*[publish engine](.core/.libs/TOM/Engine/pub.md) generates content in XHTML, HTML5, SVG, XML, JSON, RPC/SOAP services, ...*
- multi-domain
*one framework installation, unlimited number of domains and services*
- multi-server
*developed for HA cluster installations in master-master mode*

## Used technologies

- Perl & FastCGI
- MySQL/Percona
- RedisDB
- RabbitMQ
- ElasticSearch
- Template Toolkit 2

## Quick Installation

We are typically using Debian or Ubuntu for Cyclone3 Framework, so these are our two cents for Debian administrators. This installation process can take 15 minutes (without optimization).

*Note: If any problem occurs, don't hesitate to ask us at open@comsultia.com.*

This is just basic setup, but can be enhanced to get full Cyclone3 cluster.

## Prerequisites
- Linux operating system (mostly tested under Ubuntu Server LTS 14.04 and 16.04)
- git
- Perl >= 5.12
- MySQL >=5.5
- Apache2
- root access (no root access? forget about using Cyclone3)

## Getting Cyclone3

#### Prepare environment

Create **cyclone3** user

```bash
groupadd cyclone3;useradd cyclone3 -g cyclone3 -G www-data,crontab,users -s /bin/bash -m
```

Add Cyclone3 binaries location to PATH and export CYCLONE3PATH. Edit /etc/profile file, or add this content into /etc/profile.d/cyclone3.sh file

```bash
CYCLONE3PATH="/srv/Cyclone3"
export CYCLONE3PATH
PATH="$PATH:$CYCLONE3PATH/.bin"
```

Apply environment variables

```bash
source /etc/profile
```

#### Download Cyclone3

Get Cyclone3 Framework source codes and binaries from git to directory /srv/Cyclone3 (you can use different directory, but this is default and optimal setup). Don't create /srv/Cyclone3 as symlink.
You can clone from http://bit.comsultia.com/scm/cyc/framework.git repository (Comsultia) or https://github.com/rfordinal/cyclone3-framework.git (github)
Please, don't download as zip archive, the upgrade process after installation is provided using **git** too.

```bash
git clone http://bit.comsultia.com/scm/cyc/framework.git /srv/Cyclone3
chmod 770 /srv/Cyclone3
chown www-data:www-data /srv/Cyclone3
```

## Install all dependencies

Required libraries

```bash
apt-get install build-essential libinline-perl libmime-perl libdatetime-perl \
libxml-generator-perl libxml-xpath-perl libxml-simple-perl libsoap-lite-perl \
libnet-smtpauth-perl libstring-crc32-perl libfcgi-perl libcgi-fast-perl \
libparallel-forkmanager-perl libfile-type-perl \
libjson-any-perl perlmagick libtime-modules-perl libxml-libxml-perl \
libjson-perl libproc-processtable-perl libtie-ixhash-perl libmoosex-getopt-perl \
libanyevent-perl
```

Perl libraries not available in Debian/Ubuntu as .deb packages

```bash
cpan CPAN
cpan Template::Stash::XS
cpan Digest::MurmurHash
cpan Digest::SHA1
cpan AnyEvent::ForkManager
cpan Sys::Info
cpan Net::RabbitFoot
```

## Install and setup database

### MySQL

MySQL >= 5.5 is the main database for Cyclone3, but connection to another type of databases can be configured too.

We recommend Percona Server (http://www.percona.com/)

```bash
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
```

Add this to /etc/apt/sources.list, replacing VERSION with the name of your distribution:

``deb http://repo.percona.com/apt VERSION main``
```bash
sudo apt-get update && sudo apt-get install percona-server-server percona-server-client
```

Create Cyclone3 user (This is just an example. Of course you want to use password)

```sql
GRANT ALL PRIVILEGES ON *.* TO 'Cyclone3'@'localhost' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;
```

```bash
mysql -h localhost -u Cyclone3 -pmysecretpassword < /srv/Cyclone3/_data/TOM.sql
```

### RedisDB

```bash
apt-get install redis-server
cpan RedisDB
```

## Setup Cyclone3

Copy configuration template file to destination

```bash
cp /srv/Cyclone3/_config/TOM.conf.tmpl /srv/Cyclone3/_config/TOM.conf
```

This is minimal working configuration example
```perl
#!/usr/bin/perl
package TOM;
use strict;

$TOM::domain='nameofmycluster'; # "domain" of cyclone3 cluster nodes
$TOM::contact{'from'}='cyclone3@'.$TOM::hostname;
$TOM::contact{'_'}='cyclone3@'.$TOM::hostname; # default email to send notifications about health

# sending email over ...
$TOM::smtp_host='localhost';

# default databases
$TOM::DB{'main'}= {
	host	=>"localhost",
	user	=>"Cyclone3",
	pass	=>"",
	sql => [
		"SET NAMES 'utf8'",
		"SET CHARACTER SET 'utf8'",
		"SET character_set_connection='utf8'",
		"SET character_set_database='utf8'",
	]
};
$TOM::DB{'stats'}=$TOM::DB{'main'};
$TOM::DB{'sys'}=$TOM::DB{'main'};

# apache2 user
$TOM::user_www="www-data";

#$Ext::Redis::host='/var/run/redis/redis.sock';
$Ext::Redis::host='localhost:6379';

1;# don't remove me!
```

Check installed MySQL database scheme
```bash
tom3-chtables
```

Check files permissions
```bash
tom3-chfiles
```

Setup cron system
```bash
$ su cyclone3
$ crontab -e
# add lines
*    *    * * * cd /srv/Cyclone3/.core/;nice -n 20 ./cron 1min > /dev/null 2> /dev/null
*/5  *    * * * cd /srv/Cyclone3/.core/;nice -n 20 ./cron 5min > /dev/null 2> /dev/null
*/30 *    * * * cd /srv/Cyclone3/.core/;nice -n 20 ./cron 30min > /dev/null 2> /dev/null
2    *    * * * cd /srv/Cyclone3/.core/;nice -n 20 ./cron 1hour > /dev/null 2> /dev/null
5    */6  * * * cd /srv/Cyclone3/.core/;nice -n 20 ./cron 6hour > /dev/null 2> /dev/null
10    1    * * * cd /srv/Cyclone3/.core/;nice -n 20 ./cron 1day > /dev/null 2> /dev/null
20    2    */5 * * cd /srv/Cyclone3/.core/;nice -n 20 ./cron 5day > /dev/null 2> /dev/null
30    3    * * 1 cd /srv/Cyclone3/.core/;nice -n 20 ./cron 7day > /dev/null 2> /dev/null
40    4    1 * * cd /srv/Cyclone3/.core/;nice -n 20 ./cron 1month > /dev/null 2> /dev/null
```

## Setup Webserver

Install apache2 and mod_fcgid
```bash
apt-get install apache2
apt-get install libapache2-mod-fcgid
```

Add www-data user to cyclone3 group
```bash
usermod -a -G cyclone3 www-data
```

Copy virtualhost default template
```bash
cp /srv/Cyclone3/_config/httpd.virtual.conf.tmpl /srv/Cyclone3/_config/httpd.virtual.conf
```

Symlink configuration files
```bash
ln -s /srv/Cyclone3/.core/_config/httpd.conf /etc/apache2/conf.d/00-cyclone3.conf
ln -s /srv/Cyclone3/_config/httpd.virtual.conf /etc/apache2/sites-enabled/01-cyclone3-virtual.conf
```

Enable mod_expires and mod_rewrite
```bash
cd /etc/apache2/mods-enabled
ln -s ../mods-available/expires.load .
ln -s ../mods-available/rewrite.load .
```

Restart apache2
```bash
service apache2 restart
```

Now is everything configured properly, the next step is configuration/installation of first domain service (virtualhost)
