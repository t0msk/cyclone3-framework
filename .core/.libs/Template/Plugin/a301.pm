package Template::Plugin::a301;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::301::_init;

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


sub get_user {
	my $self = shift;
	my $env = shift;
	my %user;
	
	my @bind;
	my %sql_env;
	
	# random
	my $sql=qq{
		SELECT
			a301_user.login,
			a301_user_profile.firstname,
			a301_user_profile.surname
		FROM
			`$App::301::db_name`.a301_user
		INNER JOIN `$App::301::db_name`.a301_user_profile ON
		(
			a301_user_profile.ID_entity = a301_user.ID_user
		)
		WHERE};
	my $sql_where;
	
	if (ref($env) eq 'SCALAR' || !ref($env))
	{
		$sql.=qq{ AND a301_user.ID_user=?};
		push @bind,$env;
	}
	
	$sql=~s|WHERE AND|WHERE|ms;
	
	$sql.=qq{
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[@bind],'quiet'=>1,'-slave'=>1,'-cache'=>60,%sql_env);
	%user=$sth0{'sth'}->fetchhash();
	
	return \%user;
}

1;
