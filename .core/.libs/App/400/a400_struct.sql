-- app=a400

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDname` varchar(255) default NULL,
  `IDattrs` int(10) unsigned default NULL,
  `IDcategory` varchar(32) binary NOT NULL default '',
  `priority` varchar(17) binary NOT NULL default '00000000000000000',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `changetime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `title` varchar(100) NOT NULL default '',
  `subtitle` varchar(150) NOT NULL default '',
  `tiny` text NOT NULL,
  `full` text NOT NULL,
  `visits` mediumint(8) unsigned NOT NULL default '0',
  `link` int(10) unsigned NOT NULL default '0', -- linkovanie sa v praxi už nepoužíva
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL, -- starší ekvivalent pre cvml_data
--  `private` char(1) NOT NULL default 'N', -- určuje či je daný článok verejný alebo patrí do privátnej sekcie
  `lng` varchar(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  `arch` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`starttime`,`active`,`lng`,`arch`), -- toto je riadok ktory zabezpecuje unikatnost
  KEY `starttime` (`starttime`),
  KEY `priority` (`priority`),
  KEY `IDattrs` (`IDattrs`),
  KEY `IDcategory` (`IDcategory`),
  KEY `endtime` (`endtime`),
  KEY `IDname` (`IDname`),
  FULLTEXT KEY `MATSEARCH` (`full`,`tiny`,`subtitle`,`title`),
  FULLTEXT KEY `xrelated` (`xrelated`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_arch` (
  `ID` int(10) unsigned NOT NULL default '0',
  `IDname` varchar(255) default NULL,
  `IDattrs` int(10) unsigned default NULL,
  `IDcategory` varchar(32) binary NOT NULL default '',
  `priority` varchar(17) binary NOT NULL default '00000000000000000',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `changetime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `title` varchar(100) NOT NULL default '',
  `subtitle` varchar(150) NOT NULL default '',
  `tiny` tinytext NOT NULL,
  `full` text NOT NULL,
  `visits` mediumint(8) unsigned NOT NULL default '0',
  `link` int(10) unsigned NOT NULL default '0',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
--  `private` char(1) NOT NULL default 'N',
  `lng` varchar(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  `arch` char(1) NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`starttime`,`arch`,`active`,`lng`),
  KEY `starttime` (`starttime`),
  KEY `IDcategory` (`IDcategory`),
  KEY `IDattrs` (`IDattrs`),
  KEY `endtime` (`endtime`),
  KEY `lng` (`lng`),
  KEY `active` (`active`),
  KEY `IDname` (`IDname`),
  FULLTEXT KEY `MATSEARCH` (`full`,`tiny`,`subtitle`,`title`),
  FULLTEXT KEY `xrelated` (`xrelated`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_attrs` (
  `IDattrs` int(10) unsigned NOT NULL auto_increment,
  `visits_index7day` float NOT NULL default '0',
  `votes_count` int(10) unsigned NOT NULL default '0',
  `votes_points` int(11) NOT NULL default '0',
  PRIMARY KEY  (`IDattrs`),
  KEY `visits_index7day` (`visits_index7day`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_attrs_arch` (
  `IDattrs` int(10) unsigned NOT NULL auto_increment,
  `visits_index7day` float NOT NULL default '0',
  `votes_count` int(10) unsigned NOT NULL default '0',
  `votes_points` int(11) NOT NULL default '0',
  PRIMARY KEY  (`IDattrs`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_category` (
  `ID` varchar(32) binary NOT NULL default '',
  `IDname` varchar(255) default NULL,
  `name` varchar(100) binary NOT NULL default '',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` varchar(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`),
  KEY `name` (`name`),
  KEY `IDname` (`IDname`)
) TYPE=MyISAM;
