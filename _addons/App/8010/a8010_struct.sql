-- db_name=TOM
-- app=a8010

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_cache` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `c_categories` varchar(200) NOT NULL default '',
  `c_from` int(11) NOT NULL default '0',
  `c_to` int(11) NOT NULL default '0',
  `c_max` int(11) NOT NULL default '0',
  `cvml_data` longtext NOT NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `Uprimary` (`domain`,`domain_sub`,`c_categories`,`c_from`,`c_to`,`c_max`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDuser` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `IDuser_email` varchar(128) default NULL,
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_change` int(10) unsigned NOT NULL default '0',
  `time_use` int(10) unsigned default NULL,
  `personalize` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `IDuser` (`IDuser`,`IDuser_email`,`domain`,`domain_sub`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
