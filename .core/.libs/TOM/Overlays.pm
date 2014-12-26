package TOM::Overlays;

=head1 NAME

TOM::Overlays

=head1 DESCRIPTION

Initialize stuff in _overlays subdirectories

With overlay anyone can enhance or rebuild Cyclone3 Framework without modifying core files and addons, also build another sofware based on CYclone3 Framework.

Every directory in _overlays has directory structure similar to Cyclone3 Framework root directory:

=over

=item *

_addons

=item *

.libs

=item *

_dsgn

=item *

_type

=back

Overlay initialization can be skipped when .ignore file is available in overlay directory, so the present overlay is ignored.

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @item;

BEGIN
{
	my $t=track TOM::Debug("_overlays");
	
	if (opendir (DIR,$TOM::P."/_overlays"))
	{
		my $i;
		foreach my $file(sort readdir DIR)
		{
			next unless -d $TOM::P.'/_overlays/'.$file;
			next if $file=~/^\./;
			next if -e $TOM::P.'/_overlays/'.$file.'/.ignore';
			
			$i++;
			main::_log("init '$file' prior: $i");
			
			unshift @item, $file;
			unshift @INC, $TOM::P.'/_overlays/'.$file.'/.libs';
			unshift @INC, $TOM::P.'/_overlays/'.$file.'/_addons';
		}
		closedir(DIR);
	}
	
	$t->close();
}


1;
