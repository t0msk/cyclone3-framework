#!/usr/bin/perl
package main;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

use TOM;
use Utils::datetime;

#sub _log {return _log_lite(@_)}

=head2 _log_stdout()

Log message to STDOUT when $main::stdout is enabled. Used to log in console utils

=cut

=head1
sub _log_stdout
{
	return undef unless $main::stdout;
	$_[2]="stdout";
	_log(@_);
}


# main::_applog($urovne,"$text",$critique,$global);
# main::_applog(0,"spustam prikaz");
# main::_applog(1,"spustam dalsi","300");
sub _applog
{
	if ($_[0]=~/^\d+$/)
	{
		shift @_;
		#return _log(@_);
	}
	return _log(@_);
}


# tu pridam uz rozoznavanie domen
sub _deprecated
{
	#return 1;
	my ($package, $filename, $line) = caller;
	_log("[".($tom::H || "?domain?")."] ".$_[0]." from $filename:$line",0,"deprecated",1);
}


package TOM::Debug::logs;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}
=cut

1;# DO NOT CHANGE !
