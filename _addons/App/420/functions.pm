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
	
	use Ext::Elastic::_init;
	$Elastic||=$Ext::Elastic::service;
	if ($Elastic)
	{
		my $t=track TOM::Debug(__PACKAGE__."::_static_index::elastic(".$env{'ID'}.")",'timer'=>1);
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				`static`.*
			FROM
				`$App::420::db_name`.`a420_static` AS `static`
			WHERE
						`static`.`status` IN ('Y','N','L','W')
				AND		`static`.`ID_entity` = ?
			LIMIT
				1
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (!$sth0{'rows'})
		{
			main::_log("static.ID=$env{'ID'} not found",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::420::db_name,
				'type' => 'a420_static',
				'id' => $env{'ID'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::420::db_name,
					'type' => 'a420_static',
					'id' => $env{'ID'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %static = $sth0{'sth'}->fetchhash();
		
		foreach (keys %static)
		{
			delete $static{$_} unless $static{$_};
		}
		
		$static{'datetime_modified'}=~s| (\d\d)|T$1|;$static{'datetime_modified'}.="Z"
			if $static{'datetime_modified'};
		delete $static{'datetime_modified'}
			if $static{'datetime_modified'}=~/^0/;
		
		%{$static{'metahash'}}=App::020::functions::metadata::parse($static{'metadata'});
		delete $static{'metadata'};
		
		foreach (grep {not defined $static{$_}} keys %static)
		{
			delete $static{$_};
		}
		
		foreach my $sec(keys %{$static{'metahash'}})
		{
			if ($sec=~/\./)
			{
				my $sec_=$sec;$sec_=~s|\.|-|g;
				$static{'metahash'}{$sec_}=$static{'metahash'}{$sec};
				delete $static{'metahash'}{$sec};
				$sec=$sec_;
			}
			foreach my $var(keys %{$static{'metahash'}{$sec}})
			{
				if ($var=~/\./)
				{
					my $var_=$var;$var_=~s|\.|-|g;
					$static{'metahash'}{$sec}{$var_}=$static{'metahash'}{$sec}{$var};
					delete $static{'metahash'}{$sec}{$var};
					next;
				}
			}
		}
		
		foreach my $sec(keys %{$static{'metahash'}})
		{
			foreach (keys %{$static{'metahash'}{$sec}})
			{
				if (!$static{'metahash'}{$sec}{$_})
				{
					delete $static{'metahash'}{$sec}{$_};
					next
				}
				if ($_=~s/\[\]$//)
				{
					foreach my $val (split(';',$static{'metahash'}{$sec}{$_.'[]'}))
					{
						push @{$static{'metahash'}{$sec}{$_}},$val;
						push @{$static{'metahash'}{$sec}{$_.'_t'}},$val;
						
						if ($val=~/^[0-9]{1,9}$/)
						{
							push @{$static{'metahash'}{$sec}{$_.'_i'}},$val;
						}
						if ($val=~/^[0-9\.]{1,9}$/ && (not $val=~/\..*?\./))
						{
							push @{$static{'metahash'}{$sec}{$_.'_f'}},$val;
						}
						
					}
					#push @{$static->{'metahash_keys'}},$sec.'.'.$_ ;
					delete $static{'metahash'}{$sec}{$_.'[]'};
					next;
				}
				
				if ($static{'metahash'}{$sec}{$_}=~/^[0-9]{1,9}$/)
				{
					$static{'metahash'}{$sec}{$_.'_i'} = $static{'metahash'}{$sec}{$_};
				}
				if ($static{'metahash'}{$sec}{$_}=~/^[0-9\.]{1,9}$/ && (not $static{'metahash'}{$sec}{$_}=~/\..*?\./))
				{
					$static{'metahash'}{$sec}{$_.'_f'} = $static{'metahash'}{$sec}{$_};
				}
			}
		}
		
		# categories
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				`ID_charindex`,
				`ID_entity`,
				`name`,
				`name_url`,
				`lng`
			FROM
				`$App::420::db_name`.`a420_static_cat`
			WHERE
				`ID` = ?
		},'quiet'=>1,'bind'=>[$static{'ID_category'}]);
		my %used;
		my %used2;
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			push @{$static{'cat'}},$db0_line{'ID_entity'}
				unless $used{$db0_line{'ID_entity'}};
			
			push @{$static{'cat_charindex'}},$db0_line{'ID_charindex'}
				unless $used{$db0_line{'ID_charindex'}};
			
			push @{$static{'cat_name'}},$db0_line{'name'}
				unless $used{$db0_line{'name'}};
				
			push @{$static{'cat_name_url'}},$db0_line{'name_url'}
				unless $used{$db0_line{'name_url'}};
				
			
			my %sql_def=('db_h' => "main",'db_name' => $App::420::db_name,'tb_name' => "a420_static_cat");
			foreach my $p(
				App::020::SQL::functions::tree::get_path(
					$db0_line{'ID_category'},
					%sql_def,
					'-cache' => 86400*7
				)
			)
			{
				push @{$static{'cat_path'}},$p->{'ID_entity'}
					unless $used2{$p->{'ID_entity'}};
				$used2{$p->{'ID_entity'}}++;
			}
			
			$used{$db0_line{'ID_charindex'}}++;
			$used{$db0_line{'ID_entity'}}++;
		}
		
		# static lng
		my %used;
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				`name`,
				`body`,
				`lng`
			FROM
				`$App::420::db_name`.`a420_static`
			WHERE
						`status` = 'Y'
				AND		`ID_entity` = ?
		},'quiet'=>1,'bind'=>[$static{'ID_entity'}]);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			#if ($db0_line{'name'})
			#{
			#	push @{$static{'name'}},$db0_line{'name'}
			#		unless $used{$db0_line{'name'}};
			#	$used{$db0_line{'name'}}++;
			#}
			
			foreach (grep {not defined $db0_line{$_}} keys %db0_line)
			{
				delete $db0_line{$_};
			}
			
			%{$static{'locale'}{$db0_line{'lng'}}}=%db0_line;
		}
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		$Elastic->index(
			'index' => 'cyclone3.'.$App::420::db_name,
			'type' => 'a420_static',
			'id' => $env{'ID'},
			'body' => {
				%static,
				'_datetime_index' => 
					$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
					.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z'
			}
		);
		
		$t->close();
	}
	
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_static_index()",'timer'=>1);
	
	if ($Ext::Solr && ($env{'solr'} || not exists $env{'solr'}))
	{
		my $solr = Ext::Solr::service();
		
		my %content;
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::420::db_name`.`a420_static`
			WHERE
					`status` IN ('Y','L')
				AND	`ID` = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
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
	}
	
	$t->close();
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
