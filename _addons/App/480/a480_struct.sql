-- db_h=main
-- addon=a480
-- version=5.0

-- --------------------------------------------------------
-- TABLE APP
-- custom table with A-Z columns (26 columns)

-- --------------------------------------------------------
CREATE TABLE `/*db_name*/`.`/*addon*/_table` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL, -- rel _table_cat.ID_entity
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_table_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL, -- rel _table_cat.ID_entity
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
CREATE TABLE `/*db_name*/`.`/*addon*/_table_row` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _table.ID_entity
  `status` char(1) character set ascii NOT NULL default 'Y',
  `status_header` char(1) character set ascii NOT NULL default 'N',
  `order_id` int(11) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `A` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `B` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `C` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `D` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `E` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `F` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `G` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `H` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `I` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `J` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `K` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `L` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `M` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `N` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `O` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `P` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `Q` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `R` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `S` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `T` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `U` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `V` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `W` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `X` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `Y` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `Z` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
CREATE TABLE `/*db_name*/`.`/*addon*/_table_row_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _table.ID_entity
  `status` char(1) character set ascii NOT NULL default 'Y',
  `order_id` int(11) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `A` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `B` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `C` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `D` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `E` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `F` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `G` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `H` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `I` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `J` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `K` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `L` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `M` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `N` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `O` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `P` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `Q` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `R` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `S` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `T` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `U` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `V` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `W` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `X` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `Y` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  `Z` varchar(255) character set utf8 collate utf8_unicode_ci NOT NULL default '',  
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
CREATE TABLE `/*db_name*/`.`/*addon*/_table_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_table_cat_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

