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
use TOM::Database::SQL::cache;

our $debug=$TOM::Database::SQL::debug || 0;
our $save_error=$TOM::Database::SQL::save_error || 1;
our $logcachequery=$TOM::Database::SQL::logcachequery || 0;
our $lognonselectquery=$TOM::Database::SQL::lognonselectquery || 0;
our $logquery=$TOM::Database::SQL::logquery || 0;
our $logquery_long=$TOM::Database::SQL::logquery_long || 5; # in seconds

our $query_long_autocache=$TOM::Database::SQL::query_long_autocache || 0.01; # less availability than Memcached

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
		main::_log("found table '$db0_line[0]'");
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
	
	if ($main::DB{$handler}->{Driver}->{Name} eq 'ODBC')
	{
		# for now leave this empty - here we should get an alternative to SHOW CREATE TABLE for a particular database server
		# ODBC driver does not support ->Query anyway
		$SQL = '';
	}
	else
	{
		my $db0=$main::DB{$handler}->Query("SHOW CREATE TABLE `$database`.`$table`");
		$SQL=($db0->fetchrow())[1];
		$SQL=~s|TABLE `.*?` \(|TABLE `$database`.`$table` (|;
	}
	return $SQL;
}



=head2 show_slave_status($db_h)



=cut

our %slave_status;
sub get_slave_status
{
	my $db_h=shift;
	use Ext::Redis::_init;
	
	my $TTL=5;
		$TTL=1 if $Redis;
	
	# check only on every $TTL seconds
#	main::_log("chk $slave_status{$db_h}{'time'} ".time()." diff:".(time() - $slave_status{$db_h}{'time'}))
#		if $slave_status{$db_h};
	if ($slave_status{$db_h} && ((time() - $slave_status{$db_h}{'time'}) < $TTL))
	{
#		main::_log("from cache");
		return %{$slave_status{$db_h}{'hash'}};
	}
	
#	main::_log("read $db_h slave status (seconds behind)");
	TOM::Database::connect::multi($db_h) unless $main::DB{$db_h};
	
	if ($Redis && ($db_h=~/^main:/))
	{
		my $changetime=$Redis->get('C3|db_main|modified');
		if ($changetime)
		{
#			main::_log("modifytime=$changetime");
			my $db0=$main::DB{$db_h}->Query("SELECT timestamp FROM TOM.a100_master LIMIT 1");
			my %db0_line=$db0->fetchhash();
			my $changetime_slave=$db0_line{'timestamp'};
#			main::_log("modifytime_slave=$changetime_slave");
			
			$db0_line{'Seconds_Behind_Master'}=int(($changetime-$changetime_slave)*10000)/10000;
			if ($db0_line{'Seconds_Behind_Master'} > 300)
			{
				main::_log("SQL: Seconds_Behind_Master too high. $db0_line{'Seconds_Behind_Master'}s",1);
				main::_log("{$db_h} Seconds_Behind_Master too high. $db0_line{'Seconds_Behind_Master'}s",4,"sql.err");
				main::_log("[$tom::H] {$db_h} Seconds_Behind_Master too high. $db0_line{'Seconds_Behind_Master'}s",4,"sql.err",1) if $tom::H;
			}
			else
			{
#				main::_log("{$db_h} Seconds_Behind_Master $db0_line{'Seconds_Behind_Master'}s");
			}
			$slave_status{$db_h}{'time'}=time();
			%{$slave_status{$db_h}{'hash'}}=%db0_line;
			return %db0_line;
		}
	}
	
	my $db0=$main::DB{$db_h}->Query("SHOW SLAVE STATUS");
	my %db0_line=$db0->fetchhash();
	
	if ($db0_line{'Seconds_Behind_Master'} > 300)
	{
		main::_log("SQL: Seconds_Behind_Master too high. $db0_line{'Seconds_Behind_Master'}s",1);
		main::_log("{$db_h} Seconds_Behind_Master too high. $db0_line{'Seconds_Behind_Master'}s",4,"sql.err");
		main::_log("[$tom::H] {$db_h} Seconds_Behind_Master too high. $db0_line{'Seconds_Behind_Master'}s",4,"sql.err",1) if $tom::H;
	}
	
	$slave_status{$db_h}{'time'}=time();
	%{$slave_status{$db_h}{'hash'}}=%db0_line;
	return %db0_line;
}



=head2 execute($SQL,'db_h'=>'main')

Executes SQL query and return hash with variables

 %sth=TOM::Database::SQL::execute(
   $SQL,
   'bind' => ["value1","value2"],
   'db_h' => "main",
   '-slave' => 1 # is safe to execute this SQL query on slave server?
                # other queries than SELECT will be executed on master
   '-cache' => 1 # cache this SQL query
                # number represents seconds in cache
   '-schedule' => 1 # schedule this cache query to backend execution
	'-long' => 2 # log this query when longer than 2s
   '-recache' => 1 # re-cache force this query
   '-cache_auto' => 1 # cache this SQL query when Memcached availability is higher than MySQL query cache
                     # number represents seconds in cache
 );
 # %sth={'sth', 'rows', 'info', 'err'};
 while (my %db_line=$sth{'sth'}->fetchhash())
 {
   # parsing data
 }

Example of binding params into SQL

 my %sth0=TOM::Database::SQL::execute(qq{
     SELECT
       *
     FROM
       TOM.a301_user
     WHERE
       ID_user LIKE ? OR ID_user LIKE ?
     LIMIT 1
   },
   'bind' => ["c%","b%"]
 );

=cut

sub execute
{
	my $SQL=shift;
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."::execute()",'namespace'=>"SQL",'quiet' => $env{'quiet'},'timer'=>1);
	  
	# when I'm sometimes really wrong ;)
	my $typeselect=0; # select query?
	$env{'slave'}=$env{'slave'} || $env{'-slave'};
	$env{'cache'}=$env{'cache'} || $env{'-cache'};
	$env{'cache_auto'}=$env{'cache_auto'} || $env{'-cache_auto'};
	$env{'-long'}=$logquery_long unless $env{'-long'};
	$env{'-changetime'} = $env{'-changetime'} || $env{'-cache_changetime'};
	# no, TOM::Database::SQL::cache, changes 1s to default value
	#if ($env{'cache'} == 1){$env{'cache'}=60}; # default is 60 seconds
	
	my %output;
	
	$SQL=~s|^[\t\n\r]+||;
	if ($SQL=~/-- db_h=([a-zA-Z0-9]*)/)
	{
		$env{'db_h'}=$1;
		main::_log("db_h changed by comment to '$env{db_h}'") unless $env{'quiet'};
	}
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_h_orig'}=$env{'db_h'};
	
	$typeselect=1 if $SQL=~/^(\(\s+SELECT|SELECT)/;
	
	if ($env{'slave'} && $TOM::DB{$env{'db_h'}}{'slaves'} && $typeselect)
	{
		my $slave=int(rand($TOM::DB{$env{'db_h'}}{'slaves'}))+1;
		if ($TOM::DB{$env{'db_h'}.':'.$slave})
		{
			# check quality of this slave
			my %slave_quality=get_slave_status($env{'db_h'}.':'.$slave);
			
			if ($env{'-changetime'} &&
				($slave_quality{'Seconds_Behind_Master'} &&
				(time()-$slave_quality{'Seconds_Behind_Master'}-60 < $env{'-changetime'})))
			{
				main::_log("slave '$slave' is behind master:$slave_quality{'Seconds_Behind_Master'}s, data changed ".(time()-$env{'-changetime'})."s before now, using master") unless $env{'quiet'};
			}
			elsif ($slave_quality{'Seconds_Behind_Master'} > $TOM::DB_mysql_seconds_behind_master_max)
			{
				main::_log("slave '$slave' is outdated (behind master:$slave_quality{'Seconds_Behind_Master'}s), using master",1);
			}
			else
			{
				main::_log("using slave '$slave' (behind master:$slave_quality{'Seconds_Behind_Master'}s)".do{
					if ($env{'-changetime'})
					{
						" (changetime -".int(time()-$env{'-changetime'})."s)";
					}
				}) unless $env{'quiet'};
				$env{'db_h'}=$env{'db_h'}.':'.$slave;
			}
		}
	}
	
	TOM::Database::connect::multi($env{'db_h'}) unless $main::DB{$env{'db_h'}};
	if (!$main::DB{$env{'db_h'}})
	{
		main::_log("can't connect db_h=$env{'db_h'}",1);
		$t->close();
		return 1;
	}
	
	# subtype of connected handler (MySQL or MsSQL?)
	my $subtype;
	$subtype = $TOM::DB{$env{'db_h'}}{'subtype'};
	if ($subtype && $env{$subtype})
	{
		$SQL = $env{$subtype};
	}
		
	main::_log("db_h='$env{'db_h'}'") unless $env{'quiet'};
	if ($env{'log'})
	{
		foreach my $line(split("\n",$SQL))
		{
			$line=~s|\t|   |g;
			$line=~s|[\t ]+$||g;
			main::_log($line) unless $env{'quiet'};
		}
	}
	
	my ($package, $filename, $line) = caller;
	
	my $SQL_=$SQL;
	$SQL_=~s|[\n\t\r]+| |gms;
	$SQL_=~s|^[ ]+||;
	$SQL_=~s|[ ]+$||;
	
	my $cache_key=$TOM::DB{$env{'db_h_orig'}}{'host'};
	$cache_key.='::'.$TOM::DB{$env{'db_h_orig'}}{'name'}.':'.$TOM::DB{$env{'db_h_orig'}}{'uri'}
		if $TOM::DB{$env{'db_h_orig'}}{'type'} eq "DBI";
#	$cache_key.='::'.$env{'db_name'}.'::'.$SQL_;
	$cache_key.='::'.$SQL_;
	foreach (@{$env{'bind'}})
	{
		$cache_key.="::".$_;
	}
	
#	main::_log("cache_key='$cache_key'") if $env{'log'};
	
	$typeselect=1 if $SQL_=~/^(\(\s+SELECT|SELECT)/;
	if (($env{'cache'} || $env{'cache_auto'}) && $TOM::CACHE && $TOM::CACHE_memcached && ($typeselect || $env{'cache_force'}) && $main::FORM{'_rc'}!=-2)
	{
		main::_log("SQL: try to read from cache") if $env{'log'};
		
		my $cache=new TOM::Database::SQL::cache(
			'id' => $cache_key
		);
		
		if ($env{'-changetime'})
		{
			main::_log("SQL: db changed before ".int(time()-$env{'-changetime'})."s. cache created ".int($cache->{'value'}->{'time'}-$env{'-changetime'})."s after db changes (min old:$env{'-cache_min'}s)") if $env{'log'};
		}
		
		if ($cache && $env{'-changetime'} && ($env{'-changetime'})>$cache->{'value'}->{'time'} && ((time()-$cache->{'value'}->{'time'})>$env{'-cache_min'}) )
		{
			main::_log("SQL: don't use this cache, data changed") if $env{'log'};
		}
		elsif ($env{'-recache'})
		{
			main::_log("SQL: don't use this cache, -recache is enabled") if $env{'log'};
		}
		elsif ($cache)
		{
			main::_log("SQL: readed from cache '".($cache->{'value'}->{'rows'})."' rows (".(time()-$cache->{'value'}->{'time'})."s old)") if $env{'log'};
			main::_log("{$env{'db_h_orig'}:cache} '$SQL_' from '$filename:$line'",3,"sql") if $logcachequery;
			$output{'sth'}=$cache;
			$output{'info'}=$cache->{'value'}->{'info'};
			$output{'err'}=$cache->{'value'}->{'err'};
			$output{'rows'}=$cache->{'value'}->{'rows'};
			$output{'time'}=$cache->{'value'}->{'time'};
			
			if ($TOM::DEBUG_cache)
			{
				my $cache_key_id=TOM::Digest::hash($cache_key);
				$Ext::CacheMemcache::cache->incr(
					'namespace' => "sqlcache_hits",
					'key' => $cache_key_id
				);
				my $hits=$Ext::CacheMemcache::cache->get(
					'namespace' => "sqlcache_hits",
					'key' => $cache_key_id
				);
				my $hpm=0;
				$hpm=int($hits/((time()-$cache->{'value'}->{'time'})/60))
					if (((time()-$cache->{'value'}->{'time'})/60));
				main::_log("[sql][".$cache_key_id."][HIT] name='".substr($SQL_,0,80)."...' (start:".$cache->{'value'}->{'time'}." old:".(time()-$cache->{'value'}->{'time'})." hits:$hits hpm:".$hpm.")",3,"cache");
				main::_log("[sql][$tom::H][".$cache_key_id."][HIT]",3,"cache",1);
			}
			
			$t->close();
			return %output;
		}
		else
		{
			main::_log("SQL: not available cache") if $env{'log'};
		}
	}
	
	#main::_log("{$env{'db_h'}:exec} '$SQL_' from '$filename:$line'",3,"sql") if $logquery;
	
	if ($TOM::DB{$env{'db_h'}}{'type'} eq "DBI")
	{
		$output{'type'} = "DBI";
		
		# how much of binary columns we want (MsSQL)
		if ($TOM::DB{$env{'db_h'}}{'uri'}=~/^dbi:Sybase:/)
		{
		}
		else
		{
			$main::DB{$env{'db_h'}}->{'LongReadLen'} = 512 * 1024;
		}
		
		$output{'sth'} = $main::DB{$env{'db_h'}}->prepare($SQL,{'ora_auto_lob'=>0});
		#$output{'err'} = $DBI::errstr unless $output{'sth'};
		$output{'err'}=$main::DB{$env{'db_h'}}->errstr();
		
		if (not $output{'sth'})
		{
			if ($output{'err'})
			{
				my ($package, $filename, $line) = caller;
				main::_log("SQL prepare: err=".$output{'err'},1);# unless $env{'quiet'};
				main::_log("{$env{'db_h'}} SQL prepare='$SQL_' err='$output{'err'}' from $package:$filename:$line",4,"sql.err");
				main::_log("[$tom::H] {$env{'db_h'}} SQL prepare='$SQL_' err='$output{'err'}' from $package:$filename:$line",4,"sql.err",1) if $tom::H;
				
				if ($output{'err'}=~/ORA-03114/) # hapal dole Orákulum
				{
					# vynutime reconnect, ale tento query je uz strateny
					undef $main::DB{$env{'db_h'}};
				}
				
				if ($output{'err'}=~/Attempt to initiate a new Adaptive Server/
					|| $output{'err'}=~/Adaptive Server connection timed out/) # hapalo dole MsSQL
				{
					# vynutime reconnect
					undef $main::DB{$env{'db_h'}};
					
					if ($TOM::DB_DBI_sql_recall) # if auto-reconnect disabled, do it manually
					{
						main::_log("{$env{'db_h'}} lost connection ",4,"sql.err");
						main::_log("[$tom::H] {$env{'db_h'}} lost connection",4,"sql.err",1);
#						main::_log("lost connection, re-connecting '$env{'db_h'}'",4,"sql.err");
						
						TOM::Database::connect::disconnect($env{'db_h'}); # removes handlers
						TOM::Database::connect::multi($env{'db_h'}) || do 
						{
							main::_log("{'$env{'db_h'}'} can't be reconnected",1);
							# can't be reconnected
							main::_log("{$env{'db_h'}} DBI server can't be reconnected",4,"sql.err");
							main::_log("[$tom::H] {$env{'db_h'}} DBI server can't be reconnected",4,"sql.err",1);
							$t->close();
							return undef;
						};
						main::_log("SQL: sucesfully reconnected '$env{'db_h'}'");
					}
					
					if ($package eq "TOM::Database::SQL")
					{
						$t->close();
						return undef;
					}
					
					main::_log("SQL: trying to re-call the query");
					$t->close();
					return TOM::Database::SQL::execute($SQL,%env,'quiet'=>0);
					
				}
				
			}
			main::_log("output info=".$output{'info'}) if (!$env{'quiet'} && $output{'info'});
			$t->close();
			return %output;
		}
		
		if ($env{'bind'}){$output{'sth'}->execute(@{$env{'bind'}});}
		else {$output{'sth'}->execute()}
		
		$output{'rows'}=$output{'sth'}->rows;
		
		$output{'err'} = $main::DB{$env{'db_h'}}->errstr();
		
		if ($output{'err'})
		{
			my ($package, $filename, $line) = caller;
			main::_log("SQL: err=".$output{'err'},1);# unless $env{'quiet'};
			main::_log("{$env{'db_h'}} SQL='$SQL_' err='$output{'err'}' from $package:$filename:$line",4,"sql.err");
			main::_log("[$tom::H] {$env{'db_h'}} SQL='$SQL_' err='$output{'err'}' from $package:$filename:$line",4,"sql.err",1) if $tom::H;
			
			main::_log("output info=".$output{'info'}) if (!$env{'quiet'} && $output{'info'});
			
			if ($output{'err'}=~/ORA-03114/) # hapal dole Orákulum
			{
				main::_log("{$env{'db_h'}} lost connection ",4,"sql.err");
				main::_log("[$tom::H] {$env{'db_h'}} lost connection",4,"sql.err",1);
				# vynutime reconnect, ale tento query je uz strateny
				undef $main::DB{$env{'db_h'}};
			}
			
			if ($output{'err'}=~/Attempt to initiate a new Adaptive Server/) # hapalo dole MsSQL
			{
				main::_log("{$env{'db_h'}} lost connection ",4,"sql.err");
				main::_log("[$tom::H] {$env{'db_h'}} lost connection",4,"sql.err",1);
				# vynutime reconnect, ale tento query je uz strateny
				undef $main::DB{$env{'db_h'}};
			}
			
			if ($output{'err'}=~/Adaptive Server connection timed out/) # hapalo dole MsSQL
			{
				main::_log("{$env{'db_h'}} lost connection ",4,"sql.err");
				main::_log("[$tom::H] {$env{'db_h'}} lost connection",4,"sql.err",1);
				# vynutime reconnect, ale tento query je uz strateny
				undef $main::DB{$env{'db_h'}};
			}
			
			undef $output{'sth'};
			$t->close();
			return %output;
		}
		
	}
	else # standard MySQL
	{
		my $result;
		$output{'sth'}=$main::DB{$env{'db_h'}}{'dbh'}->prepare($SQL);
		if ($env{'bind'}){$result=$output{'sth'}->execute(@{$env{'bind'}});}
		else {$result=$output{'sth'}->execute();}
		
		$output{'info'}=$main::DB{$env{'db_h'}}->info();
		$output{'err'}=$main::DB{$env{'db_h'}}->errmsg();
		
		undef $output{'sth'} unless $result; # backward compatibility
		
		if (not $output{'sth'} || $subtype)
		{
			if ($output{'err'})
			{
				my ($package, $filename, $line) = caller;
				main::_log("SQL: ".$output{'err'},1);# unless $env{'quiet'};
				main::_log("{$env{'db_h'}} SQL='$SQL_' err='$output{'err'}' from $package:$filename:$line",4,"sql.err");
				main::_log("[$tom::H] {$env{'db_h'}} SQL='$SQL_' err='$output{'err'}' from $package:$filename:$line",4,"sql.err",1) if $tom::H;
				if ($save_error && 
					(
						$output{'err'} ne "MySQL server has gone away"
					)
				)
				{
					my %date=Utils::datetime::ctodatetime(time,format=>1);
					open(SUSP,">".$TOM::P."/_logs/_debug/".$date{'hour'}.":".$date{'min'}.":".$date{'sec'}."-".$$.".sql.err.event");
					print SUSP "domain: $tom::H\n";
					print SUSP "db_h: $env{'db_h'}\n";
					print SUSP "from:\n";
					my $i;
					while (my ($package, $filename, $line) = caller($i))
					{
						last unless $filename;
						print SUSP "\t$package:$filename:$line\n";
						$i++;
					}
					print SUSP "err: $output{'err'}\n";
					print SUSP "---\n";
					print SUSP $SQL."\n";
					print SUSP "---\n";
					close(SUSP);
				}
				
				if ($output{'err'} eq "MySQL server has gone away" ||
					$output{'err'} eq "Lost connection to MySQL server during query") # hapal dole MySQL
				{
					main::_log("{$env{'db_h'}} MySQL server has gone away",4,"sql.err");
					main::_log("[$tom::H] {$env{'db_h'}} MySQL server has gone away",4,"sql.err",1);
					
					main::_log("SQL: trying to reconnect '$env{'db_h'}' and re-call this SQL query");
					
					if (!$TOM::DB_mysql_auto_reconnect) # if auto-reconnect disabled, do it manually
					{
						TOM::Database::connect::disconnect($env{'db_h'}); # removes handlers
						TOM::Database::connect::multi($env{'db_h'}) || do 
						{
							main::_log("{'$env{'db_h'}'} can't be reconnected",1);
							# can't be reconnected
							main::_log("{$env{'db_h'}} MySQL server can't be reconnected",4,"sql.err");
							main::_log("[$tom::H] {$env{'db_h'}} MySQL server can't be reconnected",4,"sql.err",1);
							$t->close();
							return undef;
						};
						main::_log("SQL: sucesfully reconnected '$env{'db_h'}'");
					}
					
					if ($package eq "TOM::Database::SQL")
					{
						$t->close();
						return undef;
					}
					
					main::_log("SQL: trying to re-call the query");
					$t->close();
					return TOM::Database::SQL::execute($SQL,%env,'quiet'=>0);
				}
				
			}
			main::_log("output info=".$output{'info'}) if (!$env{'quiet'} && $output{'info'});
			$t->close();
			return %output;
		}
		
		$output{'rows'}=$output{'sth'}->affectedrows();
	}
	
	# error in output
	if ($output{'err'})
	{
		main::_log("SQL: err=".$output{'err'},1);# unless $env{'quiet'};
		main::_log("{$env{'db_h'}} SQL='$SQL_' err='$output{'err'}' from $package:$filename:$line",4,"sql.err");
		main::_log("[$tom::H] {$env{'db_h'}} SQL='$SQL_' err='$output{'err'}' from $package:$filename:$line",4,"sql.err",1);
	}
	
	if ($TOM::DB{$env{'db_h'}}{'type'} ne "DBI")
	{
		main::_log("affectedrows='".$output{'rows'}."'") unless $env{'quiet'};
		main::_log("output info=".$output{'info'}) if (!$env{'quiet'} && $output{'info'});
	}
	
	$t->close();
	
	if ($env{'cache_auto'} && ($typeselect || $env{'cache_force'}) && $t->{'time'}{'req'}{'duration'} >= $query_long_autocache)
	{
		main::_log("SQL: cache_auto used to cache, because query long") if $env{'log'};
		$env{'cache'} = $env{'cache_auto'};
	}
	if ($env{'cache'} && $TOM::CACHE && $TOM::CACHE_memcached && ($typeselect || $env{'cache_force'}))
	{
		main::_log("SQL: saving to cache") if $env{'log'};
		$output{'sth'}=new TOM::Database::SQL::cache(
			'sth'=> $output{'sth'}, # we are saving output from STH
			'err'=> $output{'err'},
			'type'=> $output{'type'},
			'info'=> $output{'info'},
			'rows'=> $output{'rows'},
			'expire' => $env{'cache'},
			'schedule' => $env{'-schedule'},
			'schedule_group' => $env{'-schedule_group'},
#			'from' => "$package:$filename:$line",
			'recache' => $env{'-recache'},
			'sql' => $SQL,
			'db_h' => $env{'db_h'},
			'time' => $output{'time'},
			'id'=> $cache_key
		);
		
		if ($TOM::DEBUG_cache)
		{
			my $cache_key_id=TOM::Digest::hash($cache_key);
			$Ext::CacheMemcache::cache->set(
				'namespace' => "sqlcache_hits",
				'key' => $cache_key_id,
				'value' => 0
			);
			main::_log("[sql][".$cache_key_id."][CRT] name='".substr($SQL_,0,80)."...' (start:".time().")",3,"cache");
			main::_log("[sql][$tom::H][".$cache_key_id."][CRT]",3,"cache",1);
		}
		
	}
	
	if ($logquery || (!$typeselect && $lognonselectquery))
	{
		my $caller_plus;
		my ($package_, $filename_, $line_) = caller(1);
		if ($filename_)
		{
			$caller_plus.="/$package_:$filename_:$line_";
			($package_, $filename_, $line_) = caller(2);
			if ($filename_)
			{
				$caller_plus.="/$package_:$filename_:$line_";
			}
		}
		main::_log("{$env{'db_h'}:exec:".($t->{'time'}{'req'}{'duration'})."s} '$SQL_' from '$package:$filename:$line'$caller_plus",3,"sql");
	}
	
	if ($logquery_long && ($t->{'time'}{'req'}{'duration'} > $env{'-long'}))
	{
		main::_log("{$env{'db_h'}} executed ".($t->{'time'}{'req'}{'duration'})."s query",1);
		main::_log("{$env{'db_h'}} duration:".($t->{'time'}{'req'}{'duration'})."s SQL='$SQL_' from $package:$filename:$line",4,"sql.long");
		main::_log("[$tom::H] {$env{'db_h'}} duration:".($t->{'time'}{'req'}{'duration'})."s SQL='$SQL_' from $package:$filename:$line",4,"sql.long",1) if $tom::H;
	}
	
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
	
	if ($main::DB{$db_h}->{'Driver'}->{'Name'} eq 'ODBC')
	{
		if ($main::DB{$db_h}->{'Name'} =~ /driver=\{SQL Native Client\}/)
		{
			my $version = 'MSSQL';
			return $version;
		}
	}
	else
	{
		my $version=$main::DB{$db_h}->getserverinfo();
			$version=~s|^([\d]+)\.([\d]+)\.(.*)$|\1.\2|;
			
		main::_log("MySQL version on handler '$db_h'='$version'") if $debug;
		
		return $version;
	}
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

package DBI::db;
# provide methods fetchrow and Query, often used (old Mysql way)

sub AUTOLOAD
{
	(my $method = our $AUTOLOAD) =~ s/.*:://;
	my $self = shift;
	
	return if ($method eq 'DESTROY');
	
	# Query (from Mysql)
	if ($method eq 'Query')
	{
		return unless (my $query = shift);
		
		my $sth = $self->prepare($query);
		$sth->execute();
		
		return $sth;
	}
}

package DBI::st;
# provide methods fetchhash and insertid if missing

sub AUTOLOAD
{
	(my $method = our $AUTOLOAD) =~ s/.*:://;
	my $self = shift;
	
	return if ($method eq 'DESTROY');
	
	# fetchhash (from Mysql)
	if ($method eq 'fetchhash')
	{
		my %outhash;
		
		my $hashref = $self->fetchrow_hashref();
		
		if ($hashref)
		{
			foreach my $item (keys %{$hashref})
			{
				$outhash{$item} = $hashref -> {$item};
			}  
			return %outhash;
		}
		else
		{
			return;
		}
	}
	
	# insertid (from Mysql))
	elsif ($method eq 'insertid')
	{
		my $dbh = $self->{'Database'}; # reference to my parent database handle
	
		# SELECT last inserted autoincrement column - MS SQL
		my $sth = $dbh->prepare('SELECT @@IDENTITY;');
		$sth->execute();
		my @results = $sth->fetchrow_array();
	
		return $results[0] if (@results); 
	}
	else
	{
		die("DBI::st::$method is undefined and could not be autloaded.");
	}
	
}

1;