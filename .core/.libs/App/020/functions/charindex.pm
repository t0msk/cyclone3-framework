package App::020::functions::charindex;

=head1 NAME

App::020::functions::charindex

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use TOM::Utils::vars;



sub new
{
	my $class=shift;
	my $self={};
	my %env=@_;
	
	@{$self->{'table'}}=@TOM::Utils::vars::WCHAR;
	$self->{'depth'}=3;
	$self->{'char'}=$self->{'depth'};
	$self->{'idx'}=[]; # pole hodnot vysledneho charindexu
	$self->{'idx'}[$self->{'depth'}]=-1;
	$self->{'to'}=@{$self->{'table'}};
	$self->{'max'}=$self->{'to'}**$self->{'char'};
	$self->{'list'}=0;
	
	if ($env{'from'})
	{
		# rozsekam si charindex na pismenka
		my @ref=split('',$env{'from'});
		
		# kazdemu jednemu pismenku priradim cislo
		for my $i (0..@ref-1)
		{
			for my $ii(0..@{$self->{'table'}}-1)
			{
				if ($ref[$i] eq $self->{'table'}[$ii])
				{
					$self->{'idx'}[$i+1]=$ii;
					last;
				}
			}
		}
	}
	
	main::_log("idx=[@{$self->{idx}}]");
	
	return bless $self, $class;
}


sub increase
{
	my $self=shift;
	$self->{'list'}++;
	return undef if $self->{'list'} > $self->{'max'};
	
	$self->{'idx'}[$self->{'depth'}]++;
	
	while ($self->{'idx'}[$self->{'depth'}]>@{$self->{'table'}}-1)
	{
		$self->{'idx'}[$self->{'depth'}]=0;
		$self->{'depth'}--;
		$self->{'idx'}[$self->{'depth'}]++;
	}
	$self->{'depth'}=$self->{'char'};
	
	main::_log("idx=[@{$self->{idx}}]");
	
	my $cat;
	for (1..$self->{'char'})
	{
		$cat.=${$self->{'table'}}[$self->{'idx'}[$_]];
	}
	return $cat;
}


1;