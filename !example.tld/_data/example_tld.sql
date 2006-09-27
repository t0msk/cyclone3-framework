CREATE DATABASE example_tld;

USE example_tld;

-- --------------------------------------------------------

-- 
-- Table structure for table `_config`
-- 

CREATE TABLE `_config` (
  `namespace` varchar(10) NOT NULL default '',
  `variable` varchar(50) binary NOT NULL default '',
  `linkT` char(1) NOT NULL default '',
  `value` text NOT NULL,
  `type` varchar(5) binary NOT NULL default '',
  `cache` smallint(5) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `about` varchar(100) default NULL,
  PRIMARY KEY  (`variable`,`type`,`namespace`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `_tom3`
-- 

CREATE TABLE `_tom3` (
  `var` varchar(100) NOT NULL default '0',
  `value` text NOT NULL,
  PRIMARY KEY  (`var`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a120`
-- 

CREATE TABLE `a120` (
  `ID` smallint(5) unsigned NOT NULL auto_increment,
  `IDcategory` smallint(5) unsigned NOT NULL default '0',
  `IDtype` tinyint(4) unsigned NOT NULL default '0',
  `nickname` varchar(50) NOT NULL default '',
  `fullname` varchar(250) binary NOT NULL default '',
  `xdata` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a120_category`
-- 

CREATE TABLE `a120_category` (
  `ID` smallint(5) unsigned NOT NULL auto_increment,
  `IDre` smallint(5) unsigned NOT NULL default '0',
  `name` varchar(100) binary NOT NULL default '',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a400`
-- 

CREATE TABLE `a400` (
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
  `link` int(10) unsigned NOT NULL default '0',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  `arch` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`starttime`,`active`,`lng`,`arch`),
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

-- 
-- Table structure for table `a400_arch`
-- 

CREATE TABLE `a400_arch` (
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
  `lng` char(3) NOT NULL default '',
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

-- 
-- Table structure for table `a400_attrs`
-- 

CREATE TABLE `a400_attrs` (
  `IDattrs` int(10) unsigned NOT NULL auto_increment,
  `visits_index7day` float NOT NULL default '0',
  PRIMARY KEY  (`IDattrs`),
  KEY `visits_index7day` (`visits_index7day`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a400_attrs_arch`
-- 

CREATE TABLE `a400_attrs_arch` (
  `IDattrs` int(10) unsigned NOT NULL auto_increment,
  `visits_index7day` float NOT NULL default '0',
  PRIMARY KEY  (`IDattrs`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a400_category`
-- 

CREATE TABLE `a400_category` (
  `ID` varchar(32) binary NOT NULL default '',
  `IDname` varchar(255) default NULL,
  `name` varchar(100) binary NOT NULL default '',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`),
  KEY `name` (`name`),
  KEY `IDname` (`IDname`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a400_visits`
-- 

CREATE TABLE `a400_visits` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `IDarticle` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a500`
-- 

CREATE TABLE `a500` (
  `ID` int(7) unsigned zerofill NOT NULL default '0000000',
  `IDattrs` int(7) unsigned NOT NULL default '0',
  `hash` varchar(16) binary NOT NULL default '',
  `IDcategory` varchar(32) binary NOT NULL default '',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `format` char(1) NOT NULL default '',
  `changetime` int(10) unsigned NOT NULL default '0',
  `size` varchar(9) NOT NULL default '',
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default '',
  PRIMARY KEY  (`ID`,`format`,`lng`,`active`),
  KEY `SEL` (`ID`,`IDcategory`,`format`,`lng`,`active`),
  KEY `hash` (`hash`),
  KEY `IDattrs` (`IDattrs`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a500_attrs`
-- 

CREATE TABLE `a500_attrs` (
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
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `IDcategory` (`IDcategory`),
  KEY `starttime` (`starttime`),
  KEY `endtime` (`endtime`),
  KEY `IDname` (`IDname`),
  FULLTEXT KEY `keywords` (`keywords`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a500_category`
-- 

CREATE TABLE `a500_category` (
  `ID` varchar(32) binary NOT NULL default '',
  `IDname` varchar(255) default NULL,
  `name` varchar(100) binary NOT NULL default '',
  `photos` int(11) unsigned NOT NULL default '0',
  `photos_sub` int(10) unsigned NOT NULL default '0',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default '',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `name` (`name`),
  KEY `IDname` (`IDname`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a540`
-- 

CREATE TABLE `a540` (
  `ID` int(9) unsigned zerofill NOT NULL auto_increment,
  `ID_dir` varchar(32) binary NOT NULL default '',
  `name` tinytext NOT NULL,
  `comment` tinyint(4) NOT NULL default '0',
  `hash` varchar(16) binary NOT NULL default '',
  `owner` varchar(8) binary NOT NULL default '',
  `size` int(12) unsigned NOT NULL default '0',
  `mime` varchar(50) binary NOT NULL default '',
  `metadata` text NOT NULL,
  `time` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `active` char(1) NOT NULL default 'N',
  `lng` char(3) NOT NULL default '',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a540_dir`
-- 

CREATE TABLE `a540_dir` (
  `ID` int(9) unsigned zerofill NOT NULL auto_increment,
  `ID_dir` varchar(32) binary NOT NULL default '',
  `name` tinytext NOT NULL,
  `comment` mediumtext NOT NULL,
  `lng` char(3) NOT NULL default '',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;
