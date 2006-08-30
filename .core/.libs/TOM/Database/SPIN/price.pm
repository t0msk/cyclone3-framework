package TOM::Database::SPIN::price;

=head1 NAME

TOM::Database::SPIN::price

=head1 DESCRIPTION

Knižnica správy cien systému SPIN spoločnosti DATALOCK.

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
our @EXPORT = qw (&GetRebate);


=head1 VARIABLES

=over

=item *

$debug

Zapnutie logovania narocnejsich veci. Ide napr. priamo o query na databazu, vsetky volania funkcii, etc...

=back

=cut

our $debug=0;


=head1 FUNCTIONS

=head2 GetRebate()

Vracia hash s informaciami o rabate. Funkcia momentálne nenarába s časovým rozsahom.

 my %rebate=(TOM::Database::SPIN::GetRebate();

Vstupy:

=over

=item *

user_ID

=item *

product_ID

=item *

brand

=item *

category_ID

=back

=cut

sub GetRebate
{
	my $t=track TOM::Debug(__PACKAGE__."::GetRebate()",'namespace'=>'SPIN');
	my %env=@_;
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	my %data;
	
	$env{'user_ID'}=$main::USRM{'session'}{'SPIN'}{'ID'} unless $env{'user_ID'};
	$env{'user_ID'}=0 unless $env{'user_ID'};
	
	if (!$env{'brand'} || not exists $env{'user_ID'} || !$env{'category_ID'})
	{
		$t->close();
		main::_log("without input",1);
		return undef;
	}
	
	my $sql=qq{
		SELECT
			rabat_id "rebate_ID",
			firma_id "user_ID",
			chvuep "brand",
			druh_ceny_id "price_ID",
			platnost_od "date_from",
			platnost_do "date_to"
		FROM
			dl.sof_rabat
		WHERE
			(
				firma_id IS NULL OR
				firma_id=$env{'user_ID'}
			) AND
			produkt_id='$env{'product_ID'}'
		ORDER BY firma_id DESC
	};
	main::_log("sql:=$sql") if $debug;
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	$db0->execute();
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'rebate_ID'}=$arr[0];
		$data{'user_ID'}=$arr[1];
		#$data{'brand'}=$arr[2];
		$data{'price_ID'}=$arr[3];
		$data{'date_from'}=$arr[4];
		$data{'date_to'}=$arr[5];
		$data{'product_ID'}=$env{'product_ID'};
		
		foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
		$t->close();
		return %data;
	}
	
	my $sql=qq{
		SELECT
			rabat_id "rebate_ID",
			firma_id "user_ID",
			chvuep "brand",
			druh_ceny_id "price_ID",
			platnost_od "date_from",
			platnost_do "date_to"
		FROM
			dl.sof_rabat
		WHERE
			(
				firma_id IS NULL OR
				firma_id=$env{'user_ID'}
			) AND
			chvuep='$env{'brand'}'
		ORDER BY firma_id DESC
	};
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	
	$db0->execute();
	
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'rebate_ID'}=$arr[0];
		$data{'user_ID'}=$arr[1];
		$data{'brand'}=$arr[2];
		$data{'price_ID'}=$arr[3];
		$data{'date_from'}=$arr[4];
		$data{'date_to'}=$arr[5];
		
		foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
		
		$t->close();
		return %data;
	}
	
	
	# idem hladat rabat podla kategorie produktu
	# priorita je kladena na priradenie konkretnej firme a az potom lubovolnej firme
	
	# zistim ku category_ID vsetky nadkategorie
	# uplatnujem totiz vztah ze ak je nastaveny rabat na kategoriu produktu, plati
	# i pre vsetky podkategorie produktov.
	my @cats;
	foreach my $cat(TOM::Database::SPIN::GetRecategories($env{'category_ID'}))
	{
		next unless $cat->{'ID'};
		push @cats, $cat->{'ID'};
	}
	my $cat_in=join ",",@cats;
	main::_log("search for category IN ($cat_in)");
	$cat_in='0' unless $cat_in;
	
	# vytvorenie query
	my $sql=qq{
		SELECT
			rabat_id "rebate_ID",
			firma_id "user_ID",
			chvuep "brand",
			druh_ceny_id "price_ID",
			platnost_od "date_from",
			platnost_do "date_to",
			kategoria_id
		FROM
			dl.sof_rabat
		WHERE
			(
				firma_id IS NULL OR
				firma_id=$env{'user_ID'}
			) AND
			kategoria_id IN ($cat_in)
		ORDER BY kategoria_id ASC, firma_id DESC
	};
	my $db0 = $main::DB{spin}->prepare($sql);
	die "$DBI::errstr" unless $db0;
	$db0->execute();
	if (my $arr=$db0->fetch())
	{
		my @arr=@{$arr};
		$data{'rebate_ID'}=$arr[0];
		$data{'user_ID'}=$arr[1];
		#$data{'brand'}=$arr[2];
		$data{'price_ID'}=$arr[3];
		$data{'date_from'}=$arr[4];
		$data{'date_to'}=$arr[5];
		$data{'category_ID'}=$env{'category_ID'};
		
		foreach (sort keys %data){main::_log("output $_='$data{$_}'");}
		$t->close();
		return %data;
	}
	
	$t->close();
	return %data;
	
}


1;