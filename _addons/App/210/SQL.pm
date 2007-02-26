#!/bin/perl
package App::210::SQL;

=head1 NAME

App::210::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

 App::210

=cut

use App::210::_init;

=head1 FUNCTIONS

=head2 page_set_as_default

Nastavi stranku ako defaultnu

=cut

sub page_set_as_default
{
	my $ID=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::page_set_as_default()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# zistim najprv informacie o tomto ID
	my %data=App::020::SQL::functions::get_ID(
		'ID' => $ID,
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => "a210_page",
		'columns' =>
		{
			'lng' => 1,
			'is_default' => 1
		}
	);
	
	# zistim ci mozem vobec nastavovat toto ID
	if (!$data{'ID'})
	{
		main::_log("ID='$ID' not exists",1);
		$t->close();
		return undef;
	}
	
	if (not $data{'status'}=~/^[YN]$/)
	{
		main::_log("only ID with status='Y/N' can be set as default",1);
		$t->close();
		return undef;
	}
	
	if ($data{'is_default'} eq "Y")
	{
		main::_log("this ID is default");
		$t->close();
		return 1;
	}
	
	# start transakcie
	my $tr=new TOM::Database::SQL::transaction('db_h'=>$env{'db_h'});
	
	# najdem polozky ktora su momentalne ako default
	# zrusenia starej ako default
	my $sql=qq{
	SELECT
		ID
	FROM
		`$env{'db_name'}`.`a210_page`
	WHERE
		lng='$data{'lng'}'
		AND is_default='Y'
	};
	my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'});
	if (!$sth0{'sth'})
	{
		main::_log("error",1);
		$tr->rollback();
		$t->close();
		return undef;
	}
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("default ID='$db0_line{'ID'}'");
		App::020::SQL::functions::update(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => "a210_page",
			'ID'      => $db0_line{'ID'},
			'columns' =>
			{
				'is_default' => "'N'",
			},
			'-journalize' => 1
		);
	}
	# update novej polozky na default
	App::020::SQL::functions::update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => "a210_page",
		'ID'      => $ID,
		'columns' =>
		{
			'is_default' => "'Y'",
		},
		'-journalize' => 1
	);
	
	# stop transakcie
	$tr->close();
	
	$t->close();
	return 1;
}


=head2 page_get_default_ID



=cut

sub page_get_default_ID
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::page_get_default_ID()");
	
	my $where;
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	
	$where.="AND status='Y' ";
	
	# najdem polozku ktora je momentalne ako default
	my $sql=qq{
	SELECT
		ID
	FROM
		`$env{'db_name'}`.`a210_page`
	WHERE
		lng='$env{'lng'}'
		AND is_default='Y'
		$where
	LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'},'quiet'=>1);
	if (!$sth0{'sth'})
	{
		main::_log("error",1);
		$t->close();
		return undef;
	}
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("return ID='$db0_line{'ID'}'");
		$t->close();
		return $db0_line{'ID'};
	}
	
	$t->close();
	return undef;
}


1;
