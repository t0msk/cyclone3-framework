-- db_h=main
-- app=a910
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(64) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `ID_brand` bigint(20) unsigned NOT NULL,
  `product_number` varchar(32) NOT NULL,
  `description_short` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `amount` bigint(20) unsigned NOT NULL,
  `amount_availability` varchar(32) NOT NULL,
  `price` float NOT NULL,
  `VAT` float NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
   PRIMARY KEY  (`ID`,`datetime_create`),
   UNIQUE KEY `UNI_1` (`ID_brand`,`name`,`lng`),
   UNIQUE KEY `UNI_2` (`product_number`,`lng`),
   UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(64) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `ID_brand` bigint(20) unsigned NOT NULL,
  `product_number` varchar(32) NOT NULL,
  `description_short` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `amount` bigint(20) unsigned NOT NULL,
  `amount_availability` varchar(32) NOT NULL,
  `price` float NOT NULL,
  `VAT` float NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
   PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_brand` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_charindex` (`ID_charindex`),
  KEY `ID` (`ID`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_cat_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N'
) ENGINE=ARCHIVE DEFAULT CHARSET=utf8;

-- --------------------------------------------------