-- db_h=main
-- app=a401
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_ent` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel article.ID_entity
  `datetime_create` datetime NOT NULL,
  `ID_author` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `visits` int(10) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `ID_author` (`ID_author`),
  KEY `visits` (`visits`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_ent_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `ID_author` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `visits` int(10) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_attrs` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel 
  `ID_category` bigint(20) unsigned default NULL, -- rel article_cat.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_stop` datetime default NULL,
  `priority_A` tinyint(3) unsigned default NULL,
  `priority_B` tinyint(3) unsigned default NULL,
  `priority_C` tinyint(3) unsigned default NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `SEL_0` (`status`,`lng`,`datetime_start`),
  KEY `SEL_1` (`datetime_start`,`datetime_stop`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `ID_category` (`ID_category`),
  KEY `name` (`name`),
  KEY `datetime_start` (`datetime_start`),
  KEY `datetime_stop` (`datetime_stop`),
  KEY `priority_A` (`priority_A`),
  KEY `priority_B` (`priority_B`),
  KEY `priority_C` (`priority_C`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_attrs_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel 
  `ID_category` bigint(20) unsigned default NULL, -- rel article_cat.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_stop` datetime default NULL,
  `priority_A` tinyint(3) unsigned default NULL,
  `priority_B` tinyint(3) unsigned default NULL,
  `priority_C` tinyint(3) unsigned default NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_content` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `ID_editor` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `subtitle` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL,
  `mimetype` varchar(50) character set ascii NOT NULL default 'text/html',
  `abstract` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `body` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `keywords` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `subtitle` (`subtitle`),
  KEY `mimetype` (`mimetype`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_content_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `ID_editor` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `subtitle` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL,
  `mimetype` varchar(50) character set ascii NOT NULL default 'text/html',
  `abstract` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `body` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `keywords` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_visit` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_article` bigint(20) NOT NULL,
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_article`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_charindex` (`ID_charindex`),
  KEY `ID` (`ID`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_cat_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_article_view` AS (
	SELECT
		CONCAT(article.ID_entity,'-',article.ID,'-',article_attrs.lng) AS ID,
		
		article.ID_entity AS ID_entity_article,
		article.ID AS ID_article,
		article_attrs.ID AS ID_attrs,
		article_content.ID AS ID_content,
		
		article_attrs.ID_category,
		article_cat.name AS ID_category_name,
		article_cat.name_url AS ID_category_name_url,
--		(SELECT name FROM `/*db_name*/`.`/*app*/_article_cat` WHERE ID=article_attrs.ID_category LIMIT 1) AS ID_category_name,
		
		article.posix_owner,
--		(SELECT login FROM TOM.a300_users_view WHERE IDhash=article.posix_owner LIMIT 1) AS posix_owner_name,
--		IF (article.posix_owner,
--			(SELECT login FROM TOM.a300_users_view WHERE IDhash=article.posix_owner LIMIT 1), NULL
--		) AS posix_owner_name,
		article.posix_group,
--		IF (article.posix_group>0,
--			(SELECT name FROM TOM.a300_users_group WHERE ID=article.posix_group LIMIT 1), NULL
--		) AS posix_group_name,
		article.posix_perms,
		article_ent.ID_author AS posix_author,
		article_content.ID_editor AS posix_editor,
--		IF (article_ent.ID_author,
--			(SELECT login FROM TOM.a300_users_view WHERE IDhash=article_ent.ID_author LIMIT 1), NULL
--		) AS posix_author_name,
		
		article_content.datetime_create,
		article_attrs.datetime_start,
		article_attrs.datetime_stop,
		
		article_attrs.priority_A,
		article_attrs.priority_B,
		article_attrs.priority_C,
		
		article_attrs.name,
		article_attrs.name_url,
		article_content.subtitle,
		article_content.mimetype,
		article_content.abstract,
		article_content.body,
		article_content.keywords,
		article_content.lng,
		
--		article.status AS status_article,
--		article_attrs.status AS status_attrs,
--		article_content.status AS status_content,
		
		article_ent.visits,
		
		article_attrs.status,
		
		IF
		(
			(
				article.status LIKE 'Y' AND
				article_attrs.status LIKE 'Y' AND
				article_content.status LIKE 'Y'
			),
			 'Y', 'U'
		) AS status_all
		
	FROM
		`/*db_name*/`.`/*app*/_article` AS article
	LEFT JOIN `/*db_name*/`.`/*app*/_article_ent` AS article_ent ON
	(
		article_ent.ID_entity = article.ID_entity
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_article_attrs` AS article_attrs ON
	(
		article_attrs.ID_entity = article.ID
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_article_content` AS article_content ON
	(
		article_content.ID_entity = article.ID_entity AND
		article_content.lng = article_attrs.lng
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_article_cat` AS article_cat ON
	(
		article_cat.ID = article_attrs.ID_category
	)
	
	WHERE
		article_ent.ID AND
		article_attrs.ID AND
		article_content.ID
	ORDER BY
		article_attrs.datetime_start DESC
)

-- --------------------------------------------------
