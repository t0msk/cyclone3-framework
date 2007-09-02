package TOM::Utils::vars;

=head1 NAME

TOM::Utils::vars

=head1 DESCRIPTION

Functions above variables

=cut

use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @WCHAR=qw/0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z/;
our @NUCHAR=qw/0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
our @NCHAR=qw/0 1 2 3 4 5 6 7 8 9/;
our @UCHAR=qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
our @LCHAR=qw/a b c d e f g h i j k l m n o p q r s t u v w x y z/;

our $debug=0;

=head1 DEPENDS

=over

=item *

L<Int::charsets::encode|source-doc/".core/.libs/Int/charsets/encode.pm">

=back

=cut



use Int::charsets::encode;

=head1 FUNCTIONS

=head2 genhash()

Return random hash from characters 0-9a-Z

 my $hash=TOM::Utils::vars::genhash(25);

=cut

sub genhash
{
	my $var;
	for (1..$_[0])
	{
		$var.=$WCHAR[int(rand(61))];
	}
	return $var;
}



=head2 genhashN()

Return random hash from characters 0-9

 my $hash=TOM::Utils::vars::genhashN(25);

=cut

sub genhashN
{
	my $var;
	for (1..$_[0])
	{
		$var.=$NCHAR[int(rand(9))];
	}
	return $var;
}



=head2 unique_split()

Split given string by ";" character and removes duplicit parts of this string.

Return checked string

 my $string=TOM::Utils::vars::unique_split($string);

=cut

sub unique_split
{
	my $email=shift;
	
	my %addr;foreach (split(";",$email)){$addr{$_}++;}$email='';
	foreach (keys %addr){next unless $_;$email.=$_.";"};$email=~s|;$||;
	
	return $email;
}


our %replace_functions=
(
	'ASCII' =>
	{
		function => 'Int::charsets::encode::UTF8_ASCII($text)',
	},
);



=head2 replace()

Replaces variables in given string. Variables are represented by this syntax: <$variable>

 TOM::Utils::vars::replace($string)

Can execute functions which is represented in this library by syntax:

 <@function></@function>

List of available functions is in %replace_functions hash;

Checks string for security vulnerable - sub, do, &, |, etc...

 %TOM::Utils::vars::replace_functions=
 (
  'ASCII' => # name of function
  {
   function => 'Int::charsets::encode::UTF8_ASCII($text)',
  },
 );

=cut

sub replace
{
	my $t=track TOM::Debug(__PACKAGE__."::replace()") if $debug;
	
	my $TMP=TOM::Utils::vars::genhash(8);
	my $i;
	for (@_)
	{
		$i++;
		main::_log("replacing text No. $i") if $debug;
		
		
		while ($_=~s/<\$(.{1,100}?)>/<!TMP-$TMP!>/) # MAXIMALNE 100 znakova premmenna
		{
			my $value;
			my $var=$1;
			my $null="***";
			
			main::_log("replacing variable '\$$var'") if $debug;
			
			if ($var=~/(sub\{|do\{|&|\+|\*|\/|=|"|\||;)/)
			{
				main::_log("Unsecure variable replacement \"".
				$var.
				"\" z $main::ENV{'REMOTE_ADDR'} s $main::ENV{'QUERY_STRING'} ",1,"secure");
				$var="null";
				# TUTO POSLAT OZNAMENIE O TOMTO ERRORE!!
			}
			
			eval "\$value=\$$var;";
			
			if ('<$'.$var.'>' eq $value)
			{
				main::_log("neverending",1);
				$value=~s|^<||;
				$value=~s|>$||;
			}
			
			if ($@)
			{
				main::_log("error:$@",1);
			}
			
			$_=~s|<!TMP-$TMP!>|$value|;
		}
		
		
		while ($_=~s|<@([a-zA-Z0-9_\-:]+)>(.*?)</@\1>|<!TMP-$TMP!>|)
		{
			my $function=$1;
			my $text=$2;
			main::_log("requesting function '$1'") if $debug;
			
			my $cmd="\$text=".$replace_functions{$function}{'function'};
			
			main::_log("calling '$cmd'");
			
			eval $cmd;
			
			main::_log("error '$@'",1) if $@;
			
			$_=~s|<!TMP-$TMP!>|$text|;
			
		}
	}
	
	$t->close() if $debug;
}



=head2 replace_sec()

Same as replace(), but more secure, and: without function, return string

 $string=TOM::Utils::vars::replace_sec(
  $string,
  'notallow' => ['not allow to replace by this string','and by this string']
 )

=cut

sub replace_sec
{
	my $t=track TOM::Debug(__PACKAGE__."::replace_sec()") if $debug;
	
	my $TMP=TOM::Utils::vars::genhash(8);
	
	my $data=shift;
	
	my %env=@_;
	
	while ($data=~s/<\$(.{2,100}?)>/<!TMP-$TMP!>/)
	{
		my $value;
		my $var=$1;
		my $null="***";
		
		main::_log("replacing variable '\$$var'") if $debug;
		
		if ($env{'log'})
		{
			main::_log("[$tom::H] replacing variable '\$$var'",4,'secure',1);
		}
		
		if ($var=~/(sub\{|do\{|&|\+|\*|\/|=|"|\||;)/)
		{
			main::_log("Unsecure variable replacement \"".
			$var.
			"\" z $main::ENV{'REMOTE_ADDR'} s $main::ENV{'QUERY_STRING'} ",1,"secure");
			$var="null";
		}
		
		eval "\$value=\$$var;";
		
		if ('<$'.$var.'>' eq $value)
		{
			main::_log("neverending");
			$value=~s|^<||;
			$value=~s|>$||;
		}
		
		if ($@)
		{
			main::_log("error:$@");
		}
		
		foreach (@{$env{'notallow'}})
		{
			if ($value=~/$_/)
			{
				main::_log("Unsecure variable replacement \"".
				$var.
				"\" z $main::ENV{'REMOTE_ADDR'} s $main::ENV{'QUERY_STRING'} ",1,"secure");
				$value=$null;
				last;
			}
		}
		
		$data=~s|<!TMP-$TMP!>|$value|;
		
	}
	
	$t->close() if $debug;
	return $data;
}



sub CurrencyInt50h
{
	my $price=shift;
	$price=~s|\.||g;
	$price=~s|,|.|g;
	main::_obsolete_func();
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


=head2 s_sort

Sorts strings as numbers with whitespaces and delimiters .,

Nice functions when you need sort these numbers:

 10,5
 12.8
 12 125.5
 128 Kg

Syntax to use

 foreach (sort {s_sort($values{$a},$values{$b})} keys %values)
 {
 	...
 }

=cut

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


=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;
