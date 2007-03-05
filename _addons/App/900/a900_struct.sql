
-- app=a900

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_bnn` (
  `host` varchar(150) NOT NULL default '',
  `section` varchar(100) NOT NULL default '',
  `position` varchar(100) NOT NULL default '',
  `type` varchar(50) NOT NULL default '',
  `action` varchar(50) NOT NULL default '',
  `starttime` int(10) unsigned NOT NULL default '0',
  `endtime` int(10) unsigned NOT NULL default '0',
  `time_use` int(10) unsigned NOT NULL default '0',
  `code` text NOT NULL,
  `lng` char(3) NOT NULL default '',
  `active` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`host`,`section`,`position`,`type`,`starttime`,`lng`,`active`,`action`),
  KEY `active` (`active`),
  KEY `lng` (`lng`),
  KEY `host` (`host`),
  KEY `section` (`section`),
  KEY `type` (`type`),
  KEY `starttime` (`starttime`)
) TYPE=MyISAM;

