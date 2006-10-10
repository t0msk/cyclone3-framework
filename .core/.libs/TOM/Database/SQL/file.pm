package TOM::Database::SQL::file;

=head1 NAME

TOM::Database::SQL::file

=cut

use open ':utf8', ':std';
use encoding 'utf8';
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
		$header->{$var[0]}=$var[1];
		main::_log("set '$var[0]'='$header->{$var[0]}'");;
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
		if (-e $tom::P.'/.libs/App/'.$what.'/a'.$what.'_struct.sql')
		{
			$filename=$tom::P.'/.libs/App/'.$what.'/a'.$what.'_struct.sql';
		}
		# or in global library
		elsif (-e $TOM::P.'/.core/.libs/App/'.$what.'/a'.$what.'_struct.sql')
		{
			$filename=$TOM::P.'/.core/.libs/App/'.$what.'/a'.$what.'_struct.sql';
		}
		else
		{
			main::_log("SQL file of structure application '$what' not exists",1);
			$t->close();
			die "SQL file of structure application '$what' not exists";
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
			$t->close();
			die "SQL file of structure standardized '$what' not exists";
		}
	}
	elsif ($what eq "TOM")
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
			my @eout=TOM::Database::SQL::execute($SQL_ALTER);
		}
	}
	
	$t->close();
	return %output;
}

sub _chunk_prepare
{
	my $chunk=shift;
	my $header=shift;
	
	$$chunk=~s|^\s+||;
	$$chunk=~s|\s+$||;
	
	# odstranim zbytocne riadky
	my $data;
	foreach my $line(split('\n',$$chunk))
	{
		$line=~s|[\n\r]||g;
		$line=~s|--(.*)$||; # odstranim commenty na konci riadkov
		$line=~s|\s+$||g;
		next unless $line;
		next if $line=~/^--/;
		$data.=$line."\n";
	}
	$$chunk=$data;
	
	# zamenim premenne
	1 while($$chunk=~s|/\*(.*?)\*/|$header->{$1}|g);
	
	$$chunk=~s|TABLE|TABLE IF NOT EXISTS|;
	
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
	
	$SQL=~/TABLE(.*?) `(.*?)`.`(.*?)`/;
	my $database=$2;
	my $table=$3;
	main::_log("database='$database ' table='$table' in db_h='$header->{'db_h'}'");
	
	TOM::Database::connect::multi($header->{'db_h'}) unless $main::DB{$header->{'db_h'}};
	
	if ($debug)
	{
		foreach my $line(split('\n',$SQL))
		{
			main::_log("$line");
		}
	}
	
	my $db=$main::DB{$header->{'db_h'}}->Query($SQL);
	main::_log("output='$db'");
	
	if ($env{'-compare'})
	{
		main::_log("calling '-compare'");
		
		my $SQL_real=TOM::Database::SQL::show_create_table($header->{'db_h'},$database,$table);
		
		my @out=TOM::Database::SQL::compare::compare_create_table($SQL,$SQL_real);
		foreach my $SQL_ALTER (@out)
		{
			$SQL_ALTER.=" -- db_h=".$header->{'db_h'};
			main::_log("ALTER='$SQL_ALTER'");
			push @{$output{'ALTER'}}, $SQL_ALTER;
			if ($env{'-compare_execute'})
			{
				my @eout=TOM::Database::SQL::execute($SQL_ALTER);
			}
		}
		
	}
	
	$t->close();
	return %output;
}

1;
