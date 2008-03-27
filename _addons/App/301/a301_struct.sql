-- db_h=main
-- db_name=TOM
-- app=a301
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_user` (
  `ID_user` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `login` varchar(32) character set ascii default NULL,
  `pass` varchar(256) character set ascii collate ascii_bin default NULL,
  `autolog` char(1) character set ascii NOT NULL default 'N',
  `hostname` varchar(64) character set ascii NOT NULL,
  `datetime_register` datetime NOT NULL,
  `datetime_last_login` datetime default NULL,
  `requests_all` smallint(5) unsigned NOT NULL default '0',
  `email` varchar(64) character set ascii default NULL,
  `email_verified` char(1) character set ascii NOT NULL default 'N',
--  `email_alt` varchar(64) character set ascii default NULL,
--  `email_alt_verified` char(1) character set ascii NOT NULL default 'N',
  `saved_cookies` blob NOT NULL,
  `saved_session` blob NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID_user`),
  UNIQUE KEY `UNI_0` (`hostname`,`login`),
  KEY `login` (`login`),
  KEY `hostname` (`hostname`),
  KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_user_emailverify` (
  `ID_user` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `email` varchar(64) character set ascii default NULL,
  `datetime_register` datetime NOT NULL,
  `hash` varchar(16) character set ascii collate ascii_bin default NULL,
  PRIMARY KEY  (`ID_user`),
  UNIQUE KEY `UNI_0` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_user_profile` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel _user.ID_user
  `datetime_create` datetime NOT NULL,
  `firstname` varchar(32) character set utf8 collate utf8_bin default NULL,
  `surname` varchar(64) character set utf8 collate utf8_bin default NULL,
  `sex` char(1) character set ascii default NULL,
  `date_birth` date default NULL,
  `country` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `education` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `phone` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_mobile` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `about_me` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `SEL_0` (`firstname`,`surname`),
  KEY `ID` (`ID`),
  KEY `firstname` (`firstname`),
  KEY `surname` (`surname`),
  KEY `sex` (`sex`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_user_profile_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel _user.ID_user
  `datetime_create` datetime NOT NULL,
  `firstname` varchar(32) character set utf8 collate utf8_bin default NULL,
  `surname` varchar(64) character set utf8 collate utf8_bin default NULL,
  `sex` char(1) character set ascii default NULL,
  `date_birth` date default NULL,
  `country` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `education` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `phone` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_mobile` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `about_me` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_user_profile_view` AS (
	SELECT
		
		user.hostname,
		user.ID_user,
		user.login,
		user.email,
		user.email_verified,
		user_profile.*
		
	FROM
		`/*db_name*/`.`/*app*/_user` AS user
	LEFT JOIN `/*db_name*/`.`/*app*/_user_profile` AS user_profile ON
	(
		user.ID_user = user_profile.ID_entity
	)
	WHERE
		user.login IS NOT NULL AND
		user_profile.ID_entity IS NOT NULL
)

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_user_online` (
  `ID_user` varchar(8) character set utf8 collate utf8_bin NOT NULL default '',
  `ID_session` varchar(32) character set utf8 collate utf8_bin NOT NULL default '',
  `domain` varchar(64) character set ascii NOT NULL,
  `logged` char(1) NOT NULL default 'N',
  `datetime_login` datetime NOT NULL,
  `datetime_request` datetime NOT NULL,
  `requests` smallint(5) unsigned NOT NULL default '0',
  `IP` varchar(20) NOT NULL default '',
  `user_agent` varchar(200) NOT NULL default '',
  `cookies` blob NOT NULL,
  `session` blob NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID_user`),
  KEY `ID_session` (`ID_session`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_user_online_view` AS (
	SELECT
		
		user_online.ID_session,
		user_online.logged,
		user_online.datetime_login,
		user_online.datetime_request,
		user_online.requests,
		user_online.IP,
		user_online.domain,
		user_online.user_agent,
		user_online.cookies,
		user_online.session,
		
		user.*
		
	FROM
		`/*db_name*/`.`/*app*/_user_online` AS user_online
	LEFT JOIN `/*db_name*/`.`/*app*/_user` AS user ON
	(
		user.ID_user = user_online.ID_user
	)
	
)

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_user_group` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `hostname` varchar(64) character set ascii NOT NULL default '',
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  UNIQUE KEY `UNI_1` (`ID_charindex`),
  UNIQUE KEY `UNI_2` (`hostname`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_user_group_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `hostname` varchar(64) character set ascii NOT NULL default '',
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_user_rel_group` (
  `ID_group` int(10) unsigned NOT NULL auto_increment,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  PRIMARY KEY  (`ID_group`,`ID_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_user_rel_group_view` AS (
	SELECT
		
		user.hostname,
		user_group.ID AS ID_group,
		user_group.name AS group_name,
		user.ID_user AS ID_user,
		user.login AS user_login
		
	FROM
		`/*db_name*/`.`/*app*/_user_rel_group` AS rel
	LEFT JOIN `/*db_name*/`.`/*app*/_user` AS user ON
	(
		user.ID_user = rel.ID_user
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_user_group` AS user_group ON
	(
		user_group.ID = rel.ID_group
	)
)

