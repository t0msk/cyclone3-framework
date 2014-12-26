package TOM::Utils::charindex;
use Tomahawk;
use Utils::vars;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
#use Utils::vars;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

# test (table=>"a400_category", IDcharindex=>"000:005:007")
sub get
{
	my %env=@_;
	my %out;
	
	my $sql_where;
	if ($env{lng})
	{
		$sql_where.="AND (lng IS NULL OR lng='$env{lng}') ";
	}
	
	#return 1;
	
	die "parameter 'table' missed in function" unless $env{table};
	#die "parameter 'table' missed in function" if not exists $env{ID};
	
	#return 1;
	
	# extrahnem si z nazvu tabulky, cislo aplikacie
	$env{table}=~/^a([^_]+)/;
	$env{app}=$1;die "can't extract app name in function" unless $env{app};
	
	#$out{text}="app $env{app}";return %out;
	
	# zistim si v ktorej databaze sa nachadza tato aplikacia (a tym padom aj tabulka s ktorou xem pracovat)
	#eval
	#{
	$env{db}=Tomahawk::Getmdlvar($env{app},"db");
	#};
	#$out{text}=$@.$!;return %out;
	$env{db}=$TOM::DB_name unless $env{db};
	
	#return 1;
	
	# zistim aku mam hlbku IDcharindex
	$env{depth}=Tomahawk::Getmdlvar($env{app},$env{table}."-IDcharindex_chars",db=>$env{db});
	$env{depth}=2 unless $env{depth};
	
	#return 1;
	
	main::_log(9,"IDcharindex in app $env{app}, table $env{table}, database $env{db} has depth $env{depth}");
	
	# zistim aku mam hlbku IDcharindex vo vstupe
	$env{IDcharindex}=~s|^:||;$env{IDcharindex}=~s|:$||;
	my $depth;
	foreach (split(':',$env{IDcharindex}))
	{
		$depth=length($_) unless $depth;
		die "IDcharindex has floating number of depth in function" if length($_) != $depth;
	}
	
	die "IDcharindex has depth $depth, in _config $env{depth} in function" if ($depth != $env{depth}) && $depth;
	
	# rozsekam si existujuci IDcharindex
	my @node=split(':',$env{IDcharindex});
	$env{IDcharindex}=join ':',@node;
	
	
	
	
	# idem hladat prvy child
	if ($env{-first_free_child} || $env{-first_child})
	{
		my $plusq;
		if (!$env{-next_free_child} && $env{-first_child})
		{
			$plusq="LIMIT 1";
		}
		
		my $object=TOM::Utils::charindex::find->new(depth=>$env{depth});
		my $plus;$plus=":" if $env{IDcharindex};
		my $sql="
			SELECT IDcharindex
			FROM $env{db}.$env{table}
			WHERE
				IDcharindex LIKE '$env{IDcharindex}$plus".('_' x $env{depth})."'
				$sql_where
			ORDER BY IDcharindex
			$plusq
		";
		#print "$sql\n";
		my $ttr;
		my $key;
		my $db0=$main::DB{main}->Query($sql);
		while (my %db0_line=$db0->fetchhash())
		{
			$out{first_child}=$db0_line{IDcharindex} unless $out{first_child};
			$db0_line{IDcharindex}=~s|^$env{IDcharindex}:||;
			$key=$object->list();
			#print "$db0_line{IDcharindex} $key\n";
			if ($db0_line{IDcharindex} ne $key)
			{
				$ttr=1;
				last;
			}
		}
		
		if (!$ttr && $key){$key=$object->list();} # ak som hladal v databaze ale nenasiel medzeru
		$key=("0" x $env{depth}) unless $key; # ak som nehladal v databaze lebo je prazdna
		
#		if (!$ttr){$key=$object->list();}
		
		if ($env{-next_free_child})
		{
			$out{first_free_child}=$env{IDcharindex}.":".$key;$out{first_free_child}=~s|^:||;
		}
		
	}
	
	
	
	
	if ($env{-next_free_child} || $env{-last_child})
	{
		my $plus;$plus=":" if $env{IDcharindex};
		my $sql="
			SELECT IDcharindex
			FROM $env{db}.$env{table}
			WHERE
				IDcharindex LIKE '$env{IDcharindex}$plus".('_' x $env{depth})."'
				$sql_where
			ORDER BY IDcharindex DESC
			LIMIT 1
		";
		#print "$sql\n";
		my $key;
		my $db0=$main::DB{main}->Query($sql);
		if (my %db0_line=$db0->fetchhash())
		{
			$out{last_child}=$db0_line{IDcharindex};
			$db0_line{IDcharindex}=~s|^$env{IDcharindex}:||;
			
			#print "posledny je $db0_line{IDcharindex}\n";
			
			my $object=TOM::Utils::charindex::find->new(depth=>$env{depth},from=>$db0_line{IDcharindex});
			$key=$object->list();
			#print "posledny je $key\n";
			#my $key=$object->list();
			#print "posledny je $key\n";
			
		}
		$key=("0" x $env{depth}) unless $key;
		
		$out{next_free_child}=$env{IDcharindex}.":".$key;$out{next_free_child}=~s|^:||;
		
	}
	
	
	if ($env{-next_free})
	{
		my $charindex=$env{IDcharindex};
			$charindex=~s|^(.*):.*?$|$1| or $charindex="";
		my $from=$env{IDcharindex};
			$from=~s|^$charindex||;
			$from=~s|^:||;
		my $plus;$plus=":" if $charindex;
		
		#print "ID: $env{IDcharindex} char: $charindex from: $from\n";
		
		my $sql="
			SELECT IDcharindex
			FROM $env{db}.$env{table}
			WHERE
				IDcharindex LIKE '$charindex$plus".('_' x $env{depth})."'
				AND IDcharindex>'$env{IDcharindex}'
				AND length(IDcharindex)=".length($env{IDcharindex})."
				$sql_where
			ORDER BY IDcharindex
		";
		#print "$sql\n";
		
		
		my $object=TOM::Utils::charindex::find->new(depth=>$env{depth},from=>$from);
		
		my $ttr;
		my $key;
		my $db0=$main::DB{main}->Query($sql);
		while (my %db0_line=$db0->fetchhash())
		{
			$db0_line{IDcharindex}=~s|^$charindex:||;
			$key=$object->list();
			
			#print "++$db0_line{IDcharindex} $key\n";
			
			if ($db0_line{IDcharindex} ne $key)
			{
				$ttr=1;
				last;
			}
			
		}
		
		if (!$ttr && $key){$key=$object->list();} # ak som hladal v databaze ale nenasiel medzeru
		$key=("0" x $env{depth}) unless $key; # ak som nehladal v databaze lebo je prazdna
		
		if ($charindex)
		{
			$out{next_free}=$charindex.":";
		}
		
		$out{next_free}.=$key;$out{next_free}=~s|^:||;
		
	}
	
	
	return %out;
}














package TOM::Utils::charindex::find;

=head1
my $object=TOM::Utils::charindex::find->new(
				depth=>4,
				table=>["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"],
			);
while (my $key=$object->list())
{
 print "$key\n";
}
=cut

sub new
{
	my $class=shift;
	my $self={};
	my %env=@_;
	
	$env{depth}=2 unless $env{depth}; 
	@{$self->{table}}=@Utils::vars::WCHAR;# unless $self->{table}=$env{table};
	$self->{depth}=$env{depth};
	$self->{char}=$env{depth};  
	$self->{idx}=[];
	$self->{idx}[$self->{depth}]=-1;
	$self->{to}=@{$self->{table}};
	$self->{max}=$self->{to}**$self->{char};
	$self->{list}=0;
	
	if ($env{from})
	{
		# rozsekam si charindex na pismenka
		my @ref=split('',$env{from});
		#print "@ref\n";
		#print " ".$self->{idx}[2]."\n";
		
		# kazdemu jednemu pismenku najdem spravne cislo
		for my $i (0..@ref-1)
		{
			for my $ii(0..@{$self->{table}}-1)
			{
				if ($ref[$i] eq $self->{table}[$ii])
				{
					$self->{idx}[$i+1]=$ii;
					last;
				}
			}
		}
	}
	
	return bless $self, $class;
}

sub list
{
	my $self=shift;
	$self->{list}++;
	return undef if $self->{list} > $self->{max};
	$self->{idx}[$self->{depth}]++;
	while ($self->{idx}[$self->{depth}]>@{$self->{table}}-1)
	{
		$self->{idx}[$self->{depth}]=0;
		$self->{depth}--;
		$self->{idx}[$self->{depth}]++;
	}
	$self->{depth}=$self->{char};
	my $cat;
	for (1..$self->{char}){$cat.=${$self->{table}}[$self->{idx}[$_]];}
	return $cat
}



















1;