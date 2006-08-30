package TOM::Debug::pub;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub output_save
{
	my $t=track TOM::Debug(__PACKAGE__."::output_save()");
		my $filename="../_logs/_debug/page_".$main::request_code.".".(time()).".output";
		main::_log("saving into file '$filename'");
		open (HND_SAVE,">".$filename);
		print HND_SAVE $main::H->{OUT}{HEADER}."\n".$main::H->{OUT}{BODY}."\n".$main::H->{OUT}{FOOTER};
		close (HND_SAVE);
	$t->close();
}




1;
