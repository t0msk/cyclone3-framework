-- db_h=sys
-- db_name=TOM
-- addon=a150

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_cache` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_config` int(10) unsigned NOT NULL default '0',
  `domain` varchar(32) character set ascii NOT NULL default '',
  `domain_sub` varchar(64) character set ascii NOT NULL default '',
  `engine` varchar(4) character set ascii NOT NULL default '',
  `Capp` varchar(16) character set ascii collate ascii_bin NOT NULL default '',
  `Cmodule` varchar(50) character set ascii NOT NULL default '',
  `Cid` varchar(20) character set ascii NOT NULL default '',
  `Cid_md5` varchar(32) character set ascii collate ascii_bin NOT NULL default '',
  `C_id_sub` varchar(50) character set ascii NOT NULL default '',
  `C_xsgn` varchar(50) character set ascii NOT NULL default '',
  `C_xlng` char(2) character set ascii NOT NULL default '',
  `time_from` int(10) unsigned NOT NULL default '0',
  `time_duration` int(10) unsigned NOT NULL default '0',
  `time_to` int(10) unsigned NOT NULL default '0',
  `body` mediumblob NOT NULL,
  `loads` int(10) unsigned NOT NULL default '0',
  `return_code` int(11) NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `Uprimary` (`domain`,`domain_sub`,`engine`,`Capp`,`Cmodule`,`Cid`,`Cid_md5`,`time_from`),
  UNIQUE KEY `Usecond` (`domain`,`domain_sub`,`engine`,`Cid_md5`,`time_from`),
  KEY `domain` (`domain`,`domain_sub`,`Capp`,`Cmodule`,`Cid`),
  KEY `ID_config` (`ID_config`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_config` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `domain` varchar(32) character set ascii NOT NULL default '',
  `domain_sub` varchar(64) character set ascii NOT NULL default '',
  `engine` varchar(4) character set ascii NOT NULL default '',
  `Capp` varchar(16) character set ascii collate ascii_bin NOT NULL default '',
  `Cmodule` varchar(50) character set ascii NOT NULL default '',
  `Cid` varchar(20) character set ascii NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_duration` int(10) unsigned NOT NULL default '0',
  `time_duration_need` int(10) unsigned default NULL,
  `time_duration_range_min` int(10) unsigned default NULL,
  `time_duration_range_max` int(10) unsigned default NULL,
  `time_use` int(10) unsigned default NULL,
  `time_optimalization` int(10) unsigned default NULL,
  `about` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`engine`,`Capp`,`Cmodule`,`Cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_debug` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `domain` varchar(32) character set ascii NOT NULL default '',
  `domain_sub` varchar(64) character set ascii NOT NULL default '',
  `engine` varchar(4) character set ascii NOT NULL default '',
  `Capp` varchar(16) character set ascii collate ascii_bin NOT NULL default '',
  `Cmodule` varchar(50) character set ascii NOT NULL default '',
  `Cid` varchar(20) character set ascii NOT NULL default '',
  `fragments` int(10) unsigned NOT NULL default '0',
  `time_from` int(10) unsigned NOT NULL default '0',
  `time_duration` int(10) unsigned NOT NULL default '0',
  `loads` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`engine`,`Capp`,`Cmodule`,`Cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- version=5.0

CREATE TABLE `/*db_name*/`.`/*addon*/_sql` (
  `ID` char(32) character set ascii NOT NULL default '',
  `cache_duration` time NOT NULL,
  `datetime_executed` datetime default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

