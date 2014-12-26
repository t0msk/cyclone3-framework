#!/bin/perl
package App::930;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Application 930 - Requests For Proposal

=head1 DESCRIPTION

A request for proposal (RFP) is a solicitation made, often through a bidding process, by an agency or company interested in procurement of a commodity, service or valuable asset, to potential suppliers to submit business proposals

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::930::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::930::a160|app/"930/a160.pm">

=item *

L<App::930::a301|app/"930/a301.pm">

=item *

L<App::930::functions|app/"930/functions.pm">

=back

=cut

use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::930::a020;
use App::930::a160;
use App::930::a301;
use App::930::functions;



=head1 CONFIGURATION

 $db_name
 $currency='EUR'

=cut

our $currency=$App::930::currency || 'EUR';
our $db_name=$App::930::db_name || $TOM::DB{'main'}{'name'};
our $metaindex=$App::930::metaindex || 'Y';

our $metadata_default=$App::930::metadata_default || qq{
<metatree>
	<section name="Others"></section>
</metatree>
};


# rfp cat avatars

our $cat_avatar_cat_ID_entity;
our %cat_avatar_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='rfp category avatars' AND
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
			'name' => "'rfp category avatars'",
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
				'name' => "'rfp category avatars'",
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
