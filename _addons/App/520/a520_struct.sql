-- db_h=main
-- addon=a520
-- version=5.6

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_rec_start` datetime DEFAULT NULL,
  `datetime_rec_stop` datetime DEFAULT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `datetime_rec_start` (`datetime_rec_start`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_j` (
  `ID` mediumint(8) unsigned NOT NULL,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_rec_start` datetime DEFAULT NULL,
  `datetime_rec_stop` datetime DEFAULT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_ent` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL, -- ref _audio.ID_entity
  `datetime_create` datetime NOT NULL,
  `datetime_rec_start` datetime DEFAULT NULL,
  `datetime_rec_stop` datetime DEFAULT NULL,
  `posix_owner` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `posix_author` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `posix_modified` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `keywords` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `audio_length` time DEFAULT NULL,
  `audio_note` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `metadata` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_ent_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_rec_start` datetime DEFAULT NULL,
  `datetime_rec_stop` datetime DEFAULT NULL,
  `posix_owner` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `posix_author` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `posix_modified` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `keywords` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `audio_length` time DEFAULT NULL,
  `audio_note` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `metadata` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_ent_metaindex` (
  `ID` bigint(20) unsigned NOT NULL, -- ref _audio_ent.ID
  `meta_section` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `meta_variable` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `meta_value` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`,`meta_section`,`meta_variable`),
  KEY `SEL_0` (`meta_section`,`meta_variable`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_attrs` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL, -- rel _audio.ID
  `ID_category` bigint(20) unsigned DEFAULT NULL, -- rel _audio_cat.ID_entity
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime DEFAULT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `description` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `priority_A` tinyint(3) unsigned DEFAULT NULL,
  `priority_B` tinyint(3) unsigned DEFAULT NULL,
  `priority_C` tinyint(3) unsigned DEFAULT NULL,
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT '',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `SEL_0` (`status`,`lng`,`datetime_publish_start`),
  KEY `SEL_1` (`datetime_publish_start`,`datetime_publish_stop`),
  KEY `SEL_2` (`ID_category`,`status`,`lng`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `order_id` (`order_id`),
  KEY `datetime_publish_stop` (`datetime_publish_stop`),
  KEY `priority_A` (`priority_A`),
  KEY `priority_B` (`priority_B`),
  KEY `priority_C` (`priority_C`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_attrs_j` (
  `ID` mediumint(8) unsigned NOT NULL,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL,
  `ID_category` bigint(20) unsigned DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime DEFAULT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `description` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `priority_A` tinyint(3) unsigned DEFAULT NULL,
  `priority_B` tinyint(3) unsigned DEFAULT NULL,
  `priority_C` tinyint(3) unsigned DEFAULT NULL,
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT '',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL, -- rel _audio.ID_entity
  `part_id` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `ID_brick` mediumint(8) unsigned DEFAULT NULL, -- rel _audio_brick.ID
  `datetime_create` datetime NOT NULL,
  `datetime_air` datetime DEFAULT '2000-01-01 00:00:00',
  `visits` int(10) unsigned NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `rating` int(10) unsigned NOT NULL,
  `keywords` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `process_lock` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `thumbnail_lock` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_brick` (`ID_brick`),
  KEY `visits` (`visits`),
  KEY `rating` (`rating`),
  KEY `part_id` (`part_id`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_j` (
  `ID` mediumint(8) unsigned NOT NULL,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL, -- rel _audio.ID_entity
  `part_id` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `ID_brick` mediumint(8) unsigned DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_air` datetime DEFAULT '2000-01-01 00:00:00',
  `visits` int(10) unsigned NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `rating` int(10) unsigned NOT NULL,
  `keywords` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `process_lock` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `thumbnail_lock` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_rating_vote` (
  `ID_user` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `user_token` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `ID_part` mediumint(8) unsigned NOT NULL,
  `datetime_event` datetime NOT NULL,
  `score` int(10) unsigned NOT NULL,
  KEY `ID_user` (`ID_user`),
  KEY `user_token` (`user_token`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_smil` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL, -- rel _audio_part.ID
  `datetime_create` datetime NOT NULL,
  `name` varchar(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_smil_j` (
  `ID` mediumint(8) unsigned NOT NULL,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `name` varchar(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_caption` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL, -- rel _audio_part.ID
  `datetime_create` datetime NOT NULL,
  `time_start` time NOT NULL,
  `time_stop` time NOT NULL,
  `caption` varchar(128) NOT NULL DEFAULT '',
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT '',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`),
  FULLTEXT KEY `FULL_0` (`caption`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`time_start`,`lng`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_caption_j` (
  `ID` mediumint(8) unsigned NOT NULL,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `time_start` time NOT NULL,
  `time_stop` time NOT NULL,
  `caption` varchar(128) NOT NULL DEFAULT '',
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT '',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_callback` (
  `ID_part` mediumint(8) unsigned NOT NULL,
  `datetime_create` datetime NOT NULL,
  `ID_user` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `IP` varchar(15) CHARACTER SET ascii DEFAULT NULL,
  `country_code` char(3) CHARACTER SET ascii DEFAULT NULL,
  `duration` int(10) unsigned NOT NULL DEFAULT '0',
  `state` varchar(10) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  KEY `datetime_create` (`datetime_create`),
  KEY `country_code` (`country_code`),
  KEY `SEL_0` (`ID_user`,`datetime_create`),
  KEY `SEL_1` (`ID_part`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_callback_arch` (
  `ID_part` mediumint(8) unsigned NOT NULL,
  `datetime_create` datetime NOT NULL,
  `ID_user` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `IP` varchar(15) CHARACTER SET ascii DEFAULT NULL,
  `country_code` char(3) CHARACTER SET ascii DEFAULT NULL,
  `duration` int(10) unsigned NOT NULL DEFAULT '0',
  `state` varchar(10) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  KEY `datetime_create` (`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_attrs` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL, -- rel _audio_part.ID
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `description` tinytext CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT '',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_attrs_j` (
  `ID` mediumint(8) unsigned NOT NULL,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL, -- rel _audio_part.ID
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `description` tinytext CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT '',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_file` (
  `ID` mediumint(8) unsigned zerofill NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL, -- rel _audio_part.ID
  `ID_format` bigint(20) unsigned NOT NULL,
  `name` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `audio_codec` varchar(50) CHARACTER SET ascii NOT NULL,
  `audio_bitrate` int(10) unsigned NOT NULL,
  `length` time NOT NULL,
  `file_alt_src` varchar(250) CHARACTER SET ascii DEFAULT NULL,
  `file_size` bigint(20) unsigned DEFAULT NULL,
  `file_checksum` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `file_ext` varchar(120) CHARACTER SET ascii NOT NULL,
  `from_parent` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N', -- is this file generated from parent audio_part_file?
  `regen` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N', -- regenerate this audio_part_file?
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`ID_format`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_format` (`ID_format`),
  KEY `name` (`name`),
  KEY `regen` (`regen`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_file_j` (
  `ID` mediumint(8) unsigned zerofill NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL,
  `ID_format` bigint(20) unsigned NOT NULL,
  `name` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `audio_codec` varchar(50) CHARACTER SET ascii NOT NULL,
  `audio_bitrate` int(10) unsigned NOT NULL,
  `length` time NOT NULL,
  `file_alt_src` varchar(250) CHARACTER SET ascii DEFAULT NULL,
  `file_size` bigint(20) unsigned DEFAULT NULL,
  `file_checksum` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `file_ext` varchar(120) CHARACTER SET ascii NOT NULL,
  `from_parent` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `regen` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_part_file_process` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_part` mediumint(8) unsigned DEFAULT NULL, -- rel _audio_part.ID
  `ID_format` bigint(20) unsigned NOT NULL, -- rel _audio_format.ID_entity
  `hostname` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `hostname_PID` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `process` text CHARACTER SET ascii NOT NULL,
  `process_output` text CHARACTER SET ascii NOT NULL,
  `datetime_start` datetime NOT NULL,
  `datetime_stop` datetime DEFAULT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'W',
  PRIMARY KEY (`ID`),
  KEY `SEL_0` (`ID_part`,`ID_format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_brick` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` mediumint(8) unsigned DEFAULT NULL,
  `name` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, -- class name
  `datetime_create` datetime NOT NULL,
  `dontprocess` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_visit` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `ID_audio` bigint(20) NOT NULL,
  PRIMARY KEY (`datetime_event`,`ID_user`,`ID_audio`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_cat` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_charindex` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `alias_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `posix_owner` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_modified` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `posix_perms` char(9) CHARACTER SET ascii NOT NULL DEFAULT 'rwxrw-r--',
  `keywords` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `datetime_create` datetime NOT NULL,
  `description` longtext CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `ID_brick` mediumint(8) unsigned DEFAULT NULL, -- rel _audio_brick.ID
  `metadata` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT '',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_charindex` (`ID_charindex`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_cat_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_charindex` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `alias_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `posix_owner` varchar(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_modified` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `posix_perms` char(9) CHARACTER SET ascii NOT NULL DEFAULT 'rwxrw-r--',
  `keywords` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `datetime_create` datetime NOT NULL,
  `description` longtext CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `ID_brick` mediumint(8) unsigned DEFAULT NULL,
  `metadata` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT '',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_format` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_charindex` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `process` text CHARACTER SET ascii NOT NULL,
  `definition` text CHARACTER SET ascii,
  `required_min_bitrate` int(10) unsigned DEFAULT NULL,
  `required` char(1) NOT NULL DEFAULT 'Y',
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT 'xx',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_charindex` (`ID_charindex`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_audio_format_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_charindex` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `process` text CHARACTER SET ascii NOT NULL,
  `definition` text CHARACTER SET ascii,
  `required_min_bitrate` int(10) unsigned DEFAULT NULL,
  `required` char(1) NOT NULL DEFAULT 'Y',
  `lng` char(5) CHARACTER SET ascii NOT NULL DEFAULT 'xx',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_broadcast_channel` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `name` (`name`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_broadcast_channel_state` ( -- switching of broadcasting / not broadcasting
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL, -- rel _broadcast_channel.ID_entity
  `description` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N', -- Y = live, N = not streaming
  PRIMARY KEY (`ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_broadcast_program` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_channel` bigint(20) unsigned DEFAULT '0', -- rel _live_channel.ID_entity
  `ID_series` bigint(20) unsigned DEFAULT NULL, -- internal rel _broadcast_series.ID_entity
  `ID_audio` bigint(20) unsigned DEFAULT NULL, -- internal rel _audio.ID_entity
  `program_code` varchar(64) CHARACTER SET ascii DEFAULT NULL, -- number of program - not unique
  `program_type_code` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_original` varchar(256) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `name_url` varchar(256) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `subtitle` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `synopsis` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `description` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `datetime_air_start` datetime NOT NULL,
  `datetime_air_stop` datetime NOT NULL,
  `datetime_real_start` datetime DEFAULT NULL,
  `datetime_real_start_msec` smallint(3) unsigned zerofill DEFAULT NULL,
  `datetime_real_stop` datetime DEFAULT NULL,
  `datetime_real_stop_msec` smallint(3) unsigned zerofill DEFAULT NULL,
  `datetime_real_status` char(1) CHARACTER SET ascii DEFAULT NULL, -- status of broadcasting NULL/Y = true
  `authoring_year` year(4) DEFAULT NULL,
  `authoring_country` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `authoring_cast` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `authoring_authors` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `license_valid_to` datetime DEFAULT NULL,
  `series_ID` bigint(20) unsigned DEFAULT NULL,
  `series_type` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `series_code` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `series_episode` smallint(5) unsigned DEFAULT NULL,
  `series_episodes` smallint(5) unsigned DEFAULT NULL,
  `audio_mode` varchar(12) CHARACTER SET ascii DEFAULT NULL,
  `audio_dubbing` char(1) CHARACTER SET ascii DEFAULT NULL,
  `rating_pg` char(1) CHARACTER SET ascii DEFAULT NULL,
  `accessibility_deaf` char(1) CHARACTER SET ascii DEFAULT NULL,
  `accessibility_cc` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_archive` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_premiere` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_live` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_live_geoblock` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_internet` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_geoblock` char(1) CHARACTER SET ascii DEFAULT NULL,
  `recording` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N', -- it is recording now
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `metadata` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UNI_0` (`ID_channel`,`program_code`,`datetime_air_start`),
  KEY `ID_entity` (`ID_entity`),
  KEY `name` (`name`,`datetime_air_start`),
  KEY `datetime_air_start` (`datetime_air_start`,`datetime_air_stop`),
  KEY `ID_series` (`ID_series`),
  KEY `series_ID` (`series_ID`),
  KEY `status` (`status`,`status_internet`,`status_premiere`,`status_live`),
  KEY `ID_channel` (`ID_channel`,`datetime_air_stop`,`datetime_air_start`),
  KEY `SEL_0` (`status`,`datetime_real_stop`),
  KEY `SEL_1` (`status`,`datetime_real_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_broadcast_program_j` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_channel` bigint(20) unsigned DEFAULT '0',
  `ID_series` bigint(20) unsigned DEFAULT NULL,
  `ID_audio` bigint(20) unsigned DEFAULT NULL,
  `program_code` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `program_type_code` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_original` varchar(256) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `name_url` varchar(256) CHARACTER SET ascii NOT NULL DEFAULT '',
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `subtitle` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `synopsis` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `description` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `datetime_air_start` datetime NOT NULL,
  `datetime_air_stop` datetime NOT NULL,
  `datetime_real_start` datetime DEFAULT NULL,
  `datetime_real_start_msec` smallint(3) unsigned zerofill DEFAULT NULL,
  `datetime_real_stop` datetime DEFAULT NULL,
  `datetime_real_stop_msec` smallint(3) unsigned zerofill DEFAULT NULL,
  `datetime_real_status` char(1) CHARACTER SET ascii DEFAULT NULL,
  `authoring_year` year(4) DEFAULT NULL,
  `authoring_country` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `authoring_cast` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `authoring_authors` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `license_valid_to` datetime DEFAULT NULL,
  `series_ID` bigint(20) unsigned DEFAULT NULL,
  `series_type` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `series_code` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `series_episode` smallint(5) unsigned DEFAULT NULL,
  `series_episodes` smallint(5) unsigned DEFAULT NULL,
  `audio_mode` varchar(12) CHARACTER SET ascii DEFAULT NULL,
  `audio_dubbing` char(1) CHARACTER SET ascii DEFAULT NULL,
  `rating_pg` char(1) CHARACTER SET ascii DEFAULT NULL,
  `accessibility_deaf` char(1) CHARACTER SET ascii DEFAULT NULL,
  `accessibility_cc` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_archive` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_premiere` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_live` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_live_geoblock` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_internet` char(1) CHARACTER SET ascii DEFAULT NULL,
  `status_geoblock` char(1) CHARACTER SET ascii DEFAULT NULL,
  `recording` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  `metadata` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_broadcast_series` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_channel` bigint(20) unsigned DEFAULT '0', -- rel _broadcast_channel.ID_entity
  `parent_ID` bigint(20) unsigned DEFAULT NULL, -- ref ID_entity
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '', -- series name
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `name_original` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `program_code` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `program_type_code` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `authoring_year` year(4) DEFAULT NULL,
  `authoring_country` varchar(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `authoring_cast` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `authoring_authors` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `series_ID` bigint(20) unsigned DEFAULT NULL, -- external ID (IBDm/...)
  `series_type` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `series_code` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `series_episodes` smallint(5) unsigned DEFAULT NULL,
  `posix_owner` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `posix_modified` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `synopsis` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `body` longtext CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL, -- description + content
  `metadata` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y', -- display Y/N/T
  PRIMARY KEY (`ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `parent_ID` (`parent_ID`),
  KEY `series_ID` (`series_ID`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_broadcast_series_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_channel` bigint(20) unsigned DEFAULT '0',
  `parent_ID` bigint(20) unsigned DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',
  `name_original` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `program_code` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `program_type_code` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `authoring_year` year(4) DEFAULT NULL,
  `authoring_country` varchar(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `authoring_cast` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `authoring_authors` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `series_ID` bigint(20) unsigned DEFAULT NULL,
  `series_type` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `series_code` varchar(6) CHARACTER SET ascii DEFAULT NULL,
  `series_episodes` smallint(5) unsigned DEFAULT NULL,
  `posix_owner` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `posix_modified` varchar(8) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `synopsis` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `body` longtext CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `metadata` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_broadcast_schedule` ( -- schedule with realtime and commercials
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ID_entity` bigint(20) unsigned DEFAULT NULL,
  `ID_channel` bigint(20) unsigned DEFAULT NULL, -- rel _broadcast_channel.ID_entity
  `program_code` varchar(64) CHARACTER SET ascii DEFAULT NULL, -- number of program - not unique
  `name` varchar(250) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name_url` varchar(256) CHARACTER SET ascii NOT NULL DEFAULT '',
  `artist` varchar(256) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `album` varchar(256) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `track` varchar(256) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_start` datetime(3) NOT NULL,
  `datetime_stop` datetime(3) NOT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'N',
  PRIMARY KEY (`ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `name` (`name`),
  KEY `datetime_start` (`datetime_start`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

