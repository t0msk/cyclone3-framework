-- db_h=stats
-- db_name=TOM
-- app=a100
-- version 5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_ticket` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `domain` varchar(64) character set ascii NOT NULL default '',
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `emails` varchar(255) character set ascii default NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`domain`,`name`),
  KEY `SEL_0` (`status`,`datetime_create`,`emails`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `domain` (`domain`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_ticket_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `domain` varchar(64) character set ascii NOT NULL default '',
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `emails` varchar(255) character set ascii default NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_ticket_event` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_ticket` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `cvml` text NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `SEL_0` (`ID_ticket`,`status`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`),
  KEY `status` (`status`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_ircbot_msg` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `message` varchar(255) character set ascii NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `status` (`status`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_h=main
-- version 5.0

CREATE TABLE `/*db_name*/`.`/*app*/_master` (
  `ID` bigint(20) unsigned NOT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `timestamp` decimal(20,6) unsigned NOT NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

