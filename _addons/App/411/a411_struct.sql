-- db_h=main
-- app=a411
-- version=5.0

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_poll` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_stop` datetime default NULL,
  `datetime_voting_start` datetime default NULL,
  `datetime_voting_stop` datetime default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_poll_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_stop` datetime default NULL,
  `datetime_voting_start` datetime default NULL,
  `datetime_voting_stop` datetime default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_poll_answer` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_poll` bigint(20) unsigned NOT NULL, -- rel _poll.ID_entity
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `SEL_0` (`ID_poll`,`lng`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_poll_answer_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_poll` bigint(20) unsigned NOT NULL, -- rel _poll.ID_entity
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_poll_vote` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ref_user` varchar(64) character set ascii collate ascii_bin default NULL,
  `ID_answer` bigint(20) NOT NULL, -- rel poll_answer.ID_entity
  `IP` varchar(15) NOT NULL default '',
  `email` varchar(64) character set ascii default NULL,
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_answer`),
  UNIQUE KEY `UNI_0` (`datetime_event`,`IP`),
  KEY `ID_answer` (`ID_answer`),
  KEY `SEL_0` (`datetime_event`,`ref_user`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_poll_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_poll_cat_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_poll_view` AS (
	SELECT
		
		poll.ID_entity AS ID_entity_poll,
		poll.ID AS ID_poll,
		poll_answer.ID_entity AS ID_entity_answer,
		poll_answer.ID AS ID_answer,
		
		poll.name AS question,
		poll.description,
		poll_answer.name AS answer,
		
		poll.lng,
		
		(SELECT COUNT(*) FROM `/*db_name*/`.`/*app*/_poll_vote` WHERE ID_answer=poll_answer.ID) AS votes,
		
		IF
		(
			(
				poll.status LIKE 'Y' AND
				poll_answer.status LIKE 'Y'
			),
			 'Y', 'U'
		) AS status
		
	FROM
		`/*db_name*/`.`/*app*/_poll` AS poll
	LEFT JOIN `/*db_name*/`.`/*app*/_poll_answer` AS poll_answer ON
	(
		poll.ID_entity = poll_answer.ID_poll AND
		poll.lng = poll_answer.lng
	)
	
	WHERE
		poll.ID AND
		poll_answer.ID
)

