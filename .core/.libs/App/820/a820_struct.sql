
-- app=a820
-- version=4.1

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` varchar(48) binary NOT NULL default '',
  `IDattrs` int(10) unsigned NOT NULL default '0',
  `IDcategory` bigint(20) unsigned default NULL,
  `starttime` int(10) unsigned NOT NULL default '0',
  `createtime` int(10) unsigned NOT NULL default '0',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `name` varchar(100) binary NOT NULL default '',
  `about` varchar(100) default NULL,
  `type` char(1) NOT NULL default 'C', -- C=category F=forum
  `messages` smallint(5) unsigned NOT NULL default '0',
  `login_required` char(1) NOT NULL default 'N',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
  `IDowner` varchar(8) binary NOT NULL default '',
  `IDgroup` varchar(32) binary NOT NULL default '',
  `lng` char(2) character set ascii NOT NULL default '',
  `tactive` char(1) NOT NULL default 'N', -- keby si niekto spomenul na co je toto active, nech da vediet :)
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`),
  KEY `ID` (`ID`),
  KEY `IDattrs` (`IDattrs`),
  KEY `inserttime` (`inserttime`),
  KEY `name` (`name`),
  KEY `tactive` (`tactive`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_attrs` (
  `IDattrs` int(10) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`IDattrs`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_category` ( -- tabulka vytvorena podla vsetkeho podla DATA standardu
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `IDentity` bigint(20) unsigned NOT NULL default '0',
  `IDcharindex` varchar(64) binary NOT NULL default '',
  `name` varchar(54) NOT NULL default '',
  `time_create` int(10) unsigned NOT NULL default '0',
  `time_change` int(10) unsigned default NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  `cvml` text NOT NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`IDentity`,`lng`),
  UNIQUE KEY `UNI_1` (`IDcharindex`,`lng`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_msgs` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDre` int(10) unsigned NOT NULL default '0',
  `IDforum` varchar(48) binary NOT NULL default '0',
  `IDcategory` bigint(20) unsigned NOT NULL default '0',
  `from_name` varchar(20) binary NOT NULL default '',
  `from_IDhash` varchar(8) binary NOT NULL default '',
  `from_email` varchar(50) NOT NULL default '',
  `from_IP` varchar(20) NOT NULL default '',
  `email_reply` char(1) NOT NULL default 'N',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `title` varchar(50) NOT NULL default '',
  `msg` text NOT NULL,
  `authorized` char(1) NOT NULL default 'N',
  `lng` char(2) character set ascii NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `IDforum` (`IDforum`)
) TYPE=MyISAM;
