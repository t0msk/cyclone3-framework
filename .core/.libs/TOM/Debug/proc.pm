package TOM::Debug::proc;

=head1 NAME

TOM::Debug

=head1 DESCRIPTION

Knižnica pre analýzy chovania Cyclone3

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use Proc::ProcessTable;


sub get_proc_info
{
	my %data;
	my $t = new Proc::ProcessTable;
	foreach my $p (@{$t->table} )
	{
		my @arr=$t->fields;
		if ($p->pid == $$)
		{
			$data{'size'}=$p->size;
			return %data;
		}
	}
}

1;
