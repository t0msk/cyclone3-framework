#!/bin/perl
package App::400::a160;

=head1 NAME

App::400::a160

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a400

=cut

=head1 DEPENDS

=over

=item *

L<App::400::_init|app/"400/_init.pm">

=back

=cut

use App::400::_init;

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
			(
				SELECT
					title
				FROM
					`$env{'r_db_name'}`.`a400`
				WHERE
					ID=$env{'r_ID_entity'} AND
					lng='$env{'lng'}'
				LIMIT 1
			)
			UNION ALL
			(
				SELECT
					title
				FROM
					`$env{'r_db_name'}`.`a400_arch`
				WHERE
					ID=$env{'r_ID_entity'} AND
					lng='$env{'lng'}'
				LIMIT 1
			)
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','log'=>$DEBUG);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'title'};
			main::_log("returning name='$db0_line{'title'}'");
			$t->close();
			return %info;
		}
	}
	
	$t->close();
	return undef;
}

1;