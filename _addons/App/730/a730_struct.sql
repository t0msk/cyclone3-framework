-- db_h=main
-- addon=a730
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_event` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `datetime_start` datetime default NULL, -- event starts
  `datetime_finish` datetime default NULL, -- event ends
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `link` varchar(128) character set ascii default NULL,
  `location` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `priority_A` tinyint(3) unsigned default NULL,
  `price` decimal(12,3) default NULL, -- different modifications, different prices
  `price_max` decimal(12,3) default NULL,
  `price_currency` varchar(3) character set ascii default 'EUR',
  `price_EUR` decimal(12,3) default NULL, -- price in EUR
  `VAT` float NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  `mode` char(1) character set ascii NOT NULL default 'M',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `SEL_0` (`ID_entity`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_event_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `datetime_start` datetime default NULL,
  `datetime_finish` datetime default NULL,
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `link` varchar(128) character set ascii default NULL,
  `location` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `priority_A` tinyint(3) unsigned default NULL,
  `price` decimal(12,3) default NULL, -- different modifications, different prices
  `price_max` decimal(12,3) default NULL,
  `price_currency` varchar(3) character set ascii default 'EUR',
  `price_EUR` decimal(12,3) default NULL, -- price in EUR
  `VAT` float NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  `mode` char(1) character set ascii NOT NULL default 'M',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_event_metaindex` (
  `ID` bigint(20) unsigned NOT NULL, -- ref _event.ID
  `meta_section` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_value` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`meta_section`,`meta_variable`),
  KEY `SEL_0` (`meta_section`,`meta_variable`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_event_lng` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _event.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description_short` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_event_lng_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description_short` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_event_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_event_cat_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_event_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _event_cat.ID_entity
  `ID_event` bigint(20) unsigned NOT NULL, -- rel _event.ID_entity,
  PRIMARY KEY  (`ID_category`,`ID_event`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
