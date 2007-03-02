-- app=a160
-- version=5.0

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_relation` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `l_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `l_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `l_ID_entity` bigint(20) unsigned NOT NULL,
  `r_db_name` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` bigint(20) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`l_prefix`,`l_table`,`l_ID_entity`,`r_db_name`,`r_prefix`,`r_table`,`r_ID_entity`),
  UNIQUE KEY `UNI_1` (`ID`,`datetime_create`,`l_prefix`,`l_table`,`l_ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_relation_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `l_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `l_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `l_ID_entity` bigint(20) unsigned NOT NULL,
  `r_db_name` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_prefix` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `r_table` varchar(64) character set ascii collate ascii_bin NOT NULL,
  `r_ID_entity` bigint(20) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------