package Utils::datetime;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use vars qw/
	@ISA
	@EXPORT
	%DAYS
	%DAYS_L
	%MONTHS
	%MONTHS_L
	/;
use Exporter;
@ISA=qw/Exporter/;
@EXPORT=qw/
	%DAYS
	%DAYS_L
	%MONTHS
	%MONTHS_L
	/;

	
	
	
=head1
aa 	Afar 	ab 	Abkhazian
af 	Afrikaans 	am 	Amharic
ar 	Arabic 	as 	Assamese
ay 	Aymara 	az 	Azerbaijani
ba 	Bashkir 	be 	Byelorussian
bg 	Bulgarian 	bh 	Bihari
bi 	Bislama 	bn 	Bengali; Bangla        
bo 	Tibetan 	br 	Breton
ca 	Catalan 	co 	Corsican
cs 	Czech 	cy 	Welsh
da 	Danish 	de 	German
dz 	Bhutani 	el 	Greek
en 	English 	eo 	Esperanto
es 	Spanish 	et 	Estonian
eu 	Basque 	fa 	Persian
fi 	Finnish 	fj 	Fiji
fo 	Faeroese 	fr 	French
fy 	Frisian 	ga 	Irish
gd 	Scots, Gaelic 	gl 	Galician
gn 	Guarani 	gu 	Gujarati
he 	Hebrew 	ha 	Hausa
hi 	Hindi 	hr 	Croatian
hu 	Hungarian 	hy 	Armenian
ia 	Interlingua 	id 	Indonesian
ie 	Interlingue 	ik 	Inupiak
in 	Indonesian 	is 	Icelandic
it 	Italian 	iu 	Inuktitut
iw 	Hebrew (obsolete)     	ja 	Japanese
ji 	Yiddish (obsolete)     	jw 	Javanese
ka 	Georgian 	kk 	Kazakh
kl 	Greenlandic 	km 	Cambodian
kn 	Kannada 	ko 	Korean
ks 	Kashmiri 	ku 	Kurdish
ky 	Kirghiz 	la 	Latin
ln 	Lingala 	lo 	Laothian
lt 	Lithuanian 	lv 	Latvian, Lettish
mg 	Malagasy 	mi 	Maori
mk 	Macedonian 	ml 	Malayalam
mn 	Mongolian 	mo 	Moldavian
mr 	Marathi 	ms 	Malay
mt 	Maltese 	my 	Burmese
na 	Nauru 	ne 	Nepali
nl 	Dutch 	no 	Norwegian
oc 	Occitan 	om 	(Afan), Oromo
or 	Oriya 	pa 	Punjabi
pl 	Polish 	ps 	Pashto, Pushto
pt 	Portuguese 	qu 	Quechua
rm 	Rhaeto-Romance 	rn 	Kirundi
ro 	Romanian 	ru 	Russian
rw 	Kinyarwanda 	sa 	Sanskrit
sd 	Sindhi 	sg 	Sangro
sh 	Serbo-Croatian 	si 	Singhalese
sk 	Slovak 	sl 	Slovenian
sm 	Samoan 	sn 	Shona
so 	Somali 	sq 	Albanian
sr 	Serbian 	ss 	Siswati
st 	Sesotho 	su 	Sundanese
sv 	Swedish 	sw 	Swahili
ta 	Tamil 	te 	Tegulu
tg 	Tajik 	th 	Thai
ti 	Tigrinya 	tk 	Turkmen
tl 	Tagalog 	tn 	Setswana
to 	Tonga 	tr 	Turkish
ts 	Tsonga 	tt 	Tatar
tw 	Twi 	ug 	Uigur
uk 	Ukrainian 	ur 	Urdu
uz 	Uzbek 	vi 	Vietnamese
vo 	Volapuk 	wo 	Wolof
xh 	Xhosa 	y 	Yiddish
yo 	Yoruba 	za 	Zuang
zh 	Chinese 	zu 	Zulu
=cut
	
	
	

# http://www.domesticat.net/misc/monthsdays.php
# http://users.telenet.be/geert.geerits/dBASE/Translations.htm
# http://www.virtualtuner.com/iso639.php

%DAYS=
(
	en	=>	["Sun","Mon","Tue","Wed","Thu","Fri","Sat","Sun"],
	sk	=>	["Ned","Pon","Ut","Str","Štv","Pia","So","Ned"],
	cs	=>	["Ned","Pon","Ut","Str","Ctv","Pát","Sob","Ned"],
	la	=>	["Sol","Lun","Mar","Mer","Jov","Ven","Sat","Sol"],
);

%DAYS_L=
(
	'af'	=>	["Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrydag", "Saterdag", "Sondag"],
	'am'	=>	["ሰኞ", "ማክሰኞ", "ረቡዕ", "ሐሙስ", "ዓርብ", "ቅዳሜ", "እሑድ"],
	'bg'	=>	["понеделник", "вторник", "сряда", "четвъртък", "петък", "събота", "неделя"],
	'br'	=>	["Dilun", "Dimeurzh", "Dimerc'her", "Diriaou", "Digwener", "Disadorn", "Disul"],
	'cs'	=>	["pondělí","úterý","středa","čtvrtek","pátek","sobota","neděle"],
	'de'	=>	["Montag",	"Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"],
	'en'	=>	["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],
	'eu'	=>	["astelehena", "asteartea", "asteazkena", "osteguna", "ostirala", "larunbata", "igandea"],
	'hu'	=>	["hétfő", "kedd", "szerda", "csütörtök", "péntek", "szombat", "vasárnap"],
	'hy'	=>	["Երկուշաբթի", "Երկուշաբթի", "Երեքշաբթի", "Չորեքշաբթի", "Հինգշաբթի", "Ուրբաթ", "Շաբաթ"],
	'ja'	=>	["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"],
	'ko'	=>	["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"],
	'pl'	=>	["poniedziałek", "wtorek", "środa", "czwartek", "piątek", "sobota", "niedziela"],
	'ru'	=>	["понедельник", "вторник", "среда", "четверг", "пятница", "суббота", "воскресенье"],
	'sk'	=>	["pondelok","utorok","streda","štvrtok","piatok","sobota","nedeľa"],
	'sq'	=>	["e hënë", "e martë", "e mërkurë", "e enjte", "e premte", "e shtunë", "e diel"],
	'th'	=>	["วันจันทร์", "วันอังคาร", "วันพุธ", "วันพฦหัสบดี", "วันศุกร์", "วันเสาร์", "วันอาทิตย์"],
	'zh'	=>	["星期日", "星期二", "星期三", "星期四", "星期五",  "星期六", "星期日"],
	'la'	=>	["Lunae dies","Martis dies","Mercurii dies","Jovis dies","Veneris dies","Saturni dies","Solis dies"],
);unshift @{$DAYS_L{$_}},$DAYS_L{$_}[-1] foreach (%DAYS_L);



%MONTHS=
(
	en	=>	["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],
	sk	=>	["Jan","Feb","Mar","Apr","Maj","Jún","Júl","Aug","Sep","Okt","Nov","Dec"],
	la	=>	["Ian","Feb","Mar","Apr","Mai","Iun","Iul","Aug","Sep","Oct","Nov","Dec"],
#	cz	=>	["Led","Ún","Mar","Apr","Maj","Jun","Júl","Aug","Sep","Okt","Nov","Dec"],
);


%MONTHS_L=
(
	'af'	=>	["Januarie", "Februarie", "Maart", "April", "Mei", "Junie", "Julie", "Augustus", "September", "Oktober", "November", "Desember"],
	'ca'	=>	["gener", "febrer", "març", "abril", "maig", "juny", "juliol", "agost", "setembre", "octubre", "novembre", "desembre"],
	'cs'	=>	["leden", "únor", "březen", "duben", "květen", "červen", "červenec", "srpen", "září", "říjen", "listopad", "prosinec"],
	'de'	=>	["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"],
	'el'	=>	["Ιανουάριοs", "Φεβρουάριοs", "Mάρτιος", "Απρίλιος", "Mάιος", "Ιούνιοs", "Ιούλιοs", "Αύγουστος", "Σεπτέμβριοs", "Οκτώβριοs", "Νοέμβριοs", "Δεκέμβριοs"],
	'en'	=>	["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
	'es'	=>	["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"],
	'fr'	=>	["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"],
	'it'	=>	["Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno", "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"],
	'pt'	=>	["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"],	
	'sk'	=>	["január", "február", "marec", "apríl", "máj", "jún", "júl", "august", "september", "október", "november", "december"],
	'la'	=>	["Ianuarius", "Februarius", "Martius", "Aprilis", "Maius", "Iunius", "Iulius", "Augustus", "September", "October", "November", "December"],
);











#our @days_en = ("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
#our @days_sk = ("Ned","Pon","Ut","Str","Štv","Pia","So");

#our @months_en = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
#our @months_sk = ("Jan","Feb","Mar","Apr","Maj","Jun","Júl","Aug","Sep","Okt","Nov","Dec");

sub ctodatetime
{
 my $var=shift @_;
 my %env=@_;
 my %env0;

 (	$env0{sec},
	$env0{min},
	$env0{hour},
	$env0{mday},
	$env0{mom},
	$env0{year},
	$env0{wday},
	$env0{yday},
	$env0{isdst}) = localtime($var);
 # doladenie casu
 $env0{year}+=1900;$env0{mom}++;

 return %env0 unless $env{format};

 (	$env0{sec},
	$env0{min},
	$env0{hour},
	$env0{mday},
	$env0{mom},
	) = (
	sprintf ('%02d', $env0{sec}),
	sprintf ('%02d', $env0{min}),
	sprintf ('%02d', $env0{hour}),
	sprintf ('%02d', $env0{mday}),
	sprintf ('%02d', $env0{mom}),
	);
	
	$env0{mon}=$env0{mom};
	

return %env0}


sub splittime
{
 my $var=shift;
 my %env=(sec=>$var);
 $env{day}=int($env{sec}/86400);$env{sec}-=$env{day}*86400;
 $env{hour}=int($env{sec}/3600);$env{sec}-=$env{hour}*3600;
 $env{min}=int($env{sec}/60);$env{sec}-=$env{min}*60;
 return %env;
}


1;
