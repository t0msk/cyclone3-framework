-- version=5.0
-- ------------------------------------------------------

CREATE TABLE `/*db_name*/`.`_config` (
  `namespace` varchar(10) collate utf8_unicode_ci NOT NULL default '',
  `variable` varchar(50) character set utf8 collate utf8_bin NOT NULL default '',
  `linkT` char(1) character set ascii NOT NULL default '',
  `value` text collate utf8_unicode_ci NOT NULL,
  `type` varchar(5) character set ascii collate ascii_bin NOT NULL default '',
  `cache` smallint(5) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `about` varchar(100) character set ascii default NULL,
  PRIMARY KEY  (`variable`,`type`,`namespace`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`_tom3` (
  `var` varchar(100) collate utf8_unicode_ci NOT NULL default '0',
  `value` text collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`var`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
