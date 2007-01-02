package TOM::Database::SPIN::address;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Time::Local;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw (&GetCities &CreateAddress);

our $debug=0;
our $debug_disable=0;


sub GetCities
{
	my $t=track TOM::Debug(__PACKAGE__."::GetCities()",'namespace'=>'SPIN');
	my %env=@_;
	
	my @data;
	
	my $sql = qq{
		SELECT
			mesto_id "city_ID",
			nazov_mesta "name",
			psc
		FROM
			dl.dl_mesto
		WHERE
			stat_id=1
		ORDER BY
			nazov_mesta ASC
	};    # Prepare and execute SELECT
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	my $i=0;
	while (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		my %hash;
		$hash{'ID'}=$arr[0];
		$hash{'name'}=$arr[1];
		$hash{'PSC'}=$arr[2];
		
		#main::_log("output[$i] ID='$arr[0]' name='$arr[1]' PSC='$arr[2]'");
		
		push @data,{%hash};
		$i++;
	}
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return @data;
}




sub CreateAddress
{
	my $t=track TOM::Debug(__PACKAGE__."::CreateAddress()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	return undef unless $env{'city_ID'};
	return undef unless $env{'city_PSC'};
	#return undef unless $env{'street'};
	return undef unless $env{'street_number'};
	
	my $sql=qq{
		DECLARE
			anadresa_id NUMBER ;
			avviditelnost VARCHAR2(1);
			anmesto_id NUMBER;
			avadresa1 VARCHAR2(50);
			anakt_adresa_id NUMBER(38);
			adplatnost_do DATE;
			avulica VARCHAR2(50);
			antyp_adresy_id NUMBER;
			avcislo_supisne VARCHAR2(10);
			avcislo_orientacne VARCHAR2(10);
			avadresa2 VARCHAR2(50);
			avadresapsc VARCHAR2(10);
			adPredplatnost_do DATE;
			anpredtyp_adresy_id NUMBER;
		BEGIN
			dl.pkdlAdresa.pkInsert
			(
				anadresa_id => :anadresaid,
				avviditelnost => :avviditelnost,
				anmesto_id => :anmesto_id,
				avadresa1 => :avadresa1,
				anakt_adresa_id => :anakt_adresa_id,
				adplatnost_do => :adplatnost_do,
				avulica => :avulica,
				antyp_adresy_id => :antyp_adresy_id,
				avcislo_supisne => :avcislo_supisne,
				avcislo_orientacne => :avcislo_orientacne,
				avadresa2 => :avadresa2,
				avadresapsc => :avadresapsc,
				adPredplatnost_do => :adPredplatnost_do,
				anpredtyp_adresy_id => :anpredtyp_adresy_id
			);
		END;
	};
	
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	my %data;
	
	#$db0->bind_param(":anadresaid",undef);
	$db0->bind_param(":avviditelnost",'V');
	$db0->bind_param(":anmesto_id",$env{'city_ID'});
	$db0->bind_param(":avadresa1",undef);
	$db0->bind_param(":anakt_adresa_id",undef);
	$db0->bind_param(":adplatnost_do",undef);
	$db0->bind_param(":avulica",$env{'street'});
	$db0->bind_param(":antyp_adresy_id",undef);
	$db0->bind_param(":avcislo_supisne",undef);
	$db0->bind_param(":avcislo_orientacne",$env{'street_number'});
	$db0->bind_param(":avadresa2",undef);
	$db0->bind_param(":avadresapsc",$env{'city_PSC'});
	$db0->bind_param(":adPredplatnost_do",undef);
	$db0->bind_param(":anpredtyp_adresy_id",undef);
	
	$db0->bind_param_inout( ":anadresaid", \$data{'address_ID'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
	
}



1;