-- db_h=main
-- addon=a740
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_joboffer` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `datetime_publish_start` datetime default NULL,
  `datetime_publish_stop` datetime default NULL,
  `location_city` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `education` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `for_students` char(1) character set ascii NOT NULL default 'N',
  `contract_type` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `contact_org` bigint(20) unsigned default NULL, -- rel 710_org.ID_entity
  `contact_person` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel 301.user_ID
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `SEL_0` (`ID_entity`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_joboffer_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `location_city` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `education` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `for_students` char(1) character set ascii NOT NULL default 'N',
  `contact_org` bigint(20) unsigned default NULL, -- rel 710_org.ID_entity
  `contact_person` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel 301.user_ID
  `contract_type` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_joboffer_lng` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _joboffer.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_joboffer_lng_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _joboffer.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_joboffer_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_joboffer_cat_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_joboffer_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _joboffer_cat.ID_entity
  `ID_joboffer` bigint(20) unsigned NOT NULL, -- rel _joboffer.ID_entity,
  PRIMARY KEY  (`ID_category`,`ID_joboffer`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
