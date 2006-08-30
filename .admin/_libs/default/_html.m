###########################
# HTML PROCESSOR
###########################

package HP;

sub ALARM {return}; $SIG{ALRM} = \&ALARM;

sub new # initialize
{
 my $procc=shift;
 my $self={};
 my %env=@_;
 my %env0,%env1;
 
 # start Content-*
# $env{'Content-Type'}="text/html" unless $env{'Content-Type'};
# $self->{header} = "Content-Type: ".$env{'Content-Type'}."\n";

# $self->{header} .= "Content-Encoding: ".$env{'Content-Encoding'}."\n"
# 	if $env{'Content-Encoding'};

# $self->{header}.="\n";
 # koniec Content-*
 
 $env{'DOCTYPE'} = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.00 Transitional//EN\">" unless $env{'DOCTYPE'};
 $self->{header} .= $env{'DOCTYPE'}."\n";
 
 $self->{header} .= "<HTML>\n";
 
 #------------------------------#
 # HEADER 						#
 #------------------------------#
 $self->{header} .= "<HEAD>\n"; 
 
 # TITLE
 $self->{header} .= " <TITLE>".$env{'HEAD'}{'TITLE'}."</TITLE>\n";

 # STYLE
 if ($env{'HEAD'}{'STYLE'})
 {
  $self->{header} .= " <style>\n <!--\n";
  foreach (keys %{$env{'HEAD'}{'STYLE'}})
  {
   $self->{header} .= "  " . $_ . " {" . $env{'HEAD'}{'STYLE'}{$_} . "}\n";
  }
  $self->{header} .= " -->\n </style>\n";
 }

 #STYLE LINKS
 foreach (keys %{$env{'HEAD'}{'STYLESHEETS'}})
 {$self->{header} .= " <LINK rel='stylesheet' media='screen' href='" . $env{'HEAD'}{'STYLESHEETS'}{$_} . "' type='text/css'>\n";}

 # META
 foreach (keys %{$env{'HEAD'}{'META'}})
 {$self->{header} .= " <META HTTP-EQUIV='" . $_ . "' CONTENT='" . $env{'HEAD'}{'META'}{$_} . "'>\n";}

 
 $self->{header} .= "</HEAD>\n"; 



 # BODY

 $self->{header} .= "<BODY";
 #$env{'BODY'}{'bgcolor'}="#FFFFFF" unless $env{'BODY'}{'bgcolor'};
 #$env{'BODY'}{'text'}="#000000" unless $env{'BODY'}{'text'};
 #$env{'BODY'}{'link'}="#002F5A" unless $env{'BODY'}{'link'};
 #$env{'BODY'}{'vlink'}="#002F5A" unless $env{'BODY'}{'vlink'};
 #$env{'BODY'}{'alink'}="#002F5A" unless $env{'BODY'}{'alink'};
 foreach (keys %{$env{'BODY'}})
 {$self->{header} .= "\n " . $_ . "=" . "\"" . $env{'BODY'}{$_} . "\"";}
 $self->{header} .= ">\n";

 # FOOTER
 
 $self->{footer} = "</BODY>\n</HTML>\n";
 bless $self;
 return $self;
}


sub tmp # initialize
{
 my $procc=shift;
 my $self={};
 $self->{body}="";
 bless $self;
 return $self;
}



sub i # insert at begin
{
 my $self=shift;
 return 0 unless my $code=shift;
 $self->{body} = $code . "\n" . $self->{body};
 return 1;
}

sub r # replace
{
 my $self=shift;
 return 0 unless my $what=shift;
 return 0 unless my $code=shift;
 return 0 unless $self->{body}=~s|$what|$code|g;
 return 1;
}

sub r_ # replace next
{
 my $self=shift;
 return 0 unless my $what=shift;
 return 0 unless my $code=shift;
 return 0 unless $self->{body}=~s|$what|$code$what|g;
 return 1;
}

sub a # append
{
 my $self=shift;
 return 0 unless my $code=shift;
 $self->{body} .= "\n" . $code;
 return 1;
}

sub t # tag
{
 my $self=shift; # prvy je self
 my $text=pop; # posledny je text - dost brutal :)
 my %env=@_; # natiahnem vnoreny hash TAGu



 my $noclose; # zavriem?
 my @tagy=keys %env;
 %env=%{$env{$tagy[0]}}; # skratenie hashu %env :)
 my $tag="\U$tagy[0]";
 undef @tagy;

 # OSETRENIE TEXTU
# $text .= "\n" unless $text=~/\n$/; # dam \n
  # rozsekam
# my @ref=split('\n',$text);$text="";
# foreach (@ref)
# {$text .= " ".$_."\n";}
# undef @ref;

 my $output = "<".$tag; # text for output


 if ($tag eq "A")
 {
  $env{'href'}="#" unless ($env{'href'})||($env{'name'});
 }
 elsif ($tag eq "FORM")
 {
  $env{'method'}="POST" unless $env{'method'};
 }
 elsif ($tag eq "INPUT")
 {
  $env{'type'}="text" unless $env{'type'};
 }
 elsif ($tag eq "IMG")
 {
  $env{'border'}="0" unless $env{'border'};
  return undef unless $env{'src'};
  $noclose=1;
 }
 elsif ($tag eq "TABLE")
 {
  $env{'cellspacing'}="0" unless $env{'cellspacing'};
  $env{'cellpadding'}="0" unless $env{'cellpadding'};
  $env{'border'}="0" unless $env{'border'};  
  $env{'width'}="100%" unless $env{'width'};
 }
  
 foreach (keys %env) {$output .= " ".$_."=\"".$env{$_}."\"";}
 
# if (!$noclose){$output .= ">\n".$text."</".$tag.">\n";}
# else {$output .= ">\n";}

 if (!$noclose){$output .= ">\n".$text."\n</".$tag.">\n";}
 else {$output .= ">".$text;}
 
 return $output; 
}

sub HTML # get html code
{
 my $self=shift;
 return $self->{header}.$self->{body}.$self->{footer};
}

sub BODY # get body code
{
 my $self=shift;
 return $self->{body};
}

sub HTML_ # get clean html code
{
 my $self=shift;
 my @text=split('\n',$self->{body});
 my $out;
 foreach (@text)
 {
  if ($_){$out .= $_."\n"}
 }
 $out=~s|<%.*?%>||g;
 $out=~s|<!--.*?-->||g;
 return $self->{header}."\n\n".$out."\n\n".$self->{footer};
}

sub DESTROY
{
 my $self=shift; 
 $self={};
}


1;













