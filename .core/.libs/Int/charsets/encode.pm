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

	'138'	=>	" ", # ?

#	'140'	=>	"",
#	'141'	=>	"",
	'142'	=>	"Z", # SS2 ??? 'Z' s makcenom
	
#	'143'	=>	"",
	
	'145'	=>	"", # PU1

	'154'	=>	"s", # 's' s makcenom
	
	'157'	=>	" ", # ?
	
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
	'188'	=>	"¼", # 1/4
	
	'189'	=>	"½", # 1/2
	'190'	=>	"Z", # 'Z' s makcenom
	'191'	=>	"¿", # obrateny otaznik
	
	'193'	=>	"A", # 'A' s dlznom
	'194'	=>	"A", # 'A' s kruzkom
	'195'	=>	"A", # 'A' s ~
	'196'	=> "A", # 'A' s dvojbodkou
	'197'	=> "A", # 'A' s makcenom
	
	'200'	=> "E", # 'E' s opacnym dlznom
	'201'	=> "E", # 'E' s dlznom na konci
	
	'203'	=> "E", # 'E' s dvoma dlznami
	
	'205'	=>	"I", # 'I' s dlznom
	
	'207'	=>	"I", # 'I' s dvojbodkou
	
	'211'	=> "U", # 'U' s dvomi dlznami
	'212'	=> "U", # 'U' so strieskou
	
	'214'	=>	"O", # 'O' s dvojbodkou
	
	'216'	=>	"O", # 'O' preskrtnute
	
	'218'	=>	"U", # 'U' s dlznom
	
	'220'	=>	"U", # 'U' s dvomi dlznami
	
	'221'	=> "Y", # 'Y' s dlznom na konci
	
	'223'	=>	"S", # 'ß' nemecke ostre s	
	'224'	=>	"a", # 'a' s opacnym dlznom
	'225'	=>	"a", # 'a' s dlznom
	'226'	=> "a", # 'a' so strieskou
	'227'	=> "a", # 'a' s vlnovkou
	'228' =>	"a", # 'a' s dvojbodkou
	'229' =>	"a", # 'a' s kruzkom
	
	'231'	=>	"c", # 'c' s chvostikom
	'232'	=>	"c", # 'c' s makcenom
	'233'	=>	"e", # 'e' s dlznom
	'234'	=> "e", # 'e' s opacnym hacikom
	'235'	=> "e", # 'e' s dvojbodkou
	'236'	=> "i", # 'i' s opacnym dlznom
	'237'	=> "i",
	
	'239'	=> "i", # 'i' s dvojbodkou
	
	'241'	=>	"n", # 'n' s dvomi dlznami
	'242'	=>	"n", # 'n' s makcenom
	'243'	=>	"o", # 'o' s dlznom
	'244'	=>	"o", # 'o' s hacikom
	
	'246'	=>	"o", # 'o' s dvojbodkou
	
	'248'	=>	"o", # 'o' preskrtnute
	'249'	=>	"u", # 'o' s opacnym dlznom
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
	
	'304' => "I", # 'I' s ciarkou
	
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
	
	'8224' => "+", # '†' kriz
	
	'8364' => "(E)", # euro
	
	'8482' =>	"(tm)", # 'tm' trademark
	
	# Pashto
	'1570' => " ^a", # آ
	'1575' => " ", # ARABIC ELEF ا
	'1576' => "b", # ب
	'1577' => "h", # ة
	'1578' => "t", # ت
	'1579' => "s", # ث
	'1580' => "j", # ج
	'1581' => ".h", # ح
	'1582' => "kh", # خ
	'1583' => "d", # د
	'1584' => "z", # ذ
	'1585' => "r", # ر
	'1586' => "z", # ز
	'1587' => "s", # س
	'1588' => "sh", # ش
	'1589' => ".s", # ص
	
	'1594' => "gh", # غ
	
	'1601' => "f", # ف
	'1602' => "q", # ق
	'1603' => "k", # ك
	'1604' => "l", # ل
	'1605' => "m", # م
	'1606' => "n", # ن
	'1607' => "h", # ه
	'1608' => "w", # و
	'1609' => "y", # ى
	
	'1614' => "a", # َ
	
	'1618' => " ", # ARABIC SUKUN ْ
	
	'1632' => "0", # ٠
	'1633' => "1", # ١
	'1634' => "2", # ٢
	'1635' => "3", # ٣
	'1636' => "4", # ٤
	'1637' => "5", # ٥
	'1638' => "6", # ٦
	'1639' => "7", # ٧
	'1640' => "8", # ٨
	'1641' => "9", # ٩
	
	'1662' => "p", # پ
	
	'1665' => "dz", # ځ
	
	'1669' => "ts", # څ
	'1670' => "ch", # چ
	
	'1686' => "z _h", # ږ
	
	'1688' => "zh", # ژ
	
	'1690' => "s _h", # ښ
	
	'1711' => "g", # گ
	'1712' => "g", # ڰ
	
	'1740' => "y", # ی
	
	'1744' => "e", # ې
	
#	'8226' =>	"", #
#	'8230' =>	"", #

#	'8482' =>	"", #

#	'9829' => "?", # srdce

#	'61514' =>	"", #

#	'61516' =>	"", #

	'65279' => " ", # medzera?

);


our %table_string=
(
#	'زژ' => "ey",
#	'ق ک' => "aaaay",
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
	# enable utf8 flag unless enabled
	# only utf8 string can be converted
	utf8::decode($text) unless utf8::is_utf8($text);
	
	foreach (keys %table_string)
	{
		print "test $_\n";
		$text=~s|$_|$table_string{$_}|g;
	}
	
	$text=~s/([^a-zA-Z0-9\s])/UTF8_ASCII_($1)/eg;
	return $text;
}


1;
