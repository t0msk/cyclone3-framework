-- db_h=main
-- db_name=TOM
-- app=a130
-- version=4.1

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_received` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `rectime` int(10) unsigned NOT NULL default '0',
  `from_name` varchar(50) NOT NULL default '',
  `from_email` varchar(50) NOT NULL default '',
  `to_name` varchar(50) NOT NULL default '',
  `to_email` varchar(255) NOT NULL default '',
  `body` longtext NOT NULL,
  `lng` varchar(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_send` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `ID_md5` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `sendtime` int(10) unsigned NOT NULL default '0',
  `priority` tinyint(4) NOT NULL default '0',
  `from_name` varchar(20) NOT NULL default '',
  `from_email` varchar(50) NOT NULL default '',
  `from_host` varchar(50) NOT NULL default '',
  `from_service` varchar(20) NOT NULL default '',
  `to_name` varchar(50) NOT NULL default '',
  `to_email` varchar(255) NOT NULL default '',
  `to_cc` varchar(250) NOT NULL default '',
  `to_bcc` varchar(250) NOT NULL default '',
  `body` longtext NOT NULL,
  `lng` varchar(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `ID_md5` (`ID_md5`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_send_history` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `hash` varchar(32) NOT NULL default '',
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
  `IP` varchar(25) NOT NULL default '',
  `from_email` varchar(100) NOT NULL default '',
  `from_service` varchar(100) NOT NULL default '',
  `to_email` varchar(100) NOT NULL default '',
  `to_service` varchar(100) NOT NULL default '',
  `time_create` int(10) unsigned NOT NULL default '0',
  `cvml_message` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_services` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(150) NOT NULL default '',
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `email_count` int(10) unsigned NOT NULL default '0',
  `time_last` int(10) unsigned default NULL,
  `time_create` int(10) unsigned NOT NULL default '0',
  `time_change` int(10) unsigned default NULL,
  `cvml_data` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  `lng` varchar(3) NOT NULL default '',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `name` (`name`,`domain`,`domain_sub`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

