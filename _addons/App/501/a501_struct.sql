-- db_h=main
-- app=a501
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_attrs` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `order_id` int(10) unsigned NOT NULL,
  `description` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_attrs_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `order_id` int(10) unsigned NOT NULL,
  `description` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_file` (
  `ID` mediumint(8) unsigned zerofill NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_format` bigint(20) unsigned NOT NULL,
  `name` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `image_width` int(10) unsigned NOT NULL,
  `image_height` int(10) unsigned NOT NULL,
  `file_size` bigint(20) unsigned default NULL,
  `file_checksum` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `file_ext` varchar(120) character set ascii NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`ID_format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_file_j` (
  `ID` mediumint(8) unsigned zerofill NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_format` bigint(20) unsigned NOT NULL,
  `name` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `image_width` int(10) unsigned NOT NULL,
  `image_height` int(10) unsigned NOT NULL,
  `file_size` bigint(20) unsigned default NULL,
  `file_checksum` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `file_ext` varchar(120) character set ascii NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_visit` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_image` bigint(20) NOT NULL,
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_image`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_cat_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_format` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `process` tinytext character set ascii NOT NULL,
  `required` char(1) NOT NULL default 'Y',
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_image_format_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `process` tinytext character set ascii NOT NULL,
  `required` char(1) NOT NULL default 'Y',
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_image_view` AS (
	SELECT
		CONCAT(image.ID_entity,'-',image.ID,'-',image_attrs.lng,'-',image_format.ID) AS ID,
		
		image.ID_entity AS ID_entity_image,
		image.ID AS ID_image,
		image_attrs.ID AS ID_attrs,
		image_file.ID_format AS ID_format,
		image_format.name AS ID_format_name,
		image_file.ID AS ID_file,
		
		image_attrs.ID_category,
		image_cat.name AS ID_category_name,
		
		image.posix_owner,
		image.posix_group,
		image.posix_perms,
		
		image_attrs.name,
		image_attrs.description,
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
		
		IF
		(
			(
				image.status LIKE 'Y' AND
				image_attrs.status LIKE 'Y' AND
				image_format.status IN ('Y','L') AND
				image_file.status LIKE 'Y'
			),
			 'Y', 'U'
		) AS status
		
	FROM
		`/*db_name*/`.`/*app*/_image` AS image
	LEFT JOIN `/*db_name*/`.`/*app*/_image_attrs` AS image_attrs ON
	(
		image_attrs.ID_entity = image.ID
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_image_file` AS image_file ON
	(
		image_file.ID_entity = image.ID_entity
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_image_format` AS image_format ON
	(
		image_format.ID = image_file.ID_format
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_image_cat` AS image_cat ON
	(
		image_cat.ID = image_attrs.ID_category
	)
	
	WHERE
		image.ID AND
		image_attrs.ID AND
		image_format.ID AND
		image_file.ID
)

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_image_view_thumbnail` AS (
	SELECT
		*
	FROM
		`/*db_name*/`.`/*app*/_image_view` AS image
	WHERE
		image.ID_format_name='thumbnail'
)

-- --------------------------------------------------