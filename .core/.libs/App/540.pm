#!/bin/perl
package App::540;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

# Generic HASH => SQL => HASH get query
sub sql_insert
{
	my %args = @_;

	my $table = $args{table};
	delete $args{table};

# Where (Spracuje Dodatocne Argumenty)
	my $keys = "";
	my $values = "";
	foreach my $key (keys %args)
{
		my $value = $args{$key};
# Escape fix - zachytenie unikovych znakov
		$value =~ s/'/\\'/g;
		$value =~ s/\\/\\\\/g;

		$keys .= "$key,";
		$values .= "'$value',";
}
	$values =~ s/,$//;
	$keys =~ s/,$//;

# SQL query execution
	my @ret;
	main::_log("REPLACE INTO $table ($keys) VALUES ($values)",0);
	my $result = $main::DB{main}->Query("REPLACE INTO $table ($keys) VALUES ($values)");

# SQL Error
	if ($main::DB{main}->errmsg)
	{
		main::_log($main::DB{main}->errmsg,1);
		return -1;
	}

	my $id = $result->insertid;
	main::_log("Inserted new ID: $id",0);
	return $id;
}

sub sql_get
{
	my %args = @_;

	my $table = $args{table};
	delete $args{table};

# Get Pattern
	my $return = "*";
	$return = $args{"return"} if $args{"return"};
	delete $args{return};

# Limit
	my $limit = "";
	$limit = "LIMIT ".$args{"limit"} if $args{"limit"};
	delete $args{limit};

# Order
	my $order = "";
	$order = "ORDER BY ".$args{"order"} if $args{"order"};
	delete $args{order};

# Group
	my $group = "";
	$group = "GROUP BY ".$args{"group"} if $args{"group"};
	delete $args{group};

# Where (Spracuje Dodatocne Argumenty)
	my $where = "";
	my $first = "WHERE";
	foreach my $key (keys %args)
	{
		my $value = $args{$key};

# Capture Operator (default je =)
		my $op = "=";
		$op = $1 if $value =~ s/^([=!<>%])//o;
		$op = " LIKE " if $op eq "%";

# Escape fix - zachytenie unikovy
		$value =~ s/'/\\'/g;
		$value =~ s/\\/\\\\/g;

		$value="'$value'" if ($op eq "=" || $op eq " LIKE " || $op eq "!");
		$where .= "$first $key$op$value";
		$first = " AND";
	}

# SQL query execution
	my @ret;
	main::_log("SELECT $return FROM $table $where $group $order $limit",0);
	my $result = $main::DB{main}->Query("SELECT $return FROM $table $where $group $order $limit");

# SQL Error
	if ($main::DB{main}->errmsg)
	{
			main::_log($main::DB{main}->errmsg);
			return {};
	}

# Pack Results 2 Array
	while ( my %row = $result->fetchhash)
	{
			push @ret, {%row};
	}
	return @ret;
}

sub sql_del
{
	my %args = @_;

	my $table = $args{table};
	delete $args{table};

# Limit
	my $limit = "";
	$limit = "LIMIT ".$args{"limit"} if $args{"limit"};
	delete $args{limit};

# Where (Spracuje Dodatocne Argumenty)
	my $where = "";
	my $first = "WHERE";
	foreach my $key (keys %args)
	{
		my $value = $args{$key};

# Capture Operator (default je =)
# 2DO: like chyba a pravdepodobne by sa hodil
		my $op = "=";
		$op = $1 if $value =~ s/^([=!<>%])//o;
		$op = " LIKE " if $op eq "%";


# Escape fix - zachytenie unikovy
		$value =~ s/'/\\'/g;
		$value =~ s/\\/\\\\/g;

		$value="'$value'" if ($op eq "=" || $op eq " LIKE " || $op eq "!");
		$where .= "$first $key$op$value";
		$first = " AND";
	}

# SQL query execution
	main::_log("DELETE FROM $table $where $limit",0);
	my $result = $main::DB{main}->Query("DELETE FROM $table $where $limit");

# SQL Error
	if ($main::DB{main}->errmsg)
	{
			main::_log($main::DB{main}->errmsg,1);
			return -1;
	}
	return $result->affectedrows;
}

1;