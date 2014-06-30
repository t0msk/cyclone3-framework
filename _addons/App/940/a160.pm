#!/bin/perl
package App::940::a160;

=head1 NAME

App::940::a160

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a940

=cut

=head1 DEPENDS

=over

=item *

L<App::940::_init|app/"940/_init.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::020::a160|app/"020/a160.pm">

=back

=cut

use App::940::_init;
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
	$env{'r_db_name'}=$App::940::db_name unless $env{'r_db_name'};
	
	my $lng_in;
	
	my %info;
	
=head1
	if ($env{'r_table'} eq "discount")
	{
		my $sql=qq{
			SELECT
				rfp.ID AS ID_rfp,
				rfp_lng.name,
				rfp_cat.ID AS ID_category,
				rfp_lng.lng
			FROM
				`$App::930::db_name`.`a930_rfp` AS rfp
			LEFT JOIN `$App::930::db_name`.`a930_rfp_lng` AS rfp_lng ON
			(
				rfp_lng.ID_entity = rfp.ID_entity
			)
			LEFT JOIN `$App::930::db_name`.`a930_rfp_rel_cat` AS rel_cat ON
			(
				rel_cat.ID_rfp = rfp.ID_entity
			)
			LEFT JOIN `$App::930::db_name`.`a930_rfp_cat` AS rfp_cat ON
			(
				rfp_cat.ID_entity = rel_cat.ID_category AND
				rfp_cat.lng = rfp_lng.lng
			)
			WHERE
				rfp.ID_entity=$env{'r_ID_entity'}
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID_rfp'};
			$info{'ID_category'}=$db0_line{'ID_category'};
			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
=cut
	
	$t->close();
	return undef;
}



1;
