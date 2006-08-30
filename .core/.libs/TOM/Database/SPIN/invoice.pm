package TOM::Database::SPIN::invoice;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use DBI;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Time::Local;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw (&CreateUpfrontInvoice &GetInvoices &GetInvoiceContent &GetDDs);

our $debug=0;
our $debug_disable=0;


sub CreateUpfrontInvoice
{
	my $t=track TOM::Debug(__PACKAGE__."::CreateUpfrontInvoice()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	return undef unless $env{'ID'};
	
	my $sql=qq{
		DECLARE
			anepid NUMBER;
			antypepidfa NUMBER;
			ascommit VARCHAR2(1);
			retout NUMBER;
		BEGIN
			dl.pksoffafromobj.pimpfafromobj1
			(
				anepid => :anepid,
				antypepidfa => :antypepidfa,
				ascommit => :ascommit
			);
		END;
	};
	my $db0 = $main::DB{'spin'}->prepare( $sql );
	
	die "$DBI::errstr" unless $db0;
	
	$db0->bind_param(":anepid",$env{'ID'});
	$db0->bind_param(":antypepidfa",302);
	$db0->bind_param(":ascommit",undef);
	
	#$db0->bind_param_inout( ":retout", \$data{'retout'}, 32 );
	
	$db0->execute() || die "$DBI::errstr\n";
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}

our %dd=
(
	'ZVFT' => 'Vyšlá zálohová faktúra',
	'VFT' => 'Vyšlá faktúra',
	'DFT' => 'Došlá faktúra',
	'DZFT' => 'Došlá zálohová faktúra',
);

sub GetDDs
{
	my $t=track TOM::Debug(__PACKAGE__."::GetDDs()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	my $where;
	my $limit;
	
	$where.="AND \"dl\".dd_ID = $env{'ID'} " if $env{'ID'};
	$where.="AND \"dl\".cr_ID = $env{'cr_ID'} " if $env{'cr_ID'};
	#$where.="AND \"dl\".firma_id = $env{'user_ID'} " if $env{'user_ID'};
	
	
	if ($env{limit} == 1)
	{
		$limit="WHERE NUM=1 ";
	}
	elsif ($env{'limit'})
	{
		my @lim=split(',',$env{'limit'});
		$lim[0]++;
		$lim[1]+=$lim[0];
		$limit="WHERE NUM>=$lim[0] AND NUM<=$lim[1]";
	}
	else
	{
		#$limit="WHERE NUM<=10";
	}
	
	my @data;
	
	my $sql = qq{
		SELECT * FROM
		(
			SELECT
				"dl".dd_id "ID",
				"dl".cr_id "cr_ID",
				"dl".typ_ep_id "type_ID",
				"dl".kod_dd "code",
				row_number() over (order by dd_id) "NUM"
			FROM
				dl.sof_dd "dl"
			WHERE
				"dl".dd_id >= 0
				$where
			ORDER BY
				"dl".dd_id ASC
		) $limit
	};    # Prepare and execute SELECT
	
=head1
	my $sql = qq{
			SELECT
				dd_id,
				cr_id,
				typ_ep_id,
				kod_dd,
				nazov_dd
			FROM
				dl.sof_dd
	};    # Prepare and execute SELECT
=cut
	#main::_log($sql);
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	my $i=0;
	while (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		my %hash;
		
		$hash{'ID'}=$arr[0];
		$hash{'cr_ID'}=$arr[1];
		$hash{'type_ID'}=$arr[2];
		$hash{'code'}=$arr[3];
		#$hash{'name'}=$arr[4];
		
		main::_log("output[$i] ID='$arr[0]' cr_ID='$arr[1]' type_ID='$arr[2]' code='$arr[3]' name='$arr[4]'");
		
		push @data,{%hash};
		$i++;
	}
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return @data;
}


sub GetInvoices
{
	my $t=track TOM::Debug(__PACKAGE__."::GetInvoices()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	my $where;
	my $limit;
	
	$where.="AND \"dl\".ep_id = $env{'ID'} " if $env{'ID'};
	$where.="AND \"dl\".cislo_objednavky = '$env{'order_ID'}' " if $env{'order_ID'};
	$where.="AND \"dl\".firma_id = $env{'user_ID'} " if $env{'user_ID'};
	
	if ($env{limit} == 1)
	{
		$limit="WHERE NUM=1 ";
	}
	elsif ($env{'limit'})
	{
		my @lim=split(',',$env{'limit'});
		$lim[0]++;
		$lim[1]+=$lim[0];
		$limit="WHERE NUM>=$lim[0] AND NUM<=$lim[1]";
	}
	else
	{
		#$limit="WHERE NUM<=10";
	}
	
	my @data;
	
	my $sql = qq{
		SELECT * FROM
		(
			SELECT
				"dl".ep_id "ID",
				"dl".firma_id "user_ID",
				"dl".dd_ID,
				"dl".cislo_dokladu "proof_ID",
				"dl".variabilny_symbol "variable_sym",
				"dl".specificky_symbol "specific_sym",
				"dl".konstantny_symbol "constant_sym",
				"dl".sposob_uhrady "refund",
				"dl".stav_dokladu "status",
				"dl".cislo_objednavky "order_ID",
				
				dl.ffaksumacfs("dl".ep_id) "price_1",
				/*dl.ffaksumacelkovatm("dl".ep_id) "price_1",*/
				/*dl.ffaksumacfswaw("dl".ep_id) "price_1",*/
				dl.ffaksumaZakladov("dl".ep_id) "price_2",
				dl.ffaksumaDphSpolu("dl".ep_id) "price_DPH",
				dl.fdlPsUHradenaSuma("dl".ep_id) "price_4",
				dl.ffaksumahv("dl".ep_id) "price_int",
				
				TO_CHAR("dl".datum_vystavenia,'YYYY-MM-DD') "time_generated",
				TO_CHAR("dl".datum_splatnosti,'YYYY-MM-DD') "time_payback",
				
				row_number() over (order by "dl".datum_vystavenia DESC) "NUM"
			FROM
				dl.sof_faktura "dl"
			WHERE
				"dl".ep_id > 1
				$where
			ORDER BY
				"dl".datum_vystavenia DESC
		) $limit
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
		$hash{'user_ID'}=$arr[1];
		$hash{'dd_ID'}=$arr[2];
		$hash{'proof_ID'}=$arr[3];
		$hash{'variable_sym'}=$arr[4];
		$hash{'specific_sym'}=$arr[5];
		$hash{'constant_sym'}=$arr[6];
		$hash{'refund'}=$arr[7];
		$hash{'status'}=$arr[8];
		$hash{'order_ID'}=$arr[9];
		
		$hash{'price_1'}=$arr[10];
		$hash{'price_2'}=$arr[11];
		$hash{'price_DPH'}=$arr[12];
		$hash{'price_4'}=$arr[13];
		$hash{'price_int'}=$arr[14];
		
		$hash{'time_generated'}=$arr[15];
		$hash{'time_payback'}=$arr[16];
		
		main::_log("output[$i] ID='$arr[0]' proof_ID='$arr[3]' order_ID='$arr[9]' price_1='$arr[10]'");
		
		push @data,{%hash};
		$i++;
	}
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return @data;
}



sub GetInvoiceContent
{
	my $t=track TOM::Debug(__PACKAGE__."::GetInvoiceContent()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	my $where;
	$where.="AND \"fa\".mep_id = $env{'invoice_ID'} " if $env{'invoice_ID'};
	$where.="AND \"fa\".ep_id = $env{'ID'} " if $env{'ID'};
	
	my @data;
		
	my $sql = qq{
		SELECT
			"fa".ep_id "ID",
			"fa".mep_id "invoice_ID",
			"fa".suma "price",
			"fa".mnozstvo "amount",
			"fa".poradie "no",
			"fa".produkt_id "product_ID",
			"text".text_riadku_fa "name",
			"clip".suma_ep "price_EP",
			"sumacm".sumacm "price_CM"
		FROM
			dl.sof_riadok_fa "fa"
		LEFT JOIN dl.sof_text_riadku_fa "text" ON
		(
			"text".ep_id = "fa".ep_id
		)
		LEFT JOIN dl.dl_EP_Clip "clip" ON
		(
			"fa".ep_id = "clip".ep_id
		)
		LEFT JOIN dl.dl_ep_sumacm "sumacm" ON
		(
			"fa".ep_id = "sumacm".ep_id
		)
		WHERE
			"fa".ep_id > 0
			$where
		ORDER BY
			"fa".poradie ASC
	};    # Prepare and execute SELECT
	

	my $sql = qq{
		SELECT
			"fa".ep_id "ID",
			"fa".mep_id "invoice_ID",
			"fa".suma "price",
			"fa".mnozstvo "amount",
			"fa".poradie "no",
			"fa".produkt_id "product_ID",
			"text".text_riadku_fa "name",
			"dan".sadzba_dph "DPH",
			"clip".suma_ep "price_TM",
			"sumacm".sumacm "price_CM"
		FROM
			dl.sof_riadok_fa "fa",
			dl.sof_text_riadku_fa "text",
			dl.dan_typ_polozky_DP "dan",
			dl.dl_ep_clip "clip",
			dl.dl_ep_sumacm "sumacm"
		WHERE
			"fa".ep_id > 0 AND
			"fa".ep_id = "text".ep_id(+) AND
			"fa".ep_id = "clip".ep_id AND
			"fa".ep_id = "sumacm".ep_id(+) AND
			"fa".typ_pdp_id = "dan".rtyp_pdp_id(+)
			$where
		ORDER BY
			"fa".poradie ASC
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
		$hash{'invoice_ID'}=$arr[1];
		$hash{'price'}=$arr[2];
		$hash{'amount'}=$arr[3];
		$hash{'no'}=$arr[4];
		$hash{'product_ID'}=$arr[5];
		$hash{'name'}=$arr[6];
		$hash{'DPH'}=$arr[7];
		
		$hash{'price_TM'}=$arr[8];
		$hash{'price_CM'}=$arr[9];
		
		main::_log("output[$i] ID='$arr[0]' invoice_ID='$arr[1]' price='$arr[2]' amount='$arr[3]' no='$arr[4]' product_id='$arr[5]' name='$arr[6]' DPH='$arr[7]' price_TM='$arr[8]' price_CM='$arr[9]'");
		
		push @data,{%hash};
		$i++;
	}
	
	#foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	$t->close();
	return @data;
}







1;