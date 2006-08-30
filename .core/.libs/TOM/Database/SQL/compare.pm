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


=head1 DEPENDS

knižnice:

 DBI

=cut

use DBI;


# [@sql] compare ([$table1], [$table2])
# $table1 - SQL syntax for source table (SHOW CREATE TABLE ..]
# $table2 - SQL syntax for destination table (SHOW CREATE TABLE ..]
# @sql - Array of SQL commands that alters table2 to table1

	my @deadapps=qw/
		a300
		a400
		a500
		a8020
		a820
		a900
		a110
		a150
		a1D0
		a1A0
		a1B0
		a410
		a430
			/;

	my %keyfields=
	(
	# 'ID'			=>	"UNSIGNED",
	'domain'		=>	"varchar(32) NOT NULL default ''",
	'domain_sub'	=>	"varchar(64) NOT NULL default ''",
	'lng'			=>	"char(3) NOT NULL default ''",
	'active'		=>	"char(1) NOT NULL default 'N'",
	'time_insert'	=>	"int(10) unsigned NOT NULL default '0'",
	'time_start'	=>	"int(10) unsigned NOT NULL default '0'",
	'time_from'	=>	"int(10) unsigned NOT NULL default '0'",
	'time_end'		=>	"int(10) unsigned default NULL",
	'time_use'		=>	"int(10) unsigned default NULL",
	);


=head1 FUNCTIONS

=head2 compare()

Vracia pole SQL QUERIES

 ...

=cut

sub compare
{
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

	# Get Table Name
	$create1 =~ /CREATE TABLE `(.*?)`/;
	my $tbl  =$1;

	$create0=~s|^.*\(|\(|;
	$create1=~s|^.*\(|\(|;

	if ($create0)
	{
		$create0=~s|\((.*)\)(.*)|\1|s;
		$type0=$2;$type0=~/TYPE=(\w+)/;$type0=$1;

		$create1=~s|\((.*)\)(.*)|\1|s;
		$type1=$2;$type1=~/TYPE=(\w+)/;$type1=$1;

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
			my $exec="ALTER TABLE $tbl TYPE=$type0";
			push @return,$exec;
#			if ($FORM{e}){if ($db1=$DB{$tab}->Query($exec))
			$type1=$type0;
		}

		my $count;
		my $field;
		foreach my $field(@fields0a)
		{
			if (!$fields1h{$field})
			{
				my $plus;
				if (!$count){$plus.=" FIRST";}
				elsif ($fields0a[$count-1]){$plus.=" AFTER $fields0a[$count-1]";}
				my $exec="ALTER TABLE $tbl ADD $field $fields0h{$field}$plus";

				push @return,$exec;
				$fields1h{$field}=$fields0h{$field};
				$count++;
				next;
			}
			if ($fields1h{$field} ne $fields0h{$field})
			{
				my $plus;
				my $exec="ALTER TABLE $tbl CHANGE `$field` `$field` $fields0h{$field}$plus";
				push @return,$exec;
				$fields1h{$field}=$fields0h{$field};
			}
			$count++;
		}
		@fields1a=@fields0a;

		my $count;
		foreach my $key(keys %keys0h)
		{
			if (!$keys1h{$key})
			{
				my $plus=$keys0h{$key};
				my $exec="ALTER TABLE $tbl ADD $plus";
				push @return,$exec;
				$keys1h{$key}=$keys0h{$key};
				next;
			}
			if ($keys1h{$key} ne $keys0h{$key})
			{
				my $plus=$keys0h{$key};

				my $exec;
				if ($key eq "PRIMARY")
				{
					$exec="ALTER TABLE $tbl DROP PRIMARY KEY, ADD $plus";
				}
				else
				{
					$exec="ALTER TABLE $tbl DROP KEY $key, ADD $plus";
				}
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
					my $exec="ALTER TABLE $tbl DROP INDEX `$key`";
					push @return,$exec;
					delete $fields1h{$field};
					next;
				}
			}
		}

		if ($type0 ne $type1)
		{
			my $exec="ALTER TABLE $tbl TYPE=$type0";
		   push @return,$exec;
		}
	}
	return @return;
};
1;

=head1 AUTHOR

Peter Drahos

=cut