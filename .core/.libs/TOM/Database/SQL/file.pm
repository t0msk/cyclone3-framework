package TOM::Database::SQL::file;

=head1 NAME

TOM::Database::SQL::file

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 VARIABLES

 $debug - debug

=cut


our $debug=1;


=head1 FUNCTIONS

=head2 get_sqlfile_header(filename,\%sql_header)

Prečíta header SQL dávkového suboru a naplní predaný %sql_header hodnotami z headeru

 -- premenna=value
 -- premenna2=/*premenna*/_estenieco
 -- ---------------------------------------

=cut

sub get_sqlfile_header
{
	my $file=shift;
	my $header=shift;
	my $t=track TOM::Debug(__PACKAGE__."::get_sqlfile_header('$file')");
	
	open(SQLFILE,'<'.$file) || die "can't open file $file $!";
	my $data;
	while (my $line=<SQLFILE>)
	{
		last if $line=~/^-- --/;
		$data.=$line;
	}
	close(SQLFILE);
	
	_sqlheader_process($data,$header);
	
	$t->close();
	return 1;
}

sub _sqlheader_process
{
	my $data=shift;
	my $header=shift;
	
	foreach my $line(split('\n',$data))
	{
		$line=~s|[\r\n]||g;
		next unless $line=~s/^-- //;
		next unless $line;
		
		my @var=split("=",$line,2);
		next if $var[0]=~/^--/;
		
		if ($var[0] eq "db_name" && $var[1] eq "local")
		{
			$var[1]=$TOM::DB{'main'}{'name'};
		}
		$header->{$var[0]}=$var[1];
		main::_log("set '$var[0]'='$header->{$var[0]}'");;
		
		if ($var[0] eq "addon" && $tom::H)
		{
			# try to override db_name, when addon is installed into another domain
			if ($var[1]=~s/^a//)
			{
				my $db_name;
				eval "\$db_name=\$App::".$var[1]."::db_name || \$TOM::DB{'main'}{'name'}";
				$header->{'db_name'}=$db_name;
				main::_log("re-set 'db_name'='$db_name'");
			}
		}
	}
	
	return 1;
}


=head2 get_sqlfile_chunks

Vezme sql súbor a vyparsuje z neho jednotlivé chunky

 -- premenna=value
 -- db_name=example_tld
 
 CREATE TABLE `/*db_name*/`.`/*app*/_arch` (
  `ID` int(10) unsigned NOT NULL default '0',
  `starttime` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  KEY `starttime` (`starttime`)
 ) TYPE=MyISAM;
 -- -------------------------------------------------

=cut

sub get_sqlfile_chunks
{
	my $filename=shift;
	my $t=track TOM::Debug(__PACKAGE__."::get_sqlfile_chunks('$filename')");
	my @chunks;
	
	open(SQLFILE,'<'.$filename) || return undef;
	my $data;
	while (my $line=<SQLFILE>){$data.=$line;}
	close(SQLFILE);
	
	# vkladanie platnych chunkov do pola
	foreach my $chunk(split(/-- -{40,}\n/,$data))
	{
		next unless $chunk;
		my $chunk_ok;
		foreach my $line(split('\n',$chunk))
		{
			$line=~s|[\s]||g;
			next if $line=~/^--/;
			next unless $line;
			$chunk_ok=1;
			last;
		}
		if ($chunk_ok)
		{
			main::_log("chunk length(".(length($chunk)).") bytes");
			push @chunks, $chunk;
		}
	}
	
	$t->close();
	return @chunks;
}


=head2 install()

Nainštaluje SQL dávku chunkov do databázy. 1 SQl dávka predstavuje napr. jednu aplikáciu

=cut

sub install
{
	my $what=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::install('$what')");
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my %output;
	
	my %sql_header;
	
	main::_log("reading header from TOM.sql");
	get_sqlfile_header($TOM::P.'/.core/.libs/TOM/Database/SQL/TOM.sql',\%sql_header);
	
	main::_log("overriding header by \@_");
	foreach (keys %env)
	{
		next if $_=~/^-/;
		$sql_header{$_}=$env{$_};
		main::_log("set '$_'='$sql_header{$_}'");
	}
	
	my $filename;
	if ($what=~s/^a//)
	{
		main::_log("application '$what'");
		# searching localized structure in domain
		if (-e $tom::P.'/_addons/App/'.$what.'/a'.$what.'_struct.sql')
		{
			$filename=$tom::P.'/_addons/App/'.$what.'/a'.$what.'_struct.sql';
		}
		
		if (not $what=~/^01/) # this is definition of local app
		{
			# look into overlays
			if (!$filename)
			{
				foreach (@TOM::Overlays::item)
				{
					if ($_=~/^\// && -e $_.'/_addons/App/'.$what.'/a'.$what.'_struct.sql')
					{
						$filename=$_.'/_addons/App/'.$what.'/a'.$what.'_struct.sql';
						last;
					}
					elsif (-e $TOM::P.'/_overlays/'.$_.'/_addons/App/'.$what.'/a'.$what.'_struct.sql')
					{
						$filename=$TOM::P.'/_overlays/'.$_.'/_addons/App/'.$what.'/a'.$what.'_struct.sql';
						last;
					}
				}
			}
			
			# or in global
			if (!$filename && -e $TOM::P.'/_addons/App/'.$what.'/a'.$what.'_struct.sql')
			{
				$filename=$TOM::P.'/_addons/App/'.$what.'/a'.$what.'_struct.sql';
			}
		}
		
		# definition file not found
		if (!$filename)
		{
			main::_log("SQL file of structure application '$what' not exists",1);
			main::_log_stdout("SQL file of structure application '$what' not exists",4);
			$t->close();
			#die "SQL file of structure application '$what' not exists";
			return undef;
		}
	}
	elsif ($what=~s/^_//)
	{
		main::_log("standardized package '$what'");
		# searching localized structure in domain
		if (-e $tom::P.'/_data/_'.$what.'_struct.sql')
		{
			$filename=$tom::P.'/_data/_'.$what.'_struct.sql';
		}
		# or in global library
		elsif (-e $TOM::P.'/.core/.libs/TOM/Database/SQL/_'.$what.'_struct.sql')
		{
			$filename=$TOM::P.'/.core/.libs/TOM/Database/SQL/_'.$what.'_struct.sql';
		}
		else
		{
			main::_log("SQL file of structure standardized '$what' not exists",1);
			main::_log_stdout("SQL file of structure standardized '$what' not exists",4);
			$t->close();
			#die "SQL file of structure standardized '$what' not exists";
			return undef;
		}
	}
	elsif ($what eq $TOM::DB_name)
	{
		main::_log("global '$what'");
		$filename=$TOM::P.'/.core/.libs/TOM/Database/SQL/TOM_struct.sql';
	}
	else
	{
		main::_log("unknown SQL file '$what'",1);
		$t->close();
		die "unknown SQL file '$what'";
	}
	
	main::_log("filename of sqlfile is '$filename'");
	
	main::_log("reading header from this sqlfile");
	get_sqlfile_header($filename,\%sql_header);
	
	main::_log("reading chunks from this sqlfile");
	my $i;
	foreach my $chunk (get_sqlfile_chunks($filename,\%sql_header))
	{
		$i++;
		main::_log("chunk '$i'");
		my %sql_header=%sql_header; #sql_header localization
		# get header from chunk
		_sqlheader_process($chunk,\%sql_header);
		# chunk cleaning
		_chunk_prepare(\$chunk,\%sql_header);
		# installing (and comparing) chunk
		# zakazujem vykonanie ALTER prikazov, vykonam ich nakonci naraz
		my %input=install_table($chunk, \%sql_header, %env, '-compare_execute' => 0);
		push @{$output{'ALTER'}}, @{$input{'ALTER'}} if $input{'ALTER'};
	}
	
	# zozbieram vsetky ALTER prikazy a vykonam ich az teraz, ak je '-compare_execute'=>1
	foreach my $SQL_ALTER (@{$output{'ALTER'}})
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

sub _chunk_prepare
{
	my $chunk=shift;
	my $header=shift;
	my $t=track TOM::Debug(__PACKAGE__."::_chunk_prepare");
	
	$$chunk=~s|^\s+||;
	$$chunk=~s|\s+$||;
	
	# odstranim zbytocne riadky
	my $data;
	foreach my $line(split('\n',$$chunk))
	{
		$line=~s|[\n\r]||g;
		$line=~s|-- (.*)$||; # odstranim commenty na konci riadkov
		$line=~s|\s+$||g;
		next unless $line;
		next if $line=~/^--/;
		$data.=$line."\n";
	}
	$$chunk=$data;
	
	# zamenim premenne
	1 while($$chunk=~s|/\*(.*?)\*/|$header->{$1}|g);
	
	$$chunk=~s| TABLE| TABLE IF NOT EXISTS|;
	
	TOM::Database::connect::multi($header->{'db_h'}) unless $main::DB{$header->{'db_h'}};
	
	my $version;
	if ($main::DB{$header->{'db_h'}}->{Driver}->{Name} eq 'ODBC')
	{
		if ($main::DB{$header->{'db_h'}}->{Name} =~ /driver=\{SQL Native Client/)
		{
			$version = 'MSSQL';
		}
	}
	else
	{
		$version=$main::DB{$header->{'db_h'}}->getserverinfo();
			$version=~s|^([\d]+)\.([\d]+)\.(.*)$|\1.\2|;
		main::_log("MySQL version on handler '$header->{'db_h'}'='$version'");
	}
	
	if ($version eq 'MSSQL')
	{
		main::_log("converting SQL $header->{'version'} to MSSQL");
		
		# CREATE TABLE IF NOT EXISTS
		my @db_table = $$chunk =~ /CREATE TABLE IF NOT EXISTS `([^`]+)`.`([^`]+)`/i;
		
		if ($db_table[0] && $db_table[1])
		{
			
			$db_table[0] = $TOM::DB_name if ($TOM::DB_name && $db_table[0] eq 'TOM');
			
			my $add_code = qq{
					IF NOT EXISTS (
						SELECT * FROM sysobjects WHERE id = object_id(N'[$db_table[0]]..[$db_table[1]]')
						AND OBJECTPROPERTY(id, N'IsUserTable') = 1
					) CREATE TABLE [$db_table[0]]..[$db_table[1]] };
			$$chunk =~ s/CREATE TABLE IF NOT EXISTS `([^`]+)`.`([^`]+)`/$add_code/i;
		}
		
		$$chunk =~ s/CREATE OR REPLACE VIEW/CREATE VIEW/gi;
		
		# FIX ENCODINGS
		# ASCII
		$$chunk =~ s/(var)?char\((\d+)\) character set ascii( collate ascii_bin)?/\1char\(\2\)/gi;
		# UTF8
		$$chunk =~ s/(var)?char\((\d+)\) character set utf8( collate utf8_bin| collate utf8_unicode_ci)?/n\1char\(\2\)/gi;
		# TEXT
		$$chunk =~ s/ (long|tiny)?text character set.*unicode_ci/ nvarchar\(max\)/gi;
		$$chunk =~ s/(tiny)?text character set ascii( collate ascii_bin)?/nvarchar\(max\)/gi;
		
		# VARCHAR BINARY (???)
		
		$$chunk =~ s/varchar\((\d+)\) binary/nvarchar\(\1\)/gi;
		
		# AUTO INCREMENT
		# some journalling tables have auto-increment too - they shouldn't have
		
		if ($db_table[1] =~ /(_j|a301_user_rel_group|a010_eform_sym)$/)
		{
		   $$chunk =~ s/auto_increment//gi;
		}
		else
		{
			$$chunk =~ s/auto_increment/IDENTITY(1,1)/gi;
		}
		
		# ZEROFILL - select statements will have to format manually
		$$chunk =~ s/ zerofill / /gi;
		
		# ESCAPE CHARACTERS
		$$chunk =~ s/`/\"/g;
		
		# NUMERIC TYPES, UNSIGNED - not supported by SQL server
		$$chunk =~ s/(smallint|tinyint)(\(\d+\)?) unsigned/int/gi;
		$$chunk =~ s/ (big|medium)?int(\(\d+\)?) unsigned/ bigint/gi;
		$$chunk =~ s/\bdouble\b/real/gi;
		$$chunk =~ s/bigint\(\d+\)/bigint/gi;
		$$chunk =~ s/ int\(\d+\) / bigint /gi;
		$$chunk =~ s/(smallint|tinyint)(\(\d+\)?)/int/gi;
		
		# UNIQUE KEY - also prepend table prefix to unique key name
		# $$chunk =~ s/UNIQUE KEY \"([^\"]+)\" \(([^)]+)\)/CONSTRAINT "$db_table[1]\1" UNIQUE (\2)/gi;
		# ACTUALLY LIFE WITHOUT UNIQUE KEYS IS EASIER
		$$chunk =~ s/UNIQUE KEY +\"([^\"]+)\" \(([^)]+)\),?//gi;
		
		# ALSO GET RID OF PRIMARY KEY, THIS IS MANAGED BY IDENTITY
		$$chunk =~ s/PRIMARY KEY +\(([^)]+)\),?//gi;
		
		# NO NOT NULL RESTRICTIONS
		$$chunk =~ s/ NOT NULL//gi;
		
		# BLOB
		$$chunk =~ s/(\"[^\"]+\") (medium)?blob/\1 varbinary(max)/gi;
		
		# KEY INDEX - ignore for now
		$$chunk =~ s/(FULLTEXT )?KEY +\"[^\"]+\" +\([^\)]+\) *,? *\n//gi;
		
		# REMOVE MYSQL-SPECIFIC ENGINE DIRECTIVES
		$$chunk =~ s/(TYPE|ENGINE)=(InnoDb|MyIsam)[^;]*//gi;
		
		# MSSQL 2005 doesn't support date type
		$$chunk =~ s/\bdate\b/datetime/gi;
		
		# CONCAT MySQL=CONCAT(a,b,c) MSSQL=a+b+c
		$$chunk =~ /CONCAT\ *\(([^\)]+)\)/;
		if ($1)
		{
			my $operands = $1;
			$operands =~ s/,/+/g;
			$$chunk =~ s/CONCAT\ *\(([^\)]+)\)/$operands/;
		}
		
		# SUBSTR
		$$chunk =~ s/\bSUBSTR\b/SUBSTRING/gi;
		
		# FUNCTIONS
		$$chunk =~ s/CURRENT_DATE\(\)/GETDATE()/gi;
		
		# FINALLY, REMOVE TRAILING COMMA
		
		$$chunk =~ s/,\s*\)\s*;/\n\);/m;
		
		# fix 301_user_group_j
		
		if ($db_table[1] eq 'a301_user_group_j')
		{
			$$chunk =~ s/\"perm_roles_override\"\s+varbinary\(max\)/\"perm_roles_override\" nvarchar\(max\)/;
		}
		
	}
	else # MySQL
	{
		
		# upgrade na vyssie verzie
		
		# 4.0 -> 4.1
		if ($header->{'version'} eq "4.0" && $version > $header->{'version'})
		{
			main::_log("converting SQL $header->{'version'} to 4.1");
			$header->{'version'}="4.1";
		}
		
		# 4.1 -> 5.0
		if ($header->{'version'} eq "4.1" && $version > $header->{'version'})
		{
			main::_log("converting SQL $header->{'version'} to 5.0");
			$header->{'version'}="5.0";
		}
		
		# 5.0 -> 5.1
		if ($header->{'version'} eq "5.0" && $version > $header->{'version'})
		{
			main::_log("converting SQL $header->{'version'} to 5.1");
			$$chunk=~s|collate|COLLATE|g;
			$$chunk=~s|character set|CHARACTER SET|g;
			$$chunk=~s| default| DEFAULT|g;
			$$chunk=~s|auto_increment|AUTO_INCREMENT|g;
			$$chunk=~s|PRIMARY KEY  |PRIMARY KEY |g;
			$$chunk=~s|TYPE=|ENGINE=|;
#		  $$chunk=~s|(int\(\d+\).*?) NOT NULL,|$1 NOT NULL DEFAULT '0',|g;
#		  $$chunk=~s|(float.*?) NOT NULL,|$1 NOT NULL DEFAULT '0',|g;
#		  $$chunk=~s|( datetime) NOT NULL,|$1 NOT NULL DEFAULT '2000-01-01 00:00:00',|g;
#		  $$chunk=~s|( date) NOT NULL,|$1 NOT NULL DEFAULT '2000-01-01',|g;
#		  $$chunk=~s|( time) NOT NULL,|$1 NOT NULL DEFAULT '00:00:00',|g;
#		  $$chunk=~s|NOT NULL,|NOT NULL DEFAULT '',|g;
			
			$$chunk=~s|([^8]) COLLATE utf8_unicode_ci |$1 CHARACTER SET utf8 COLLATE utf8_unicode_ci |g;
			$$chunk=~s|tinyint |tinyint(3) |g;
			$$chunk=~s| (text\|longtext)( .*?) DEFAULT NULL,| $1$2,|g;
			$$chunk=~s| (text\|tinytext\|longtext\|blob)( .*?)NOT NULL DEFAULT '',| $1$2NOT NULL,|g;
			$header->{'version'}="5.1";
		}
		
		
		# downgrade na nizsie verzie
		
		# 5.6 -> 5.5
		if ($header->{'version'} eq "5.6" && $version < $header->{'version'})
		{
			my $to='5.5';
			main::_log("converting SQL $header->{'version'} to $to");
			$$chunk=~s|datetime\(\d+\) |datetime |g;
			$header->{'version'}=$to;
		}
		
		# 5.0 -> 4.1
		if ($header->{'version'} eq "5.0" && $version < $header->{'version'})
		{
			my $to='4.1';
			main::_log("converting SQL $header->{'version'} to $to");
			$header->{'version'}=$to;
		}
		
		# 4.1 -> 4.0
		if ($header->{'version'} eq "4.1" && $version eq "4.0")
		{
			main::_log("converting SQL $header->{'version'} to $version");
			$$chunk=~s|ENGINE=|TYPE=|;
			$$chunk=~s|TYPE=InnoDB|TYPE=MyISAM|;
			$$chunk=~s|character set (.*?) ||g;
			$$chunk=~s|collate (.*?)_bin|binary|g;
			$$chunk=~s|collate (.*?) ||g;
			$$chunk=~s| DEFAULT CHARSET=(utf8\|ascii)||;
			$$chunk=~s|varchar\((.*?)NOT NULL,|varchar(\1NOT NULL default '',|g;
			$$chunk=~s|int\((.*?)NOT NULL,|int(\1NOT NULL default '0',|g;
			$header->{'version'}=$version;
		}
		
	}
	
	$t->close();
	return 1;
}


=head2 install_table($SQL,\%header,%env)

Inštaluje tabuľku pomocou pripraveného SQL príkazu "CREATE TABLE IF NOT EXISTS"

Prípadne vie porovnať existujúcu tabuľku a opraviť ju podľa vzoru

=cut

sub install_table
{
	my $t=track TOM::Debug(__PACKAGE__."::install_table()");
	my $SQL=shift;
	my $header=shift;
	my %env=@_;
	my %output;
	
	$SQL=~/(TABLE|VIEW|TRIGGER)(.*?) [`\[](.*?)[`\]]..?[`\[](.*?)[`\]]/ || do
	{
		main::_log("this chunk is not a table or view",1);
		$t->close();
		return undef;
	};
	
	my $database=$3;
	my $table=$4;
	
	# don't install more than twice
	if ($env{'-compare'})
	{
#		main::_log("  check if compared '".($database.'.'.$table.'@'.$header->{'db_h'})."'");
		if ($TOM::Database::SQL::compare::compared_tabe{$database.'.'.$table.'@'.$header->{'db_h'}})
		{
			$t->close();
			return undef;
		}
		$TOM::Database::SQL::compare::compared_tabe{$database.'.'.$table.'@'.$header->{'db_h'}}++;
	}
	
	main::_log("database='$database' table='$table' in db_h='$header->{'db_h'}'");
	main::_log_stdout("check $database.$table \@$header->{'db_h'}",3);
	
	TOM::Database::connect::multi($header->{'db_h'}) unless $main::DB{$header->{'db_h'}};
	
	if ($debug){foreach my $line(split('\n',$SQL)){main::_log("$line");}}
	
	main::_log("(re)installing view `$database`.`$table`",3) if $SQL=~/ VIEW /;
	if ($SQL=~/ TRIGGER /)
	{
		main::_log("(re)installing trigger `$database`.`$table`",3);
		TOM::Database::SQL::execute(qq{DROP TRIGGER IF EXISTS `$database`.`$table`},'db_h'=>$header->{'db_h'});
	}
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$header->{'db_h'});
	
	if ($env{'-compare'} && !$sth0{'err'} && not($SQL=~/ TRIGGER /))
	{
		main::_log("calling '-compare'");
		
		my $SQL_real=TOM::Database::SQL::show_create_table($header->{'db_h'},$database,$table);
		
		my @out=TOM::Database::SQL::compare::compare_create_table($SQL,$SQL_real);
		foreach my $SQL_ALTER (@out)
		{
			# when ALTER commands available, then reset compare counter of this table
			# it's better to check table twice when differences
			delete $TOM::Database::SQL::compare::compared_tabe{$database.'.'.$table.'@'.$header->{'db_h'}};
			
			$SQL_ALTER.=" -- db_h=".$header->{'db_h'};
			main::_log("ALTER='$SQL_ALTER'");
			push @{$output{'ALTER'}}, $SQL_ALTER;
			if ($env{'-compare_execute'})
			{
				my %sth1=TOM::Database::SQL::execute($SQL_ALTER);
			}
		}
		
	}
	elsif ($sth0{'err'})
	{
		main::_log_stdout("error $sth0{'err'} in '$SQL'",4);
	}
	
	$t->close();
	return %output;
}

1;
