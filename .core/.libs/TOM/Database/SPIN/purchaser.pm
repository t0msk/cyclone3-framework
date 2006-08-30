package TOM::Database::SPIN::purchaser;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use DBI;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Time::Local;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw (&CreatePurchaser);

our $debug=0;
our $debug_disable=0;


sub CreatePurchaser
{
	my $t=track TOM::Debug(__PACKAGE__."::CreatePurchaser()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	return undef unless $env{'user_ID'};
	return undef unless $env{'price_ID'};
	return undef unless $env{'code'};
	
	$env{'payer_DPH'}="Y" unless $env{'payer_DPH'};
	return undef unless $env{'code'};
	
	my $sql=qq{
		DECLARE
			anOdberatelId NUMBER;
			anMenaId NUMBER;
			anFirmaId NUMBER;
			avaInternyKod VARCHAR2(20);
			anDodBuId NUMBER;
			anDruhCenyId NUMBER;
			anDniSplatnosti NUMBER;
			anRabat NUMBER;
			anLimit NUMBER;
			avaFakturacneMiesto VARCHAR2(1);
			anUzodId NUMBER;
			avaSposobUhrady VARCHAR2(1);
			anRabat2 NUMBER;
			anRabatKategId NUMBER;
			anDruhCenyId2 NUMBER;
			avaTypSplatnosti VARCHAR2(1);
		BEGIN
			dl.pksofOdberatel.WriteOdberatel
			(
				anOdberatelId => :anOdberatelId,
				anMenaId => :anMenaId,
				anFirmaId => :anFirmaId,
				avaInternyKod => :avaInternyKod,
				anDodBuId => :anDodBuId,
				anDruhCenyId => :anDruhCenyId,
				anDniSplatnosti => :anDniSplatnosti,
				anRabat => :anRabat,
				anLimit => :anLimit,
				avaFakturacneMiesto => :avaFakturacneMiesto,
				anUzodId => :anUzodId,
				avaSposobUhrady => :avaSposobUhrady,
				anRabat2 => :anRabat2,
				anRabatKategId => :anRabatKategId,
				anDruhCenyId2 => :anDruhCenyId2,
				avaTypSplatnosti => :avaTypSplatnosti
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	my %data;
	
	$db0->bind_param(":anMenaId",1);
	$db0->bind_param(":anFirmaId",$env{'user_ID'});
	$db0->bind_param(":avaInternyKod",$env{'code'});
	$db0->bind_param(":anDodBuId",undef);
	$db0->bind_param(":anDruhCenyId",$env{'price_ID'});
	$db0->bind_param(":anDniSplatnosti",$env{'purchaser_payback'});
	$db0->bind_param(":anRabat",0);
	$db0->bind_param(":anLimit",0);
	$db0->bind_param(":avaFakturacneMiesto",'A');
	$db0->bind_param(":anUzodId",undef);
	$db0->bind_param(":avaSposobUhrady",'B');
	$db0->bind_param(":anRabat2",0);
	$db0->bind_param(":anRabatKategId",undef);
	$db0->bind_param(":anDruhCenyId2",undef);
	$db0->bind_param(":avaTypSplatnosti",'K');
	
	$db0->bind_param_inout( ":anOdberatelId", \$data{'purchaser_ID'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}



1;