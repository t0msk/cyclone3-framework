--
-- db_h=main
-- db_name=TOM
-- version=5.0

-- ------------------------------------------------------
-- db_h=sys

CREATE TABLE `/*db_name*/`.`_url` (
  `hash` varchar(32) NOT NULL default '',
  `url` text NOT NULL,
  `inserttime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`hash`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ------------------------------------------------------

CREATE TABLE `/*db_name*/`.`_config` (
  `namespace` varchar(10) NOT NULL default '',
  `variable` varchar(50) NOT NULL default '',
  `linkT` char(1) NOT NULL default '',
  `value` text NOT NULL,
  `type` varchar(5) NOT NULL default '',
  `cache` smallint(5) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `about` varchar(100) default NULL,
  PRIMARY KEY  (`variable`,`type`,`namespace`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`_tom3` (
  `var` varchar(100) NOT NULL default '0',
  `value` text NOT NULL,
  PRIMARY KEY  (`var`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

