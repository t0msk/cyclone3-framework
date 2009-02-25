-- db_h=main
-- addon=a720
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_contract` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '', -- contract name
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `type` varchar(32) character set utf8 collate utf8_unicode_ci default NULL, -- contract type
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `contract_number` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL default '', -- internal evidence number
  `contract_date_start` date default NULL, -- contract starts
  `contract_date_end` date default NULL, -- contract ends
  `datetime_evidence` datetime default NULL, -- added into evidence
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
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_contract_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `type` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `contract_number` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `contract_date_start` date default NULL,
  `contract_date_end` date default NULL,
  `datetime_evidence` datetime default NULL,
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
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
