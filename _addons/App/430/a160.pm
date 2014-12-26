#!/bin/perl
package App::430::a160;

=head1 NAME

App::430::a160

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a430

=cut

=head1 DEPENDS

=over

=item *

L<App::430::_init|app/"430/_init.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::020::a160|app/"020/a160.pm">

=back

=cut

use App::430::_init;
use App::020::_init;
use App::020::a160;

our $VERSION='1';

sub get_relation_iteminfo
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_relation_iteminfo()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	# if db_name is undefined, use local name
	$env{'r_db_name'}=$App::430::db_name unless $env{'r_db_name'};
	
	my $lng_in;
	
	my %info;
	
	if ($env{'r_table'} eq "list")
	{
		my $sql=qq{
			SELECT
				ID,
				ID_entity,
				name
			FROM
				`$env{'r_db_name'}`.a430_list
			WHERE
				ID_entity=$env{'r_ID_entity'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID'};
			$info{'ID_entity'}=$db0_line{'ID_entity'};
			$info{'ID_category'}=$db0_line{'ID_category'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	$t->close();
	return undef;
}



1;
