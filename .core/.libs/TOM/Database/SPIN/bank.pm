package TOM::Database::SPIN::bank;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Time::Local;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw (&GetBanks &CreateBU);

our $debug=0;
our $debug_disable=0;


sub GetBanks
{
	my $t=track TOM::Debug(__PACKAGE__."::GetBanks()",'namespace'=>'SPIN');
	my %env=@_;
	
	my @data;
	
	my $sql = qq{
		SELECT
			banka_id "ID",
			nazov_banky "name",
			kod_banky "code"
		FROM
			dl.dl_penazny_ustav
		ORDER BY
			kod_banky
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
		$hash{'code'}=$arr[2];
		
		main::_log("output[$i] ID='$arr[0]' name='$arr[1]' code='$arr[2]'");
		
		push @data,{%hash};
		$i++;
	}
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return @data;
}


sub CreateBU
{
	my $t=track TOM::Debug(__PACKAGE__."::CreateBU()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	return undef unless $env{'user_ID'};
	return undef unless $env{'BU'};
	return undef unless $env{'PU'};
	
	my $sql=qq{
		DECLARE
			anBuId NUMBER;
			anBankaId NUMBER;
			avaCisloBankovehoUctu VARCHAR2(100);
			avaDescBu VARCHAR2(100);
			anFirmaId NUMBER;
			anOsobaId NUMBER;
			anDuId NUMBER;
			anColnicaId NUMBER;
			avaViditelnost VARCHAR2(1);
			anKBankaId NUMBER;
			adPlatnostBuDo DATE;
			avaBuUrcenie VARCHAR2(1);
		BEGIN
			dl.pkdlBankovyUcet.InsertBankovyUcet
			(
				anBuId => :anBuId,
				anBankaId => :anBankaId,
				avaCisloBankovehoUctu => :avaCisloBankovehoUctu,
				avaDescBu => :avaDescBu,
				anFirmaId => :anFirmaId,
				anOsobaId => :anOsobaId,
				anDuId => :anDuId,
				anColnicaId => :anColnicaId,
				avaViditelnost => :avaViditelnost,
				anKBankaId => :anKBankaId,
				adPlatnostBuDo => :adPlatnostBuDo,
				avaBuUrcenie => :avaBuUrcenie
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	my %data;
	
	$db0->bind_param(":anBankaId",$env{'PU'});
	$db0->bind_param(":avaCisloBankovehoUctu",$env{'BU'});
	$db0->bind_param(":avaDescBu",undef);
	$db0->bind_param(":anFirmaId",$env{'user_ID'});
	$db0->bind_param(":anOsobaId",undef);
	$db0->bind_param(":anDuId",undef);
	$db0->bind_param(":anColnicaId",undef);
	$db0->bind_param(":avaViditelnost",'V');
	$db0->bind_param(":anKBankaId",undef);
	$db0->bind_param(":adPlatnostBuDo",undef);
	$db0->bind_param(":avaBuUrcenie",undef);
	
	$db0->bind_param_inout( ":anBuId", \$data{'ID'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}










1;