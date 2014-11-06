-- db_h=main
-- addon=a940
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_discount` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL, -- last modified
  `datetime_valid_from` datetime DEFAULT NULL,
  `datetime_valid_to` datetime DEFAULT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who created this item
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who last modified this item
  `postprocess` char(1) character set ascii NOT NULL default 'N',
  `rules_validation` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `rules_apply` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_discount_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL, -- last modified
  `datetime_valid_from` datetime DEFAULT NULL,
  `datetime_valid_to` datetime DEFAULT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `postprocess` char(1) character set ascii NOT NULL default 'N',
  `rules_validation` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `rules_apply` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_discount_coupon` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned default NULL, -- rel _discount.ID
  `datetime_create` datetime NOT NULL, -- last modified
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who created this item
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who last modified this item
  `coupon_code` varchar(12) character set ascii default NULL,
  `datetime_valid_from` datetime DEFAULT NULL,
  `datetime_valid_to` datetime DEFAULT NULL,
  `limit_applications` int(8) unsigned DEFAULT '1',
  `applications` int(8) unsigned DEFAULT '0',
  `limit_to_email` varchar(32) character set ascii DEFAULT NULL,
  `limit_customer` char(1) character set ascii NOT NULL default 'Y',
  `status` char(1) character set ascii NOT NULL default 'N', -- active or not
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`coupon_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_discount_coupon_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `coupon_code` varchar(12) character set ascii default NULL,
  `datetime_valid_from` datetime DEFAULT NULL,
  `datetime_valid_to` datetime DEFAULT NULL,
  `limit_applications` int(8) unsigned DEFAULT NULL,
  `applications` int(8) unsigned DEFAULT '0',
  `limit_to_email` varchar(32) character set ascii DEFAULT NULL,
  `limit_customer` char(1) character set ascii NOT NULL default 'Y',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_discount_coupon_use` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned default NULL, -- rel _discount_coupon.ID
  `datetime_create` datetime NOT NULL, -- last modified
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who used
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who writed
  `datetime_application` datetime DEFAULT NULL,
  `customer_email` varchar(32) character set ascii DEFAULT NULL,
  `status` char(1) character set ascii NOT NULL default 'N', -- used or not
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_gift` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL, -- last modified
  `datetime_valid_from` datetime DEFAULT NULL,
  `datetime_valid_to` datetime DEFAULT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who created this item
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who last modified this item
  `postprocess` char(1) character set ascii NOT NULL default 'N',
  `rules_validation` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `rules_apply` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_gift_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL, -- last modified
  `datetime_valid_from` datetime DEFAULT NULL,
  `datetime_valid_to` datetime DEFAULT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `postprocess` char(1) character set ascii NOT NULL default 'N',
  `rules_validation` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `rules_apply` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
