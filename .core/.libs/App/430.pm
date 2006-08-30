#!/bin/perl
package App::430;
#use App::1B0::SQL; # pytam si SQL a SQL si pyta vsetko pod nim
use strict;
use Time::Local;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



sub get_ticker_beta
{
	my $name=shift;
	my $env;
	my $db0=$main::DB{main}->Query("
		SELECT *
		FROM	TOM.a430_messages
		WHERE
				(
					domain=''
					OR
					(
						domain='$tom::Hm'
						AND (domain_sub='$tom::H' OR domain_sub='')
					)
				)
				AND time_start<=$main::time_current
				AND (time_end>=$main::time_current OR time_end IS NULL)
	");
	while (my %db0_line=$db0->fetchhash)
	{
		push @{$env},{%db0_line};
	}
	return $env;
}






1;


=head1
App::1B0::IsBanned(
	IP		=>	"192.168.0.1",
	a300		=>	"NyJsqrmgh",
	-type		=>	"app",
	-what	=>	"820",
);
=cut
=head1
sadfasdfasdfasfdasfdas
asdfas
dfas
fdasf
asdfasfdasdfasdfhasflasjflasflasjfljaslfjaslf;dasjfas
fasdfl;asfjlasfjal;sdfjl;asjfdl;asdjfl;sajflas;dfj;aslfas
fasfj;alsfjas;lfjasl;fja;sdfjasda;sdlfjasl;fd:w!
asdfasdfjwoerjsladfjasldfjals;dfjasl;jfasjf;as
asfla;sfj;alsdj;saldjsaldf;jsad;ljfd;ldjs;lasjf;asfdlj
asdff;alsdja;lsdfjal;sjasl;fdjsa;lfjlasfljsadf;lasdfj
asdjk;lsaj;lsajlas;djsal;jslad;ja;lsfjas;ljas;lasjdfl;asdf
sadfl;asdja;slfjas;ldjasl;fjas;ldfjasdlfjasd;lfajs;lasfdj
asdjlas;jsa;ldfjas;ljas;fja
=cut
=head1
sadfasdfasdfasfdasfdas
asdfas
dfas
fdasf
asdfasfdasdfasdfhasflasjflasflasjfljaslfjaslf;dasjfas
fasdfl;asfjlasfjal;sdfjl;asjfdl;asdjfl;sajflas;dfj;aslfas
fasfj;alsfjas;lfjasl;fja;sdfjasda;sdlfjasl;fd:w!
asdfasdfjwoerjsladfjasldfjals;dfjasl;jfasjf;as
asfla;sfj;alsdj;saldjsaldf;jsad;ljfd;ldjs;lasjf;asfdlj
asdff;alsdja;lsdfjal;sjasl;fdjsa;lfjlasfljsadf;lasdfj
asdjk;lsaj;lsajlas;djsal;jslad;ja;lsfjas;ljas;lasjdfl;asdf
sadfl;asdja;slfjas;ldjasl;fjas;ldfjasdlfjasd;lfajs;lasfdj
asdjlas;jsa;ldfjas;ljas;fja
=cut
