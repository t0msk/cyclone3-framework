
-- app=a120
-- version=4.1

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` smallint(5) unsigned NOT NULL auto_increment,
  `IDcategory` smallint(5) unsigned NOT NULL default '0',
  `IDtype` tinyint(4) unsigned NOT NULL default '0',
  `nickname` varchar(50) character set ascii NOT NULL default '',
  `fullname` varchar(250) character set utf8 collate utf8_bin NOT NULL default '',
  `email` varchar(60) character set ascii NOT NULL default '',
  `homepage` varchar(250) character set ascii NOT NULL default '',
  `xdata` text character set utf8 collate utf8_bin NOT NULL,
  `active` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_category` (
  `ID` smallint(5) unsigned NOT NULL auto_increment,
  `IDre` smallint(5) unsigned NOT NULL default '0',
  `name` varchar(100) character set utf8 collate utf8_bin NOT NULL default '',
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------