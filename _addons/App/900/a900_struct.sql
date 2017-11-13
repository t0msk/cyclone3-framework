-- db_h=main
-- addon=a900
-- version=5.0

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `ID_zonetarget` bigint(20) unsigned NOT NULL, -- rel banner_zonetarget.ID_entity
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `target_url` varchar(128) character set ascii default NULL,
  `target_addon` varchar(64) character set ascii default NULL,
  `target_nofollow` char(1) character set ascii NOT NULL default 'N',
  `rules_validation` text character set utf8 collate utf8_unicode_ci NOT NULL, -- valid=1 to valid to display
  `rules_apply` text character set utf8 collate utf8_unicode_ci NOT NULL, -- script variables for banner - target.url, etc...
  `rules_weight` int(10) unsigned default '1',
  `stats_views` int(10) unsigned NOT NULL, -- impressions
  `stats_clicks` int(10) unsigned NOT NULL, -- applied impressions
  `rules_views_max` int(10) unsigned default NULL,
  `rules_views_session_max` int(10) unsigned default NULL,
  `rules_pageviews_session_min` int(10) unsigned default NULL,
  `rules_views_browser_session_max` int(10) unsigned default NULL,
  `rules_clicks_max` int(10) unsigned default NULL,
  `rules_clicks_browser_max` int(10) unsigned default NULL,
  `skip` int(10) unsigned default NULL, -- number of seconds to be to allow to skip ad playback, NULL = default, 0 = never
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `time_publish_start` time default NULL,
  `time_publish_stop` time default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `utm_source` varchar(128) character set ascii default NULL,
  `utm_medium` varchar(128) character set ascii default NULL,
  `utm_term` varchar(128) character set ascii default NULL,
  `utm_content` varchar(128) character set ascii default NULL,
  `utm_campaign` varchar(128) character set ascii default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  KEY `SEL_0` (`status`,`datetime_publish_start`,`datetime_publish_stop`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `ID_zonetarget` bigint(20) unsigned NOT NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `target_url` varchar(128) character set ascii default NULL,
  `target_addon` varchar(64) character set ascii default NULL,
  `target_nofollow` char(1) character set ascii NOT NULL default 'N',
  `rules_validation` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `rules_apply` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `rules_weight` int(10) unsigned default '1',
  `stats_views` int(10) unsigned NOT NULL,
  `stats_clicks` int(10) unsigned NOT NULL,
  `rules_views_max` int(10) unsigned default NULL,
  `rules_views_session_max` int(10) unsigned default NULL,
  `rules_pageviews_session_min` int(10) unsigned default NULL,
  `rules_views_browser_session_max` int(10) unsigned default NULL,
  `rules_clicks_max` int(10) unsigned default NULL,
  `rules_clicks_browser_max` int(10) unsigned default NULL,
  `skip` int(10) unsigned default NULL, -- number of seconds to be to allow to skip ad playback, NULL = default, 0 = never
  `datetime_publish_start` datetime NOT NULL,
  `datetime_publish_stop` datetime default NULL,
  `time_publish_start` time default NULL,
  `time_publish_stop` time default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `utm_source` varchar(128) character set ascii default NULL,
  `utm_medium` varchar(128) character set ascii default NULL,
  `utm_term` varchar(128) character set ascii default NULL,
  `utm_content` varchar(128) character set ascii default NULL,
  `utm_campaign` varchar(128) character set ascii default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_lng` ( -- language versions of banner
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _banner.ID_entity
  `title` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `def_type` varchar(32) character set ascii collate ascii_bin default NULL, -- popup, html, dynamic, ...
  `def_img_src` varchar(250) character set ascii collate ascii_bin default NULL,
  `def_script` text character set utf8 collate utf8_unicode_ci default NULL,
  `def_target` varchar(16) character set ascii collate ascii_bin default '_blank',
  `def_text_1` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `def_text_2` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `def_text_3` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `def_text_4` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `def_body` text character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  KEY `lng` (`lng`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_lng_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL, -- rel _banner.ID_entity
  `title` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `def_type` varchar(32) character set ascii collate ascii_bin default NULL, -- popup, html, dynamic, ...
  `def_img_src` varchar(250) character set ascii collate ascii_bin default NULL,
  `def_script` text character set utf8 collate utf8_unicode_ci default NULL,
  `def_target` varchar(16) character set ascii collate ascii_bin default '_blank',
  `def_text_1` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `def_text_2` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `def_text_3` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `def_text_4` varchar(128) character set utf8 collate utf8_unicode_ci default NULL,
  `def_body` text character set utf8 collate utf8_unicode_ci default NULL,
  `datetime_create` datetime NOT NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `lng` char(5) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_view` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_session` varchar(32) character set utf8 collate utf8_bin default NULL, -- rel a301_user_online.ID_session
  `ID_browser` varchar(8) character set utf8 collate utf8_bin default NULL,
  `ID_browser_session` varchar(32) character set utf8 collate utf8_bin default NULL,
  `ID_banner` bigint(20) NOT NULL, -- rel to banner.ID_entity
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_banner`),
  KEY `SEL_0` (`ID_banner`,`datetime_event`),
  KEY `SEL_1` (`ID_user`,`ID_banner`),
  KEY `SEL_2` (`ID_session`,`ID_banner`),
  KEY `SEL_3` (`ID_browser`,`ID_banner`),
  KEY `SEL_4` (`ID_browser_session`,`ID_banner`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8; -- must be myisam because inserting with insert delayed

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_view_anon` (
  `date_event` date NOT NULL,
  `ID_banner` bigint(20) NOT NULL, -- rel to banner.ID_entity
  `stats_views` int(10) unsigned NOT NULL, -- impressions
  PRIMARY KEY  (`date_event`,`ID_banner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_view_arch` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_session` varchar(32) character set utf8 collate utf8_bin default NULL,
  `ID_browser` varchar(8) character set utf8 collate utf8_bin default NULL,
  `ID_browser_session` varchar(32) character set utf8 collate utf8_bin default NULL,
  `ID_banner` bigint(20) NOT NULL,
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_banner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8; -- too big table

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_click` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_session` varchar(32) character set utf8 collate utf8_bin default NULL, -- rel a301_user_online.ID_session
  `ID_browser` varchar(8) character set utf8 collate utf8_bin default NULL,
  `ID_browser_session` varchar(32) character set utf8 collate utf8_bin default NULL,
  `ID_banner` bigint(20) NOT NULL, -- rel to banner.ID_entity
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_banner`),
  KEY `SEL_0` (`ID_banner`,`datetime_event`),
  KEY `SEL_1` (`ID_user`,`ID_banner`),
  KEY `SEL_2` (`ID_session`,`ID_banner`),
  KEY `SEL_3` (`ID_browser`,`ID_banner`),
  KEY `SEL_4` (`ID_browser_session`,`ID_banner`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8; -- must be myisam because inserting with insert delayed

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_zonetarget` ( -- skyscaper, popup, carousel,...
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_zonetarget_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
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

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_cat_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin default NULL,
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `datetime_create` datetime NOT NULL,
  `lng` char(5) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_rel_cat` (
  `ID_category` bigint(20) unsigned NOT NULL auto_increment, -- rel _banner_cat.ID_entity
  `ID_banner` bigint(20) unsigned NOT NULL, -- rel _banner.ID_entity,
  PRIMARY KEY  (`ID_category`,`ID_banner`),
  KEY `SEL_0` (`ID_banner`,`ID_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_domain` ( -- domain.tld, domain2.tld, subdomain.domain.tld
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_domain_j` (
  `ID` bigint(20) unsigned NOT NULL,
  `ID_entity` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `posix_modified` varchar(8) character set ascii collate ascii_bin default NULL,
  `metadata` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*addon*/_banner_rel_domain` (
  `ID_domain` bigint(20) unsigned NOT NULL auto_increment, -- rel _banner_domain.ID_entity
  `ID_banner` bigint(20) unsigned NOT NULL, -- rel _banner.ID_entity,
  PRIMARY KEY  (`ID_domain`,`ID_banner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------
