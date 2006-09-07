package TOM::Database::SPIN::product;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Time::Local;

# Export
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw /
	%category
	%vuep
	%vuep_category
	&GetCategories
	&GetSubcategories
	&GetRecategories
	&GetCategories2
	&GetSubcategories2
	&GetProducts
	&GetProductReserved
	&VUEP_array
	/;

our $debug=1;
our $debug_disable=0;

our %vuep_category;
our %vuep;
our %category;


sub GetCategories
{
	my $t=track TOM::Debug(__PACKAGE__."::GetCategories()");
	my %env=@_;
	$env{'status'}=1 unless exists $env{'status'};
	my @data;
	if ($env{ID})
	{
		main::_log("ID='$env{ID}'");
		my $sql=qq{
			SELECT
				*
			FROM
				a01_category
			WHERE
				ID=$env{ID} AND
				status=$env{'status'}
			LIMIT 1
		};
		main::_log("$sql");
		my $db0=$main::DB{'main'}->Query($sql);
		my %db0_line=$db0->fetchhash();
		push @data,{%db0_line};
	}
	elsif ($env{'name_full_rewrite'})
	{
		main::_log("name_full_rewrite");
		my $sql=qq{
			SELECT
				*
			FROM
				a01_category
			WHERE
				name_full_rewrite='$env{'name_full_rewrite'}' AND
				status=$env{'status'}
			LIMIT 1
		};
		main::_log("$sql");
		my $db0=$main::DB{'main'}->Query($sql);
		my %db0_line=$db0->fetchhash();
		push @data,{%db0_line};
	}
	elsif (exists $env{IDre})
	{
		$env{'IDre'}=0 unless $env{'IDre'};
		main::_log("IDre");
		my $sql=qq{
			SELECT
				*
			FROM
				a01_category
			WHERE
				IDre=$env{IDre} AND
				status=$env{'status'}
		};
		main::_log("$sql");
		my $db0=$main::DB{'main'}->Query($sql);
		while (my %db0_line=$db0->fetchhash())
		{
			push @data,{%db0_line};
		}
	}
	$t->close();
	return @data;
}

sub GetSubcategories
{
	my $ID=shift;
	
	my @IDs;
	push @IDs,$ID;
	
	# najdem zoznam kategorii ktore su childy mna
	foreach my $category(GetCategories('IDre'=>$ID))
	{
		push @IDs,GetSubcategories($category->{ID});
	}
	
	return @IDs;
}

sub GetRecategories
{
	my $ID=shift;
	
	return undef unless $ID;
	
	my @IDs;
	
	my $category=(GetCategories('ID'=>$ID))[0];
	push @IDs,$category;
	
	push @IDs,GetRecategories($category->{'IDre'});
	
	#push @IDs,GetSubcategories($category->{ID});
	
	return @IDs;
}



sub GetProducts
{
	my $t=track TOM::Debug(__PACKAGE__."::GetProducts()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	my $where;
	my $limit;
	
	$where.="AND produkt_id = $env{'ID'} " if $env{'ID'};
	$where.="AND internet = 'A' " unless $env{'force'};
	$where.="AND kod_produktu = '$env{'code'}' " if $env{'code'};
	$where.="AND dl.ffakvuepvalues(produkt_id,'0120') = '$env{'special'}' " if $env{'special'};
	$where.="AND dl.ffakvuepvalues(produkt_id,'0006') = '$env{'new'}' " if $env{'new'};
	$where.="AND dl.fsklSumaNaSklade(produkt_id) >= '$env{'skladom'}' " if $env{'skladom'};
	
	# spracovanie vyhladavania podla VUEP
	foreach my $k(keys %env)
	{
		if ($k=~s/^vuep_//)
		{
			my $w;
			
			if ($k eq "0000")
			{
				$w="AND UPPER(dl.ffakvuepvalues(produkt_id,'".$k."')) LIKE UPPER('".$env{'vuep_'.$k}."') ";
				$where.=$w;
				main::_log("plus '$w'");
				next;
			}
			
			# pokial hladam produkt s VUEP ktory ma mat hodnotu 'N',
			# povazuje sa za nu i hodnota prazdna ''
			if ($env{'vuep_'.$k} eq 'N')
			{
				$w="AND ( dl.ffakvuepvalues(produkt_id,'".$k."') LIKE '".$env{'vuep_'.$k}."' OR dl.ffakvuepvalues(produkt_id,'".$k."') IS NULL )";
			}
			else
			{
				# zistim ci ide o skupinu VUEP hodnot podla rozdelenia znakom ';'
				if ($env{'vuep_'.$k}=~/;/)
				{
					my @in=split(';',$env{'vuep_'.$k});
					my $in_out="'".(join "','",@in)."'";
					$w="AND dl.ffakvuepvalues(produkt_id,'".$k."') IN ($in_out) ";
				}
				# alebo ide o rozsah hodnot
				elsif ($env{'vuep_'.$k}=~/-/)
				{
					my @in=split('-',$env{'vuep_'.$k},2);
					$w="AND ( dl.ffakvuepvalues(produkt_id,'".$k."') >= '$in[0]' AND dl.ffakvuepvalues(produkt_id,'".$k."') <= '$in[1]' ) ";
				}
				else
				{
					$w="AND dl.ffakvuepvalues(produkt_id,'".$k."') LIKE '".$env{'vuep_'.$k}."' ";
				}
			}
			
			$where.=$w;
			main::_log("plus '$w'");
		}
	}
	
	$env{'type'}="T" unless $env{'type'};
	$where.="AND typ_produktu = '$env{type}' " if $env{'type'};
	
	if ($env{'type'} eq "T")
	{
		$where.="AND hmotnost_mj>0 ";
	}
	
	if ($env{'name_search'})
	{
		$where.="AND (";
		foreach (split(' ',$env{'name_search'}))
		{
#			$where.="nazov_produktu LIKE '%$_%' AND ";
			$where.="UPPER(nazov_produktu) LIKE UPPER('%$_%') AND ";
#			UPPERCASE(SEARCH) LIKE UPPERCASE('%co%')
		}
		$where=~s|AND $||;
		$where.=") ";
	}
	
	if ($env{'category_ID%'})
	{
		# musim zistit ID vsetkych subkategorii.
		my @IDs=GetSubcategories($env{'category_ID%'});
		my $IDss=join(',',@IDs);
		$where.="AND kategoria_id IN ($IDss)";
	}
	
	$where.="AND kategoria_id = $env{'category_ID'} " if $env{'category_ID'};
	$where.="AND kod_kategorie LIKE '$env{'category_code'}%' " if $env{'category_code'};
	if ($env{'limit'})
	{
		my @lim=split(',',$env{'limit'});
		$lim[0]++;
		$lim[1]+=$lim[0];
		$limit="WHERE NUM>=$lim[0] AND NUM<=$lim[1]";
	}
	else
	{
		$limit="WHERE NUM<=10";
	}
	
	my @data;
	
	my $sql = qq{
		SELECT * FROM
		(
			SELECT
				produkt_id "ID",
				nazov_produktu "name",
				kod_produktu "code",
				sadzba_dph "DPH",
				hmotnost_mj "weight",
				kategoria_id "category_ID",
				kod_kategorie "category_code",
				dl.fsklSumaNaSklade(produkt_id) "amount",
				dl.ffakvuepvalues(produkt_id,'0000') "brand",
				dl.ffakvuepvalues(produkt_id,'0002') "width",
				dl.ffakvuepvalues(produkt_id,'0001') "height",
				dl.ffakvuepvalues(produkt_id,'0003') "depth",
				dl.ffakvuepvalues(produkt_id,'0120') "special",
				dl.ffakvuepvalues(produkt_id,'0004') "name_plus",
				dl.ffakvuepvalues(produkt_id,'0005') "description",
				dl.ffakvuepvalues(produkt_id,'0006') "new",
				
				row_number() over (order by nazov_produktu) "NUM",
				typ_produktu "type"
			FROM
				dl.sof_view_produkt
			WHERE
				mandant_id >= 0
				$where
			ORDER BY nazov_produktu
		)
		$limit
	};    # Prepare and execute SELECT
	
	if ($env{count})
	{
		$sql = qq{
			SELECT
				COUNT(*)
			FROM
				dl.sof_view_produkt
			WHERE
				mandant_id >= 0
				$where
		};
	}
	
#	$sql=~s|\$where|$where|;
#	$sql=~s|\$limit|$limit|;
	
	main::_log("sql:=$sql") if $debug;
	
	
#	if ($cache{$sql} && $main::IAdm)
#	{
#		main::_log("returning cached query");
#		$t->close();
#		return @{$cache{$sql}{'data'}};
#	}
	
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	if ($env{count})
	{
		my $arr=$db0->fetch();
		my @arr=@{$arr};
		$t->close();
		return $arr[0];
	}
	
	my $i=0;
	while (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		my %hash;
		$hash{'ID'}=$arr[0];
		$hash{'name'}=$arr[1];
		$hash{'code'}=$arr[2];
		$hash{'DPH'}=$arr[3];
		$hash{'weight'}=$arr[4];
		$hash{'category_ID'}=$arr[5];
		$hash{'category_code'}=$arr[6];
		$hash{'amount'}=$arr[7];
		
		$hash{'brand'}=$arr[8];
		$hash{'width'}=$arr[9];
		$hash{'height'}=$arr[10];
		$hash{'depth'}=$arr[11];
		$hash{'special'}=$arr[12];
		$hash{'name_plus'}=$arr[13];
		$hash{'description'}=$arr[14];
		$hash{'new'}=$arr[15];
		$hash{'type'}=$arr[17];
		
		main::_log("output[$i] ID='$arr[0]' name='$arr[1]' name_plus='$arr[13]' description='$arr[14]' code='$arr[2]' DPH='$arr[3]' weight='$arr[4]' category_ID='$arr[5]' category_code='$arr[6]' amount='$arr[7]' brand='$arr[8]' WxHxD='$arr[9]x$arr[10]x$arr[11]' special='$arr[12]' new='$arr[15]'");
		
		#fsofGetRabat('user_ID'=>$main::USRM{'session'}{'SPIN'}{'ID'},'product_ID'=>$hash{'ID'});
		
		push @data,{%hash};
		$i++;
	}
	
	$t->close();
	#@{$cache{$sql}{'data'}}=@data;
	return @data;
}


sub VUEP_array
{
	my $hash=shift;
	my %env=@_;
	
	$env{'max'}=10 unless $env{'max'};
	
	my $count=keys %{$hash};
	main::_log("keys counted '$count'");
	
	my $div=int($count/$env{'max'});
	
	$div=$env{'min_div'} if $div<$env{'min_div'};
	
	main::_log("divided by '$div'");
	
	my @output;
	
	my $i;
	my @arr;
	my $first;
	foreach my $kk(sort {TOM::Utils::vars::s_sort($hash->{$a},$hash->{$b})} keys %{$hash})
	{
		$i++;
		push @arr,$hash->{$kk};
		$first=$hash->{$kk} unless $first;
		
		if (not ($i % $div) || ($i == $count))
		{
			my $arr_out=join ";",@arr;
			push @output, ["$first - $hash->{$kk}",$arr_out];
			# vyprazdnenie
			@arr=();
			$first=undef;
		}
		
	}
	
	return @output;
}


sub GetProductReserved
{
	my $t=track TOM::Debug(__PACKAGE__."::GetProductReserved()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	my $sql = qq{
		SELECT
			"prod".mep_id "ID_order",
			"prod".produkt_id "ID_product",
			"prod".mnozstvo "amount",
			"prod".dod_mnozstvo "amount_delivered",
			"prod".mnozstvo-"prod".dod_mnozstvo "reserved"
		FROM
			dl.sof_riadok_obj "prod"
		WHERE
			"prod".produkt_id = $env{product_ID} AND
			"prod".dod_mnozstvo < "prod".mnozstvo
	};
	
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	$db0->execute();
	while (my $ref=$db0->fetchrow_hashref())
	{
		main::_log("ID_order='$ref->{'ID_order'}' amount='$ref->{'amount'}' amount_delivered='$ref->{'amount_delivered'}' reserved='$ref->{'reserved'}'");
		$data{'reserved'}+=$ref->{'reserved'};
	}
	
	foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
	
	$t->close();
	return %data;
}

1;