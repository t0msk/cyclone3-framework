package TOM::Utils::currency;
use strict;
use POSIX qw(ceil floor);

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub Int50h
{
	my $price=shift;
	
	if ($price=~/,/)
	{
		$price=~s|\.||g;
		$price=~s|,|.|g;
	}
	
	my $ost=$price-int($price);
	$price=int($price);
	
	$ost=do
	{
		($ost>0.5) ? 1:
		($ost==0) ? 0:
		0.5
	};
	
	$price+=$ost;
	
	return $price;
}

sub Int
{
	my $price=shift;
	
	if ($price=~/,/)
	{
		$price=~s|\.||g;
		$price=~s|,|.|g;
	}
	
	my $ost=$price-int($price);
	$price=int($price);
	
	$ost=do
	{
		($ost<=-0.5) ? -1:
		($ost>=0.5) ? 1:
		($ost<0.5) ? 0:
		0
	};
	
	$price+=$ost;
	
	return $price;
}

=head1
sub format
{
	my $currency=shift;;
	$currency=sprintf("%01.2f", $currency);
	
	
	$currency=~s|\.|,|g;
	$currency=~s|,00|,--|g;
	$currency="--" if $currency eq "0,--";
	return $currency;
}
=cut

our $currency_format_extsymbol=do{
	if (defined $TOM::Utils::currency::currency_format_extsymbol)
	{
		$TOM::Utils::currency::currency_format_extsymbol;
	}
	else
	{
		",–";
	}
};

sub format
{
	my $currency=shift;
	my $delimiter=".";
	
	$currency=sprintf("%01.2f", $currency);
	$currency=~s|\.|,|g;
	
	# delimite
	my @cur=split(',',$currency);
	my @a = ();
	while($cur[0] =~ /\d\d\d\d/)
	{
		$cur[0] =~ s/(\d\d\d)$//;
		unshift @a,$1;
	}
	unshift @a,$cur[0];
	$currency = (join $delimiter,@a) . "," . $cur[1];
	
	$currency=~s|,00|$currency_format_extsymbol|g;
#	$currency="--" if $currency eq "0,--";
	return $currency;
}


sub format_EUR
{
	my $currency=shift;
	my $delimiter=".";
	
	$currency=sprintf("%01.3f", $currency);
	$currency=~s|\.|,|g;
	
	# delimite
	my @cur=split(',',$currency);
	my @a = ();
	while($cur[0] =~ /\d\d\d\d/)
	{
		$cur[0] =~ s/(\d\d\d)$//;
		unshift @a,$1;
	}
	unshift @a,$cur[0];
	$currency = (join $delimiter,@a) . "," . $cur[1];
	
	$currency=~s|,000|,---|g;
	$currency="---" if $currency eq "0,---";
	return $currency;
}


1;
