#!/bin/perl
package App::401;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 401 - Articles

=head1 DESCRIPTION

Application which manages content in articles

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::401::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::821::_init|app/"821/_init.pm">

=item *

L<App::401::mimetypes|app/"401/mimetypes.pm">

=item *

L<App::401::functions|app/"401/functions.pm">

=item *

L<App::401::keywords::html_extract|app/"401/keywords/html_extract.pm">

=item *

L<App::401::a160|app/"401/a160.pm">

=item *

L<App::401::a301|app/"401/a301.pm">

=back

=cut

use TOM::Template;
use App::020::_init; # data standard 0
use App::301::_init;
use App::821::_init;
use App::401::mimetypes;
use App::401::functions;
use App::401::keywords;
use App::401::a160;
use App::401::a301;


=head1 CONFIGURATION

 $db_name
 $priority_A_level=1
 $priority_B_level=undef
 $priority_C_level=undef

=cut

# level number 1 is TOP level
# any higher number is higher level
# level number NULL is none level

our $db_name=$App::401::db_name || $TOM::DB{'main'}{'name'};
our %priority;
$priority{'A'}=$App::401::priority{'A'} || 1;
$priority{'B'}=$App::401::priority{'B'} || undef;
$priority{'C'}=$App::401::priority{'C'} || undef;
$priority{'D'}=$App::401::priority{'D'} || undef;
$priority{'E'}=$App::401::priority{'E'} || undef;
$priority{'F'}=$App::401::priority{'F'} || undef;
our $metadata_default=$App::401::metadata_default || qq{
<metatree>
</metatree>
};

our %a301_user_group;

if ($tom::H_cookie)
{
	# author is group for authors
	# publisher is group for publishers
	foreach my $group('author','publisher')
	{
		my $sql=qq{
			SELECT
				*
			FROM
				TOM.a301_user_group
			WHERE
				hostname='$tom::H_cookie' AND
				name='$group'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if (!$db0_line{'ID'})
		{
			$db0_line{'ID'}=App::020::SQL::functions::tree::new(
				'db_h' => "main",
				'db_name' => "TOM",
				'tb_name' => "a301_user_group",
				'columns' =>
				{
					'name' => "'".$group."'",
					'hostname' => "'".$tom::H_cookie."'",
					'status' => "'L'"
				},
				'-journalize' => 1
			);
		}
		elsif ($db0_line{'status'} ne "L")
		{
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => "main",
				'db_name' => "TOM",
				'tb_name' => "a301_user_group",
				'columns' =>
				{
					'status' => "'L'"
				},
				'-journalize' => 1
			);
		}
		$a301_user_group{$group}=$db0_line{'ID'};
	}
}



# check relation to a821
our $forum_ID_entity;
our %forum;

if ($tom::addons{'a821'})
{
	# find any category;
	my $sql="
		SELECT
			ID, ID_entity
		FROM
			`$App::821::db_name`.`a821_discussion_forum`
		WHERE
			name='article discussions' AND
			lng IN ('".(join "','",@TOM::LNG_accept)."')
		LIMIT 1
	";
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$forum_ID_entity=$db0_line{'ID_entity'} unless $forum_ID_entity;
	}
	else
	{
		$forum_ID_entity=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::821::db_name,
			'tb_name' => "a821_discussion_forum",
			'columns' => {
				'name' => "'article discussions'",
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
				`$App::821::db_name`.`a821_discussion_forum`
			WHERE
				ID_entity=$forum_ID_entity AND
				lng='$lng'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$forum{$lng}=$db0_line{'ID'};
		}
		else
		{
			#main::_log("creating related category");
			$forum{$lng}=App::020::SQL::functions::tree::new(
				'db_h' => "main",
				'db_name' => $App::821::db_name,
				'tb_name' => "a821_discussion_forum",
				'columns' => {
					'ID_entity' => $forum_ID_entity,
					'name' => "'article discussions'",
					'lng' => "'$lng'",
					'status' => "'L'"
				},
				'-journalize' => 1
			);
		}
	}
}

# check relation to a501
use App::501::_init;
our $thumbnail_cat_ID_entity;
our %thumbnail_cat;


# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='article thumbnails' AND
		lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1
";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{
	$thumbnail_cat_ID_entity=$db0_line{'ID_entity'} unless $thumbnail_cat_ID_entity;
}
else
{
	$thumbnail_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::501::db_name,
		'tb_name' => "a501_image_cat",
		'parent_ID' => $App::501::system_cat{$tom::LNG},
		'columns' => {
			'name' => "'article thumbnails'",
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
			ID_entity=$thumbnail_cat_ID_entity AND
			lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$thumbnail_cat{$lng}=$db0_line{'ID'};
	}
	else
	{
		#main::_log("creating related category");
		$thumbnail_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'parent_ID' => $App::501::system_cat{$lng},
			'columns' => {
				'ID_entity' => $thumbnail_cat_ID_entity,
				'name' => "'article thumbnails'",
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
