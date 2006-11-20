package Int::charsets::encode;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our %table=
(
#

	'130'	=>	" ",
	'131'	=>	" ",

#	'136'	=>	"",

#	'140'	=>	"",
#	'141'	=>	"",
	'142'	=>	"Z", # SS2 ??? 'Z' s makcenom
	
#	'143'	=>	"",
	
	'145'	=>	"", # PU1

	'154'	=>	"s", # 's' s makcenom
	
	'158'	=>	"z", # 'z' s makcenom
	
	'161'	=>	"i", # 'i' divne
	
	'164'	=>	"'", # napriklad v slove "don't"
	'165'	=>	"¥", # yen - mena
	
	'167'	=>	"§", # paragraf
	'169'	=>	"S", # 'S' s makcenom
	
	'173'	=>	"-", # pomlcka
	'174'	=>	"z", # 'z' s makcenom
	
	'176'	=>	" ", # pevna medzera
	
	'180'	=>	"'", # napriklad v slove "don't"
	'181'	=>	"l", # 'l' s makcenom
	
	'185'	=>	"s", # 's' s makcenom
	'186'	=>	"º", # stupne - ºC
	
	'187'	=>	"»", # dvojita pomlcka
	
	'189'	=>	"½", # 1/2
	'190'	=>	"Z", # 'Z' s makcenom
	'191'	=>	"¿", # obrateny otaznik
	
	'193'	=>	"A", # 'A' s dlznom
	'194'	=>	"A", # 'A' s kruzkom
	'195'	=>	"A", # 'A' s ~
	'196'	=> "A", # 'A' s dvojbodkou
	'197'	=> "A", # 'A' s makcenom
	
	'201'	=> "E", # 'E' s dlznom na konci
	
	'203'	=> "E", # 'E' s dvoma dlznami
	
	'205'	=>	"I", # 'I' s dlznom
	
	'211'	=> "U", # 'U' s dvomi dlznami
	'212'	=> "U", # 'U' so strieskou
	
	'214'	=>	"O", # 'O' s dvojbodkou
	
	
	'218'	=>	"U", # 'U' s dlznom
	
	'220'	=>	"U", # 'U' s dvomi dlznami
	
	'221'	=> "Y", # 'Y' s dlznom na konci
	
	'223'	=>	"S", # 'ß' nemecke ostre s
	
#	'224'	=>	"", #
	'225'	=>	"a", # 'a' s dlznom
	'226'	=> "a", # 'a' so strieskou
	'227'	=> "a", # 'a' s vlnovkou
	'228' =>	"a", # 'a' s dvojbodkou
	
	'231'	=>	"c", # 'c' s chvostikom
	'232'	=>	"c", # 'c' s makcenom
	'233'	=>	"e", # 'e' s dlznom
	
	'235'	=> "e", # 'e' s dvojbodkou
	
	'237'	=> "i",
	
	'241'	=>	"n", # 'n' s dvomi dlznami
	'242'	=>	"n", # 'n' s makcenom
	'243'	=>	"o", # 'o' s dlznom
	'244'	=>	"o", # 'o' s hacikom
	
	'246'	=>	"o", # 'o' s dvojbodkou
	
	'250'	=>	"u", # 'u' s dlznom
	
	'252'	=>	"u", # 'u' s dvojdlznom
	'253'	=>	"y",
	
	'259'	=>	"a", # 'a' s hacikom
	
	'261'	=> "a", # 'c' s chvostikom
	
	'263'	=> "c", # 'c' s dlzdnom
	
	'268'	=>	"C", # 'C' s makcenom
	'269'	=>	"c", # 'c' s makcenom
	'270'	=>	"D", # 'D' s makcenom
	'271'	=>	"d", # 'd' s makcenom
	'272'	=> "D", # 'D' presktnute
	
	'282'	=>	"E", # 'E' s makcenom
	'283'	=>	"e", # 'e' s makcenom
	
	'313'	=>	"L", # 'L' s dlznom
	'314'	=>	"l", # 'l' s dlznom
	
	'317'	=>	"L", # 'L' s makcenom
	'318'	=>	"l", # 'l' s makcenom
	
	'322'	=> "l", # 'l' preskrtnute
	'323'	=> "N", # 'N' s dlznom
	'324'	=> "n", # 'n' s dlznom
	
	'327'	=>	"N", # 'N' s makcenom
	'328'	=>	"n", # 'n' s makcenom
	
	'336'	=>	"O", # 'o' s vlnovkou
	'337'	=>	"o", # 'o' s dlznom
	
	'341'	=>	"r", # 'r' s dlznom
	
	'344'	=>	"R",
	'345'	=>	"r",
	
	'347'	=> "s", # 's' s dlznom
	
	'350'	=>	"S", # 'S' s chvostikom
	'351'	=>	"s", # 'S' s chvostikom
	'352'	=>	"S", # 'S' s makcenom
	'353'	=>	"s", # 's' s makcenom
	
	'356'	=>	"T", # 'T' s makcenom
	'357'	=>	"t", # 't' s makcenom
	
	'366'	=>	"U", # 'U' s kruzkom
	'367'	=> "u", # 'u' s kruzkom
	
	'369'	=> "u", # 'u' s dvomi dlzdnami
	
	'377'	=> "Z", # 'Z' na konci s dlznom
	'378'	=>	"z", # 'z' s dlznom
	'379'	=>	"Z", # 'Z' s dlznom
	
	'380'	=>	"z", # 'z' s bodkou
	'381'	=>	"Z", # 'Z' s makcenom
	'382'	=>	"z", # 'z' s makcenom
	
	'711'	=>	"ˇ", # makcen
	
	'728'	=>	"ˇ", # makcen
	
	'733'	=>	"\"", # dva horne apostrofy
	
	'1041'	=> "B", # 'Б' v azbuke
	
	'1053'	=> "N", # 'Н'  v azbuke
	
	'1072'	=> "а", # 'а'  v azbuke
	
	'1076'	=> "d", # 'д'  v azbuke
	'1077'	=> "e", # 'е'  v azbuke
	
	'1085'	=> "n", # 'н'  v azbuke
	
	'1089'	=> "s", # 'с'  v azbuke
	'1090'	=> "t", # 'т'  v azbuke
	
	'1103'	=> "ja", # 'я'  v azbuke	
	
	
#	'711'	=>	"", #
	
	'8211' =>	"-", # '-'

	'8216' =>	"'", #  horne apostrofy zaciatok
	'8217' =>	"'", #  horne apostrofy koniec
	'8218' =>	",", #  ciarka
		
	'8220' =>	"\"", # '' horne apostrofy zaciatok
	'8221' =>	"\"", # '' horne apostrofy koniec
	'8222' =>	"\"", # '' dolne apostrofy
	
	'8226' =>	"*", # '' gulicka
	
	'8230' => "...", # ... tri bodky na jednom znaku
	
	'8364' => "(E)", # euro
	
	'8482' =>	"(tm)", # 'tm' trademark

#	'8226' =>	"", #
#	'8230' =>	"", #

#	'8482' =>	"", #

#	'9829' => "?", # srdce

#	'61514' =>	"", #

#	'61516' =>	"", #

	'65279' => " ", # medzera?

);


sub UTF8_ASCII_
{
	return $table{ord($_[0])} if $table{ord($_[0])};
	
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require) = caller(1);
	main::_log("Int::charsets::encode::* ASCII from UTF-8 \\$_[0] {".(ord($_[0]))."} - unknown from ($package/$filename/$line)",1,"lib.err",1) if (ord($_[0])>127);
	return "\\utf{".ord($_[0])."}" if ord($_[0])>127;
	
	return $_[0];
}

sub UTF8_ASCII
{
	my $text=shift;
	utf8::decode($text) unless utf8::is_utf8($text);
	$text=~s/([^a-zA-Z0-9\s])/UTF8_ASCII_($1)/eg;
	return $text;
}


1;
