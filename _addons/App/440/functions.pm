#!/bin/perl
package App::440::functions;

=head1 NAME

App::440::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::440::_init|app/"440/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::440::_init;
use TOM::Security::form;
use Time::HiRes qw(usleep);
use Ext::TextHyphen::_init;

our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head2 promo_item_add()

Adds new promo_item content to category, or updates old content

 promo_item_add
 (
   'promo_item.ID' => '',
   'promo_item.ID_entity' => ''
 );

=cut

sub promo_item_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::promo_item_add()",'timer'=>1);
	
	my $content_updated=0; # boolean if important content attributes was updated
	my $content_reindex=0; # boolean if is required to update searchindex
	
	# STATIC
	
	my %promo_item;
	if ($env{'promo_item.ID'})
	{
		%promo_item=App::020::SQL::functions::get_ID(
			'ID' => $env{'promo_item.ID'},
			'db_h' => "main",
			'db_name' => $App::440::db_name,
			'tb_name' => "a440_promo_item",
			'columns' => {'*'=>1}
		);
		$env{'promo_item.ID_entity'}=$promo_item{'ID_entity'} if $promo_item{'ID_entity'};
	}
	
	# promo_item.ID is unknown
	if (!$env{'promo_item.ID'} && $env{'promo_item.ID_entity'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::440::db_name`.`a440_promo_item`
			WHERE
				ID_entity=$env{'promo_item.ID_entity'} AND
				status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID'})
		{
			$env{'promo_item.ID'}=$db0_line{'ID'};
			main::_log("setup promo_item.ID='$db0_line{'ID'}'");
		}
	}
	
	main::_log("status promo_item.ID='$env{'promo_item.ID'}' promo_item.ID_entity='$env{'promo_item.ID_entity'}'");
	
	if (!$env{'promo_item.ID'})
	{
		# generating new promo_item!
		main::_log("adding new regular promo_item content");
		
		my %columns;
		$columns{'ID_entity'}=$env{'promo_item.ID_entity'} if $env{'promo_item.ID_entity'};
		$columns{'datetime_start'}="NOW()" unless $columns{'datetime_start'};
		
		$env{'promo_item.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::440::db_name,
			'tb_name' => "a440_promo_item",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		
		main::_log("generated promo_item ID='$env{'promo_item.ID'}'");
		$content_updated=1;
	}
	
	if (!$env{'promo_item.ID_entity'})
	{
		if ($promo_item{'ID_entity'})
		{
			$env{'promo_item.ID_entity'}=$promo_item{'ID_entity'};
		}
		elsif ($env{'promo_item.ID'})
		{
			%promo_item=App::020::SQL::functions::get_ID(
				'ID' => $env{'promo_item.ID'},
				'db_h' => "main",
				'db_name' => $App::440::db_name,
				'tb_name' => "a440_promo_item",
				'columns' => {'*'=>1}
			);
			$env{'promo_item.ID_entity'}=$promo_item{'ID_entity'};
		}
		else
		{
			die "ufff\n";
		}
	}
	
	if (!$env{'promo_item.ID_entity'})
	{
		die "ufff, missing promo_item.ID_entity\n";
	}
	
	if (!$promo_item{'posix_owner'} && !$env{'promo_item.posix_owner'})
	{
		$env{'promo_item.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update if necessary
	if ($env{'promo_item.ID'})
	{
		my %columns;
		# title
		$env{'promo_item.title'}=~s|$soft_hyphen||g;
		if ($env{'promo_item.title'} && ($env{'promo_item.title'} ne $promo_item{'title'}))
		{
			$columns{'title'}="'".TOM::Security::form::sql_escape($env{'promo_item.title'})."'";
			$columns{'title_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'promo_item.title'}))."'";
		}
		# ID_category
		$columns{'ID_category'}=$env{'promo_item.ID_category'}
			if ($env{'promo_item.ID_category'} && ($env{'promo_item.ID_category'} ne $promo_item{'ID_category'}));
		
		# datetime_start
		$columns{'datetime_start'}="'".$env{'promo_item.datetime_start'}."'"
			if ($env{'promo_item.datetime_start'} && ($env{'promo_item.datetime_start'} ne $promo_item{'datetime_start'}));
		$columns{'datetime_start'}=$env{'promo_item.datetime_start'}
			if (($env{'promo_item.datetime_start'} && ($env{'promo_item.datetime_start'} ne $promo_item{'datetime_start'})) && (not $env{'promo_item.datetime_start'}=~/^\d/));
		
		# datetime_stop
		if (exists $env{'promo_item.datetime_stop'} && ($env{'promo_item.datetime_stop'} ne $promo_item{'datetime_stop'}))
		{
			if (!$env{'promo_item.datetime_stop'})
			{
				$columns{'datetime_stop'}="NULL";
			}
			else
			{
				$columns{'datetime_stop'}="'".$env{'promo_item.datetime_stop'}."'";
			}
		}
		
		# subtitle
		$columns{'subtitle'}="'".TOM::Security::form::sql_escape($env{'promo_item.subtitle'})."'"
			if (exists $env{'promo_item.subtitle'} && ($env{'promo_item.subtitle'} ne $promo_item{'subtitle'}));
		
		# abstract
		$columns{'abstract'}="'".TOM::Security::form::sql_escape($env{'promo_item.abstract'})."'"
			if (exists $env{'promo_item.abstract'} && ($env{'promo_item.abstract'} ne $promo_item{'abstract'}));
		
		# body
		$columns{'body'}="'".TOM::Security::form::sql_escape($env{'promo_item.body'})."'"
			if ($env{'promo_item.body'} && ($env{'promo_item.body'} ne $promo_item{'body'}));
		
		# status
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'promo_item.status'})."'"
			if ($env{'promo_item.status'} && ($env{'promo_item.status'} ne $promo_item{'status'}));
		
		# status_nofollow
		$columns{'status_nofollow'}="'".TOM::Security::form::sql_escape($env{'promo_item.status_nofollow'})."'"
			if ($env{'promo_item.status_nofollow'} && ($env{'promo_item.status_nofollow'} ne $promo_item{'status_nofollow'}));
		
		# alias_url
		$columns{'alias_url'}="'".TOM::Security::form::sql_escape($env{'promo_item.alias_url'})."'"
			if (exists $env{'promo_item.alias_url'} && ($env{'promo_item.alias_url'} ne $promo_item{'alias_url'}));
		$columns{'alias_url'}='NULL' if $columns{'alias_url'} eq "''";
		# alias_addon
		$columns{'alias_addon'}="'".TOM::Security::form::sql_escape($env{'promo_item.alias_addon'})."'"
			if (exists $env{'promo_item.alias_addon'} && ($env{'promo_item.alias_addon'} ne $promo_item{'alias_addon'}));
		
		# posix_owner
		$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'promo_item.posix_owner'})."'"
			if ($env{'promo_item.posix_owner'} && ($env{'promo_item.posix_owner'} ne $promo_item{'posix_owner'}));
		
		# metadata
		my %metadata=App::020::functions::metadata::parse($promo_item{'metadata'});
		
		foreach my $section(split(';',$env{'promo_item.metadata.override_sections'}))
		{
			delete $metadata{$section};
		}
		
		if ($env{'promo_item.metadata.replace'})
		{
			if (!ref($env{'promo_item.metadata'}) && $env{'promo_item.metadata'})
			{
				%metadata=App::020::functions::metadata::parse($env{'promo_item.metadata'});
			}
			if (ref($env{'promo_item.metadata'}) eq "HASH")
			{
				%metadata=%{$env{'promo_item.metadata'}};
			}
		}
		else
		{
			if (!ref($env{'promo_item.metadata'}) && $env{'promo_item.metadata'})
			{
				# when metadata send as <metatree></metatree> then always replace
				%metadata=App::020::functions::metadata::parse($env{'promo_item.metadata'});
			}
			if (ref($env{'promo_item.metadata'}) eq "HASH")
			{
				# metadata overrride
				foreach my $section(keys %{$env{'promo_item.metadata'}})
				{
					foreach my $variable(keys %{$env{'promo_item.metadata'}{$section}})
					{
						$metadata{$section}{$variable}=$env{'promo_item.metadata'}{$section}{$variable};
					}
				}
			}
		}
		
		$env{'promo_item.metadata'}=App::020::functions::metadata::serialize(%metadata);
		
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'promo_item.metadata'})."'"
		if (exists $env{'promo_item.metadata'} && ($env{'promo_item.metadata'} ne $promo_item{'metadata'}));
		
		if ($columns{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::440::db_name,
				'tb_name' => 'a440_promo_item',
				'ID' => $env{'promo_item.ID'},
				'metadata' => {%metadata}
			);
		}
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'promo_item.ID'},
				'db_h' => "main",
				'db_name' => $App::440::db_name,
				'tb_name' => "a440_promo_item",
				'columns' => {
					%columns,
					'posix_modified' => "'".TOM::Security::form::sql_escape($env{'promo_item.posix_modified'} || $main::USRM{'ID_user'})."'"
				},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;# if $columns{'name'};
#			$content_reindex=1 if $columns{'status'};
		}
	}
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::440::db_name,'tb_name'=>'a440_promo_item','ID_entity'=>$env{'promo_item.ID_entity'}});
	}
	
	if ($content_reindex)
	{
		_promo_item_index('ID' => $env{'promo_item.ID'});
	}
	
	$t->close();
	return %env;
}


sub _promo_item_index
{
	my %env=@_;
	return undef unless $env{'ID'};
	
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
