package TOM::Database::connect;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use DBI;
use Mysql;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


sub all
{
	my @databases=@_;
	$TOM::DB{main}{name}=$TOM::DB_name unless $TOM::DB{main}{name};
	
	main::_log("request to connect handler main");
	
	main::_log("connecting main ($TOM::DB{main}{host} $TOM::DB{main}{name} $TOM::DB{main}{user})");
	
	return undef unless $main::DB{main} = Mysql->Connect
	(
		$TOM::DB{main}{host},
		$TOM::DB{main}{name},
		$TOM::DB{main}{user},
		$TOM::DB{main}{pass}
	);
	
	$main::DB{main}->{dbh}->{mysql_auto_reconnect}=1;
	
	TOM::Database::connect::multi(@databases);
	# spetna kompatiblita
	# TODO: [Aben] Vyhodit spetnu kompatibilitu na $main::DBH
	$main::DBH=$main::DB{main}; 
	return 1;
}



sub multi
{
	my $t=track TOM::Debug(__PACKAGE__."::multi()");
	
	my @databases=@_;
	
	foreach my $handler (@databases)
	{
		main::_log("request to connect handler '$handler'");
		
		if ($main::DB{$handler})
		{
			main::_log("this handler already exists");
			next;
		}
		
		foreach (keys %TOM::DB)
		{
			#main::_log("control handler '$_'");
			if
			(
				($main::DB{$_})
				&&
				(
					($TOM::DB{$_}{host} eq $TOM::DB{$handler}{host})
					&&($TOM::DB{$_}{user} eq $TOM::DB{$handler}{user})
				)
			)
			{
				main::_log("is same as handler '$_'");
				$main::DB{$handler}=$main::DB{$_};last;
			}
		}
		
		if ($main::DB{$handler})
		{
			main::_log("this handler is connected");
			next;
		}
		
		# idem connectovat
		
		if ($TOM::DB{$handler}{'type'} eq "DBI")
		{
			main::_log("DBI connecting '$handler' ('$TOM::DB{$handler}{uri}' '$TOM::DB{$handler}{user}' '****')");
			
			return undef unless $main::DB{$handler} = DBI->connect
			(
				$TOM::DB{$handler}{uri},
				$TOM::DB{$handler}{user},
				$TOM::DB{$handler}{pass}
			);
			
			#$dbh->{AutoCommit}    = 1;
			#$main::DB{$handler}->{RaiseError}    = 1;
			$main::DB{$handler}->{ora_check_sql} = 0;
			$main::DB{$handler}->{RowCacheSize}  = 32;
			
		}
		else
		{
			main::_log("connecting '$handler' ('$TOM::DB{$handler}{host}' '$TOM::DB{$handler}{name}' '$TOM::DB{$handler}{user}' '****')");
			
			return undef unless $main::DB{$handler} = Mysql->Connect
			(
				$TOM::DB{$handler}{host},
				$TOM::DB{$handler}{name},
				$TOM::DB{$handler}{user},
				$TOM::DB{$handler}{pass},
			);
			
			$main::DB{$handler}->{'dbh'}->{'mysql_auto_reconnect'}=1;
		}
		
	}
	
	$t->close();
	return 1;
}

1;
