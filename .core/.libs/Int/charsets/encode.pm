package Int::charsets::encode;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our %table=
(
#
	'128' => "",
	'129' => "", # 
	'130'	=>	" ",
	'131'	=>	" ",

#	'136'	=>	"",

	'138'	=>	" ", # ?
	
	'140'	=>	"OE", # PARTIAL LINE BACKWARD
	'141'	=>	"", # REVERSE LINE FEED
	'142'	=>	"Z", # SS2 ??? 'Z' s makcenom
	
#	'143'	=>	"",
	
	'145'	=>	"", # PU1
	
	'147'	=>	"", # STS
	
	'152' => "~", # START OF STRING
	'153'	=>	"(tm)", # znak 'tm'
	'154'	=>	"s", # 's' s makcenom
	'155' => ">", # CONTROL SEQUENCE INTRODUCER
	'156' => "oe", # STRING TERMINATOR
	'157'	=>	" ", # ?
	
	'158'	=>	"z", # 'z' s makcenom
	
	'161'	=>	"!", # '¡' 
	'162'	=>	"c", # '¢'
	'163' => "£", # '£'
	
	'164'	=>	"'", # napriklad v slove "don't"
	'165'	=>	"¥", # yen - mena
	
	'167'	=>	"§", # paragraf
	'168'	=>	"", # '¨'
	'169'	=>	"S", # 'S' s makcenom
	
	'171'	=>	"<", # '«'
	
	'173'	=>	"", # soft hyphen (don't display!)
	'174'	=>	"z", # 'z' s makcenom
	
	'176'	=>	" ", # pevna medzera
	'177'	=>	"plusminus", # ±
	
	'179' => "f", # NO BREAK HERE
	'180'	=>	"'", # napriklad v slove "don't"
	'181'	=>	"l", # 'l' s makcenom
	'182'	=>	"", # PILCROW SIGN
	
	'184'	=>	"", # '¸'
	'185'	=>	"s", # 's' s makcenom
	'186'	=>	"º", # stupne - ºC
	
	'187'	=>	"»", # dvojita pomlcka
	'188'	=>	"¼", # 1/4
	
	'189'	=>	"½", # 1/2
	'190'	=>	"Z", # 'Z' s makcenom
	'191'	=>	"?", # '¿' obrateny otaznik
	'192'	=>	"A", # 'À'
	'193'	=>	"A", # 'A' s dlznom
	'194'	=>	"A", # 'A' s kruzkom
	'195'	=>	"A", # 'A' s ~
	'196'	=> "A", # 'A' s dvojbodkou
	'197'	=> "A", # 'A' s makcenom
	'198'	=> "Ae", # 'Æ'
	'199'	=> "C", # 'Ç'
	'200'	=> "E", # 'E' s opacnym dlznom
	'201'	=> "E", # 'E' s dlznom na konci
	'202'	=> "E", # 'Ê'

	'203'	=> "E", # 'E' s dvoma dlznami
	'204'	=> "I", # 'Ì' s dvoma dlznami
	'205'	=>	"I", # 'Í' s dlznom
	
	'206'	=>	"I", # 'Î'
	'207'	=>	"I", # 'I' s dvojbodkou
	'208'	=>	"D", # 'Ð'
	'209'	=>	"N", # 'Ñ'
	'210'	=>	"O", # 'Ò'
	'211'	=> "O", # 'Ó'
	'212'	=> "O", # 'Ô'
	'213'	=> "O", # 'Õ'
	'214'	=>	"O", # 'O' s dvojbodkou
	
	'215'	=>	"x", # '×' znak nasobenia
	
	'216'	=>	"O", # 'O' preskrtnute
	'217'	=>	"U", # 'Ù'
	'218'	=>	"U", # 'Ú'
	'219'	=>	"U", # 'Û'
	'220'	=>	"U", # 'U' s dvomi dlznami
	
	'221'	=> "Y", # 'Y' s dlznom na konci
	
	'223'	=>	"S", # 'ß' nemecke ostre s	
	'224'	=>	"a", # 'a' s opacnym dlznom
	'225'	=>	"a", # 'a' s dlznom
	'226'	=> "a", # 'a' so strieskou
	'227'	=> "a", # 'ã' s vlnovkou
	'228' =>	"a", # 'a' s dvojbodkou
	'229' =>	"a", # 'a' s kruzkom
	'230' =>	"ae", # 'æ'
	'231'	=>	"c", # 'c' s chvostikom
	'232'	=>	"c", # 'c' s makcenom
	'233'	=>	"e", # 'e' s dlznom
	'234'	=> "e", # 'e' s opacnym hacikom
	'235'	=> "e", # 'e' s dvojbodkou
	'236'	=> "i", # 'i' s opacnym dlznom
	'237'	=> "i",
	'238'	=> "i", # 'î'
	'239'	=> "i", # 'i' s dvojbodkou
	'240'	=> "eth", # 'ð'
	'241'	=>	"n", # 'n' s dvomi dlznami
	'242'	=>	"n", # 'n' s makcenom
	'243'	=>	"o", # 'o' s dlznom
	'244'	=>	"o", # 'o' s hacikom
	'245'	=>	"o", # 'õ'
	'246'	=>	"o", # 'o' s dvojbodkou
	
	'248'	=>	"o", # 'o' preskrtnute
	'249'	=>	"u", # 'o' s opacnym dlznom
	'250'	=>	"u", # 'u' s dlznom
	'251'	=>	"u", # 'û' s dlznom
	'252'	=>	"u", # 'u' s dvojdlznom
	'253'	=>	"y",

	'255'	=> "y", # 'ÿ'
	'256'	=> "A", # 'Ā'
	'257'	=> "a", # 'ā'
	'258'	=> "A", # 'Ă'
	
	'259'	=>	"a", # 'ă'
	
	'260'	=> "A", # 'Ą'
	'261'	=> "a", # 'ą'
	'262'	=> "C", # 'Ć'
	'263'	=> "c", # 'c'
	
	'268'	=>	"C", # 'C' s makcenom
	'269'	=>	"c", # 'c' s makcenom
	'270'	=>	"D", # 'Ď' s makcenom
	'271'	=>	"d", # 'ď' s makcenom
	'272'	=> "D", # 'Đ' presktnute
	'273'	=> "d", # 'đ' presktnute

	'274'	=> "E", # 'Ē'
	'275'	=> "e", # 'ē'
	'277'	=> "e", # 'ĕ'
	'278'	=> "E", # 'Ė'
	'279'	=> "e", # 'ė'
	'280'	=> "E", # 'Ę'
	'281'	=> "e", # 'ę'
	
	'282'	=>	"E", # 'Ě' s makcenom
	'283'	=>	"e", # 'ě' s makcenom
	
	'290'	=>	"G", # 'Ģ
	'291'	=>	"g", # 'ģ
	'298'	=>	"I", # 'Ī
	'299'	=>	"i", # 'ī
	'302'	=>	"I", # 'Į
	'303'	=>	"i", # 'į
	'304' => "I", # 'I' s ciarkou

	'310'	=>	"K", # 'Ķ
	'311'	=>	"k", # 'ķ
	
	'313'	=>	"L", # 'Ĺ' s dlznom
	'314'	=>	"l", # 'ĺ' s dlznom
	'315'	=>	"L", # 'Ļ'
	'316'	=>	"l", # 'ļ'
	'317'	=>	"L", # 'Ľ' s makcenom
	'318'	=>	"l", # 'ľ' s makcenom
	'321'	=> "L", # 'Ł' preskrtnute
	'322'	=> "l", # 'ł' preskrtnute
	'323'	=> "N", # 'Ń'
	'324'	=> "n", # 'ń'
	'325'	=> "N", # 'Ņ'
	'326'	=> "n", # 'ņ'
	'327'	=>	"N", # 'Ň'
	'328'	=>	"n", # 'ň'
	
	'332'	=>	"O", # 'Ō'
	'333'	=>	"o", # 'ō'
	
	'336'	=>	"O", # 'o' s vlnovkou
	'337'	=>	"o", # 'ó'
	'338'	=>	"Oe", # 'Œ'
	'339'	=>	"oe", # 'œ'

	'341'	=>	"r", # 'r' s dlznom
	'342'	=>	"R", # 'Ŗ'
	'343'	=>	"r", # 'ŗ'
	'344'	=>	"R", # 'Ř'
	'345'	=>	"r", # 'ř'
	'346'	=> "S", # 'Ś'
	'347'	=> "s", # 'ś'
	
	'350'	=>	"S", # 'Ş' s chvostikom
	'351'	=>	"s", # 'ş' s chvostikom
	'352'	=>	"S", # 'Š' s makcenom
	'353'	=>	"s", # 'š' s makcenom
	'354'	=>	"T", # 'Ţ'
	'355'	=>	"t", # 'ţ'
	'356'	=>	"T", # 'Ť' s makcenom
	'357'	=>	"t", # 'ť' s makcenom
	
	'366'	=>	"U", # 'U' s kruzkom
	'367'	=> "u", # 'u' s kruzkom
	'368'	=> "U", # 'Ű' s dvomi dlznami
	'369'	=> "u", # 'u' s dvomi dlznami
	
	'370'	=> "U", # 'Ų'
	'371'	=> "u", # 'ų'
	'376'	=> "Y", # 'Ÿ'
	
	'377'	=> "Z", # 'Z' na konci s dlznom
	'378'	=>	"z", # 'z' s dlznom
	'379'	=>	"Z", # 'Z' s dlznom
	
	'380'	=>	"z", # 'z' s bodkou
	'381'	=>	"Z", # 'Z' s makcenom
	'382'	=>	"z", # 'z' s makcenom
	
	'536'	=>	"S", # 'Ș'
	'537'	=>	"s", # 'ș'
	'538'	=>	"T", # 'Ț'
	'539'	=>	"t", # 'ț'
	
	'711'	=>	"ˇ", # makcen
	
	'728'	=>	"ˇ", # makcen
	
	'733'	=>	"\"", # dva horne apostrofy
	
	'1028'	=> "Є", # 'E' v azbuke
	
	'1030'	=> "I", # 'І' v azbuke
	'1031'	=> "J", # 'Ї' v azbuke
	
	'1040'	=> "A", # 'А' v azbuke
	'1041'	=> "B", # 'Б' v azbuke
	'1042'	=> "V", # 'В' v azbuke
	'1043'	=> 'G', # 'Г' v azbuke
	'1044'	=> "D", # 'Д' v azbuke
	'1045'	=> "E", # 'Е' v azbuke
	
	'1046'	=> "Zh", # 'Ж' v azbuke (ž/zh)	
	'1047'	=> "Z", # 'З' v azbuke
	'1048'	=> "I", # 'И' v azbuke
	'1049'	=> "Y", # 'Й' v azbuke
	'1050'	=> "K", # 'К' v azbuke
	'1051'	=> "L", # 'Л' v azbuke
	'1052'	=> "M", # 'М' v azbuke
	'1053'	=> "N", # 'Н' v azbuke
	'1054'	=> "O", # 'О' v azbuke
	'1055'	=> "P", # 'П' v azbuke
	'1056'	=> "R", # 'Р' v azbuke
	'1057'	=> "S", # 'С' v azbuke
	'1058'	=> "T", # 'Т' v azbuke
	'1059'	=> "U", # 'U' v azbuke
	'1060'	=> "F", # 'Ф' v azbuke
	'1061'	=> "H", # 'Х' v azbuke
	'1062'	=> "C", # 'Ц' v azbuke
	'1063'	=> "CH", # 'Ч' v azbuke
	'1064'	=> "SH", # 'Ш' v azbuke
	'1065'	=> "Sth", # 'Щ' v azbuke
	'1066'	=> "A", # 'Ъ' v azbuke
	
	'1068'	=> "Y", # 'Ь' v azbuke
	
	'1070'	=> "Yu", # 'Ю' v azbuke
	'1071'	=> "Ya", # 'Я' v azbuke
	'1072'	=> "a", # 'а' v azbuke
	'1073'	=> "b", # 'б' v azbuke
	'1074'	=> "v", # 'в' v azbuke
	'1075'	=> "g", # 'г' v azbuke
	'1076'	=> "d", # 'д' v azbuke
	'1077'	=> "e", # 'е' v azbuke
	'1078'	=> "zh", # 'ж' v azbuke
	'1079'	=> "z", # 'з' v azbuke
	'1080'	=> "i", # 'и' v azbuke
	'1081'	=> "y", # 'й' v azbuke
	'1082'	=> "k", # 'к' v azbuke
	'1083'	=> "l", # 'л' v azbuke
	'1084'	=> "m", # 'м' v azbuke
	'1085'	=> "n", # 'н' v azbuke
	'1086'	=> "o", # 'о' v azbuke
	'1087'	=> "p", # 'п' v azbuke
	'1088'	=> "r", # 'р' v azbuke
	'1089'	=> "s", # 'с' v azbuke
	'1090'	=> "t", # 'т' v azbuke
	'1091'	=> "u", # 'у' v azbuke
	'1092'	=> "f", # 'ф' v azbuke
	'1093'	=> "h", # 'х' v azbuke
	'1094'	=> "c", # 'ц' v azbuke
	'1095'	=> "ch", # 'ч' v azbuke
	'1096'	=> "sh", # 'ш' v azbuke
	'1097'	=> "sth", # 'Щ' v azbuke
	'1098'	=> "a", # 'ъ' v azbuke
	
	'1099'	=> "y", # 'ы' v azbuke
	
	'1103'	=> "ya", # 'я' v azbuke	
	
	'1108'	=> "e", # 'є' v azbuke
	
	'1100'	=> "y", # 'ь' v azbuke
	
	'1102'	=> "yu", # 'ю' v azbuke
	
	'1110'	=> "i", # 'і' v azbuke
	'1111'	=> "i", # 'ї' v azbuke
	
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
	
	'8364' => "(EUR)", # euro
	
	'8482' =>	"(tm)", # 'tm' trademark
	
	# Pashto
	'1569' => "hamza",
	'1570' => " ^a", # آ
	
	'1574' => "yh",
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
	
	'1592' => "zah",
	'1593' => "ain",
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
	'1610' => "yeh",
	
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
	
	'8209' => "-", # NON-BREAKING HYPHEN
	
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
	return $table{ord($_[0])} if exists $table{ord($_[0])};
	
#	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require) = caller(1);
	main::_log("Int::charsets::encode::* ASCII from UTF-8 \\$_[0] {".(ord($_[0]))."} - unknown",1,"lib.err",1) if (ord($_[0])>127);
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

sub UTF8_ASCII_lite
{
	my $text=shift;
	# enable utf8 flag unless enabled
	# only utf8 string can be converted
	utf8::decode($text) unless utf8::is_utf8($text);
	
	$text=~tr/áéíóúôäýžčšťľďňČŽ/aeiouoayzcstldnCZ/;
	
	return $text;
}

1;
