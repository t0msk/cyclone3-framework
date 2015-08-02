-- db_h=main
-- addon=a720
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_contract` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `name` varchar(256) character set utf8 collate utf8_unicode_ci NOT NULL default '', -- contract name
  `name_url` varchar(256) character set ascii NOT NULL default '',
  `type` varchar(32) character set utf8 collate utf8_unicode_ci default NULL, -- contract type
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_contractor` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `contract_number` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL default '', -- internal evidence number
  `contract_date_prepare` date default NULL, -- contract preparing
  `contract_date_first` date default NULL, -- contract first version
  `contract_date_approval` date default NULL, -- contract to approval
  `contract_date_start` date default NULL, -- contract starts
  `contract_date_end` date default NULL, -- contract ends
  `contract_date_cancel` date default NULL, -- contract canceled
  `cancelation_note` text character set utf8 collate utf8_unicode_ci,
  `cancelation_fee` decimal(12,3) default NULL,
  `datetime_evidence` datetime default NULL, -- added into evidence
  `billing_service` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `entity_addon` varchar(64) character set ascii NOT NULL default '',
  `amendment1_date_evidence` date default NULL,
  `amendment1_date_start` date default NULL,
  `amendment1_date_end` date default NULL,
  `amendment1_note` text character set utf8 collate utf8_unicode_ci,
  `amendment2_date_evidence` date default NULL,
  `amendment2_date_start` date default NULL,
  `amendment2_date_end` date default NULL,
  `amendment2_note` text character set utf8 collate utf8_unicode_ci,
  `amendment3_date_evidence` date default NULL,
  `amendment3_date_start` date default NULL,
  `amendment3_date_end` date default NULL,
  `amendment3_note` text character set utf8 collate utf8_unicode_ci,
  `description` text character set utf8 collate utf8_unicode_ci, -- contract description
  `notes` text character set utf8 collate utf8_unicode_ci, -- note of editor
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status_internal` char(3) character set ascii default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `SEL_0` (`ID_entity`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_contract_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(256) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(256) character set ascii NOT NULL default '',
  `type` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_contractor` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `contract_number` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `contract_date_prepare` date default NULL,
  `contract_date_first` date default NULL,
  `contract_date_approval` date default NULL, -- contract to approval
  `contract_date_start` date default NULL,
  `contract_date_end` date default NULL,
  `contract_date_cancel` date default NULL,
  `cancelation_note` text character set utf8 collate utf8_unicode_ci,
  `cancelation_fee` decimal(12,3) default NULL,
  `datetime_evidence` datetime default NULL,
  `billing_service` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `entity_addon` varchar(64) character set ascii NOT NULL default '',
  `amendment1_date_evidence` date default NULL,
  `amendment1_date_start` date default NULL,
  `amendment1_date_end` date default NULL,
  `amendment1_note` text character set utf8 collate utf8_unicode_ci,
  `amendment2_date_evidence` date default NULL,
  `amendment2_date_start` date default NULL,
  `amendment2_date_end` date default NULL,
  `amendment2_note` text character set utf8 collate utf8_unicode_ci,
  `amendment3_date_evidence` date default NULL,
  `amendment3_date_start` date default NULL,
  `amendment3_date_end` date default NULL,
  `amendment3_note` text character set utf8 collate utf8_unicode_ci,
  `description` text character set utf8 collate utf8_unicode_ci,
  `notes` text character set utf8 collate utf8_unicode_ci,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status_internal` char(3) character set ascii default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_contract_cat` (
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

CREATE TABLE `/*db_name*/`.`/*addon*/_contract_cat_j` (
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

CREATE TABLE `/*db_name*/`.`/*addon*/_contract_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _contract_cat.ID_entity
  `ID_contract` bigint(20) unsigned NOT NULL, -- rel _contract.ID_entity,
  PRIMARY KEY  (`ID_category`,`ID_contract`),
  KEY `ID_contract` (`ID_contract`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
