
-- app=a500

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` int(7) unsigned zerofill NOT NULL default '0000000',
  `IDattrs` int(7) unsigned NOT NULL default '0',
  `hash` varchar(16) binary NOT NULL default '',
  `IDcategory` varchar(32) binary NOT NULL default '',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `format` char(1) NOT NULL default '',
  `changetime` int(10) unsigned NOT NULL default '0',
  `size` varchar(9) NOT NULL default '',
  `lng` varchar(2) NOT NULL default '',
  `active` char(1) NOT NULL default '',
  PRIMARY KEY  (`ID`,`format`,`lng`,`active`),
  KEY `SEL` (`ID`,`IDcategory`,`format`,`lng`,`active`),
  KEY `hash` (`hash`),
  KEY `IDattrs` (`IDattrs`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_attrs` (
  `ID` int(7) unsigned zerofill NOT NULL auto_increment,
  `IDname` varchar(255) default NULL,
  `IDattrs` int(7) unsigned NOT NULL default '0',
  `IDcategory` varchar(32) binary NOT NULL default '',
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `visits` int(10) unsigned NOT NULL default '0',
  `priority` int(10) unsigned NOT NULL default '0',
  `about` varchar(250) NOT NULL default '',
  `keywords` text NOT NULL,
  `lng` varchar(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `IDcategory` (`IDcategory`),
  KEY `starttime` (`starttime`),
  KEY `endtime` (`endtime`),
  KEY `IDname` (`IDname`),
  FULLTEXT KEY `keywords` (`keywords`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_category` (
  `ID` varchar(32) binary NOT NULL default '',
  `IDname` varchar(255) default NULL,
  `name` varchar(100) binary NOT NULL default '',
  `photos` int(11) unsigned NOT NULL default '0',
  `photos_sub` int(10) unsigned NOT NULL default '0',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` varchar(2) NOT NULL default '',
  `active` char(1) NOT NULL default '',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `name` (`name`),
  KEY `IDname` (`IDname`)
) TYPE=MyISAM;
