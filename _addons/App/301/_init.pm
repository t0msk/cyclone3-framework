#!/bin/perl
package App::301;
use open ':utf8', ':std';
use Encode;
use encoding 'utf8';
use utf8;
use strict;



=head1 NAME

Application 301 - User Management

=head1 DESCRIPTION

Application which manages users

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 SYNOPSIS

 use App::301::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::301::functions|app/"301/functions.pm">

=item *

L<App::301::session|app/"301/session.pm">

=item *

L<App::301::authors|app/"301/authors.pm">

=item *

L<App::501::_init|app/"501/_init.pm">

=item *

CVML

=item *

Digest::MD5

=back

=cut


use App::301::functions;
use App::301::session;
use App::301::authors;
use CVML;
use Digest::MD5;



sub CookieClean
{
	my $t=track TOM::Debug(__PACKAGE__."::CookieClean()");
	
	opendir DIR, '../_data/USRM/';
	foreach my $file(readdir DIR)
	{
		next unless $file=~/cookie/;
		my $old=$main::time_current-(stat "../_data/USRM/".$file)[9];
		main::_log("file '$file' old='$old'");
		unlink "../_data/USRM/".$file if $old>3600;
	}
	
	$t->close();
}


CookieClean();


if ($tom::H_cookie)
{
	# admin is group for administrators
	# editor is group with access into rpc services
	foreach my $group('admin','editor')
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
			App::020::SQL::functions::tree::new(
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
	}
}




# check relation to a501 if domain defined
if ($tom::H)
{
	require App::501::_init;
	our $photo_cat_ID_entity;
	our %photo_cat;
	
	# find any category;
	my $sql="
		SELECT
			ID, ID_entity
		FROM
			`$App::501::db_name`.`a501_image_cat`
		WHERE
			name='user photo' AND
			lng IN ('".(join "','",@TOM::LNG_accept)."')
		LIMIT 1
	";
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$photo_cat_ID_entity=$db0_line{'ID_entity'} unless $photo_cat_ID_entity;
	}
	else
	{
		$photo_cat_ID_entity=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'columns' => {
				'name' => "'user photo'",
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
				ID_entity=$photo_cat_ID_entity AND
				lng='$lng'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$photo_cat{$lng}=$db0_line{'ID'};
		}
		else
		{
			#main::_log("creating related category");
			$photo_cat{$lng}=App::020::SQL::functions::tree::new(
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a501_image_cat",
				'columns' => {
					'ID_entity' => $photo_cat_ID_entity,
					'name' => "'user photo'",
					'lng' => "'$lng'",
					'status' => "'L'"
				},
				'-journalize' => 1
			);
		}
	}
}




=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
