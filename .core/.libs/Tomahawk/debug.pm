#!/usr/bin/perl
package Tomahawk::debug;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


sub module_load
{
	return 1;
	# ZRUSENE: odteraz robim iba analyzu tych modulov ktore potrebuju aj optimalizaciu
	
	# informaciu o tom aky modul kolko trva zapisujem do logu iba vtedy
	# ak ten modul ma cache a ten cache je v stave debuggingu, take informacie
	# o vyuziti cache sa zapisuju do suboru a za nejaky cas pride optimalizacia
	# samozrejme na zaklade dat ktore zapisuje debugger cache.
	
	# DOCASNE VYPNUTE, POTREBUJEME STATISTIKY MODULOV!
=head1
	# zaznamenavaj len vtedy ak je zapnuty CACHE
	return undef unless $TOM::DEBUG_cache; # TOTO JE BLBOST, NIEEE? :-O
	# zaznamenavaj len vtedy ak tento modul pozna CACHE
	return undef unless exists $Tomahawk::CACHE{$Tomahawk::mdl_C{T_CACHE}};
	# pokracuj ak starie posledneho casu optimalizacie je vacsie ako pozadovane starie v configu
	return undef if (($main::time_current-$Tomahawk::CACHE{$Tomahawk::mdl_C{T_CACHE}}{-opt_time})<$TOM::DEBUG_cache_old);
=cut
	
	my %env=@_;

	open HND_mdllog, ">>$TOM::P/_logs/mdllog/mdllog.$tom::Fyear-$tom::Fmom-$tom::Fmday.$tom::Fhour.$tom::Fmin.".$$.".log";
	print HND_mdllog <<"HEAD";
<request>
 <reqtime>$main::time_current</reqtime>
 <reqdatetime>$tom::Fyear-$tom::Fmom-$tom::Fmday $tom::Fhour:$tom::Fmin:$tom::Fsec</reqdatetime>
 <domain>$tom::Hm</domain>
 <domain_sub>$tom::H</domain_sub>
 <Ctype>$env{-type}</Ctype>
 <Capp>$env{-category}</Capp>
 <Cmodule>$env{-name}</Cmodule>
 <load_proc>$env{-load_proc}</load_proc>
 <load_req>$env{-load_req}</load_req>
</request>
HEAD
	close (HND_mdllog);
 
}



sub cache_conf_opt
{
=head1
 return undef;

# return undef if $TOM::CACHE==2;
 
 # TOTO BY V PRIPADE DATABASE CACHE NEMAL PRECO ROBIT
 # SAMOTNY PORTAL A NEVIEMPRECO SA TYM ZDRZOVAT, ZE ANO?
 # LEBO TO ROBI UZ SAM CRON
=cut
return 1}




sub cache_conf_opt_plus
{
	#return 1;
	# zapisujem debug data o cache len v pripade ze je optimalizacia velmi davno
	
	#return undef unless $TOM::DEBUG_cache;
	#return undef if (($tom::time_current-$Tomahawk::CACHE{$Tomahawk::mdl_C{T_CACHE}}{-opt_time})<$TOM::DEBUG_cache_old);
	
#	main::_log("cache_conf_opt_plus ID='$Tomahawk::mdl_C{N_IDcache}'");
	
#=head1
	$main::DB{sys}->Query("
		UPDATE TOM.a150_cache
		SET loads=loads+1
		WHERE ID='$Tomahawk::mdl_C{N_IDcache}'
		LIMIT 1");
#=cut
		
return 1}












# MUSIM PRIDAT POCITANIE CASU, PAMATE, A INYCH SYS.PROSTRIEDKOV












1;
