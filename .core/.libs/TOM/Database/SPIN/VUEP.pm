package TOM::Database::SPIN::VUEP;

=head1 NAME

TOM::Database::SPIN::VUEP

=head1 DESCRIPTION

Knižnica správy voliteľných údajov evidenčných položiek

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
		&GetVUEPs
		&GetVUEP
		&saveVUEP_db
	/;


our $debug=0;


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


=head2 saveVUEP_db()



=cut

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
	};
	
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




1;