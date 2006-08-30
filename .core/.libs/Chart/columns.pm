#!/bin/perl
package Chart::columns;
use strict;


sub new
{
	my ($class,%env)=@_;
	my $self={};
	%{$self->{ENV}}=%env;
	return bless $self,$class;
}


sub addData
{
	my ($self,$null,$var)=@_;
	
	main::_log("addData to column '$self->{ENV}{title}' row '$null' value '$var'");
	
	$self->{data}{$null}+=$var;
	#push @{$self->{data}},@_;
	
	return 1;
}


#sub addDataBegin
#{
# my $self=shift;
# unshift @{$self->{data}},@_;
# return 1;
#}

=head1
sub GetMaxValue
{
 my $self=shift;
 my $val;
 foreach (values %{$self->{data}})
 {
  $val=$_ if $_>$val;
 }
 return $val;
}
=cut

sub GetAVG
{
 my $self=shift;
 my $val;
 my $null;
 foreach (values %{$self->{data}})
 {
  $val+=$_;$null++
 }
 return 0 unless $null;
 return ($val/$null);
}

=head1
sub GetMinValue
{
 my $self=shift;
 my $val;
 foreach (values %{$self->{data}})
 {
  $val=$_ if ($_<$val) || (!$val);
 }
 return $val;
}
=cut

=head1
sub GetIndex
{
 my $self=shift;
 my $null;
 foreach (keys %{$self->{data}}){$null++}
 return $null;
}
=cut

=head1
sub GetValues
{
 my $self=shift;
 #return %{$self->{data}};
 return $self->{data};
}
=cut

1;
