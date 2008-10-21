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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
-- version=5.0

CREATE TABLE `/*db_name*/`.`/*app*/_users` (
  `IDhash` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `login` varchar(64) character set utf8 collate utf8_bin NOT NULL,
  `pass` varchar(20) character set utf8 collate utf8_bin NOT NULL,
  `pass_md5` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `autolog` char(1) character set ascii NOT NULL default 'N',
  `host` varchar(50) character set ascii NOT NULL,
  `regtime` int(10) unsigned NOT NULL default '0',
  `logtime` int(10) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `rqs` mediumint(8) unsigned NOT NULL default '0',
  `IPlast` varchar(20) character set ascii NOT NULL,
  `profile` text character set utf8 collate utf8_bin NOT NULL,
  `profile_shadow` text character set utf8 collate utf8_bin NOT NULL,
  `cookies` text character set utf8 collate utf8_bin NOT NULL,
  `cookies_system` text character set utf8 collate utf8_bin NOT NULL,
  `lng` char(2) character set ascii default NULL,
  `active` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`),
  KEY `login` (`login`),
  KEY `pass_md5` (`pass_md5`),
  KEY `host` (`host`),
  KEY `lng` (`lng`),
  KEY `active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- version=5.0

CREATE TABLE `/*db_name*/`.`/*app*/_users_arch` (
  `IDhash` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `login` varchar(64) character set utf8 collate utf8_bin NOT NULL,
  `pass` varchar(20) character set utf8 collate utf8_bin NOT NULL,
  `pass_md5` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `autolog` char(1) character set ascii NOT NULL default 'N',
  `host` varchar(50) character set ascii NOT NULL,
  `regtime` int(10) unsigned NOT NULL default '0',
  `logtime` int(10) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `rqs` mediumint(8) unsigned NOT NULL default '0',
  `IPlast` varchar(20) character set ascii NOT NULL,
  `profile` text character set utf8 collate utf8_bin NOT NULL,
  `profile_shadow` text character set utf8 collate utf8_bin NOT NULL,
  `cookies` text character set utf8 collate utf8_bin NOT NULL,
  `cookies_system` text character set utf8 collate utf8_bin NOT NULL,
  `lng` char(2) character set ascii default NULL,
  `active` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`),
  KEY `login` (`login`),
  KEY `pass_md5` (`pass_md5`),
  KEY `host` (`host`),
  KEY `lng` (`lng`),
  KEY `active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users_attrs` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `favorities` text NOT NULL,
  `friends` text NOT NULL,
  `settings` text NOT NULL,
  `email` varchar(128) NOT NULL default '',
  `email_verify` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_users_attrs_arch` (
  `IDhash` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `favorities` text NOT NULL,
  `friends` text NOT NULL,
  `settings` text NOT NULL,
  `email` varchar(128) NOT NULL default '',
  `email_verify` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
-- version=5.0

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_user` AS
(
	SELECT * FROM `/*db_name*/`.`/*app*/_users`
)
UNION ALL
(
	SELECT * FROM `/*db_name*/`.`/*app*/_users_arch`
)

-- --------------------------------------------------------
-- version=5.0

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_user_view_login` AS
(
	SELECT * FROM `/*db_name*/`.`/*app*/_users`
	WHERE login NOT LIKE ''
)

-- --------------------------------------------------------

