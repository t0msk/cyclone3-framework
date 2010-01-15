#!/bin/perl
package App::301::functions;

=head1 NAME

App::301::functions

=head1 DESCRIPTION

Functions to handle basic actions with users.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
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
	my $t=track TOM::Debug(__PACKAGE__."::user_add()");
	
	$env{'user.hostname'}=$tom::H_cookie unless $env{'user.hostname'};
	main::_log("hostname=$env{'user.hostname'}");
	
	my %user;
	if ($env{'user.ID_user'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`TOM`.a301_user
			WHERE
				ID_user='$env{'user.ID_user'}'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
	}
	
	if ($env{'user.login'} && !$env{'user.ID_user'})
	{
		main::_log("search user by login='$env{'user.login'}'");
		my $login=TOM::Security::form::sql_escape($env{'user.login'});
		my $sql=qq{
			SELECT
				*
			FROM
				`TOM`.a301_user
			WHERE
				login='$login' AND
				hostname='$env{'user.hostname'}'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
		$env{'user.ID_user'}=$user{'ID_user'} if $user{'ID_user'};
	}
	
	if (!$env{'user.ID_user'})
	{
		main::_log("!user.ID_user, create new");
		
		$env{'user.ID_user'}=user_newhash();
		
		TOM::Database::SQL::execute(qq{
			INSERT INTO `TOM`.a301_user
			(
				ID_user,
				posix_owner,
				hostname,
				datetime_register
			)
			VALUES
			(
				'$env{'user.ID_user'}',
				'$main::USRM{'ID_user'}',
				'$env{'user.hostname'}',
				NOW()
			)
		},'quiet'=>1) || return undef;
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
		my $sql=qq{
			SELECT
				*
			FROM
				`TOM`.a301_user_profile
			WHERE
				ID_entity='$env{'user.ID_user'}'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%user_profile=$sth0{'sth'}->fetchhash();
		$env{'user_profile.ID_entity'}=$user_profile{'ID_entity'} if $user_profile{'ID_entity'};
		$env{'user_profile.ID'}=$user_profile{'ID'} if $user_profile{'ID'};
		
		if (!$env{'user_profile.ID_entity'})
		{
			$env{'user_profile.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => 'TOM',
				'tb_name' => "a301_user_profile",
				'columns' =>
				{
					'ID_entity' => "'$env{'user.ID_user'}'",
					'status' => "'Y'"
				},
				'-journalize' => 1,
			);
			$env{'user_profile.ID_entity'}=$env{'user.ID_user'} if $env{'user_profile.ID'};
		}
		
	}
	if ($env{'user_profile.ID'})
	{
		my %columns;
		$columns{'gender'}="'".TOM::Security::form::sql_escape($env{'user_profile.gender'})."'"
			if ($env{'user_profile.gender'} && ($env{'user_profile.gender'} ne $user_profile{'gender'}));
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
			if ($env{'user_profile.date_birth'} && ($env{'user_profile.date_birth'} ne $user_profile{'date_birth'}));
		$columns{'birth_country_code'}="'".TOM::Security::form::sql_escape($env{'user_profile.birth_country_code'})."'"
			if (exists $env{'user_profile.birth_country_code'} && ($env{'user_profile.birth_country_code'} ne $user_profile{'birth_country_code'}));
		$columns{'PIN'}="'".TOM::Security::form::sql_escape($env{'user_profile.PIN'})."'"
			if ($env{'user_profile.PIN'} && ($env{'user_profile.PIN'} ne $user_profile{'PIN'}));
		
		$columns{'street'}="'".TOM::Security::form::sql_escape($env{'user_profile.street'})."'"
			if ($env{'user_profile.street'} && ($env{'user_profile.street'} ne $user_profile{'street'}));
		$columns{'street_num'}="'".TOM::Security::form::sql_escape($env{'user_profile.street_num'})."'"
			if ($env{'user_profile.street_num'} && ($env{'user_profile.street_num'} ne $user_profile{'street_num'}));
		$columns{'city'}="'".TOM::Security::form::sql_escape($env{'user_profile.city'})."'"
			if ($env{'user_profile.city'} && ($env{'user_profile.city'} ne $user_profile{'city'}));
		$columns{'ZIP'}="'".TOM::Security::form::sql_escape($env{'user_profile.ZIP'})."'"
			if (exists $env{'user_profile.ZIP'} && ($env{'user_profile.ZIP'} ne $user_profile{'ZIP'}));
		$columns{'district'}="'".TOM::Security::form::sql_escape($env{'user_profile.district'})."'"
			if ($env{'user_profile.district'} && ($env{'user_profile.district'} ne $user_profile{'district'}));
		$columns{'county'}="'".TOM::Security::form::sql_escape($env{'user_profile.county'})."'"
			if ($env{'user_profile.county'} && ($env{'user_profile.county'} ne $user_profile{'county'}));
		$columns{'state'}="'".TOM::Security::form::sql_escape($env{'user_profile.state'})."'"
			if ($env{'user_profile.state'} && ($env{'user_profile.state'} ne $user_profile{'state'}));
		$columns{'country_code'}="'".TOM::Security::form::sql_escape($env{'user_profile.country_code'})."'"
			if ($env{'user_profile.country_code'} && ($env{'user_profile.country_code'} ne $user_profile{'country_code'}));
		
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

		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'user_profile.metadata'})."'"
			if (exists $env{'user_profile.metadata'} && ($env{'user_profile.metadata'} ne $user_profile{'metadata'}));
      
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'user_profile.ID'},
				'db_h' => "main",
				'db_name' => 'TOM',
				'tb_name' => "a301_user_profile",
				'columns' => {%columns},
				'-journalize' => 1,
				'-posix' => 1
			);
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
			exists $env{'user.saved_cookies'} ||
			exists $env{'user.saved_session'} ||
			$env{'user.status'} ||
			$env{'user.email_verified'}
		)
	)
	{
		my $set;
		# login
		if ($env{'user.login'})
		{
			$set.=",login='".TOM::Security::form::sql_escape($env{'user.login'})."'";
		}
		elsif (exists $env{'user.login'})
		{
			$set.=",login=NULL";
		}
		# pass
		$set.=",pass='$env{'user.pass'}'"
			if exists $env{'user.pass'};
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
		# status
		$set.=",status='$env{'user.status'}'"
			if $env{'user.status'};
		
		TOM::Database::SQL::execute(qq{
			UPDATE `TOM`.a301_user
			SET
				ID_user='$env{'user.ID_user'}'
				$set
			WHERE
				ID_user='$env{'user.ID_user'}'
			LIMIT 1
		},'quiet'=>1) || return undef;
		
	}
	else
	{
#		return undef
	}
	
	foreach my $group(@{$env{'groups'}})
	{
		next unless $group;
		main::_log("add to group '$group'");
		
		my $sql=qq{
			SELECT
				ID
			FROM
				TOM.a301_user_group
			WHERE
				(name = '$group' OR ID='$group') AND
				hostname = '$env{'user.hostname'}'
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			my $sql=qq{
				REPLACE INTO TOM.a301_user_rel_group
				(
					ID_user,
					ID_group
				)
				VALUES
				(
					'$env{'user.ID_user'}',
					'$db0_line{'ID'}'
				)
			};
			TOM::Database::SQL::execute($sql,'quiet'=>1);
			
			my $sql=qq{
				INSERT INTO TOM.a301_user_rel_group_l
				(
					ID_user,
					ID_group,
					datetime_event,
					posix_modified,
					action
				)
				VALUES
				(
					'$env{'user.ID_user'}',
					'$db0_line{'ID'}',
					NOW(),
					'$main::USRM{'ID_user'}',
					'A'
				)
			};
			TOM::Database::SQL::execute($sql,'quiet'=>1);
		}
		
	}
	
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
		my $sql=qq{
			SELECT
				*
			FROM
				TOM.a301_user
			WHERE
				hostname='$env{'user.hostname'}' AND
				login=$env{'user.login'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$t->close();
			return %db0_line;
		}
	}
	
	$env{'user.ID_user'}=$data{'user.ID_user'}=$data{'ID_user'}=user_newhash();
	
	TOM::Database::SQL::execute(qq{
		INSERT INTO TOM.a301_user
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
	}) || die "can't insert user into TOM.a301_user";
	
	
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
			(SELECT ID_user FROM TOM.a301_user WHERE ID_user='$var' LIMIT 1) UNION ALL
			(SELECT ID_user FROM TOM.a301_user_inactive WHERE ID_user='$var' LIMIT 1)
		},'quiet'=>1,'-slave'=>1);
		if ($sth0{'rows'}){next}
		last;
	}
	
	$t->close();
	
	return $var;
}



sub user_groups
{
	my $ID_user=shift;
	my $t=track TOM::Debug(__PACKAGE__."::user_groups($ID_user)");
	
	my %env=@_;
	
	my %groups;
	
	my $sql=qq{
		SELECT
			user_group.ID AS ID_group,
			user_group.name AS group_name
		FROM
			`TOM`.`a301_user_rel_group` AS rel
		LEFT JOIN `TOM`.`a301_user` AS user ON
		(
			user.ID_user = rel.ID_user
		)
		LEFT JOIN `TOM`.`a301_user_group` AS user_group ON
		(
			user_group.ID = rel.ID_group
		)
		WHERE
			rel.ID_user = '$ID_user'
		ORDER BY
			user_group.name
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'slave'=>1);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$groups{$db0_line{'group_name'}}{'ID'} = $db0_line{'ID_group'};
		main::_log("group '$db0_line{'ID_group'}' named '$db0_line{'group_name'}' status='$db0_line{'status'}'");
		$groups{$db0_line{'group_name'}}{'status'} = $db0_line{'status'};
	}
	
	$t->close();
	return %groups;
}



sub user_active
{
	my $ID_user=shift;
#	my $t=track TOM::Debug(__PACKAGE__."::user_inactive($ID_user)");
	
	my %sth0=TOM::Database::SQL::execute(qq{
		INSERT INTO TOM.a301_user
			SELECT
				*
			FROM TOM.a301_user_inactive
			WHERE
				ID_user='$ID_user'
			LIMIT 1
	},'quiet'=>1);
	if ($sth0{'rows'})
	{
		main::_log("inserted user '$ID_user' into active table");
		TOM::Database::SQL::execute(qq{
			DELETE FROM TOM.a301_user_inactive
			WHERE
				ID_user='$ID_user'
			LIMIT 1;
		},'quiet'=>1,'-backend'=>1);
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
#	my $t=track TOM::Debug(__PACKAGE__."::user_inactive($ID_user)");
	
	my %sth0=TOM::Database::SQL::execute(qq{
		REPLACE INTO TOM.a301_user_inactive
			SELECT
				*
			FROM TOM.a301_user
			WHERE
				ID_user='$ID_user'
			LIMIT 1
	},'quiet'=>1);
	if ($sth0{'rows'})
	{
		main::_log("inserted user '$ID_user' into inactive table");
		TOM::Database::SQL::execute(qq{
			DELETE FROM TOM.a301_user
			WHERE
				ID_user='$ID_user'
			LIMIT 1;
		},'quiet'=>1,'-backend'=>1);
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
	my %data;
	
	my $sql=qq{
		SELECT
			*
		FROM
			TOM.a301_user
		WHERE
			ID_user='$ID_user'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1);
	if (%data=$sth0{'sth'}->fetchhash)
	{
		main::_log("user '$ID_user' found in active table");
	}
	else
	{
		main::_log("user '$ID_user' not found in active table, trying inactive");
		my $sql=qq{
			SELECT
				*
			FROM
				TOM.a301_user_inactive
			WHERE
				ID_user='$ID_user'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1);
		if (%data=$sth0{'sth'}->fetchhash)
		{
			main::_log("user found in inactive table");
			main::_log("reactivating user '$data{'ID_user'}' from '$data{'datetime_last_login'}' with '$data{'requests_all'}' requests",3,"a301",2);
			user_active($ID_user);
		}
		else
		{
			main::_log("user '$ID_user' not found in archive table",1);
			return undef;
		}
	}
	
	return %data;
}



=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
