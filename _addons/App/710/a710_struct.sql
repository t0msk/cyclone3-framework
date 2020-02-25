-- db_h=main
-- addon=a710
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `ref_ID` varchar(64) character set ascii default NULL, -- external reference
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `name_short` varchar(64) character set utf8 collate utf8_bin NOT NULL default '',
  `name_code` char(20) character set ascii NOT NULL default '',
  
  `type` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  
  `legal_form` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ID_org` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `tax_number` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `VAT_number` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `bank_contact` text character set utf8 collate utf8_unicode_ci,
  
  `country_code` char(3) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `county` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- kraj
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- okres
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,

  `latitude_decimal` float(10,6) default NULL,
  `longitude_decimal` float(10,6) default NULL,
  `location_verified` char(1) character set ascii NOT NULL default 'N',
  
  `address_postal` text character set utf8 collate utf8_unicode_ci,
  
  `phone_1` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_2` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `fax` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `email` varchar(64) character set ascii default NULL,
  `web` varchar(100) character set ascii default NULL,
  
  `about` text character set utf8 collate utf8_unicode_ci,
  `note` text character set utf8 collate utf8_unicode_ci,
  `metadata` longtext character set utf8 collate utf8_unicode_ci NOT NULL,

  `datetime_evidence` datetime default NULL,
  `datetime_modified` datetime default NULL,  

  `priority_A` tinyint(3) unsigned default NULL,
  `priority_B` tinyint(3) unsigned default NULL,
  `priority_C` tinyint(3) unsigned default NULL,

  `mode` char(1) character set ascii NOT NULL default 'M',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `county` (`county`),
  KEY `district` (`district`),
  KEY `city` (`city`),
  KEY `status` (`status`),
  KEY `ref_ID` (`ref_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `ref_ID` varchar(64) character set ascii default NULL, -- external reference
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `name_short` varchar(64) character set utf8 collate utf8_bin NOT NULL default '',
  `name_code` char(20) character set ascii NOT NULL default '',
  
  `type` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  
  `legal_form` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ID_org` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `tax_number` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `VAT_number` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `bank_contact` text character set utf8 collate utf8_unicode_ci,
  
  `country_code` char(3) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `county` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- kraj
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- okres
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,
  
  `latitude_decimal` float(10,6) default NULL,
  `longitude_decimal` float(10,6) default NULL,
  `location_verified` char(1) character set ascii NOT NULL default 'N',

  `address_postal` text character set utf8 collate utf8_unicode_ci,
  
  `phone_1` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_2` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `fax` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `email` varchar(64) character set ascii default NULL,
  `web` varchar(100) character set ascii default NULL,
  
  `about` text character set utf8 collate utf8_unicode_ci,
  `note` text character set utf8 collate utf8_unicode_ci,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,

  `datetime_evidence` datetime default NULL,
  `datetime_modified` datetime default NULL,  

  `priority_A` tinyint(3) unsigned default NULL,
  `priority_B` tinyint(3) unsigned default NULL,
  `priority_C` tinyint(3) unsigned default NULL,

  `mode` char(1) character set ascii NOT NULL default 'M',  
  `status` char(1) character set ascii NOT NULL default 'Y'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org_metaindex` (
  `ID` bigint(20) unsigned NOT NULL, -- ref _org.ID_entity
  `meta_section` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_value` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`meta_section`,`meta_variable`),
  KEY `SEL_0` (`meta_section`,`meta_variable`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org_lng` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- related _org.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `name_short` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `about` text character set utf8 collate utf8_unicode_ci,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org_lng_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `name_short` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `about` text character set utf8 collate utf8_unicode_ci,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `metadata` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
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

CREATE TABLE `/*db_name*/`.`/*addon*/_org_cat_j` (
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
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _org_cat.ID_entity
  `ID_org` bigint(20) unsigned NOT NULL, -- rel _org.ID_entity,
  PRIMARY KEY  (`ID_category`,`ID_org`),
  KEY `ID_org` (`ID_org`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------