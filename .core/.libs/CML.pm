
package CML;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $level;

=head1
sub VARhash
{my $data=shift @_;return undef unless $data;my %env;
 $data=~s|=""|=" "|g;
#while ($data=~s|[\t ](.{1,50}?)="(.{0,255}?[^\\])"||s){$env{$1}=$2;$env{$1}=~s|\\||g;}
while ($data=~s|([\t ].{1,50}?)="(.{0,255}?[^\\])"||s)
{
 my $var=$1;
 my $null=$2;
 $var=~s|[^a-zA-Z0-9_]||g;
 $env{$var}=$null;$env{$var}=~s|\\||g;
}
#while ($data=~s|[\t ](.{1,50}?)="(.[^\\]?)"||s){$env{$1}=$2;$env{$1}=~s|\\||g;}
return %env}
=cut

sub VARhash
{my $data=shift @_;return undef unless $data;my %env;
 $data=~s|=""|=" "|g;
 $data=" ".$data;
 #while ($data=~s|[^a-zA-Z0-9]+(.*?)="(.*?[^\\])"||s){$env{$1}=$2;$env{$1}=~s|\\||g;}
 while ($data=~s|[^a-zA-Z0-9]+(.*?)="(.*?[^\\])"||s){$env{$1}=$2;$env{$1}=~s|\\||g;$env{$1}="" if $env{$1} eq " "};
return %env}

=head1
sub VARhash2
{my $data=shift @_;return undef unless $data;my %env;
 $data=~s|=""|=" "|g;
 while ($data=~s|[^a-zA-Z0-9]+(.*?)="(.*?[^\\])"||s)
 {
  $env{$1}=$2;$env{$1}=~s|\\||g;
 }
return %env}
=cut

#sub VARhash_long
#{my $data=shift @_;return undef unless $data;my %env;
#while ($data=~s|[\t ](.*?)="(.[^\\]?)"||s){$env{$1}=$2;$env{$1}=~s|\\||g;}
#return %env}



sub _gVAR
{
 my $data=shift @_;return undef unless $data;my %env;
 while ($data=~s|\n(.*?)<VAR id="(.*?)">(.*?)\n\1</VAR>||s)
 {$env{$2}=$3;}
 return %env;
}



sub new
{
 my $procc=shift;
 my $self={};
 my %env=@_;

 print "\n\n enter with $env{parse}\n\n";

 #$self->{bubu}="aaa";
# print "$env{parse}\n";
 $self->{value}=$env{parse};
 while ($env{parse}=~s|\n(.*?)<VAR id="(\w*?)">(.*?)\n\1</VAR>||s)
 {
  print "parse !$2! !$3!\n";
  $self->{$2}=Tomahawk::CML->new(parse=>$3);
  #$env{$2}=$3;
 }

 if ($env{parse}=~s|<VAR(.*?)/>||)
 {
  print "varparse !$1!\n";
 }
 else
 {
  print "value=$env{parse}\n";
  $self->{value}=$env{parse};
 }

 bless $self;
 return $self;
}




sub list
{
 my $self=shift;

}





sub ghash
{
 my $data=shift @_;return undef unless $data;my %env;
 $level++;

 print "[$level] entering\n";

 while ($data=~s|\n(.*?)<VAR id="(\w*?)">(.*?)\n\1</VAR>||s)
 {
  my $var=$2;
  my $value=$3;
  print "[$level] parse ->!$var!\n";
  my $newval=&ghash($value);
  #$env{$var}=&ghash($value);
  $level--;
  print "[$level] <-$newval\n";

  #$self->{$2}=Tomahawk::CML->new(parse=>$3);
  #my %env0=ghash($3);
  #foreach(keys %env0)
  #{
   #print "plus $2 $_ $env0{$_}\n";
   #$env{$2}{$_}=$env0{$_};
  #}
 }
 if ($data=~s|sl;adfjkal;sdkfj||)
 {
 }
 else
 {
  print "[$level] mam $data\n";
  $env{value}=$data;
  #return $data;
  #return $data;
 }
 #$env{value}=$data;
# %env=_gVAR($data); # vytrham velke VARY;

# foreach (keys %env)
# {
# }

 foreach (keys %env)
 {
  print "[$level] + $_\n";
 }

 return %env;
}
















1;
