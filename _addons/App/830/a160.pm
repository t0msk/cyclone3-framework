#!/bin/perl
package App::830::a160;

=head1 NAME

App::830::a160

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a830

=cut

=head1 DEPENDS

=over

=item *

L<App::830::_init|app/"830/_init.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::020::a160|app/"020/a160.pm">

=back

=cut

use App::830::_init;
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
	$env{'r_db_name'}=$App::830::db_name unless $env{'r_db_name'};
	
	my $lng_in;
	
	my %info;
	
	if ($env{'r_table'} eq "form")
	{
		my $sql=qq{
			SELECT
				`form`.`ID` AS `ID_form`,
				`form`.`name` AS `name`,
				`form`.`lng` AS `lng`,
				`form_cat`.`ID` AS `ID_category`
			FROM
				`$App::830::db_name`.`a830_form` AS `form`
			LEFT JOIN `$App::830::db_name`.`a830_form_rel_cat` AS `rel_cat` ON
			(
				`rel_cat`.`ID_form` = `form`.`ID_entity`
			)
			LEFT JOIN `$App::830::db_name`.`a830_form_cat` AS `form_cat` ON
			(
				`form_cat`.`ID_entity` = `rel_cat`.`ID_category`
			)
			WHERE
				`form`.`ID_entity` = $env{'r_ID_entity'}
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID_form'};
			$info{'ID_category'}=$db0_line{'ID_category'};
			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	
	if ($env{'lng'})
	{
		$lng_in="AND `lng` ='".$env{'lng'}."'";
	}
	
	if ($env{'r_table'} eq "form_cat")
	{
		my $sql=qq{
			SELECT
				`ID`,
				`name`,
				`lng`
			FROM
				`$env{'r_db_name'}`.`a830_form_cat`
			WHERE
				`ID_entity` = $env{'r_ID_entity'}
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID'};
			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	$t->close();
	return undef;
}



1;
