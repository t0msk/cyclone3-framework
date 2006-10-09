--
-- db_h=main
-- db_name=TOM

-- ------------------------------------------------------
-- db_h=sys

CREATE TABLE `/*db_name*/`.`_url` (
  `hash` varchar(32) NOT NULL default '',
  `url` text NOT NULL,
  `inserttime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`hash`)
) TYPE=MyISAM;

-- ------------------------------------------------------

CREATE TABLE `/*db_name*/`.`_config` (
  `namespace` varchar(10) NOT NULL default '',
  `variable` varchar(50) binary NOT NULL default '',
  `linkT` char(1) NOT NULL default '',
  `value` text NOT NULL,
  `type` varchar(5) binary NOT NULL default '',
  `cache` smallint(5) unsigned NOT NULL default '0',
  `reqtime` int(10) unsigned NOT NULL default '0',
  `about` varchar(100) default NULL,
  PRIMARY KEY  (`variable`,`type`,`namespace`)
) TYPE=MyISAM;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`_tom3` (
  `var` varchar(100) NOT NULL default '0',
  `value` text NOT NULL,
  PRIMARY KEY  (`var`)
) TYPE=MyISAM;

