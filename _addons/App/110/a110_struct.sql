-- db_h=stats
-- db_name=TOM
-- app=a110

-- reqdatetime=varchar(19) NOT NULL default ''
-- domain=varchar(32) NOT NULL default ''
-- domain_sub=varchar(64) NOT NULL default ''

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_load_day` (
  `reqdatetime` /*reqdatetime*/,
  `load_1min` float default NULL,
  `load_5min` float default NULL,
  `load_15min` float default NULL,
  PRIMARY KEY  (`reqdatetime`)
) TYPE=MyISAM;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_load_hour` (
  `reqdatetime` /*reqdatetime*/,
  `load_1min` float default NULL,
  `load_5min` float default NULL,
  `load_15min` float default NULL,
  PRIMARY KEY  (`reqdatetime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_load_min` (
  `reqtime` int(10) unsigned NOT NULL default '0',
  `reqdatetime` /*reqdatetime*/,
  `hostname` varchar(50) NOT NULL default '',
  `load_1min` float default NULL,
  `load_5min` float default NULL,
  `load_15min` float default NULL,
  `output_vmstat` tinytext NOT NULL,
  `output_psaux` text NOT NULL,
  PRIMARY KEY  (`reqdatetime`,`hostname`),
  KEY `reqtime` (`reqtime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_mdl_log` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `reqtime` int(10) unsigned NOT NULL default '0',
  `reqdatetime` /*reqdatetime*/,
  `domain` /*domain*/,
  `domain_sub` /*domain_sub*/,
  `Ctype` varchar(8) NOT NULL default '',
  `Capp` varchar(16) binary NOT NULL default '',
  `Cmodule` varchar(50) NOT NULL default '',
  `load_proc` float NOT NULL default '0',
  `load_req` float NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  KEY `reqdatetime` (`reqdatetime`),
  KEY `domain` (`domain`,`domain_sub`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_obsolete_log` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `time_created` int(10) unsigned NOT NULL default '0',
  `type` varchar(20) NOT NULL default '',
  `call_filename` varchar(100) NOT NULL default '',
  `call_line` int(10) unsigned NOT NULL default '0',
  `func_filename` varchar(100) NOT NULL default '',
  `func_line` int(10) unsigned NOT NULL default '0',
  `func` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------
-- version=5.0

CREATE TABLE `/*db_name*/`.`/*app*/_sitemap` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `url` varchar(200) NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `lastmod` varchar(30) NOT NULL default '',
  `changefreq` varchar(20) NOT NULL default '',
  `requests` bigint(20) unsigned NOT NULL default '0',
  `weight` float NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`url`)
) TYPE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- version=5.0

CREATE TABLE `/*db_name*/`.`/*app*/_sitemap_day` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `url` varchar(200) NOT NULL default '',
  `date_create` date NOT NULL,
  `lastmod` varchar(30) NOT NULL default '',
  `changefreq` varchar(20) NOT NULL default '',
  `requests` bigint(20) unsigned NOT NULL default '0',
  `weight` float NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`url`,`date_create`)
) TYPE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_webclick_log` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` /*domain*/,
  `domain_sub` /*domain_sub*/,
  `TID` varchar(25) NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `x` int(10) NOT NULL default '0',
  `y` int(10) unsigned NOT NULL default '0',
  `logged` char(1) NOT NULL default 'N',
  `IDuser` varchar(8) binary NOT NULL default '',
  PRIMARY KEY  (`ID`),
  KEY `domain` (`domain`,`domain_sub`),
  KEY `domain_2` (`domain`,`domain_sub`,`TID`,`time_insert`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_weblog_day` (
  `reqdatetime` /*reqdatetime*/,
  `domain` /*domain*/,
  `domain_sub` /*domain_sub*/,
  `visits` int(10) unsigned NOT NULL default '0',
  `visits_all` int(10) unsigned NOT NULL default '0',
  `visits_direct` int(10) unsigned NOT NULL default '0',
  `visits_firstpage` int(10) unsigned NOT NULL default '0',
  `visits_failed` int(10) unsigned NOT NULL default '0',
  `IPs` int(10) unsigned NOT NULL default '0',
  `IDhashs` int(10) unsigned NOT NULL default '0',
  `IDhashs_return` int(10) unsigned NOT NULL default '0',
  `IDsessions` int(10) unsigned NOT NULL default '0',
  `load_proc` float unsigned NOT NULL default '0',
  `load_req` float unsigned NOT NULL default '0',
  PRIMARY KEY  (`reqdatetime`,`domain`,`domain_sub`),
  KEY `reqdatetime` (`reqdatetime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_weblog_hour` (
  `reqdatetime` /*reqdatetime*/,
  `domain` /*domain*/,
  `domain_sub` /*domain_sub*/,
  `visits` int(10) unsigned NOT NULL default '0',
  `visits_all` int(10) unsigned NOT NULL default '0',
  `visits_direct` int(10) unsigned NOT NULL default '0',
  `visits_firstpage` int(10) unsigned NOT NULL default '0',
  `visits_failed` int(10) unsigned NOT NULL default '0',
  `IPs` int(10) unsigned NOT NULL default '0',
  `IDhashs` int(10) unsigned NOT NULL default '0',
  `IDhashs_return` int(10) unsigned NOT NULL default '0',
  `IDsessions` int(10) unsigned NOT NULL default '0',
  `load_proc` float unsigned NOT NULL default '0',
  `load_req` float unsigned NOT NULL default '0',
  PRIMARY KEY  (`reqdatetime`,`domain`,`domain_sub`),
  KEY `reqdatetime` (`reqdatetime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_weblog_min` (
  `reqdatetime` /*reqdatetime*/,
  `domain` /*domain*/,
  `domain_sub` /*domain_sub*/,
  `visits` int(10) unsigned NOT NULL default '0',
  `visits_all` int(10) unsigned NOT NULL default '0',
  `visits_direct` int(10) unsigned NOT NULL default '0',
  `visits_firstpage` int(10) unsigned NOT NULL default '0',
  `IPs` int(10) unsigned NOT NULL default '0',
  `IDhashs` int(10) unsigned NOT NULL default '0',
  `IDsessions` int(10) unsigned NOT NULL default '0',
  `load_proc` float unsigned NOT NULL default '0',
  `load_req` float unsigned NOT NULL default '0',
  `load_proc_max` float unsigned NOT NULL default '0',
  `load_req_max` float unsigned NOT NULL default '0',
  PRIMARY KEY  (`reqdatetime`,`domain`,`domain_sub`),
  KEY `reqdatetime` (`reqdatetime`)
) TYPE=MyISAM;

-- --------------------------------------------------------
-- version=5.0

CREATE TABLE `/*db_name*/`.`/*app*/_weblog_rqs` (
  `page_code` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `page_code_referer` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `HTTP_unique_ID` varchar(24) character set ascii collate ascii_bin NOT NULL default '',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `reqdatetime` varchar(50) character set ascii NOT NULL default '',
  `reqtype` char(1) character set ascii collate ascii_bin default NULL,
  `host` varchar(50) character set ascii NOT NULL default '',
  `domain` varchar(100) character set ascii NOT NULL default '',
  `domain_sub` varchar(150) character set ascii NOT NULL default '',
  `IP` varchar(50) character set ascii NOT NULL default '',
  `IDhash` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `IDsession` varchar(32) character set ascii collate ascii_bin NOT NULL default '',
  `logged` char(1) character set ascii NOT NULL default 'N',
  `USRM_flag` char(1) character set ascii collate ascii_bin NOT NULL default '',
  `query_string` varchar(255) character set ascii collate ascii_bin NOT NULL default '',
  `query_TID` varchar(25) character set ascii collate ascii_bin NOT NULL default '',
  `query_URL` varchar(255) character set ascii collate ascii_bin NOT NULL default '',
  `referer` varchar(255) character set ascii collate ascii_bin NOT NULL default '',
  `referer_SE` varchar(100) character set ascii default NULL,
  `user_agent` varchar(250) character set ascii collate ascii_bin NOT NULL default '',
  `user_agent_name` varchar(50) character set ascii collate ascii_bin default NULL,
  `load_proc` float unsigned NOT NULL default '0',
  `load_req` float unsigned NOT NULL default '0',
  `result` varchar(10) character set ascii NOT NULL default '',
  `lng` char(2) character set ascii NOT NULL default '',
  `active` char(1) character set ascii NOT NULL default 'N',
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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_weblog_week` (
  `reqdatetime` /*reqdatetime*/,
  `domain` /*domain*/,
  `domain_sub` /*domain_sub*/,
  `visits` int(10) unsigned NOT NULL default '0',
  `visits_all` int(10) unsigned NOT NULL default '0',
  `visits_direct` int(10) unsigned NOT NULL default '0',
  `visits_firstpage` int(10) unsigned NOT NULL default '0',
  `visits_failed` int(10) unsigned NOT NULL default '0',
  `IPs` int(10) unsigned NOT NULL default '0',
  `IDhashs` int(10) unsigned NOT NULL default '0',
  `IDhashs_return` int(10) unsigned NOT NULL default '0',
  `IDsessions` int(10) unsigned NOT NULL default '0',
  `load_proc` float unsigned NOT NULL default '0',
  `load_req` float unsigned NOT NULL default '0',
  PRIMARY KEY  (`reqdatetime`,`domain`,`domain_sub`),
  KEY `reqdatetime` (`reqdatetime`)
) TYPE=MyISAM;
