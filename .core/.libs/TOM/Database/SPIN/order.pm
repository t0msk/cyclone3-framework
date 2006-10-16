package TOM::Database::SPIN::order;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use DBI;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Time::Local;
use TOM::Database::SQL;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw (&GetOrders &GetOrderProducts &fsklWriteObj &fsklWriteRObj &fsklDeleteObj &fsklDeleteRObj &CheckCycloneOrder);

our $debug=0;
our $debug_disable=0;



sub GetOrders
{
	my $t=track TOM::Debug(__PACKAGE__."::GetOrders()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	#return undef unless $env{ID};
	
	my $where;
	
	$where.="AND \"obj\".firma_id = $env{ID_user} " if $env{ID_user};
	$where.="AND \"obj\".ep_id = $env{ID} " if $env{ID};
	$where.="AND \"obj\".cislo_doslobj = '$env{ID_cyclone}' " if $env{ID_cyclone};
	$where.="AND \"obj\".cislo_doslobj IS NULL " if (!$env{ID_cyclone} && exists $env{ID_cyclone});
	$where.="AND \"obj\".stav_dokladu <> 3 " if $env{'opened'};
	$where.="AND \"obj\".stav_dokladu = $env{status} " if $env{'status'};
	
	if ($env{limit} == 1)
	{
		$where.="AND ROWNUM=1 ";
	}
	
	#$where.="AND \"tbl\".rfirma_id = $env{parent_ID} " if $env{parent_ID};
	#$where.="AND dl.pkdlFirmaMu.GetFirmaMuKodHodnota(\"dl\".firma_id,'0005') = '$env{mu_login}' " if $env{mu_login};
	#$where.="AND dl.pkdlFirmaMu.GetFirmaMuKodHodnota(\"dl\".firma_id,'aktivny') = '$env{mu_login}' " if $env{mu_active};
	
	my @data;
	
	my $sql = qq{
		SELECT
			"obj".ep_id "ID",
			"obj".cislo_doslobj "ID_cyclone",
			"obj".firma_id "ID_user",
			TO_CHAR("obj".datum_vystavenia,'YYYY-MM-DD HH24:MI:SS') "time_create",
			TO_CHAR("obj".datum_plnenia,'YYYY-MM-DD HH24:MI:SS') "time_inquiry",
			"obj".stav_dokladu "status",
			"obj".kod_dopravy "transport_type"
		FROM
			dl.sof_objednavka "obj"
		WHERE
			"obj".mena_id = 1
			$where
	};    # Prepare and execute SELECT
	
	#$sql=~s|\$where|$where|;
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	my $i=0;
	while (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		my %hash;
		$hash{'ID'}=$arr[0];
		$hash{'ID_cyclone'}=$arr[1];
		$hash{'ID_user'}=$arr[2];
		$hash{'time_create'}=$arr[3];
		$hash{'time_inquiry'}=$arr[4];
		$hash{'status'}=$arr[5];
		$hash{'transport_type'}=$arr[6];
		
		main::_log("output[$i] ID='$arr[0]' ID_cyclone='$arr[1]' ID_user='$arr[2]' time_create='$arr[3]' time_inquiry='$arr[4]' status='$arr[5]' transport_type='$arr[6]'");
		
		push @data,{%hash};
		$i++;
	}
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return @data;
}




sub GetOrderProducts
{
	my $t=track TOM::Debug(__PACKAGE__."::GetOrderProducts()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	#return undef unless $env{ID};
	
	my $where;
	
#	$where.="AND \"obj\".firma_id = $env{ID_user} " if $env{ID_user};
	$where.="AND \"prod\".produkt_id = $env{ID_product} " if $env{ID_product};
	$where.="AND \"prod\".mep_id = $env{ID_order} " if $env{ID_order};
	$where.="AND \"prod\".dod_mnozstvo == 0 " if $env{notdelivered};
	$where.="AND \"prod\".dod_mnozstvo > 0 " if $env{delivered};
	$where.="AND \"prod\".dod_mnozstvo < \"prod\".dod_mnozstvo " if $env{notdelivered_full};
	$where.="AND \"prod\".dod_mnozstvo == \"prod\".dod_mnozstvo " if $env{delivered_full};
#	$where.="AND \"obj\".cislo_doslobj = '$env{ID_cyclone}' " if $env{ID_cyclone};
#	$where.="AND \"obj\".stav_dokladu <> 3 " if $env{'opened'};
#	$where.="AND \"obj\".stav_dokladu = $env{status} " if $env{'status'};
	
	if ($env{limit} == 1)
	{
		$where.="AND ROWNUM=1 ";
	}
	
	#$where.="AND \"tbl\".rfirma_id = $env{parent_ID} " if $env{parent_ID};
	#$where.="AND dl.pkdlFirmaMu.GetFirmaMuKodHodnota(\"dl\".firma_id,'0005') = '$env{mu_login}' " if $env{mu_login};
	#$where.="AND dl.pkdlFirmaMu.GetFirmaMuKodHodnota(\"dl\".firma_id,'aktivny') = '$env{mu_login}' " if $env{mu_active};
	
	my @data;
	
	my $sql = qq{
		SELECT
			"prod".ep_id "ID",
			"prod".mep_id "ID_order",
			"prod".produkt_id "ID_product",
			"prod".mnozstvo "amount",
			"prod".dod_mnozstvo "amount_delivered",
			TO_CHAR("prod".datum_plnenia,'YYYY-MM-DD HH24:MI:SS') "time_inquiry",
			"prod".mnozstvo_original "amount_original",
			"prod".cena "price"
		FROM
			dl.sof_riadok_obj "prod"
		WHERE
			"prod".ep_id > 1
			$where
	};    # Prepare and execute SELECT
	
	#$sql=~s|\$where|$where|;
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	my $i=0;
	while (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		my %hash;
		$hash{'ID'}=$arr[0];
		$hash{'ID_order'}=$arr[1];
		$hash{'ID_product'}=$arr[2];
		$hash{'amount'}=$arr[3];
		$hash{'amount_delivered'}=$arr[4];
		$hash{'time_inquiry'}=$arr[5];
		$hash{'price'}=$arr[7];
		
		main::_log("output[$i] ID='$arr[0]' ID_order='$arr[1]' ID_product='$arr[2]' amount='$arr[3]' amount_delivered='$arr[4]' time_inquiry='$arr[5]' price='$arr[7]'");
		
		push @data,{%hash};
		$i++;
	}
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return @data;
}


sub fsklWriteObj
{
	my $t=track TOM::Debug(__PACKAGE__."::fsklWriteObj()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	my %dph=&TOM::Database::SPIN::GetICDPH('ID_user'=>$main::USRM{'session'}{'SPIN'}{'ID'});
	
	return undef unless $env{'ID'};
	$env{'ID'} = sprintf("%06d",$env{'ID'});
	
	my $sql=qq{
		DECLARE
			retout NUMBER;
			aiTypEPid INTEGER;
			anMandantid NUMBER;
			anEPid NUMBER;
			anVEPid NUMBER;
			acTypvazbyE VARCHAR2(1);
			anVNEPid NUMBER;
			acTypvazbyN VARCHAR2(1);
			anOsobaid NUMBER;
			anMenaid NUMBER;
			anDDid NUMBER;
			acCisloDokladu VARCHAR2(20);
			anFirmaid NUMBER;
			adtDatumVystavenia DATE;
			adtDatumPlnenia DATE;
			anOdberatelid NUMBER;
			acStavDokladu VARCHAR2(1);
			acCisloDoslobj VARCHAR2(30);
			acCisloZmluvy VARCHAR2(20);
			acKodDodavky VARCHAR2(5);
			acKodDopravy VARCHAR2(5);
			acObjednal VARCHAR2(50);
			anDruhCenyid NUMBER;
			adRabat NUMBER(5,2);
			adRabat2 NUMBER(5,2);
			adSplatnost NUMBER(38);
			acStavImex VARCHAR2(1);
			anSmerdavkalogid NUMBER;
			anOrgId NUMBER;
			acEO VARCHAR2(32);
			acErrMsg VARCHAR2(32);
			anSkladid NUMBER;
			anDPid INTEGER;
			anInterstatid INTEGER;
			anIntICDPHid INTEGER;
			anextICDPHid INTEGER;
		BEGIN
			:retout := dl.pksklObjednavka.fsklWriteObj
			(
				:aiTypEPid,
				:anMandantid,
				:anEPid,
				:anVEPid,
				:acTypvazbyE,
				:anVNEPid,
				:acTypvazbyN,
				:anOsobaid,
				:anMenaid,
				:anDDid,
				:acCisloDokladu,
				:anFirmaid,
				:adtDatumVystavenia,
				:adtDatumPlnenia,
				:anOdberatelid,
				:acStavDokladu,
				:acCisloDoslobj,
				:acCisloZmluvy,
				:acKodDodavky,
				:acKodDopravy,
				:acObjednal,
				:anDruhCenyid,
				:adRabat,
				:adRabat2,
				:adSplatnost,
				:acStavImex,
				:anSmerdavkalogid,
				:anOrgId,
				:acEO,
				:acErrMsg,
				:anSkladid,
				:anDPid,
				:anInterstatid,
				:anIntICDPHid,
				:anextICDPHid
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	#my $date=$tom::Fmday.'.'.$Utils::datetime::MONTHS{en}[$tom::Tmom-1].'.'.$tom::Fyear;
	my $date=$tom::Fmday.$tom::Fmom.$tom::Fyear;
	
	my %dateh=Utils::datetime::ctodatetime($main::time_current+(86400*31),format=>1);
	#my $date2=$dateh{year}.$dateh{mon}.$dateh{mday};
	my $date2=$dateh{mday}.$dateh{mon}.$dateh{year};
	
	main::_log("date='$date' => '$date2'");
	
	$db0->bind_param(":aiTypEPid",360); # tyb EP = dosla objednavka
	$db0->bind_param(":anMandantid",1); # prvy spravca
#	$db0->bind_param(":anEPid",);
	$db0->bind_param(":anVEPid",undef);
	$db0->bind_param(":acTypvazbyE",undef);
	$db0->bind_param(":anVNEPid",undef);
	$db0->bind_param(":acTypvazbyN",undef);
	$db0->bind_param(":anOsobaid",undef);
	$db0->bind_param(":anMenaid",undef);
	$db0->bind_param(":anDDid",21); # typ danoveho dokladu
#	$db0->bind_param(":acCisloDokladu",);
	$db0->bind_param(":anFirmaid",$main::USRM{'session'}{'SPIN'}{'ID'}); # firma ktora vytvara objednavku
	$db0->bind_param(":adtDatumVystavenia",$date);
	$db0->bind_param(":adtDatumPlnenia",$date2);
	$db0->bind_param(":anOdberatelid",$main::USRM{'session'}{'SPIN'}{'purchaser_ID'}); # firma ktora si objednava evidovana ako odberatel
	$db0->bind_param(":acStavDokladu",1); # otvoreny doklad
	$db0->bind_param(":acCisloDoslobj","ES".$env{'ID'});
	$db0->bind_param(":acCisloZmluvy",undef);
	$db0->bind_param(":acKodDodavky",undef);
	$db0->bind_param(":acKodDopravy",$env{'acKodDopravy'});
	$db0->bind_param(":acObjednal",undef);
	$db0->bind_param(":anDruhCenyid",$main::USRM{'session'}{'SPIN'}{'price_ID'});
	$db0->bind_param(":adRabat",$main::USRM{'session'}{'SPIN'}{'purchaser_rebate1'});
	$db0->bind_param(":adRabat2",$main::USRM{'session'}{'SPIN'}{'purchaser_rebate2'});
	$db0->bind_param(":adSplatnost",$main::USRM{'session'}{'SPIN'}{'purchaser_payback'} || 14);
	$db0->bind_param(":acStavImex",undef);
	$db0->bind_param(":anSmerdavkalogid",undef);
	$db0->bind_param(":anOrgId",26); # firma od ktorej sa objednava = ProELEKTRO
	$db0->bind_param(":acEO",undef);
#	$db0->bind_param(":acErrMsg",);
	$db0->bind_param(":anSkladid",undef);
	$db0->bind_param(":anDPid",undef);
	$db0->bind_param(":anInterstatid",1);
	$db0->bind_param(":anIntICDPHid",1);
	$db0->bind_param(":anextICDPHid",$dph{'icdph_id'});
	
	$db0->bind_param_inout( ":anEPid", \$data{'anEPid'}, 32 );
	$db0->bind_param_inout( ":acCisloDokladu", \$data{'acCisloDokladu'}, 32 );
	$db0->bind_param_inout( ":acErrMsg", \$data{'acErrMsg'}, 256 );
	$db0->bind_param_inout( ":retout", \$data{'retout'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	main::_log("(order) insert SPIN order anEPid='$data{'anEPid'}' acCisloDoslobj='ES$env{'ID'}' acCisloDokladu='$data{'acCisloDokladu'}' anFirmaid='$main::USRM{'session'}{'SPIN'}{'ID'}' anDruhCenyid='$main::USRM{'session'}{'SPIN'}{'price_ID'}'",4,"eshop");
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}


sub fsklWriteRObj
{
	my $t=track TOM::Debug(__PACKAGE__."::fsklWriteRObj()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
#	my %dph=&GetICDPH('ID_user'=>$main::USRM{'session'}{'SPIN'}{'ID'});
	
	#return undef unless $env{'ID'};
	return undef unless $env{'anMEPid'};
	#$env{'ID'} = sprintf("%06d",$env{'ID'});
	
	my $sql=qq{
		DECLARE
			retout NUMBER;
			aiTypEPid INTEGER;
			anMandantid NUMBER;
			anEPid NUMBER;
			anMEPid NUMBER;
			anVEPid NUMBER;
			acTypvazbyE VARCHAR2(1);
			anVNEPid NUMBER;
			acTypvazbyN VARCHAR2(1);
			anProduktid NUMBER;
			adMnozstvo NUMBER;
			adMnozstvoOriginal NUMBER;
			adMnozstvo2 NUMBER;
			adMnozstvoDod NUMBER;
			adCena NUMBER;
			adRabat1 NUMBER;
			adTypRabatu1 VARCHAR2(1);
			adRabat2 NUMBER;
			adTypRabatu2 VARCHAR2(1);
			anDruhCenyid NUMBER;
			anTypPDPid NUMBER;
			adtDatumPln DATE;
			adtObjednatOd DATE;
			adtDatumOriginal DATE;
			adtDatumPotvrdenia DATE;
			acRezervacia VARCHAR2(1);
			anZostavaid NUMBER;
			aiPoradie INTEGER;
			anOrgId NUMBER;
			acEO VARCHAR2(1);
			acErrMsg VARCHAR2(1);
			adKoefMJMJ2 NUMBER;
			ackodMJ2 VARCHAR2(1);
		BEGIN
			:retout := dl.pksklObjednavka.fsklWriteRObj
			(
				:aiTypEPid,
				:anMandantid,
				:anEPid,
				:anMEPid,
				:anVEPid,
				:acTypvazbyE,
				:anVNEPid,
				:acTypvazbyN,
				:anProduktid,
				:adMnozstvo,
				:adMnozstvoOriginal,
				:adMnozstvo2,
				:adMnozstvoDod,
				:adCena,
				:adRabat1,
				:adTypRabatu1,
				:adRabat2,
				:adTypRabatu2,
				:anDruhCenyid,
				:anTypPDPid,
				:adtDatumPln,
				:adtObjednatOd,
				:adtDatumOriginal,
				:adtDatumPotvrdenia,
				:acRezervacia,
				:anZostavaid,
				:aiPoradie,
				:anOrgId,
				:acEO,
				:acErrMsg,
				:adKoefMJMJ2,
				:ackodMJ2
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	#my $date=$tom::Fmday.'.'.$Utils::datetime::MONTHS{en}[$tom::Tmom-1].'.'.$tom::Fyear;
	my $date=$tom::Fmday.$tom::Fmom.$tom::Fyear;
	
	my %dateh=Utils::datetime::ctodatetime($main::time_current+(86400*31),format=>1);
	my $date2=$dateh{year}.$dateh{mon}.$dateh{mday};
	my $date2=$dateh{mday}.$dateh{mon}.$dateh{year};
	
	main::_log("date='$date' => '$date2'");
	
#	my $price=&fsofGetPrice('product_ID'=>$env{'anProduktid'})
#				|| &fsofGetPrice('product_ID'=>$env{'anProduktid'},'price_ID'=>1);
	
	my $price_ID=$main::USRM{'session'}{'SPIN'}{'price_ID'} || 2;
#	my $price;
	
	
	my $price=$env{'price'} || macro::get_price
	(
		'ID'=>$price_ID,
		'product_ID'=>$env{'anProduktid'},
		'category_ID'=>$env{'category_ID'},
		'brand'=>$env{'brand'}
	);
	
	my %rebate=TOM::Database::SPIN::fsofGetRabat
	(
		'user_ID'=>$main::USRM{'session'}{'SPIN'}{'ID'},
		'product_ID'=>$env{'anProduktid'},
		'category_ID'=>$env{'category_ID'}
	) unless $env{'price'};
	
	$db0->bind_param(":aiTypEPid",361); # tovar v objednavke
	$db0->bind_param(":anMandantid",1);
#	$db0->bind_param(":anEPid",undef);
	$db0->bind_param(":anMEPid",$env{'anMEPid'});
	$db0->bind_param(":anVEPid",undef);
	$db0->bind_param(":acTypvazbyE",undef);
	$db0->bind_param(":anVNEPid",undef);
	$db0->bind_param(":acTypvazbyN",undef);
	$db0->bind_param(":anProduktid",$env{'anProduktid'});
	$db0->bind_param(":adMnozstvo",$env{'adMnozstvo'});
	$db0->bind_param(":adMnozstvoOriginal",$env{'adMnozstvo'});
	$db0->bind_param(":adMnozstvo2",undef);
	$db0->bind_param(":adMnozstvoDod",undef);
	$db0->bind_param(":adCena",$price);
	$db0->bind_param(":adRabat1",$rebate{'rebate'});
	$db0->bind_param(":adTypRabatu1",$rebate{'rebate_type'});
	$db0->bind_param(":adRabat2",$rebate{'rebate2'});
	$db0->bind_param(":adTypRabatu2",$rebate{'rebate_type2'});
	$db0->bind_param(":anDruhCenyid",$main::USRM{'session'}{'SPIN'}{'price_ID'});
	$db0->bind_param(":anTypPDPid",undef);
	$db0->bind_param(":adtDatumPln",$date2);
	$db0->bind_param(":adtObjednatOd",undef);
	$db0->bind_param(":adtDatumOriginal",$date2);
	$db0->bind_param(":adtDatumPotvrdenia",undef);
	$db0->bind_param(":acRezervacia",undef);
	$db0->bind_param(":anZostavaid",undef);
	$db0->bind_param(":aiPoradie",undef);
	$db0->bind_param(":anOrgId",undef);
	$db0->bind_param(":acEO",undef);
#	$db0->bind_param(":acErrMsg",undef);
	$db0->bind_param(":adKoefMJMJ2",undef);
	$db0->bind_param(":ackodMJ2",undef);
	
	$db0->bind_param_inout( ":anEPid", \$data{'anEPid'}, 32 );
	$db0->bind_param_inout( ":acErrMsg", \$data{'acErrMsg'}, 256 );
	$db0->bind_param_inout( ":retout", \$data{'retout'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	main::_log("(order) insert SPIN order product anEPid='$data{'anEPid'}' anMEPid='$env{'anMEPid'}' anProduktid='$env{'anProduktid'}' adMnozstvo='$env{'adMnozstvo'}' anDruhCenyid='$main::USRM{'session'}{'SPIN'}{'price_ID'}'",4,"eshop");
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}

sub fsklDeleteObj
{
	my $t=track TOM::Debug(__PACKAGE__."::fsklDeleteObj()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	my $sql=qq{
		DECLARE
			retout NUMBER;
			anEPid NUMBER;
			acErrMsg VARCHAR2(32);
		BEGIN
			:retout := dl.pksklObjednavka.fsklDeleteObj
			(
				:anEPid,
				:acErrMsg
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	$db0->bind_param(":anEPid",$env{'anEPid'});
	
	$db0->bind_param_inout( ":acErrMsg", \$data{'acErrMsg'}, 256 );
	$db0->bind_param_inout( ":retout", \$data{'retout'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	main::_log("(order) delete SPIN order anEPid='$env{'anEPid'}'",4,"eshop");
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}

sub fsklDeleteRObj
{
	my $t=track TOM::Debug(__PACKAGE__."::fsklDeleteRObj()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	my $sql=qq{
		DECLARE
			retout NUMBER;
			anEPid NUMBER;
			acErrMsg VARCHAR2(32);
		BEGIN
			:retout := dl.pksklObjednavka.fsklDeleteRObj
			(
				:anEPid,
				:acErrMsg
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	$db0->bind_param(":anEPid",$env{'anEPid'});
	
	$db0->bind_param_inout( ":acErrMsg", \$data{'acErrMsg'}, 256 );
	$db0->bind_param_inout( ":retout", \$data{'retout'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	main::_log("(order) delete SPIN order product anEPid='$env{'anEPid'}'",4,"eshop");
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}


sub CheckCycloneOrder
{
	my $t=track TOM::Debug(__PACKAGE__."::CheckCycloneOrder()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	if (!$env{'ID'})
	{
		main::_log("missing input ID");
		$t->close();
		return undef;
	}
	
	$env{'ID'}=sprintf("%06d",$env{'ID'});
	
	my $order;
		# toto robim preto aby som nemusel tahat informacie o objednavke zo SPIN-u vo funkcii
		# ked uz cislo objednavky v SPIN-e poznam pri volani funkcie CheckCycloneOrder
		$order->{'ID'}=$env{'ID_SPIN'} if $env{'ID_SPIN'};
		if (!$order->{'ID'})
		{
			$order=(TOM::Database::SPIN::GetOrders('ID_cyclone'=>'ES'.$env{'ID'},'limit'=>1))[0];
		}
	
	
	if (!$order->{'ID'})
	{
		main::_log("can't find order in SPIN");
		$t->close();
		return undef;
	}
	
	#return undef unless $order->{'ID'};
	
	main::_log("search for missing ordered products in Cyclone3");
	
	my %pp;
	
	foreach my $product (TOM::Database::SPIN::GetOrderProducts('ID_order'=>$order->{ID}))
	{
		main::_log("product ID='$product->{ID_product}' amount='$product->{amount}' price='$product->{price}'");
		
		$pp{$product->{'ID_product'}}=1;
		
		my $dbx=$main::DB{main}->Query("
			SELECT *
			FROM a01_order_product
			WHERE
				IDorder='$env{ID}'
				AND IDproduct='$product->{ID_product}'
			LIMIT 1
		");
		if (my %dbx_line=$dbx->fetchhash())
		{
			# checkujem aj cenu produktu v objednavke ale len v pripade ak
			# do samotnej objednavky bol pridany produkt uplne bez ceny
			if (($dbx_line{'price'} ne $product->{'price'})&&(!$dbx_line{'price'}))
			{
				main::_log("price in Cyclone3 ('$dbx_line{'price'}') not equal to price in SPIN ('$product->{'price'}')");
				
				main::_log("(check) change price '$dbx_line{'price'}' to '$product->{'price'}' in Cyclone3 order WHERE IDorder='$env{ID}' AND IDproduct='$product->{ID_product}'",4,"eshop");
				
				$main::DB{'main'}->Query("
					UPDATE
						a01_order_product
					SET
						price=".($product->{'price'}).",
						price_full=".($product->{'price'}*1.19)."
					WHERE
						IDorder='$env{ID}'
						AND IDproduct='$product->{ID_product}'
					LIMIT 1
				");
			}
		}
		else
		{
			main::_log("this product is not in Cyclone3, inserting");
			# hladanie produktu
			if (my $productx=(TOM::Database::SPIN::GetProducts('ID'=>$product->{'ID_product'},force=>1))[0])
			{
				main::_log("inserting product type='T'");
				main::_log("(check) insert Cyclone3 order product IDorder='$env{ID}' IDproduct='$productx->{'ID'}' amount='$product->{'amount'}' type='T'",4,"eshop");
				my $dbx=$main::DB{main}->Query("
					INSERT INTO a01_order_product
					(
						IDorder,
						IDproduct,
						IDcategory,
						name,
						amount,
						amount_delivered,
						weight,
						width,
						height,
						depth,
						price
					)
					VALUES
					(
						'$env{ID}',
						'$productx->{'ID'}',
						'$productx->{'category_ID'}',
						'".TOM::Database::SQL::escape($productx->{'name'})."',
						'$product->{'amount'}',
						'0',
						'$productx->{'weight'}',
						'$productx->{'width'}',
						'$productx->{'height'}',
						'$productx->{'depth'}',
						'$productx->{'price'}'
					)
				") || die $dbx->errstr();
			}
			# hladanie sluzby
			elsif (my $productx=(TOM::Database::SPIN::GetProducts('ID'=>$product->{'ID_product'},force=>1,type=>'S'))[0])
			{
				main::_log("inserting product type='S'");
				main::_log("(check) insert Cyclone3 order product IDorder='$env{ID}' IDproduct='$productx->{'ID'}' type='S'",4,"eshop");
				my $dbx=$main::DB{main}->Query("
					INSERT INTO a01_order_product
					(
						IDorder,
						IDproduct,
						IDcategory,
						type,
						name,
						amount,
						amount_delivered,
						weight,
						width,
						height,
						depth
					)
					VALUES
					(
						'$env{ID}',
						'$productx->{'ID'}',
						'$productx->{'category_ID'}',
						'S',
						'$productx->{'name'}',
						'$product->{'amount'}',
						'0',
						'',
						'',
						'',
						'',
						'$productx->{'price'}'
					)
				") || die $dbx->errstr();
			}
			else
			{
				main::_log("can't find product in SPIN");
			}
		}
		
	}
	
	my $dbx=$main::DB{main}->Query("
		SELECT *
		FROM a01_order_product
		WHERE
			IDorder='$env{ID}'
		");
	while (my %dbx_line=$dbx->fetchhash())
	{
		if ((!$pp{$dbx_line{'IDproduct'}}) && ($dbx_line{'active'} ne "N"))
		{
			main::_log("product ID='$dbx_line{'IDproduct'}' is missing in SPIN ");
			main::_log("(check) change Cyclone3 order product IDorder='$env{ID}' IDproduct='$dbx_line{'IDproduct'}' SET active='N' ($dbx_line{'active'}) (product is missing in SPIN)",4,"eshop");
			$main::DB{main}->Query("
				UPDATE a01_order_product
				SET active='N'
				WHERE
					IDorder='$env{ID}' AND
					IDproduct='$dbx_line{'IDproduct'}'
				LIMIT 1
			");
			
		}
		elsif (($pp{$dbx_line{'IDproduct'}}) && ($dbx_line{'active'} ne "Y"))
		{
			main::_log("product ID='$dbx_line{'IDproduct'}' found in SPIN ");
			main::_log("(check) change Cyclone3 order product IDorder='$env{ID}' IDproduct='$dbx_line{'IDproduct'}' SET active='Y' ($dbx_line{'active'}) (product found in SPIN)",4,"eshop");
			$main::DB{main}->Query("
				UPDATE a01_order_product
				SET active='Y'
				WHERE
					IDorder='$env{ID}' AND
					IDproduct='$dbx_line{'IDproduct'}'
				LIMIT 1
			");
		}
	}
	
	$t->close();
	return 1;
}


1;