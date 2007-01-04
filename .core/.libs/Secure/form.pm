package Secure::form;
use strict;

=head1 NAME

Secure::form

=head1 DESCRIPTION

Knižnica ktorá má za úlohu ošetrovať vstupy z formulárov

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 FUNCTIONS

=head2 convert()

obsolete

=cut

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

=head2 convert_sql(@)

Zamena znakov \"' v mnozine SQL prikazov predtym nez sa vykonaju

=cut

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

=head2 convert_tags()

=cut

sub convert_tags
{
	foreach (@_)
	{
	$_=~s|<|&lt;|g;
	$_=~s|>|&gt;|g;
	}
	return 1
}

=head2 check_email()

=cut

sub check_email
{
	my $email=shift;
	return undef if $email=~/\.\./;
	return 1 if $email=~/^[a-zA-Z0-9_\.\-]{2,50}\@[a-zA-Z0-9_\.\-]{2,100}\.[a-zA-Z0-9]{2,10}$/;
	return undef;
}




1;
