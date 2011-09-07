#!/bin/perl
package App::400::format;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}
#our @ISA=("App::0::SQL_old"); # pytam si abstrakciu



sub reformat
{
	my $text=shift;
	my $debug=shift;
	
	
	if ($debug){print "vstup:\n";print $text."\n";}
	
	$text.="\n\n";

	
	
#	<br /><p><span><o:p><FONT face="times new roman" size=2>&nbsp;</font></o:p></span><br />
#	&nbsp;
		
	# cistenie whitespaces
	$text=~s|\r||g;
	$text=~s|\n|<br />|g;

	# precitim &nbsp; medzi odstavcami
	#?????? - ako?
	
	
	
	# zamenim nespravne odstavce na spravne
	1 while ($text=~s|<br /><br /><br />|<br /><br />|g);
	#if ($debug){print "zamenim nespravne odstavce na spravne:\n";print $text."\n";}	
	
	# cistenie dlhych tagov od parametrov tam kde ich nechcem
	$text=~s/<(p|span|br|font) .*?>/<$1>/gi;
	#if ($debug){print "cistenie dlhych tagov od parametrov tam kde ich nechcem:\n";print $text."\n";}
	
	# lowercase tagov (len bez parametrov)
	$text=~s|<([A-Z/ ]*?)>|\L<$1>|g;
	#if ($debug){print "lowercase tagov (len bez parametrov):\n";print $text."\n";}
	
	# standardizovat uzavrete tagy
	$text=~s|<([^<>]*?)></\1>|\L<$1 />|g;
	#if ($debug){print "standardizovat uzavrete tagy:\n";print $text."\n";}
	
	# uzatvorenie tagov
	$text=~s/<(hr|br)>/<$1 \/>/gs;
	#if ($debug){print "uzatvorenie tagov:\n";print $text."\n";}
	
	# odstranit nedolezite uzavrete tagy
	$text=~s/<(span|font) \/>//g;
	#if ($debug){print "odstranit nedolezite uzavrete tagy:\n";print $text."\n";}
	
	# odstranit nedolezite tagy
	$text=~s/<[\/]?(font|o:p|\?xml.*?)(|\/| \/)>//g;
	#if ($debug){print "odstranit nedolezite uzavrete tagy:\n";print $text."\n";}
	
	# odstranit zbytocne &nbsp; tam kde nepatri
	# medzi slovami
	$text=~s/(\w)&nbsp;(\w)/$1 $2/g;
	
	
	
	
	# standardizovat text
	
	# zmena odstavcov
	#$text=~s|(.*)<br />(.*?)<br /><br />|$1<p>$2</p>|gs;
	while ($text=~s|<br /><br />(.*?)<br /><br />|<p>$1</p>|gs)
	{
		if ($debug){print "\nzmena odstavcov:\n";print $text."\n";}
	}
	$text=~s|</p>(.*?)<p>|</p><p>$1</p><p>|gs;
	if ($debug){print "\nzmena odstavcov:\n";print $text."\n";}
	#$text=~s|<br /><p>|<p>|g;
	#$text=~s|<br /><p>|<p>|g;
	
	#$text=~s|<STRONG></STRONG>||g;
	
	
	# NAKONIEC ZAMENA UZIVATELSKYCH FLAGOV
	
	
	
	
	
	
	return $text;
}



=head1
asdfljasdf;lasjdfljasdf;lajs;lfasjdfl;asdjf
asdfajs;lfdjasdf;lajsdfl;asjf;lsajfdl;asjfl;asf
asdfjals;dflajsfd;lasjfalsfjasl;fjas;lfdjasl;fdjas
asdfl;asfj;alsfjas;lfjas;lfjasl;jasf;ljasf;lajsdf
asdfjals;fdjasf;ljasf;lasjfla;sjfdl;asjf;alsfdjlas;fjas
asdasl;dfjas;dlfjas;ldfjasl;dfjas;ldfja;slfdjas;lfdj;asfd
asdfjasd;fljasdfl;jasdf;lasjflasfj;slajf;asljfaslfjas;ljf
asfj;lasdfjas;ljfasl;jsald;fjasldfjasl;fjasl;fjaslf
asdfl;asdfjas;dfljas;lfjas;lfjasl;fdjas;ldfjas;fdasjfd
asdjkas;dlfjas;dfljasd;fljasd;fljsadfl;ajsf;lasjdfl;asdfj
asdfjas;ldfjasd;ljas;fljas;lfjasdl;fjasdl;jas;ldfja;sldj
asdlj;asdfjas;dljasd;fljasdl;jasd;lfjasdf;ljasdf;ljasdf;l
asdfjl;asdfjas;dljasd;fljasd;fljasdfl;asjdfl;asjd;lasj
asdl;a;sjdf;lasdjasl;djasl;dfjas;ldjas;dlfjasdf;las
sadkl;asdjl;asdfjasl;djasd;lfjsdl;fjsad;lfjasd;fljasdf
asdl;fasjd;lasdjfl;asjdf;lasdjas;ldfjasdl;fjasdl;fjas;dlf
asdjas;dlfjasd;ljfas;ldfjdasl;jasdl;jflasdj;flasdjl;sad;
asdfjlkas;dlasj;lasjd;lsaj;fldjsl;jasd;lfjasdl;jsldjasd;fl
sad;lasdjal;sdjdsal;jas;ldjfls;daja;sdlfja;sdlja;sdljasd;lf
asdj;;lasdjasl;djasd;ljas;ldjasldfjasld;jasd;ljsadl;jsa;dl
asdfjalsd;j;sadljfas;dljasd;ljladsfljasd;jlads;lja;ljasd
asdfjklasdfl;kjdfsa;jlkdsfajl;sda;jlkdsfaj;kdfs;ljdfsa;lj
sdfajlksdfa;lkdfsa;lkdjl;kdasf;jklasdf;jkdsfa;jadsf;jadsf
asdfl;kjasdf;ljkdsfajlkdfsal;jkdfsa;dfsa;dfsa;ldfas;jlasdf
;lasdf;ljkdsfajkldfs;ljkdfsa;jsdf;lasd;jadsj;dafs;
=cut

1;