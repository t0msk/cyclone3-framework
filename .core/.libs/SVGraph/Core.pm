#!/bin/perl
package SVGraph::Core;

=head1 NAME

SVGraph::Core in .core/.libs

=cut

=head1 DESCRIPTION

Obsolete implementácia SVGraph v Cyclone3. Nová implementácia SVGraph sa nachádza v addons.

Táto knižnica len volá L<Ext::SVGraph::_init>;

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	main::_obsolete_func();
}

use Ext::SVGraph::_init;

1;
