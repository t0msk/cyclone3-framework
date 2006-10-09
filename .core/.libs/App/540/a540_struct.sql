
-- app=a540

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` int(9) unsigned zerofill NOT NULL auto_increment,
  `ID_dir` varchar(32) binary NOT NULL default '',
  `name` tinytext NOT NULL,
  `comment` text NOT NULL,
  `hash` varchar(16) binary NOT NULL default '',
  `owner` varchar(8) binary NOT NULL default '',
  `size` int(12) unsigned NOT NULL default '0',
  `mime` varchar(50) binary NOT NULL default '',
  `metadata` text NOT NULL,
  `time` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `active` char(1) NOT NULL default 'N',
  `lng` varchar(2) NOT NULL default '',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_dir` (
  `ID` int(9) unsigned zerofill NOT NULL auto_increment,
  `ID_dir` varchar(32) binary NOT NULL default '',
  `name` tinytext NOT NULL,
  `comment` mediumtext NOT NULL,
  `lng` varchar(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_visits` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `IDfile` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `IP` varchar(15) NOT NULL default '',
  `dns` varchar(100) default NULL,
  `time_insert` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;
