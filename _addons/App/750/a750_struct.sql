-- db_h=main
-- addon=a750
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_complex` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `owner_occupied` char(1) character set ascii NOT NULL default 'N',
  `rental_park` char(1) character set ascii NOT NULL default 'N',
  `land` char(1) character set ascii NOT NULL default 'N',
  `park` char(1) character set ascii NOT NULL default 'N',
  `code` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! there is also name in complex_lng table, which is not curently used
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! there is also name_url in complex_lng table, which is not curently used
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `industry` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `complex_type` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `clear_height` bigint(20) unsigned default NULL,
  `clear_height_to` bigint(20) unsigned default NULL,
  `floor_loading_capacity` bigint(20) unsigned default NULL,
  `floor_loading_capacity_to` bigint(20) unsigned default NULL,
  `truck_yard_depth` bigint(20) unsigned default NULL,
  `truck_yard_depth_to` bigint(20) unsigned default NULL,
  `cross_dock` char(1) character set ascii collate ascii_bin DEFAULT 'N',
  `dock_doors_amount` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `city` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `county` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `country_code` char(3) character set ascii default NULL,
  `street` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `url_google_maps` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `url_web` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `geo_lat` decimal(10,8) DEFAULT NULL,
  `geo_lon` decimal(11,8) DEFAULT NULL,
  `year` varchar(4) DEFAULT NULL,
  `transport_availability` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `SEL_0` (`ID_entity`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_complex_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `owner_occupied` char(1) character set ascii NOT NULL default 'N',
  `rental_park` char(1) character set ascii NOT NULL default 'N',
  `land` char(1) character set ascii NOT NULL default 'N',
  `park` char(1) character set ascii NOT NULL default 'N',
  `code` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! there is also name in complex_lng table, which is not curently used
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! there is also name_url in complex_lng table, which is not curently used
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `industry` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `complex_type` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `clear_height` bigint(20) unsigned default NULL,
  `clear_height_to` bigint(20) unsigned default NULL,
  `floor_loading_capacity` bigint(20) unsigned default NULL,
  `floor_loading_capacity_to` bigint(20) unsigned default NULL,
  `truck_yard_depth` bigint(20) unsigned default NULL,
  `truck_yard_depth_to` bigint(20) unsigned default NULL,
  `cross_dock` char(1) character set ascii collate ascii_bin DEFAULT 'N',
  `dock_doors_amount` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `city` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `county` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `country_code` char(3) character set ascii default NULL,
  `street` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `url_google_maps` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `url_web` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `geo_lat` decimal(10,8) DEFAULT NULL,
  `geo_lon` decimal(11,8) DEFAULT NULL,
  `year` varchar(4) DEFAULT NULL,
  `transport_availability` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_complex_lng` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _complex.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! this field is not currently used, see name in complex table
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! this field is not currently used, see name_url in complex table
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_complex_lng_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _complex.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! this field is not currently used, see name in complex table
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! this field is not currently used, see name_url in complex table
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_complex_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_complex_cat_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_complex_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _complex_cat.ID_entity
  `ID_complex` bigint(20) unsigned NOT NULL, -- rel _complex.ID_entity,
  PRIMARY KEY  (`ID_category`,`ID_complex`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_object` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _complex.ID_entity
  `code` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! there is also name in object_lng table, which is not curently used
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! there is also name_url in object_lng table, which is not curently used
  `status_object` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `size_sqm` bigint(20) unsigned default NULL,
  `year_built` varchar(4) DEFAULT NULL,
  `city` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `county` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `country_code` char(3) character set ascii default NULL,
  `street` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `geo_lat` decimal(10,8) DEFAULT NULL,
  `geo_lon` decimal(11,8) DEFAULT NULL,
  `construction_type` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `clear_height` bigint(20) unsigned default NULL,
  `heating_system` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `truck_yard_depth` bigint(20) unsigned default NULL,
  `roof_system` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `column_grid_x` bigint(20) unsigned default NULL,
  `column_grid_y` bigint(20) unsigned default NULL,
  `services` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `cross_dock` char(1) character set ascii collate ascii_bin DEFAULT 'N',
  `dock_doors_description` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `dock_doors_amount` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `standard` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `drive_in` char(1) character set ascii collate ascii_bin DEFAULT 'N',
  `drive_in_description` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `drive_in_amount` bigint(20) unsigned default NULL,
  `sprinkler_system` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `truck_parking` bigint(20) unsigned default NULL,
  `floor_loading_capacity` bigint(20) unsigned default NULL,
  `car_parking` bigint(20) unsigned default NULL,
  `solar_panels` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `average_lighting` bigint(20) unsigned default NULL,
  `fire_load` bigint(20) unsigned default NULL,
  `facade_isolation` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `general_constructor` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `insulation_type` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `SEL_0` (`ID_entity`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_object_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _complex.ID_entity
  `code` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! there is also name in object_lng table, which is not curently used
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! there is also name_url in object_lng table, which is not curently used
  `status_object` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `size_sqm` bigint(20) unsigned default NULL,
  `year_built` varchar(4) DEFAULT NULL,
  `city` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `county` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `country_code` char(3) character set ascii default NULL,
  `street` varchar(128) character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `street_num` varchar(12) character set ascii default NULL,
  `district` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `ZIP` varchar(16) character set ascii default NULL,
  `state` varchar(64) character set utf8 collate utf8_unicode_ci default NULL,
  `geo_lat` decimal(10,8) DEFAULT NULL,
  `geo_lon` decimal(11,8) DEFAULT NULL,
  `construction_type` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `clear_height` bigint(20) unsigned default NULL,
  `heating_system` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `truck_yard_depth` bigint(20) unsigned default NULL,
  `roof_system` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `column_grid_x` bigint(20) unsigned default NULL,
  `column_grid_y` bigint(20) unsigned default NULL,
  `services` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `cross_dock` char(1) character set ascii collate ascii_bin DEFAULT 'N',
  `dock_doors_description` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `dock_doors_amount` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `standard` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `drive_in` char(1) character set ascii collate ascii_bin DEFAULT 'N',
  `drive_in_description` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `drive_in_amount` bigint(20) unsigned default NULL,
  `sprinkler_system` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `truck_parking` bigint(20) unsigned default NULL,
  `floor_loading_capacity` bigint(20) unsigned default NULL,
  `car_parking` bigint(20) unsigned default NULL,
  `solar_panels` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `average_lighting` bigint(20) unsigned default NULL,
  `fire_load` bigint(20) unsigned default NULL,
  `facade_isolation` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `general_constructor` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `insulation_type` text character set utf8 collate utf8_unicode_ci DEFAULT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_object_lng` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _object.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! this field is not currently used, see name in object table
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! this field is not currently used, see name_url in object table
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_object_lng_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _object.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! this field is not currently used, see name in object table
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL, -- careful! this field is not currently used, see name in object table
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_area` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_complex` bigint(20) unsigned default NULL, -- ref complex.ID
  `ID_object` bigint(20) unsigned default NULL, -- ref object.ID
  `code` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `availability` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `available_from` datetime NOT NULL default '0000-00-00 00:00:00',
  `area` bigint(20) unsigned default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `SEL_0` (`ID_entity`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_area_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_complex` bigint(20) unsigned default NULL, -- ref complex.ID
  `ID_object` bigint(20) unsigned default NULL, -- ref object.ID
  `code` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- created by
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- changed by user
  `availability` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `available_from` datetime NOT NULL default '0000-00-00 00:00:00',
  `area` bigint(20) unsigned default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_area_lng` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _area.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_area_lng_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- ref _area.ID_entity
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00', -- last change
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `name_url` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_lease` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_estate_entity` bigint(20) unsigned default NULL, -- rel _area/_object/_complex.ID (defined by estate_entity_name)
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  `estate_entity_name` varchar(16) character set ascii default NULL,
  `lease_date_start` date default NULL,
  `lease_date_end` date default NULL,
  `term_years` varchar(128) character set ascii default NULL,
  `break` date default NULL,
  `incentive` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_lease_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_estate_entity` bigint(20) unsigned default NULL, -- rel _area/_object/_complex.ID (defined by estate_entity_name)
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  `estate_entity_name` varchar(16) character set ascii default NULL,
  `lease_date_start` date default NULL,
  `lease_date_end` date default NULL,
  `term_years` varchar(16) character set ascii default NULL,
  `break` date default NULL,
  `incentive` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
