#!/bin/perl
package App::710::functions;

=head1 NAME

App::710::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::710::_init|app/"710/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::710::_init;
use TOM::Security::form;
use App::160::SQL;
use App::020::functions::metadata;

our $debug=1;
our $quiet;$quiet=1 unless $debug;

=head2 org_add()

Adds new org or updates old one

Add new org

 org_add
 (
   'org.name' => '',
	'org.status' => '', # Y/N/T
 );

Change org code (displayed in listing)

 org_add
 (
   'org.ID' => '',
   'org.name_code' => '',
 );
 
=cut

sub org_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::org_add()");
	
	my $content_reindex=0; # boolean if is required to update searchindex
	
	# ORG
	
	my %org;
	
	if ($env{'org.ID'})
	{
		undef $env{'org.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding org.ID_entity by org.ID='$env{'org.ID'}'");
		%org=App::020::SQL::functions::get_ID(
			'ID' => $env{'org.ID'},
			'db_h' => "main",
			'db_name' => $App::710::db_name,
			'tb_name' => "a710_org",
			'columns' => {'*'=>1}
		);
		if ($org{'ID'})
		{
			$env{'org.ID_entity'}=$org{'ID_entity'};
			main::_log("found org.ID_entity='$env{'org.ID_entity'}'");
		}
		else
		{
			main::_log("not found org.ID, undef",1);
			undef $env{'org.ID'};
		}
	}
	
	# find org by name_code
	if (!$env{'org.ID'} && $env{'org.name_code'})
	{
		# check if this name_code not already used by another org
		my $sql=qq{
			SELECT
				ID,
				ID_entity,
				name_code
			FROM
				`$App::710::db_name`.a710_org
			WHERE
				name_code='$env{'org.name_code'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'org.ID'} = $db0_line{'ID'} if $db0_line{'ID'};
		$env{'org.ID_entity'} = $db0_line{'ID_entity'} if $db0_line{'ID_entity'};
		%org=App::020::SQL::functions::get_ID(
			'ID' => $env{'org.ID'},
			'db_h' => "main",
			'db_name' => $App::710::db_name,
			'tb_name' => "a710_org",
			'columns' => {'*'=>1}
		);
		main::_log("found org.ID='$env{'org.ID'}'");
	}
	
	if (!$env{'org.ID'}) # create a new
	{
		main::_log("!org.ID, create org.ID");
		my %columns;
		$env{'org.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::710::db_name,
			'tb_name' => "a710_org",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		$org{'ID'}=$env{'org.ID'};
	}
	
	if (!$org{'ID_entity'} && $org{'ID'})
	{
		%org=App::020::SQL::functions::get_ID(
			'ID' => $org{'ID'},
			'db_h' => "main",
			'db_name' => $App::710::db_name,
			'tb_name' => "a710_org",
			'columns' => {'*'=>1}
		);
		$env{'org.ID_entity'}=$org{'ID_entity'};
	}
	
	main::_log("org.ID='$org{'ID'}'");
	
	if (!$org{'posix_owner'} && !$env{'org.posix_owner'})
	{
		$env{'org.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update only if necessary
	my %columns;
	
   # ref_ID
	$columns{'ref_ID'}="'".TOM::Security::form::sql_escape($env{'org.ref_ID'})."'"
		if (exists $env{'org.ref_ID'} && ($env{'org.ref_ID'} ne $org{'ref_ID'}));
	# posix_owner
	$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'org.posix_owner'})."'"
			if ($env{'org.posix_owner'} && ($env{'org.posix_owner'} ne $org{'posix_owner'}));
	# name, name_url
	if ((exists $env{'org.name'}) && ($env{'org.name'} ne $org{'name'}))
	{
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'org.name'})."'";
		$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'org.name'}))."'";
	}
	# name_short
	$columns{'name_short'}="'".TOM::Security::form::sql_escape($env{'org.name_short'})."'"
		if (exists $env{'org.name_short'} && ($env{'org.name_short'} ne $org{'name_short'}));
	# name_code
	$columns{'name_code'}="'".TOM::Security::form::sql_escape($env{'org.name_code'})."'"
		if (exists $env{'org.name_code'} && ($env{'org.name_code'} ne $org{'name_code'}));
	# type
	$columns{'type'}="'".TOM::Security::form::sql_escape($env{'org.type'})."'"
		if (exists $env{'org.type'} && ($env{'org.type'} ne $org{'type'}));
	# legal_form
	$columns{'legal_form'}="'".TOM::Security::form::sql_escape($env{'org.legal_form'})."'"
		if (exists $env{'org.legal_form'} && ($env{'org.legal_form'} ne $org{'legal_form'}));
	# ID_org
	$columns{'ID_org'}="'".TOM::Security::form::sql_escape($env{'org.ID_org'})."'"
		if (exists $env{'org.ID_org'} && ($env{'org.ID_org'} ne $org{'ID_org'}));
	# tax_number
	$columns{'tax_number'}="'".TOM::Security::form::sql_escape($env{'org.tax_number'})."'"
		if (exists $env{'org.tax_number'} && ($env{'org.tax_number'} ne $org{'tax_number'}));
	# VAT_number
	$columns{'VAT_number'}="'".TOM::Security::form::sql_escape($env{'org.VAT_number'})."'"
		if (exists $env{'org.VAT_number'} && ($env{'org.VAT_number'} ne $org{'VAT_number'}));
	# bank_contact
	$columns{'bank_contact'}="'".TOM::Security::form::sql_escape($env{'org.bank_contact'})."'"
		if (exists $env{'org.bank_contact'} && ($env{'org.bank_contact'} ne $org{'bank_contact'}));
	# country_code
	$columns{'country_code'}="'".TOM::Security::form::sql_escape($env{'org.country_code'})."'"
		if (exists $env{'org.country_code'} && ($env{'org.country_code'} ne $org{'country_code'}));
	# state
	$columns{'state'}="'".TOM::Security::form::sql_escape($env{'org.state'})."'"
		if (exists $env{'org.state'} && ($env{'org.state'} ne $org{'state'}));
	# county
	$columns{'county'}="'".TOM::Security::form::sql_escape($env{'org.county'})."'"
		if (exists $env{'org.county'} && ($env{'org.county'} ne $org{'county'}));
	# district
	$columns{'district'}="'".TOM::Security::form::sql_escape($env{'org.district'})."'"
		if (exists $env{'org.district'} && ($env{'org.district'} ne $org{'district'}));
	# city
	$columns{'city'}="'".TOM::Security::form::sql_escape($env{'org.city'})."'"
		if (exists $env{'org.city'} && ($env{'org.city'} ne $org{'city'}));
	# ZIP
	$columns{'ZIP'}="'".TOM::Security::form::sql_escape($env{'org.ZIP'})."'"
		if (exists $env{'org.ZIP'} && ($env{'org.ZIP'} ne $org{'ZIP'}));
	# street
	$columns{'street'}="'".TOM::Security::form::sql_escape($env{'org.street'})."'"
		if (exists $env{'org.street'} && ($env{'org.street'} ne $org{'street'}));
	# street_num
	$columns{'street_num'}="'".TOM::Security::form::sql_escape($env{'org.street_num'})."'"
		if (exists $env{'org.street_num'} && ($env{'org.street_num'} ne $org{'street_num'}));
	# latitude_decimal
	$columns{'latitude_decimal'}="'".TOM::Security::form::sql_escape($env{'org.latitude_decimal'})."'"
		if (exists $env{'org.latitude_decimal'} && ($env{'org.latitude_decimal'} ne $org{'latitude_decimal'}));
	# longitude_decimal
	$columns{'longitude_decimal'}="'".TOM::Security::form::sql_escape($env{'org.longitude_decimal'})."'"
		if (exists $env{'org.longitude_decimal'} && ($env{'org.longitude_decimal'} ne $org{'longitude_decimal'}));
	# location_verified
	$columns{'location_verified'}="'".TOM::Security::form::sql_escape($env{'org.location_verified'})."'"
		if (exists $env{'org.location_verified'} && ($env{'org.location_verified'} ne $org{'location_verified'}));
	# address_postal
	$columns{'address_postal'}="'".TOM::Security::form::sql_escape($env{'org.address_postal'})."'"
		if (exists $env{'org.address_postal'} && ($env{'org.address_postal'} ne $org{'address_postal'}));
	# phone_1
	$columns{'phone_1'}="'".TOM::Security::form::sql_escape($env{'org.phone_1'})."'"
		if (exists $env{'org.phone_1'} && ($env{'org.phone_1'} ne $org{'phone_1'}));
	main::_log("phone_1 $env{'org.phone_1'} ne $org{'phone_1'}");
	# phone_2
	$columns{'phone_2'}="'".TOM::Security::form::sql_escape($env{'org.phone_2'})."'"
		if (exists $env{'org.phone_2'} && ($env{'org.phone_2'} ne $org{'phone_2'}));
	# fax
	$columns{'fax'}="'".TOM::Security::form::sql_escape($env{'org.fax'})."'"
		if (exists $env{'org.fax'} && ($env{'org.fax'} ne $org{'fax'}));
	# email
	$columns{'email'}="'".TOM::Security::form::sql_escape($env{'org.email'})."'"
		if (exists $env{'org.email'} && ($env{'org.email'} ne $org{'email'}));
	# web
	$columns{'web'}="'".TOM::Security::form::sql_escape($env{'org.web'})."'"
		if (exists $env{'org.web'} && ($env{'org.web'} ne $org{'web'}));
	# about
	$columns{'about'}="'".TOM::Security::form::sql_escape($env{'org.about'})."'"
		if (exists $env{'org.about'} && ($env{'org.about'} ne $org{'about'}));
	# note
	$columns{'note'}="'".TOM::Security::form::sql_escape($env{'org.note'})."'"
		if (exists $env{'org.note'} && ($env{'org.note'} ne $org{'note'}));
	# datetime_evidence
	$columns{'datetime_evidence'}="'".TOM::Security::form::sql_escape($env{'org.datetime_evidence'})."'"
		if (exists $env{'org.datetime_evidence'} && ($env{'org.datetime_evidence'} ne $org{'datetime_evidence'}));
	# datetime_modified
	$columns{'datetime_modified'}="'".TOM::Security::form::sql_escape($env{'org.datetime_modified'})."'"
		if (exists $env{'org.datetime_modified'} && ($env{'org.datetime_modified'} ne $org{'datetime_modified'}));
	# mode
	$columns{'mode'}="'".TOM::Security::form::sql_escape($env{'org.mode'})."'"
		if (exists $env{'org.mode'} && ($env{'org.mode'} ne $org{'mode'}));
	# status
	$columns{'status'}="'".TOM::Security::form::sql_escape($env{'org.status'})."'"
		if (exists $env{'org.status'} && ($env{'org.status'} ne $org{'status'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($org{'metadata'});
#	use Data::Dumper;
#	print Dumper(\%columns);
	
	if ($env{'org.metadata.replace'} && $env{'org.metadata'})
	{
		if (!ref($env{'org.metadata'}))
		{
			%metadata=App::020::functions::metadata::parse($env{'org.metadata'});
		}
		if (ref($env{'org.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'org.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'org.metadata'}) && $env{'org.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'org.metadata'});
#			my %metadata_=App::020::functions::metadata::parse($env{'org.metadata'});
#			delete $env{'org.metadata'};
#			%{$env{'org.metadata'}}=%metadata_;
		}
		if (ref($env{'org.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'org.metadata'}})
			{
				foreach my $variable(keys %{$env{'org.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'org.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'org.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'org.metadata'})."'"
		if (exists $env{'org.metadata'} && ($env{'org.metadata'} ne $org{'metadata'}));
	
	# status
	$columns{'status'}="'".TOM::Security::form::sql_escape($env{'org.status'})."'"
		if ($env{'org.status'} && ($env{'org.status'} ne $org{'status'}));
	
	if (keys %columns)
	{
		
		App::020::SQL::functions::update(
			'ID' => $env{'org.ID'},
			'db_h' => "main",
			'db_name' => $App::710::db_name,
			'tb_name' => "a710_org",
			'columns' => {%columns},
			'-posix' => 1,
			'-journalize' => 1
		);
		
		if ($columns{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::710::db_name,
				'tb_name' => 'a710_org',
				'ID' => $env{'org.ID'},
				'metadata' => {%metadata}
			);
		}
		
		$content_reindex=1;
		
	}
	
	if ($env{'org_lng.lng'})
	{
		# okay, ide sa updatovat lng konkretny
		my %org_lng;
		
		# check if this name_code not already used by another org
		my $sql=qq{
			SELECT
				ID,
				ID_entity
			FROM
				`$App::710::db_name`.a710_org_lng
			WHERE
				ID_entity = ? AND
				lng = ?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$org{'ID_entity'},$env{'org_lng.lng'}],'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'org_lng.ID'} = $db0_line{'ID'};
		
		if (!$env{'org_lng.ID'})
		{
			# generate
			$env{'org_lng.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::710::db_name,
				'tb_name' => "a710_org_lng",
				'columns' =>
				{
					'ID_entity' => $org{'ID_entity'},
					'lng' => "'".$env{'org_lng.lng'}."'"
				},
#				'-journalize' => 1,
				'-posix' => 1,
			);
		}
		
		%org_lng=App::020::SQL::functions::get_ID(
			'ID' => $env{'org_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::710::db_name,
			'tb_name' => "a710_org_lng",
			'columns' => {'*'=>1}
		);
		
		main::_log("found org_lng.ID='$env{'org_lng.ID'}'");
		
		my %columns;
	
		# name_short
		$columns{'name_short'}="'".TOM::Security::form::sql_escape($env{'org_lng.name_short'})."'"
			if ($env{'org_lng.name_short'} && ($env{'org_lng.name_short'} ne $org_lng{'name_short'}));
		
		# about
		$columns{'about'}="'".TOM::Security::form::sql_escape($env{'org_lng.about'})."'"
			if ($env{'org_lng.about'} && ($env{'org_lng.about'} ne $org_lng{'about'}));
		
		if (%columns)
		{
			
			App::020::SQL::functions::update(
				'ID' => $env{'org_lng.ID'},
				'db_h' => "main",
				'db_name' => $App::710::db_name,
				'tb_name' => "a710_org_lng",
				'columns' => {%columns},
				'-posix' => 1,
				'-journalize' => 1
			);
			
		}
		
	}
	
	if (ref($env{'org.cats'}) eq "ARRAY")
	{
		if ($env{'org.cats.replace'})
		{
			TOM::Database::SQL::execute(qq{
				DELETE FROM
					$App::710::db_name.a710_org_rel_cat
				WHERE
					ID_org = ?
			},'bind'=>[$org{'ID_entity'}],'quiet'=>1);
			$content_reindex=1;
		}
		
		foreach (@{$env{'org.cats'}})
		{
			TOM::Database::SQL::execute(qq{
				REPLACE INTO
					$App::710::db_name.a710_org_rel_cat
					(ID_category, ID_org)
				VALUES
					(?, $org{'ID_entity'})
			},'bind'=>[$_],'quiet'=>1);
		}
	}
	
	if ($content_reindex)
	{
		# reindex this org
		main::_log("go to reindex");
		_org_index('ID'=>$env{'org.ID'});
	}
	
	$t->close();
	return %env;
}


sub _org_index
{
#	return 1 if TOM::Engine::jobify(\@_); # do it in background
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::710::db_name,'class'=>'indexer'}); # do it in background
	
	my %env=@_;
	return undef unless $env{'ID'};
#	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::710::db_name,'class'=>'indexer'});
	
	my $t=track TOM::Debug(__PACKAGE__."::_org_index($env{'ID'})",'timer'=>1);
	
	my %org=App::020::SQL::functions::get_ID(
		'ID' => $env{'ID'},
		'db_h' => "main",
		'db_name' => $App::710::db_name,
		'tb_name' => "a710_org",
		'columns' => {'*'=>1}
	);
	
	if ($Ext::Solr && ($env{'solr'} || not exists $env{'solr'}))
	{
		my $id=$App::710::db_name.".a710_org.".$org{'ID_entity'};
		
		my $solr = Ext::Solr::service();
		
		if ($org{'status'} ne "Y")
		{
			# zmazat z indexu
			my $response = $solr->search( "id:".$id );
			main::_log("removing inactive index entry '$id'");
			for my $doc ( $response->docs )
			{
				$solr->delete_by_id($doc->value_for('id'));
			}
	#		$solr->commit();
#			$t->close();
#			return 1;
		}
		else
		{
			
			my %content;
			my $suffix="t"; # text
			
			my %sth1=TOM::Database::SQL::execute(qq{
				SELECT
					org_cat.name
				FROM
					$App::710::db_name.a710_org_rel_cat AS org_rel_cat
				INNER JOIN $App::710::db_name.a710_org_cat AS org_cat ON
				(
					org_cat.ID_entity=org_rel_cat.ID_category
				)
				WHERE
					org_rel_cat.ID_org = ?
			},'bind'=>[$org{'ID_entity'}],'quiet'=>1);
			while (my %db1_line=$sth1{'sth'}->fetchhash())
			{
				main::_log(" cat=$db1_line{'name'}");
				push @{$content{'cat'}},WebService::Solr::Field->new( 'cat' => $db1_line{'name'} );
			}
			
			my @fields;
			my %metadata=App::020::functions::metadata::parse($org{'metadata'});
			foreach my $sec(keys %metadata)
			{
				foreach (keys %{$metadata{$sec}})
				{
					next unless $metadata{$sec}{$_};
					if ($_=~s/\[\]$//)
					{
						# this is comma separated array
						foreach my $val (keys %{{map{$_=>1}(split(';',$metadata{$sec}{$_.'[]'}))}})
		#				foreach my $val (split(';',$metadata{$sec}{$_.'[]'}))
						{push @fields,WebService::Solr::Field->new( $sec.'.'.$_.'_sm' => $val);
						push @fields,WebService::Solr::Field->new( $sec.'.'.$_.'_tm' => $val)}
						push @fields,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_);
						next;
					}
					
					push @fields,WebService::Solr::Field->new( $sec.'.'.$_.'_s' => "$metadata{$sec}{$_}" );
					if ($metadata{$sec}{$_}=~/^[0-9]{1,9}$/)
					{
						push @fields,WebService::Solr::Field->new( $sec.'.'.$_.'_i' => "$metadata{$sec}{$_}" );
					}
					if ($metadata{$sec}{$_}=~/^[0-9\.]{1,9}$/)
					{
						push @fields,WebService::Solr::Field->new( $sec.'.'.$_.'_f' => "$metadata{$sec}{$_}" );
					}
					
					# list of used metadata fields
					push @fields,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_ );
				}
			}
			
			my $doc = WebService::Solr::Document->new();
			
			if ($org{'latitude_decimal'})
			{
				push @fields,WebService::Solr::Field->new( 'latitude_decimal_f' => $org{'latitude_decimal'});
			}
			if ($org{'longitude_decimal'})
			{
				push @fields,WebService::Solr::Field->new( 'longitude_decimal_f' => $org{'longitude_decimal'});
			}
			
			#if ($org{'latitude_decimal'} && $org{'longitude_decimal'})
			#{
			#	push @fields,WebService::Solr::Field->new( 'location' => $org{'latitude_decimal'}.','.$org{'longitude_decimal'});
			#}
			
			if ($org{'location_verified'})
			{
				push @fields,WebService::Solr::Field->new( 'location_verified_s' => $org{'location_verified'})
					if $org{'location_verified'};
			}
			
			if ($org{'county'})
			{
				push @fields,WebService::Solr::Field->new( 'county_t' => $org{'county'} || '');
				push @fields,WebService::Solr::Field->new( 'county_s' => $org{'county'} || '');
			}
			
			if ($org{'district'})
			{
				push @fields,WebService::Solr::Field->new( 'district_t' => $org{'district'} || '');
				push @fields,WebService::Solr::Field->new( 'district_s' => $org{'district'} || '');
			}
			
			$doc->add_fields((
				WebService::Solr::Field->new( 'id' => $id ),
				
				WebService::Solr::Field->new( 'name' => $org{'name'} || ''),
				WebService::Solr::Field->new( 'name_url_s' => $org{'name_url'} || ''),
				
				WebService::Solr::Field->new( 'title' => $org{'name'} || ''),
				
				WebService::Solr::Field->new( 'type_'.$suffix => $org{'type'} || ''),
				WebService::Solr::Field->new( 'name_short_'.$suffix => $org{'name_short'} || ''),
				WebService::Solr::Field->new( 'name_code_'.$suffix => $org{'name_code'} || ''),
				WebService::Solr::Field->new( 'legal_form_'.$suffix => $org{'legal_form'} || ''),
				
				WebService::Solr::Field->new( 'ID_org_'.$suffix => $org{'ID_org'} || ''),
				WebService::Solr::Field->new( 'VAT_number_'.$suffix => $org{'VAT_number'} || ''),
				
				WebService::Solr::Field->new( 'state_'.$suffix => $org{'state'} || ''),
				WebService::Solr::Field->new( 'ZIP_'.$suffix => $org{'ZIP'} || ''),
				WebService::Solr::Field->new( 'city_'.$suffix => $org{'city'} || ''),
				WebService::Solr::Field->new( 'street_'.$suffix => $org{'street'} || ''),
				WebService::Solr::Field->new( 'street_number_t' => $org{'street_num'} || ''),
				
				WebService::Solr::Field->new( 'address_postal_'.$suffix => $org{'address_postal'} || ''),
				
				WebService::Solr::Field->new( 'db_s' => $App::710::db_name ),
				WebService::Solr::Field->new( 'addon_s' => 'a710_org' ),
		#			WebService::Solr::Field->new( 'lng_s' => $lng ),
				WebService::Solr::Field->new( 'ID_i' => $org{'ID'} ),
				WebService::Solr::Field->new( 'ID_entity_i' => $org{'ID_entity'} ),
				
				@fields,
				
				@{$content{'cat'}},
				@{$content{'metadata'}},
				
			));
			
		#	return 1;
			
			main::_log("adding index entry '$id'");
			
			$solr->add($doc);
		}
	#	return 1;
	#	$solr->commit;
	}
	
	use Ext::Elastic::_init;
	$Elastic||=$Ext::Elastic::service;
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				org.ID,
				org.ID_entity,
				org.ref_ID,
				org.name,
				org.name_url,
				org.name_short,
				org.name_code,
				org.type,

				org.legal_form,
				org.ID_org,
				org.tax_number,
				org.VAT_number,
				org.bank_contact,

				org.country_code,
				org.state,
				org.county,
				org.district,
				org.city,
				org.ZIP,
				org.street,
				org.street_num,

				org.latitude_decimal,
				org.longitude_decimal,
				org.location_verified,

				org.address_postal,

				org.phone_1,
				org.phone_2,
				org.fax,
				org.email,
				org.web,

				org.about,
				org.note,
				org.metadata,

				org.datetime_evidence,
				org.datetime_modified,

				org.priority_A,
				org.priority_B,
				org.priority_C,

				org.mode,
				org.status
				
			FROM
				$App::710::db_name.a710_org AS org
			WHERE
				org.status IN ('Y','N','L','W') AND
				org.ID=?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (!$sth0{'rows'})
		{
			main::_log("org.ID=$env{'ID'} not found",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::710::db_name,
				'type' => 'a710_org',
				'id' => $env{'ID'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::710::db_name,
					'type' => 'a710_org',
					'id' => $env{'ID'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %org=$sth0{'sth'}->fetchhash();
		
		$org{'name_short'}=[$org{'name_short'}]
			if $org{'name_short'};
		
		foreach (keys %org)
		{
			delete $org{$_} unless $org{$_};
		}
		
		$org{'datetime_modified'}=~s| (\d\d)|T$1|;$org{'datetime_modified'}.="Z"
			if $org{'datetime_modified'};
		delete $org{'datetime_modified'}
			if $org{'datetime_modified'}=~/^0/;
		
		%{$org{'metahash'}}=App::020::functions::metadata::parse($org{'metadata'});
		delete $org{'metadata'};
		
		foreach (grep {not defined $org{$_}} keys %org)
		{
			delete $org{$_};
		}
		
		foreach my $sec(keys %{$org{'metahash'}})
		{
			if ($sec=~/\./)
			{
				my $sec_=$sec;$sec_=~s|\.|-|g;
				$org{'metahash'}{$sec_}=$org{'metahash'}{$sec};
				delete $org{'metahash'}{$sec};
				$sec=$sec_;
			}
			foreach my $var(keys %{$org{'metahash'}{$sec}})
			{
				if ($var=~/\./)
				{
					my $var_=$var;$var_=~s|\.|-|g;
					$org{'metahash'}{$sec}{$var_}=$org{'metahash'}{$sec}{$var};
					delete $org{'metahash'}{$sec}{$var};
					next;
				}
			}
		}
		
		foreach my $sec(keys %{$org{'metahash'}})
		{
			foreach (keys %{$org{'metahash'}{$sec}})
			{
				if (!$org{'metahash'}{$sec}{$_})
				{
					delete $org{'metahash'}{$sec}{$_};
					next
				}
				if ($_=~s/\[\]$//)
				{
					foreach my $val (split(';',$org{'metahash'}{$sec}{$_.'[]'}))
					{
						push @{$org{'metahash'}{$sec}{$_}},$val;
						push @{$org{'metahash'}{$sec}{$_.'_t'}},$val;
						
						if ($val=~/^[0-9]{1,9}$/)
						{
							push @{$org{'metahash'}{$sec}{$_.'_i'}},$val;
						}
						if ($val=~/^[0-9\.]{1,9}$/ && (not $val=~/\..*?\./))
						{
							push @{$org{'metahash'}{$sec}{$_.'_f'}},$val;
						}
						
					}
					#push @{$org->{'metahash_keys'}},$sec.'.'.$_ ;
					delete $org{'metahash'}{$sec}{$_.'[]'};
					next;
				}
				
				if ($org{'metahash'}{$sec}{$_}=~/^[0-9]{1,9}$/)
				{
					$org{'metahash'}{$sec}{$_.'_i'} = $org{'metahash'}{$sec}{$_};
				}
				if ($org{'metahash'}{$sec}{$_}=~/^[0-9\.]{1,9}$/ && (not $org{'metahash'}{$sec}{$_}=~/\..*?\./))
				{
					$org{'metahash'}{$sec}{$_.'_f'} = $org{'metahash'}{$sec}{$_};
				}
			}
		}
		
		# categories
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				a710_org_rel_cat.ID_org,
				a710_org_cat.ID_charindex,
				a710_org_cat.ID AS cat_ID,
				a710_org_cat.ID_entity AS cat_ID_entity,
				a710_org_cat.name,
				a710_org_cat.name_url,
				a710_org_cat.lng
			FROM
				$App::710::db_name.a710_org_rel_cat
			INNER JOIN $App::710::db_name.a710_org_cat ON
			(
				a710_org_rel_cat.ID_category = a710_org_cat.ID_entity
			)
			WHERE
				a710_org_rel_cat.ID_org=?
		},'quiet'=>1,'bind'=>[$org{'ID_entity'}]);
		my %used;
		my %used2;
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			push @{$org{'cat'}},$db0_line{'cat_ID_entity'}
				unless $used{$db0_line{'cat_ID_entity'}};
			
			push @{$org{'cat_charindex'}},$db0_line{'ID_charindex'}
				unless $used{$db0_line{'ID_charindex'}};
			
			push @{$org{'cat_name'}},$db0_line{'name'}
				unless $used{$db0_line{'name'}};
				
			push @{$org{'cat_name_url'}},$db0_line{'name_url'}
				unless $used{$db0_line{'name_url'}};
				
			push @{$org{'locale'}{$db0_line{'lng'}}{'cat_name'}}, $db0_line{'name'};
			
			my %sql_def=('db_h' => "main",'db_name' => $App::710::db_name,'tb_name' => "a710_org_cat");
			foreach my $p(
				App::020::SQL::functions::tree::get_path(
					$db0_line{'cat_ID'},
					%sql_def,
					'-cache' => 86400*7
				)
			)
			{
				push @{$org{'cat_path'}},$p->{'ID_entity'}
					unless $used2{$p->{'ID_entity'}};
				$used2{$p->{'ID_entity'}}++;
			}
			
			$used{$db0_line{'ID_charindex'}}++;
			$used{$db0_line{'cat_ID_entity'}}++;
		}
		
		# org_lng
		my %used;
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				name_short,
				about,
				lng
			FROM
				$App::710::db_name.a710_org_lng
			WHERE
				status='Y'
				AND ID_entity=?
		},'quiet'=>1,'bind'=>[$org{'ID_entity'}]);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			if ($db0_line{'name_short'})
			{
				push @{$org{'name_short'}},$db0_line{'name_short'}
					unless $used{$db0_line{'name_short'}};
				$used{$db0_line{'name_short'}}++;
			}
			
			foreach (grep {not defined $db0_line{$_}} keys %db0_line)
			{
				delete $db0_line{$_};
			}
			
			%{$org{'locale'}{$db0_line{'lng'}}}=%db0_line;
		}
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		$Elastic->index(
			'index' => 'cyclone3.'.$App::710::db_name,
			'type' => 'a710_org',
			'id' => $env{'ID'},
			'body' => {
				%org,
				'_datetime_index' => 
					$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
					.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z'
			}
		);
		
	}

	$t->close();
}





=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
