package TOM::Database::SPIN::document;

=head1 NAME

TOM::Database::SPIN::document

=head1 DESCRIPTION

Práca s dokumentami v SPIN

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw /
		&GetProductDocuments
		&GetDocument
	/;

our $debug=0;

=head1 FUNCTIONS

=head2 GetProductDocuments()

Vracia zoznam dokumentov priradených k produktu

 my $doc=(TOM::Database::SPIN::GetProductDocuments())[0];

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

=head2 GetDocument()

Vracia vyžadovaný dokument alebo súbor

=cut

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


1;