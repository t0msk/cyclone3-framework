#!/bin/perl
package App::950;
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
use App::950::a020;
use App::950::a160;
use App::950::a301;
use App::950::functions;


our $currency=$App::950::currency || 'EUR';
our $db_name=$App::950::db_name || $TOM::DB{'main'}{'name'};
our $metaindex=$App::950::metaindex || 'Y';

our $metadata_default=$App::950::metadata_default || qq{
<metatree>
	<section name="Others"></section>
</metatree>
};


# offer cat avatars

our $cat_avatar_cat_ID_entity;
our %cat_avatar_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='offer category avatars' AND
		lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1
";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{
	$cat_avatar_cat_ID_entity=$db0_line{'ID_entity'} unless $cat_avatar_cat_ID_entity;
}
else
{
	$cat_avatar_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::501::db_name,
		'tb_name' => "a501_image_cat",
		'parent_ID' => $App::501::system_cat{$tom::LNG},
		'columns' => {
			'name' => "'offer category avatars'",
			'lng' => "'$tom::LNG'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}

foreach my $lng(@TOM::LNG_accept)
{
	my $sql=qq{
		SELECT
			ID, ID_entity
		FROM
			`$App::501::db_name`.`a501_image_cat`
		WHERE
			ID_entity=$cat_avatar_cat_ID_entity AND
			lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$cat_avatar_cat{$lng}=$db0_line{'ID'};
	}
	else
	{
		$cat_avatar_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'parent_ID' => $App::501::system_cat{$lng},
			'columns' => {
				'ID_entity' => $cat_avatar_cat_ID_entity,
				'name' => "'offer category avatars'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}


1;
