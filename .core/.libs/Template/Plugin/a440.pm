package Template::Plugin::a440;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::440::_init;

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


sub get_promo_item {
	my $self = shift;
	my $env = shift;
	my %static;
	
	my @bind;
	my %sql_env;
	
	# random
	my $sql=qq{
		SELECT
			a440_promo_item.*
		FROM
			$App::440::db_name.a440_promo_item
		LEFT JOIN $App::440::db_name.a440_promo_cat ON
		(
			a440_promo_item.ID_category = a440_promo_cat.ID
		)
		WHERE};
	my $sql_where;
	
	if (ref($env) eq 'SCALAR' || !ref($env))
	{
		if ($env=~/^\d+$/)
		{
			$sql.=qq{ AND a440_promo_item.ID=?};
			push @bind,$env;
		}
		else
		{
			$sql.=qq{ AND a440_promo_item.title=?};
			push @bind,$env;
		}
	}
	else
	{
		if ($env->{'promo_cat.name'})
		{
			$sql.=qq{ AND a440_promo_cat.name=?};
			push @bind,$env->{'promo_cat.name'};
		}
		if ($env->{'promo_item.title'})
		{
			$sql.=qq{ AND a440_promo_item.title=?};
			push @bind,$env->{'promo_item.title'};
		}
		if ($env->{'promo_item.ID'})
		{
			$sql.=qq{ AND a440_promo_item.ID=?};
			push @bind,$env->{'promo_item.ID'};
		}
		if ($env->{'ID'})
		{
			$sql.=qq{ AND a440_promo_item.ID=?};
			push @bind,$env->{'ID'};
		}
	}
	
	$sql=~s|WHERE AND|WHERE|ms;
	
	$sql.=qq{ AND a440_promo_item.status='Y'};
	
#	$sql.=$sql_where;
	$sql.=qq{
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[@bind],'log'=>1,%sql_env);
	%static=$sth0{'sth'}->fetchhash();
	
	return \%static;
}

1;
