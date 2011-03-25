-- version=5.0
-- ------------------------------------------------------

CREATE TABLE `/*db_name*/`.`_config` (
  `namespace` varchar(10) NOT NULL default '',
  `variable` varchar(50) NOT NULL default '',
  `linkT` char(1) character set ascii NOT NULL default '',
  `value` text NOT NULL,
  `type` varchar(5) character set ascii collate ascii_bin NOT NULL default '',
  `cache` smallint(5) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `about` varchar(100) character set ascii default NULL,
  PRIMARY KEY  (`variable`,`type`,`namespace`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`_tom3` (
  `var` varchar(100) NOT NULL default '0',
  `value` text NOT NULL,
  PRIMARY KEY  (`var`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
