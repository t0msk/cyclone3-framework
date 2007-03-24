-- --------------------------------------------------------

CREATE DATABASE TOM;

USE TOM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `_config` (
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

CREATE TABLE IF NOT EXISTS `_tom3` (
  `var` varchar(100) NOT NULL default '0',
  `value` text NOT NULL,
  PRIMARY KEY  (`var`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `_url` (
  `hash` varchar(32) NOT NULL default '',
  `url` text NOT NULL,
  `inserttime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`hash`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a110_weblog_rqs` (
  `page_code` varchar(8) binary NOT NULL default '',
  `page_code_referer` varchar(8) binary NOT NULL default '',
  `HTTP_unique_ID` varchar(24) binary NOT NULL default '',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `reqdatetime` varchar(19) NOT NULL default '',
  `reqtype` char(1) binary default NULL,
  `host` varchar(50) NOT NULL default '',
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `IP` varchar(15) NOT NULL default '',
  `IDhash` varchar(8) binary NOT NULL default '',
  `IDsession` varchar(32) binary NOT NULL default '',
  `logged` char(1) NOT NULL default 'N',
  `USRM_flag` char(1) NOT NULL default '',
  `query_string` varchar(200) NOT NULL default '',
  `query_TID` varchar(25) NOT NULL default '',
  `query_URL` varchar(200) NOT NULL default '',
  `referer` varchar(200) NOT NULL default '',
  `referer_SE` varchar(100) default NULL,
  `user_agent` varchar(64) NOT NULL default '',
  `user_agent_name` varchar(50) default NULL,
  `load_proc` float unsigned NOT NULL default '0',
  `load_req` float unsigned NOT NULL default '0',
  `result` varchar(10) NOT NULL default '',
  `lng` char(2) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  KEY `reqdatetime` (`reqdatetime`),
  KEY `domain` (`domain`),
  KEY `domain_sub` (`domain_sub`),
  KEY `query_TID` (`query_TID`),
  KEY `page_code` (`page_code`),
  KEY `active` (`active`),
  KEY `IP` (`IP`),
  KEY `user_agent_name` (`user_agent_name`),
  KEY `IDhash` (`IDhash`),
  KEY `IDsession` (`IDsession`),
  KEY `referer_SE` (`referer_SE`),
  KEY `page_code_referer` (`page_code_referer`),
  KEY `HTTP_unique_ID` (`HTTP_unique_ID`),
  KEY `docasne` (`user_agent`,`IP`,`domain`,`reqdatetime`,`reqtime`),
  KEY `USRM_flag` (`USRM_flag`),
  KEY `lng` (`lng`),
  KEY `result` (`result`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a130_received` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `rectime` int(10) unsigned NOT NULL default '0',
  `from_name` varchar(50) NOT NULL default '',
  `from_email` varchar(50) NOT NULL default '',
  `to_name` varchar(50) NOT NULL default '',
  `to_email` varchar(255) NOT NULL default '',
  `body` longtext NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a130_send` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `ID_md5` varchar(32) binary NOT NULL default '',
  `sendtime` int(10) unsigned NOT NULL default '0',
  `priority` tinyint(4) NOT NULL default '0',
  `from_name` varchar(20) NOT NULL default '',
  `from_email` varchar(50) NOT NULL default '',
  `from_host` varchar(50) NOT NULL default '',
  `from_service` varchar(20) NOT NULL default '',
  `to_name` varchar(50) NOT NULL default '',
  `to_email` varchar(255) NOT NULL default '',
  `to_cc` varchar(250) NOT NULL default '',
  `to_bcc` varchar(250) NOT NULL default '',
  `body` longtext NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `ID_md5` (`ID_md5`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a150_cache` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_config` int(10) unsigned NOT NULL default '0',
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
  `engine` varchar(4) NOT NULL default '',
  `Capp` varchar(16) binary NOT NULL default '',
  `Cmodule` varchar(50) NOT NULL default '',
  `Cid` varchar(20) NOT NULL default '',
  `Cid_md5` varchar(32) binary NOT NULL default '',
  `C_id_sub` varchar(50) NOT NULL default '',
  `C_xsgn` varchar(50) NOT NULL default '',
  `C_xlng` char(3) NOT NULL default '',
  `time_from` int(10) unsigned NOT NULL default '0',
  `time_duration` int(10) unsigned NOT NULL default '0',
  `time_to` int(10) unsigned NOT NULL default '0',
  `body` mediumblob NOT NULL,
  `loads` int(10) unsigned NOT NULL default '0',
  `return_code` int(11) NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `Uprimary` (`domain`,`domain_sub`,`engine`,`Capp`,`Cmodule`,`Cid`,`Cid_md5`,`time_from`),
  UNIQUE KEY `Usecond` (`domain`,`domain_sub`,`engine`,`Cid_md5`,`time_from`),
  KEY `domain` (`domain`,`domain_sub`,`Capp`,`Cmodule`,`Cid`),
  KEY `ID_config` (`ID_config`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a150_config` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
  `engine` varchar(4) NOT NULL default '',
  `Capp` varchar(16) binary NOT NULL default '',
  `Cmodule` varchar(50) NOT NULL default '',
  `Cid` varchar(20) NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_duration` int(10) unsigned NOT NULL default '0',
  `time_duration_need` int(10) unsigned default NULL,
  `time_duration_range_min` int(10) unsigned default NULL,
  `time_duration_range_max` int(10) unsigned default NULL,
  `time_use` int(10) unsigned default NULL,
  `time_optimalization` int(10) unsigned default NULL,
  `about` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`engine`,`Capp`,`Cmodule`,`Cid`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a1B0_banned` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(64) default NULL,
  `domain_sub` varchar(64) default NULL,
  `IDmessage` int(10) unsigned NOT NULL default '0',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_start` int(10) unsigned NOT NULL default '0',
  `time_end` int(10) unsigned default NULL,
  `time_use` int(10) unsigned default NULL,
  `Atype` varchar(16) binary NOT NULL default '',
  `Awhat` varchar(16) binary NOT NULL default '',
  `Awhat_action` varchar(100) binary NOT NULL default '',
  `Btype` varchar(5) NOT NULL default '',
  `Bwho` varchar(64) binary NOT NULL default '',
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  `banned` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `time_start` (`time_start`,`Atype`,`Awhat`,`Btype`,`Bwho`,`lng`,`domain`,`domain_sub`,`Awhat_action`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a1D0_imports` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDimport` int(10) unsigned NOT NULL default '0',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_use` int(10) unsigned NOT NULL default '0',
  `uses` int(10) unsigned NOT NULL default '0',
  `import` longtext NOT NULL,
  PRIMARY KEY  (`ID`),
  KEY `IDimport` (`IDimport`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a300_users` (
  `IDhash` varchar(8) binary NOT NULL default '',
  `login` varchar(20) NOT NULL default '',
  `pass` varchar(20) binary NOT NULL default '',
  `pass_md5` varchar(32) binary NOT NULL default '',
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
  `lng` char(3) default NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`),
  KEY `login` (`login`),
  KEY `pass_md5` (`pass_md5`),
  KEY `host` (`host`),
  KEY `lng` (`lng`),
  KEY `active` (`active`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a410` (
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
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`,`starttime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `a8010_users` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDuser` varchar(8) binary NOT NULL default '',
  `IDuser_email` varchar(60) default NULL,
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_change` int(10) unsigned NOT NULL default '0',
  `time_use` int(10) unsigned default NULL,
  `personalize` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `IDuser` (`IDuser`,`IDuser_email`,`domain`,`domain_sub`)
) TYPE=MyISAM;

