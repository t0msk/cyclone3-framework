-- db_h=main
-- addon=a301
-- version=5.0

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user` (
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `secure_hash` varchar(16) character set ascii collate ascii_bin default NULL,
  `login` varchar(64) character set ascii default NULL,
  `pass` varchar(256) character set ascii collate ascii_bin default NULL,
  `autolog` char(1) character set ascii NOT NULL default 'N',
  `hostname` varchar(64) character set ascii NOT NULL,
  `datetime_register` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `datetime_last_login` datetime default NULL,
  `requests_all` smallint(5) unsigned NOT NULL default '0',
  `email` varchar(64) character set ascii default NULL, -- internal email
  `email_verified` char(1) character set ascii NOT NULL default 'N',
  `saved_cookies` blob NOT NULL,
  `saved_session` blob NOT NULL,
  `perm_roles_override` blob,
  `ref_facebook` varchar(20) character set ascii default NULL,
  `ref_deviceid` varchar(64) character set ascii default NULL,
  `ref_ID` varchar(64) character set ascii default NULL, -- external reference
  `src_data` longtext character set utf8 collate utf8_unicode_ci default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID_user`),
  UNIQUE KEY `UNI_0` (`hostname`,`login`),
  KEY `secure_hash` (`secure_hash`),
  KEY `login` (`login`),
  KEY `hostname` (`hostname`,`email`),
  KEY `email` (`email`),
  KEY `ref_facebook` (`ref_facebook`),
  KEY `ref_deviceid` (`ref_deviceid`),
  KEY `ref_ID` (`ref_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_session` (
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `ID_session` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `IP` varchar(15) NOT NULL default '',
  `datetime_session_begin` datetime NOT NULL,
  `datetime_session_begin_msec` int(10) NOT NULL default '0',
  `datetime_session_end` datetime NOT NULL,
  `requests_all` smallint(5) unsigned NOT NULL default '0',
  `saved_cookies` blob NOT NULL,
  `saved_session` blob NOT NULL,
  PRIMARY KEY  (`ID_user`,`datetime_session_begin`,`datetime_session_begin_msec`),
  KEY `datetime_session_begin` (`datetime_session_begin`),
  KEY `ID_session` (`ID_session`),
  KEY `IP` (`IP`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_inactive` (
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `secure_hash` varchar(16) character set ascii collate ascii_bin default NULL,
  `login` varchar(64) character set ascii default NULL,
  `pass` varchar(256) character set ascii collate ascii_bin default NULL,
  `autolog` char(1) character set ascii NOT NULL default 'N',
  `hostname` varchar(64) character set ascii NOT NULL,
  `datetime_register` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `datetime_last_login` datetime default NULL,
  `requests_all` smallint(5) unsigned NOT NULL default '0',
  `email` varchar(64) character set ascii default NULL, -- internal email
  `email_verified` char(1) character set ascii NOT NULL default 'N',
  `saved_cookies` blob NOT NULL,
  `saved_session` blob NOT NULL,
  `perm_roles_override` blob,
  `ref_facebook` varchar(20) character set ascii default NULL,
  `ref_deviceid` varchar(64) character set ascii default NULL,
  `ref_ID` varchar(64) character set ascii default NULL, -- external reference
  `src_data` longtext character set utf8 collate utf8_unicode_ci default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID_user`),
  KEY `SEL_0` (`datetime_last_login`,`requests_all`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8; -- don't change to MyISAM

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_emailverify` (
  `ID_user` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `email` varchar(64) character set ascii default NULL,
  `datetime_register` datetime NOT NULL,
  `hash` varchar(16) character set ascii collate ascii_bin default NULL,
  PRIMARY KEY  (`ID_user`),
  UNIQUE KEY `UNI_0` (`email`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_journal` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel _user.ID_user
  `datetime_create` datetime NOT NULL,
  `datetime_journal` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `note` text character set utf8 collate utf8_unicode_ci,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_journal_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `datetime_journal` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `note` text character set utf8 collate utf8_unicode_ci,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_profile` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel _user.ID_user
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `firstname` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `middlename` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `surname` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `maidenname` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `name_prefix` varchar(64) character set utf8 collate utf8_bin default NULL,
  `name_suffix` varchar(16) character set utf8 collate utf8_bin default NULL,
  `gender` char(1) character set ascii default NULL,
  `date_birth` date default NULL,
  `PIN` varchar(64) character set utf8 collate utf8_bin default NULL,
  `country_code` char(3) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `county` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- kraj
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- okres
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `education` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `phone` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_mobile` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_office` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_home` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `email_public` varchar(64) character set ascii default NULL,
  `email_office` varchar(64) character set ascii default NULL,
  `address_current` text character set utf8 collate utf8_unicode_ci,
  `address_postal` text character set utf8 collate utf8_unicode_ci,
  `phys_weight` int(10) unsigned default NULL,
  `phys_height` int(10) unsigned default NULL,
  `idcard_num` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `passport_num` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `bank_contact` text character set utf8 collate utf8_unicode_ci,
  `birth_place` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `birth_country_code` char(3) character set ascii default NULL,
  `about_me` text character set utf8 collate utf8_unicode_ci,
  `note` text character set utf8 collate utf8_unicode_ci,
  `rating_weight` decimal(2,2) default NULL,
  `web_push_data` text character set utf8 collate utf8_bin default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `SEL_0` (`surname`,`firstname`),
  KEY `firstname` (`firstname`),
  KEY `gender` (`gender`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_profile_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel _user.ID_user
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `firstname` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `middlename` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `surname` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `maidenname` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `name_prefix` varchar(64) character set utf8 collate utf8_bin default NULL,
  `name_suffix` varchar(16) character set utf8 collate utf8_bin default NULL,
  `gender` char(1) character set ascii default NULL,
  `date_birth` date default NULL,
  `PIN` varchar(64) character set utf8 collate utf8_bin default NULL,
  `country_code` char(3) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `county` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- kraj
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- okres
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `education` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `phone` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_mobile` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_office` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_home` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `email_public` varchar(64) character set ascii default NULL,
  `email_office` varchar(64) character set ascii default NULL,
  `address_current` text character set utf8 collate utf8_unicode_ci,
  `address_postal` text character set utf8 collate utf8_unicode_ci,
  `phys_weight` int(10) unsigned default NULL,
  `phys_height` int(10) unsigned default NULL,
  `idcard_num` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `passport_num` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `bank_contact` text character set utf8 collate utf8_unicode_ci,
  `birth_place` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `birth_country_code` char(3) character set ascii default NULL,
  `about_me` text character set utf8 collate utf8_unicode_ci,
  `note` text character set utf8 collate utf8_unicode_ci,
  `rating_weight` decimal(2,2) default NULL,
  `web_push_data` text character set utf8 collate utf8_bin default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_profile_h` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `datetime_valid` datetime NOT NULL, -- valid to this datetime
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `firstname` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `middlename` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `surname` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `maidenname` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `name_prefix` varchar(16) character set utf8 collate utf8_bin default NULL,
  `name_suffix` varchar(16) character set utf8 collate utf8_bin default NULL,
  `gender` char(1) character set ascii default NULL,
  `date_birth` date default NULL,
  `PIN` varchar(64) character set utf8 collate utf8_bin default NULL,
  `country_code` char(3) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `county` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- kraj
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- okres
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `education` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `phone` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_mobile` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_office` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_home` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `email_public` varchar(64) character set ascii default NULL,
  `email_office` varchar(64) character set ascii default NULL,
  `address_current` text character set utf8 collate utf8_unicode_ci,
  `address_postal` text character set utf8 collate utf8_unicode_ci,
  `phys_weight` int(10) unsigned default NULL,
  `phys_height` int(10) unsigned default NULL,
  `idcard_num` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `passport_num` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `bank_contact` text character set utf8 collate utf8_unicode_ci,
  `birth_place` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `about_me` text character set utf8 collate utf8_unicode_ci,
  `note` text character set utf8 collate utf8_unicode_ci,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_valid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_profile_metaindex` (
  `ID` bigint(20) unsigned NOT NULL, -- ref _product.ID
  `meta_section` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_value` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`meta_section`,`meta_variable`),
  KEY `SEL_0` (`meta_section`,`meta_variable`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE OR REPLACE VIEW `/*db_name*/`.`/*addon*/_user_profile_view` AS (
	SELECT
		
		`user`.hostname,
		`user`.ID_user,
      `user`.posix_owner,
		`user`.`login`,
		`user`.`email`,
		`user`.email_verified,
      `user`.datetime_register,
		YEAR(CURRENT_DATE()) - YEAR(user_profile.date_birth) - (RIGHT(CURRENT_DATE(),5) < RIGHT(user_profile.date_birth,5)) AS age,
		user_profile.*
		
	FROM
		`/*db_name*/`.`/*addon*/_user` AS `user`
	LEFT JOIN `/*db_name*/`.`/*addon*/_user_profile` AS user_profile ON
	(
		`user`.ID_user = user_profile.ID_entity
	)
)

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_profile_karma` (
  `ID_user` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel _user.ID_user
  `date_event` date NOT NULL,
  `karma` double default NULL,
  PRIMARY KEY  (`ID_user`,`date_event`),
  KEY `date_event` (`date_event`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_receipt` (
  `ID` varchar(256) character set utf8 collate utf8_bin NOT NULL,
  `ID_user` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel _user.ID_user
  `datetime_create` date NOT NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_profile_emo` ( -- experimental EMO characteristics
  `ID_user` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel _user.ID_user
  `date_event` date NOT NULL,
  `emo_sad` int(10) unsigned NOT NULL default '0',
  `emo_angry` int(10) unsigned NOT NULL default '0',
  `emo_confused` int(10) unsigned NOT NULL default '0',
  `emo_love` int(10) unsigned NOT NULL default '0',
  `emo_omg` int(10) unsigned NOT NULL default '0',
  `emo_smile` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID_user`,`date_event`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_online` (
  `ID_user` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `ID_session` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `domain` varchar(64) character set ascii NOT NULL,
  `logged` char(1) NOT NULL default 'N',
  `datetime_login` datetime NOT NULL,
  `datetime_request` datetime NOT NULL,
  `requests` smallint(5) unsigned NOT NULL default '0',
  `IP` varchar(15) NOT NULL default '',
  `_ga` varchar(64) character set ascii default NULL,
  `user_agent` varchar(200) NOT NULL default '',
  `cookies` blob NOT NULL,
  `session` blob NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID_user`),
  KEY `ID_session` (`ID_session`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE OR REPLACE VIEW `/*db_name*/`.`/*addon*/_user_online_view` AS (
	SELECT
		
		user_online.ID_session,
		user_online.logged,
		user_online.datetime_login,
		user_online.datetime_request,
		user_online.requests,
		user_online.IP,
		user_online.`domain`,
		user_online.user_agent,
		user_online.cookies,
		user_online.`session`,
		
		`user`.*
		
	FROM
		`/*db_name*/`.`/*addon*/_user_online` AS user_online
	LEFT JOIN `/*db_name*/`.`/*addon*/_user` AS `user` ON
	(
		`user`.ID_user = user_online.ID_user
	)
	
)

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_group` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `hostname` varchar(64) character set ascii NOT NULL default '',
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `perm_roles_override` blob,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  UNIQUE KEY `UNI_1` (`ID_charindex`),
  UNIQUE KEY `UNI_2` (`hostname`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_group_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `hostname` varchar(64) character set ascii NOT NULL default '',
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `perm_roles_override` blob,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_rel_group` (
  `ID_group` bigint(20) unsigned NOT NULL auto_increment, -- rel _user_group.ID_entity
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  PRIMARY KEY  (`ID_group`,`ID_user`),
  KEY `ID_user` (`ID_user`),
  KEY `ID_group` (`ID_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_user_rel_group_l` (
  `datetime_event` datetime NOT NULL default '0000-00-00 00:00:00',
  `ID_group` bigint(20) unsigned NOT NULL auto_increment,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `action` char(1) character set ascii NOT NULL default 'A', -- A (added)/R (removed)
  KEY `SEL_0` (`ID_user`,`datetime_event`),
  KEY `datetime_event` (`datetime_event`),
  KEY `ID_group` (`ID_group`),
  KEY `ID_user` (`ID_user`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_contact_lng` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- ref _user.ID_user
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_contact_lng_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_contact_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `alias_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `hostname` varchar(64) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_contact_cat_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `alias_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `hostname` varchar(64) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_contact_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _contact_cat.ID
  `priority_A` tinyint(3) unsigned default NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  PRIMARY KEY  (`ID_category`,`ID_user`),
  KEY `ID_user` (`ID_user`),
  KEY `SEL_0` (`ID_category`,`priority_A`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*addon*/_contact_rel_cat_l` (
  `datetime_event` datetime NOT NULL default '0000-00-00 00:00:00',
  `ID_category` bigint(20) unsigned NOT NULL auto_increment,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `action` char(1) character set ascii NOT NULL default 'A', -- A (added)/R (removed)
  KEY `SEL_0` (`ID_user`,`datetime_event`),
  KEY `datetime_event` (`datetime_event`),
  KEY `ID_category` (`ID_category`),
  KEY `ID_user` (`ID_user`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=local

CREATE TABLE `/*db_name*/`.`/*addon*/_ACL_user` ( -- table is stored where addon defined in r_prefix
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set ascii collate ascii_bin NOT NULL default '', -- rel _user.ID_user
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `datetime_evidence` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `roles` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `perm_R` char(1) character set ascii NOT NULL default 'N',
  `perm_W` char(1) character set ascii NOT NULL default 'N',
  `perm_X` char(1) character set ascii NOT NULL default 'N',
  `perm_1` char(1) character set ascii NOT NULL default 'N',
  `perm_2` char(1) character set ascii NOT NULL default 'N',
  `perm_3` char(1) character set ascii NOT NULL default 'N',
  `perm_4` char(1) character set ascii NOT NULL default 'N',
  `perm_roles_override` blob,
  `note` text character set utf8 collate utf8_unicode_ci,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`r_prefix`,`r_table`,`r_ID_entity`),
  KEY `SEL_0` (`r_prefix`,`r_table`,`r_ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=local

CREATE TABLE `/*db_name*/`.`/*addon*/_ACL_user_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `datetime_evidence` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `roles` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `perm_R` char(1) character set ascii NOT NULL default 'N',
  `perm_W` char(1) character set ascii NOT NULL default 'N',
  `perm_X` char(1) character set ascii NOT NULL default 'N',
  `perm_1` char(1) character set ascii NOT NULL default 'N',
  `perm_2` char(1) character set ascii NOT NULL default 'N',
  `perm_3` char(1) character set ascii NOT NULL default 'N',
  `perm_4` char(1) character set ascii NOT NULL default 'N',
  `perm_roles_override` blob,
  `note` text character set utf8 collate utf8_unicode_ci,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=local

CREATE TABLE `/*db_name*/`.`/*addon*/_ACL_user_group` ( -- table is stored where addon defined in r_prefix
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned NOT NULL, -- rel _user_group.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `roles` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `perm_R` char(1) character set ascii NOT NULL default 'N',
  `perm_W` char(1) character set ascii NOT NULL default 'N',
  `perm_X` char(1) character set ascii NOT NULL default 'N',
  `perm_roles_override` blob,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`r_prefix`,`r_table`,`r_ID_entity`),
  KEY `SEL_0` (`r_prefix`,`r_table`,`r_ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=local

CREATE TABLE `/*db_name*/`.`/*addon*/_ACL_user_group_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned NOT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `roles` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `perm_R` char(1) character set ascii NOT NULL default 'N',
  `perm_W` char(1) character set ascii NOT NULL default 'N',
  `perm_X` char(1) character set ascii NOT NULL default 'N',
  `perm_roles_override` blob,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=local

CREATE TABLE `/*db_name*/`.`/*addon*/_ACL_org` ( -- table is stored where addon defined in r_prefix
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned NOT NULL, -- rel a710_org.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `roles` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `perm_R` char(1) character set ascii NOT NULL default 'N',
  `perm_W` char(1) character set ascii NOT NULL default 'N',
  `perm_X` char(1) character set ascii NOT NULL default 'N',
  `perm_roles_override` blob,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`r_prefix`,`r_table`,`r_ID_entity`),
  KEY `SEL_0` (`r_prefix`,`r_table`,`r_ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- db_name=local

CREATE TABLE `/*db_name*/`.`/*addon*/_ACL_org_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned NOT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `roles` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `perm_R` char(1) character set ascii NOT NULL default 'N',
  `perm_W` char(1) character set ascii NOT NULL default 'N',
  `perm_X` char(1) character set ascii NOT NULL default 'N',
  `perm_roles_override` blob,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
-- db_name=TOM

CREATE OR REPLACE VIEW `/*db_name*/`.`/*addon*/_user_rel_group_view` AS (
	SELECT
		
		`user`.`hostname`,
		user_group.ID_entity AS ID_group,
		user_group.name AS group_name,
		`user`.ID_user AS ID_user,
		`user`.`login` AS user_login
		
	FROM
		`/*db_name*/`.`/*addon*/_user_rel_group` AS rel
	LEFT JOIN `/*db_name*/`.`/*addon*/_user` AS user ON
	(
		`user`.ID_user = rel.ID_user
	)
	LEFT JOIN `/*db_name*/`.`/*addon*/_user_group` AS user_group ON
	(
		user_group.ID = rel.ID_group
	)
)

