-- db_h=main
-- app=a830
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form_entry` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form_entry_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form_data` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _form.ID_entity
  `ID_entry` bigint(20) unsigned default NULL, -- rel _form_entry.ID_entity
  `datetime_event` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `data_name` varchar(128) character set ascii NOT NULL default '',
  `data_value` text NOT NULL,
  `IP` varchar(15) NOT NULL default '',
  `lng` char(5) character set ascii NOT NULL default 'xx',
  PRIMARY KEY  (`ID`,`datetime_event`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`datetime_event`,`data_name`,`IP`),
  KEY `ID_entity` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form_data_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _form.ID_entity
  `ID_entry` bigint(20) unsigned default NULL, -- rel _form_entry.ID_entity
  `datetime_event` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `data` text NOT NULL,
  `IP` varchar(15) NOT NULL default '',
  `lng` char(5) character set ascii NOT NULL default 'xx',
  PRIMARY KEY  (`ID`,`datetime_event`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`datetime_event`,`IP`),
  KEY `ID_entity` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_charindex` (`ID_charindex`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form_cat_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_charindex` (`ID_charindex`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_form_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _offer_cat.ID_entity
  `ID_form` bigint(20) unsigned NOT NULL, -- rel _offer.ID,
  PRIMARY KEY  (`ID_category`,`ID_form`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------