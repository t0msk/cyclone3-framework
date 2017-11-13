#!/bin/perl
package App::420::functions;

=head1 NAME

App::420::functions

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
   'static.lng' => '',
   'static.ID_entity' => '',
   'static.ID_category' => '',
   'static.name' => '',
   'static.body' => ''
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
		$env{'static.lng'}=$static{'lng'} if $static{'lng'};
	}
	
	$env{'static.lng'}=$tom::lng unless $env{'static.lng'};
	
	# static.ID is unknown
	if (!$env{'static.ID'} && $env{'static.ID_entity'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::420::db_name`.`a420_static`
			WHERE
				ID_entity=? AND
				lng=? AND
				status IN ('Y','N','L')
			LIMIT 1
		},'bind'=>[
			$env{'static.ID_entity'},
			$env{'static.lng'}
		],'quiet'=>1);
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
		my %data;
		$data{'lng'} = $env{'static.lng'};
		
		$env{'static.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::420::db_name,
			'tb_name' => "a420_static",
			'columns' =>
			{
				%columns,
			},
			'data' => {
				%data
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
			$env{'static.lng'}=$static{'lng'};
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
		
		# metadata
		my %metadata=App::020::functions::metadata::parse($static{'metadata'});
		
		foreach my $section(split(';',$env{'static.metadata.override_sections'}))
		{
			delete $metadata{$section};
		}
		
		if ($env{'static.metadata.replace'})
		{
			if (!ref($env{'static.metadata'}) && $env{'static.metadata'})
			{
				%metadata=App::020::functions::metadata::parse($env{'static.metadata'});
			}
			if (ref($env{'static.metadata'}) eq "HASH")
			{
				%metadata=%{$env{'static.metadata'}};
			}
		}
		else
		{
			if (!ref($env{'static.metadata'}) && $env{'static.metadata'})
			{
				# when metadata send as <metatree></metatree> then always replace
				%metadata=App::020::functions::metadata::parse($env{'static.metadata'});
			}
			if (ref($env{'static.metadata'}) eq "HASH")
			{
				# metadata overrride
				foreach my $section(keys %{$env{'static.metadata'}})
				{
					foreach my $variable(keys %{$env{'static.metadata'}{$section}})
					{
						$metadata{$section}{$variable}=$env{'static.metadata'}{$section}{$variable};
					}
				}
			}
		}
		
		$env{'static.metadata'}=App::020::functions::metadata::serialize(%metadata);
		
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'static.metadata'})."'"
		if (exists $env{'static.metadata'} && ($env{'static.metadata'} ne $static{'metadata'}));
		
		if ($columns{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::420::db_name,
				'tb_name' => 'a420_static',
				'ID' => $env{'static.ID'},
				'metadata' => {%metadata}
			);
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
			$content_reindex=1;# if $columns{'name'};
#			$content_reindex=1 if $columns{'status'};
		}
	}
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::420::db_name,'tb_name'=>'a420_static','ID_entity'=>$env{'static.ID_entity'}});
	}
	
	if ($content_reindex)
	{
		_static_index('ID' => $env{'static.ID'});
	}
	
	$t->close();
	return %env;
}


sub _static_index
{
	my %env=@_;
	return undef unless $env{'ID'};
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_static_index()",'timer'=>1);
	
	my $solr = Ext::Solr::service();
	
	my %content;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::420::db_name.a420_static
		WHERE
			status IN ('Y','L')
			AND ID=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("found");
		
		my $id=$App::420::db_name.".a420_static.".$db0_line{'ID'};
		main::_log("index id='$id'");
		
		my $doc = WebService::Solr::Document->new();
		
		$db0_line{'body'}=~s|<.*?>| |gms;
		$db0_line{'body'}=~s|&nbsp;| |gms;
		$db0_line{'body'}=~s|  | |gms;
		
#		print $db0_line{'body'};
		
		$db0_line{'datetime_create'}=~s| (\d\d)|T$1|;
		$db0_line{'datetime_create'}.="Z";
		
		my @content;
		
		push @content,WebService::Solr::Field->new( 'cat' =>  $db0_line{'ID_category'})
			if $db0_line{'ID_category'};
		
		my %metadata=App::020::functions::metadata::parse($db0_line{'metadata'});
		foreach my $sec(keys %metadata)
		{
			foreach (keys %{$metadata{$sec}})
			{
				next unless $metadata{$sec}{$_};
				push @content,WebService::Solr::Field->new( $sec.'.'.$_.'_s' => "$metadata{$sec}{$_}" );
				push @content,WebService::Solr::Field->new( $sec.'.'.$_.'_t' => "$metadata{$sec}{$_}" );
				if ($metadata{$sec}{$_}=~/^[0-9]+$/)
				{
					push @content,WebService::Solr::Field->new( $sec.'.'.$_.'_i' => "$metadata{$sec}{$_}" );
				}
				if ($metadata{$sec}{$_}=~/^[0-9\.]+$/)
				{
					push @content,WebService::Solr::Field->new( $sec.'.'.$_.'_f' => "$metadata{$sec}{$_}" );
				}
				
				# list of used metadata fields
				push @content,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_ );
			}
		}
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				$App::420::db_name.a420_static_cat
			WHERE
				ID=?
		},'quiet'=>1,'bind'=>[$db0_line{'ID_category'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			push @content,WebService::Solr::Field->new( 'cat' => $db1_line{'name'} );
			push @content,WebService::Solr::Field->new( 'cat_ID_sm' =>  $db1_line{'ID'});
			push @content,WebService::Solr::Field->new( 'cat_charindex_sm' =>  $db1_line{'ID_charindex'});
		}
		
		$doc->add_fields((
			WebService::Solr::Field->new( 'id' => $id ),
			
			WebService::Solr::Field->new( 'name' => $db0_line{'name'} || '' ),
			WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} || ''),
			WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
			
			WebService::Solr::Field->new( 'description' => $db0_line{'body'} || ''),
			
			WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_create'} ),
			
			WebService::Solr::Field->new( 'db_s' => $App::420::db_name ),
			WebService::Solr::Field->new( 'addon_s' => 'a420_static' ),
			WebService::Solr::Field->new( 'ID_i' => $db0_line{'ID'} ),
			WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} ),
			
			WebService::Solr::Field->new( 'lng_s' => $db0_line{'lng'} ),
			
			WebService::Solr::Field->new( 'status_s' => $db0_line{'status'} ),
			
			@content
		));
		
		$solr->add($doc);
		
	}
	else
	{
		main::_log("not found active ID",1);
		my $response = $solr->search( "id:".$App::420::db_name.".a420_static.* AND ID_i:$env{'ID'}" );
		for my $doc ( $response->docs )
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
#		$solr->commit;
	}
	
	$t->close();
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
