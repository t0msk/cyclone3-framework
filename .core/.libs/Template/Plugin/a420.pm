package Template::Plugin::a420;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::420::_init;

our $VERSION = 1.00;
our $DEBUG   = 0 unless defined $DEBUG;
our $AUTOLOAD;

#==============================================================================
#                      -----  CLASS METHODS -----
#==============================================================================

sub new {
	my ($class, $context, $params) = @_;
	my ($key, $val);
	$params ||= { };

	bless { 
		_CONTEXT => $context, 
	}, $class;
}


sub get_static {
	my $self = shift;
	my $env = shift;
	my %static;
	
	my @bind;
	my %sql_env;
	
	# random
	my $sql=qq{
		SELECT
			a420_static.*
		FROM
			$App::420::db_name.a420_static
		LEFT JOIN $App::420::db_name.a420_static_cat ON
		(
			a420_static.ID_category = a420_static_cat.ID
		)
		WHERE};
	my $sql_where;
	
	if (ref($env) eq 'SCALAR' || !ref($env))
	{
		if ($env=~/^\d+$/)
		{
			$sql.=qq{ AND a420_static.ID_entity=?};
			push @bind,$env;
		}
		else
		{
			$sql.=qq{ AND a420_static.name=?};
			push @bind,$env;
		}
	}
	else
	{
		if ($env->{'static_cat.name'})
		{
			$sql.=qq{ AND a420_static_cat.name=?};
			push @bind,$env->{'static_cat.name'};
		}
		if ($env->{'static.name'})
		{
			$sql.=qq{ AND a420_static.name=?};
			push @bind,$env->{'static.name'};
		}
		if ($env->{'static.ID'})
		{
			$sql.=qq{ AND a420_static.ID=?};
			push @bind,$env->{'static.ID'};
		}
		if ($env->{'static.ID_entity'})
		{
			$sql.=qq{ AND a420_static.ID_entity=?};
			push @bind,$env->{'static.ID_entity'};
		}
		if ($env->{'ID'})
		{
			$sql.=qq{ AND a420_static.ID=?};
			push @bind,$env->{'ID'};
		}
		if ($env->{'ID_entity'})
		{
			$sql.=qq{ AND a420_static.ID_entity=?};
			push @bind,$env->{'ID_entity'};
		}
	}
	
	$sql=~s|WHERE AND|WHERE|ms;
	
	$sql.=qq{ AND a420_static.status='Y'};
	$sql.=qq{ AND a420_static.lng=?};push @bind,$self->{'_CONTEXT'}->{'tpl'}->{'ENV'}->{'lng'};
	
#	use Data::Dumper;
#	open(HND,'>'.$tom::P.'/!www/dump.dump');
#	print HND Dumper($self->{'_CONTEXT'}->{'tpl'}->{'ENV'});
#	close (HND);
#	main::_log("lng is ".Dumper($self->{'_CONTEXT'}),3,"debug");
	
#	$sql.=$sql_where;
	$sql.=qq{
		LIMIT 1
	};
	
	my %sql_def=('db_h' => "main",'db_name' => $App::420::db_name,'tb_name' => "a420_static");
	my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[@bind],'log'=>0,'quiet'=>1,%sql_env,
		'-slave' => 1,
		'-cache' => 86400,
		'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%sql_def)
	);
	%static=$sth0{'sth'}->fetchhash();
	
	return \%static;
}

1;
