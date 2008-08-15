-- db_h=main
-- addon=a501
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_ent` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel image.ID_entity
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_author` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `visits` int(10) unsigned NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `visits` (`visits`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_ent_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_author` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `visits` int(10) unsigned NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_rating_vote` (
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_image` mediumint(8) unsigned NOT NULL, -- ref _image.ID_entity
  `datetime_event` datetime NOT NULL,
  `score` int(10) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_attrs` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel image.ID
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `description` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `keywords` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `ID_category` (`ID_category`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_attrs_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `description` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `keywords` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_file` (
  `ID` mediumint(8) unsigned zerofill NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel image.ID_entity
  `ID_format` bigint(20) unsigned NOT NULL,
  `name` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_check` datetime default NULL,
  `image_width` int(10) unsigned NOT NULL,
  `image_height` int(10) unsigned NOT NULL,
  `file_size` bigint(20) unsigned default NULL,
  `file_checksum` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `file_ext` varchar(120) character set ascii NOT NULL,
  `from_parent` char(1) character set ascii NOT NULL default 'Y', -- is this file generated from parent image_file?
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`ID_format`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `ID_format` (`ID_format`),
  KEY `name` (`name`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_file_j` (
  `ID` mediumint(8) unsigned zerofill NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_format` bigint(20) unsigned NOT NULL,
  `name` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_check` datetime default NULL,
  `image_width` int(10) unsigned NOT NULL,
  `image_height` int(10) unsigned NOT NULL,
  `file_size` bigint(20) unsigned default NULL,
  `file_checksum` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `file_ext` varchar(120) character set ascii NOT NULL,
  `from_parent` char(1) character set ascii NOT NULL default 'Y',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_visit` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_image` bigint(20) NOT NULL,
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_image`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_emo` ( -- experimental EMO characteristics
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel _image.ID_entity
  `datetime_create` datetime NOT NULL,
  `emo_sad` int(10) unsigned NOT NULL default '0',
  `emo_angry` int(10) unsigned NOT NULL default '0',
  `emo_confused` int(10) unsigned NOT NULL default '0',
  `emo_love` int(10) unsigned NOT NULL default '0',
  `emo_omg` int(10) unsigned NOT NULL default '0',
  `emo_smile` int(10) unsigned NOT NULL default '0',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_emo_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `emo_angry` int(10) unsigned NOT NULL default '0',
  `emo_confused` int(10) unsigned NOT NULL default '0',
  `emo_love` int(10) unsigned NOT NULL default '0',
  `emo_omg` int(10) unsigned NOT NULL default '0',
  `emo_sad` int(10) unsigned NOT NULL default '0',
  `emo_smile` int(10) unsigned NOT NULL default '0',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_emo_vote` (
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_image` mediumint(8) unsigned NOT NULL, -- rel _image.ID_entity
  `datetime_event` datetime NOT NULL,
  `emo` varchar(8) character set ascii NOT NULL default ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*addon*/_image_emo_view` AS (
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
		`/*db_name*/`.`/*addon*/_image_emo` AS emo
	WHERE
		(emo.emo_sad + emo.emo_angry + emo.emo_confused + emo.emo_love + emo.emo_omg + emo.emo_smile) > 5
)

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*addon*/_image_emo_viewEQ` AS (
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
		`/*db_name*/`.`/*addon*/_image_emo_view` AS emo1,
		`/*db_name*/`.`/*addon*/_image_emo_view` AS emo2
	WHERE
		emo1.ID <> emo2.ID AND
      emo1.emo_all > 100 AND
      emo2.emo_all > 100
)

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_cat` (
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
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_cat_j` (
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

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_format` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `process` tinytext character set ascii NOT NULL,
  `required` char(1) NOT NULL default 'Y',
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_image_format_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `process` tinytext character set ascii NOT NULL,
  `required` char(1) NOT NULL default 'Y',
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*addon*/_image_view` AS (
	SELECT
		CONCAT(image.ID_entity,'-',image.ID,'-',image_attrs.lng,'-',image_format.ID) AS ID,
		
		image.ID_entity AS ID_entity_image,
		image.ID AS ID_image,
		image_attrs.ID AS ID_attrs,
		image_file.ID_format AS ID_format,
		image_format.name AS ID_format_name,
		image_file.ID AS ID_file,
		
		image_attrs.datetime_create,
		image_attrs.ID_category,
		image_cat.name AS ID_category_name,
		
		image_ent.posix_owner,
		image_ent.posix_author,
		
		image_attrs.name,
		image_attrs.description,
		image_attrs.keywords,
		image_attrs.order_id,
		image_attrs.lng,
		
		image_file.image_width,
		image_file.image_height,
		image_file.file_size,
		image_file.file_ext,
		
		CONCAT(image_file.ID_format,'/',SUBSTR(image_file.ID,1,4),'/',image_file.name,'.',image_file.file_ext) AS file_path,
		
		IF
		(
			(
				image_format.datetime_create <= image_file.datetime_create
			),
			 'Y', 'U'
		) AS processed,
		
		image_attrs.status,
		
		IF
		(
			(
				image.status LIKE 'Y' AND
				image_attrs.status LIKE 'Y' AND
				image_format.status IN ('Y','L') AND
				image_file.status LIKE 'Y'
			),
			 'Y', 'U'
		) AS status_all
		
	FROM
		`/*db_name*/`.`/*addon*/_image` AS image
	LEFT JOIN `/*db_name*/`.`/*addon*/_image_ent` AS image_ent ON
	(
		image_ent.ID_entity = image.ID_entity
	)
	LEFT JOIN `/*db_name*/`.`/*addon*/_image_attrs` AS image_attrs ON
	(
		image_attrs.ID_entity = image.ID
	)
	LEFT JOIN `/*db_name*/`.`/*addon*/_image_file` AS image_file ON
	(
		image_file.ID_entity = image.ID_entity
	)
	LEFT JOIN `/*db_name*/`.`/*addon*/_image_format` AS image_format ON
	(
		image_format.ID = image_file.ID_format
	)
	LEFT JOIN `/*db_name*/`.`/*addon*/_image_cat` AS image_cat ON
	(
		image_cat.ID = image_attrs.ID_category
	)
	
	WHERE
		image.ID AND
		image_attrs.ID
)

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*addon*/_image_view_thumbnail` AS (
	SELECT
		*
	FROM
		`/*db_name*/`.`/*addon*/_image_view` AS image
	WHERE
		image.ID_format_name='thumbnail'
)

-- --------------------------------------------------

