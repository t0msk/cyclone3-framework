#!/bin/perl
package App::910;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Application 910 - Products catalog

=head1 DESCRIPTION

Application which manages products catalag

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::910::_init;

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

L<App::910::a160|app/"910/a160.pm">

=item *

L<App::910::a301|app/"910/a301.pm">

=item *

L<App::910::functions|app/"910/functions.pm">

=back

=cut

use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::821::_init;
use App::401::mimetypes;
use App::910::a160;
use App::910::a301;
use App::910::functions;



=head1 CONFIGURATION

 $db_name
 $currency='EUR'

=cut

our $currency=$App::910::currency || 'EUR';
our $db_name=$App::910::db_name || $TOM::DB{'main'}{'name'};
our $index_name=$App::910::index_name || $App::910::db_name || $TOM::DB{'main'}{'name'};
our $metaindex=$App::910::metaindex || 'Y';
our $solr_status_index=$App::910::solr_status_index || 'Y';
our $solr_price_history=$App::910::solr_price_history || undef;

our $metadata_default=$App::910::metadata_default || qq{
<metatree>
	<section name="Others"></section>
</metatree>
};

our $VAT_default=$App::910::VAT_default || '0.20';



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
			name='product discussions' AND
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
				'name' => "'product discussions'",
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
					'name' => "'product discussions'",
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
		name='product thumbnails' AND
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
			'name' => "'product thumbnails'",
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
				'name' => "'product thumbnails'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}


# product cat avatars

our $cat_avatar_cat_ID_entity;
our %cat_avatar_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='product category avatars' AND
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
			'name' => "'product category avatars'",
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
		#main::_log("creating related category");
		$cat_avatar_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'parent_ID' => $App::501::system_cat{$lng},
			'columns' => {
				'ID_entity' => $cat_avatar_cat_ID_entity,
				'name' => "'product category avatars'",
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
