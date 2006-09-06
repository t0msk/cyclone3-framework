package TOM::Debug;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM::Debug::logs;
use TOM::Debug::breakpoints;
use XML::Generator;

package main;

sub _obsolete_func
{
	my $msg=shift;
	my %env=@_;
	
	my ($package, $filename, $line, $subroutine) = caller(1);
	my ($package2, $filename2, $line2) = caller(0);
	
	main::_log("calling obsolete function '$subroutine' $msg",4);
	if ($msg)
	{
		main::_log("func:'$filename2:$line2:$subroutine' from:'$filename:$line' msg:{$msg}",4,"obsolete",1);
	}
	else
	{
		main::_log("func:'$filename2:$line2:$subroutine' from:'$filename:$line'",4,"obsolete",1);
	}
	
	my $X = XML::Generator->new(':pretty');
	
	my $xml_msg=
	$X->obsolete(
		$X->type("function"),
		$X->timestamp(time()),
		$X->call_filename($filename),
		$X->call_line($line),
		$X->func_filename($filename2),
		$X->func_line($line2),
		$X->func($subroutine)
	)."\n";
	
	open (HND_OBSOLETE,'>>'.$TOM::P.'/_logs/obsolete/'.$$.'.xml') || main::_log("obsolete $!");
	print HND_OBSOLETE $xml_msg;
	close (HND_OBSOLETE);
	
	return 1;
}


1;
