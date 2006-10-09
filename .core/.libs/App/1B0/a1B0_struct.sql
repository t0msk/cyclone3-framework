-- db_h=sys
-- db_name=TOM
-- app=a1B0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_banned` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(64) default NULL,
  `domain_sub` varchar(64) default NULL,
  `IDmessage` int(10) unsigned NOT NULL default '0',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_start` int(10) unsigned NOT NULL default '0',
  `time_end` int(10) unsigned default NULL,
  `time_use` int(10) unsigned default NULL,
  `Atype` varchar(16) character set utf8 collate utf8_bin NOT NULL default '',
  `Awhat` varchar(16) character set utf8 collate utf8_bin NOT NULL default '',
  `Awhat_action` varchar(100) character set utf8 collate utf8_bin NOT NULL default '',
  `Btype` varchar(5) NOT NULL default '',
  `Bwho` varchar(64) character set utf8 collate utf8_bin NOT NULL default '',
  `lng` varchar(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  `banned` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `time_start` (`time_start`,`Atype`,`Awhat`,`Btype`,`Bwho`,`lng`,`domain`,`domain_sub`,`Awhat_action`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_message` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `about` text NOT NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

