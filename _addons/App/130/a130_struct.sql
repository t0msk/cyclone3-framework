-- db_h=main
-- db_name=TOM
-- app=a130
-- version=4.1

-- --------------------------------------------------
-- version=5.0

CREATE TABLE `/*db_name*/`.`/*app*/_received` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `rectime` int(10) unsigned NOT NULL default '0',
  `from_name` varchar(50) NOT NULL,
  `from_email` varchar(50) character set ascii NOT NULL,
  `to_name` varchar(50) NOT NULL,
  `to_email` varchar(50) character set ascii NOT NULL,
  `subject` varchar(255) character set ascii NOT NULL,
  `body` blob NOT NULL,
  `lng` char(2) character set ascii NOT NULL,
  `active` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `subject` (`subject`),
  KEY `rectime` (`rectime`),
  KEY `from_email` (`from_email`),
  KEY `active` (`active`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

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
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `ID_md5` (`ID_md5`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

