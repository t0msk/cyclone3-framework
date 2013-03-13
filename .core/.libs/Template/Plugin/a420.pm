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
		WHERE
	};
	my $sql_where;
	
	if (ref($env) == 'SCALAR')
	{
		if ($env=~/^\d+$/)
		{
			$sql_where.=qq{a420_static.ID=?};
			@bind=[$env];
		}
		else
		{
			$sql.=qq{a420_static.name=?};
			@bind=[$env];
		}
	}
	elsif ($env->{'static_cat.name'})
	{
		$sql.=qq{a420_static_cat.name=?};
		@bind=[$env->{'static_cat.name'}];
	}
	elsif ($env->{'static.name'})
	{
		$sql.=qq{a420_static.name=?};
		@bind=[$env->{'static.name'}];
	}
	elsif ($env->{'static.ID'})
	{
		$sql.=qq{a420_static.ID=?};
		@bind=[$env->{'static.ID'}];
	}
	elsif ($env->{'ID'})
	{
		$sql.=qq{a420_static.ID=?};
		@bind=[$env->{'ID'}];
	}
	
	$sql.=qq{ AND a420_static.status='Y'};
	
#	$sql.=$sql_where;
	$sql.=qq{
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'bind'=>@bind,'quiet'=>1,%sql_env);
	%static=$sth0{'sth'}->fetchhash();
	
	return \%static;
}

1;