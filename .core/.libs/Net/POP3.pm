package Net::POP3;

use IO::Socket;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub ALARM {return}; $SIG{ALRM} = \&ALARM;

sub new # initialize
{
 my $procc=shift;
 my %env=@_;
 my $self={};
 $self->{host}="localhost" unless $self->{host}=$env{host};
 $self->{port}="110" unless $self->{port}=$env{port};
 $self->{proto}="tcp" unless $self->{proto}=$env{proto};
 $self->{user}=$env{user};
 $self->{pass}=$env{pass};
 $self->{timeout}=10 unless $self->{timeout}=$env{timeout};
 $self->{logout}=$env{logout};
 bless $self;
 return $self;
}

sub Connect # initialize & connect
{
 my $procc=shift;
 my %env=@_;
 my $self={};
 $self->{host}="localhost" unless $self->{host}=$env{host};
 $self->{port}="110" unless $self->{port}=$env{port};
 $self->{proto}="tcp" unless $self->{proto}=$env{proto};
 $self->{user}=$env{user};
 $self->{pass}=$env{pass};
 $self->{timeout}=10 unless $self->{timeout}=$env{timeout};
 $self->{logout}=$env{logout};
 bless $self;
 return 0 unless $self->dataconn();
 return $self;
}

sub ch_read
{
 my $self=shift;
 my ($rin, $rout) = ('', '');
 vec ($rin, fileno ($self->{SOCK}), 1) = 1;
 my ($nfound, undef) = select ($rout = $rin, undef, undef, 0);

 # print "CH:$nfound:\n";

 return $nfound;
}

sub ch_write
{
 my $self=shift;
 my ($rin, $rout) = ('', '');
 vec ($rin, fileno ($self->{SOCK}), 1) = 1;
 my ($nfound, undef) = select ($rout = $rin, undef, undef, 0);
 if ($nfound){undef $nfound;}else{$nfound=1;};
 return $nfound;
}


sub R_line
{
 local $self=shift;
 local $sock=$self->{SOCK};
 local $buf,bufw;

# casto "drbe na to" :(
# print "R1:\n";
# return 0 unless $self->ch_read(); # da sa este prijimat? ak nie, vrat 0!
# print "R2:\n";

 # PRIJIMAM V CASOVOM LIMITE...
 eval
 {
  local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
  local $SIG{PIPE} = sub { die "pipe\n" }; # NB: \n required
  alarm $self->{timeout};
  $buf=<$sock>;
  $bufw=$buf;$bufw=~s|[\n\r]||g;
  #if ($self->{logout}){print "<=[$bufw]\n";}
  alarm 0;
 };
 # ak som stiahol vrat stiahnuty riadok, ak nie, vrat 0!
 if ($@){return 0;}else{return $buf;}
}


sub W_line
{
 local $self=shift;
 local $sock=$self->{SOCK};
 local $line=shift @_;

# zas na to drbe :(
# return 0 unless $self->ch_write(); # da sa este zapisovat? ak nie, vrat 0!

 # ZAPISUJEM V CASOVOM LIMITE...
 eval
 {
  local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
  local $SIG{PIPE} = sub { die "pipe\n" }; # NB: \n required
  alarm $self->{timeout};
  print $sock "$line\n";
  #if ($self->{logout}){print "=>[$line]\n"}
  alarm 0;
 };
 # ak som zapisal vrat 1, ak nie, vrat 0!
 return 1 unless $@;
 return 0;
}


sub R_lines
{
 my $self=shift;
 my @lines,$buf;
 while ($buf=$self->R_line()){if ($buf){push @lines, $buf;}}
 return @lines;
}


sub dataconn
{
 my $self=shift;

# STARE
 $self->{SOCK} = IO::Socket::INET->new(PeerAddr=>$self->{host}, PeerPort=>$self->{port}, Proto=>$self->{proto});
# NOVE!
# my $sock; #=$self->{SOCK};

# $self->{SOCK}="SOCK";
# return 0 unless connect(SOCK,sockaddr_in($self->{port},inet_aton($self->{host})));
# return 0 unless socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname($self->{proto}));
# print "aok\n";
# $self->{SOCK}=SOCK;

#    my $proto = getprotobyname($self->{proto});
#    socket($self->{SOCK}, PF_INET, SOCK_STREAM, getprotobyname($self->{proto}));
#									    my $port = getservbyname('smtp', 'tcp');
#    my $sin = sockaddr_in($self->{port},inet_aton($self->{host}));
#									    $sin = sockaddr_in(7,inet_aton("localhost"));
#									    $sin = sockaddr_in(7,INADDR_LOOPBACK);
#    connect($self->{SOCK},sockaddr_in($self->{port},inet_aton($self->{host})));


 if (!$self->{SOCK}) # drbka na mna a neconnectne
 {
#  print STDERR "ERR: cannot connect $self->{host}:$self->{port} proto:$self->{proto}\n";
  return 0;
 }
 return 0 unless my $buf=$self->R_line(); # cakam kym sa mi predstavi server?
 return $buf;
}

sub check_ok
{
 my $self=shift;
 my $line=shift;
 $line=~s|[\n\r]||g;
 if ($line=~/^\+OK/g){return 1}
 return 0;
}

sub login
{
 my $self=shift;
 my %env=@_;

 if ($env{account}){$self->{account}=$env{account}}
 if (!$self->{account}){
# print STDERR "ERR: none account for login;\n";
 return 0}
 if ($env{password}){$self->{password}=$env{password}}
 if (!$self->{password}){
#print STDERR "ERR: none password for login;\n";
 return 0}

 $self->W_line("USER ".$self->{account});
 if (!$self->check_ok($self->R_line())){
#print STDERR "ERR: bad account;\n";
 return 0}
 $self->W_line("PASS ".$self->{password});
 if (!$self->check_ok($self->R_line())){
#print STDERR "ERR: bad account or password;\n";
 return 0}

 return 1;
}



sub get_list
{
 my $self=shift;
 my $buf="a";
 my @list,@ref,$msgs,$totalsize;
 return 0 unless $self->W_line("LIST");
 if (!$self->check_ok($self->R_line())){
#print STDERR "ERR: bad list???;\n";
 return 0}
 while ($buf ne ".")
 {
  $buf=$self->R_line();
  $buf=~s|[\n\r]||g;
  if ($buf ne ".")
  {
   $msgs++;
   @ref=split(' ',$buf);
   push @list, $ref[1];
   $totalsize += $ref[1];
  }
 }
 return $msgs,$totalsize,@list;
}



sub get_mail
{
 my $self=shift;
 my $msg=shift;
 my $buf;
 my $body;
 return 0 unless $self->W_line("RETR ".$msg);
 if (!$self->check_ok($self->R_line())){
#print STDERR "ERR: bad RETR???;\n";
 return 0}

 $buf=">";
 while ($buf=~/^>/){$buf=$self->R_line();}
 $buf=~s|[\n\r]||g;$body .= $buf."\n";
 while ($buf ne ".")
 {
  $buf=$self->R_line();
  $buf=~s|[\n\r]||g;
  if ($buf ne "."){$body .= $buf."\n";}
 }
 return $body;
}



sub del_mail
{
 my $self=shift;
 my $msg=shift;
 return 0 unless $self->W_line("DELE ".$msg);
 if (!$self->check_ok($self->R_line())){
#print STDERR "ERR: bad DELE???;\n";
 return 0}
 return 1;
}


sub disconnect
{
 my $self=shift;
 return 0 unless $self->W_line("QUIT");
 if (!$self->check_ok($self->R_line())){
#print STDERR "ERR: bad quit?;\n";
 return 0}
 return 1;
}






1;
