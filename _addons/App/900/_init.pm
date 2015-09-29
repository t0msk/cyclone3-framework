#!/bin/perl
package App::900;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::900::a020;
use App::900::a160;
use App::900::a301;
use App::900::functions;

our $db_name=$App::900::db_name || $TOM::DB{'main'}{'name'};

our $banner_cat_default;
my %sth0=TOM::Database::SQL::execute(qq{
	SELECT ID, ID_entity
	FROM `$App::900::db_name`.`a900_banner_cat`
	WHERE name='Default' AND status = 'L'
	LIMIT 1},'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash()){$banner_cat_default=$db0_line{'ID_entity'}}
else
{
	$banner_cat_default=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::900::db_name,
		'tb_name' => "a900_banner_cat",
		'columns' => {
			'name' => "'Default'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}

1;
