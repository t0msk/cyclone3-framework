package Secure::form;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub convert
{
	foreach (@_)
	{
		$_=~s|\\|\\\\|g;
		$_=~s|\"|\\"|g;
		$_=~s|\'|\\'|g;
	}
return 1
}


sub convert_sql
{
	foreach (@_)
	{
		$_=~s|\\|\\\\|g;
		$_=~s|\"|\\"|g;
		$_=~s|\'|\\'|g;
	}
return 1
}


sub convert_tags
{
	foreach (@_)
	{
	$_=~s|<|&lt;|g;
	$_=~s|>|&gt;|g;
	}
	return 1
}


sub check_email
{
	my $email=shift;
	return undef if $email=~/\.\./;
	return 1 if $email=~/^[a-zA-Z0-9_\.\-]{2,50}\@[a-zA-Z0-9_\.\-]{2,100}\.[a-zA-Z0-9]{2,10}$/;
	return undef;
}




1;
