#!/bin/perl
package App::420;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Application 420 - Static

=head1 DESCRIPTION

Application which manages static content

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::420::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::401::functions|app/"401/functions.pm">

=item *

L<App::420::functions|app/"420/functions.pm">

=item *

L<App::420::a160|app/"420/a160.pm">

=item *

L<App::420::a301|app/"420/a301.pm">

=back

=cut

use TOM::Template;
use App::020::_init; # data standard 0
use App::301::_init;
use App::401::mimetypes;
use App::420::functions;
use App::420::a160;
use App::420::a301;


=head1 CONFIGURATION

 $db_name

=cut

our $db_name=$App::420::db_name || $TOM::DB{'main'}{'name'};
our %priority;
our $metadata_default=$App::420::metadata_default || qq{
<metatree>
</metatree>
};

our $section_templates_cat_ID_entity;
my %sth0=TOM::Database::SQL::execute(qq{
	SELECT ID, ID_entity
	FROM `$App::420::db_name`.`a420_static_cat`
	WHERE name='Section templates'
	LIMIT 1
},'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{$section_templates_cat_ID_entity=$db0_line{'ID_entity'} unless $section_templates_cat_ID_entity;}
else
{
	$section_templates_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::420::db_name,
		'tb_name' => "a420_static_cat",
		'columns' => {
			'name' => "'Section templates'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
