-- db_h=main
-- app=a542
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file_ent` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel file.ID_entity
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_author` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `downloads` int(10) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `posix_author` (`posix_author`),
  KEY `downloads` (`downloads`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file_ent_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_author` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `downloads` int(10) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file_attrs` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel file.ID
  `ID_category` bigint(20) unsigned default NULL, -- rel file_dir.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `name_ext` varchar(120) character set ascii NOT NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
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

CREATE TABLE `/*db_name*/`.`/*app*/_file_attrs_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel 
  `ID_category` bigint(20) unsigned default NULL, -- rel file_dir.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `name_ext` varchar(120) character set ascii NOT NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file_item` (
  `ID` mediumint(8) unsigned zerofill NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `description` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL,
  `mimetype` varchar(50) character set ascii NOT NULL default 'binary',
  `file_size` bigint(20) unsigned default NULL,
  `file_checksum` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `file_ext` varchar(120) character set ascii NOT NULL, -- only for storage
  `hash_secure` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID` (`ID`),
  KEY `description` (`description`),
  KEY `mimetype` (`mimetype`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file_item_j` (
  `ID` mediumint(8) unsigned zerofill NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `description` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL,
  `mimetype` varchar(50) character set ascii NOT NULL default 'binary',
  `file_size` bigint(20) unsigned default NULL,
  `file_checksum` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `file_ext` varchar(120) character set ascii NOT NULL,
  `hash_secure` varchar(32) character set ascii collate ascii_bin NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file_download` (
  `datetime_event` datetime NOT NULL,
  `IP` varchar(15) character set ascii default NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_file` bigint(20) NOT NULL, -- ref _file.ID_entity
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_file`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_file_dir` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
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

CREATE TABLE `/*db_name*/`.`/*app*/_file_dir_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_file_view` AS (
	SELECT
		CONCAT(file.ID_entity,'-',file.ID,'-',file_attrs.lng) AS ID,
		
		file.ID_entity AS ID_entity_file,
		file.ID AS ID_file,
		file_attrs.ID AS ID_attrs,
		file_item.ID AS ID_item,
		
		file_attrs.ID_category,
		file_dir.name AS ID_dir_name,
		file_dir.name_url AS ID_dir_name_url,
		
		file_ent.posix_owner,
		file_ent.posix_author,
		
		file_item.hash_secure,
		file_item.datetime_create,
		
		file_attrs.name,
		file_attrs.name_url,
		file_attrs.name_ext,
		
		file_item.mimetype,
		file_item.file_ext,
		file_item.file_size,
		file_item.lng,
		
		file_ent.downloads,
		
		file_attrs.status,
		
		CONCAT(file_item.lng,'/',SUBSTR(file_item.ID,1,4),'/',file_item.name,'.',file_attrs.name_ext) AS file_path,
      
		IF
		(
			(
				file.status LIKE 'Y' AND
				file_attrs.status LIKE 'Y' AND
				file_item.status LIKE 'Y'
			),
			 'Y', 'U'
		) AS status_all
		
	FROM
		`/*db_name*/`.`/*app*/_file` AS file
	LEFT JOIN `/*db_name*/`.`/*app*/_file_ent` AS file_ent ON
	(
		file_ent.ID_entity = file.ID_entity
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_file_attrs` AS file_attrs ON
	(
		file_attrs.ID_entity = file.ID
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_file_item` AS file_item ON
	(
		file_item.ID_entity = file.ID_entity AND
		file_item.lng = file_attrs.lng
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_file_dir` AS file_dir ON
	(
		file_dir.ID = file_attrs.ID_category
	)
	
	WHERE
		file_ent.ID AND
		file_attrs.ID AND
		file_item.ID
)

-- --------------------------------------------------
