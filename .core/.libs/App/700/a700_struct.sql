-- db_name=TOM
-- app=a700

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_categories` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDowner` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `name` varchar(30) NOT NULL default '',
  `public` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `IDowner` (`IDowner`,`ID`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(100) default NULL,
  `IDcharindex` varchar(64) character set utf8 collate utf8_bin NOT NULL default '',
  `IDlink` int(10) unsigned default NULL,
  `IDowner` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `IDrule` int(10) unsigned default NULL,
  `IDgroup` int(10) unsigned default NULL,
  `owning` char(1) character set utf8 collate utf8_bin NOT NULL default 'D',
  `multiowning` char(1) NOT NULL default 'N',
  `createtime` int(10) unsigned NOT NULL default '0',
  `changetime` int(10) unsigned default NULL,
  `startplantime` int(10) unsigned default NULL,
  `endplantime` int(10) unsigned default NULL,
  `starttime` int(10) unsigned default NULL,
  `endtime` int(10) unsigned default NULL,
  `viewtime` int(10) unsigned default NULL,
  `fondtime` int(10) unsigned default NULL,
  `type` char(1) character set utf8 collate utf8_bin NOT NULL default '',
  `priority` tinyint(3) unsigned NOT NULL default '0',
  `progress` tinyint(3) unsigned NOT NULL default '0',
  `subject` varchar(250) NOT NULL default '',
  `description` text,
  `lng` varchar(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`active`,`lng`),
  UNIQUE KEY `UNILINE` (`IDcharindex`,`lng`,`active`),
  KEY `domain` (`domain`),
  KEY `IDcharindex` (`IDcharindex`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_activity` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `active` char(1) NOT NULL default 'N',
  KEY `IDtask` (`IDtask`),
  KEY `endtime` (`endtime`),
  KEY `IDuser` (`IDuser`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_categories` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDcategory` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDtask`,`IDcategory`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_dependencies` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDdependency` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDtask`,`IDdependency`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_groups` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDgroup` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `perm_view` char(1) NOT NULL default 'Y',
  `perm_edit` char(1) NOT NULL default 'N',
  `perm_del` char(1) NOT NULL default 'N',
  `perm_progress` char(1) NOT NULL default 'N',
  `perm_work` char(1) NOT NULL default 'N',
  `perm_finish` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDtask`,`IDgroup`,`starttime`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_related` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `App_ID` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `App_type` varchar(10) NOT NULL default '',
  `App_unique` varchar(50) NOT NULL default '',
  PRIMARY KEY  (`IDtask`,`App_ID`,`App_type`,`App_unique`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_sources` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDtask`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_status` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `endtime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDtask`,`IDuser`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_users` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `perm_view` char(1) NOT NULL default 'Y',
  `perm_edit` char(1) NOT NULL default 'N',
  `perm_del` char(1) NOT NULL default 'N',
  `perm_progress` char(1) NOT NULL default 'N',
  `perm_work` char(1) NOT NULL default 'N',
  `perm_finish` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDtask`,`IDuser`,`starttime`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_task_viewtimes` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `viewtime` int(10) unsigned NOT NULL default '0',
  KEY `IDtask` (`IDtask`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
