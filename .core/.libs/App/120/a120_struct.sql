
-- app=a120

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` smallint(5) unsigned NOT NULL auto_increment,
  `IDcategory` smallint(5) unsigned NOT NULL default '0',
  `IDtype` tinyint(4) unsigned NOT NULL default '0',
  `nickname` varchar(50) NOT NULL default '',
  `fullname` varchar(250) binary NOT NULL default '',
  `xdata` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_category` (
  `ID` smallint(5) unsigned NOT NULL auto_increment,
  `IDre` smallint(5) unsigned NOT NULL default '0',
  `name` varchar(100) binary NOT NULL default '',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;