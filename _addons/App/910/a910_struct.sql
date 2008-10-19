-- db_h=main
-- app=a910
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product` ( -- list of modifications
  `ID` bigint(20) unsigned NOT NULL auto_increment, -- modification of product
  `ID_entity` bigint(20) unsigned default NULL,
  `product_number` varchar(32) character set ascii default NULL, -- unique for every modification
  `datetime_create` datetime NOT NULL,
  `amount` bigint(20) unsigned NOT NULL,
  `amount_availability` varchar(32) NOT NULL,
  `price` float default NULL, -- different modifications, different prices
  `price_currency` varchar(3) character set ascii default 'EUR',
  `price_EUR` float default NULL, -- price in EUR
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`product_number`),
  KEY `ID_entity` (`ID_entity`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `product_number` varchar(32) character set ascii default NULL,
  `datetime_create` datetime NOT NULL,
  `amount` bigint(20) unsigned NOT NULL,
  `amount_availability` varchar(32) NOT NULL,
  `price` float default NULL,
  `price_currency` varchar(3) character set ascii default 'EUR',
  `price_EUR` float default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_ent` ( -- summary table for product - one row=one product
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel product.ID_entity
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_brand` bigint(20) unsigned NOT NULL, -- rel product_brand.ID_entity
  `VAT` float NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
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
  `VAT` float NOT NULL,
  `rating_score` int(10) unsigned NOT NULL,
  `rating_votes` int(10) unsigned NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
   PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_lng` ( -- language versions of product modification
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _product.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description_short` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_lng_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `name_long` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL,
  `description_short` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_sym` ( -- list of product symlinks
  `ID` bigint(20) unsigned NOT NULL auto_increment, -- rel _product_cat.ID_entity
  `ID_entity` bigint(20) unsigned default NULL, -- rel _product.ID_entity
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`ID_entity`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_sym_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`ID_entity`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_brand` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_product_brand_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
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
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
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
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N'
) ENGINE=ARCHIVE DEFAULT CHARSET=utf8;

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