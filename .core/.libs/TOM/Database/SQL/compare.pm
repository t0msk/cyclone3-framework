package TOM::Database::SQL::compare;

=head1 NAME

TOM::Database::SQL::compare

=head1 DESCRIPTION

Porovnanie dvoch tabuliek

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM::Database::SQL::file;

our $debug=0;

=head1 FUNCTIONS

=head2 compare_create_table($table0,$table1)

Vracia pole SQL príkazov ktoré musia byť vykonané aby sa štruktúra druhej tabuľky zmenila tak aby obidve tabuľky boli identické.

 CREATE TABLE `database`.`table` (
 	`ID` ...
 )

=cut

sub compare_create_table
{
	my $t=track TOM::Debug(__PACKAGE__."::compare_create_table()");
	
	my @return;
	
	my $type0;
	my @fields0a;
	my %fields0h;
	my %keys0h;
	my $create0 = shift;
	
	# Destination Table
	my $type1;
	my @fields1a;
	my %fields1h;
	my %keys1h;
	my $create1 = shift;
	
	if ($create1=~/CREATE ALGORITHM/)
	{
		main::_log("this is ALGORITHM, not able to compare");
		$t->close();
		return @return;
	}
	
	# Get Table Name
	$create1 =~ /CREATE TABLE `(.*?)`\.`(.*?)`/;
	my $database=$1;
	my $tbl  =$2;
	
	main::_log("database='$database' table='$tbl'");
	
	$create0=~s|^.*\(|\(|;
	$create1=~s|^.*\(|\(|;
	
	if ($create0)
	{
		
		
		$create0=~s|\((.*)\)(.*)|\1|s;
		$type0=$2;$type0=~/(TYPE|ENGINE)=(\w+)/;$type0=$2;
		
		$create1=~s|\((.*)\)(.*)|\1|s;
		$type1=$2;$type1=~/(TYPE|ENGINE)=(\w+)/;$type1=$2;
		
		main::_log("table0 type='$type0' table1 type='$type1'");
		
		foreach my $line(split('\n',$create0))
		{
			next unless $line;1 while ($line=~s|^ ||);
			$line=~/^`/ && do
			{
				$line=~s|,$||;$line=~s|`(.*?)` (.*)|\2|;my $name=$1;
				push @fields0a, $name;$fields0h{$name}=$line; next
			};
			
			$line=~s|,$||;
			if ($line=~/^PRIMARY KEY/)
			{
				$keys0h{PRIMARY}=$line;
			}
			elsif ($line=~/FOREIGN KEY/)
			{
			}
			else
			{
				$line=~/`(.*?)`/;$keys0h{$1}=$line;
			}
		}
		
		foreach my $line(split('\n',$create1))
		{
			next unless $line;1 while ($line=~s|^ ||);
			$line=~/^`/ && do
			{
				$line=~s|,$||;$line=~s|`(.*?)` (.*)|\2|;my $name=$1;
				push @fields1a, $name;$fields1h{$name}=$line; next
			};
			
			$line=~s|,$||;
			if ($line=~/^PRIMARY KEY/)
			{
				$keys1h{PRIMARY}=$line;
			}
			
			elsif ($line=~/FOREIGN KEY/)
			{
			}
			else
			{
				$line=~/`(.*?)`/;$keys1h{$1}=$line;
			}
		}
		
		if ($type0 ne $type1)
		{
			my $exec="ALTER TABLE `$database`.`$tbl` TYPE=$type0";
			push @return,$exec;
			main::_log("add SQL '$exec'");
			$type1=$type0;
		}
		
		
		my $t_fields=track TOM::Debug("table0 fields");
		my $count;
		my $field;
		foreach my $field(@fields0a)
		{
			main::_log("field='$field'");
			main::_log("'$fields1h{$field}' <=> '$fields0h{$field}'") if $debug;
			if (!$fields1h{$field})
			{
				main::_log("not exists in table1");
				my $plus;
				if (!$count){$plus.=" FIRST";}
				elsif ($fields0a[$count-1]){$plus.=" AFTER `$fields0a[$count-1]`";}
				my $exec="ALTER TABLE `$database`.`$tbl` ADD `$field` $fields0h{$field}$plus";
				$exec=~s|auto_increment||;
				main::_log("add SQL '$exec'");
				push @return,$exec;
				$fields1h{$field}=$fields0h{$field};
				$count++;
				next;
			}
			if ($fields1h{$field} ne $fields0h{$field})
			{
				main::_log("not equals");
				if ($fields1h{$field}=~/character set/ && (not $fields0h{$field}=~/character set/)
					&& $fields0h{$field}=~/(char|text)/)
				{
					main::_log("MySQL '4.0' -> '>=4.1', cancel (not defined collation in struct SQL file)");
				}
				else
				{
					my $plus;
					my $exec="ALTER TABLE `$database`.`$tbl` CHANGE `$field` `$field` $fields0h{$field}$plus";
					main::_log("add SQL '$exec'");
					push @return,$exec;
					$fields1h{$field}=$fields0h{$field};
				}
			}
			$count++;
		}
		
#		if (not $tbl=~/_attrs(_arch|)$/)
#		{
			foreach my $key(keys %fields1h)
			{
				if (!$fields0h{$key})
				{
					my $exec="ALTER TABLE `$database`.`$tbl` DROP `$key`";
					main::_log("add SQL '$exec'");
					push @return,$exec;
					delete $fields1h{$field};
					next;
				}
			}
#		}
		
		@fields1a=@fields0a;
		$t_fields->close();
		
		
		my $t_keys=track TOM::Debug("table0 keys");
		my $count;
		foreach my $key(keys %keys0h)
		{
			main::_log("key='$key'");
			if (!$keys1h{$key})
			{
				main::_log("not exists in table1");
				my $plus=$keys0h{$key};
				my $exec="ALTER TABLE `$database`.`$tbl` ADD $plus";
				main::_log("add SQL '$exec'");
				push @return,$exec;
				$keys1h{$key}=$keys0h{$key};
				next;
			}
			if ($keys1h{$key} ne $keys0h{$key})
			{
				main::_log("not equals '$keys0h{$key}'<=>'$keys1h{$key}'");
				my $plus=$keys0h{$key};
				my $exec;
				if ($key eq "PRIMARY")
				{
					$exec="ALTER TABLE `$database`.`$tbl` DROP PRIMARY KEY, ADD $plus";
				}
				else
				{
					$exec="ALTER TABLE `$database`.`$tbl` DROP KEY $key, ADD $plus";
				}
				main::_log("add SQL '$exec'");
				push @return,$exec;
				$keys1h{$key}=$keys0h{$key};
				next;
			}
		}
		
		if (not $tbl=~/_attrs(_arch|)$/)
		{
			foreach my $key(keys %keys1h)
			{
				if (!$keys0h{$key})
				{
					my $exec="ALTER TABLE `$database`.`$tbl` DROP INDEX `$key`";
					main::_log("add SQL '$exec'");
					push @return,$exec;
					delete $fields1h{$field};
					next;
				}
			}
		}
		
		$t_keys->close();
		
		if ($type0 ne $type1)
		{
			my $exec="ALTER TABLE `$database`.`$tbl` TYPE=$type0";
			main::_log("add SQL '$exec'");
		   push @return,$exec;
		}
	}
	
	$t->close();
	return @return;
};


=head2 compare_database(%env)

detekcia zoznamu aplikacii nachadzajucich sa v databaze a ich reinstalacia

=cut

sub compare_database
{
	my $database=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::compare_database($database)");
	$env{'db_name'}=$database;
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my %output;
	
	if ($database eq 'TOM')
	{
		# zrusim pripadne predefinovanie handleru a nazvu databazy (to si precitam z TOM.sql a nemoze byt overridovane)
		# hlavna databaza totiz moze byt len TOM a moze byt len v main handleri
		#$env{'db_h'}='main';
		undef $env{'db_name'};
		my %input=TOM::Database::SQL::file::install('TOM','-compare'=>1,'-compare_execute' => 0);
		push @{$output{'ALTER'}}, @{$input{'ALTER'}} if $input{'ALTER'};
	}
	else
	{
		my %input=TOM::Database::SQL::file::install('_domain',
			'db_name'=>$database,
			'-compare'=>1,
			'-compare_execute'=>0);
		push @{$output{'ALTER'}}, @{$input{'ALTER'}} if $input{'ALTER'};
	}
	
	# detekcia zoznamu aplikacii nachadzajucich sa v domene
	foreach my $app (TOM::Database::SQL::get_database_applications($database,'db_h'=>$env{'db_h'}))
	{
		my %input=TOM::Database::SQL::file::install('a'.$app,
			'db_name'=>$database,
			'-compare'=>1,
			'-compare_execute' => 0
		) or die "can't install 'a$app' by TOM::Database::SQL::file::install";
		push @{$output{'ALTER'}}, @{$input{'ALTER'}} if $input{'ALTER'};
	}
	
	# zozbieram vsetky ALTER prikazy a vykonam ich az teraz,
	foreach my $SQL_ALTER(@{$output{'ALTER'}})
	{
		main::_log("ALTER='$SQL_ALTER'");
		if ($env{'-compare_execute'})
		{
			my %sth0=TOM::Database::SQL::execute($SQL_ALTER);
		}
	}
	
	$t->close();
	return %output;
}


1;

=head1 CONTRIB

Peter Drahos
Roman Fordinál

=cut