package TOM::Utils::vars;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @WCHAR=qw/0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z/;
our @NUCHAR=qw/0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
our @NCHAR=qw/0 1 2 3 4 5 6 7 8 9/;
our @UCHAR=qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
our @LCHAR=qw/a b c d e f g h i j k l m n o p q r s t u v w x y z/;

sub genhash
{
	my $var;
	for (1..$_[0])
	{
		$var.=$WCHAR[int(rand(61))];
	}
	return $var;
}

sub genhashN
{
	my $var;
	for (1..$_[0])
	{
		$var.=$NCHAR[int(rand(9))];
	}
	return $var;
}

=head1
sub uniq_split
{
	my $email=shift;
	
	my %addr;foreach (split(";",$email)){$addr{$_}++;}$email='';
	foreach (keys %addr){next unless $_;$email.=$_.";"};$email=~s|;$||;
	
	return $email;
}
=cut

sub unique_split
{
	my $email=shift;
	
	my %addr;foreach (split(";",$email)){$addr{$_}++;}$email='';
	foreach (keys %addr){next unless $_;$email.=$_.";"};$email=~s|;$||;
	
	return $email;
}



use Int::charsets::encode;

our %replace_functions=
(
#	'XMLize-entity' =>
#	{
#		function => 'Int::charsets::encode::UTF8_ASCII($text)',
#	},
	'ASCII' =>
	{
		function => 'Int::charsets::encode::UTF8_ASCII($text)',
	},
);



#
# <@XMLize-entity>ahojte</@XMLize-entity>
#

sub replace
{
	my $t=track TOM::Debug(__PACKAGE__."::replace()");
	
	my $TMP=TOM::Utils::vars::genhash(8);
	my $i;
	for (@_)
	{
		$i++;
		main::_log("replacing text No. $i");
		
		
		while ($_=~s/<\$(.{2,100}?)>/<!TMP-$TMP!>/) # MAXIMALNE 100 znakova premmenna
		{
			my $value;
			my $var=$1;
			
			main::_log("replacing variable '$var'");
			
			if ($var=~/(sub\{|do\{|&|\+|\-|\*|\/|=|"|\||;)/)
			{
				main::_log("VAZNY PRIENIK ZAMENY PREMENNEJ \"".
				$var.
				"\" z $main::ENV{'REMOTE_ADDR'} s $main::ENV{'QUERY_STRING'} ",1,"secure");
				$var="***";
				# TUTO POSLAT OZNAMENIE O TOMTO ERRORE!!
			}
			
			eval "\$value=\$$var;";
			
			if ('<$'.$var.'>' eq $value)
			{
				main::_log("nekonecny cyklus, modifikujem value");
				$value=~s|^<||;
				$value=~s|>$||;
			}
			
			if ($@)
			{
				main::_log("error:$@");
			}
			
			$_=~s|<!TMP-$TMP!>|$value|;
		}
		
		
		while ($_=~s|<@([a-zA-Z0-9_\-:]+)>(.*?)</@\1>|<!TMP-$TMP!>|)
		{
			my $function=$1;
			my $text=$2;
			main::_log("requesting function '$1'");
			
			my $cmd="\$text=".$replace_functions{$function}{'function'};
			
			main::_log("calling '$cmd'");
			
			eval $cmd;
			
			main::_log("error '$@'") if $@;
			
			$_=~s|<!TMP-$TMP!>|$text|;
			
		}
	}
	
	$t->close();
}


sub CurrencyInt50h
{
	my $price=shift;
	$price=~s|\.||g;
	$price=~s|,|.|g;
	
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


sub s_sort
{
	my $s1=shift;
	my $s2=shift;
	
	my $s_1=$s1;
	my $s_2=$s2;
	
	$s_1=~s|,|.|g;
	$s_2=~s|,|.|g;
	
	1 while ($s_1=~s|\s||g);
	1 while ($s_2=~s|\s||g);
	
	$s_1=~s|^([\.0-9]+).*$|$1|g;
	$s_2=~s|^([\.0-9]+).*$|$1|g;
	
	if (not $s_1=~/[0-9]/)
	{
		return $s1 cmp $s2;
	}
	
	return $s_1 <=> $s_2;
	
	return 1;
}


1;
