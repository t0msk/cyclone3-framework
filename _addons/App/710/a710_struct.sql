-- db_h=main
-- addon=a710
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  
  `name` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(64) character set ascii NOT NULL default '',
  `name_short` varchar(64) character set utf8 collate utf8_bin NOT NULL default '',
  `name_code` char(4) character set ascii NOT NULL default '',
  
  `legal_form` varchar(16) character set utf8 collate utf8_unicode_ci default NULL,
  `ID_org` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `VAT_number` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `bank_contact` text character set utf8 collate utf8_unicode_ci,
  
  `country_code` char(3) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `county` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- kraj
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- okres
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,
  
  `address_postal` text character set utf8 collate utf8_unicode_ci,
  
  `phone_1` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_2` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `fax` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `email` varchar(64) character set ascii default NULL,
  `web` varchar(64) character set ascii default NULL,
  
  `about` text character set utf8 collate utf8_unicode_ci,
  `note` text character set utf8 collate utf8_unicode_ci,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_org_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL, -- main id
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  
  `name` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(64) character set ascii NOT NULL default '',
  `name_short` varchar(64) character set utf8 collate utf8_bin NOT NULL default '',
  `name_code` char(4) character set ascii NOT NULL default '',
  
  `legal_form` varchar(16) character set utf8 collate utf8_unicode_ci default NULL,
  `ID_org` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `VAT_number` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `bank_contact` text character set utf8 collate utf8_unicode_ci,
  
  `country_code` char(3) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `county` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- kraj
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL, -- okres
  `city` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `street` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `street_num` varchar(12) character set ascii default NULL,
  
  `address_postal` text character set utf8 collate utf8_unicode_ci,
  
  `phone_1` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `phone_2` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `fax` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `email` varchar(64) character set ascii default NULL,
  `web` varchar(64) character set ascii default NULL,
  
  `about` text character set utf8 collate utf8_unicode_ci,
  `note` text character set utf8 collate utf8_unicode_ci,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  
  `status` char(1) character set ascii NOT NULL default 'Y'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------