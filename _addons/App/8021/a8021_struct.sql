-- addon=a8021
-- version=5.0

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_message` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_reply` mediumint(8) unsigned default NULL, -- ref _message.ID_entity
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '', -- titles
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_recipient` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL, -- last modifytime
  `datetime_sent` datetime NOT NULL,
  `datetime_readed` datetime default NULL,
  `body` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `SEL_0` (`posix_owner`,`datetime_sent`),
  KEY `ID_reply` (`ID_reply`),
  KEY `posix_owner` (`posix_owner`),
  KEY `datetime_sent` (`datetime_sent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_message_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_reply` mediumint(8) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_recipient` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_sent` datetime NOT NULL,
  `datetime_readed` datetime default NULL,
  `body` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------