-- db_h=main
-- addon=a930
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_rfp` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned zerofill default NULL,
  `datetime_create` datetime NOT NULL, -- last modified
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who created this order
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who last modified this order
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL, -- rel a301_user.ID_user
  `ID_org` bigint(20) unsigned default NULL, -- a710_org.ID_entity
  `price` decimal(12,3) default NULL,
  `price_currency` varchar(3) character set ascii default 'EUR',
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N', -- N=new order Y=accepted T=canceled
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `ID_user` (`ID_user`),
  KEY `ID_org` (`ID_org`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_rfp_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` int(8) unsigned zerofill default NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_org` bigint(20) unsigned default NULL,
  `price` decimal(12,3) default NULL,
  `price_currency` varchar(3) character set ascii default 'EUR',
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_rfp_lng` ( -- language versions of rfp
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _rfp.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `abstract` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `body` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_rfp_lng_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `abstract` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `body` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_rfp_rfi` ( -- request for information
  `ID_rfp` mediumint(8) unsigned NOT NULL, -- ref _rfp.ID
  `datetime_create` datetime NOT NULL,
  `req_ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `req_ID_org` bigint(20) unsigned default NULL,
  `req_IP` varchar(15) character set ascii default NULL,
  `ref_email` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  KEY `datetime_create` (`datetime_create`),
  KEY `SEL_0` (`ID_rfp`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_rfp_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `alias_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
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

CREATE TABLE `/*db_name*/`.`/*addon*/_rfp_cat_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `alias_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_rfp_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _rfp_cat.ID_entity
  `ID_rfp` bigint(20) unsigned NOT NULL, -- rel _rfp.ID,
  PRIMARY KEY  (`ID_category`,`ID_rfp`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------
