#!/bin/perl
package App::542::a160;

=head1 NAME

App::542::a160

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a542

=cut

=head1 DEPENDS

=over

=item *

L<App::542::_init|app/"542/_init.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::020::a160|app/"020/a160.pm">

=back

=cut

use App::542::_init;
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
	$env{'r_db_name'}=$App::542::db_name unless $env{'r_db_name'};
	
	my $lng_in;
	
	if ($env{'lng'})
	{
		$lng_in="AND lng='".$env{'lng'}."'";
	}
	
	my %info;
	
	if ($env{'r_table'} eq "file")
	{
		my $sql=qq{
			SELECT
				ID_file,
				name,
				name_ext,
				ID_category,
				lng
			FROM
				`$env{'r_db_name'}`.a542_file_view
			WHERE
				ID_entity_file=$env{'r_ID_entity'}
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'name_plus'}='.'.$db0_line{'name_ext'};
			$info{'ID'}=$db0_line{'ID_file'};
			$info{'ID_category'}=$db0_line{'ID_category'};
			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	if ($env{'r_table'} eq "file_dir")
	{
		my $sql=qq{
			SELECT
				ID,
				name,
				lng
			FROM
				`$env{'r_db_name'}`.a542_file_dir
			WHERE
				ID_entity=$env{'r_ID_entity'}
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