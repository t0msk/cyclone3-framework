#!/bin/perl
package App::910::metadata;

=head1 NAME

App::910::metadata

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=0;
our $quiet;$quiet=1 unless $debug;
our $log_changes=$App::910::log_changes || undef;

sub preprocess
{
    my $metadata = shift;
    
    return 1;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
