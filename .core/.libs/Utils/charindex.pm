package Utils::charindex;
use strict;
use Utils::vars;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1
my $object=Utils::charindex->find(
				depth=>4,
				table=>["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"],
			);
while (my $key=$object->list())
{
 print "$key\n";
}
=cut
sub find
{
 my $class=shift;
 my $self={};
 my %env=@_;

 $env{depth}=2 unless $env{depth}; 
 @{$self->{table}}=@Utils::vars::WCHAR unless $self->{table}=$env{table};
 $self->{depth}=$env{depth};
 $self->{char}=$env{depth};  
 $self->{idx}=[];
 $self->{idx}[$self->{depth}]=-1;
 $self->{to}=@{$self->{table}};
 $self->{max}=$self->{to}**$self->{char};
 $self->{list}=0;
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
