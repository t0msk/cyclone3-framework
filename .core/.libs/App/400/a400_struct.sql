-- app=a400
-- version=4.1

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDname` varchar(255) character set ascii collate ascii_bin default NULL,
  `IDattrs` int(10) unsigned default NULL,
  `IDcategory` varchar(32) character set ascii collate ascii_bin NOT NULL default '',
  `priority` varchar(17) character set ascii NOT NULL default '00000000000000000',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `changetime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `title` varchar(100) character set utf8 collate utf8_bin NOT NULL default '',
  `subtitle` varchar(150) character set utf8 collate utf8_bin NOT NULL default '',
  `tiny` text character set utf8 collate utf8_bin NOT NULL,
  `full` text character set utf8 collate utf8_bin NOT NULL,
  `visits` mediumint(8) unsigned NOT NULL default '0',
  `link` int(10) unsigned NOT NULL default '0', -- linkovanie sa v praxi už nepoužíva
  `xrelated` text character set utf8 collate utf8_bin NOT NULL,
  `xdata` text character set utf8 collate utf8_bin NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `private` char(1) character set ascii NOT NULL default 'N',
  `active` char(1) character set ascii NOT NULL default 'N',
  `arch` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`starttime`,`active`,`lng`,`arch`),
  KEY `starttime` (`starttime`),
  KEY `priority` (`priority`),
  KEY `IDattrs` (`IDattrs`),
  KEY `IDcategory` (`IDcategory`),
  KEY `endtime` (`endtime`),
  KEY `IDname` (`IDname`),
  FULLTEXT KEY `MATSEARCH` (`full`,`tiny`,`subtitle`,`title`),
  FULLTEXT KEY `xrelated` (`xrelated`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_arch` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDname` varchar(255) character set ascii collate ascii_bin default NULL,
  `IDattrs` int(10) unsigned default NULL,
  `IDcategory` varchar(32) character set ascii collate ascii_bin NOT NULL default '',
  `priority` varchar(17) character set ascii NOT NULL default '00000000000000000',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `changetime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `title` varchar(100) character set utf8 collate utf8_bin NOT NULL default '',
  `subtitle` varchar(150) character set utf8 collate utf8_bin NOT NULL default '',
  `tiny` text character set utf8 collate utf8_bin NOT NULL,
  `full` text character set utf8 collate utf8_bin NOT NULL,
  `visits` mediumint(8) unsigned NOT NULL default '0',
  `link` int(10) unsigned NOT NULL default '0', -- linkovanie sa v praxi už nepoužíva
  `xrelated` text character set utf8 collate utf8_bin NOT NULL,
  `xdata` text character set utf8 collate utf8_bin NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `private` char(1) character set ascii NOT NULL default 'N',
  `active` char(1) character set ascii NOT NULL default 'N',
  `arch` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`starttime`,`active`,`lng`,`arch`),
  KEY `starttime` (`starttime`),
  KEY `priority` (`priority`),
  KEY `IDattrs` (`IDattrs`),
  KEY `IDcategory` (`IDcategory`),
  KEY `endtime` (`endtime`),
  KEY `IDname` (`IDname`),
  FULLTEXT KEY `MATSEARCH` (`full`,`tiny`,`subtitle`,`title`),
  FULLTEXT KEY `xrelated` (`xrelated`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_attrs` (
  `IDattrs` int(10) unsigned NOT NULL auto_increment,
  `visits_index7day` float NOT NULL default '0',
  `votes_count` int(10) unsigned NOT NULL default '0',
  `votes_points` int(11) NOT NULL default '0',
  PRIMARY KEY  (`IDattrs`),
  KEY `visits_index7day` (`visits_index7day`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_attrs_arch` (
  `IDattrs` int(10) unsigned NOT NULL auto_increment,
  `visits_index7day` float NOT NULL default '0',
  `votes_count` int(10) unsigned NOT NULL default '0',
  `votes_points` int(11) NOT NULL default '0',
  PRIMARY KEY  (`IDattrs`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_category` (
  `ID` varchar(32) character set ascii collate ascii_bin NOT NULL default '',
  `IDname` varchar(255) character set ascii collate ascii_bin default NULL,
  `name` varchar(100) character set utf8 collate utf8_bin NOT NULL default '',
  `xrelated` text character set utf8 collate utf8_bin NOT NULL,
  `xdata` text character set utf8 collate utf8_bin NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `active` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`),
  KEY `name` (`name`),
  KEY `IDname` (`IDname`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
