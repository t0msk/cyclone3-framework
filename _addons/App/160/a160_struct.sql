-- addon=a160
-- version=5.0

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_relation` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `l_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `l_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `l_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `rel_type` varchar(20) character set utf8 collate utf8_unicode_ci NOT NULL,
  `r_db_name` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `SEL_0` (`l_prefix`,`l_table`,`l_ID_entity`),
  KEY `SEL_1` (`r_prefix`,`r_table`,`r_ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_relation_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `l_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `l_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `l_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `rel_type` varchar(20) character set utf8 collate utf8_unicode_ci NOT NULL,
  `r_db_name` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_historization` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, 
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `datetime_valid` datetime NOT NULL default '0000-00-00 00:00:00', -- valid to
  `l_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `l_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `l_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `l_column` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `value` varchar(256) character set utf8 collate utf8_unicode_ci default NULL, 
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  KEY `SEL_0` (`l_prefix`,`l_table`,`l_ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_historization_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, 
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `datetime_valid` datetime NOT NULL default '0000-00-00 00:00:00',
  `l_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `l_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `l_ID_entity` varchar(16) character set utf8 collate utf8_unicode_ci NOT NULL,
  `l_column` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `value` varchar(256) character set utf8 collate utf8_unicode_ci default NULL, 
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------