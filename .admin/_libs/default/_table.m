###########################
# HTML PROCESSOR
###########################

package HP_TABLE;

sub new # initialize
{
 my $procc=shift;
# my %self=@_;
 my $self={};
 my %env=@_;

 
 %{$self->{define}}=%{$env{define}};
 

 $env{'cellspacing'}="0" unless $env{'cellspacing'};
 $env{'cellpadding'}="0" unless $env{'cellpadding'};
 $env{'border'}="0" unless $env{'border'};
 
 $self->{color_active}=$env{color_active};

 $self->{header}="<TABLE width=100% cellspacing=$env{'cellspacing'} cellpadding=$env{'cellpadding'} border=$env{'border'}>\n";

 $self->{header}.="<tr class=tr0>\n";
 foreach (sort keys %{$env{define}})
 {
  $self->{header}.="<td";
  $self->{header}.=" class=$env{define}{$_}{class}" if $env{define}{$_}{class};
   $self->{header}.=" ".$env{define}{$_}{plus} if $env{define}{$_}{plus};
  $self->{header}.=" onclick=\"load('$env{link_core}$env{define}{$_}{select}');\"" if $env{define}{$_}{select};
  $self->{header}.=">&nbsp;$env{define}{$_}{id}$env{define}{$_}{id_plus}&nbsp;</td>\n";  
 }
 $self->{header}.="<td width=100%></td>\n</tr>\n";
 
 

 
 $self->{footer}="</TABLE>";
 
 bless $self;
 return $self;
}





sub add
{
 my $self=shift;
 my %env=@_;
 $self->{body}.="<tr";
 $self->{body}.=" class=$env{class}" if $env{class};
 $self->{body}.=" style=\"background:$env{color}\"" if $env{color};
 $self->{body}.=" onmouseover=\"this.style.background='$self->{color_active}';\" onmouseout=\"this.style.background='$env{color}';\"" if $self->{color_active};
 $self->{body}.=">\n";
 
 foreach my $key(sort keys %{$self->{define}})
 {
  $self->{body}.="<td";
  $self->{body}.=" class=$self->{define}{$key}{td_class}" if $self->{define}{$key}{td_class};
  $self->{body}.=" $self->{define}{$key}{td_plus}" if $self->{define}{$key}{td_plus};
  $self->{body}.=">$self->{define}{$key}{code}</td>\n";
  my $id=$self->{define}{$key}{id};
  foreach (keys %{$env{define}{$id}})
  {$self->{body}=~s|<%$_%>|$env{define}{$id}{$_}|g;}
  $self->{body}=~s|<%.*?%>||g;
 }
 $self->{body}.="<td></td></tr>\n";
 
 foreach (keys %{$env{replace}})
 {$self->{body}=~s|<!--$_-->|$env{replace}{$_}|g;} 
 
}




sub i # insert at begin
{
 my $self=shift;
 return 0 unless my $code=shift;
 $self->{body} = $code . "\n" . $self->{body};
 return 1;
}


sub HTML # get html code
{
 my $self=shift;
 return $self->{header}.$self->{body}.$self->{footer};
}


sub DESTROY
{
 my $self=shift; 
 $self={};
}


1;













