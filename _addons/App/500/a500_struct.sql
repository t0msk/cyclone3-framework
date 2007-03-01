
-- app=a500
-- version=4.1

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` int(7) unsigned zerofill NOT NULL default '0000000',
  `IDattrs` int(7) unsigned NOT NULL default '0',
  `hash` varchar(16) character set utf8 collate utf8_bin NOT NULL default '',
  `IDcategory` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `format` char(1) NOT NULL default '',
  `changetime` int(10) unsigned NOT NULL default '0',
  `size` varchar(9) NOT NULL default '',
  `lng` char(2) character set ascii NOT NULL default '',
  `active` char(1) character set ascii NOT NULL default '',
  PRIMARY KEY  (`ID`,`format`,`lng`,`active`),
  KEY `SEL` (`ID`,`IDcategory`,`format`,`lng`,`active`),
  KEY `hash` (`hash`),
  KEY `IDattrs` (`IDattrs`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_attrs` (
  `ID` int(7) unsigned zerofill NOT NULL auto_increment,
  `IDname` varchar(255) default NULL,
  `IDattrs` int(7) unsigned NOT NULL default '0',
  `IDcategory` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `visits` int(10) unsigned NOT NULL default '0',
  `priority` int(10) unsigned NOT NULL default '0',
  `about` varchar(250) NOT NULL default '',
  `keywords` text NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `active` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `IDcategory` (`IDcategory`),
  KEY `starttime` (`starttime`),
  KEY `endtime` (`endtime`),
  KEY `IDname` (`IDname`),
  FULLTEXT KEY `keywords` (`keywords`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_category` (
  `ID` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `IDname` varchar(200) character set ascii default NULL,
  `name` varchar(100) character set utf8 collate utf8_bin NOT NULL default '',
  `photos` int(11) unsigned NOT NULL default '0',
  `photos_sub` int(10) unsigned NOT NULL default '0',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `active` char(1) character set ascii NOT NULL default '',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `name` (`name`),
  KEY `IDname` (`IDname`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

