-- db_h=main
-- app=a210
-- version=4.1

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_page` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `t_name` varchar(64) character set ascii NOT NULL default '',
  `t_keys` text NOT NULL, -- kluce uchovavane ako CVML
  `is_default` char(1) character set ascii NOT NULL default 'N',
  `lng` char(2) character set ascii NOT NULL default '',
  `visible` char(1) character set ascii NOT NULL default 'Y',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_page_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `t_name` varchar(64) character set ascii NOT NULL default '',
  `t_keys` text NOT NULL,
  `is_default` char(1) character set ascii NOT NULL default 'N',
  `lng` char(2) character set ascii NOT NULL default '',
  `visible` char(1) character set ascii NOT NULL default 'Y',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;