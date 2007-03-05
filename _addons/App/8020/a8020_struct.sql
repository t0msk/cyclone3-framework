-- db_name=TOM
-- app=a8020

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_mail` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDre` int(10) unsigned default NULL,
  `domain` varchar(32) default NULL,
  `sendtime` int(10) unsigned default NULL,
  `readtime` int(10) unsigned default NULL,
  `from_IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `from_flag` char(1) NOT NULL default '',
  `to_IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `to_flag` char(1) NOT NULL default '',
  `togroup_IDhash` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `togroup_flag` char(1) NOT NULL default '',
  `subject` varchar(250) NOT NULL default '',
  `body` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` varchar(3) NOT NULL default '',
  `arch` char(1) NOT NULL default 'N',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `IDhash_togroup` (`togroup_IDhash`),
  KEY `sendtime` (`sendtime`,`to_IDhash`),
  KEY `domain` (`domain`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_mail_arch` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDre` int(10) unsigned default NULL,
  `domain` varchar(100) default NULL,
  `sendtime` int(10) unsigned default NULL,
  `readtime` int(10) unsigned default NULL,
  `from_IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `from_flag` char(1) NOT NULL default '',
  `to_IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `to_flag` char(1) NOT NULL default '',
  `togroup_IDhash` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `togroup_flag` char(1) NOT NULL default '',
  `subject` varchar(250) NOT NULL default '',
  `body` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` varchar(3) NOT NULL default '',
  `arch` char(1) NOT NULL default 'Y',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `IDhash_togroup` (`togroup_IDhash`),
  KEY `sendtime` (`sendtime`,`to_IDhash`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

