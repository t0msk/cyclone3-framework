#!/bin/perl
package App::710;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 710 - Organizations

=head1 DESCRIPTION

Application which manages organizations

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='$Rev$';


=head1 SYNOPSIS

 use App::710::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::401::mimetypes|app/"401/mimetypes.pm">

=item *

L<App::710::a160|app/"710/a160.pm">

=item *

L<App::710::a301|app/"710/a301.pm">

=item *

L<App::710::functions|app/"710/functions.pm">

=back

=cut

use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::401::mimetypes;
use App::710::a160;
use App::710::a301;
#use App::710::functions;


our $db_name=$App::710::db_name || $TOM::DB{'main'}{'name'};


# check relation to a501
use App::501::_init;
our $avatar_cat_ID_entity;
our %avatar_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='organization avatars' AND
		lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1
";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{
	$avatar_cat_ID_entity=$db0_line{'ID_entity'} unless $avatar_cat_ID_entity;
}
else
{
	$avatar_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::501::db_name,
		'tb_name' => "a501_image_cat",
		'columns' => {
			'name' => "'organization avatars'",
			'lng' => "'$tom::LNG'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}

foreach my $lng(@TOM::LNG_accept)
{
	#main::_log("check related category $lng");
	my $sql=qq{
		SELECT
			ID, ID_entity
		FROM
			`$App::501::db_name`.`a501_image_cat`
		WHERE
			ID_entity=$avatar_cat_ID_entity AND
			lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$avatar_cat{$lng}=$db0_line{'ID'};
	}
	else
	{
		#main::_log("creating related category");
		$avatar_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'columns' => {
				'ID_entity' => $avatar_cat_ID_entity,
				'name' => "'organization avatars'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}



=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
