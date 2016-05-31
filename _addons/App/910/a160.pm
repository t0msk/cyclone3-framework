#!/bin/perl
package App::910::a160;

=head1 NAME

App::910::a160

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a910

=cut

=head1 DEPENDS

=over

=item *

L<App::910::_init|app/"910/_init.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::020::a160|app/"020/a160.pm">

=back

=cut

use App::910::_init;
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
	$env{'r_db_name'}=$App::910::db_name unless $env{'r_db_name'};
	
	my $lng_in;
	
	if ($env{'lng'})
	{
		$lng_in="AND product_lng.lng='".$env{'lng'}."'";
	}
	
	my %info;
	
	if ($env{'r_table'} eq "product")
	{
		my $sql=qq{
			SELECT
				product.ID AS ID_product,
				product_lng.name,
				product_cat.ID AS ID_category,
				product_lng.lng
			FROM
				`$App::910::db_name`.`a910_product` AS product
			LEFT JOIN `$App::910::db_name`.`a910_product_ent` AS product_ent ON
			(
				product_ent.ID_entity = product.ID_entity
			)
			LEFT JOIN `$App::910::db_name`.`a910_product_lng` AS product_lng ON
			(
				product_lng.ID_entity = product.ID
			)
			LEFT JOIN `$App::910::db_name`.`a910_product_sym` AS product_sym ON
			(
				product_sym.ID_entity = product.ID_entity
			)
			LEFT JOIN `$App::910::db_name`.`a910_product_cat` AS product_cat ON
			(
				product_cat.ID_entity = product_sym.ID AND
				product_cat.lng = product_lng.lng
			)
			WHERE
				product.ID=?
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$env{'r_ID_entity'}],'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID_product'};
			$info{'ID_category'}=$db0_line{'ID_category'};
			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}

	
	if ($env{'lng'})
	{
		$lng_in="AND lng='".$env{'lng'}."'";
	}
	
	if ($env{'r_table'} eq "product_cat")
	{
		my $sql=qq{
			SELECT
				ID,
				name,
				lng
			FROM
				`$env{'r_db_name'}`.a910_product_cat
			WHERE
				ID_entity=?
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$env{'r_ID_entity'}],'db_h'=>'main');
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
	
	if ($env{'r_table'} eq "product_brand")
	{
		my $sql=qq{
			SELECT
				ID,
				name
			FROM
				`$env{'r_db_name'}`.a910_product_brand
			WHERE
				ID_entity=$env{'r_ID_entity'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	$t->close();
	return undef;
}



1;
