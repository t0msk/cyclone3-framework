package Database::connect;
use TOM::Debug;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};main::_obsolete_func();}

sub all
{
	main::_obsolete_func();
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
	
	#main::_log("SET NAMES 'utf8' to hander main ");
	#$main::DB{main}->Query("SET NAMES 'utf8'");
	
	$main::DB{main}->{dbh}->{mysql_auto_reconnect}=1;
	
	Database::connect::multi(@databases);
	# spetna kompatiblita
	# TODO: [Aben] Vyhodit spetnu kompatibilitu na $main::DBH
	$main::DBH=$main::DB{main}; 
	return 1;
}



sub multi
{
	main::_obsolete_func();
  my @databases=@_;
  
#  foreach my $handler (keys %TOM::DB)
  foreach my $handler (@databases)
  {
    #main::_log("use handler $handler");
    main::_log("request to connect handler $handler");
    next if $main::DB{$handler};
#    next if $
    foreach (keys %TOM::DB)
    {
     main::_log(" control handler $_");
     if (
	 ($main::DB{$_})
	 &&
	 (
		($TOM::DB{$_}{host} eq $TOM::DB{$handler}{host})
		&&($TOM::DB{$_}{user} eq $TOM::DB{$handler}{user})
	 )
	)
     {
		main::_log("$handler=$_");
		$main::DB{$handler}=$main::DB{$_};last;
		}
	}
	next if $main::DB{$handler};
	
	main::_log("connecting $handler ($TOM::DB{$handler}{host} $TOM::DB{$handler}{name} $TOM::DB{$handler}{user} $TOM::DB{$handler}{pass})");
	return undef unless $main::DB{$handler} = Mysql->Connect
	(
		$TOM::DB{$handler}{host},
		$TOM::DB{$handler}{name},
		$TOM::DB{$handler}{user},
		$TOM::DB{$handler}{pass},
	);
	
	#main::_log("error mysql: ".Mysql->errstr(),1) if Mysql->errstr();
	
	#main::_log("SET NAMES 'utf8' to hander $handler ");
	
	$main::DB{$handler}->{dbh}->{mysql_auto_reconnect}=1;
	
	#$main::DB{$handler}->Query("SET NAMES 'utf8'");
	#my $sth=$dbh->prepare(qq{SET NAMES 'utf8'});
  }
  return 1;
}


sub utf8
{
	main::_obsolete_func();
	#  foreach my $handler (keys %TOM::DB)
	foreach my $handler (keys %main::DB)
	{
		main::_log("SET NAMES 'utf8' to hander $handler ");
		$main::DB{$handler}->{dbh}->{mysql_auto_reconnect}=1;
		$main::DB{$handler}->Query("SET NAMES 'utf8'") || $main::DB{$handler}->Query("SET NAMES 'utf8'");
	}
	return 1;
}






1;
