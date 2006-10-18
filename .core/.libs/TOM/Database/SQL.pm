package TOM::Database::SQL;

=head1 NAME

TOM::Database::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use TOM::Database::SQL::file;
use TOM::Database::SQL::compare;

=head1 FUNCTIONS

=head2 escape()

Očistenie SQL príkazu

=cut

sub escape
{
	my $sql=shift;
	$sql=~s|\'|\\'|g;
	return $sql;
}


sub get_database_applications
{
	my $database=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_database_applications($database)");
	$env{'db_h'}='main' unless $env{'db_h'};
	
	TOM::Database::connect::multi($env{'db_h'}) unless $main::DB{$env{'db_h'}};
	
	my @applications;
	
	my %app;
	my $db0=$main::DB{$env{'db_h'}}->Query("SHOW TABLES FROM `$database`");
	while (my @db0_line=$db0->fetchrow())
	{
		main::_log("fount table '$db0_line[0]'");
		if ($db0_line[0]=~s/^a//)
		{
			if ($db0_line[0]=~s|^([a-zA-Z0-9]*)||)
			{
				$app{$1}++;
			}
		}
	}
	
	foreach (sort keys %app)
	{
		main::_log("add application '$_'");
		push @applications,$_;
	}
	
	$t->close();
	return @applications;
}

=head2 show_create_table()



=cut

sub show_create_table
{
	my $handler=shift;
	my $database=shift;
	my $table=shift;
	my $SQL;
	
	my $db0=$main::DB{$handler}->Query("SHOW CREATE TABLE `$database`.`$table`");
	my $SQL=($db0->fetchrow())[1];
	$SQL=~s|TABLE `.*?` \(|TABLE `$database`.`$table` (|;
	
	return $SQL;
}


=head2 execute($SQL,'db_h'=>'main')

Vykoná SQL príkaz a vráti pole hodnot

 @output=(return code, affected rows, ...)

=cut

sub execute
{
	my $SQL=shift;
	my %env=shift;
	my $t=track TOM::Debug(__PACKAGE__."::execute()");
	
	my @output;
	
	if ($SQL=~/-- db_h=([a-zA-Z0-9]*)/)
	{
		$env{'db_h'}=$1;
		main::_log("db_h changed by comment to '$env{db_h}'");
	}
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	TOM::Database::connect::multi($env{'db_h'}) unless $main::DB{$env{'db_h'}};
	
	my $sth=$main::DB{$env{'db_h'}}->Query($SQL);
	
	if (not $sth)
	{
		my @output=(
			$main::DB{$env{'db_h'}}->info(),
			undef,
			$main::DB{$env{'db_h'}}->errmsg(),
			undef
		);
		main::_log("output errmsg=".$output[2]);
		main::_log("output info=".$output[0]);
		$t->close();
		return @output;
	}
	
	my @output=(
		$main::DB{$env{'db_h'}}->info(),
		$sth->affectedrows(),
		$main::DB{$env{'db_h'}}->errmsg(),
		$sth
	);
	
	main::_log("output errmsg=".$output[2]);
	main::_log("output affectedrows=".$output[1]);
	main::_log("output info=".$output[0]);
	
	$t->close();
	return @output;
}

=head1 SYNOPSIS

Nainstalovat globalnu databazu aj s datami (ak je uz nainstalovana, aktualizovat)

 TOM::Database::SQL::file::install('TOM',
  '-compare'=>1,
  '-compare_execute'=>1,
  '-data'=>1
 );

Nainstalovat domenu aj s datami (ak je uz nainstalovana, aktualizovat)

 TOM::Database::SQL::file::install('_domain',
  'db_name'=>"example_tld",
  '-compare'=>1,
  '-compare_execute'=>1,
  '-data'=>1
 );

Nainstalovat aplikaciu aj s default datami

 TOM::Database::SQL::file::install('a300',
  'db_name'=>"example_tld",
  '-compare'=>1,
  '-compare_execute'=>1,
  '-data'=>1
 );

Checknut ci su nainstalovane aplikacie pre domenu (lokalne alebo globalne) a chybajuce nainstalovat (podla local.conf)

 ?

Checknut aplikacie nainstalovane v globale a vykonat upgrade

 TOM::Database::SQL::compare::compare_database("TOM",
  '-compare'=>1,
  '-compare_execute'=>1
 );

Checknut aplikacie nainstalovane v domene a vykonat upgrade

 TOM::Database::SQL::compare::compare_database("example_tld",
  '-compare'=>1,
  '-compare_execute'=>1
 );

Aktualizovat aplikacie vo vsetkych databazach

 TOM::Database::SQL::compare::compare_database("*",
  '-compare'=>1,
  '-compare_execute'=>1
 );

=cut

1;
