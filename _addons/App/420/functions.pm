#!/bin/perl
package App::420::functions;

=head1 NAME

App::420::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::420::_init|app/"420/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::420::_init;
use TOM::Security::form;
use Time::HiRes qw(usleep);
use Ext::TextHyphen::_init;

our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head2 static_add()

Adds new static content to category, or updates old content

 static_add
 (
   'static.ID' => '',
   'static.ID_entity' => '',
   'article.ID_category' => '',
   'article.name' => '',
   'article.body' => ''
 );

=cut

sub static_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::static_add()",'timer'=>1);
	
	my $content_updated=0; # boolean if important content attributes was updated
	my $content_reindex=0; # boolean if is required to update searchindex
	
	# STATIC
	
	my %static;
	if ($env{'static.ID'})
	{
		%static=App::020::SQL::functions::get_ID(
			'ID' => $env{'static.ID'},
			'db_h' => "main",
			'db_name' => $App::420::db_name,
			'tb_name' => "a420_static",
			'columns' => {'*'=>1}
		);
		$env{'static.ID_entity'}=$static{'ID_entity'} if $static{'ID_entity'};
	}
	
	# static.ID is unknown
	if (!$env{'static.ID'} && $env{'static.ID_entity'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::420::db_name`.`a420_static`
			WHERE
				ID_entity=$env{'static.ID_entity'} AND
				status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID'})
		{
			$env{'static.ID'}=$db0_line{'ID'};
			main::_log("setup static.ID='$db0_line{'ID'}'");
		}
	}
	
	main::_log("status static.ID='$env{'static.ID'}' static.ID_entity='$env{'static.ID_entity'}'");
	
	if (!$env{'static.ID'})
	{
		# generating new static!
		main::_log("adding new regular static content");
		
		my %columns;
		$columns{'ID_entity'}=$env{'static.ID_entity'} if $env{'static.ID_entity'};
		$columns{'datetime_start'}="NOW()" unless $columns{'datetime_start'};
		
		$env{'static.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::420::db_name,
			'tb_name' => "a420_static",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		
		main::_log("generated static ID='$env{'static.ID'}'");
		$content_updated=1;
	}
	
	if (!$env{'static.ID_entity'})
	{
		if ($static{'ID_entity'})
		{
			$env{'static.ID_entity'}=$static{'ID_entity'};
		}
		elsif ($env{'static.ID'})
		{
			%static=App::020::SQL::functions::get_ID(
				'ID' => $env{'static.ID'},
				'db_h' => "main",
				'db_name' => $App::420::db_name,
				'tb_name' => "a420_static",
				'columns' => {'*'=>1}
			);
			$env{'static.ID_entity'}=$static{'ID_entity'};
		}
		else
		{
			die "ufff\n";
		}
	}
	
	if (!$env{'static.ID_entity'})
	{
		die "ufff, missing static.ID_entity\n";
	}
	
	if (!$static{'posix_owner'} && !$env{'static.posix_owner'})
	{
		$env{'static.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update if necessary
	if ($env{'static.ID'})
	{
		my %columns;
		# name
		$env{'static.name'}=~s|$soft_hyphen||g;
		if ($env{'static.name'} && ($env{'static.name'} ne $static{'name'}))
		{
			$columns{'name'}="'".TOM::Security::form::sql_escape($env{'static.name'})."'";
			$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'static.name'}))."'";
		}
		# ID_category
		$columns{'ID_category'}=$env{'static.ID_category'}
			if ($env{'static.ID_category'} && ($env{'static.ID_category'} ne $static{'ID_category'}));
		# datetime_start
		$columns{'datetime_start'}="'".$env{'static.datetime_start'}."'"
			if ($env{'static.datetime_start'} && ($env{'static.datetime_start'} ne $static{'datetime_start'}));
		$columns{'datetime_start'}=$env{'static.datetime_start'}
			if (($env{'static.datetime_start'} && ($env{'static.datetime_start'} ne $static{'datetime_start'})) && (not $env{'static.datetime_start'}=~/^\d/));
		
		# datetime_stop
		if (exists $env{'static.datetime_stop'} && ($env{'static.datetime_stop'} ne $static{'datetime_stop'}))
		{
			if (!$env{'static.datetime_stop'})
			{
				$columns{'datetime_stop'}="NULL";
			}
			else
			{
				$columns{'datetime_stop'}="'".$env{'static.datetime_stop'}."'";
			}
		}
		# status
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'static.status'})."'"
			if ($env{'static.status'} && ($env{'static.status'} ne $static{'status'}));
		
		# alias_url
		$columns{'alias_url'}="'".TOM::Security::form::sql_escape($env{'static.alias_url'})."'"
			if ($env{'static.alias_url'} && ($env{'static.alias_url'} ne $static{'alias_url'}));
		
		# posix_owner
		$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'static.posix_owner'})."'"
			if ($env{'static.posix_owner'} && ($env{'static.posix_owner'} ne $static{'posix_owner'}));
		
		# body
		$env{'static.body'}=~s|$soft_hyphen||g;
		if ($env{'static.body'} && ($env{'static.body'} ne $static{'body'}))
		{
			$columns{'body'}="'".TOM::Security::form::sql_escape($env{'static.body'})."'";
		}
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'static.ID'},
				'db_h' => "main",
				'db_name' => $App::420::db_name,
				'tb_name' => "a420_static",
				'columns' => {
					%columns,
					'posix_modified' => "'".TOM::Security::form::sql_escape($env{'static.posix_modified'} || $main::USRM{'ID_user'})."'"
				},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1 if $columns{'name'};
			$content_reindex=1 if $columns{'status'};
		}
	}
	
	
	
	$t->close();
	return %env;
}



=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
