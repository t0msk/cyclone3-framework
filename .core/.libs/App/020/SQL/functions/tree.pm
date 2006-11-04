#!/bin/perl
package App::020::SQL::functions::tree;

=head1 NAME

App::020::SQL::functions::tree

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use TOM::Net::URI::rewrite;


=head1 FUNCTIONS

=head2 new()

Vytvori novy zaznam v tabulke

=cut

sub new
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::new()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# automaticka zamena name na name_url
	if (!$env{'collumns'}{'name_url'})
	{
		$env{'collumns'}{'name'}=~s|^'||;
		$env{'collumns'}{'name'}=~s|'$||;
		$env{'collumns'}{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'collumns'}{'name'})."'";
		$env{'collumns'}{'name'}="'".$env{'collumns'}{'name'}."'";
		main::_log("create 'collumns'->'name_url'='$env{'collumns'}{'name_url'}'");
	}
	
	
	
	# najdem volny ID_charindex
	my $level=0; # default
	my $parent_ID_charindex;
	
	# pozriem sa na parent_ID
	if ($env{'parent_ID'})
	{
		my %data=App::020::SQL::functions::get_ID(
			'ID' => $env{'parent_ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'collumns' =>
			{
				'ID_charindex' => 1
			}
		);
		if ($data{'ID'})
		{
			$parent_ID_charindex=$data{'ID_charindex'};
			main::_log("parent_ID_charindex='$parent_ID_charindex'");
		}
		else
		{
			main::_log("can't find parent ID='$env{'parent_ID'}'",1);
			$t->close();
			return undef;
		}
	}
	
	# ID_charindex_ - base pre novy ID_charindex
	my $ID_charindex_= $parent_ID_charindex.':';
	$ID_charindex_=~s|^:||;
	
	# novy ID_charindex
	my $ID_charindex_new=$ID_charindex_;
	
	# hladam posledny child v tomto node podla ID_charindex_
	my $sql=qq{
	SELECT
		ID_charindex
	FROM `$env{'db_name'}`.`$env{'tb_name'}`
	WHERE
		ID_charindex LIKE '$ID_charindex_\___'
	ORDER BY ID_charindex DESC
	LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'},'log'=>1);
	if (!$sth0{'sth'})
	{
		$t->close();
		return undef;
	}
	
	if ($sth0{'rows'})
	{
		# idem vyratavat novy ID_charindex, pretoze tento nod ma childy
		my %db0_line=$sth0{'sth'}->fetchhash();
		main::_log("last child of parent ID_charindex='$db0_line{ID_charindex}'");
		$db0_line{'ID_charindex'}=~/(...)$/;
		my $sub=$1;
		main::_log("ID_charindex '$sub'++");
		# TODO: ratanie dalsieho ID_charindex
	}
	else
	{
		# tento nod nema childy, takze "koncovka" noveho ID_charindex je 000
		$ID_charindex_new.='000';
	}
	$ID_charindex_new=~s|:$||;
	
	main::_log("new ID_charindex='$ID_charindex_new'");
	
	$env{'collumns'}{'ID_charindex'}="'".$ID_charindex_new."'";
	my $ID=App::020::SQL::functions::new(%env);
	
	$t->close();
	return $ID;
}


=head2 move_up()

Posunie záznam o položku vyššie. V preklade to znamená že nájde položku predchádzajúci a switchne sa s ňou.

=cut

sub move_up
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::move_up()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# vyberiem si tento zaznam z databazy
	my %data=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'collumns' => {'ID_charindex'=>1}
	);
	if (!$data{'ID'})
	{
		$t->close();
		return undef;
	}
	
	if (not $data{'status'} =~ /^[YN]$/)
	{
		main::_log("only ID with status 'Y' or 'N' can be moved in tree, not status='$data{'status'}'",1);
		$t->close();
		return undef;
	}
	
	main::_log("ID='$env{'ID'}' has ID_charindex='$data{'ID_charindex'}'");
	
	my $ID_charindex=$data{'ID_charindex'};
	my $ID_charindex_=$data{'ID_charindex'};
	$ID_charindex_=~s|^(.*)...$|\1|;
	
	# najdem predchadzajucu polozku
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM `$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex < '$data{'ID_charindex'}'
			AND ID_charindex LIKE '$ID_charindex_\___'
			AND (status='Y' OR status='N')
		ORDER BY
			ID_charindex DESC
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>0,'quiet'=>1);
	if ($sth0{'rows'})
	{
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("higher ID='$db0_line{'ID'}' ID_charindex='$db0_line{'ID_charindex'}'");
			
			swap(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID1' => $env{'ID'},
				'ID2' => $db0_line{'ID'},
				'-journalize' => $env{'-journalize'},
			);
			
		}
	}
	else
	{
		main::_log("this ID='$env{ID}' is at top");
	}
	
	$t->close();
}


=head2 move_down()

Posunie záznam o položku nižšie. V preklade to znamená že nájde položku nižsiu a switchne sa s ňou.

=cut

sub move_down
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::move_down()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# vyberiem si tento zaznam z databazy
	my %data=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'collumns' => {'ID_charindex'=>1}
	);
	if (!$data{'ID'})
	{
		$t->close();
		return undef;
	}
	
	if (not $data{'status'} =~ /^[YN]$/)
	{
		main::_log("only ID with status 'Y' or 'N' can be moved in tree, not status='$data{'status'}'",1);
		$t->close();
		return undef;
	}
	
	main::_log("ID='$env{'ID'}' has ID_charindex='$data{'ID_charindex'}'");
	
	my $ID_charindex=$data{'ID_charindex'};
	my $ID_charindex_=$data{'ID_charindex'};
	$ID_charindex_=~s|^(.*)...$|\1|;
	
	# najdem predchadzajucu polozku
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM `$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex > '$data{'ID_charindex'}'
			AND ID_charindex LIKE '$ID_charindex_\___'
			AND (status='Y' OR status='N')
		ORDER BY
			ID_charindex ASC
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>0,'quiet'=>1);
	if ($sth0{'rows'})
	{
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("lower ID='$db0_line{'ID'}' ID_charindex='$db0_line{'ID_charindex'}'");
			
			swap(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID1' => $env{'ID'},
				'ID2' => $db0_line{'ID'},
				'-journalize' => $env{'-journalize'},
			);
			
		}
	}
	else
	{
		main::_log("this ID='$env{ID}' is at bottom");
	}
	
	$t->close();
}



sub swap
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::swap()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my %data1=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID1'},
		'collumns' => {'ID_charindex'=>1}
	);
	my %data2=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID2'},
		'collumns' => {'ID_charindex'=>1}
	);
	if (!$data1{'ID'} || !$data2{'ID'})
	{
		main::_log("ID1 or ID2 can't be found in table",1);
		$t->close();
		return undef;
	}
	
	main::_log("swap ID='$data1{ID}' ID_charindex='$data1{'ID_charindex'}' => ID='$data2{ID}' ID_category='$data2{'ID_charindex'}'");
	
	my $ID_charindex=$data1{'ID_charindex'};
	$ID_charindex=~s|^(.*)...|\1\.\.\.|;
	main::_log("middle ID_charindex='$ID_charindex'");
	
	# ziskam zoznam vsetkych poloziek pod ID_charindex a zacnem ich menit na medziID_charindex '...'
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$data1{ID_charindex}%'
			AND (status='Y' OR status='N')
		ORDER BY
			ID_entity
	};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth1{'rows'})
	{
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			my $ID_charindex_c=$db1_line{'ID_charindex'};
			$ID_charindex_c=~s|^$data1{ID_charindex}|$ID_charindex|;
			
			main::_log("sub of ID_charindex='$data1{ID_charindex}' is ID='$db1_line{'ID'}' ID_charindex='$db1_line{'ID_charindex'}'=>'$ID_charindex_c'");
			
			App::020::SQL::functions::update(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID' => $db1_line{'ID'},
#				'-journalize' => $env{'-journalize'},
				'collumns' => {
					'ID_charindex' => "'$ID_charindex_c'"
				}
			);
		}
	}
	
	# zistam zoznam vsetkych poloziek pod $IDcharindex2
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$data2{ID_charindex}%'
			AND (status='Y' OR status='N')
		ORDER BY
			ID_entity
	};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth1{'rows'})
	{
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			my $ID_charindex_c=$db1_line{'ID_charindex'};
			$ID_charindex_c=~s|^$data2{ID_charindex}|$data1{ID_charindex}|;
			
			main::_log("sub of ID_charindex='$data2{ID_charindex}' is ID='$db1_line{'ID'}' ID_charindex='$db1_line{'ID_charindex'}'=>'$ID_charindex_c'");
			
			App::020::SQL::functions::update(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID' => $db1_line{'ID'},
				'-journalize' => $env{'-journalize'},
				'collumns' => {
					'ID_charindex' => "'$ID_charindex_c'"
				}
			);
		}
	}
	
	# zistam zoznam vsetkych poloziek pod $IDcharindex3
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$ID_charindex%'
			AND (status='Y' OR status='N')
		ORDER BY
			ID_entity
	};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth1{'rows'})
	{
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			my $ID_charindex_c=$db1_line{'ID_charindex'};
			$ID_charindex_c=~s|^$ID_charindex|$data2{ID_charindex}|;
			
			main::_log("sub of ID_charindex='$ID_charindex' is ID='$db1_line{'ID'}' ID_charindex='$db1_line{'ID_charindex'}'=>'$ID_charindex_c'");
			
			App::020::SQL::functions::update(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID' => $db1_line{'ID'},
				'-journalize' => $env{'-journalize'},
				'collumns' => {
					'ID_charindex' => "'$ID_charindex_c'"
				}
			);
		}
	}
	
	$t->close();
	return 1;
}


=head2 get_path

Vypisanie cesty konkretnej polozky

=cut

sub get_path
{
}


=head2 find_path

Hladanie cesty

=cut

sub find_path
{
}


=head2 find_path_url

Hladanie cesty

=cut

sub find_path_url
{
	my $path=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::find_path_url('$path')");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my @level=split('/',$path);
	my $levels=($path=~s|/|/|g);
	
	main::_log("levels=$levels");
	
	my $ID_charindex= '___:' x ($levels+1);
	$ID_charindex=~s|:$||;
	
	# zistam zoznam vsetkych poloziek pod $IDcharindex3
	my $SQL=qq{
		SELECT
			*
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$ID_charindex'
			AND status='Y'
			AND lng='$env{lng}'
			AND name_url='$level[-1]'};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>1);
	if ($sth1{'rows'}==1)
	{
		main::_log("only 1 output");
		my %data=$sth1{'sth'}->fetchhash();
		$t->close();
		return %data;
	}
	elsif ($sth1{'rows'})
	{
		main::_log("concurent outputs",1);
		# TODO: dorobit spracovanie
		$t->close();
		return undef;
	}
	else
	{
		main::_log("can't be found",1);
		$t->close();
		return undef;
	}
	
	$t->close();
	return 1;
}


=head2 rename()

Premenujem dany zaznam

=cut

sub rename
{
	my $name=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::rename($name)");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my $name_url=TOM::Net::URI::rewrite::convert($name);
	
	# zistim si nieco o polozke ktoru chcem premenovat
	my %data=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'collumns' =>
		{
			'status' => 1,
		}
	);
	
	if (!$data{ID})
	{
		main::_log("ID='$env{ID}' not exists",1);
		$t->close();
		return undef;
	}
	
	if ($data{status}=~/^[YN]$/)
	{
		# premenovanie
		App::020::SQL::functions::update(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'ID' => $env{'ID'},
			'-journalize' => $env{'-journalize'},
			'collumns' => {
				'name'     => "'$name'",
				'name_url' => "'$name_url'"
			}
		);
	}
	else
	{
		main::_log("only ID with status 'Y' or 'N' can be renamed, not status='$data{'status'}'",1);
		$t->close();
		return undef;
	}
	
	# end track
	$t->close();
	return 1;
}

1;
