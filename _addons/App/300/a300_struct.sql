-- db_h=main
-- db_name=TOM
-- app=a300

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_emailverify` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `hash` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `inserttime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDhash`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_online` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `IDsession` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `login` varchar(30) NOT NULL default '',
  `logged` char(1) NOT NULL default 'N',
  `host` varchar(50) character set utf8 collate utf8_bin NOT NULL default '',
  `host_sub` varchar(50) character set utf8 collate utf8_bin NOT NULL default '',
  `logtime` int(10) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `rqs` smallint(5) unsigned NOT NULL default '0',
  `IP` varchar(20) NOT NULL default '',
  `HTTP_USER_AGENT` text NOT NULL,
  `cookies` text NOT NULL,
  `xdata` text NOT NULL,
  `session` text NOT NULL,
  `active` char(1) NOT NULL default '',
  PRIMARY KEY  (`IDhash`),
  KEY `IDsession` (`IDsession`),
  KEY `login` (`login`),
  KEY `SEL0` (`IDhash`,`host`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_profile_def` (
  `host` varchar(50) NOT NULL default '',
  `variable` varchar(30) character set utf8 collate utf8_bin NOT NULL default '',
  `type_save` varchar(30) NOT NULL default '',
  `type_input` varchar(30) NOT NULL default '',
  `type_check` varchar(255) NOT NULL default '',
  `values` text NOT NULL,
  `necessary` char(1) NOT NULL default 'N',
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`variable`,`host`,`lng`,`active`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_roles` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDcharindex` varchar(64) character set utf8 collate utf8_bin NOT NULL default '',
  `domain` varchar(100) default NULL,
  `name` varchar(50) NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`starttime`,`lng`,`active`),
  UNIQUE KEY `IDcharindex` (`IDcharindex`,`starttime`,`lng`,`active`),
  KEY `domain` (`domain`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_shadow` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `host` varchar(50) character set utf8 collate utf8_bin NOT NULL default '',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `variable` varchar(50) NOT NULL default '',
  `value` text NOT NULL,
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`),
  KEY `lng` (`lng`),
  KEY `active` (`active`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `login` varchar(30) NOT NULL default '',
  `pass` varchar(20) character set utf8 collate utf8_bin NOT NULL default '',
  `pass_md5` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `autolog` char(1) NOT NULL default 'N',
  `host` varchar(50) NOT NULL default '',
  `regtime` int(10) unsigned NOT NULL default '0',
  `logtime` int(10) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `rqs` mediumint(8) unsigned NOT NULL default '0',
  `IPlast` varchar(20) NOT NULL default '',
  `profile` text NOT NULL,
  `profile_shadow` text NOT NULL,
  `cookies` text NOT NULL,
  `cookies_system` text NOT NULL,
  `lng` char(2) default NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`),
  KEY `login` (`login`),
  KEY `pass_md5` (`pass_md5`),
  KEY `host` (`host`),
  KEY `lng` (`lng`),
  KEY `active` (`active`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users_arch` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `login` varchar(30) NOT NULL default '',
  `pass` varchar(20) character set utf8 collate utf8_bin NOT NULL default '',
  `pass_md5` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `autolog` char(1) NOT NULL default 'N',
  `host` varchar(50) NOT NULL default '',
  `regtime` int(10) unsigned NOT NULL default '0',
  `logtime` int(10) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `rqs` mediumint(8) unsigned NOT NULL default '0',
  `IPlast` varchar(20) NOT NULL default '',
  `profile` text NOT NULL,
  `profile_shadow` text NOT NULL,
  `cookies` text NOT NULL,
  `cookies_system` text NOT NULL,
  `lng` char(2) default NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`),
  KEY `login` (`login`),
  KEY `pass_md5` (`pass_md5`),
  KEY `host` (`host`),
  KEY `lng` (`lng`),
  KEY `active` (`active`),
  KEY `rqs` (`rqs`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE ALGORITHM=UNDEFINED DEFINER=`TOM`@`localhost` SQL SECURITY DEFINER VIEW `/*db_name*/`.`/*app*/_user` AS (select `a300_users`.`IDhash` AS `IDhash`,`a300_users`.`login` AS `login`,`a300_users`.`pass` AS `pass`,`a300_users`.`pass_md5` AS `pass_md5`,`a300_users`.`autolog` AS `autolog`,`a300_users`.`host` AS `host`,`a300_users`.`regtime` AS `regtime`,`a300_users`.`logtime` AS `logtime`,`a300_users`.`reqtime` AS `reqtime`,`a300_users`.`rqs` AS `rqs`,`a300_users`.`IPlast` AS `IPlast`,`a300_users`.`profile` AS `profile`,`a300_users`.`profile_shadow` AS `profile_shadow`,`a300_users`.`cookies` AS `cookies`,`a300_users`.`cookies_system` AS `cookies_system`,`a300_users`.`lng` AS `lng`,`a300_users`.`active` AS `active` from `a300_users`) union all (select `a300_users_arch`.`IDhash` AS `IDhash`,`a300_users_arch`.`login` AS `login`,`a300_users_arch`.`pass` AS `pass`,`a300_users_arch`.`pass_md5` AS `pass_md5`,`a300_users_arch`.`autolog` AS `autolog`,`a300_users_arch`.`host` AS `host`,`a300_users_arch`.`regtime` AS `regtime`,`a300_users_arch`.`logtime` AS `logtime`,`a300_users_arch`.`reqtime` AS `reqtime`,`a300_users_arch`.`rqs` AS `rqs`,`a300_users_arch`.`IPlast` AS `IPlast`,`a300_users_arch`.`profile` AS `profile`,`a300_users_arch`.`profile_shadow` AS `profile_shadow`,`a300_users_arch`.`cookies` AS `cookies`,`a300_users_arch`.`cookies_system` AS `cookies_system`,`a300_users_arch`.`lng` AS `lng`,`a300_users_arch`.`active` AS `active` from `a300_users_arch`)

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users_attrs` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `favorities` text NOT NULL,
  `friends` text NOT NULL,
  `settings` text NOT NULL,
  `email` varchar(50) NOT NULL default '',
  `email_verify` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users_attrs_arch` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `favorities` text NOT NULL,
  `friends` text NOT NULL,
  `settings` text NOT NULL,
  `email` varchar(50) NOT NULL default '',
  `email_verify` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users_group` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `host` varchar(100) default NULL,
  `name` varchar(30) NOT NULL default '',
  `status` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`host`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users_rel_group` (
  `IDgroup` int(10) unsigned NOT NULL auto_increment,
  `IDuser` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  PRIMARY KEY  (`IDgroup`,`IDuser`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
