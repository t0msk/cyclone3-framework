#!/bin/perl
package App::540::a160;

=head1 NAME

App::540::a160

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a540

=cut

=head1 DEPENDS

=over

=item *

L<App::540::_init|app/"540/_init.pm">

=back

=cut

use App::540::_init;

our $VERSION='$Rev$';
our $DEBUG;

sub get_relation_iteminfo
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_relation_iteminfo()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	# if db_name is undefined, use local name
	$env{'r_db_name'}=$TOM::DB{'main'}{'name'} unless $env{'r_db_name'};
	
	my %info;
	
	if ($env{'r_table'} eq "")
	{
		my $sql=qq{
			SELECT
				name
			FROM
				`$env{'r_db_name'}`.`a540`
			WHERE
				ID=$env{'r_ID_entity'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','log'=>$DEBUG);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'type_name'}='File';
			main::_log("returning name='$db0_line{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	$t->close();
	return undef;
}

1;