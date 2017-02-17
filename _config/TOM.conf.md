# Cyclone3 configuration options

## Cluster

Cluster in Cyclone3 is defined as pool of hosts. This pool is named "domain of hosts".

When resources (as rlog server) are shared between more clusters, then cluster is identified by this name.

```perl
# optional
$TOM::domain='mycluster';
```

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

"main" is the reserved name for Cyclone3 primary 

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

- **type**

 Use different type of connector. "DBI" for example

- **uri**

 URI configuration for "DBI" connector. example: "dbi:Sybase:server=sap"

- **host**

- **user**

- **password**

- **sql**

 Set of queries executed immediatelly after connection

- **slaves**

 Number of configured slaves in master-slave MySQL cluster mode.

- **weight**

 Weight of this node for read operations across all slaves.

- **slaves_autoweight**

 When enabled, job.workerd is calculating automatically weight for every node from average speed of queries executed.

**first slave configuration**

Number of database slaves are unlimited. Slaves are used to distribute read-only queries across slave nodes.

```perl
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
```



### Tips:
- When connection is lost to **master**, by default is database reconnected automatically, and last query re-send.
- When connection is lost to **slave**, this node is evicted from pool to short time. You can freely restart any of slave without lost of availability in application.
