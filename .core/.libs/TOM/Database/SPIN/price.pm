package TOM::Database::SPIN::price;

=head1 NAME

TOM::Database::SPIN::price

=head1 DESCRIPTION

Knižnica správy cien systému SPIN spoločnosti DATALOCK.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

knižnice:

 TOM::Database::SPIN
 Time::Local

=cut

use TOM::Database::SPIN;
use Time::Local;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw /
	&GetRebate
	&GetPriceID
	&fsofGetPrice
	&fsofGetRabat
	&fsklCenikCenaDatumOd
	/;


=head1 VARIABLES

=over

=item *

$debug

Zapnutie logovania narocnejsich veci. Ide napr. priamo o query na databazu, vsetky volania funkcii, etc...

=back

=cut

our $debug=0;


=head1 FUNCTIONS

=head2 GetRebate()

Vracia hash s informaciami o rabate. Funkcia momentálne nenarába s časovým rozsahom.

 my %rebate=(TOM::Database::SPIN::GetRebate();

Vstupy:

=over

=item *

user_ID

=item *

product_ID

=item *

brand

=item *

category_ID

=back

=cut

sub GetRebate
{
	my $t=track TOM::Debug(__PACKAGE__."::GetRebate()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	$env{'user_ID'}=$main::USRM{'session'}{'SPIN'}{'ID'} unless $env{'user_ID'};
	$env{'user_ID'}=0 unless $env{'user_ID'};
	
	if (!$env{'brand'} || not exists $env{'user_ID'} || !$env{'category_ID'})
	{
		$t->close();
		main::_log("without input",1);
		return undef;
	}
	
	my $sql=qq{
		SELECT
			rabat_id "rebate_ID",
			firma_id "user_ID",
			chvuep "brand",
			druh_ceny_id "price_ID",
			platnost_od "date_from",
			platnost_do "date_to"
		FROM
			dl.sof_rabat
		WHERE
			(
				firma_id IS NULL OR
				firma_id=$env{'user_ID'}
			) AND
			produkt_id='$env{'product_ID'}'
		ORDER BY firma_id ASC
	};
	main::_log("sql:=$sql") if $debug;
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	$db0->execute();
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'rebate_ID'}=$arr[0];
		$data{'user_ID'}=$arr[1];
		#$data{'brand'}=$arr[2];
		$data{'price_ID'}=$arr[3];
		$data{'date_from'}=$arr[4];
		$data{'date_to'}=$arr[5];
		$data{'product_ID'}=$env{'product_ID'};
		
		foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
		$t->close();
		return %data;
	}
	
	my $sql=qq{
		SELECT
			rabat_id "rebate_ID",
			firma_id "user_ID",
			chvuep "brand",
			druh_ceny_id "price_ID",
			platnost_od "date_from",
			platnost_do "date_to"
		FROM
			dl.sof_rabat
		WHERE
			(
				firma_id IS NULL OR
				firma_id=$env{'user_ID'}
			) AND
			chvuep='$env{'brand'}'
		ORDER BY firma_id ASC
	};
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'rebate_ID'}=$arr[0];
		$data{'user_ID'}=$arr[1];
		$data{'brand'}=$arr[2];
		$data{'price_ID'}=$arr[3];
		$data{'date_from'}=$arr[4];
		$data{'date_to'}=$arr[5];
		
		foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
		
		$t->close();
		return %data;
	}
	
	
	# idem hladat rabat podla kategorie produktu
	# priorita je kladena na priradenie konkretnej firme a az potom lubovolnej firme
	
	# zistim ku category_ID vsetky nadkategorie
	# uplatnujem totiz vztah ze ak je nastaveny rabat na kategoriu produktu, plati
	# i pre vsetky podkategorie produktov.
	my @cats;
	foreach my $cat(TOM::Database::SPIN::GetRecategories($env{'category_ID'}))
	{
		next unless $cat->{'ID'};
		push @cats, $cat->{'ID'};
	}
	my $cat_in=join ",",@cats;
	main::_log("search for category IN ($cat_in)");
	$cat_in='0' unless $cat_in;
	
	# vytvorenie query
	my $sql=qq{
		SELECT
			rabat_id "rebate_ID",
			firma_id "user_ID",
			chvuep "brand",
			druh_ceny_id "price_ID",
			platnost_od "date_from",
			platnost_do "date_to",
			kategoria_id
		FROM
			dl.sof_rabat
		WHERE
			(
				firma_id IS NULL OR
				firma_id=$env{'user_ID'}
			) AND
			kategoria_id IN ($cat_in)
		ORDER BY kategoria_id ASC, firma_id ASC
	};
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	$db0->execute();
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'rebate_ID'}=$arr[0];
		$data{'user_ID'}=$arr[1];
		#$data{'brand'}=$arr[2];
		$data{'price_ID'}=$arr[3];
		$data{'date_from'}=$arr[4];
		$data{'date_to'}=$arr[5];
		$data{'category_ID'}=$env{'category_ID'};
		
		foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
		$t->close();
		return %data;
	}
	
	$t->close();
	return %data;
	
}

=head2 fsofGetRabat()

=cut

sub fsofGetRabat
{
	my $t=track TOM::Debug(__PACKAGE__."::fsofGetRabat()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	my $sql=qq{
		DECLARE
			anFirmaId NUMBER;
			anProduktId NUMBER;
			avaTypRabatu VARCHAR2(32);
			adecHodnota NUMBER;
			avaTypHodnoty VARCHAR2(32);
			adecRabat2 NUMBER;
			avaTypRabatu2 VARCHAR2(32);
			anDruhCenyId NUMBER;
			adDatum DATE;
			retout NUMBER;
		BEGIN
			:retout := dl.fsofGetRabat
			(
				:anFirmaId,
				:anProduktId,
				:avaTypRabatu,
				:adecHodnota,
				:avaTypHodnoty,
				:adecRabat2,
				:avaTypRabatu2,
				:anDruhCenyId,
				:adDatum
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	my $date=$tom::Fmday.$tom::Fmom.$tom::Fyear;
	main::_log("date='$date'");
	
	$db0->bind_param(":anFirmaId", $env{'user_ID'} );
	$db0->bind_param(":anProduktId", $env{'product_ID'} );
	$db0->bind_param(":adDatum", $date );
	
	$db0->bind_param_inout( ":avaTypRabatu", \$data{'rebate_type'}, 32 );
	$db0->bind_param_inout( ":adecHodnota", \$data{'amount'}, 32 );
	$db0->bind_param_inout( ":avaTypHodnoty", \$data{'amount_type'}, 32 );
	$db0->bind_param_inout( ":adecRabat2", \$data{'rebate2'}, 32 );
	$db0->bind_param_inout( ":avaTypRabatu2", \$data{'rebate_type2'}, 32 );
	$db0->bind_param_inout( ":anDruhCenyId", \$data{'price_ID'}, 32 );
	$db0->bind_param_inout( ":retout", \$data{'rebate'}, 32 );
	$db0->execute();
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}

=head2 fsofGetPrice()

=cut

sub fsofGetPrice
{
	my $t=track TOM::Debug(__PACKAGE__."::fsofGetPrice()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my $data;
	
	return undef unless $env{'product_ID'};
	
	$env{'price_ID'} = $main::USRM{'session'}{'SPIN'}{'price_ID'} unless $env{'price_ID'};
	$env{'price_ID'} = 2 unless $env{'price_ID'};
	$env{'tax_DPH'}='N' unless $env{'tax_DPH'};
	
	main::_log("price_ID='$env{'price_ID'}'");
	
	my $sql=qq{
		DECLARE
			retout NUMBER;
		BEGIN
			:retout := dl.fsofGetPrice
			(
				:anProduktId,
				:anDruhCenyId,
				:adDatum,
				:anFirmaId,
				:acRetCenaSdph
			);
		END;
	};
	
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	my $date=$tom::Fmday.'.'.$Utils::datetime::MONTHS{en}[$tom::Tmom-1].'.'.$tom::Fyear;
	my $date=$tom::Fmday.$tom::Fmom.$tom::Fyear;
	
	$env{'date'}=$date unless $env{'date'};
	
	main::_log("date='$env{'date'}'");
	
	$db0->bind_param(":anFirmaId", $main::USRM{'session'}{'SPIN'}{'ID'} );
	#$db0->bind_param(":anDruhCenyId", $main::USRM{'session'}{'SPIN'}{'price_ID'} );
	$db0->bind_param(":anDruhCenyId", $env{'price_ID'} );
	$db0->bind_param(":anProduktId", $env{'product_ID'} );
	$db0->bind_param(":adDatum", $env{'date'} );
	$db0->bind_param(":acRetCenaSdph", $env{'tax_DPH'} );
	
	$db0->bind_param_inout( ":retout", \$data, 32 );
	$db0->execute();
	
	main::_log("returning price '$data'");
	
	$t->close();
	
	return undef unless $data;
	
	return $data;
}


=head2 fsklCenikCenaDatumOd()

Vráti dátum_od aktuálnej cenníkovej ceny

=cut

sub fsklCenikCenaDatumOd
{
	
	my $t=track TOM::Debug(__PACKAGE__."::fsklCenikCenaDatumOd()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my $data;
	
	return undef unless $env{'product_ID'};
	
	$env{'price_ID'} = $main::USRM{'session'}{'SPIN'}{'price_ID'} unless $env{'price_ID'};
	$env{'price_ID'} = 2 unless $env{'price_ID'};
	
	main::_log("price_ID='$env{'price_ID'}'");
	
	my $sql=qq{
		DECLARE
			retout DATE;
		BEGIN
			:retout := dl.fsklCenikCenaDatumOd
			(
				:anProduktId,
				:anDruhCenyId
			);
		END;
	};
	
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	$db0->bind_param(":anDruhCenyId", $env{'price_ID'} );
	$db0->bind_param(":anProduktId", $env{'product_ID'} );
	
	$db0->bind_param_inout( ":retout", \$data, 32 );
	$db0->execute();
	
	main::_log("returning date '$data'");
	
	$t->close();
	
	return $data;
}


=head2 GetPriceID()

=cut

sub GetPriceID
{
	my $t=track TOM::Debug(__PACKAGE__."::GetPriceID()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	my $where;
	$where.="AND druh_ceny_id = $env{'ID'} " if $env{'ID'};
	$where.="AND kod_druhu_ceny = '$env{'name'}' " if $env{'name'};
	
	my $sql = qq{
		SELECT
			druh_ceny_id "ID",
			kod_druhu_ceny "name",
			popis_druhu_ceny "about",
			macro "macro"
		FROM
			dl.sof_druh_ceny
		WHERE
			mandant_id >= 0
			$where
	};    # Prepare and execute SELECT
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'ID'}=$arr[0];
		$data{'name'}=$arr[1];
		$data{'about'}=$arr[2];
		$data{'macro'}=$arr[3];
	}
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}


1;