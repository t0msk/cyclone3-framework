-- db_h=main
-- app=a401
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_ent` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel article.ID_entity
  `datetime_create` datetime NOT NULL,
  `uuid` char(36) character set ascii default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `ID_author` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `sources` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `visits` int(10) unsigned NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `rating` decimal(12,3) unsigned NOT NULL, -- helps indexing
  `votes` int(10) unsigned DEFAULT '0', -- helps indexing
  `social_shares_facebook` int(10) unsigned default NULL,
  `social_shares_twitter` int(10) unsigned default NULL,
  `social_shares_linkedin` int(10) unsigned default NULL,
  `social_shares_pinterest` int(10) unsigned default NULL,
  `social_shares_googleplus` int(10) unsigned default NULL,
  `published_mark` varchar(16) character set ascii collate ascii_bin NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `uuid` (`uuid`),
  KEY `ID_entity` (`ID_entity`,`status`),
  KEY `ID_author` (`ID_author`),
  KEY `visits` (`visits`),
  KEY `rating` (`rating`),
  KEY `votes` (`votes`),
  KEY `status` (`status`),
  KEY `published_mark` (`published_mark`),
  KEY `datetime_create` (`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_ent_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `uuid` char(36) character set ascii default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `ID_author` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `sources` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `visits` int(10) unsigned NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `rating` decimal(12,3) unsigned NOT NULL,
  `votes` int(10) unsigned DEFAULT '0',
  `social_shares_facebook` int(10) unsigned default NULL,
  `social_shares_twitter` int(10) unsigned default NULL,
  `social_shares_linkedin` int(10) unsigned default NULL,
  `social_shares_pinterest` int(10) unsigned default NULL,
  `social_shares_googleplus` int(10) unsigned default NULL,
  `published_mark` varchar(16) character set ascii collate ascii_bin NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_ent_metaindex` (
  `ID` bigint(20) unsigned NOT NULL, -- ref _article_ent.ID
  `meta_section` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_value` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`meta_section`,`meta_variable`),
  KEY `SEL_0` (`meta_section`,`meta_variable`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_rating_vote` (
  `ID_user` varchar(8) character set ascii collate ascii_bin default NULL,
  `IP` varchar(15) default NULL,
  `ID_article` mediumint(8) unsigned NOT NULL, -- ref _article.ID_entity
  `datetime_event` datetime NOT NULL,
  `score` int(10) unsigned NOT NULL,
  KEY `ID_article` (`ID_article`)
  -- UNIQUE KEY `UNI_0` (`ID_user`,`IP`,`ID_article`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_attrs` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _article.ID
  `ID_category` bigint(20) unsigned default NULL, -- rel article_cat.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `name_hyphens` varchar(200) character set ascii default NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_stop` datetime default NULL,
  `priority_A` tinyint(3) unsigned default NULL,
  `priority_B` tinyint(3) unsigned default NULL,
  `priority_C` tinyint(3) unsigned default NULL,
  `priority_D` tinyint(3) unsigned default NULL,
  `priority_E` tinyint(3) unsigned default NULL,
  `priority_F` tinyint(3) unsigned default NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `SEL_0` (`status`,`lng`,`datetime_start`,`ID_category`),
  KEY `SEL_1` (`datetime_start`,`datetime_stop`),
  KEY `SEL_2` (`status`,`lng`,`ID_category`),
  KEY `name` (`name`),
  KEY `name_url` (`name_url`),
  KEY `datetime_stop` (`datetime_stop`),
  KEY `priority_A` (`priority_A`),
  KEY `priority_B` (`priority_B`),
  KEY `priority_C` (`priority_C`),
  KEY `priority_D` (`priority_D`),
  KEY `priority_E` (`priority_E`),
  KEY `priority_F` (`priority_F`),
  KEY `lng` (`lng`,`datetime_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_attrs_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL, -- rel 
  `ID_category` bigint(20) unsigned default NULL, -- rel article_cat.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `name_hyphens` varchar(200) character set ascii default NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_stop` datetime default NULL,
  `priority_A` tinyint(3) unsigned default NULL,
  `priority_B` tinyint(3) unsigned default NULL,
  `priority_C` tinyint(3) unsigned default NULL,
  `priority_D` tinyint(3) unsigned default NULL,
  `priority_E` tinyint(3) unsigned default NULL,
  `priority_F` tinyint(3) unsigned default NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_content` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_check` datetime default NULL,
  `datetime_modified` datetime default NULL,
  `version` tinyint(3) unsigned default '0',
  `ID_editor` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `subtitle` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL,
  `subtitle_hyphens` text character set ascii,
  `mimetype` varchar(50) character set ascii NOT NULL default 'text/html',
  `abstract` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `abstract_hyphens` text character set ascii,
  `body` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `body_hyphens` longtext character set ascii,
  `keywords` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`,`version`),
  FULLTEXT KEY `FULL_0` (`subtitle`,`abstract`,`body`,`keywords`),
  FULLTEXT KEY `FULL_1` (`keywords`),
  KEY `ID_entity` (`ID_entity`),
  KEY `subtitle` (`subtitle`),
  KEY `datetime_create` (`datetime_create`),
  KEY `datetime_check` (`datetime_check`),
  KEY `mimetype` (`mimetype`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_content_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_check` datetime default NULL,
  `datetime_modified` datetime default NULL,
  `version` tinyint(3) unsigned default '0',
  `ID_editor` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `subtitle` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL,
  `subtitle_hyphens` text character set ascii,
  `mimetype` varchar(50) character set ascii NOT NULL default 'text/html',
  `abstract` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `abstract_hyphens` text character set ascii,
  `body` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `body_hyphens` longtext character set ascii,
  `keywords` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_visit` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_article` bigint(20) NOT NULL, -- rel to article.ID_entity
  `visit_ref` varchar(20) character set ascii NOT NULL default '',
--  `visit_ref_full` varchar(128) character set ascii NOT NULL default '',
  `page_code` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_article`),
  KEY `SEL_0` (`ID_article`,`datetime_event`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8; -- must be myisam because inserting with insert delayed

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_visit_arch` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_article` bigint(20) NOT NULL,
  `visit_ref` varchar(20) character set ascii NOT NULL default '',
--  `visit_ref_full` varchar(128) character set ascii NOT NULL default '',
  `page_code` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  KEY `datetime_event` (`datetime_event`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_keyword_income` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_article` bigint(20) NOT NULL, -- rel to article.ID_entity
  `keyword` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `page_code` varchar(8) character set ascii collate ascii_bin NOT NULL default '',
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_article`,`keyword`),
  KEY `SEL_0` (`ID_article`,`datetime_event`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8; -- must be myisam because inserting with insert delayed

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `uuid` char(36) character set ascii default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_cat_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `uuid` char(36) character set ascii default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_cat_metaindex` (
  `ID` bigint(20) unsigned NOT NULL, -- ref _article_cat.ID
  `meta_section` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_value` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`meta_section`,`meta_variable`),
  KEY `SEL_0` (`meta_section`,`meta_variable`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_emo` ( -- experimental EMO characteristics
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel article.ID_entity
  `datetime_create` datetime NOT NULL,
  `emo_sad` int(10) unsigned NOT NULL default '0',
  `emo_angry` int(10) unsigned NOT NULL default '0',
  `emo_confused` int(10) unsigned NOT NULL default '0',
  `emo_love` int(10) unsigned NOT NULL default '0',
  `emo_omg` int(10) unsigned NOT NULL default '0',
  `emo_smile` int(10) unsigned NOT NULL default '0',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_emo_j` (
  `ID` mediumint(8) unsigned NOT NULL,
  `ID_entity` mediumint(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `emo_sad` int(10) unsigned NOT NULL default '0',
  `emo_angry` int(10) unsigned NOT NULL default '0',
  `emo_confused` int(10) unsigned NOT NULL default '0',
  `emo_love` int(10) unsigned NOT NULL default '0',
  `emo_omg` int(10) unsigned NOT NULL default '0',
  `emo_smile` int(10) unsigned NOT NULL default '0',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_emo_vote` (
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_part` mediumint(8) unsigned NOT NULL,
  `datetime_event` datetime NOT NULL,
  `emo` varchar(8) character set ascii NOT NULL default ''
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_ent_rel_published` (
  `ID_ent` bigint(20) unsigned NOT NULL, -- rel article_ent.ID
  `ID_published` mediumint(8) unsigned NOT NULL, -- rel article_published.ID
  UNIQUE KEY `UNI_0` (`ID_ent`,`ID_published`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_published` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `name` varchar(256) character set utf8 collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_article_vote` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned NOT NULL, -- rel article.ID_entity
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `datetime_event` datetime NOT NULL,
  `IP` varchar(15) default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_article_emo_view` AS (
	SELECT
		emo.ID,
      emo.ID_entity,
		(emo.emo_sad + emo.emo_angry + emo.emo_confused + emo.emo_love + emo.emo_omg + emo.emo_smile) AS emo_all,
      (emo.emo_sad/(GREATEST(emo.emo_sad,emo.emo_angry,emo.emo_confused,emo.emo_love,emo.emo_omg,emo.emo_smile)/100))
			AS emo_sad_perc,
		(emo.emo_angry/(GREATEST(emo.emo_sad,emo.emo_angry,emo.emo_confused,emo.emo_love,emo.emo_omg,emo.emo_smile)/100))
			AS emo_angry_perc,
		(emo.emo_confused/(GREATEST(emo.emo_sad,emo.emo_angry,emo.emo_confused,emo.emo_love,emo.emo_omg,emo.emo_smile)/100))
			AS emo_confused_perc,
		(emo.emo_love/(GREATEST(emo.emo_sad,emo.emo_angry,emo.emo_confused,emo.emo_love,emo.emo_omg,emo.emo_smile)/100))
			AS emo_love_perc,
		(emo.emo_omg/(GREATEST(emo.emo_sad,emo.emo_angry,emo.emo_confused,emo.emo_love,emo.emo_omg,emo.emo_smile)/100))
			AS emo_omg_perc,
		(emo.emo_smile/(GREATEST(emo.emo_sad,emo.emo_angry,emo.emo_confused,emo.emo_love,emo.emo_omg,emo.emo_smile)/100))
			AS emo_smile_perc
	FROM
		`/*db_name*/`.`/*app*/_article_emo` AS emo
	WHERE
		(emo.emo_sad + emo.emo_angry + emo.emo_confused + emo.emo_love + emo.emo_omg + emo.emo_smile) > 5
)

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_article_emo_viewEQ` AS (
	SELECT
		emo1.ID AS emo1_ID,
		emo2.ID AS emo2_ID,
      ABS(emo1.emo_sad_perc - emo2.emo_sad_perc) AS emo_sad_diff,
		ABS(emo1.emo_angry_perc - emo2.emo_angry_perc) AS emo_angry_diff,
		ABS(emo1.emo_confused_perc - emo2.emo_confused_perc) AS emo_confused_diff,
		ABS(emo1.emo_love_perc - emo2.emo_love_perc) AS emo_love_diff,
		ABS(emo1.emo_omg_perc - emo2.emo_omg_perc) AS emo_omg_diff,
		ABS(emo1.emo_smile_perc - emo2.emo_smile_perc) AS emo_smile_diff,
		(100-((
			ABS(emo1.emo_sad_perc - emo2.emo_sad_perc) +
			ABS(emo1.emo_angry_perc - emo2.emo_angry_perc) +
			ABS(emo1.emo_confused_perc - emo2.emo_confused_perc) +
			ABS(emo1.emo_love_perc - emo2.emo_love_perc) +
			ABS(emo1.emo_omg_perc - emo2.emo_omg_perc) +
			ABS(emo1.emo_smile_perc - emo2.emo_smile_perc)
		)/6)) AS EQ
	FROM
		`/*db_name*/`.`/*app*/_article_emo_view` AS emo1,
		`/*db_name*/`.`/*app*/_article_emo_view` AS emo2
	WHERE
		emo1.ID <> emo2.ID AND
      emo1.emo_all > 100 AND
      emo2.emo_all > 100
)

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
		
		article_ent.posix_owner, -- first editor
		article_content.ID_editor AS posix_editor, -- last editor
		article_ent.ID_author AS posix_author,
		article_ent.sources,
		
		article_content.datetime_create,
		DATE_FORMAT(article_attrs.datetime_start, '%Y-%m-%d %H:%i') AS datetime_start,
		DATE_FORMAT(article_attrs.datetime_stop, '%Y-%m-%d %H:%i') AS datetime_stop,
		
		article_attrs.priority_A,
		article_attrs.priority_B,
		article_attrs.priority_C,
		article_attrs.priority_D,
		article_attrs.priority_E,
		article_attrs.priority_F,
		
		article_attrs.name,
		article_attrs.name_url,
		article_attrs.alias_url,
		article_content.subtitle,
		article_content.mimetype,
		article_content.abstract,
		article_content.body,
		article_content.keywords,
		article_content.lng,
		article_content.version,
		
--		article.status AS status_article,
--		article_attrs.status AS status_attrs,
		article_content.status AS status_content,
		
		article_ent.visits,
		article_ent.rating_score,
		article_ent.rating_votes,
		article_ent.metadata,
		(article_ent.rating_score/article_ent.rating_votes) AS rating,
		article_ent.published_mark,
		
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
		article_content.lng = article_attrs.lng AND
		article_content.status = 'Y'
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_article_cat` AS article_cat ON
	(
		article_cat.ID = article_attrs.ID_category
	)
	
	WHERE
		article_ent.ID AND
		article_attrs.ID
	ORDER BY
		article_attrs.datetime_start DESC
)

-- --------------------------------------------------
