#!/bin/perl
package App::301::functions;

=head1 NAME

App::301::functions

=head1 DESCRIPTION

Functions to handle basic actions with users.

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=back

=cut

use App::301::_init;
use Ext::Elastic::_init;
our $user_index=$App::301::functions::user_index||0;

=head1 FUNCTIONS

=cut


=head2 user_add

 my %user=user_add(
  'user.login' => "userName",
  'user.pass' => "password",
  #'user.hostname' => "",
  #'user.status' => "N"
 );

=cut

sub user_add
{
	my %env=@_;
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_); # do it in background
	}
	my $t=track TOM::Debug(__PACKAGE__."::user_add()");
	
	$env{'user.hostname'}=$tom::H_cookie unless $env{'user.hostname'};
	main::_log("hostname=$env{'user.hostname'}");
	
	my $content_reindex;
	my %user;
	if ($env{'user.ID_user'})
	{
		if (not $env{'user.ID_user'}=~/^[a-zA-Z0-9]{8}$/)
		{
			$t->close();
			return undef;
		}
		main::_log("get user by ID_user='$env{'user.ID_user'}'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user
			WHERE
				ID_user=?
			LIMIT 1;
		},'bind'=>[$env{'user.ID_user'}],'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
		$env{'pass'}=$user{'pass'};
	}
	
	if ($env{'user.ref_facebook'} && !$env{'user.ID_user'})
	{
		main::_log("search user by ref_facebook='$env{'user.ref_facebook'}'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user
			WHERE
				ref_facebook=? AND
				hostname=?
			LIMIT 1;
		},'bind'=>[$env{'user.ref_facebook'},$env{'user.hostname'}],'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
		$env{'user.ID_user'}=$user{'ID_user'} if $user{'ID_user'};
	}
	
	if ($env{'user.ref_deviceid'} && !$env{'user.ID_user'})
	{
		main::_log("search user by ref_deviceid='$env{'user.ref_deviceid'}'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user
			WHERE
				ref_deviceid=? AND
				hostname=?
			LIMIT 1;
		},'bind'=>[$env{'user.ref_deviceid'},$env{'user.hostname'}],'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
		$env{'user.ID_user'}=$user{'ID_user'} if $user{'ID_user'};
	}
	
	if ($env{'user.ref_ID'} && !$env{'user.ID_user'})
	{
		main::_log("search user by ref_ID='$env{'user.ref_ID'}'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user
			WHERE
				ref_ID=? AND
				hostname=?
			LIMIT 1;
		},'bind'=>[$env{'user.ref_ID'},$env{'user.hostname'}],'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
		$env{'user.ID_user'}=$user{'ID_user'} if $user{'ID_user'};
	}
	
	if ($env{'user.login'} && !$env{'user.ID_user'})
	{
		main::_log("search user by login='$env{'user.login'}'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user
			WHERE
				login=? AND
				hostname=?
			LIMIT 1;
		},'bind'=>[$env{'user.login'},$env{'user.hostname'}],'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
		$env{'user.ID_user'}=$user{'ID_user'} if $user{'ID_user'};
		$env{'pass'}=$user{'pass'};
	}
	
	if ($env{'user.email'} && !$env{'user.ID_user'} && $App::301::email_unique)
	{
		main::_log("search user by email='$env{'user.email'}'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user
			WHERE
				email=? AND
				hostname=?
			LIMIT 1;
		},'bind'=>[$env{'user.email'},$env{'user.hostname'}],'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
		$env{'user.ID_user'}=$user{'ID_user'} if $user{'ID_user'};
		$env{'pass'}=$user{'pass'};
	}
	
	
	
	if (!$env{'user.ID_user'})
	{
		main::_log("!user.ID_user, create new");
		# generate random token
		my $token;
		if ($user{'login'} || $user{'email'} || $user{'ref_deviceid'} || $user{'ref_facebook'} || $env{'user.login'} || $env{'user.email'} || $env{'user.ref_facebook'} || $env{'user.ref_deviceid'})
		{
			$token=TOM::Utils::vars::genhash(16);
			main::_log(" secure_hash='$token'");
			$env{'user.secure_hash'}=$token;
		}
		$env{'user.ID_user'}=user_newhash();
		TOM::Database::SQL::execute(qq{
			INSERT INTO `$App::301::db_name`.a301_user
			(
				ID_user,
				secure_hash,
				posix_owner,
				hostname,
				datetime_register
			)
			VALUES
			(
				?,
				?,
				?,
				?,
				NOW()
			)
		},'bind'=>[$env{'user.ID_user'},$token,($env{'user.owner'} || $main::USRM{'ID_user'} || ""),$env{'user.hostname'}],'quiet'=>1) || return undef;
		$env{'new'}=1;
		$content_reindex=1;
	}
	else
	{
		# user already exists
		# check for missing data and problems to autofix it
		if (($user{'login'} || $user{'email'} || $user{'ref_deviceid'} || $user{'ref_facebook'}) && !$user{'secure_hash'})
		{
			$env{'user.secure_hash'}=TOM::Utils::vars::genhash(16);
			main::_log(" generate secure_hash='$env{'user.secure_hash'}'");
		}
	}
	
	
	# AVATAR
	
	if ($env{'avatar'} && -e $env{'avatar'} && not -d $env{'avatar'})
	{
		
		if (my $relation=(App::160::SQL::get_relations(
			'db_name' => $App::301::db_name,
			'l_prefix' => 'a301',
			'l_table' => 'user',
			'l_ID_entity' => $env{'user.ID_user'},
			'rel_type' => 'avatar',
			'r_prefix' => "a501",
			'r_table' => "image",
			'status' => "Y",
			'limit' => 1
		))[0])
		{
			
			my %image=App::501::functions::image_add(
				'image.ID_entity' => $relation->{'r_ID_entity'},
				'image_attrs.name' => $env{'user.ID_user'} || $env{'avatar'},
				'image_attrs.ID_category' => $App::301::photo_cat_ID_entity,
				'file' => $env{'avatar'}
			);
			
			if ($image{'image.ID'})
			{
				App::501::functions::image_regenerate(
					'image.ID' => $image{'image.ID'}
				);
			}
			
		}
		else
		{
			
			my %image=App::501::functions::image_add(
				'image_attrs.name' => $env{'user.ID_user'} || $env{'avatar'},
				'image_attrs.ID_category' => $App::301::photo_cat_ID_entity,
				'image_attrs.status' => 'Y',
				'file' => $env{'avatar'}
			);
			
			if ($image{'image.ID'})
			{
				
				App::501::functions::image_regenerate(
					'image.ID' => $image{'image.ID'}
				);
				
				my ($ID_entity,$ID)=App::160::SQL::new_relation(
					'l_prefix' => 'a301',
					'l_table' => 'user',
					'l_ID_entity' => $env{'user.ID_user'},
					'rel_type' => 'avatar',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'r_ID_entity' => $image{'image.ID_entity'},
					'status' => 'Y',
				);
				
			}
			
		}
		
	}
	
	
	
	# AUTOGRAPH
	
	if ($env{'autograph'} && -e $env{'autograph'} && not -d $env{'autograph'})
	{
		
		if (my $relation=(App::160::SQL::get_relations(
			'db_name' => $App::301::db_name,
			'l_prefix' => 'a301',
			'l_table' => 'user',
			'l_ID_entity' => $env{'user.ID_user'},
			'rel_type' => 'autograph',
			'r_prefix' => "a501",
			'r_table' => "image",
			'status' => "Y",
			'limit' => 1
		))[0])
		{
			
			my %image=App::501::functions::image_add(
				'image.ID_entity' => $relation->{'r_ID_entity'},
				'image_attrs.name' => $env{'user.ID_user'} || $env{'autograph'},
				'file' => $env{'autograph'}
			);
			
			if ($image{'image.ID'})
			{
				App::501::functions::image_regenerate(
					'image.ID' => $image{'image.ID'}
				);
			}
			
		}
		else
		{
			
			my %image=App::501::functions::image_add(
				'image_attrs.name' => $env{'user.ID_user'} || $env{'autograph'},
				'image_attrs.ID_category' => $App::301::autograph_cat_ID_entity,
				'image_attrs.status' => 'Y',
				'file' => $env{'autograph'}
			);
			
			if ($image{'image.ID'})
			{
				
				App::501::functions::image_regenerate(
					'image.ID' => $image{'image.ID'}
				);
				
				my ($ID_entity,$ID)=App::160::SQL::new_relation(
					'l_prefix' => 'a301',
					'l_table' => 'user',
					'l_ID_entity' => $env{'user.ID_user'},
					'rel_type' => 'autograph',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'r_ID_entity' => $image{'image.ID_entity'},
					'status' => 'Y',
				);
				
			}
			
		}
		
	}
	
	
	
	# PROFILE
	
	my %user_profile;
	if (!$env{'user_profile.ID_entity'} && $env{'user.ID_user'})
	{
		main::_log("search user_profile by ID_user='$env{'user.ID_user'}'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user_profile
			WHERE
				ID_entity=?
			LIMIT 1
		},'bind'=>[$env{'user.ID_user'}],'quiet'=>1);
		%user_profile=$sth0{'sth'}->fetchhash();
		$env{'user_profile.ID_entity'}=$user_profile{'ID_entity'} if $user_profile{'ID_entity'};
		$env{'user_profile.ID'}=$user_profile{'ID'} if $user_profile{'ID'};
		
		if (!$env{'user_profile.ID_entity'})
		{
			main::_log("not found user_profile, creating new");
			$env{'user_profile.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::301::db_name,
				'tb_name' => "a301_user_profile",
				'columns' =>
				{
					'ID_entity' => "'$env{'user.ID_user'}'",
					'status' => "'Y'"
				},
				'-journalize' => 1,
			);
			$env{'user_profile.ID_entity'}=$env{'user.ID_user'} if $env{'user_profile.ID'};
			$content_reindex=1;
		}
		
	}
	if ($env{'user_profile.ID'})
	{
		my %columns;
		my %data;
		
		$columns{'gender'}="'".TOM::Security::form::sql_escape($env{'user_profile.gender'})."'"
			if (exists $env{'user_profile.gender'} && ($env{'user_profile.gender'} ne $user_profile{'gender'}));
		$columns{'firstname'}="'".TOM::Security::form::sql_escape($env{'user_profile.firstname'})."'"
			if (exists $env{'user_profile.firstname'} && ($env{'user_profile.firstname'} ne $user_profile{'firstname'}));
		$columns{'middlename'}="'".TOM::Security::form::sql_escape($env{'user_profile.middlename'})."'"
			if (exists $env{'user_profile.middlename'} && ($env{'user_profile.middlename'} ne $user_profile{'middlename'}));
		$columns{'surname'}="'".TOM::Security::form::sql_escape($env{'user_profile.surname'})."'"
			if (exists $env{'user_profile.surname'} && ($env{'user_profile.surname'} ne $user_profile{'surname'}));
		$columns{'maidenname'}="'".TOM::Security::form::sql_escape($env{'user_profile.maidenname'})."'"
			if (exists $env{'user_profile.maidenname'} && ($env{'user_profile.maidenname'} ne $user_profile{'maidenname'}));
		$columns{'name_prefix'}="'".TOM::Security::form::sql_escape($env{'user_profile.name_prefix'})."'"
			if (exists $env{'user_profile.name_prefix'} && ($env{'user_profile.name_prefix'} ne $user_profile{'name_prefix'}));
		$columns{'name_suffix'}="'".TOM::Security::form::sql_escape($env{'user_profile.name_suffix'})."'"
			if (exists $env{'user_profile.name_suffix'} && ($env{'user_profile.name_suffix'} ne $user_profile{'name_suffix'}));
		$columns{'date_birth'}="'".TOM::Security::form::sql_escape($env{'user_profile.date_birth'})."'"
			if (exists $env{'user_profile.date_birth'} && ($env{'user_profile.date_birth'} ne $user_profile{'date_birth'}));
		$columns{'date_birth'} = 'NULL' if $columns{'date_birth'} eq "''";
		$columns{'birth_country_code'}="'".TOM::Security::form::sql_escape($env{'user_profile.birth_country_code'})."'"
			if (exists $env{'user_profile.birth_country_code'} && ($env{'user_profile.birth_country_code'} ne $user_profile{'birth_country_code'}));
		$columns{'PIN'}="'".TOM::Security::form::sql_escape($env{'user_profile.PIN'})."'"
			if (exists $env{'user_profile.PIN'} && ($env{'user_profile.PIN'} ne $user_profile{'PIN'}));
		
		$columns{'street'}="'".TOM::Security::form::sql_escape($env{'user_profile.street'})."'"
			if (exists $env{'user_profile.street'} && ($env{'user_profile.street'} ne $user_profile{'street'}));
		$columns{'street_num'}="'".TOM::Security::form::sql_escape($env{'user_profile.street_num'})."'"
			if (exists $env{'user_profile.street_num'} && ($env{'user_profile.street_num'} ne $user_profile{'street_num'}));
		$columns{'city'}="'".TOM::Security::form::sql_escape($env{'user_profile.city'})."'"
			if (exists $env{'user_profile.city'} && ($env{'user_profile.city'} ne $user_profile{'city'}));
		$columns{'ZIP'}="'".TOM::Security::form::sql_escape($env{'user_profile.ZIP'})."'"
			if (exists $env{'user_profile.ZIP'} && ($env{'user_profile.ZIP'} ne $user_profile{'ZIP'}));
		$columns{'district'}="'".TOM::Security::form::sql_escape($env{'user_profile.district'})."'"
			if (exists $env{'user_profile.district'} && ($env{'user_profile.district'} ne $user_profile{'district'}));
		$columns{'county'}="'".TOM::Security::form::sql_escape($env{'user_profile.county'})."'"
			if (exists $env{'user_profile.county'} && ($env{'user_profile.county'} ne $user_profile{'county'}));
		$columns{'state'}="'".TOM::Security::form::sql_escape($env{'user_profile.state'})."'"
			if (exists $env{'user_profile.state'} && ($env{'user_profile.state'} ne $user_profile{'state'}));
		$columns{'country_code'}="'".TOM::Security::form::sql_escape($env{'user_profile.country_code'})."'"
			if (exists $env{'user_profile.country_code'} && ($env{'user_profile.country_code'} ne $user_profile{'country_code'}));
		
		$columns{'email_public'}="'".TOM::Security::form::sql_escape($env{'user_profile.email_public'})."'"
			if (exists $env{'user_profile.email_public'} && ($env{'user_profile.email_public'} ne $user_profile{'email_public'}));
		$columns{'email_office'}="'".TOM::Security::form::sql_escape($env{'user_profile.email_office'})."'"
			if (exists $env{'user_profile.email_office'} && ($env{'user_profile.email_office'} ne $user_profile{'email_office'}));
		
		$columns{'idcard_num'}="'".TOM::Security::form::sql_escape($env{'user_profile.idcard_num'})."'"
			if (exists $env{'user_profile.idcard_num'} && ($env{'user_profile.idcard_num'} ne $user_profile{'idcard_num'}));
		
		$columns{'passport_num'}="'".TOM::Security::form::sql_escape($env{'user_profile.passport_num'})."'"
			if (exists $env{'user_profile.passport_num'} && ($env{'user_profile.passport_num'} ne $user_profile{'passport_num'}));
		
		$columns{'bank_contact'}="'".TOM::Security::form::sql_escape($env{'user_profile.bank_contact'})."'"
			if (exists $env{'user_profile.bank_contact'} && ($env{'user_profile.bank_contact'} ne $user_profile{'bank_contact'}));
		
		$columns{'birth_place'}="'".TOM::Security::form::sql_escape($env{'user_profile.birth_place'})."'"
			if (exists $env{'user_profile.birth_place'} && ($env{'user_profile.birth_place'} ne $user_profile{'birth_place'}));
		
		$columns{'phone'}="'".TOM::Security::form::sql_escape($env{'user_profile.phone'})."'"
			if (exists $env{'user_profile.phone'} && ($env{'user_profile.phone'} ne $user_profile{'phone'}));
		$columns{'phone_office'}="'".TOM::Security::form::sql_escape($env{'user_profile.phone_office'})."'"
			if (exists $env{'user_profile.phone_office'} && ($env{'user_profile.phone_office'} ne $user_profile{'phone_office'}));
		$columns{'phone_home'}="'".TOM::Security::form::sql_escape($env{'user_profile.phone_home'})."'"
			if (exists $env{'user_profile.phone_home'} && ($env{'user_profile.phone_home'} ne $user_profile{'phone_home'}));
		$columns{'phone_mobile'}="'".TOM::Security::form::sql_escape($env{'user_profile.phone_mobile'})."'"
			if (exists $env{'user_profile.phone_mobile'} && ($env{'user_profile.phone_mobile'} ne $user_profile{'phone_mobile'}));
		
		$columns{'address_current'}="'".TOM::Security::form::sql_escape($env{'user_profile.address_current'})."'"
			if (exists $env{'user_profile.address_current'} && ($env{'user_profile.address_current'} ne $user_profile{'address_current'}));
		$columns{'address_postal'}="'".TOM::Security::form::sql_escape($env{'user_profile.address_postal'})."'"
			if (exists $env{'user_profile.address_postal'} && ($env{'user_profile.address_postal'} ne $user_profile{'address_postal'}));
		
		$columns{'phys_weight'}="'".TOM::Security::form::sql_escape($env{'user_profile.phys_weight'})."'"
			if (exists $env{'user_profile.phys_weight'} && ($env{'user_profile.phys_weight'} ne $user_profile{'phys_weight'}));
		$columns{'phys_height'}="'".TOM::Security::form::sql_escape($env{'user_profile.phys_height'})."'"
			if (exists $env{'user_profile.phys_height'} && ($env{'user_profile.phys_height'} ne $user_profile{'phys_height'}));
		
		$columns{'about_me'}="'".TOM::Security::form::sql_escape($env{'user_profile.about_me'})."'"
			if (exists $env{'user_profile.about_me'} && ($env{'user_profile.about_me'} ne $user_profile{'about_me'}));
			
		$columns{'note'}="'".TOM::Security::form::sql_escape($env{'user_profile.note'})."'"
			if (exists $env{'user_profile.note'} && ($env{'user_profile.note'} ne $user_profile{'note'}));
		
		$columns{'lng'}="'".TOM::Security::form::sql_escape($env{'user_profile.lng'})."'"
			if (exists $env{'user_profile.lng'} && ($env{'user_profile.lng'} ne $user_profile{'lng'}));
		
#		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'user_profile.metadata'})."'"
#			if (exists $env{'user_profile.metadata'} && ($env{'user_profile.metadata'} ne $user_profile{'metadata'}));
		
		# metadata
		my %metadata=App::020::functions::metadata::parse($user_profile{'metadata'});
		
		foreach my $section(split(';',$env{'user_profile.metadata.override_sections'}))
		{
			delete $metadata{$section};
		}
		
		if ($env{'user_profile.metadata.replace'})
		{
			if (!ref($env{'user_profile.metadata'}) && $env{'user_profile.metadata'})
			{
				%metadata=App::020::functions::metadata::parse($env{'user_profile.metadata'});
			}
			if (ref($env{'user_profile.metadata'}) eq "HASH")
			{
				%metadata=%{$env{'user_profile.metadata'}};
			}
		}
		else
		{
			if (!ref($env{'user_profile.metadata'}) && $env{'user_profile.metadata'})
			{
				# when metadata send as <metatree></metatree> then always replace
				%metadata=App::020::functions::metadata::parse($env{'user_profile.metadata'});
	#			my %metadata_=App::020::functions::metadata::parse($env{'product.metadata'});
	#			delete $env{'product.metadata'};
	#			%{$env{'product.metadata'}}=%metadata_;
			}
			if (ref($env{'user_profile.metadata'}) eq "HASH")
			{
				# metadata overrride
				foreach my $section(keys %{$env{'user_profile.metadata'}})
				{
					foreach my $variable(keys %{$env{'user_profile.metadata'}{$section}})
					{
						$metadata{$section}{$variable}=$env{'user_profile.metadata'}{$section}{$variable};
					}
				}
			}
		}
		
		$env{'user_profile.metadata'}=App::020::functions::metadata::serialize(%metadata);
		
		$data{'metadata'}=$env{'user_profile.metadata'}
			if (exists $env{'user_profile.metadata'} && ($env{'user_profile.metadata'} ne $user_profile{'metadata'}));
		
		if ($data{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::301::db_name,
				'tb_name' => 'a301_user_profile',
				'ID' => $env{'user_profile.ID'},
				'metadata' => {%metadata}
			);
		}
		
		if (keys %columns || keys %data)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'user_profile.ID'},
				'db_h' => "main",
				'db_name' => $App::301::db_name,
				'tb_name' => "a301_user_profile",
				'columns' => {%columns},
				'data' => {%data},
				'-journalize' => 1,
				'-posix' => 1
			);
			$content_reindex=1;
		}
	}
	
	if ($env{'user.pass'})
	{
		if ($env{'user.pass'}=~/^(MD5|SHA1):/)
		{
			
		}
		else
		{
			#$env{'user.pass'}='MD5:'.Digest::MD5::md5_hex(Encode::encode_utf8($env{'user.pass'}));
			$env{'user.pass'}='SHA1:'.Digest::SHA1::sha1_hex(Encode::encode_utf8($env{'user.pass'}));
		}
	}
	
	if (
		$env{'user.ID_user'} &&
		(
			exists $env{'user.login'} ||
			exists $env{'user.pass'} ||
			exists $env{'user.email'} ||
			exists $env{'user.posix_owner'} ||
			exists $env{'user.saved_cookies'} ||
			exists $env{'user.saved_session'} ||
			$env{'user.secure_hash'} ||
			$env{'user.status'} ||
			$env{'user.ref_facebook'} ||
			$env{'user.ref_deviceid'} ||
			$env{'user.ref_ID'} ||
			$env{'user.email_verified'}
		)
	)
	{
		my $set;
		# login
		if ($env{'user.login'})
		{
			$set.=",login='".TOM::Security::form::sql_escape($env{'user.login'})."'";
			# check duplicty and remove it
			TOM::Database::SQL::execute(qq{
				UPDATE
					`$App::301::db_name`.a301_user
				SET
					login = CONCAT(login,'-',ID_user) 
				WHERE
					hostname LIKE ?
					AND login LIKE ?
					AND ID_user NOT LIKE ?
			},'bind'=>[
				$user{'hostname'},
				$env{'user.login'},
				$env{'user.ID_user'}
			]);
		}
		elsif (exists $env{'user.login'})
		{
			$set.=",login=NULL";
		}
		# pass
		$set.=",pass='$env{'user.pass'}'"
			if exists $env{'user.pass'};
		# posix_owner
		$set.=",posix_owner='".TOM::Security::form::sql_escape($env{'user.posix_owner'})."'"
			if exists $env{'user.posix_owner'};
		# email
		$set.=",email='".TOM::Security::form::sql_escape($env{'user.email'})."'"
			if exists $env{'user.email'};
		# email_verified
		$set.=",email_verified='$env{'user.email_verified'}'"
			if $env{'user.email_verified'};
		# saved_cookies
		$set.=",saved_cookies='".TOM::Security::form::sql_escape($env{'user.saved_cookies'})."'"
			if exists $env{'user.saved_cookies'};
		# saved_session
		$set.=",saved_session='".TOM::Security::form::sql_escape($env{'user.saved_session'})."'"
			if exists $env{'user.saved_session'};
		# secure_hash
		$set.=",secure_hash='$env{'user.secure_hash'}'"
			if $env{'user.secure_hash'};
		# ref_facebook
		$set.=",ref_facebook='$env{'user.ref_facebook'}'"
			if $env{'user.ref_facebook'};
		# ref_deviceid
		$set.=",ref_deviceid='$env{'user.ref_deviceid'}'"
			if $env{'user.ref_deviceid'};
		# ref_ID
		$set.=",ref_ID='$env{'user.ref_ID'}'"
			if $env{'user.ref_ID'};
		# status
		$set.=",status='$env{'user.status'}'"
			if $env{'user.status'};
		
		$content_reindex=1;
		
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::301::db_name`.a301_user
			SET
				ID_user=?
				$set
			WHERE
				ID_user=?
			LIMIT 1
		},'bind'=>[$env{'user.ID_user'},$env{'user.ID_user'}],'quiet'=>1) || return undef;
		
	}
	else
	{
#		return undef
	}
	
	if ($env{'groups'})
	{
		user_group_add($env{'user.ID_user'},$env{'groups'});
		$content_reindex=1;
	}
	
	if (ref($env{'contact.cats'}) eq "ARRAY")
	{
		foreach (@{$env{'contact.cats'}})
		{
			TOM::Database::SQL::execute(qq{
				REPLACE INTO
					`$App::301::db_name`.a301_contact_rel_cat
					(ID_category, ID_user)
				VALUES
					(?, ?)
			},'bind'=>[$_,$env{'user.ID_user'}],'quiet'=>1);
		}
	}
	
	if ($content_reindex && $user_index)
	{
		_user_index('ID_user'=>$env{'user.ID_user'});
	}
	
	# backward compatibility
	$env{'ID_user'}=$env{'user.ID_user'};
	
	$t->close();
	return %env;
}



=head2 user_new

 my %user=user_new(
  'user.login' => "userName",
  'user.pass' => "password",
  #'user.hostname' => "",
  #'user.status' => "N"
 );

=cut

sub user_new
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::user_new()");
	
	foreach (sort keys %env)
	{
		if ($_ eq "user.pass")
		{
			main::_log("output $_='".('*' x length($env{$_}))."'");
			next;
		}
		main::_log("input $_='$env{$_}'");
	}
	my %data;
	
	$env{'user.hostname'}=$tom::H_cookie unless $env{'user.hostname'};
	
	if ($env{'user.pass'})
	{
		if ($env{'user.pass'}=~/^(MD5|SHA1):/)
		{
			
		}
		else
		{
			$env{'user.pass'}='MD5:'.Digest::MD5::md5_hex(Encode::encode_utf8($env{'user.pass'}));
		}
	}
	
	if ($env{'user.login'}){$env{'user.login'}="'".$env{'user.login'}."'";}
	else {$env{'user.login'}='NULL';}
	
	if ($env{'user.pass'}){$env{'user.pass'}="'".$env{'user.pass'}."'";}
	else {$env{'user.pass'}='NULL';}
	
	if ($env{'user.email'}){$env{'user.email'}="'".$env{'user.email'}."'";}
	else {$env{'user.email'}='NULL';}
	
	$env{'user.autolog'}="N" unless $env{'user.autolog'};
	$env{'user.status'}="N" unless $env{'user.status'};
	
	
	if ($env{'user.login'} ne 'NULL')
	{
		# try to find this user first
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user
			WHERE
				hostname='$env{'user.hostname'}' AND
				login=$env{'user.login'}
			LIMIT 1
		},'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$t->close();
			return %db0_line;
		}
	}
	
	$env{'user.ID_user'}=$data{'user.ID_user'}=$data{'ID_user'}=user_newhash();
	
	TOM::Database::SQL::execute(qq{
		INSERT INTO `$App::301::db_name`.a301_user
		(
			ID_user,
			login,
			pass,
			email,
			autolog,
			hostname,
			datetime_register,
			status
		)
		VALUES
		(
			'$env{'user.ID_user'}',
			$env{'user.login'},
			$env{'user.pass'},
			$env{'user.email'},
			'$env{'user.autolog'}',
			'$env{'user.hostname'}',
			NOW(),
			'$env{'user.status'}'
		)
	}) || die "can't insert user into `$App::301::db_name`.a301_user";
	
	
	foreach (sort keys %data)
	{
		if ($_ eq "pass")
		{
			main::_log("output $_='".('*' x length($data{$_}))."'");
			next;
		}
		main::_log("output $_='$data{$_}'");
	}
	$t->close();
	return %data;
}



=head2 user_newhash()

 my $ID_user=App::301::functions::user_newhash();

=cut

sub user_newhash
{
	my $t=track TOM::Debug(__PACKAGE__."::user_newhash()");
	
	my $var;
	
	while (1)
	{
		$var=TOM::Utils::vars::genhash(8);
		main::_log("trying '$var'");
		my %sth0=TOM::Database::SQL::execute(qq{
			(SELECT ID_user FROM `$App::301::db_name`.a301_user WHERE ID_user=? LIMIT 1) UNION ALL
			(SELECT ID_user FROM `$App::301::db_name`.a301_user_inactive WHERE ID_user=? LIMIT 1)
		},'bind'=>[$var,$var],'quiet'=>1,'-slave'=>1);
		if ($sth0{'rows'}){next}
		last;
	}
	
	$t->close();
	
	return $var;
}



sub user_groups
{
	my $ID_user=shift;
	if (not $ID_user=~/^[a-zA-Z0-9]{8}$/)
	{
		return undef;
	}
	my $t=track TOM::Debug(__PACKAGE__."::user_groups($ID_user)");
	
	my %env=@_;
	
	my %groups;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			user_group.ID AS ID_group,
			user_group.name AS group_name,
			user_group.status
		FROM
			`$App::301::db_name`.`a301_user_rel_group` AS rel
		LEFT JOIN `$App::301::db_name`.`a301_user` AS user ON
		(
			user.ID_user = rel.ID_user
		)
		LEFT JOIN `$App::301::db_name`.`a301_user_group` AS user_group ON
		(
			user_group.ID = rel.ID_group
		)
		WHERE
			rel.ID_user = ?
		ORDER BY
			user_group.name
	},'bind'=>[$ID_user],'quiet'=>1,'slave'=>1);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$groups{$db0_line{'group_name'}}{'ID'} = $db0_line{'ID_group'};
		main::_log("group '$db0_line{'ID_group'}' named '$db0_line{'group_name'}' status='$db0_line{'status'}'");
		$groups{$db0_line{'group_name'}}{'status'} = $db0_line{'status'};
	}
	
	$t->close();
	return %groups;
}


sub user_group_add
{
	my $ID_user=shift;
	if (not $ID_user=~/^[a-zA-Z0-9]{8}$/)
	{
		return undef;
	}
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::301::db_name`.a301_user
		WHERE
			ID_user=?
		LIMIT 1;
	},'bind'=>[$ID_user],'quiet'=>1);
	my %user=$sth0{'sth'}->fetchhash();
	return unless $user{'ID_user'};
	
	my $t=track TOM::Debug(__PACKAGE__."::user_group_add($ID_user)");
	
	my $groups=shift;
	
	my $changed;
	foreach my $group(@{$groups})
	{
		next unless $group;
		main::_log("add to group '$group'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				ID
			FROM
				`$App::301::db_name`.a301_user_group
			WHERE
				(name = ? OR ID = ?) AND
				hostname = ?
		},'bind'=>[$group,$group,$user{'hostname'}],'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("user_group.ID=$db0_line{'ID'} hostname $user{'hostname'}");
			TOM::Database::SQL::execute(qq{
				REPLACE INTO `$App::301::db_name`.a301_user_rel_group
				(
					ID_user,
					ID_group
				)
				VALUES
				(
					?,
					?
				)
			},'bind'=>[$ID_user,$db0_line{'ID'}],'quiet'=>1);
			TOM::Database::SQL::execute(qq{
				INSERT INTO `$App::301::db_name`.a301_user_rel_group_l
				(
					ID_user,
					ID_group,
					datetime_event,
					posix_modified,
					action
				)
				VALUES
				(
					?,
					?,
					NOW(),
					?,
					'A'
				)
			},'bind'=>[$ID_user,$db0_line{'ID'},$main::USRM{'ID_user'}],'quiet'=>1);
			$changed = 1;
		}
		else
		{
			main::_log(" can't find group",1);
		}
	}
	if ($changed)
	{
		App::020::SQL::functions::_save_changetime({
			'db_name' => $App::301::db_name,
			'tb_name' => 'a301_user_rel_group',
			'ID_entity' => $ID_user
		});
	}
	
	$t->close();
	return 1;
}


sub user_group_remove
{
	my $ID_user=shift;
	if (not $ID_user=~/^[a-zA-Z0-9]{8}$/)
	{
		return undef;
	}
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::301::db_name`.a301_user
		WHERE
			ID_user = ?
		LIMIT 1;
	},'bind'=>[$ID_user],'quiet'=>1);
	my %user=$sth0{'sth'}->fetchhash();
	return unless $user{'ID_user'};
	
	my $t=track TOM::Debug(__PACKAGE__."::user_group_add($ID_user)");
	
	my $groups=shift;
	
	my $changed;
	foreach my $group(@{$groups})
	{
		next unless $group;
		main::_log("remove from group '$group'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				ID
			FROM
				`$App::301::db_name`.a301_user_group
			WHERE
				(name = ? OR ID = ?) AND
				hostname = ?
		},'bind'=>[$group,$group,$user{'hostname'}],'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("user_group.ID=$db0_line{'ID'} hostname $user{'hostname'}");
			TOM::Database::SQL::execute(qq{
				DELETE FROM `$App::301::db_name`.a301_user_rel_group
				WHERE
					ID_user = ? AND
					ID_group = ?
				LIMIT 1
			},'bind'=>[$ID_user,$db0_line{'ID'}],'quiet'=>1);
			TOM::Database::SQL::execute(qq{
				INSERT INTO `$App::301::db_name`.a301_user_rel_group_l
				(
					ID_user,
					ID_group,
					datetime_event,
					posix_modified,
					action
				)
				VALUES
				(
					?,
					?,
					NOW(),
					?,
					'R'
				)
			},'bind'=>[$ID_user,$db0_line{'ID'},$main::USRM{'ID_user'}],'quiet'=>1);
			$changed = 1;
		}
		else
		{
			main::_log(" can't find group",1);
		}
	}
	if ($changed)
	{
		App::020::SQL::functions::_save_changetime({
			'db_name' => $App::301::db_name,
			'tb_name' => 'a301_user_rel_group',
			'ID_entity' => $ID_user
		});
	}
	
	$t->close();
	return 1;
}


sub user_active
{
	my $ID_user=shift;
	if (not $ID_user=~/^[a-zA-Z0-9]{8}$/)
	{
		return undef;
	}
	
	my %sth0=TOM::Database::SQL::execute(qq{
		REPLACE INTO `$App::301::db_name`.a301_user
			SELECT
				*
			FROM `$App::301::db_name`.a301_user_inactive
			WHERE
				ID_user=?
			LIMIT 1
	},'bind'=>[$ID_user],'quiet'=>1);
	if ($sth0{'rows'})
	{
		main::_log("inserted user '$ID_user' into active table");
		TOM::Database::SQL::execute(qq{
			DELETE FROM `$App::301::db_name`.a301_user_inactive
			WHERE
				ID_user=?
			LIMIT 1;
		},'bind'=>[$ID_user],'quiet'=>1,'-backend'=>1);
		main::_log("deleted user '$ID_user' from inactive table");
		#$t->close();
		return 1;
	}
	
#	$t->close();
	return undef;
}



sub user_inactive
{
	my $ID_user=shift;
	if (not $ID_user=~/^[a-zA-Z0-9]{8}$/)
	{
		return undef;
	}
	
	my %sth0=TOM::Database::SQL::execute(qq{
		REPLACE INTO `$App::301::db_name`.a301_user_inactive
			SELECT
				*
			FROM `$App::301::db_name`.a301_user
			WHERE
				ID_user=?
			LIMIT 1
	},'bind'=>[$ID_user],'quiet'=>1);
	if ($sth0{'rows'})
	{
		main::_log("inserted user '$ID_user' into inactive table");
		TOM::Database::SQL::execute(qq{
			DELETE FROM `$App::301::db_name`.a301_user
			WHERE
				ID_user=?
			LIMIT 1;
		},'bind'=>[$ID_user],'quiet'=>1,'-backend'=>1);
		main::_log("deleted user '$ID_user' from active table");
		#$t->close();
		return 1;
	}
	
#	$t->close();
	return undef;
}


sub user_get
{
	my $ID_user=shift;
	my %env=@_;
	
	if (not $ID_user=~/^[a-zA-Z0-9]{8}$/)
	{
		return undef;
	}
	my %data;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::301::db_name`.a301_user
		WHERE
			ID_user=?
		LIMIT 1
	},'bind'=>[$ID_user],'quiet'=>1,'-slave'=>1);
	if (%data=$sth0{'sth'}->fetchhash)
	{
		main::_log("user '$ID_user' found in active table");
	}
	else
	{
		main::_log("user '$ID_user' not found in active table, trying inactive");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user_inactive
			WHERE
				ID_user=?
			LIMIT 1
		},'bind'=>[$ID_user],'quiet'=>1,'-slave'=>1);
		if (%data=$sth0{'sth'}->fetchhash)
		{
			main::_log("user found in inactive table");
			if (!$env{'dontactive'})
			{
				main::_log("reactivating user '$data{'ID_user'}' from '$data{'datetime_last_login'}' with '$data{'requests_all'}' requests",3,"a301",2);
				user_active($ID_user);
			}
		}
		else
		{
			main::_log("user '$ID_user' not found in inactive table");
			return undef;
		}
	}
	
	return %data;
}


sub _user_index
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::010::db_name,'class'=>'indexer'}); # do it in background
	my %env=@_;
	return undef unless $env{'ID_user'};
#	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_user_index()",'timer'=>1);
	
	if ($Ext::Solr && ($env{'solr'} || not exists $env{'solr'}))
	{
		my $solr = Ext::Solr::service();
		
		my %content;
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				$App::301::db_name.a301_user
			WHERE
				status IN ('Y')
				AND ID_user=?
		},'quiet'=>1,'bind'=>[$env{'ID_user'}]);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
	#		main::_log("user found");
			my $id=$App::301::db_name.".a301_user.".$db0_line{'ID_user'};
			main::_log("index id='$id'");
			
			my %sth1=TOM::Database::SQL::execute(qq{
				SELECT
					*
				FROM
					$App::301::db_name.a301_user_profile
				WHERE
					ID_entity = ?
			},'quiet'=>1,'bind'=>[$env{'ID_user'}]);
			my %profile=$sth1{'sth'}->fetchhash();
			
			my $doc = WebService::Solr::Document->new();
			
			my @fields;
			
			push @fields,WebService::Solr::Field->new( 'title' => $db0_line{'login'} )
				if $db0_line{'login'};
			push @fields,WebService::Solr::Field->new( 'login_s' => $db0_line{'login'} )
				if $db0_line{'login'};
			
			push @fields,WebService::Solr::Field->new( 'title' => $db0_line{'email'} )
				if $db0_line{'email'};
			push @fields,WebService::Solr::Field->new( 'email_s' => $db0_line{'email'} )
				if $db0_line{'email'};
			
			push @fields,WebService::Solr::Field->new( 'ID_i' => $profile{'ID'} )
				if $profile{'ID'};
			
			my $name=$db0_line{'email'} || $db0_line{'login'};
			
			if ($profile{'firstname'} && $profile{'surname'})
			{
				$name=$profile{'firstname'}.' '.$profile{'surname'};
				$name=$profile{'name_prefix'}.' '.$name
					if $profile{'name_prefix'};
				$name=$name.' '.$profile{'name_suffix'}
					if $profile{'name_suffix'};
				push @fields,WebService::Solr::Field->new( 'title' => $name );
			}
			
			if ($db0_line{'datetime_last_login'})
			{
				$db0_line{'datetime_last_login'}=~s| (\d\d)|T$1|;
				$db0_line{'datetime_last_login'}.="Z";
				push @fields,WebService::Solr::Field->new( 'datetime_last_login_tdt' => $db0_line{'datetime_last_login'} );
			}
			
			push @fields,WebService::Solr::Field->new( 'name_prefix_s' => $profile{'name_prefix'} )
				if $profile{'name_prefix'};
			push @fields,WebService::Solr::Field->new( 'firstname_s' => $profile{'firstname'} )
				if $profile{'firstname'};
			push @fields,WebService::Solr::Field->new( 'surname_s' => $profile{'surname'} )
				if $profile{'surname'};
			push @fields,WebService::Solr::Field->new( 'name_suffix_s' => $profile{'name_suffix'} )
				if $profile{'name_suffix'};
			
			if ($profile{'rating_weight'})
			{
				push @fields,WebService::Solr::Field->new( 'weight' => $profile{'rating_weight'} );
			}
			
			my %metadata=App::020::functions::metadata::parse($profile{'metadata'});
			foreach my $sec(keys %metadata)
			{
				foreach (keys %{$metadata{$sec}})
				{
					next unless $metadata{$sec}{$_};
					if ($_=~s/\[\]$//)
					{
						# this is comma separated array
						foreach my $val (keys %{{map{$_=>1}(split(';',$metadata{$sec}{$_.'[]'}))}})
	#					foreach my $val (split(';',$metadata{$sec}{$_.'[]'}))
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
			
			if (!$name)
			{
				$t->close();
				return undef;
			}
			
			$doc->add_fields((
				WebService::Solr::Field->new( 'id' => $id ),
				
				WebService::Solr::Field->new( 'name' => $name ),
				
				@fields,
				
				WebService::Solr::Field->new( 'hostname_s' => $db0_line{'hostname'} ),
				
				WebService::Solr::Field->new( 'db_s' => $App::301::db_name ),
				WebService::Solr::Field->new( 'addon_s' => 'a301_user' ),
				WebService::Solr::Field->new( 'ID_s' => $db0_line{'ID_user'} ),
				
				
				
			));
			
			$solr->add($doc);
			
	#		main::_log("Solr commiting...");
	#		$solr->commit;
	#		main::_log("commited.");
			
		}
		else
		{
			main::_log("not found active ID",1);
			my $response = $solr->search( "id:".$App::301::db_name.".a301_user.* AND ID_s:$env{'ID_user'}" );
			for my $doc ( $response->docs )
			{
				$solr->delete_by_id($doc->value_for('id'));
			}
	#		$solr->commit;
		}
	}
	
	$Elastic||=$Ext::Elastic::service;
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				a301_user.ID_user,
				a301_user.login,
				a301_user_profile.*,
				a301_user_profile.ID AS ID_entity,
				a301_user.status
			FROM
				$App::301::db_name.a301_user
			INNER JOIN $App::301::db_name.a301_user_profile ON
			(
				a301_user_profile.ID_entity = a301_user.ID_user
			)
			WHERE
				a301_user.status IN ('Y')
				AND a301_user.ID_user=?
		},'quiet'=>1,'bind'=>[$env{'ID_user'}]);
		
		if (!$sth0{'rows'})
		{
			main::_log("user.ID_user=$env{'ID_user'} not found",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::301::db_name,
				'type' => 'a301_user',
				'id' => $env{'ID_user'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::301::db_name,
					'type' => 'a301_user',
					'id' => $env{'ID_user'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %user=$sth0{'sth'}->fetchhash();
		
		%{$user{'metahash'}}=App::020::functions::metadata::parse($user{'metadata'});
		delete $user{'metadata'};
		
		foreach my $sec(keys %{$user{'metahash'}})
		{
			if ($sec=~/\./)
			{
				my $sec_=$sec;$sec_=~s|\.|-|g;
				$user{'metahash'}{$sec_}=$user{'metahash'}{$sec};
				delete $user{'metahash'}{$sec};
				$sec=$sec_;
			}
			foreach my $var(keys %{$user{'metahash'}{$sec}})
			{
				if ($var=~/\./)
				{
					my $var_=$var;$var_=~s|\.|-|g;
					$user{'metahash'}{$sec}{$var_}=$user{'metahash'}{$sec}{$var};
					delete $user{'metahash'}{$sec}{$var};
					next;
				}
			}
		}
		
		foreach my $sec(keys %{$user{'metahash'}})
		{
			foreach (keys %{$user{'metahash'}{$sec}})
			{
				if (!$user{'metahash'}{$sec}{$_})
				{
					delete $user{'metahash'}{$sec}{$_};
					next
				}
				if ($_=~s/\[\]$//)
				{
					foreach my $val (split(';',$user{'metahash'}{$sec}{$_.'[]'}))
					{
						push @{$user{'metahash'}{$sec}{$_}},$val;
						push @{$user{'metahash'}{$sec}{$_.'_t'}},$val;
						
						if ($val=~/^[0-9]{1,9}$/)
						{
							push @{$user{'metahash'}{$sec}{$_.'_i'}},$val;
						}
						if ($val=~/^[0-9\.]{1,9}$/ && (not $val=~/\..*?\./))
						{
							push @{$user{'metahash'}{$sec}{$_.'_f'}},$val;
						}
						
					}
					#push @{$user->{'metahash_keys'}},$sec.'.'.$_ ;
					delete $user{'metahash'}{$sec}{$_.'[]'};
					next;
				}
				
				if ($user{'metahash'}{$sec}{$_}=~/^[0-9]{1,9}$/)
				{
					$user{'metahash'}{$sec}{$_.'_i'} = $user{'metahash'}{$sec}{$_};
				}
				if ($user{'metahash'}{$sec}{$_}=~/^[0-9\.]{1,9}$/ && (not $user{'metahash'}{$sec}{$_}=~/\..*?\./))
				{
					$user{'metahash'}{$sec}{$_.'_f'} = $user{'metahash'}{$sec}{$_};
				}
			}
		}
		
		$Elastic->index(
			'index' => 'cyclone3.'.$App::301::db_name,
			'type' => 'a301_user',
			'id' => $env{'ID_user'},
			'body' => {
				%user
			}
		);
		
	}
	
	$t->close();
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
