
-- app=a540
-- version=4.1

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` int(9) unsigned zerofill NOT NULL auto_increment,
  `ID_dir` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `name` tinytext NOT NULL,
  `comment` text NOT NULL,
  `hash` varchar(16) character set utf8 collate utf8_bin NOT NULL default '',
  `owner` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `size` int(12) unsigned NOT NULL default '0',
  `mime` varchar(50) character set ascii NOT NULL default '',
  `metadata` text NOT NULL,
  `time` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `active` char(1) character set ascii NOT NULL default 'N',
  `lng` char(2) character set ascii NOT NULL default '',
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_dir` (
  `ID` int(9) unsigned zerofill NOT NULL auto_increment,
  `ID_dir` varchar(32) character set ascii collate ascii_bin NOT NULL default '',
  `name` tinytext NOT NULL,
  `comment` mediumtext NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `active` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_visits` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `IDfile` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `IP` varchar(15) character set ascii NOT NULL default '',
  `dns` varchar(100) character set ascii default NULL,
  `time_insert` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
