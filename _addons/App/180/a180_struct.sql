-- db_h=main
-- addon=a180
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_page` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `domain` varchar(64) character set ascii default NULL,
  `url` varchar(256) character set ascii default NULL,
  `reply` int(10) unsigned default NULL,
  `weight` int(10) unsigned default NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `url` (`url`),
  KEY `SEL_0` (`ID_entity`,`ID`),
  KEY `SEL_1` (`domain`,`url`,`reply`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_object` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, 
  `ID_page` bigint(20) unsigned default NULL, -- main: page.ID
  `catalog` varchar(16) character set ascii collate ascii_bin NOT NULL,
  `identifier` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`catalog`,`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_object_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_page` bigint(20) unsigned default NULL, -- main: page.ID
  `catalog` varchar(16) character set ascii collate ascii_bin NOT NULL,
  `identifier` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL -- changed by user
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_object_metaindex` (
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