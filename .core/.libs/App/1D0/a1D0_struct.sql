-- db_h=main
-- db_name=TOM
-- app=a1D0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_imports` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDimport` int(10) unsigned NOT NULL default '0',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_use` int(10) unsigned NOT NULL default '0',
  `uses` int(10) unsigned NOT NULL default '0',
  `import` longtext NOT NULL,
  PRIMARY KEY  (`ID`),
  KEY `IDimport` (`IDimport`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_manager` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
  `name` varchar(50) NOT NULL default '',
  `URI` varchar(255) character set utf8 collate utf8_bin NOT NULL default '',
  `dtime_refresh` varchar(100) NOT NULL default 'min:* hour:* wday:* mday:*',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_start` int(10) unsigned NOT NULL default '0',
  `time_end` int(10) unsigned default NULL,
  `time_use` int(10) unsigned NOT NULL default '0',
  `time_next` int(10) unsigned NOT NULL default '0',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`name`),
  KEY `active` (`active`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
