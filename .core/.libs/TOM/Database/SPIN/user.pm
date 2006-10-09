package TOM::Database::SPIN::user;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use DBI;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Time::Local;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw /
	&GetUserTypes
	&SetMU
	&GetUsers
	&GetUser
	&CreateUser
	&CheckCreateUser
	&DeleteUser
	&GetUserTelephones
	&GetICDPH/;

our $debug=0;
our $debug_disable=0;



sub GetUserTypes
{
	my $t=track TOM::Debug(__PACKAGE__."::GetUserTypes()",'namespace'=>'SPIN');
	my %env=@_;
	
	my @data;
	
	my $sql = qq{
		SELECT
			typ_firmy_id,
			nazov_typu_firmy
		FROM
			dl.dl_typ_firmy
		ORDER BY
			typ_firmy_id
	}; # Prepare and execute SELECT
	
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
		
		main::_log("output[$i] ID='$arr[0]' name='$arr[1]'");
		
		push @data,{%hash};
		$i++;
	}
	
	$t->close();
	return @data;
}


sub GetUsers
{
	my $t=track TOM::Debug(__PACKAGE__."::GetUsers()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	#return undef unless $env{ID};
	
	my $where;
	
	$where.="AND \"dl\".firma_id = $env{ID} " if $env{ID};
	$where.="AND \"tbl\".rfirma_id = $env{parent_ID} " if $env{parent_ID};
	$where.="AND dl.pkdlFirmaMu.GetFirmaMuKodHodnota(\"dl\".firma_id,'0005') = '$env{mu_login}' " if $env{mu_login};
	$where.="AND dl.pkdlFirmaMu.GetFirmaMuKodHodnota(\"dl\".firma_id,'aktivny') = '$env{mu_active}' " if $env{mu_active};
	
	my @data;
	
	my $sql = qq{
		SELECT
			"dl".firma_id "ID",
			"dl".nazov_firmy "name",
			"dl".typ_firmy_id "type_ID",
			"dl".nazov_typu_firmy "type_name",
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'aktivny') AS mu_active,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'0005') AS mu_login,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'eshop.hesl') AS mu_password,
			"dl".ICO "ICO",
			"dl".DIC "DIC",
			"dl".platca_dph "DPH_payer",
			"sof".odberatel "purchaser",
			"sof".odberatel_id "purchaser_ID",
			"sof".odb_rabat "purchaser_rabat1",
			"sof".odb_rabat2 "purchaser_rabat2",
			"sof".odb_splatnost "purchaser_payback",
			"sof".odb_druh_ceny_id "price_ID",
			"dl".mandant_id "mandant_ID",
			"dl".adresa1 "adresa1",
			"dl".adresa2 "adresa2",
			"dl".PSC "PSC",
			"dl".cislo_orient "cislo",
			"dl".mesto "mesto",
			"dl".stat "stat",
			"dl".iso_a2 "ISO-A2",
			"dl".iso_a3 "ISO-A3",
			"tbl".rfirma_id "parent_ID",
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'ADMIN') AS mu_admin,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'Dopr.fakt') AS mu_doprava,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'ZFA') AS proforma,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'preprava') AS mu_prepocet_prepravy,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'Firma') AS mu_firma,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'PAR') AS mu_partner
		FROM
			dl.dl_view_firma "dl",
			dl.sof_view_firma "sof",
			dl.dl_firma "tbl"
		WHERE
			"dl".firma_id = "sof".firma_id AND
			"dl".firma_id = "tbl".firma_id AND
			"sof".odberatel = 'A'
			$where
	};    # Prepare and execute SELECT
	
	$sql=~s|\$where|$where|;
	
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
		$hash{'type_ID'}=$arr[2];
		$hash{'type_name'}=$arr[3];
		$hash{'mu_active'}=$arr[4];
		$hash{'mu_login'}=$arr[5];
		$hash{'mu_password'}=$arr[6];
		$hash{'ICO'}=$arr[7];
		$hash{'DIC'}=$arr[8];
		$hash{'DPH_payer'}=$arr[9];
		$hash{'purchaser'}=$arr[10];
		$hash{'purchaser_ID'}=$arr[11];
		$hash{'purchaser_rebate1'}=$arr[12];
		$hash{'purchaser_rebate2'}=$arr[13];
		$hash{'purchaser_payback'}=$arr[14];
		$hash{'price_ID'}=$arr[15];
		$hash{'mandant_ID'}=$arr[16];
		
		$hash{'street_number'}=$arr[17];
		$hash{'street_plus'}=$arr[18];
		$hash{'PSC'}=$arr[19];
		#$data{'cislo'}=$arr[20];
		$hash{'city'}=$arr[21];
		$hash{'country'}=$arr[22];
		$hash{'ISO-A2'}=$arr[23];
		$hash{'ISO-A3'}=$arr[24];
		$hash{'parent_ID'}=$arr[25];
		$hash{'mu_admin'}=$arr[26];
		$hash{'mu_doprava'}=$arr[27];
		$hash{'mu_proforma'}=$arr[28];
		$hash{'mu_prepocet_prepravy'}=$arr[29];
		$hash{'mu_firma'}=$arr[30];
		$hash{'mu_partner'}=$arr[31];
		
		main::_log("output[$i] ID='$arr[0]' name='$arr[1]' parent_ID='$arr[25]' mu_admin='$arr[26]' mu_firma='$arr[30]' mu_partner='$arr[31]'");
		
		push @data,{%hash};
		$i++;
	}
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return @data;
}


sub GetUser
{
	my $t=track TOM::Debug(__PACKAGE__."::GetUser()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	#return undef unless $env{ID};
	
	my $where;
	
	$where.="AND \"dl\".firma_id = $env{ID} " if $env{ID};
	$where.="AND \"tbl\".rfirma_id = $env{parent_ID} " if $env{parent_ID};
	$where.="AND dl.pkdlFirmaMu.GetFirmaMuKodHodnota(\"dl\".firma_id,'0005') = '$env{mu_login}' " if $env{mu_login};
	$where.="AND dl.pkdlFirmaMu.GetFirmaMuKodHodnota(\"dl\".firma_id,'aktivny') = '$env{mu_active}' " if $env{mu_active};
	
	my %data;
	
	my $sql = qq{
		SELECT
			"dl".firma_id "ID",
			"dl".nazov_firmy "name",
			"dl".typ_firmy_id "type_ID",
			"dl".nazov_typu_firmy "type_name",
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'aktivny') AS mu_active,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'0005') AS mu_login,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'eshop.hesl') AS mu_password,
			"dl".ICO "ICO",
			"dl".DIC "DIC",
			"dl".platca_dph "DPH_payer",
			"sof".odberatel "purchaser",
			"sof".odberatel_id "purchaser_ID",
			"sof".odb_rabat "purchaser_rabat1",
			"sof".odb_rabat2 "purchaser_rabat2",
			"sof".odb_splatnost "purchaser_payback",
			"sof".odb_druh_ceny_id "price_ID",
			"dl".mandant_id "mandant_ID",
			"dl".adresa1 "adresa1",
			"dl".adresa2 "adresa2",
			"dl".PSC "PSC",
			"dl".cislo_orient "cislo",
			"dl".mesto "mesto",
			"dl".stat "stat",
			"dl".iso_a2 "ISO-A2",
			"dl".iso_a3 "ISO-A3",
			"tbl".rfirma_id "parent_ID",
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'ADMIN') AS mu_admin,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'Dopr.fakt') AS mu_doprava,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'ZFA') AS proforma,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'preprava') AS mu_prepocet_prepravy,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'Firma') AS mu_firma,
			dl.pkdlFirmaMu.GetFirmaMuKodHodnota("dl".firma_id,'PAR') AS mu_partner
		FROM
			dl.dl_view_firma "dl",
			dl.sof_view_firma "sof",
			dl.dl_firma "tbl"
		WHERE
			"dl".firma_id = "sof".firma_id AND
			"dl".firma_id = "tbl".firma_id AND
			"sof".odberatel = 'A'
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
		$data{'type_ID'}=$arr[2];
		$data{'type_name'}=$arr[3];
		$data{'mu_active'}=$arr[4];
		$data{'mu_login'}=$arr[5];
		$data{'mu_password'}=$arr[6];
		$data{'ICO'}=$arr[7];
		$data{'DIC'}=$arr[8];
		$data{'DPH_payer'}=$arr[9];
		$data{'purchaser'}=$arr[10];
		$data{'purchaser_ID'}=$arr[11];
		$data{'purchaser_rebate1'}=$arr[12];
		$data{'purchaser_rebate2'}=$arr[13];
		$data{'purchaser_payback'}=$arr[14];
		$data{'price_ID'}=$arr[15];
		$data{'mandant_ID'}=$arr[16];
		
		$data{'street_number'}=$arr[17];
		$data{'street_plus'}=$arr[18];
		$data{'PSC'}=$arr[19];
		#$data{'cislo'}=$arr[20];
		$data{'city'}=$arr[21];
		$data{'country'}=$arr[22];
		$data{'ISO-A2'}=$arr[23];
		$data{'ISO-A3'}=$arr[24];
		$data{'parent_ID'}=$arr[25];
		$data{'mu_admin'}=$arr[26];
		$data{'mu_doprava'}=$arr[27];
		$data{'mu_proforma'}=$arr[28];
		$data{'mu_prepocet_prepravy'}=$arr[29];
		$data{'mu_firma'}=$arr[30];
		$data{'mu_partner'}=$arr[31];
	}
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return %data;
}


sub CreateUser
{
	my $t=track TOM::Debug(__PACKAGE__."::CreateUser()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	return undef unless $env{'user_type'};
	#return undef unless $env{'ICO'};
	return undef unless $env{'address_ID'};
	return undef unless $env{'name'};
	#return undef unless $env{'payer_DPH'};
	$env{'payer_DPH'}="Y" unless $env{'payer_DPH'};
	return undef unless $env{'code'};
	
	my $sql=qq{
		DECLARE
			anFirmaId NUMBER;
			anMandantId NUMBER;
			anDuId NUMBER;
			anTypFirmyId NUMBER;
			avaIco VARCHAR2(15);
			avaDic VARCHAR2(15);
			anAdresaId NUMBER;
			avaNazovFirmy VARCHAR2(200);
			avaPlatcaDph VARCHAR2(1);
			anRFirmaId NUMBER;
			avaInternyKod VARCHAR2(20);
			adPlatnostDo DATE;
			anNaslednikId NUMBER;
		BEGIN
			dl.pkdlFirma.InsertFirma
			(
				anFirmaId => :anFirmaId,
				anMandantId => :anMandantId,
				anDuId => :anDuId,
				anTypFirmyId => :anTypFirmyId,
				avaIco => :avaIco,
				avaDic => :avaDic,
				anAdresaId => :anAdresaId,
				avaNazovFirmy => :avaNazovFirmy,
				avaPlatcaDph => :avaPlatcaDph,
				anRFirmaId => :anRFirmaId,
				avaInternyKod => :avaInternyKod,
				adPlatnostDo => :adPlatnostDo,
				anNaslednikId => :anNaslednikId
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	my %data;
	# FO = 4
	$db0->bind_param(":anMandantId",1);
	$db0->bind_param(":anDuId",undef);
	$db0->bind_param(":anTypFirmyId",$env{'user_type'});
	$db0->bind_param(":avaIco",$env{'ICO'});
	$db0->bind_param(":avaDic",$env{'DIC'});
	$db0->bind_param(":anAdresaId",$env{'address_ID'});
	$db0->bind_param(":avaNazovFirmy",$env{'name'});
	$db0->bind_param(":avaPlatcaDph",$env{'payer_DPH'});
	$db0->bind_param(":anRFirmaId",$env{'anRFirmaId'});
	$db0->bind_param(":avaInternyKod",$env{'code'});
	$db0->bind_param(":adPlatnostDo",undef);
	$db0->bind_param(":anNaslednikId",undef);
	
	$db0->bind_param_inout( ":anFirmaId", \$data{'user_ID'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}




sub CheckCreateUser
{
	my $t=track TOM::Debug(__PACKAGE__."::CheckCreateUser()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	return undef unless $env{'user_type'};
	#return undef unless $env{'ICO'};
	return undef unless $env{'address_ID'};
	return undef unless $env{'name'};
	#return undef unless $env{'payer_DPH'};
	$env{'payer_DPH'}="Y" unless $env{'payer_DPH'};
	return undef unless $env{'code'};
	
	my $sql=qq{
		DECLARE
			anFirmaId NUMBER;
			anMandantId NUMBER;
			anDuId NUMBER;
			anTypFirmyId NUMBER;
			avaIco VARCHAR2(15);
			avaDic VARCHAR2(15);
			anAdresaId NUMBER;
			avaNazovFirmy VARCHAR2(200);
			avaPlatcaDph VARCHAR2(1);
			anRFirmaId NUMBER;
			avaInternyKod VARCHAR2(20);
			adPlatnostDo DATE;
			anNaslednikId NUMBER;
			retout VARCHAR2(200);
		BEGIN
			:retout := dl.pkdlFirma.GetWriteWarning
			(
				:anFirmaId,
				:anMandantId,
				:anDuId,
				:anTypFirmyId,
				:avaIco,
				:avaDic,
				:anAdresaId,
				:avaNazovFirmy,
				:avaPlatcaDph,
				:anRFirmaId,
				:avaInternyKod,
				:adPlatnostDo,
				:anNaslednikId
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	my %data;
	# FO = 4
	$db0->bind_param(":anFirmaId",undef);
	$db0->bind_param(":anMandantId",1);
	$db0->bind_param(":anDuId",undef);
	$db0->bind_param(":anTypFirmyId",$env{'user_type'});
	$db0->bind_param(":avaIco",$env{'ICO'});
	$db0->bind_param(":avaDic",$env{'DIC'});
	$db0->bind_param(":anAdresaId",$env{'address_ID'});
	$db0->bind_param(":avaNazovFirmy",$env{'name'});
	$db0->bind_param(":avaPlatcaDph",$env{'payer_DPH'});
	$db0->bind_param(":anRFirmaId",undef);
	$db0->bind_param(":avaInternyKod",$env{'code'});
	$db0->bind_param(":adPlatnostDo",undef);
	$db0->bind_param(":anNaslednikId",undef);
	
	$db0->bind_param_inout( ":retout", \$data{'retout'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}




sub DeleteUser
{
	my $t=track TOM::Debug(__PACKAGE__."::DeleteUser()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	return undef unless $env{'user_ID'};
	
	my $sql=qq{
		DECLARE
			anFirmaId NUMBER;
		BEGIN
			dl.pkdlFirma.DeleteFirma
			(
				anFirmaId => :anFirmaId
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	$db0->bind_param(":anFirmaId",$env{'user_ID'});
	
	$db0->execute() || die "$DBI::errstr\n";
	
	$t->close();
	return %data;
}


sub SetMU
{
	my $t=track TOM::Debug(__PACKAGE__."::SetMU()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	return undef unless $env{'user_ID'};
	return undef unless $env{'MU'};
	return undef unless $env{'value'};
	
	# idem menit marketingovy udaj
	my $sql=qq{
		DECLARE
			anFirmaId NUMBER;
			avaKodMu VARCHAR2(10);
			avaHodnotaMu VARCHAR2(1000);
		BEGIN
			dl.pkdlFirmaMu.WriteFirmaMuKod
			(
				anFirmaId => :anFirmaId,
				avaKodMu => :avaKodMu,
				avaHodnotaMu => :avaHodnotaMu
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	die "$DBI::errstr" unless $db0;
	my %data;
	$db0->bind_param(":anFirmaId",$env{'user_ID'});
	$db0->bind_param(":avaKodMu",$env{'MU'});
	$db0->bind_param(":avaHodnotaMu",$env{'value'});
	$db0->execute() || die "$DBI::errstr\n";
	
	$t->close();
	return 1;
}


sub GetUserTelephones
{
	my $t=track TOM::Debug(__PACKAGE__."::GetUserTelephones()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my @data;
	
	return undef unless $env{'user_ID'};
	
	my $sql = qq{
		SELECT
			dl.dl_osoba.osoba_id "person_ID",
			dl.dl_osoba.meno "name",
			dl.dl_osoba.priezvisko "surname",
			dl.dl_telefon.telefonne_cislo "number"
		FROM
			dl.dl_osoba
		LEFT JOIN dl.dl_osoba_telefon ON
		(
			dl.dl_osoba.osoba_id=dl.dl_osoba_telefon.osoba_id
		)
		LEFT JOIN dl.dl_telefon ON
		(
			dl.dl_osoba_telefon.telefon_id=dl.dl_telefon.telefon_id AND
			dl.dl_telefon.typ_telefonu IN ('WORK','MOBILE')
		)
		WHERE
			dl.dl_osoba.firma_id='$env{'user_ID'}' AND
			dl.dl_telefon.telefonne_cislo IS NOT NULL
		ORDER BY dl.dl_osoba.osoba_id
	};
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	$db0->execute();
	
	my $i=0;
	while (my $ref=$db0->fetchrow_hashref())
	{
		main::_log("[$i] person_ID='$ref->{'person_ID'}' name='$ref->{'name'}' surname='$ref->{'surname'}' number='$ref->{'number'}'");
		push @data,$ref;
		$i++;
	}
	
	$t->close();
	return @data;
}


sub GetICDPH
{
	my $t=track TOM::Debug(__PACKAGE__."::GetICDPH()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	my $sql = qq{
		SELECT
			ICDPH_ID,
			FIRMA_ID,
			STAT_ID,
			IC_DPH
		FROM
			dl.dl_ic_dph
		WHERE
			stat_id=1 AND
			firma_id=$env{ID_user}
	};    # Prepare and execute SELECT
	
	#$sql=~s|\$where|$where|;
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'icdph_id'}=$arr[0];
		$data{'firma_id'}=$arr[1];
		$data{'stat_id'}=$arr[2];
		$data{'ic_dph'}=$arr[3];
	}
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	
	return %data;
}


1;