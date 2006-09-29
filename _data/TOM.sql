-- phpMyAdmin SQL Dump
-- version 2.6.4-pl4
-- http://www.phpmyadmin.net
-- 
-- Host: server1.webcom.sk
-- Generation Time: Sep 27, 2006 at 05:28 PM
-- Server version: 4.0.26
-- PHP Version: 4.4.4
-- 
-- Database: `TOM`
-- 

-- --------------------------------------------------------

CREATE DATABASE TOM;

USE TOM;

-- 
-- Table structure for table `_config`
-- 

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

-- 
-- Table structure for table `_layers`
-- 

CREATE TABLE IF NOT EXISTS `_layers` (
  `ID` varchar(16) binary NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `xdata` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`active`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `_tom3`
-- 

CREATE TABLE IF NOT EXISTS `_tom3` (
  `var` varchar(100) NOT NULL default '0',
  `value` text NOT NULL,
  PRIMARY KEY  (`var`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `_url`
-- 

CREATE TABLE IF NOT EXISTS `_url` (
  `hash` varchar(32) NOT NULL default '',
  `url` text NOT NULL,
  `inserttime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`hash`)
) TYPE=MyISAM;

-- --------------------------------------------------------




CREATE TABLE IF NOT EXISTS `a110_load_day` (
  `reqdatetime` varchar(50) NOT NULL default '',
  `load_1min` float NOT NULL default '0',
  `load_5min` float NOT NULL default '0',
  `load_15min` float NOT NULL default '0',
  PRIMARY KEY  (`reqdatetime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a110_load_hour`
-- 

CREATE TABLE IF NOT EXISTS `a110_load_hour` (
  `reqdatetime` varchar(50) NOT NULL default '',
  `load_1min` float NOT NULL default '0',
  `load_5min` float NOT NULL default '0',
  `load_15min` float NOT NULL default '0',
  PRIMARY KEY  (`reqdatetime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a110_load_min`
-- 

CREATE TABLE IF NOT EXISTS `a110_load_min` (
  `reqtime` int(10) unsigned NOT NULL default '0',
  `reqdatetime` varchar(50) NOT NULL default '',
  `hostname` varchar(50) NOT NULL default '',
  `load_1min` float NOT NULL default '0',
  `load_5min` float NOT NULL default '0',
  `load_15min` float NOT NULL default '0',
  `output_vmstat` tinytext NOT NULL,
  `output_psaux` text NOT NULL,
  PRIMARY KEY  (`reqdatetime`,`hostname`),
  KEY `reqtime` (`reqtime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a110_mdl_log`
-- 

CREATE TABLE IF NOT EXISTS `a110_mdl_log` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `reqtime` int(10) unsigned NOT NULL default '0',
  `reqdatetime` varchar(50) NOT NULL default '',
  `domain` varchar(32) default NULL,
  `domain_sub` varchar(64) default NULL,
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

-- 
-- Table structure for table `a110_obsolete_log`
-- 

CREATE TABLE IF NOT EXISTS `a110_obsolete_log` (
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

-- 
-- Table structure for table `a110_sitemap`
-- 

CREATE TABLE IF NOT EXISTS `a110_sitemap` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `url` varchar(200) NOT NULL default '',
  `time_create` int(10) unsigned NOT NULL default '0',
  `time_use` int(10) unsigned NOT NULL default '0',
  `time_generate` int(10) unsigned NOT NULL default '0',
  `lastmod` varchar(30) NOT NULL default '',
  `changefreq` varchar(20) NOT NULL default '',
  `requests` bigint(20) unsigned NOT NULL default '0',
  `weight` float NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`url`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a110_webclick_log`
-- 

CREATE TABLE IF NOT EXISTS `a110_webclick_log` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
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

-- 
-- Table structure for table `a110_weblog_day`
-- 

CREATE TABLE IF NOT EXISTS `a110_weblog_day` (
  `reqdatetime` varchar(50) NOT NULL default '',
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
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

-- 
-- Table structure for table `a110_weblog_hour`
-- 

CREATE TABLE IF NOT EXISTS `a110_weblog_hour` (
  `reqdatetime` varchar(50) NOT NULL default '',
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
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

-- 
-- Table structure for table `a110_weblog_min`
-- 

CREATE TABLE IF NOT EXISTS `a110_weblog_min` (
  `reqdatetime` varchar(50) NOT NULL default '',
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
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

-- 
-- Table structure for table `a110_weblog_rqs`
-- 

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

-- 
-- Table structure for table `a110_weblog_week`
-- 

CREATE TABLE IF NOT EXISTS `a110_weblog_week` (
  `reqdatetime` varchar(50) NOT NULL default '',
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
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

-- 
-- Table structure for table `a130_received`
-- 

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

-- 
-- Table structure for table `a130_send`
-- 

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

-- 
-- Table structure for table `a130_send_history`
-- 

CREATE TABLE IF NOT EXISTS `a130_send_history` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `hash` varchar(32) NOT NULL default '',
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
  `IP` varchar(25) NOT NULL default '',
  `from_email` varchar(100) NOT NULL default '',
  `from_service` varchar(100) NOT NULL default '',
  `to_email` varchar(100) NOT NULL default '',
  `to_service` varchar(100) NOT NULL default '',
  `time_create` int(10) unsigned NOT NULL default '0',
  `cvml_message` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a130_services`
-- 

CREATE TABLE IF NOT EXISTS `a130_services` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(150) NOT NULL default '',
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `email_count` int(10) unsigned NOT NULL default '0',
  `time_last` int(10) unsigned default NULL,
  `time_create` int(10) unsigned NOT NULL default '0',
  `time_change` int(10) unsigned default NULL,
  `cvml_data` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  `lng` char(3) NOT NULL default '',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `name` (`name`,`domain`,`domain_sub`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a150_cache`
-- 

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

-- 
-- Table structure for table `a150_config`
-- 

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

-- 
-- Table structure for table `a150_debug`
-- 

CREATE TABLE IF NOT EXISTS `a150_debug` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
  `engine` varchar(4) NOT NULL default '',
  `Capp` varchar(16) binary NOT NULL default '',
  `Cmodule` varchar(50) NOT NULL default '',
  `Cid` varchar(20) NOT NULL default '',
  `fragments` int(10) unsigned NOT NULL default '0',
  `time_from` int(10) unsigned NOT NULL default '0',
  `time_duration` int(10) unsigned NOT NULL default '0',
  `loads` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`engine`,`Capp`,`Cmodule`,`Cid`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a1A0_domainconfig`
-- 

CREATE TABLE IF NOT EXISTS `a1A0_domainconfig` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(32) default NULL,
  `domain_sub` varchar(64) default NULL,
  `engine` varchar(8) NOT NULL default '',
  `name` varchar(100) binary NOT NULL default '',
  `value` text NOT NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`engine`,`name`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a1B0_banned`
-- 

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

-- 
-- Table structure for table `a1B0_message`
-- 

CREATE TABLE IF NOT EXISTS `a1B0_message` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `about` text NOT NULL,
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a1D0_imports`
-- 

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

-- 
-- Table structure for table `a1D0_manager`
-- 

CREATE TABLE IF NOT EXISTS `a1D0_manager` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(50) NOT NULL default '',
  `domain_sub` varchar(150) NOT NULL default '',
  `name` varchar(50) NOT NULL default '',
  `URI` varchar(255) binary NOT NULL default '',
  `dtime_refresh` varchar(100) NOT NULL default 'min:* hour:* wday:* mday:*',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `time_start` int(10) unsigned NOT NULL default '0',
  `time_end` int(10) unsigned default NULL,
  `time_use` int(10) unsigned NOT NULL default '0',
  `time_next` int(10) unsigned NOT NULL default '0',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `domain` (`domain`,`domain_sub`,`name`),
  KEY `active` (`active`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_emailverify`
-- 

CREATE TABLE IF NOT EXISTS `a300_emailverify` (
  `IDhash` varchar(8) binary NOT NULL default '',
  `hash` varchar(32) binary NOT NULL default '',
  `inserttime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDhash`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_groups`
-- 

CREATE TABLE IF NOT EXISTS `a300_groups` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDcharindex` varchar(32) binary NOT NULL default '',
  `domain` varchar(100) default NULL,
  `name` varchar(30) NOT NULL default '',
  `IDowner` varchar(8) binary NOT NULL default '',
  `createtime` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `data_cvml` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`,`starttime`),
  UNIQUE KEY `IDcharindex` (`IDcharindex`,`lng`,`active`,`starttime`),
  UNIQUE KEY `name` (`domain`,`name`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_groups_users`
-- 

CREATE TABLE IF NOT EXISTS `a300_groups_users` (
  `IDuser` varchar(8) binary NOT NULL default '',
  `IDgroup` int(10) unsigned NOT NULL default '0',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDuser`,`IDgroup`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_online`
-- 

CREATE TABLE IF NOT EXISTS `a300_online` (
  `IDhash` varchar(8) binary NOT NULL default '',
  `IDsession` varchar(32) binary NOT NULL default '',
  `login` varchar(20) NOT NULL default '',
  `logged` char(1) NOT NULL default 'N',
  `host` varchar(50) binary NOT NULL default '',
  `host_sub` varchar(50) binary NOT NULL default '',
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
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_profile_def`
-- 

CREATE TABLE IF NOT EXISTS `a300_profile_def` (
  `host` varchar(50) NOT NULL default '',
  `variable` varchar(30) binary NOT NULL default '',
  `type_save` varchar(30) NOT NULL default '',
  `type_input` varchar(30) NOT NULL default '',
  `type_check` varchar(255) NOT NULL default '',
  `values` text NOT NULL,
  `necessary` char(1) NOT NULL default 'N',
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`variable`,`host`,`lng`,`active`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_roles`
-- 

CREATE TABLE IF NOT EXISTS `a300_roles` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDcharindex` varchar(64) binary NOT NULL default '',
  `domain` varchar(100) default NULL,
  `name` varchar(50) NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`starttime`,`lng`,`active`),
  UNIQUE KEY `IDcharindex` (`IDcharindex`,`starttime`,`lng`,`active`),
  KEY `domain` (`domain`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_shadow`
-- 

CREATE TABLE IF NOT EXISTS `a300_shadow` (
  `IDhash` varchar(8) binary NOT NULL default '',
  `host` varchar(50) binary NOT NULL default '',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `variable` varchar(50) NOT NULL default '',
  `value` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`),
  KEY `lng` (`lng`),
  KEY `active` (`active`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_users`
-- 

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

-- 
-- Table structure for table `a300_users_arch`
-- 

CREATE TABLE IF NOT EXISTS `a300_users_arch` (
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
  KEY `active` (`active`),
  KEY `rqs` (`rqs`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_users_attrs`
-- 

CREATE TABLE IF NOT EXISTS `a300_users_attrs` (
  `IDhash` varchar(8) binary NOT NULL default '',
  `favorities` text NOT NULL,
  `friends` text NOT NULL,
  `settings` text NOT NULL,
  `email` varchar(50) NOT NULL default '',
  `email_verify` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a300_users_attrs_arch`
-- 

CREATE TABLE IF NOT EXISTS `a300_users_attrs_arch` (
  `IDhash` varchar(8) binary NOT NULL default '',
  `favorities` text NOT NULL,
  `friends` text NOT NULL,
  `settings` text NOT NULL,
  `email` varchar(50) NOT NULL default '',
  `email_verify` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDhash`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a400_category`
-- 

CREATE TABLE IF NOT EXISTS `a400_category` (
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

CREATE TABLE IF NOT EXISTS `a400_visits` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `IDarticle` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a401`
-- 

CREATE TABLE IF NOT EXISTS `a401` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDattrs` int(10) unsigned default NULL,
  `IDcategory` varchar(32) binary NOT NULL default '',
  `priority` varchar(17) binary NOT NULL default '00000000000000000',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `changetime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `title` varchar(100) binary NOT NULL default '',
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
  KEY `ID` (`ID`),
  KEY `IDattrs` (`IDattrs`),
  KEY `IDcategory` (`IDcategory`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a410`
-- 

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

-- 
-- Table structure for table `a410_answer`
-- 

CREATE TABLE IF NOT EXISTS `a410_answer` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDquestion` int(10) unsigned NOT NULL default '0',
  `answer` varchar(250) NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `IDauthor` smallint(5) unsigned NOT NULL default '0',
  `IDeditor` smallint(5) unsigned NOT NULL default '0',
  `votes` int(10) unsigned NOT NULL default '0',
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`,`starttime`),
  UNIQUE KEY `answer` (`answer`,`IDquestion`,`starttime`,`lng`,`active`)
) TYPE=MyISAM PACK_KEYS=0;

-- --------------------------------------------------------

-- 
-- Table structure for table `a410_category`
-- 

CREATE TABLE IF NOT EXISTS `a410_category` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDcharindex` varchar(64) binary NOT NULL default '',
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `name` varchar(100) NOT NULL default '',
  `xrelated` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`,`domain`,`domain_sub`),
  UNIQUE KEY `IDcharindex` (`IDcharindex`,`lng`,`active`,`domain`,`domain_sub`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a410_votes`
-- 

CREATE TABLE IF NOT EXISTS `a410_votes` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDquestion` int(10) unsigned NOT NULL default '0',
  `IDanswer` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `votetime` int(10) unsigned NOT NULL default '0',
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default '',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `IDuser` (`IDuser`,`IDquestion`,`lng`,`active`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a500`
-- 

CREATE TABLE IF NOT EXISTS `a500` (
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

CREATE TABLE IF NOT EXISTS `a500_attrs` (
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

CREATE TABLE IF NOT EXISTS `a500_category` (
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

CREATE TABLE IF NOT EXISTS `a540` (
  `ID` int(9) unsigned zerofill NOT NULL auto_increment,
  `ID_dir` varchar(32) binary NOT NULL default '',
  `name` tinytext NOT NULL,
  `comment` text NOT NULL,
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

CREATE TABLE IF NOT EXISTS `a540_dir` (
  `ID` int(9) unsigned zerofill NOT NULL auto_increment,
  `ID_dir` varchar(32) binary NOT NULL default '',
  `name` tinytext NOT NULL,
  `comment` mediumtext NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a540_visits`
-- 

CREATE TABLE IF NOT EXISTS `a540_visits` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `IDfile` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `IP` varchar(15) NOT NULL default '',
  `dns` varchar(100) default NULL,
  `time_insert` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_categories`
-- 

CREATE TABLE IF NOT EXISTS `a700_categories` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDowner` varchar(8) binary NOT NULL default '',
  `name` varchar(30) NOT NULL default '',
  `public` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `IDowner` (`IDowner`,`ID`,`name`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task`
-- 

CREATE TABLE IF NOT EXISTS `a700_task` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(100) default NULL,
  `IDcharindex` varchar(64) binary NOT NULL default '',
  `IDlink` int(10) unsigned default NULL,
  `IDowner` varchar(8) binary NOT NULL default '',
  `IDrule` int(10) unsigned default NULL,
  `IDgroup` int(10) unsigned default NULL,
  `owning` char(1) binary NOT NULL default 'D',
  `multiowning` char(1) NOT NULL default 'N',
  `createtime` int(10) unsigned NOT NULL default '0',
  `changetime` int(10) unsigned default NULL,
  `startplantime` int(10) unsigned default NULL,
  `endplantime` int(10) unsigned default NULL,
  `starttime` int(10) unsigned default NULL,
  `endtime` int(10) unsigned default NULL,
  `viewtime` int(10) unsigned default NULL,
  `fondtime` int(10) unsigned default NULL,
  `type` char(1) binary NOT NULL default '',
  `priority` tinyint(3) unsigned NOT NULL default '0',
  `progress` tinyint(3) unsigned NOT NULL default '0',
  `subject` varchar(250) NOT NULL default '',
  `description` text,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`active`,`lng`),
  UNIQUE KEY `UNILINE` (`IDcharindex`,`lng`,`active`),
  KEY `domain` (`domain`),
  KEY `IDcharindex` (`IDcharindex`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_activity`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_activity` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `active` char(1) NOT NULL default 'N',
  KEY `IDtask` (`IDtask`),
  KEY `endtime` (`endtime`),
  KEY `IDuser` (`IDuser`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_categories`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_categories` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDcategory` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDtask`,`IDcategory`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_dependencies`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_dependencies` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDdependency` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDtask`,`IDdependency`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_groups`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_groups` (
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
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_related`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_related` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `App_ID` varchar(32) binary NOT NULL default '',
  `App_type` varchar(10) NOT NULL default '',
  `App_unique` varchar(50) NOT NULL default '',
  PRIMARY KEY  (`IDtask`,`App_ID`,`App_type`,`App_unique`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_sources`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_sources` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDtask`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_status`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_status` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `endtime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`IDtask`,`IDuser`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_users`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_users` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned default NULL,
  `perm_view` char(1) NOT NULL default 'Y',
  `perm_edit` char(1) NOT NULL default 'N',
  `perm_del` char(1) NOT NULL default 'N',
  `perm_progress` char(1) NOT NULL default 'N',
  `perm_work` char(1) NOT NULL default 'N',
  `perm_finish` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`IDtask`,`IDuser`,`starttime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a700_task_viewtimes`
-- 

CREATE TABLE IF NOT EXISTS `a700_task_viewtimes` (
  `IDtask` int(10) unsigned NOT NULL default '0',
  `IDuser` varchar(8) binary NOT NULL default '',
  `viewtime` int(10) unsigned NOT NULL default '0',
  KEY `IDtask` (`IDtask`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a8010_cache`
-- 

CREATE TABLE IF NOT EXISTS `a8010_cache` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `domain` varchar(32) NOT NULL default '',
  `domain_sub` varchar(64) NOT NULL default '',
  `time_insert` int(10) unsigned NOT NULL default '0',
  `c_categories` varchar(200) NOT NULL default '',
  `c_from` int(11) NOT NULL default '0',
  `c_to` int(11) NOT NULL default '0',
  `c_max` int(11) NOT NULL default '0',
  `cvml_data` longtext NOT NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `Uprimary` (`domain`,`domain_sub`,`c_categories`,`c_from`,`c_to`,`c_max`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a8010_users`
-- 

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

-- --------------------------------------------------------

-- 
-- Table structure for table `a8020_mail`
-- 

CREATE TABLE IF NOT EXISTS `a8020_mail` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDre` int(10) unsigned default NULL,
  `domain` varchar(32) default NULL,
  `sendtime` int(10) unsigned default NULL,
  `readtime` int(10) unsigned default NULL,
  `from_IDhash` varchar(8) binary NOT NULL default '',
  `from_flag` char(1) NOT NULL default '',
  `to_IDhash` varchar(8) binary NOT NULL default '',
  `to_flag` char(1) NOT NULL default '',
  `togroup_IDhash` varchar(32) binary NOT NULL default '',
  `togroup_flag` char(1) NOT NULL default '',
  `subject` varchar(250) NOT NULL default '',
  `body` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `arch` char(1) NOT NULL default 'N',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `IDhash_togroup` (`togroup_IDhash`),
  KEY `sendtime` (`sendtime`,`to_IDhash`),
  KEY `domain` (`domain`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a8020_mail_arch`
-- 

CREATE TABLE IF NOT EXISTS `a8020_mail_arch` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDre` int(10) unsigned default NULL,
  `domain` varchar(100) default NULL,
  `sendtime` int(10) unsigned default NULL,
  `readtime` int(10) unsigned default NULL,
  `from_IDhash` varchar(8) binary NOT NULL default '',
  `from_flag` char(1) NOT NULL default '',
  `to_IDhash` varchar(8) binary NOT NULL default '',
  `to_flag` char(1) NOT NULL default '',
  `togroup_IDhash` varchar(32) binary NOT NULL default '',
  `togroup_flag` char(1) NOT NULL default '',
  `subject` varchar(250) NOT NULL default '',
  `body` text NOT NULL,
  `xdata` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `arch` char(1) NOT NULL default 'Y',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`,`active`),
  KEY `IDhash_togroup` (`togroup_IDhash`),
  KEY `sendtime` (`sendtime`,`to_IDhash`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a820`
-- 

CREATE TABLE IF NOT EXISTS `a820` (
  `ID` varchar(48) binary NOT NULL default '',
  `IDattrs` int(10) unsigned NOT NULL default '0',
  `IDcategory` bigint(20) unsigned default NULL,
  `starttime` int(10) unsigned NOT NULL default '0',
  `createtime` int(10) unsigned NOT NULL default '0',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `lasttime` int(10) unsigned NOT NULL default '0',
  `name` varchar(100) binary NOT NULL default '',
  `about` varchar(100) default NULL,
  `type` char(1) NOT NULL default 'C',
  `messages` smallint(5) unsigned NOT NULL default '0',
  `login_required` char(1) NOT NULL default 'N',
  `xrelated` text NOT NULL,
  `xdata` text NOT NULL,
  `IDowner` varchar(8) binary NOT NULL default '',
  `IDgroup` varchar(32) binary NOT NULL default '',
  `lng` char(3) NOT NULL default '',
  `tactive` char(1) NOT NULL default 'N',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`lng`),
  KEY `ID` (`ID`),
  KEY `IDattrs` (`IDattrs`),
  KEY `inserttime` (`inserttime`),
  KEY `name` (`name`),
  KEY `tactive` (`tactive`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a820_attrs`
-- 

CREATE TABLE IF NOT EXISTS `a820_attrs` (
  `IDattrs` int(10) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`IDattrs`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a820_msgs`
-- 

CREATE TABLE IF NOT EXISTS `a820_msgs` (
  `ID` int(10) unsigned NOT NULL auto_increment,
  `IDre` int(10) unsigned NOT NULL default '0',
  `IDforum` varchar(48) binary NOT NULL default '0',
  `IDcategory` bigint(20) unsigned NOT NULL default '0',
  `from_name` varchar(20) binary NOT NULL default '',
  `from_IDhash` varchar(8) binary NOT NULL default '',
  `from_email` varchar(50) NOT NULL default '',
  `from_IP` varchar(20) NOT NULL default '',
  `email_reply` char(1) NOT NULL default 'N',
  `inserttime` int(10) unsigned NOT NULL default '0',
  `title` varchar(50) NOT NULL default '',
  `msg` text NOT NULL,
  `authorized` char(1) NOT NULL default 'N',
  `lng` char(3) NOT NULL default '0',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `IDforum` (`IDforum`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `a900_bnn`
-- 

CREATE TABLE IF NOT EXISTS `a900_bnn` (
  `host` varchar(64) NOT NULL default '',
  `section` varchar(32) NOT NULL default '',
  `position` varchar(32) NOT NULL default '',
  `type` varchar(50) NOT NULL default '',
  `action` varchar(50) NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `time_use` int(10) unsigned NOT NULL default '0',
  `code` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`host`,`section`,`position`,`type`,`starttime`,`lng`,`active`,`action`),
  KEY `active` (`active`),
  KEY `lng` (`lng`),
  KEY `host` (`host`),
  KEY `section` (`section`),
  KEY `type` (`type`),
  KEY `starttime` (`starttime`)
) TYPE=MyISAM;

-- --------------------------------------------------------

-- 
-- Table structure for table `ac00`
-- 

CREATE TABLE IF NOT EXISTS `ac00` (
  `ID` int(11) NOT NULL default '0',
  `word` varchar(100) NOT NULL default '',
  `lng` char(3) NOT NULL default '',
  KEY `ID` (`ID`),
  KEY `word` (`word`),
  KEY `lng` (`lng`)
) TYPE=MyISAM;






