#!/bin/perl
package App::301;
use open ':utf8', ':std';
use Encode;
use if $] < 5.018, 'encoding','utf8';
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

L<App::301::perm|app/"301/perm.pm">

=item *

L<App::301::a301|app/"301/a301.pm">

=item *

L<App::501::_init|app/"501/_init.pm">

=item *

CVML

=item *

Digest::MD5

=item *

Digest::SHA1

=back

=cut


use App::301::functions;
use App::301::session;
use App::301::authors;
use App::301::perm;
use App::301::a301;
use App::301::a160;
use CVML;
use Digest::MD5;
use Digest::SHA1;

our $db_name=$App::301::db_name || 'TOM';
our $VERSION=0;

sub CookieClean
{
	my $t=track TOM::Debug(__PACKAGE__."::CookieClean()");
	
	opendir DIR, $tom::P.'/_data/USRM/';
	my $files=0;
	my $deleted=0;
	foreach my $file(readdir DIR)
	{
		next unless $file=~/cookie/;
		$files++;
		my $old=$main::time_current-(stat $tom::P."/_data/USRM/".$file)[9];
		if ($old>3600)
		{
			unlink $tom::P."/_data/USRM/".$file;
			$deleted++;
		};
	}
	closedir DIR;
	
	main::_log("processed $files files, $deleted removed");
	
	$t->close();
}


CookieClean() if $tom::H;


if ($tom::H_cookie)
{
	# admin is group for administrators
	# editor is group with access into rpc services
	foreach my $group('admin','editor','newsletter')
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user_group
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
require App::501::_init if $tom::addons{'a501'};
if ($tom::H && $tom::addons{'a501'} && $App::501::db_name)
{
	our $photo_cat_ID_entity;
	our %photo_cat;
	
	# find any category;
	my $sql="
		SELECT
			ID, ID_entity
		FROM
			`$App::501::db_name`.`a501_image_cat`
		WHERE
			name='user avatars' AND
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
			'parent_ID' => $App::501::system_cat{$tom::LNG},
			'columns' => {
				'name' => "'user avatars'",
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
				'parent_ID' => $App::501::system_cat{$lng},
				'columns' => {
					'ID_entity' => $photo_cat_ID_entity,
					'name' => "'user avatars'",
					'lng' => "'$lng'",
					'status' => "'L'"
				},
				'-journalize' => 1
			);
		}
	}
	
	
	
	# Autograph
	our $autograph_cat_ID_entity;
	our %autograph_cat;
	# find any category;
	my $sql="
		SELECT
			ID, ID_entity
		FROM
			`$App::501::db_name`.`a501_image_cat`
		WHERE
			name='user autograph' AND
			lng IN ('".(join "','",@TOM::LNG_accept)."')
		LIMIT 1
	";
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$autograph_cat_ID_entity=$db0_line{'ID_entity'} unless $autograph_cat_ID_entity;
	}
	else
	{
		$autograph_cat_ID_entity=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'parent_ID' => $App::501::system_cat{$tom::LNG},
			'columns' => {
				'name' => "'user autograph'",
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
				ID_entity=$autograph_cat_ID_entity AND
				lng='$lng'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$autograph_cat{$lng}=$db0_line{'ID'};
		}
		else
		{
			$autograph_cat{$lng}=App::020::SQL::functions::tree::new(
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a501_image_cat",
				'parent_ID'   => $App::501::system_cat{$lng},
				'columns' => {
					'ID_entity' => $autograph_cat_ID_entity,
					'name' => "'user autograph'",
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
