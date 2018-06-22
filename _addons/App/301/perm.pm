#!/bin/perl
package App::301::perm;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;



=head1 NAME

App::301::perm

=head1 DESCRIPTION

Basic permissions storage and management (ACL tables)

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::160::_init|app/"160/_init.pm">

=back

=cut

#use App::301::_init;
use App::160::_init;
use App::020::SQL::functions;

our $debug=0;
our %groups;
our %roles;
our %ACL_roles;
our %functions;

# default role with function
$roles{'login'}{'a301.addon'}=1;

=head2 FUNCTIONS

=cut


sub register
{
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."::register()") if $debug;
	
	if (!$env{'addon'})
	{
		main::_log("App::301::register() addon not defined",1) unless $debug;
		main::_log("addon not defined",1) if $debug;
		$t->close();return undef;
	}
	
	main::_log("App::301::register($env{'addon'})") unless $debug;
	main::_log("addon=$env{'addon'}") if $debug;
	
	if ($env{'functions'})
	{
		foreach (sort keys %{$env{'functions'}})
		{
			main::_log("FNC_$env{'addon'}.$_") if $debug;
			$functions{$env{'addon'}.'.'.$_}=$env{'functions'}->{$_};
		}
	}
	
	if ($env{'roles'})
	{
		foreach my $role(sort keys %{$env{'roles'}})
		{
			main::_log("RL_$env{'addon'}.$role") if $debug;
			if (!$roles{$env{'addon'}.'.'.$role})
			{
				$roles{$env{'addon'}.'.'.$role}={};
			}
			foreach my $fnc(@{$env{'roles'}->{$role}})
			{
				# register function to role
				main::_log("->FNC_$env{'addon'}.$fnc") if $debug;
				$roles{$env{'addon'}.'.'.$role}{$env{'addon'}.'.'.$fnc}=1;
			}
		}
	}
	
	if ($env{'groups'})
	{
		foreach my $group(sort keys %{$env{'groups'}})
		{
			main::_log("group '$group'") if $debug;
			if (!$groups{$group})
			{
				$groups{$group}={};
			}
			
			foreach my $role(keys %{$env{'groups'}->{$group}})
			{
				# register role to groups
				my $perm=$env{'groups'}->{$group}{$role};
				my $perm_;
				
#				if (!$groups{$group}{$env{'addon'}.'.'.$role})
#				{
#					$perm_=$perm;
					$groups{$group}{$env{'addon'}.'.'.$role}=$perm;
#				}
#				else
#				{
					# setup the highest permissions
#					main::_log("exists");
#					my @perms=split('',$perm,3);
#					my @perms_=split('',$env{groups}{$env{'addon'}.'.'.$role},3);
#				}
				
				main::_log("->RL_$env{'addon'}.$role '$perm'") if $debug;
#				$roles{$env{'addon'}.'.'.$role}{$env{'addon'}.'.'.$_}=1;
			}
			
		}
	}
	
	
	if ($env{'ACL_roles'})
	{
		foreach my $ACL_role(sort keys %{$env{'ACL_roles'}})
		{
			main::_log("ACL_role '$ACL_role'") if $debug;
			if (!$ACL_roles{$ACL_role})
			{
				$ACL_roles{$ACL_role}={};
			}
			
			foreach my $role(keys %{$env{'ACL_roles'}->{$ACL_role}})
			{
				# register role to ACL_roles
				my $perm=$env{'ACL_roles'}->{$ACL_role}{$role};
				my $perm_;
				
				$ACL_roles{$ACL_role}{$env{'addon'}.'.'.$role}=$perm;
				
				main::_log("->RL_$env{'addon'}.$role '$perm'") if $debug;
			}
			
		}
	}
	
	
	$t->close() if $debug;
	return 1;
};


=head2 get_roles()

Get list of roles with permissions of user, or group
This is not list of roles setup on entity!

 my %roles=App::301::perm::get_roles(
   'ID_user' => $main::USRM{'ID_user'},
   'ID_group' => '*',
   'enhanced' => 1,
 );

=cut

sub get_roles
{
	my %env=@_;
	my %roles;
	
	my $t=track TOM::Debug(__PACKAGE__."::get_roles()");
	
	main::_log("ID_user='$env{'ID_user'}' ID_group='$env{'ID_group'}'");
	
	my $status="'Y','L'";
	if (!$env{'ID_user'})
	{
		$status="'Y','L','N'";
	}
	
	my %user;
	if ($env{'ID_user'})
	{
		if (not $env{'ID_user'}=~/^[a-zA-Z0-9]{8}$/)
		{
			$t->close();
			return undef;
		}
		%user=App::301::functions::user_get($env{'ID_user'});
	}
	
	# world group (generic)
	if ($env{'ID_group'} eq "0" || $env{'ID_group'} eq "*")
	{
		main::_log("group 'world' permissions");
		foreach my $role(sort keys %{$App::301::perm::groups{'world'}})
		{
			main::_log("RL_$role '$App::301::perm::groups{'world'}{$role}'");
			$roles{$role}=$App::301::perm::groups{'world'}{$role};
		}
	}
	
	
	# get group(s)
	my %groups;
	if ($env{'ID_group'} && $env{'ID_group'} ne "*" && $env{'ID_group'} ne $env{'ID_user'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::301::db_name`.a301_user_group AS `group`
			WHERE
				`group`.ID_entity = $env{'ID_group'} AND
				`group`.status IN ($status)
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$groups{$env{'ID_group'}}=$db0_line{'name'};
		}
	}
	if ($env{'ID_user'} && $env{'ID_group'} eq "*" && $env{'ID_group'} ne $env{'ID_user'})
	{
		my $sql=qq{
			SELECT
				`group`.*
			FROM
				`$App::301::db_name`.a301_user_rel_group AS rel,
				`$App::301::db_name`.a301_user_group AS `group`
			WHERE
				rel.ID_user='$env{'ID_user'}' AND
				rel.ID_group = `group`.ID_entity AND
				`group`.status IN ($status)
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$groups{$db0_line{'ID_entity'}}=$db0_line{'name'};
		}
	}
	
	# check 'admin' group at first
	foreach (keys %groups)
	{
		if ($groups{$_} eq "admin")
		{
			main::_log("group 'admin' permissions");
			main::_log("RL_unlimited 'rwx'");
			$roles{'unlimited'}='rwx';
			delete $groups{$_};
		}
	}
	
	# check 'editor' group as second
	foreach (keys %groups)
	{
		if ($groups{$_} eq "editor")
		{
			main::_log("group 'editor' permissions");
			my %roles_local;
			foreach my $role(sort keys %{$App::301::perm::groups{'editor'}})
			{
#				my $perm=perm_inc($roles{$role},$App::301::perm::groups{'editor'}{$role});
#				main::_log("RL_$role '$roles{$role}'+'$App::301::perm::groups{'editor'}{$role}'='$perm'");
#				$roles{$role}=$perm;
				main::_log(" RL_$role '$App::301::perm::groups{'editor'}{$role}'");
				$roles_local{$role}=$App::301::perm::groups{'editor'}{$role};
			}
			my $sql=qq{
				SELECT *
				FROM `$App::301::db_name`.a301_user_group
				WHERE ID_entity=$_ AND status IN ($status)
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
			if (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				main::_log("group 'editor' permissions overrides");
				foreach my $role(split('\n',$db0_line{'perm_roles_override'}))
				{
					my @role_def=split(':',$role,2);
					my $perm=perm_sum($roles_local{$role_def[0]},$role_def[1]);
					main::_log(" RL_$role_def[0] '$roles_local{$role_def[0]}'*'$role_def[1]'='$perm'");
					$roles_local{$role_def[0]}=$perm;
				}
			}
			
			main::_log("group 'editor' overrides");
			foreach my $role(sort keys %roles_local)
			{
				my $perm=perm_sum($roles{$role},$roles_local{$role});
				main::_log(" RL_$role '$roles{$role}'*'$roles_local{$role}'='$perm'");
				$roles{$role}=$perm;
			}
			
			main::_log(" RL_login 'r  '");
			$roles{'login'}='r  ';
			
			delete $groups{$_};
		}
	}
	
	# check other groups
	foreach my $group(sort keys %groups)
	{
		my $sql=qq{
			SELECT *
			FROM `$App::301::db_name`.a301_user_group
			WHERE ID_entity=$group AND status IN ($status)
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("group '$db0_line{'name'}' overrides");
			foreach my $role(split('\n',$db0_line{'perm_roles_override'}))
			{
				my @role_def=split(':',$role,2);
				my $perm=perm_sum($roles{$role_def[0]},$role_def[1]);
				#$perm=~s| |-|g;
				main::_log("RL_$role_def[0] '$roles{$role_def[0]}'*'$role_def[1]'='$perm'");
				$roles{$role_def[0]}=$perm;
			}
		}
	}
	
	
	# user overrides
	if ($env{'ID_group'} eq $env{'ID_user'} || $env{'ID_group'} eq "*" || ($env{'ID_user'} && !$env{'ID_group'}))
	{
		main::_log("user overrides");
		foreach my $role(split('\n',$user{'perm_roles_override'}))
		{
			my @role_def=split(':',$role,2);$role_def[1]=~tr/rwx\-/RWX_/;
			my $perm=perm_sum($roles{$role_def[0]},$role_def[1]);
			my @perm_=split('',$perm);
			$perm_[0]=' ' unless $perm_[0];
			$perm_[1]=' ' unless $perm_[1];
			$perm_[2]=' ' unless $perm_[2];
			$perm=join '',@perm_;
			main::_log("RL_$role_def[0] '$roles{$role_def[0]}'*'$role_def[1]'='$perm'");
			$roles{$role_def[0]}=$perm;
		}
	}
	
	if ($roles{'unlimited'})
	{
		%roles=('unlimited'=>'rwx','login'=>'r  ');
	}
	
	main::_log("send to output:");
	foreach (sort keys %roles)
	{
		my @perm=split('',$roles{$_});
#		$perm[0]='-' unless $perm[0];
#		$perm[1]='-' unless $perm[1];
#		$perm[2]='-' unless $perm[2];
		$perm[0]=' ' if (!$perm[0] || $perm[0] eq ' ');
		$perm[1]=' ' if (!$perm[1] || $perm[1] eq ' ');
		$perm[2]=' ' if (!$perm[2] || $perm[2] eq ' ');
		$roles{$_}=join '',@perm;
		main::_log(" RL_$_ '$roles{$_}'");
	}
	
	$t->close();
	return %roles;
}


=head2 _get_functions_from_roles

Converts %roles into %functions

 my %functions 

=cut

sub _get_functions_from_roles
{
	my %roles=@_;
	my %functions;
	my $t=track TOM::Debug(__PACKAGE__."::get_functions_from_roles()");
	
	foreach my $role(keys %roles)
	{
#		main::_log("RL_$role=$roles{$role}");
		foreach my $fnc(keys %{$App::301::perm::roles{$role}})
		{
#			main::_log(" FNC_$fnc");
			if ($functions{$fnc})
			{
				$functions{$fnc}=perm_sum($functions{$fnc},$roles{$role});
			}
			else
			{
				$functions{$fnc}=$roles{$role};
			}
#			main::_log(" FNC_$fnc=$functions{$fnc}");
#			my $perm=perm_sum($roles{$role_def[0]},$role_def[1]);
		}
	}
	
	foreach (sort keys %functions)
	{
		main::_log("FNC_$_=$functions{$_}");
	}
	
	$t->close();
	return %functions;
}



=head2 get_ACL_roles

Get list of roles from ACL and ACL_role

Return list of roles and permissions computed from users and user_groups
(organizations has only informal, not executive character in ACL)

 my (%roles,$perm)=App::301::perm::get_ACL_roles(
   'r_prefix' => 
	'r_table' => 
	'r_ID_entity' => 
 )

=cut

sub get_ACL_roles
{
	my %env=@_;
	my %roles;
	my $permstrip;
	
	my $t=track TOM::Debug(__PACKAGE__."::get_ACL_roles()");
	
	main::_log("ID_user='$env{'ID_user'}' ID_group='$env{'ID_group'}' r_prefix='$env{'r_prefix'}' r_table='$env{'r_table'}' r_ID_entity='$env{'r_ID_entity'}'");
	
	# get full roles
	foreach my $role(sort keys %App::301::perm::ACL_roles)
	{
#		next unless $role=~/^$env{'r_prefix'}\./;
		
#		print "role=$role\n";
		
#		foreach (keys %{$App::301::perm::ACL_roles{$role}})
#		{
#			print "a $_\n";
#		}
		
#		$roles{$role}=$App::301::perm::roles{$role}{'R'};
#		print "$role=$roles{$role}\n";
	}
	
	# get full ACL from this entity and filter it after
	my @ACL=get_ACL(
		'r_prefix' => $env{'r_prefix'},
		'r_table' => $env{'r_table'},
		'r_ID_entity' => $env{'r_ID_entity'},
	);
	
	foreach my $ACL_item(@ACL)
	{
		if (($env{'ID_user'} && !$ACL_item->{'folder'} && $ACL_item->{'ID'} eq $env{'ID_user'}) ||
		($env{'ID_group'} && $ACL_item->{'folder'} && $ACL_item->{'ID'} eq $env{'ID_group'}))
		{
			main::_log("override by ACL_role roles");
			my %my_roles;
			foreach my $ACL_role(split(',',$ACL_item->{'roles'}))
			{
				main::_log("ACL_role '$ACL_role'");
				foreach my $role(keys %{$App::301::perm::ACL_roles{$ACL_role}})
				{
					my $perm=perm_inc($my_roles{$role},$App::301::perm::ACL_roles{$ACL_role}{$role});
					main::_log(" RL_$role '$my_roles{$role}'+'$App::301::perm::ACL_roles{$ACL_role}{$role}'='$perm'");
					$my_roles{$role}=$perm;
				}
			}
			main::_log("override by ACL_role roles (apply)");
			foreach my $role(keys %my_roles)
			{
				my $perm=perm_sum($roles{$role},$my_roles{$role});
				main::_log(" RL_$role '$roles{$role}'*'$my_roles{$role}'='$perm'");
				$roles{$role}=$perm;
			}
			
			main::_log("override by group/user override def");
			foreach my $role(split('\n',$ACL_item->{'override'}))
			{
				my @role_def=split(':',$role,2);$role_def[1]=~tr/rwx\-/RWX_/;
				my $perm=perm_sum($roles{$role_def[0]},$role_def[1]);
				main::_log(" RL_$role_def[0] '$roles{$role_def[0]}'*'$role_def[1]'='$perm'");
				$roles{$role_def[0]}=$perm;
			}
			
			# strip
			main::_log("strip by '$ACL_item->{'perm_R'}$ACL_item->{'perm_W'}$ACL_item->{'perm_X'}'");
			$permstrip=$ACL_item->{'perm_R'}.$ACL_item->{'perm_W'}.$ACL_item->{'perm_X'};
#			$permstrip=~tr/RWXrwx_/      -/;
#			main::_log("strip string '$permstrip'");
#			foreach my $role(keys %roles)
#			{
#				my $perm=perm_sum($roles{$role},$permstrip);
#				main::_log(" RL_$role '$roles{$role}'*'$permstrip'='$perm'");
#				$roles{$role}=$perm;
#			}
			
			last;
		}
	}
	
#	main::_log("permstrip=$permstrip");
	$t->close();
	return ({%roles},$permstrip);
}




=head2 get_entity_roles()

Get list of roles in one entity for user and groups

Gets everyone group listen in ACL and where the present use is contained - for example:
world - 'r  '
editor - 'rwx'
another - 'r--'
The output are roles with 'r  ' privileges from 'world' group, roles from editor with 'rwx' privileges, etc...
All privileges are in output stripped by optimistic permissions from all groups 'r  '+'rwx'+'r--' = 'rwx',
for example 'r  '+'r--'+'-w-' = 'rw-'

After this gets roles from user if are present in this ACL list. Defined permissions overrides group permissions.
for example 'rw-'+'rwx'='rwx'. Warning! - only defined roles in user ACL list definition overrides other roles. 

=cut

sub get_entity_roles
{
	my %env=@_;
	my %roles;
	my $permstrip;
	
	my $t=track TOM::Debug(__PACKAGE__."::get_entity_roles()");
	
	main::_log("r_prefix='$env{'r_prefix'}' r_table='$env{'r_table'}' r_prefix='$env{'r_ID_entity'}'");
	
	my @ACL=get_ACL
	(
		'r_prefix' => $env{'r_prefix'},
		'r_table' => $env{'r_table'},
		'r_ID_entity' => $env{'r_ID_entity'}
	);

	my %grp;
	foreach (@{$env{'groups'}}){$grp{$_}++;}
	
	main::_log("get permissions from groups");
	my %groups_roles;
	my %strip_perms;
	foreach my $ACL_item(@ACL)
	{
		if ($ACL_item->{'folder'} && $grp{$ACL_item->{'ID'}}) # this is group
		{
			main::_log("User in this group '$ACL_item->{'ID'}'");
			
			# get basic group roles
			main::_log("load basic group roles");
			my %local_roles=get_roles(
				'ID_group' => "$ACL_item->{'ID'}"
			);
			
			# override it byt ACL_roles
			main::_log("override by ACL_role roles");
			my %my_roles;
			foreach my $ACL_role(split(',',$ACL_item->{'roles'}))
			{
				main::_log("ACL_role '$ACL_role'");
				foreach my $role(keys %{$App::301::perm::ACL_roles{$ACL_role}})
				{
					my $perm=perm_inc($my_roles{$role},$App::301::perm::ACL_roles{$ACL_role}{$role});
					main::_log(" RL_$role '$my_roles{$role}'+'$App::301::perm::ACL_roles{$ACL_role}{$role}'='$perm'");
					$my_roles{$role}=$perm;
				}
			}
			main::_log("override by ACL_role roles (apply)");
			foreach my $role(keys %my_roles)
			{
				my $perm=perm_sum($local_roles{$role},$my_roles{$role});
				main::_log(" RL_$role '$local_roles{$role}'*'$my_roles{$role}'='$perm'");
				$local_roles{$role}=$perm;
			}
			
			main::_log("override by group override def");
			foreach my $role(split('\n',$ACL_item->{'override'}))
			{
				my @role_def=split(':',$role,2);$role_def[1]=~tr/rwx\-/RWX_/;
				my $perm=perm_sum($local_roles{$role_def[0]},$role_def[1]);
				main::_log(" RL_$role_def[0] '$local_roles{$role_def[0]}'*'$role_def[1]'='$perm'");
				$local_roles{$role_def[0]}=$perm;
			}
			
			# strip (optimistic)
			main::_log("strip by '$ACL_item->{'perm_R'}$ACL_item->{'perm_W'}$ACL_item->{'perm_X'}'");
			my $permstrip=$ACL_item->{'perm_R'}.$ACL_item->{'perm_W'}.$ACL_item->{'perm_X'};
			$strip_perms{'perm_R'}=$ACL_item->{'perm_R'} if $ACL_item->{'perm_R'} ne ' ';
			$strip_perms{'perm_W'}=$ACL_item->{'perm_W'} if $ACL_item->{'perm_W'} ne ' ';
			$strip_perms{'perm_X'}=$ACL_item->{'perm_X'} if $ACL_item->{'perm_X'} ne ' ';
			$permstrip=~tr/RWXrwx_/      -/;
			main::_log("strip string '$permstrip'");
			foreach my $role(keys %local_roles)
			{
				my $perm=perm_sum($local_roles{$role},$permstrip);
				main::_log(" RL_$role '$local_roles{$role}'*'$permstrip'='$perm'");
				$local_roles{$role}=$perm;
			}
			
			
			# compare %local_roles to %groups_roles
			main::_log("group '$ACL_item->{'ID'}' roles (apply)");
			foreach my $role(keys %local_roles)
			{
				my $perm=perm_inc($groups_roles{$role},$local_roles{$role});
				main::_log(" RL_$role '$groups_roles{$role}'+'$local_roles{$role}'='$perm'");
				$groups_roles{$role}=$perm;
			}
			
			
		}
		
		
		
	}
	
	
	my %user_roles;
	foreach my $ACL_item(@ACL)
	{
		if (!$ACL_item->{'folder'} && $ACL_item->{'ID'} eq $env{'ID_user'}) # this is group
		{
			main::_log("get permissions from user ID=$ACL_item->{'ID'}, roles=$ACL_item->{'roles'}");
			
			# get basic user roles (is okay to load these roles to override? - no)
#			main::_log("load basic user roles");
#			%user_roles=get_roles(
#				'ID_user' => "$ACL_item->{'ID'}",
#			);
			
			# override it by ACL_roles
			main::_log("override by ACL_role roles");
			foreach my $ACL_role(split(',',$ACL_item->{'roles'}))
			{
				main::_log("ACL_role '$ACL_role'");
				foreach my $role(keys %{$App::301::perm::ACL_roles{$ACL_role}})
				{
					my $perm=perm_sum($user_roles{$role},$App::301::perm::ACL_roles{$ACL_role}{$role});
					main::_log(" RL_$role '$user_roles{$role}'*'$App::301::perm::ACL_roles{$ACL_role}{$role}'='$perm'");
					$user_roles{$role}=$perm;
				}
			}
			
			main::_log("override by user override def");
			foreach my $role(split('\n',$ACL_item->{'override'}))
			{
				my @role_def=split(':',$role,2);$role_def[1]=~tr/rwx\-/RWX_/;
				my $perm=perm_sum($user_roles{$role_def[0]},$role_def[1]);
				main::_log(" RL_$role_def[0] '$user_roles{$role_def[0]}'*'$role_def[1]'='$perm'");
				$user_roles{$role_def[0]}=$perm;
			}
			
			# strip (pesimistic - override)
			main::_log("strip by '$ACL_item->{'perm_R'}$ACL_item->{'perm_W'}$ACL_item->{'perm_X'}'");
			my $permstrip=$ACL_item->{'perm_R'}.$ACL_item->{'perm_W'}.$ACL_item->{'perm_X'};
			$strip_perms{'perm_R'}=$ACL_item->{'perm_R'} if $ACL_item->{'perm_R'} ne ' ';
			$strip_perms{'perm_W'}=$ACL_item->{'perm_W'} if $ACL_item->{'perm_W'} ne ' ';
			$strip_perms{'perm_X'}=$ACL_item->{'perm_X'} if $ACL_item->{'perm_X'} ne ' ';
			$permstrip=~tr/RWXrwx_/      -/;
			main::_log("strip string '$permstrip'");
			foreach my $role(keys %user_roles)
			{
				my $perm=perm_sum($user_roles{$role},$permstrip);
				main::_log(" RL_$role '$user_roles{$role}'*'$permstrip'='$perm'");
				$user_roles{$role}=$perm;
			}
			
			main::_log("override group roles by user roles");
			foreach my $role(keys %user_roles)
			{
				my $perm=perm_sum($groups_roles{$role},$user_roles{$role});
				main::_log(" RL_$role '$groups_roles{$role}'*'$user_roles{$role}'='$perm'");
				$groups_roles{$role}=$perm;
			}
			
		}
	}
	
	# strip
	my $permstrip=$strip_perms{'perm_R'}.$strip_perms{'perm_W'}.$strip_perms{'perm_X'};
	$permstrip=~tr/RWXrwx_/      -/;
	main::_log("strip all by '$strip_perms{'perm_R'}$strip_perms{'perm_W'}$strip_perms{'perm_X'}'");
	main::_log("strip string '$permstrip'");
	foreach my $role(sort keys %groups_roles)
	{
		my $perm=perm_sum($groups_roles{$role},$permstrip);
		main::_log(" RL_$role '$groups_roles{$role}'*'$permstrip'='$perm'");
		$groups_roles{$role}=$perm;
	}
	
	main::_log("output RL (filtered to prefix '$env{'r_prefix'}\.')");
	foreach my $role(sort keys %groups_roles)
	{
		delete $groups_roles{$role} unless $role=~/^$env{'r_prefix'}\./;
		next unless $role=~/^$env{'r_prefix'}\./;
		main::_log(" RL_$role '$groups_roles{$role}'");
		$roles{$role}=$groups_roles{$role};
	}
	
	$t->close();
#	return $permstrip, %roles;
	return ({%roles},$permstrip);
}



=head2 get_entity_sum_roles

Get list of roles in entity and depends for user

=cut

sub get_entity_sum_roles
{
	my %env=@_;
	my %roles;
	
	my $t=track TOM::Debug(__PACKAGE__."::get_entity_sum_roles()");
	
	main::_log("ID_user='$env{'ID_user'}' r_prefix='$env{'r_prefix'}' r_table='$env{'r_table'}' r_prefix='$env{'r_ID_entity'}'");
	
	# polopatisticky postup
	# - 
	#
	# 
	#
	#
	#
	#
	#
	#
	#
	
	# get ID_user global roles (defined by groups and ID_user)
	my %roles_global=get_roles(
		'ID_user'=>$env{'ID_user'},
		'ID_group'=>'*'
	);
	
	my @groups=(0);
	my %grp=App::301::functions::user_groups($env{'ID_user'});
	foreach (keys %grp){push @groups, $grp{$_}{'ID'};}
	
	# get list of this entity parents
	
	
	# get special roles of this entity
	my ($roles_entity,$permstrip)=get_entity_roles(
		'r_prefix' => $env{'r_prefix'},
		'r_table' => $env{'r_table'},
		'r_ID_entity' => $env{'r_ID_entity'},
		'ID_user' => $env{'ID_user'},
		'groups' => [@groups]
	);
	
	# and combine this all :)
	my %roles_output;
	foreach (keys %roles_global)
	{
		$roles_output{$_}=$roles_global{$_};
		$roles_output{$_}=~tr/RWXrwx_/rwxrwx-/;
		main::_log("RL_$_ '$roles_output{$_}'");
	}
	
	foreach (keys %{$roles_entity})
	{
		$roles_entity->{$_}=~tr/RWXrwx_/rwx   -/;
		my $output=perm_sum($roles_output{$_},$roles_entity->{$_});
		$output='rwx' if $roles_output{'unlimited'};
		main::_log("RL_$_ '$roles_output{$_}'+'$roles_entity->{$_}'='$output'");
		$roles_output{$_}=$output;
	}
	
	$t->close();
	return %roles_output;
}



=head2 get_owner()

Read owner from entity, users external function in format App::aXX::a301::get_owner() when defined,
otherwise own blind function (reads posix_owner from table).

 my $owner=App::301::perm::get_owner(
  'r_prefix' =>
  'r_table' =>
  'r_ID_entity' =>
 );

=cut

sub get_owner
{
	my $t=track TOM::Debug(__PACKAGE__."::get_owner()") if $debug;
	my %env=@_;
	my $owner;
	
	# at first check if this addon is available
	my $r_prefix=$env{'r_prefix'};
		$r_prefix=~s|^a|App::|;
		$r_prefix=~s|^e|Ext::|;
	if (not defined $r_prefix->VERSION)
	{
		eval "use $r_prefix".'::a301;';
		main::_log("err:$@",1) if $@;
	}
	
	# check if a301 enhancement of this application is available
	my $pckg=$r_prefix."::a301";
	if (defined $pckg->VERSION)
	{
		main::_log("trying get_owner() from package '$pckg'") if $debug;
		$owner=$pckg->get_owner(
			'r_table' => $env{'r_table'},
			'r_ID_entity' => $env{'r_ID_entity'}
		);
		main::_log("owner='$owner'") if $debug;
		$t->close() if $debug;
		return $owner;
	}
	else
	{
		main::_log("blind get_owner()") if $debug;
		my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'});
		
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$db_name`.$env{'r_prefix'}_$env{'r_table'}
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if ($sth0{'rows'})
		{
			my %db0_line=$sth0{'sth'}->fetchhash();
			$owner=$db0_line{'posix_owner'};
		}
	}
	
	main::_log("owner='$owner'") if $debug;
	$t->close() if $debug;
	return $owner;
};


sub set_owner
{
	my $t=track TOM::Debug(__PACKAGE__."::set_owner()");
	my %env=@_;
	
	# at first check if this addon is available
	my $r_prefix=$env{'r_prefix'};
		$r_prefix=~s|^a|App::|;
		$r_prefix=~s|^e|Ext::|;
	if (not defined $r_prefix->VERSION)
	{
		eval "use $r_prefix".'::a301;';
		main::_log("err:$@",1) if $@;
	}
	
	# check if a301 enhancement of this application is available
	my $pckg=$r_prefix."::a301";
	if (defined $pckg->VERSION)
	{
		main::_log("trying set_owner() from package '$pckg'");
		my $out=$pckg->set_owner(
			'r_table' => $env{'r_table'},
			'r_ID_entity' => $env{'r_ID_entity'},
			'posix_owner' => $env{'posix_owner'}
		);
		$t->close();
		return $out;
	}
	else
	{
		$t->close();
		return undef;
	}
	
	$t->close();
	return undef;
};



=head2 get_ACL

Returns ACL (users, user_groups and organizations) from entity

 my @ACL=App::301::perm::get_ACL(
  'r_prefix' =>
  'r_table' =>
  'r_ID_entity' =>
  'role' => # only entities with this role
 );

=cut

sub get_ACL
{
	my $t=track TOM::Debug(__PACKAGE__."::get_ACL()") if $debug;
	my %env=@_;
	my @ACL;
	
	my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	my $world;
	my $sql=qq{
	SELECT
		acl.*,
		grp.name
	FROM
		`$db_name`.a301_ACL_user_group AS acl
	LEFT JOIN `TOM`.a301_user_group AS grp ON
	(
		acl.ID_entity = grp.ID_entity
	)
	WHERE
		acl.r_prefix='$env{'r_prefix'}' AND
		acl.r_table='$env{'r_table'}' AND
		acl.r_ID_entity='$env{'r_ID_entity'}'
	ORDER BY
		acl.ID_entity ASC
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my %item;
		
		if ($db0_line{'ID_entity'} ne "0" && !$world) # world override not available
		{
			$world=1;
			my %item;
			main::_log("->{world} 'r  '") if $debug;
			$item{'ID'}='0';
			$item{'folder'}='Y';
			$item{'roles'}='';
			$item{'perm_R'}='r';
			$item{'perm_W'}=' ';
			$item{'perm_X'}=' ';
			$item{'status'}='L';
			$item{'name'}='world';
			push @ACL, {%item};
		}
		elsif (!$world)
		{
			$world=1;
			$db0_line{'status'}='L';
			$db0_line{'name'}='world';
		}
		
		$db0_line{'perm_R'}=~tr/YN/R_/;
		$db0_line{'perm_W'}=~tr/YN/W_/;
		$db0_line{'perm_X'}=~tr/YN/X_/;
		
		main::_log("->{user_group} ID='$db0_line{'ID_entity'}' name='$db0_line{'name'}' roles='$db0_line{'roles'}' '$db0_line{'perm_R'}$db0_line{'perm_W'}$db0_line{'perm_X'}'") if $debug;
		$item{'ID'}=$db0_line{'ID_entity'};
		$item{'folder'}='Y';
		$item{'roles'}=$db0_line{'roles'};
			utf8::decode($item{'roles'});
		$item{'perm_R'}=$db0_line{'perm_R'};
		$item{'perm_W'}=$db0_line{'perm_W'};
		$item{'perm_X'}=$db0_line{'perm_X'};
		$item{'status'}=$db0_line{'status'};
		$item{'override'}=$db0_line{'perm_roles_override'};
		$item{'name'}=$db0_line{'name'};
		$item{'name_short'}=$db0_line{'name'};
		
		push @ACL, {%item};
	}
	
	
	if (!$world) # if world in ACL (overriding) is not available
	{
		$world=1;
		my %item;
		main::_log("->{world} 'r  '") if $debug;
		$item{'ID'}='0';
		$item{'folder'}='Y';
		$item{'roles'}='';
		$item{'perm_R'}='r';
		$item{'perm_W'}=' ';
		$item{'perm_X'}=' ';
		$item{'status'}='L';
		$item{'name'}='world';
		$item{'name_short'}='world';
		
		push @ACL, {%item};
	}
	
	
	if ($App::710::db_name) # a710 enabled because db_name is defined
	{
		
		my $sql=qq{
		SELECT
			acl.*,
			org.name,
			org.ID_org,
			org.city
		FROM
			`$db_name`.a301_ACL_org AS acl
		LEFT JOIN `$App::710::db_name`.a710_org AS org ON
		(
			acl.ID_entity = org.ID_entity
		)
		WHERE
			acl.r_prefix='$env{'r_prefix'}' AND
			acl.r_table='$env{'r_table'}' AND
			acl.r_ID_entity='$env{'r_ID_entity'}'
		ORDER BY
			acl.ID_entity ASC
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			my %item;
			
			$db0_line{'perm_R'}=~tr/YN/R_/;
			$db0_line{'perm_W'}=~tr/YN/W_/;
			$db0_line{'perm_X'}=~tr/YN/X_/;
			
			main::_log("->{org} ID='$db0_line{'ID_entity'}' name='$db0_line{'name'}' roles='$db0_line{'roles'}' '$db0_line{'perm_R'}$db0_line{'perm_W'}$db0_line{'perm_X'}'") if $debug;
			$item{'ID'}=$db0_line{'ID_entity'};
			$item{'folder'}='O';
			$item{'roles'}=$db0_line{'roles'};
				utf8::decode($item{'roles'});
			$item{'perm_R'}=$db0_line{'perm_R'};
			$item{'perm_W'}=$db0_line{'perm_W'};
			$item{'perm_X'}=$db0_line{'perm_X'};
			$item{'status'}=$db0_line{'status'};
			$item{'override'}=$db0_line{'perm_roles_override'};
			$item{'name'}=$db0_line{'name'};
			$item{'name_short'}=$db0_line{'name'};
			if ($db0_line{'ID_org'}){$item{'name'}.=" (".$db0_line{'ID_org'}.")";}
			elsif ($db0_line{'city'}){$item{'name'}.=" (".$db0_line{'city'}.")";}
			
			push @ACL, {%item};
		}
		
	}
	
	
   # get owner
   my $owner=App::301::perm::get_owner(
		'r_prefix' => $env{'r_prefix'},
		'r_table' => $env{'r_table'},
		'r_ID_entity' => $env{'r_ID_entity'}
	);
   if ($owner)
	{
		my %item;
		
		my %author=App::301::authors::get_author($owner);
		
		main::_log("->{owner} ID='$owner' name='$author{'login'}' 'rwx'") if $debug;
		$item{'ID'}=$owner;
		$item{'folder'}='';
		$item{'roles'}='owner';
		$item{'perm_R'}='r';
		$item{'perm_W'}='w';
		$item{'perm_X'}='x';
		$item{'status'}='L';
		$item{'name'}=$author{'login'};
		$item{'name_short'}=$author{'login'};
		($item{'name'},$item{'name_short'})=App::301::authors::get_fullname(%author);
		
		push @ACL, {%item};
   }
   
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			`acl`.*,
			`user`.`login` AS `name`,
			`user`.`login`,
			YEAR(`user_profile`.`date_birth`) AS `year_birth`,
			`user_profile`.`firstname`,
			`user_profile`.`surname`
		FROM
			`$db_name`.`a301_ACL_user` AS `acl`
		INNER JOIN
			`TOM`.`a301_user` AS `user` ON
			(
				`acl`.`ID_entity` = `user`.`ID_user`
			)
		LEFT JOIN
			`TOM`.`a301_user_profile` AS `user_profile` ON
			(
				`user`.`ID_user` = `user_profile`.`ID_entity`
			)
		WHERE
					`acl`.`r_prefix` = ?
			AND	`acl`.`r_table` = ?
			AND	`acl`.`r_ID_entity` = ?
		ORDER BY
			`acl`.`ID_entity` ASC
	},'quiet'=>1,'bind'=>[$env{'r_prefix'}, $env{'r_table'}, $env{'r_ID_entity'}]);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my %item;
		
		$db0_line{'perm_R'}=~tr/YN/R_/;
		$db0_line{'perm_W'}=~tr/YN/W_/;
		$db0_line{'perm_X'}=~tr/YN/X_/;
		
		if ($db0_line{'ID_entity'} eq $owner)
		{
			main::_log("->{owner/user} '$db0_line{'perm_R'}$db0_line{'perm_W'}$db0_line{'perm_X'}'") if $debug;
			$ACL[0]{'perm_R'}=$db0_line{'perm_R'};
			$ACL[0]{'perm_W'}=$db0_line{'perm_W'};
			$ACL[0]{'perm_X'}=$db0_line{'perm_X'};
			next;
		}
		
		main::_log("->{user} ID='$db0_line{'ID_entity'}' name='$db0_line{'login'}' roles='$db0_line{'roles'}' '$db0_line{'perm_R'}$db0_line{'perm_W'}$db0_line{'perm_X'}'") if $debug;
		$item{'ID'}=$db0_line{'ID_entity'};
		$item{'folder'}='';
		$item{'roles'}=$db0_line{'roles'};
			utf8::decode($item{'roles'});
		$item{'perm_R'}=$db0_line{'perm_R'};
		$item{'perm_W'}=$db0_line{'perm_W'};
		$item{'perm_X'}=$db0_line{'perm_X'};
		$item{'perm_1'}=$db0_line{'perm_1'};
		$item{'perm_2'}=$db0_line{'perm_2'};
		$item{'perm_3'}=$db0_line{'perm_3'};
		$item{'perm_4'}=$db0_line{'perm_4'};
		$item{'status'}=$db0_line{'status'};
		$item{'override'}=$db0_line{'perm_roles_override'};
		$item{'name'}=$db0_line{'login'};
		$item{'name_short'}=$db0_line{'login'};
		($item{'name'},$item{'name_short'})=App::301::authors::get_fullname(%db0_line);
		
		push @ACL, {%item};
	}
	
	if ($env{'role'})
	{
		my @ACL_;
		foreach my $acl_entity (@ACL)
		{
#			main::_log("$_");
			my $has_role;
			foreach my $role (split(',',$acl_entity->{'roles'}))
			{
				$has_role=1 if $role eq $env{'role'};
			}
			push @ACL_,$acl_entity if $has_role;
		}
		@ACL=@ACL_;
#		foreach (@ACL)
#		{
#			main::_log("ID=$_->{'ID'}");
#		}
	}
	
	$t->close() if $debug;
	return @ACL;
}



=head2 set_ACL

Sets ACL (users, user_groups and organizations) for entity

 App::301::perm::set_ACL(
  'r_prefix' =>
  'r_table' =>
  'r_ID_entity' =>
  'role' => # set this role to all entities
  'ACL' => (
    {'ID' => 'xxxxxx', folder => ''}, # user
    {'ID' => 2, 'folder' => 'Y'}, # group
    {'ID' => 3, 'folder' => 'O'}, # org
  )
 );

=cut

sub set_ACL
{
	my $t=track TOM::Debug(__PACKAGE__."::set_ACL()");
	my %env=@_;
	my @ACL_set=@{$env{'ACL'}};
	
	my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	my @ACL_orig=App::301::perm::get_ACL('r_prefix' => $env{'r_prefix'},'r_table' => $env{'r_table'},'r_ID_entity' => $env{'r_ID_entity'});
	my @ACL_new=App::301::perm::get_ACL('r_prefix' => $env{'r_prefix'},'r_table' => $env{'r_table'},'r_ID_entity' => $env{'r_ID_entity'});
	
	foreach (@ACL_orig)
	{
		main::_log("ID='$_->{'ID'}' folder='$_->{'folder'}' roles='$_->{'roles'}'");
	}
	
	# reset role from ACL
	foreach (@ACL_new)
	{
#		main::_log("1) ID='$_->{'ID'}' $_->{'roles'}");
		my $has_role;
		# exclude role from roles only when entity not in ACL_set
		foreach my $acl_entity (@ACL_set)
		{
#			main::_log("11) ID='$acl_entity->{'ID'}' $acl_entity->{'roles'}");
			if ($acl_entity->{'ID'} eq $_->{'ID'} && $acl_entity->{'ID'} eq $_->{'ID'})
			{
#				main::_log("found in ACL_set");
				$has_role=1;last;
			}
		}
		_role_exclude($_->{'roles'}, $env{'role'}) unless $has_role;
#		main::_log("1) ID='$_->{'ID'}' $_->{'roles'}");
	}
	
	
	# add role from ACL
	foreach my $acl_entity (@ACL_set)
	{
		my $entity_found;
		foreach (@ACL_new)
		{
			if ($acl_entity->{'ID'} eq $_->{'ID'} && $acl_entity->{'ID'} eq $_->{'ID'})
			{
				_role_add($_->{'roles'}, $env{'role'});
				$entity_found=1;
				last;
			}
		}
		# add entity
		if (!$entity_found)
		{
			push @ACL_new,{'ID'=>$acl_entity->{'ID'},'folder'=>$acl_entity->{'folder'},'roles'=>$env{'role'}};
		}
	}
	
	
	# compare
	my $i=0;
	foreach (@ACL_new)
	{
		if ($ACL_orig[$i]->{'roles'} ne $_->{'roles'})
		{
			main::_log("changed ID='$_->{'ID'}' folder='$_->{'folder'}' roles='$ACL_orig[$i]->{'roles'}'->'$_->{'roles'}'");
			if ($_->{'folder'} eq "Y")
			{
			}
			else
			{
				App::301::perm::ACL_user_update(
					'r_prefix' => $env{'r_prefix'},'r_table' => $env{'r_table'},'r_ID_entity' => $env{'r_ID_entity'},
					'ID' => $_->{'ID'},
					'roles' => $_->{'roles'}
				);
			}
		}
		$i++;
	}
	
	
	foreach (@ACL_new)
	{
#		main::_log("ID='$_->{'ID'}' folder='$_->{'folder'}' roles='$_->{'roles'}'");
	}
	
	$t->close();
	return @ACL_new;
#	return @ACL;
}


sub _role_exclude
{
	my $roles_new;
	foreach (split(',',$_[0]))
	{
		next if $_ eq $_[1];
		$roles_new.=",".$_;
	}
	$roles_new=~s|^,||;
	$_[0]=$roles_new;
}

sub _role_add
{
	my $roles_new;
	my $role_has;
	foreach (split(',',$_[0]))
	{
		$role_has=1 if $_ eq $_[1];
		$roles_new.=",".$_;
	}
	$roles_new.=",".$_[1] unless $role_has;
	$roles_new=~s|^,||;
	$_[0]=$roles_new;
}

=head2 ACL_org_update

Update or add organization (a710_org) into entity ACL

 App::301::perm::ACL_org_update(
   'ID' => # ref a710_org.ID_entity
	'r_prefix' => 
	'r_table' => 
	'r_ID_entity' => 
 )

=cut

sub ACL_org_update
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_org_update()");
	my %env=@_;
	
   my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	if ($env{'roles'})
	{
		$env{'roles'}=~s|owner||g;
		my @roles=split('[,;]',$env{'roles'});
		$env{'roles'}=join ",", @roles;
		1 while ($env{'roles'}=~s|,,|,|g);
		$env{'roles'}=~s|^,||;
		$env{'roles'}=~s|,$||;
	}
	
	my $sql=qq{
		SELECT
			*
		FROM
			`$db_name`.a301_ACL_org
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		my %columns;
		
		$columns{'perm_R'} = "'".$env{'perm_R'}."'"
			if ($env{'perm_R'} && $env{'perm_R'} ne $db0_line{'perm_R'});
		$columns{'perm_W'} = "'".$env{'perm_W'}."'"
			if ($env{'perm_W'} && $env{'perm_W'} ne $db0_line{'perm_W'});
		$columns{'perm_X'} = "'".$env{'perm_X'}."'"
			if ($env{'perm_X'} && $env{'perm_X'} ne $db0_line{'perm_X'});
		$columns{'roles'} = "'".$env{'roles'}."'"
			if (exists $env{'roles'} && $env{'roles'} ne $db0_line{'roles'});
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => 'main',
				'db_name' => $db_name,
				'tb_name' => 'a301_ACL_org',
				'columns' =>
				{
					%columns,
				},
				'-journalize' => 1,
				'-posix' => 1,
			);
		}
		$t->close();
		return 1;
	}
	else
	{
		App::020::SQL::functions::new(
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_org',
			'columns' =>
			{
				'ID_entity' => "'".$env{'ID'}."'",
				'r_prefix' => "'".$env{'r_prefix'}."'",
				'r_table' => "'".$env{'r_table'}."'",
				'r_ID_entity' => "'".$env{'r_ID_entity'}."'",
				'perm_R' => "'Y'",
				'perm_W' => "'Y'",
				'perm_X' => "'Y'",
				'roles' => "'".$env{'roles'}."'"
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}



=head2 ACL_org_remove

Remove organization (a710_org) from entity ACL

 App::301::perm::ACL_org_remove(
   'ID' => # ref a710_org.ID_entity
	'r_prefix' => 
	'r_table' => 
	'r_ID_entity' => 
 )

=cut

sub ACL_org_remove
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_org_remove()");
	my %env=@_;
	
   my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_org
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		App::020::SQL::functions::delete(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_org',
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}



sub ACL_user_group_update
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_user_group_update()");
	my %env=@_;
	
   my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	if ($env{'roles'})
	{
		$env{'roles'}=~s|owner||g;
		my @roles=split('[,;]',$env{'roles'});
		$env{'roles'}=join ",", @roles;
		1 while ($env{'roles'}=~s|,,|,|g);
		$env{'roles'}=~s|^,||;
		$env{'roles'}=~s|,$||;
	}
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_user_group
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		my %columns;
		$columns{'perm_R'} = "'".$env{'perm_R'}."'" if $env{'perm_R'};
		$columns{'perm_W'} = "'".$env{'perm_W'}."'" if $env{'perm_W'};
		$columns{'perm_X'} = "'".$env{'perm_X'}."'" if $env{'perm_X'};
		$columns{'roles'} = "'".$env{'roles'}."'" if $env{'roles'};
		App::020::SQL::functions::update(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user_group',
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	else
	{
		my %columns;
		$columns{'perm_R'} = "'".$env{'perm_R'}."'" if $env{'perm_R'};
		$columns{'perm_W'} = "'".$env{'perm_W'}."'" if $env{'perm_W'};
		$columns{'perm_X'} = "'".$env{'perm_X'}."'" if $env{'perm_X'};
		App::020::SQL::functions::new(
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user_group',
			'columns' =>
			{
				'ID_entity' => "'".$env{'ID'}."'",
				'r_prefix' => "'".$env{'r_prefix'}."'",
				'r_table' => "'".$env{'r_table'}."'",
				'r_ID_entity' => "'".$env{'r_ID_entity'}."'",
				'roles' => "'".$env{'roles'}."'",
				%columns
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}


sub ACL_user_group_remove
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_user_group_remove()");
	my %env=@_;
	
   my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_user_group
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		App::020::SQL::functions::delete(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user_group',
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}


sub ACL_user_update
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_user_update()");
	my %env=@_;
	
   my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	if ($env{'roles'})
	{
		$env{'roles'}=~s|owner||g;
		my @roles=split('[,;]',$env{'roles'});
		$env{'roles'}=join ",", @roles;
		1 while ($env{'roles'}=~s|,,|,|g);
		$env{'roles'}=~s|^,||;
		$env{'roles'}=~s|,$||;
	}
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_user
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	my %columns;
	my %data;
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		$data{'perm_R'} = $env{'perm_R'} if $env{'perm_R'};
		$data{'perm_W'} = $env{'perm_W'} if $env{'perm_W'};
		$data{'perm_X'} = $env{'perm_X'} if $env{'perm_X'};
		$data{'perm_1'} = $env{'perm_1'} if $env{'perm_1'};
		$data{'perm_2'} = $env{'perm_2'} if $env{'perm_2'};
		$data{'perm_3'} = $env{'perm_3'} if $env{'perm_3'};
		$data{'perm_4'} = $env{'perm_4'} if $env{'perm_4'};
		$data{'perm_4'} = $env{'perm_4'} if $env{'perm_4'};
		$data{'roles'} = $env{'roles'} if exists $env{'roles'};
		$data{'perm_roles_override'} = $env{'perm_roles_override'} if exists $env{'perm_roles_override'};
		$data{'status'} = $env{'status'} if $env{'status'};
		$data{'note'} = $env{'note'} if $env{'note'};
		App::020::SQL::functions::update(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user',
			'columns' =>
			{
				%columns,
			},
			'data' =>
			{
				%data,
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	else
	{
		$data{'status'} = $env{'status'} if $env{'status'};
		$data{'note'} = $env{'note'} if $env{'note'};
		$data{'roles'} = $env{'roles'} if $env{'roles'};
		$data{'perm_roles_override'} = $env{'perm_roles_override'} if exists $env{'perm_roles_override'};
		
		App::020::SQL::functions::new(
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user',
			'columns' =>
			{
				'datetime_evidence' => "NOW()",
				%columns
			},
			'data' =>
			{
				'ID_entity' => $env{'ID'},
				'r_prefix' => $env{'r_prefix'},
				'r_table' => $env{'r_table'},
				'r_ID_entity' => $env{'r_ID_entity'},
				'perm_R' => "Y",
				'perm_W' => "Y",
				'perm_X' => "Y",
				%data,
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}


sub ACL_user_remove
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_user_remove()");
	my %env=@_;
	
   my $db_name=App::020::SQL::functions::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_user
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		App::020::SQL::functions::delete(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user',
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}



sub perm_inc # optimistic - only accept higher permissions '-w-'+'r-x'='rwx'
{
	my $from=shift;
	my $to=shift;
	my @from_=split('',$from);
	$from_[0]=' ' unless $from_[0];
	$from_[1]=' ' unless $from_[1];
	$from_[2]=' ' unless $from_[2];
	my @to_=split('',$to);
	$to_[0]=' ' unless $to_[0];
	$to_[1]=' ' unless $to_[1];
	$to_[2]=' ' unless $to_[2];
	$to_[0]=$from_[0] if (!$to_[0] || $to_[0] eq '-' || $to_[0] eq '_' || $to_[0] eq ' ');
	$to_[1]=$from_[1] if (!$to_[1] || $to_[1] eq '-' || $to_[0] eq '_' || $to_[1] eq ' ');
	$to_[2]=$from_[2] if (!$to_[2] || $to_[2] eq '-' || $to_[0] eq '_' || $to_[2] eq ' ');
	$to=join '',@to_;
	return $to;
}

sub perm_sum # pesimistic - accept every permission (higher or lower) 'rw-'*' -x'='r-x'
{
	my $from=shift;
	my $to=shift;
	my @from_=split('',$from);
	$from_[0]=' ' unless $from_[0];
	$from_[1]=' ' unless $from_[1];
	$from_[2]=' ' unless $from_[2];
	my @to_=split('',$to);
	$to_[0]=' ' unless $to_[0];
	$to_[1]=' ' unless $to_[1];
	$to_[2]=' ' unless $to_[2];
	$to_[0]=$from_[0] if ($to_[0] eq ' ');
	$to_[1]=$from_[1] if ($to_[1] eq ' ');
	$to_[2]=$from_[2] if ($to_[2] eq ' ');
	$to=join '',@to_;
	return $to;
}



sub _get_permissions_for_category
{
	my %env = @_;

	# If ACLs have already been retrieved, do not do this again

	unless (exists $env{'permissions_hashref'} ->{$env{'ID'}})
	{
		my %roles=App::301::perm::get_entity_sum_roles(
			'ID_user' => $env{'ID_user'},
			'r_prefix' => $env{'prefix'},
			'r_table' => $env{'table'},
			'r_ID_entity' => $env{'ID'}
		);

		$env{'permissions_hashref'} ->{$env{'ID'}} = \%roles;
	}
}


=head2

Gets permissions for a category or an entity, if supported by the application.

Returns a hash reference in form:

$ref = {
	'role' => 'rwx permissions'
	..
}

$rwx_permissions_hashref = App::301::perm::get_permissions_for_entity(

		'ID_entity' => 14,			# id entity or id category
		'prefix' => 'a910',
		'cat_table' => 'product_cat',
		'table' => 'product',			# if not specified, I assume I am a category
		'db_name' => $App::910::db_name,
		'ID_user' => 'kkOb6lS1',
		'target_prefix => 'a501'		# give me roles only for this prefix (optional)
);


=cut


sub get_permissions_for_entity
{
	my $t=track TOM::Debug(__PACKAGE__."::get_permissions_for_entity()") if $debug;
	my %env=@_;

	my $prefix_num = $env{'prefix'}; $prefix_num =~ s/\D//g;

	my $package = 'App::'.$prefix_num.'::a020';

	eval "use $package;";
	main::_log("err:$@",1) if $@;
	
	my $result_rwx_final;

	my %paths;
	# the paths of all categories that this entity is in will be listed here

	my %cat_permissions_cache;
	# for every category, we need to get permissions. the paths, however, typically contain a category more than once
	# so it makes sense for it to be stored. 

	if (defined $package->VERSION)
	{
		# get a list of categories I am in - appplication dependant. if 'table' is specified, I expect
		# I am an entity, not a category, if no 'table' is specified, I am a category and I will just insert myself
		# into the list of categories.

		my @categories_list;

		if ($env{'table'})
		{
			@categories_list = $package->get_categories_for_entity(

				$package, 
				'ID_entity' => $env{'ID_entity'}, 
				'table' => $env{'table'}
			);
		} else
		{
			# I am a category, not an entity, just examine my path

			@categories_list = ( $env{'ID_entity'} );
		}

		# Do this for every category from the categories list.
		foreach my $id_category (@categories_list)
		{
			# Get full path for this category.
	
			my @path_results = App::020::SQL::functions::tree::get_path(
				$id_category, 
				'tb_name' => $env{'prefix'} . '_' . $env{'cat_table'},
				'db_name' => $env{'db_name'}
			);
	
			# Push the path into the array {'categories'} for this category. Also, get partial permissions
			# for every category in the path. (do this only once for every category to reduce the number
			# of iterations.
	
			$paths{$id_category}->{'categories'} = [];
	
			foreach my $path_item (@path_results)
			{
				if ($path_item ->{'status'} ne 'T')
				{
					push( @{$paths{$id_category}->{'categories'}}, $path_item ->{'ID'});
	
					# Get permissions for this category and save them to cat_permissions_cache.
					# (only once for each cat)
	
					_get_permissions_for_category(
						'ID' => $path_item ->{'ID'}, 
						'ID_user' => $env{'ID_user'},
						'prefix' => $env{'prefix'},
						'table' => $env{'cat_table'},
						'permissions_hashref' => \%cat_permissions_cache
					);
					
				} else
				{
					# if a path item is trashed, do not even continue
					last;
				}
			}
	
			# Now $paths{$id_category}->{'categories'} contains an array of categories, which 
			# represents full path.
			# 
			# We will compute the rwx result for this path using the override principle and save
			# it to the variable $result_rwx_for_path.
	
			my $result_rwx_for_path = {};
	
			foreach my $i (@{$paths{$id_category}->{'categories'}})
			{
				foreach my $role (keys %{$cat_permissions_cache{$i}})
				{
					$result_rwx_for_path->{$role} = App::301::perm::perm_sum(
						$result_rwx_for_path->{$role},		# from
						$cat_permissions_cache{$i}->{$role}	# to
					);
				}
			}

			$paths{$id_category}->{'permissions'} = $result_rwx_for_path;
		}
		
		# now, %paths contains a list of categories and their full paths top -> bottom
		# now, unless one of the paths already was 'rwx', we continue to pick the path of least resistance
		
		foreach my $path (keys %paths)
		{
			foreach my $role (keys %{$paths{$path}->{'permissions'}})
			{
				$result_rwx_final->{$role} = App::301::perm::perm_inc(
		
					$result_rwx_final->{$role},			# from
					$paths{$path}->{'permissions'}->{$role}		# to
				);
			}
		}

		if ($debug)
		{
			main::_log('Final permissions for role: '.$_.' = '.$result_rwx_final->{$_}) for keys %{$result_rwx_final};
		}
	}	

	# check if I have the role unlimited and set all roles accordingly
	# (if I have unlimited, set all result role permissions to rwx here)

	if ($result_rwx_final->{'unlimited'})
	{
		my $rwx = $result_rwx_final->{'unlimited'};

		$result_rwx_final = \%App::301::perm::roles;
		$result_rwx_final->{$_} = $rwx for keys %{$result_rwx_final};  
	}

	# if there is a target prefix (we only want to know roles targeted for a particular prefix, 
	# return a list of roles filtered by prefix and the prefix cut.

	if ($env{'target_prefix'})
	{
		my %result_rwx_final_filtered;
		
		my @filtered_keys = grep {/^$env{'target_prefix'}\./} keys (%{$result_rwx_final});
		
		foreach (@filtered_keys)
		{
			my $newkey = $_;
			$newkey =~ s/$env{'target_prefix'}\.//;
			$result_rwx_final_filtered{$newkey} = $result_rwx_final->{$_};
		}

		$t->close() if ($debug);
		return \%result_rwx_final_filtered;
	}

	$t->close() if ($debug);

	return $result_rwx_final;
}

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
