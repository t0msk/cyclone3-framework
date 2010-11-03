#!/bin/perl
package App::720;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 720 - Contracts

=head1 DESCRIPTION

Application which manages contracts between organizations and users

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='$Rev$';


=head1 SYNOPSIS

 use App::720::_init;

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

L<App::720::a160|app/"720/a160.pm">

=item *

L<App::720::a301|app/"720/a301.pm">

=item *

L<App::720::functions|app/"720/functions.pm">

=back

=cut

use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::401::mimetypes;
use App::720::a160;
use App::720::a301;
#use App::710::functions;


our $db_name=$App::720::db_name || $TOM::DB{'main'}{'name'};
main::_log("db_name=$db_name");

our $metadata_default=$App::720::metadata_default || '';

# check relation to a542
our $file_ID_entity;
our %file;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::542::db_name`.`a542_file_dir`
	WHERE
		name='contracts' AND
		lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1
";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{
	$file_ID_entity=$db0_line{'ID_entity'} unless $file_ID_entity;
}
else
{
	$file_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::542::db_name,
		'tb_name' => "a542_file_dir",
		'columns' => {
			'name' => "'contracts'",
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
			`$App::542::db_name`.`a542_file_dir`
		WHERE
			ID_entity=$file_ID_entity AND
			lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$file{$lng}=$db0_line{'ID'};
	}
	else
	{
		#main::_log("creating related category");
		$file{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::720::db_name,
			'tb_name' => "a542_file_dir",
			'columns' => {
				'ID_entity' => $file_ID_entity,
				'name' => "'contracts'",
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
