-- db_h=main
-- db_name=TOM
-- app=a131
-- version=5.0

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_cellular_message` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime default NULL,
  `datetime_send` datetime default NULL,
  `datetime_sent` datetime default NULL,
  `cellular` varchar(20) character set ascii NOT NULL,
  `message` varchar(480) character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  KEY `cellular` (`cellular`),
  KEY `datetime_create` (`datetime_create`),
  KEY `datetime_send` (`datetime_send`),
  KEY `datetime_sent` (`datetime_sent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------