package TOM::Database::SPIN;

=head1 NAME

TOM::Database::SPIN

=head1 DESCRIPTION

Knižnica k systému SPIN spoločnosti DATALOCK. Táto knižnica prestavuje základnú implementáciu informačného systému SPIN do Cyclone3

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 DEPENDS

knižnice:

 DBI
 TOM::Database::SPIN::address
 TOM::Database::SPIN::user
 TOM::Database::SPIN::order
 TOM::Database::SPIN::purchaser
 TOM::Database::SPIN::invoice
 TOM::Database::SPIN::bank
 TOM::Database::SPIN::product
 TOM::Database::SPIN::price
 Time::Local

ostatné:

=over

=item *

pripojenie k databáze SPIN

=item *

konfigurácie v local.conf

=back

=cut

use DBI;
use TOM::Database::SPIN::address;
use TOM::Database::SPIN::user;
use TOM::Database::SPIN::order;
use TOM::Database::SPIN::purchaser;
use TOM::Database::SPIN::invoice;
use TOM::Database::SPIN::bank;
use TOM::Database::SPIN::product;
use TOM::Database::SPIN::price;
use Time::Local;


=head1 KEYWORDS

Popis vyrazov a klucovych slov pouzivanych v implementacii SPIN do Cyclone3

=head2 VUEP

Volitelny udaj evidencnej polozky

=head2 VUEP

Volitelny udaj evidencnej polozky

=head2 VUEP

Volitelny udaj evidencnej polozky

=cut


=head1 VARIABLES

=over

=item *

$debug

Zapnutie logovania narocnejsich veci. Ide napr. priamo o query na databazu, vsetky volania funkcii, etc...

=item *

%cache

Premenna pre storing vystupov z queries. Islo o cachovanie tychto vystupov, momentalne sa nepouziva. Mozno v buducnosti to bude treba.

=back

=cut

our $debug=0;
our %cache;

=head1 FUNCTIONS

=head2 GetVUEPs()

Vracia pole VUEP

 my $vuep=(TOM::Database::SPIN::GetVUEPs(category=>??))[0];

=over

=item *

ID

vuep_id

=item *

code

=item *

category

=back

=cut
sub GetVUEPs
{
	my $t=track TOM::Debug(__PACKAGE__."::GetVUEPs()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my @data;
	
	my $where;
	$where.="AND vuep_id = $env{'ID'} " if $env{'ID'};
	$where.="AND kod_vuep = '$env{'code'}' " if $env{'code'};
	$where.="AND kategoria = '$env{'category'}' " if $env{'category'};
	$where.="AND kategoria IS NULL " if (exists $env{'category'} && !$env{'category'});
	
	my $sql = qq{
		SELECT
			vuep_id "ID",
			nazov_vuep "name",
			poradie_vuep "number",
			kod_vuep "code",
			kategoria "category"
		FROM
			dl.dl_view_vuep
		WHERE
			typ_ep_id = 380
			$where
		ORDER BY poradie_vuep
	};    # Prepare and execute SELECT
	
	main::_log("sql:=$sql") if $debug;
	
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
		$hash{'number'}=$arr[2];
		$hash{'code'}=$arr[3];
		$hash{'category'}=$arr[4];
		
		main::_log("output[$i] ID='$arr[0]' name='$arr[1]' number='$arr[2]' code='$arr[3]' category='$arr[4]'");
		
		push @data,{%hash};
		$i++;
	}
	
	$t->close();
	return @data;
}

=head2 GetVUEP()

Vracia jednu hodnotu VUEP

=cut

sub GetVUEP
{
	my $t=track TOM::Debug(__PACKAGE__."::GetVUEP()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	return undef unless $env{'code'};
	return undef unless $env{'product_ID'};
	
	my $sql = qq{
		SELECT
			produkt_id,
			dl.ffakvuepvalues(produkt_id,'$env{code}') "value"
		FROM
			dl.sof_view_produkt
		WHERE
			produkt_id='$env{product_ID}'
	};

	main::_log("sql:=$sql") if $debug;
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		my $data=$arr[1];
		main::_log("output value='$data'");
		
		$t->close();
		return $data;
	}
	
	$t->close();
	return undef;
}



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
	
	#my $date=$tom::Fmday.'.'.$Utils::datetime::MONTHS{en}[$tom::Tmom-1].'.'.$tom::Fyear;
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
	
	
#	if ($cache{$sql} && $main::IAdm)
#	{
#		main::_log("returning cached query");
#		$t->close();
#		return $cache{$sql}{'data'};
#	}
	
	
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	my $date=$tom::Fmday.'.'.$Utils::datetime::MONTHS{en}[$tom::Tmom-1].'.'.$tom::Fyear;
	my $date=$tom::Fmday.$tom::Fmom.$tom::Fyear;
	main::_log("date='$date'");
	
	$db0->bind_param(":anFirmaId", $main::USRM{'session'}{'SPIN'}{'ID'} );
	#$db0->bind_param(":anDruhCenyId", $main::USRM{'session'}{'SPIN'}{'price_ID'} );
	$db0->bind_param(":anDruhCenyId", $env{'price_ID'} );
	$db0->bind_param(":anProduktId", $env{'product_ID'} );
	$db0->bind_param(":adDatum", $date );
	$db0->bind_param(":acRetCenaSdph", $env{'tax_DPH'} );
	
	$db0->bind_param_inout( ":retout", \$data, 32 );
	$db0->execute();
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	main::_log("returning price '$data'");
	
#	$cache{$sql}{'data'}=$data;
	$t->close();
	
	return undef unless $data;
	
	return $data;
}


sub GetPriceID
{
	my $t=track TOM::Debug(__PACKAGE__."::GetPriceID()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	
	if ($env{'ID'} == 99)
	{
		$data{name}="XXX";
		$data{macro}="round(if((PRED-DOD)*0.5<(PRED-10%);(PRED-10%);(PRED-DOD)*0.5),2)";
		
		$t->close();
		return %data;
	}
	
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
	
	
	# is this query in cache?
#	if ($cache{$sql} && $main::IAdm)
#	{
#		main::_log("returning cached query");
#		$t->close();
#		return %{$cache{$sql}{'data'}};
#	}
	
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
#	%{$cache{$sql}{'data'}}=%data;
	return %data;
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







=head1
sub GetProductReserved
{
	my $t=track TOM::Debug(__PACKAGE__."::GetProductReserved()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	my $db0=$main::DB{main}->Query("
		SELECT
			a01_order.ID AS IDorder,
			order_product.IDproduct AS IDproduct,
			order_product.amount-order_product.amount_delivered AS reserved
		FROM
			a01_order_product AS order_product
		LEFT JOIN a01_order ON
		(
			a01_order.ID = order_product.IDorder
		)
		WHERE
			a01_order.ID IS NOT NULL
			AND a01_order.delivered='N'
			AND order_product.IDproduct='$env{product_ID}'
			AND (order_product.amount-order_product.amount_delivered)>0
			AND order_product.active='Y'
	");
	
	while (my %db0_line=$db0->fetchhash())
#	while (my %db0_line = $db0->fetchhash())
	{
		main::_log("in order '$db0_line{'IDorder'}' reserved count '$db0_line{'reserved'}'");
		$data{'reserved'}+=$db0_line{'reserved'};
	}
	
#	main::_log
	
	#my %data=$db0->fetchhash();
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return %data;
}
=cut

sub GetProductDocuments
{
	my $t=track TOM::Debug(__PACKAGE__."::GetProductDocuments()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	my $where;
	#my $limit;
	
	$where.="AND \"VW\".ep_id = $env{'product_ID'} " if $env{'product_ID'};
	$where.="AND \"TBL\".cislo = '$env{'ID_sub'}' " if $env{'ID_sub'};
	$where.="AND \"VW\".nazov_typu_dokumentu = '$env{type_name}' " if $env{'type_name'};
	$where.="AND \"VW\".nazov LIKE '%$env{name_plus}' " if $env{'name_plus'};
	
	#$where.="AND kod_produktu = $env{'code'} " if $env{'code'};
	#$where.="AND kategoria_id = $env{'category_ID'} " if $env{'category_ID'};
	#$where.="AND kod_kategorie LIKE '$env{'category_code'}%' " if $env{'category_code'};
	#if ($env{'limit'})
	#{
	#	my @lim=split(',',$env{'limit'});
	#	$lim[0]++;
	#	$lim[1]+=$lim[0];
	#	$limit="WHERE NUM>=$lim[0] AND NUM<=$lim[1]";
	#}
	#else
	#{
	#	$limit="WHERE NUM<=10";
	#}
	
	my @data;
	
	my $sql = qq{
		SELECT
			"VW".dokument_id "ID",
			"VW".nazov "name",
			TO_CHAR("VW".datum_zmeny,'YYYY-MM-DD HH24:MI:SS') "time_change",
			"VW".nazov_typu_dokumentu "type_name",
			"VW".zoznam_pripon_dokumentu "type_ext",
			"VW".ep_id "product_ID",
			"TBL".cislo "ID_sub",
			"TBL".poznamka "description"
		FROM
			dl.dl_view_dokument "VW",
			dl.dl_dok_dokument "TBL"
		WHERE
			"VW".dokument_id = "TBL".dok_dokument_id AND
			"VW".dokument_id>1
			$where
		ORDER BY "TBL".cislo ASC
	};    # Prepare and execute SELECT
	
	#$sql=~s|\$limit|$limit|;
	
	main::_log("sql:=$sql") if $debug;
	
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
		$hash{'time_change'}=$arr[2];
		$hash{'type_name'}=$arr[3];
		$hash{'type_ext'}=$arr[4];
		$hash{'product_ID'}=$arr[5];
		$hash{'ID_sub'}=$arr[6];
		$hash{'description'}=$arr[7];
		
		main::_log("output[$i] ID='$arr[0]' ID_sub='$arr[6]' name='$arr[1]' time_change='$arr[2]' type_name='$arr[3]' type_ext='$arr[4]' product_ID='$arr[5]'");
		
		push @data,{%hash};
		$i++;
	}
	
	$t->close();
	return @data;
}


sub GetDocument
{
	my $t=track TOM::Debug(__PACKAGE__."::GetDocument()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	$env{'ora_auto_lob'} = 0 unless exists $env{'ora_auto_lob'};
	
	my $where;
	
	$where.="AND dok_dokument_id = $env{'ID'} " if $env{'ID'};
	$where.="AND nazov = '$env{'name'}' " if $env{'name'};
	
	my %data;
	#--			TO_DATE(datum_zmeny,'YYYY-MM-DD HH24:MI:SS') "time_change"
	my $sql = qq{
		SELECT
			dok_dokument_id "ID",
			nazov "name",
			poznamka "description",
			dokument "data",
			velkost "size",
			TO_CHAR(datum_zmeny,'YYYY-MM-DD HH24:MI:SS') "time_change"
		FROM
			dl.dl_dok_dokument
		WHERE
			mandant_id >= 0 AND
			ROWNUM = 1
			$where
	};
	
	$sql=~s|\$where|$where|;
	
	main::_log("sql:=$sql") if $debug;
	
	my $db0 = $main::DB{spin}->prepare($sql,{ 'ora_auto_lob' => $env{'ora_auto_lob'} });
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'ID'}=$arr[0];
		$data{'name'}=$arr[1];
		$data{'description'}=$arr[2];
		$data{'data'}=$arr[3];
		$data{'size'}=$arr[4];
		$data{'time_change'}=$arr[5];
		
		$arr[5]=~/(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/;
		main::_log("year=$1 mom=$2 mday=$3 hour=$4 min=$5 sec=$6");
		my $time_change=Time::Local::timelocal($6,$5,$4,$3,$2-1,$1-1900,undef,undef,undef);
		
		main::_log("output ID='$arr[0]' name='$arr[1]' description='$arr[2]' size='$arr[4]' data=length '".length($arr[3])."' time_change='$arr[5]'/$time_change");
		
		if (
				$env{'-get_file'} &&
				$arr[4]>0 &&
				(
					(not -e $env{'-get_file'})||
					(
						(stat($env{'-get_file'}))[10]<$time_change
					)
				)
			)
		{
			main::_log("saving BLOB to file");
			my $chunk_size = 1024*10;   # Arbitrary chunk size, for example
			my $offset = 1;   # Offsets start at 1, not 0
			#my $length=$data{'size'};
			
			open(SPF,'>'.$env{'-get_file'});
			
			my $blob = $main::DB{'spin'}->ora_lob_read( $data{'data'}, 1, $data{'size'});
			print SPF $blob;
			close (SPF);
			
		}
		
		if (
				$env{'-get_data'} &&
				$arr[4]>0
			)
		{
			main::_log("reading BLOB");
			my $chunk_size = 1024*10;   # Arbitrary chunk size, for example
			my $offset = 1;   # Offsets start at 1, not 0
			#my $length=$data{'size'};
			
			#open(SPF,'>'.$env{'-get_file'});
			
			$data{data} = $main::DB{'spin'}->ora_lob_read( $data{'data'}, 1, $data{'size'});
			#print SPF $blob;
			#close (SPF);
			
		}
		
		
		
	}
	
	$t->close();
	return %data;
}


sub saveVUEP_db
{
	my $t=track TOM::Debug("saveVUEP_db",'namespace'=>'SPIN');
	
	my $sql = qq{
		SELECT
			vuep_id "ID",
			kod_vuep "code",
			kategoria "category",
			nazov_vuep "name",
			je_cis_vuep "cis"
		FROM
			dl.dl_view_vuep
	};    # Prepare and execute SELECT
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	$db0->execute();
	
	my $i=0;
	while (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		main::_log("ID='$arr[0]' name='$arr[3]' code='$arr[1]'");
		
		
		my %vuep_available;
		
		# pokial nejde o ciselnikovy VUEP
		# idem overovat ci sa hodnota pouziva v spojeni s niektorym
		# produktom
		if ($arr[4] eq "N")
		{
			main::_log("necis");
			my $vuep_count;
			
			my $sql = qq{
				SELECT
					ep_id AS produkt_id,
					necis_hvuep AS num
				FROM
					dl.dl_ep_vuep
				WHERE
					vuep_id=$arr[0]
				ORDER BY
					num ASC
			};
			my $db1 = $main::DB{spin}->prepare($sql);
			die "$DBI::errstr" unless $db1;
			$db1->execute();
			while (my $arr=$db1->fetch())
			{
				my @arr2=@{$arr};
				
				# pokial tato hodnota vuep je uz uznana, tak ju nepotrebujem overovat znova
				next if $vuep_available{$arr2[1]};
				
				main::_log("produkt_id='$arr2[0]' num='$arr2[1]'");
				
				# tuto hodnotu este nepoznam, overim ci ju pouziva niektory z realnych vyrobkov
				my $product=(TOM::Database::SPIN::GetProducts('ID'=>$arr2[0],limit=>'0,1'))[0];
				if ($product->{ID})
				{
					$vuep_available{$arr2[1]}++;
					$vuep_count++;
				}
			}
			
			# nasleduje hack, ktory by tu nemusel byt ak by SPIN bol trochu sikovnejsi
			# ak zistim ze je len jedina hodnota VUEP, a to 'A', potom logicky
			# existuje aj hodnota 'N' i ked ju nema nastaveny ziaden produkt
			# aj prazdna hodnota je totiz 'N'
			if ($vuep_count == 1 && $vuep_available{'A'})
			{
				main::_log("logicky pridavam num='N'");
				$vuep_available{'N'}=1;
			}
			
		}
		else
		{
			main::_log("jecis");
			my $sql = qq{
				SELECT
					nazov_chvuep "name"
				FROM
					dl.dl_view_chvuep
				WHERE
					vuep_id=$arr[0]
				ORDER BY nazov_chvuep
			};
			my $db1 = $main::DB{spin}->prepare($sql);
			die "$DBI::errstr" unless $db1;
			$db1->execute();
			while (my $arr=$db1->fetch())
			{
				my @arr2=@{$arr};
				# pokial tato hodnota vuep je uznana, tak ju nepotrebujem overovat
				next if $vuep_available{$arr2[1]};
				# tuto hodnotu este nepoznam, overim ci ju pouziva niektory z realnych vyrobkov
				$vuep_available{$arr2[0]}++;
				main::_log("num='$arr2[0]'");
			}
			
		}
		
		
		
		foreach (sort keys %vuep_available)
		{
			$main::DB{main}->Query("
				REPLACE INTO a01_VUEP_values
				(
					VUEP,
					VUEP_code,
					av_value,
					status
				)
				VALUES
				(
					'$arr[0]',
					'$arr[1]',
					'$_',
					'2'
				)
			");
		}
		
	}
	
	$main::DB{main}->Query("DELETE FROM a01_VUEP_values WHERE status=1;");
	$main::DB{main}->Query("UPDATE a01_VUEP_values SET status=1 WHERE status=2;");
	
	$t->close();
	return 1;
}


sub OpenSession
{
	alarm(0);
	
	$main::DB{'spin'}->{LongTruncOk} = 1;
	$main::DB{'spin'}->{LongReadLen} = 1000000;
	$main::DB{'spin'}->do("ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'");
#	$main::DB{'spin'}->do("ALTER SESSION SET NLS_COMP=ANSI");
#	$main::DB{'spin'}->do("ALTER SESSION SET NLS_SORT=BINARY_CI");
	
	my $t=track TOM::Debug("SPIN dl.pkdlconnection.opensession()",'namespace'=>'SPIN');
	my $session_id;
	my $sql = qq{
		DECLARE session_id INTEGER;
		BEGIN
			:session_id := dl.pkdlconnection.opensession(11,10,1);
		END;
	};    # Prepare and execute SELECT
	my $db0 = $main::DB{spin}->prepare($sql);
	$db0->bind_param_inout( ":session_id", \$session_id, 32 );
	$db0->execute();
	
	main::_log("return session_id='".$session_id."'");
	
	my $t0=track TOM::Debug("cache VUEP to memory",'namespace'=>'SPIN');
	
	my $sql = qq{
		SELECT
			vuep_id "ID",
			kod_vuep "code",
			kategoria "category",
			nazov_vuep "name",
			je_cis_vuep "cis"
		FROM
			dl.dl_view_vuep
	};    # Prepare and execute SELECT
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	$db0->execute();
	my $i=0;
	while (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		#main::_log("ID='$arr[0]' name='$arr[3]' code='$arr[1]' category='$arr[2]'");
		foreach my $vuep_cat(split(',',$arr[2]))
		{
			#main::_log("$vuep_cat+='$arr[1]'");
			push @{$vuep_category{$vuep_cat}},{code=>$arr[1],ID=>$arr[0],name=>$arr[3],cis=>$arr[4]};
			# pridam to este vsetkym podkategoriam
			#GetSubcategories('ID'=>$vuep_cat);
		}
	}
	
	$t0->close();
	
	$t->close();
}



our $session_id=TOM::Database::SPIN::OpenSession();


1;

=head1 AUTHOR

Roman Fordinal

=cut