-- db_h=main
-- app=a910
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product` ( -- list of modifications
  `ID` bigint(20) unsigned NOT NULL auto_increment, -- modification of product
  `ID_entity` bigint(20) unsigned default NULL,
  `product_number` varchar(32) character set ascii default NULL, -- unique for every modification
  `ref_ID` varchar(64) character set ascii default NULL, -- external reference
  `EAN` varchar(32) character set ascii default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_process` datetime default NULL,
  `datetime_next_index` datetime default NULL,
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `amount` int(10) NOT NULL,
  `amount_unit` varchar(8) character set ascii default 'pcs',
  `amount_availability` varchar(32) NOT NULL,
  `amount_limit` int(10) default '0',
  `amount_order_min` int(10) unsigned default '1',
  `amount_order_max` int(10) unsigned default NULL,
  `amount_order_div` int(10) unsigned default '1',
  `price` decimal(12,3) default NULL, -- different modifications, different prices
  `price_previous` decimal(12,3) default NULL,
  `price_max` decimal(12,3) default NULL,
  `price_currency` varchar(3) character set ascii default 'EUR',
  `price_EUR` decimal(12,3) default NULL, -- price in EUR
  `src_data` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `sellscore` decimal(10,2) default '0.00',
  `supplier_org` bigint(20) unsigned default NULL, -- rel 710_org.ID_entity
  `supplier_person` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel 301.user_ID
  `status_new` char(1) character set ascii NOT NULL default 'N',
  `status_recommended` char(1) character set ascii NOT NULL default 'N',
  `status_sale` char(1) character set ascii NOT NULL default 'N',
  `status_special` char(1) character set ascii NOT NULL default 'N',
  `status_main` char(1) character set ascii NOT NULL default 'Y', -- is this main product, or only variation?
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  KEY `SEL_0` (`product_number`),
  KEY `SEL_1` (`ref_ID`),
  KEY `ID_entity` (`ID_entity`),
  KEY `sellscore` (`sellscore`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_reindex` (
  `datetime_event` datetime NOT NULL,
  `ID_product` bigint(20) NOT NULL,
  KEY `ID_product` (`ID_product`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8; -- must be myisam because inserting with insert delayed

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_hit` (
  `datetime_event` datetime NOT NULL,
  `ID_product` bigint(20) NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin default NULL,
  `note` varchar(32) character set utf8 collate utf8_bin default NULL,
  KEY `ID_product` (`ID_product`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8; -- must be myisam because inserting with insert delayed

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `product_number` varchar(32) character set ascii default NULL,
  `ref_ID` varchar(64) character set ascii default NULL, -- external reference
  `EAN` varchar(32) character set ascii default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_process` datetime default NULL,
  `datetime_next_index` datetime default NULL,
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `amount` int(10) NOT NULL,
  `amount_unit` varchar(8) character set ascii default 'pcs',
  `amount_availability` varchar(32) NOT NULL,
  `amount_limit` int(10) default '0',
  `amount_order_min` int(10) unsigned default '1',
  `amount_order_max` int(10) unsigned default NULL,
  `amount_order_div` int(10) unsigned default '1',
  `price` decimal(12,3) default NULL,
  `price_previous` decimal(12,3) default NULL,
  `price_max` decimal(12,3) default NULL,
  `price_currency` varchar(3) character set ascii default 'EUR',
  `price_EUR` decimal(12,3) default NULL,
  `src_data` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `sellscore` decimal(10,2) default NULL,
  `supplier_org` bigint(20) unsigned default NULL, -- rel 710_org.ID_entity
  `supplier_person` varchar(8) character set utf8 collate utf8_bin NOT NULL default '', -- rel 301.user_ID
  `status_new` char(1) character set ascii NOT NULL default 'N',
  `status_recommended` char(1) character set ascii NOT NULL default 'N',
  `status_sale` char(1) character set ascii NOT NULL default 'N',
  `status_special` char(1) character set ascii NOT NULL default 'N',
  `status_main` char(1) character set ascii NOT NULL default 'Y',
  `status` char(1) character set ascii NOT NULL default 'N',
  KEY `datetime_create` (`datetime_create`),
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_metaindex` (
  `ID` bigint(20) unsigned NOT NULL, -- ref _product.ID
  `meta_section` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_value` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`meta_section`,`meta_variable`),
  KEY `SEL_0` (`meta_section`,`meta_variable`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_visit` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_product` bigint(20) NOT NULL, -- rel to product.ID_entity
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_product`),
  KEY `SEL_0` (`ID_product`,`datetime_event`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8; -- must be myisam because inserting with insert delayed

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_visit_arch` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_product` bigint(20) NOT NULL,
  KEY `datetime_event` (`datetime_event`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_ent` ( -- summary table for product - one row=one product
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel product.ID_entity
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_brand` bigint(20) unsigned NOT NULL, -- rel product_brand.ID_entity
  `ID_family` bigint(20) unsigned NOT NULL, -- rel product_family.ID_entity
  `VAT` float NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `rating` int(10) unsigned NOT NULL, -- helps indexing
  `priority_A` tinyint(3) unsigned default NULL,
  `priority_B` tinyint(3) unsigned default NULL,
  `priority_C` tinyint(3) unsigned default NULL,
  `product_type` char(5) character set ascii NOT NULL default 'GDS',
  `status` char(1) character set ascii NOT NULL default 'Y',
   PRIMARY KEY  (`ID`),
   UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_ent_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_brand` bigint(20) unsigned NOT NULL,
  `ID_family` bigint(20) unsigned NOT NULL,
  `VAT` float NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `rating` int(10) unsigned NOT NULL,
  `priority_A` tinyint(3) unsigned default NULL,
  `priority_B` tinyint(3) unsigned default NULL,
  `priority_C` tinyint(3) unsigned default NULL,
  `product_type` char(5) character set ascii NOT NULL default 'GDS',
  `status` char(1) character set ascii NOT NULL default 'Y',
   PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_rating_vote` (
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_product` mediumint(8) unsigned NOT NULL, -- ref _product_ent.ID
  `datetime_event` datetime NOT NULL,
  `score` int(10) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_lng` ( -- language versions of product modification
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _product.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `name_label` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description_short` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `keywords` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
--  FULLTEXT KEY `FULL_0` (`name`,`name_long`,`name_label`,`description_short`,`description`,`keywords`),
  KEY `lng` (`lng`),
  KEY `SEL_0` (`status`,`name_url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_lng_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `name_label` varchar(64) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description_short` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `keywords` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  KEY `datetime_create` (`datetime_create`),
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_sym` ( -- list of product symlinks
  `ID` bigint(20) unsigned NOT NULL auto_increment, -- rel _product_cat.ID_entity
  `ID_entity` bigint(20) unsigned NOT NULL, -- rel _product.ID_entity
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`ID_entity`),
  KEY `ID_entity` (`ID_entity`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_sym_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned NOT NULL,
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`ID_entity`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_brand` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `code` varchar(16) character set ascii default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  UNIQUE KEY `UNI_1` (`code`),
  KEY `SEL_0` (`status`,`name_url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_brand_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `code` varchar(16) character set ascii default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_brand_lng` ( -- language versions of brands
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _brand.ID
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_brand_lng_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_family` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_family_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `alias_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`),
  KEY `ID_entity` (`ID_entity`),
  KEY `ID_charindex` (`ID_charindex`),
  KEY `name` (`name`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_cat_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `alias_url` varchar(128) character set ascii NOT NULL default '',
  `alias_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `description` longtext character set utf8 collate utf8_unicode_ci NOT NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_cat_metaindex` (
  `ID` bigint(20) unsigned NOT NULL, -- ref _product.ID
  `meta_section` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `meta_value` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`meta_section`,`meta_variable`),
  KEY `SEL_0` (`meta_section`,`meta_variable`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_price_level` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_code` varchar(6) character set ascii NOT NULL default '',
  `country_code` char(3) character set ascii default NULL,
  `currency` varchar(3) character set ascii default 'EUR',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  UNIQUE KEY `UNI_1` (`name_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_price_level_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_code` varchar(6) character set ascii NOT NULL default '',
  `country_code` char(3) character set ascii default NULL,
  `currency` varchar(3) character set ascii default 'EUR',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_price` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel product.ID
  `ID_price` bigint(20) unsigned NOT NULL, -- rel price_level.ID_entity
  `price` decimal(12,3) default NULL, -- price for this relation
  `price_full` decimal(12,3) default NULL,
  `price_previous` decimal(12,3) default NULL,
  `price_previous_full` decimal(12,3) default NULL,
  `datetime_next_index` datetime default NULL,
  `src_data` text character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`ID_price`),
  KEY `next_index` (`datetime_next_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_price_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_price` bigint(20) unsigned NOT NULL, -- rel price_level.ID_entity
  `price` decimal(12,3) default NULL,
  `price_full` decimal(12,3) default NULL,
  `price_previous` decimal(12,3) default NULL,
  `price_previous_full` decimal(12,3) default NULL,
  `datetime_next_index` datetime default NULL,
  `src_data` text character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  KEY `datetime_create` (`datetime_create`),
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_legal` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel product.ID
  `country_code` char(3) character set ascii default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `VAT` float NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`country_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_legal_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `country_code` char(3) character set ascii default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `VAT` float NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_rating` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_product` bigint(20) unsigned default NULL, -- rel product.ID
  `title` varchar(128) character set utf8 collate utf8_unicode_ci default '',
  `score_basic` tinyint(3) unsigned default NULL,
  `description` text character set utf8 collate utf8_unicode_ci default NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `datetime_rating` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `helpful_Y` mediumint(8) unsigned NOT NULL,
  `helpful_N` mediumint(8) unsigned NOT NULL,
  `status` char(1) character set ascii default 'Y',
  `status_publish` char(1) character set ascii default 'N',
   PRIMARY KEY  (`ID`),
   KEY `SEL_0` (`ID_product`,`status`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_rating_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_product` bigint(20) unsigned default NULL, -- rel product.ID
  `title` varchar(128) character set utf8 collate utf8_unicode_ci default '',
  `score_basic` tinyint(3) unsigned default NULL,
  `description` text character set utf8 collate utf8_unicode_ci default NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `datetime_rating` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `helpful_Y` mediumint(8) unsigned NOT NULL,
  `helpful_N` mediumint(8) unsigned NOT NULL,
  `status` char(1) character set ascii default 'Y',
  `status_publish` char(1) character set ascii default 'N',
   PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_rating_helpful_vote` (
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_rating` mediumint(8) unsigned NOT NULL, -- ref _product_rating.ID
  `helpful` char(1) character set ascii default 'Y',
  PRIMARY KEY  (`ID_user`,`ID_rating`),
  KEY `ID_rating` (`ID_rating`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_rating_variable` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel. product_rating.ID_entity
  `score_value` tinyint(3) unsigned default NULL,
  `score_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii default 'Y',
   UNIQUE KEY `UNI_0` (`ID_entity`,`score_variable`),
   PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_rating_variable_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel. product_rating.ID_entity
  `score_value` tinyint(3) unsigned default NULL,
  `score_variable` varchar(32) character set utf8 collate utf8_unicode_ci NOT NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii default 'Y',
   PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_product_view` AS (
	SELECT
		product.ID_entity AS ID_entity_product,
		product.ID AS ID_product,
		product_sym.ID AS ID_category,
		product_lng.ID AS ID_lng,
		
		product_lng.name,
		product_lng.name_url,
		product_lng.name_long,
		product_lng.description_short,
		product_lng.description,
		
		IF
		(
			(
				product.status LIKE 'Y' AND
				product_sym.status LIKE 'Y'
			),
			'Y', 'U'
		) AS status_all
		
	FROM
		`/*db_name*/`.`/*app*/_product` AS product
	LEFT JOIN `/*db_name*/`.`/*app*/_product_ent` AS product_ent ON
	(
		product_ent.ID_entity = product.ID_entity
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_product_lng` AS product_lng ON
	(
		product_lng.ID_entity = product.ID
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_product_sym` AS product_sym ON
	(
		product_sym.ID_entity = product.ID_entity
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_product_cat` AS product_cat ON
	(
		product_cat.ID_entity = product_sym.ID AND
		product_cat.lng = product_lng.lng
	)
	ORDER BY
		product.ID ASC
)

-- --------------------------------------------------
-- db_name=TOM

CREATE TABLE `/*db_name*/`.`/*app*/_currency_rate` (
  `currency1` char(4) character set ascii NOT NULL,
  `currency2` char(4) character set ascii NOT NULL,
  `rate` decimal(12,5) default NULL,
  `datetime_create` datetime default NULL,
  PRIMARY KEY  (`currency1`,`currency2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
