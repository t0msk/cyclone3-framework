#!/bin/perl
package Ext::POD2DocBook;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Extension POD2DocBook

=head1 DESCRIPTION

Library that generates DocBook files from POD documentation

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	my $dir=(__FILE__=~/^(.*)\//)[0].'/src';
	unshift @INC, $dir;
}

BEGIN {require Pod::DocBook;}

BEGIN {shift @INC;}


use TOM::Temp::file;


sub pod2docbook
{
	my $data=shift;
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."::pod2docbook");
	
	my $parser = Pod::DocBook->new
	(
		doctype => 'article',
		fix_double_quotes => 1,
		spaces => 3
	);
	
	my $tmp_pod=TOM::Temp::file->new('ext'=>'pm');
	$tmp_pod->save_content($data);
	my $tmp_docbook=TOM::Temp::file->new('ext'=>'docbook');
	
	$parser->parse_from_file($tmp_pod->{'filename'}, $tmp_docbook->{'filename'});
	
	open(HND,'<'.$tmp_docbook->{'filename'});local $/;
	my $output=<HND>;
	
	$t->close();
	return $output;
}


1;

=head1 AUTHOR

Roman Fordinal

=cut
