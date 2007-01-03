#!/bin/perl
package SVGraph::Core;

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	main::_obsolete_func();
}

use Ext::SVGraph::_init;

1;
