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
 TOM::Database::SPIN::document
 TOM::Database::SPIN::VUEP
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
use TOM::Database::SPIN::document;
use TOM::Database::SPIN::VUEP;
use Time::Local;


=head1 KEYWORDS

Popis vyrazov a klucovych slov pouzivanych v implementacii SPIN do Cyclone3

=over

=item *

VUEP

 Volitelny udaj evidencnej polozky

=back

=cut


=head1 VARIABLES

=over

=item *

%cache

Premenna pre storing vystupov z queries. Islo o cachovanie tychto vystupov, momentalne sa nepouziva. Mozno v buducnosti to bude treba.

=back

=cut

our %cache;
our $session_id;


sub OpenSession
{
	alarm(0);
	
	$main::DB{'spin'}->{LongTruncOk} = 1;
	$main::DB{'spin'}->{LongReadLen} = 1000000;
	$main::DB{'spin'}->do("ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'");
#	$main::DB{'spin'}->do("ALTER SESSION SET NLS_COMP=ANSI");
#	$main::DB{'spin'}->do("ALTER SESSION SET NLS_SORT=BINARY_CI");
	
	my $t=track TOM::Debug("SPIN dl.pkdlconnection.opensession()",'namespace'=>'SPIN');
	my $sql = qq{
		DECLARE session_id INTEGER;
		BEGIN
			:session_id := dl.pkdlconnection.opensession(11,10,1);
		END;
	};
	my $db0 = $main::DB{spin}->prepare($sql);
	$db0->bind_param_inout( ":session_id", \$session_id, 32 );
	$db0->execute();
	
	main::_log("return session_id='".$session_id."'");
	
	my $t0=track TOM::Debug("cache VUEPs to memory",'namespace'=>'SPIN');
	
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
		foreach my $vuep_cat(split(',',$arr[2]))
		{
			push @{$vuep_category{$vuep_cat}},{'code'=>$arr[1],'ID'=>$arr[0],'name'=>$arr[3],'cis'=>$arr[4]};
		}
	}
	
	$t0->close();
	
	$t->close();
}


TOM::Database::SPIN::OpenSession();


1;

=head1 AUTHOR

Roman Fordinal

=cut