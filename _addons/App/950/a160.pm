#!/bin/perl
package App::950::a160;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::950::_init;
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
	$env{'r_db_name'}=$App::950::db_name unless $env{'r_db_name'};
	
	my $lng_in;
	
	if ($env{'lng'})
	{
		$lng_in="AND offer_lng.lng='".$env{'lng'}."'";
	}
	
	my %info;
	
	if ($env{'r_table'} eq "offer")
	{
		my $sql=qq{
			SELECT
				offer.ID AS ID_offer,
				offer_lng.name,
				offer_cat.ID AS ID_category,
				offer_lng.lng
			FROM
				`$App::950::db_name`.`a950_offer` AS offer
			LEFT JOIN `$App::950::db_name`.`a950_offer_lng` AS offer_lng ON
			(
				offer_lng.ID_entity = offer.ID_entity
			)
			LEFT JOIN `$App::950::db_name`.`a950_offer_rel_cat` AS rel_cat ON
			(
				rel_cat.ID_offer = offer.ID_entity
			)
			LEFT JOIN `$App::950::db_name`.`a950_offer_cat` AS offer_cat ON
			(
				offer_cat.ID_entity = rel_cat.ID_category AND
				offer_cat.lng = offer_lng.lng
			)
			WHERE
				offer.ID_entity=$env{'r_ID_entity'}
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID_offer'};
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
	
	if ($env{'r_table'} eq "offer_cat")
	{
		my $sql=qq{
			SELECT
				ID,
				name,
				lng
			FROM
				`$env{'r_db_name'}`.a950_offer_cat
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
