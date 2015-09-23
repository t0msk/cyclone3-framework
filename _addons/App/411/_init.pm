#!/bin/perl
package App::411;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Application 411 - Polls

=head1 DESCRIPTION

Application which manages content in polls

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::411::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::411::functions|app/"411/functions.pm">

=item *

L<App::411::a160|app/"411/a160.pm">

=item *

L<App::411::a301|app/"411/a301.pm">

=back

=cut

use App::020::_init; # data standard 0
use App::301::_init;
use App::411::functions;
use App::411::a160;
use App::411::a301;


=head1 CONFIGURATION

 $db_name

=cut

our $db_name=$App::411::db_name || $TOM::DB{'main'}{'name'};


# check system category
our $system_cat_ID_entity;
our %system_cat;
# find any category;
my $sql="
	SELECT ID, ID_entity
	FROM `$App::411::db_name`.`a411_poll_cat`
	WHERE name='System' AND lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1 ";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{$system_cat_ID_entity=$db0_line{'ID_entity'} unless $system_cat_ID_entity;}
else
{
	$system_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::411::db_name,
		'tb_name' => "a411_poll_cat",
		'columns' => {
			'name' => "'System'",
			'lng' => "'$tom::LNG'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}
foreach my $lng(@TOM::LNG_accept)
{
	my $sql=qq{
		SELECT ID, ID_entity
		FROM `$App::411::db_name`.`a411_poll_cat`
		WHERE ID_entity=$system_cat_ID_entity AND lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{$system_cat{$lng}=$db0_line{'ID'};}
	else
	{
		$system_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::411::db_name,
			'tb_name' => "a411_poll_cat",
			'columns' => {
				'ID_entity' => $system_cat_ID_entity,
				'name' => "'System'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}

# check relation to a821
our $form_ID_entity;
our %form;

if ($tom::addons{'a830'})
{
	use App::830::_init;
	
	my $tmplng = 'xx';
	
	# find any category;
	my $sql="
		SELECT
			`ID`,
			`ID_entity`
		FROM
			`$App::830::db_name`.`a830_form_cat`
		WHERE
					`name` = 'poll forms'
--			AND	`lng` IN ('".(join "','",@TOM::LNG_accept)."')
			AND	`lng` = '$tmplng'
		LIMIT 1
	";
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$form_ID_entity=$db0_line{'ID_entity'} unless $form_ID_entity;
	}
	else
	{
		$form_ID_entity=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::830::db_name,
			'tb_name' => "a830_form_cat",
			'columns' => {
				'name' => "'poll forms'",
				#'lng' => "'$tom::LNG'",
				'lng' => "'$tmplng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
	
	#foreach my $lng(@TOM::LNG_accept)
	#{
		main::_log("check related category $tmplng");
		my $sql=qq{
			SELECT
				`ID`,
				`ID_entity`
			FROM
				`$App::830::db_name`.`a830_form_cat`
			WHERE
						`ID_entity` = $form_ID_entity
				AND	`lng` = '$tmplng'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$form{$tmplng}=$db0_line{'ID'};
		}
		#else
		#{
			#main::_log("creating related category");
			#$form{$tmplng}=App::020::SQL::functions::tree::new(
			#	'db_h' => "main",
			#	'db_name' => $App::830::db_name,
			#	'tb_name' => "a830_form_cat",
			#	'columns' => {
			#		'ID_entity' => $form_ID_entity,
			#		'name' => "'poll forms'",
			#		'lng' => "'$tmplng'",
			#		'status' => "'L'"
			#	},
			#	'-journalize' => 1
			#);
		#}
	#}
}


=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
