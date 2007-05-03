-- app=a410

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDlink` int(10) unsigned NOT NULL default '0',
  `IDcategory` int(10) unsigned NOT NULL default '0',
  `domain` varchar(100) default NULL,
  `title` varchar(100) NOT NULL default '',
  `tiny` varchar(250) NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `votes` int(10) unsigned NOT NULL default '0',
  `xrelated` text NOT NULL,
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`,`starttime`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_answer` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDquestion` int(10) unsigned NOT NULL default '0',
  `answer` varchar(250) NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `votes` int(10) unsigned NOT NULL default '0',
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`,`starttime`),
  UNIQUE KEY `answer` (`answer`,`IDquestion`,`starttime`,`lng`,`active`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 PACK_KEYS=0;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_category` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDcharindex` varchar(64) character set utf8 collate utf8_bin NOT NULL default '',
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `name` varchar(100) NOT NULL default '',
  `xrelated` text NOT NULL,
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`,`domain`,`domain_sub`),
  UNIQUE KEY `IDcharindex` (`IDcharindex`,`lng`,`active`,`domain`,`domain_sub`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_votes` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDquestion` int(10) unsigned NOT NULL default '0',
  `IDanswer` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `votetime` int(10) unsigned NOT NULL default '0',
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default '',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `IDuser` (`IDuser`,`IDquestion`,`lng`,`active`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

