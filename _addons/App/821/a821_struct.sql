-- app=a821
-- version=5.0

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_discussion` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_forum` bigint(20) unsigned default NULL, -- rel discussion_forum.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_end` datetime default NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_discussion_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_forum` bigint(20) unsigned default NULL, -- rel discussion_forum.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_end` datetime default NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_discussion_forum` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_discussion_forum_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_discussion_message` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_charindex` varchar(250) character set ascii collate ascii_bin default NULL,
  `ID_discussion` bigint(20) unsigned default NULL, -- rel discussion.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_post` datetime NOT NULL,
  `owner_anonymous_name` varchar(64) default NULL,
  `owner_IP` varchar(16) NOT NULL,
  `body` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_discussion_message_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_charindex` varchar(250) character set ascii collate ascii_bin default NULL,
  `ID_discussion` bigint(20) unsigned default NULL, -- rel discussion.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_post` datetime NOT NULL,
  `owner_anonymous_name` varchar(64) default NULL,
  `owner_IP` varchar(16) NOT NULL,
  `body` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

