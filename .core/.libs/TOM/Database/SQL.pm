package TOM::Database::SQL;

=head1 NAME

TOM::Database::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM::Database::connect;
use TOM::Database::SQL::file;
use TOM::Database::SQL::compare;
use TOM::Database::SQL::transaction;

our $debug=0;
our $logquery=1;
our $logquery_long=1;

=head1 FUNCTIONS

=head2 escape()

Cleaning variable used to SQL query

=cut

sub escape
{
	my $sql=shift;
	$sql=~s|\'|\\'|g;
	return $sql;
}

=head2 get_database_applications($database_name)

Return list of available applications installed in this database

=cut


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

 %output={'sth', 'rows', 'info', 'err'}

=cut

sub execute
{
	my $SQL=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::execute()",'namespace'=>"SQL",'quiet' => $env{'quiet'});
	
	my %output;
	
	$SQL=~s|^[\t\n\r]+||;
	if ($SQL=~/-- db_h=([a-zA-Z0-9]*)/)
	{
		$env{'db_h'}=$1;
		main::_log("db_h changed by comment to '$env{db_h}'") unless $env{'quiet'};
	}
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	if ($TOM::DB{$env{'db_h'}.':s1'} && $SQL=~/^SELECT/)
	{
		#main::_log("using slave");
		#$env{'db_h'}=$env{'db_h'}.':s1';
	}
	
	TOM::Database::connect::multi($env{'db_h'}) unless $main::DB{$env{'db_h'}};
	
	if ($env{'log'})
	{
		foreach my $line(split("\n",$SQL))
		{
			$line=~s|\t|   |g;
			main::_log($line) unless $env{'quiet'};
		}
	}
	
	if ($logquery)
	{
		my $SQL_=$SQL;
		$SQL_=~s|[\n\t\r]+| |g;
		$SQL_=~s|^[ ]+||;
		main::_log("{$env{'db_h'}} $SQL_",3,"sql");
	}
	
	$output{'sth'}=$main::DB{$env{'db_h'}}->Query($SQL);
	
	$output{'info'}=$main::DB{$env{'db_h'}}->info();
	$output{'err'}=$main::DB{$env{'db_h'}}->errmsg();
	
	if (not $output{'sth'})
	{
		if ($output{'err'})
		{
			main::_log("output errmsg=".$output{'err'},1) unless $env{'quiet'};
		}
		main::_log("output info=".$output{'info'}) unless $env{'quiet'};
		$t->close();
		return %output;
	}
	
	$output{'rows'}=$output{'sth'}->affectedrows();
	
	if ($output{'err'})
	{
		main::_log("output errmsg=".$output{'err'},1) unless $env{'quiet'};
	}
	main::_log("output affectedrows=".$output{'rows'}) unless $env{'quiet'};
	main::_log("output info=".$output{'info'}) unless $env{'quiet'};
	
	$t->close();
	return %output;
}



=head2 get_database_version

Return version of database identified by database handler name

 my $version=TOM::Database::SQL::get_database_version('main');

=cut

sub get_database_version
{
	my $db_h=shift;
	
	TOM::Database::connect::multi($db_h) unless $main::DB{$db_h};
	
	my $version=$main::DB{$db_h}->getserverinfo();
		$version=~s|^([\d]+)\.([\d]+)\.(.*)$|\1.\2|;
		
	main::_log("MySQL version on handler '$db_h'='$version'") if $debug;
	
	return $version;
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
