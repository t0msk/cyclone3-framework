#!/bin/perl
package App::401::keywords;

=head1 NAME

App::401::keywords

=head1 DESCRIPTION

Handle article source keywords processing

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::401::_init|app/"401/_init.pm">

=back

=cut

use App::401::_init;



sub html_extract
{
	my $html=shift;
	my %keywords;
	
	while ($html=~s|<span.*?class="a420_keyword".*?>(.*?)</span>||)
	{
		my $keyword=$1;
		$keyword=~s|<.*?>||g;
		$keywords{$keyword}++;
	}
	
	return %keywords;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
