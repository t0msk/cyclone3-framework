# Cyclone3 configuration options

## Cluster

Cluster in Cyclone3 is defined as pool of hosts. This pool is named "domain of hosts".

When resources (as rlog server) are shared between more clusters, then cluster is identified by this name.

```perl
# optional
$TOM::domain='mycluster';
```

This is development server/cluster:

~~~perl
$tom::devel = 1;
~~~


## User setup

~~~perl
# $TOM::user="cyclone3";
# $TOM::group="cyclone3";
$TOM::user_www="www-data";
# $TOM::mediasrv_user="apache";
# $TOM::mediasrv_group="www";
~~~

- $TOM::user

	cyclone3 framework user (uid for background services)
	
- $TOM::group

	cyclone3 group (gid for background services)

- $TOM::user_www

	apache2 user

- $TOM::mediasrv_user

	uid for static media (nginx?)

- $TOM::mediasrv_group

	gid for static media (nginx?)

## Contacts

**default setting for system emails**

Used for notifications, etc...

```perl
$TOM::contact{'_'}='cyclone3@'.$TOM::hostname; # default contact
$TOM::contact{'from'}='cyclone3@'.$TOM::hostname;
```

**smtp server configuration**

When not configured, sendmail command will be used.

```perl
# optional
$TOM::smtp_host='localhost';
$TOM::smtp_user='cyclone3@mydomain.com';
$TOM::smtp_SSL=1; # is SSL required?
$TOM::smtp_pass='mypassword';
```

## Database configuration

**default master database configuration**

"main" is the reserved name for Cyclone3 primary database connection.

```perl
$TOM::DB{'main'} = {
	'host' => "localhost", 'user' => "Cyclone3", 'password' => "mypassword",
	'sql' => [
		"SET NAMES 'utf8'",
		"SET CHARACTER SET 'utf8'",
		"SET character_set_connection='utf8'",
		"SET character_set_database='utf8'",
		"SET sql_mode = \"\"",
	],
    'slaves' => 2, # number of slaves in pool
    'slaves_autoweight' => 'true',
};
```

- type

	Use different type of connector. "DBI" for example

- uri

	URI configuration for "DBI" connector. example: "dbi:Sybase:server=sap"

- host

- user

- password

- sql

	Set of queries executed immediatelly after connection

- slaves

	Number of configured slaves in master-slave MySQL cluster mode.

- weight

	Weight of this node for read operations across all slaves.

- slaves_autoweight

	When enabled, job.workerd is calculating automatically weight
	for every node from average speed of queries executed.

**first slave configuration**

Number of database slaves are unlimited. Slaves are used to distribute read-only queries across slave nodes.

~~~perl
# optional
$TOM::DB{'main:1'} = {
	'host' => "anotherhost", 'user' => "Cyclone3", 'password' => "mypassword",
	'sql' => [
		"SET NAMES 'utf8'",
		"SET CHARACTER SET 'utf8'",
		"SET character_set_connection='utf8'",
		"SET character_set_database='utf8'",
		"SET sql_mode = \"\"",
	],
    'weight' => 100, # default weight
};
~~~

### Tips:

- When connection is lost to **master**, by default is database reconnected automatically, and last query re-send.
- When connection is lost to **slave**, this node is evicted from pool to short time. You can freely restart any of slave without lost of availability in application.

## RabbitMQ

~~~perl
$Ext::RabbitMQ::host='127.0.0.1'; # on every host it's localhost
$Ext::RabbitMQ::user='Cyclone3';
$Ext::RabbitMQ::pass='mypassword';
~~~

## ElasticSearch

~~~perl
$Ext::Elastic={
	'nodes' => ['elastic-01:9200','elastic-02:9200']
};
~~~

## Tuning

Disable internal gzip (use mod_deflate instead)

~~~perl
$pub::gzip_disable=1;
~~~

~~~
$TOM::paranoid=1;
$TOM::max_time=60*60; # 1hours
$TOM::fcgi_sleep_timeout=60*5; # 5min
~~~

~~~
$Ext::Solr::url='http://web-db-01:8983/solr/cyclone3';

$TOM::event_elastic=0; # zapnute
$TOM::event_log=1; # zapnute do logu
$TOM::event_severity_disable{'debug'}=0;
$TOM::event_facility_disable{'pub.request'}=1;
$TOM::event_facility_disable{'process.start'}=1;

$TOM::Database::SQL::logquery=1;
$TOM::Database::SQL::lognonselectquery=1;


$TOM::DEBUG_log_fluentd='127.0.0.1:24224';

$tom::admin_ip_regexp='^(95\.105\.186\.175|62\.197\.199\.74|188\.121\.174\.181|217\.73\.18\.220|192\.168\.0\.|192\.168\.123\.|95\.105\.230.\227)';


$Ext::Redis::host='localhost:6379';
@Ext::Redis::hosts=( # cluster sharding
	{
		'host' => 'web-app-01:6379', # app-01
		'replica_host' => 'web-app-02:6379', # app-02
#		'host' => '/var/run/redis/redis.sock'
	},
	{
		'host' => 'web-app-02:6379', # app-2
		'replica_host' => 'web-app-01:6379', # app-01
#		'host' => '/var/run/redis/redis.sock'
	}
);


$Ext::Elastic_rlog={
	'nodes' => ['10.18.2.151:9200'],
	'client' => '2_0::Direct',
	'_manage' => 1,
};
~~~

## Debug, events and logs

Cyclone3 has more options as log destinations (file, socket, fluentd)

Default log level

~~~perl
$TOM::DEBUG_log_level_file=90; # very deeep
~~~

Change default file log directory
~~~perl
$TOM::path_log="/var/log/Cyclone3";
~~~

Log about cache usage

~~~perl
$TOM::DEBUG_cache=1;
~~~

### Collecting data into database

Disable collecting webpages static informations into database
~~~perl
$TOM::STAT=0;
~~~

Don't create error tickets into database
~~~perl
$App::100::ticket_ignore=1;
~~~

### Events

Send events informations throught socket (splunk)
~~~perl
$TOM::event_socket='localhost:301';
~~~





