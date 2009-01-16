-- db_h=main
-- app=a920
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_order` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` int(8) unsigned zerofill default NULL,
  `datetime_create` datetime NOT NULL, -- last modified
  `datetime_order` datetime NOT NULL, -- order time
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who created this order
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL, -- who last modified this order
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL, -- rel a301_user.ID_user
  `ID_org` bigint(20) unsigned default NULL, -- a710_org.ID_entity
  `contact_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `contact_email` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `contact_phone` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `billing_service` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `billing_status` char(1) character set ascii NOT NULL default 'N',
  `delivery_service` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `delivery_address` text character set utf8 collate utf8_unicode_ci,
  `notes` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N', -- N=new order Y=accepted T=canceled
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `ID_user` (`ID_user`),
  KEY `ID_org` (`ID_org`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_order_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` int(8) unsigned zerofill default NULL,
  `datetime_create` datetime NOT NULL,
  `datetime_order` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_org` bigint(20) unsigned default NULL,
  `contact_name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `contact_email` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `contact_phone` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `billing_service` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `billing_status` char(1) character set ascii NOT NULL default 'N',
  `delivery_service` varchar(32) character set utf8 collate utf8_unicode_ci default NULL,
  `delivery_address` text character set utf8 collate utf8_unicode_ci,
  `notes` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_order_product` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _order.ID_entity
  `datetime_create` datetime NOT NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_product` bigint(20) unsigned default NULL, -- rel a710_product.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `type` char(1) character set ascii NOT NULL default 'P',
  `VAT` float NOT NULL, -- VAT percentage
  `price_unit` decimal(12,2) default NULL, -- price per unit
  `price` decimal(12,2) default NULL, -- full price (without VAT)
  `price_incl_VAT` decimal(12,2) default NULL, -- full price with VAT
  `price_currency` varchar(3) character set ascii default 'EUR', -- currency
  `amount` int(10) unsigned NOT NULL,
  `amount_unit` varchar(8) character set ascii default 'pcs',
  `amount_accepted` int(10) unsigned NOT NULL, -- accepted by seller
  `amount_supplied` int(10) unsigned NOT NULL, -- supplied by seller
  `status` char(1) character set ascii NOT NULL default 'N',
   PRIMARY KEY  (`ID`),
   KEY `ID_entity` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

