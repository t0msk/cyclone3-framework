#!/bin/perl
package App::301::perm;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;



=head1 NAME

App::301::perm

=head1 DESCRIPTION

Basic permissions storage and management

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=back

=cut

use App::301::_init;

our %groups;
our %roles;
our %functions;


sub register
{
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."::register()");
	
	if (!$env{'addon'})
	{
		main::_log("addon not defined",1);
		$t->close();return undef;
	}
	
	main::_log("addon='$env{'addon'}'");
	
	if ($env{'functions'})
	{
		foreach (sort keys %{$env{'functions'}})
		{
			main::_log("FNC_$env{'addon'}.$_");
			$functions{$env{'addon'}.'.'.$_}=$env{'functions'}->{$_};
		}
	}
	
	if ($env{'roles'})
	{
		foreach my $role(sort keys %{$env{'roles'}})
		{
			main::_log("RL_$env{'addon'}.$role");
			if (!$roles{$env{'addon'}.'.'.$role})
			{
				$roles{$env{'addon'}.'.'.$role}={};
			}
			foreach my $fnc(@{$env{'roles'}->{$role}})
			{
				# register function to role
				main::_log("->FNC_$env{'addon'}.$fnc");
				$roles{$env{'addon'}.'.'.$role}{$env{'addon'}.'.'.$fnc}=1;
			}
		}
	}
	
	if ($env{'groups'})
	{
		foreach my $group(sort keys %{$env{'groups'}})
		{
			main::_log("group '$group'");
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
				
				main::_log("->RL_$env{'addon'}.$role '$perm'");
#				$roles{$env{'addon'}.'.'.$role}{$env{'addon'}.'.'.$_}=1;
			}
			
		}
	}
	
	$t->close();
	return 1;
};



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
				TOM.a301_user_group AS `group`
			WHERE
				`group`.ID = $env{'ID_group'} AND
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
				TOM.a301_user_rel_group AS rel,
				TOM.a301_user_group AS `group`
			WHERE
				rel.ID_user='$env{'ID_user'}' AND
				rel.ID_group = `group`.ID AND
				`group`.status IN ($status)
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$groups{$db0_line{'ID'}}=$db0_line{'name'};
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
				FROM TOM.a301_user_group
				WHERE ID=$_ AND status IN ($status)
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
			foreach my $role(keys %roles_local)
			{
				my $perm=perm_inc($roles{$role},$roles_local{$role});
				main::_log(" RL_$role '$roles{$role}'+'$roles_local{$role}'='$perm'");
				$roles{$role}=$perm;
			}
			
			main::_log(" RL_login '--x'");
			$roles{'login'}='--x';
			
			delete $groups{$_};
		}
	}
	
	# check other groups
	foreach my $group(keys %groups)
	{
		my $sql=qq{
			SELECT *
			FROM TOM.a301_user_group
			WHERE ID=$group AND status IN ($status)
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("group '$db0_line{'name'}' permissions");
			foreach my $role(split('\n',$db0_line{'perm_roles_override'}))
			{
				my @role_def=split(':',$role,2);
				my $perm=perm_inc($roles{$role_def[0]},$role_def[1]);
				main::_log("RL_$role_def[0] '$roles{$role_def[0]}'+'$role_def[1]'='$perm'");
				$roles{$role_def[0]}=$perm;
			}
		}
	}
	
	
	# user overrides
	if ($env{'ID_group'} eq $env{'ID_user'} || $env{'ID_group'} eq "*")
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
		%roles=('unlimited'=>'rwx','login'=>'--x');
	}
	
	main::_log("send to output:");
	foreach (sort keys %roles)
	{
		my @perm=split('',$roles{$_});
		$perm[0]='-' if (!$perm[0] || $perm[0] eq ' ');
		$perm[1]='-' if (!$perm[1] || $perm[1] eq ' ');
		$perm[2]='-' if (!$perm[2] || $perm[2] eq ' ');
		$roles{$_}=join '',@perm;
		main::_log("RL_$_ '$roles{$_}'");
	}
	
	$t->close();
	return %roles;
}



sub perm_inc # only accept higher permissions '-w-'+'r-x'='rwx'
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

sub perm_sum # accept every permission (higher or lower) 'rw-'*' -x'='r-x'
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


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
