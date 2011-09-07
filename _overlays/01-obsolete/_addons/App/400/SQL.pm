#!/bin/perl
package App::400::SQL;
use	App::400::SQL::a400;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

# HLADANIE BUGOV
# - ako prve porozmyslaj ci je bug skutecne bugom a nie "vlastnost"
# - v maximalnej miere OKAMZITE zastav a minimalizuj straty sposobovane bugom
# - najprv hladaj VZDY v LOGu! na to je urceny.
# - debuguj, hladaj chybu v kode a pridavaj hlasky do logu
# - ak je chyba v syntaxi a nemozes ju najst viac ako 5 minut, commentom vypinaj 
#   cele casti kodu tak aby nedoslo k neziaducemu spravaniu a systemom 
#   pokus/omyl najdes chybny kod
# - UPRAC PO SEBE!!!
#

# VIRTUAL FCIONS
#
# tu definujem fcie ktore budu potom neskor bezne volane ako App::400->get_article
# to zabezpeci dedenie z App::400::SQL do App::400
# v podstate som tu schopny vytvorit lubovolne virtualne fcie ktore v skutocnosti
# neexistuju
#
sub get_article{shift; return App::400::SQL::a400::get::new("App::400::SQL::a400::get",@_);}

sub get_article_lastID{shift; return App::400::SQL::a400::get::new("App::400::SQL::a400::get",@_,
	# zamenim existujuce za premenne vhodne podla mojho uvazenia aby sa nenarusil
	# vyznam tejto abstrakcie oproti klasickemu get
	select_order		=>	"ID DESC",
	select_arch		=>	0,
	select_arch_allow	=>	0,
	select_union		=>	0,
	select_union_allow	=>	1,
	link_disable		=>	1,
);}

#
# chcel by som tu este:
# - fciu pre davkove nacitanie a spracovanie (neviem presne ako by toto bolo mozne :)
#




=head1
sub get_article_lastinserted{shift; return App::400::SQL::a400::get("App::400::SQL::a400",@_,
	select_order		=>	"inserttime DESC",
	select_arch		=>	0,
	select_arch_allow	=>	1,
	select_union		=>	0,
	select_union_allow	=>	0,
	link_disable		=>	1,
);}

sub get_article_lastchanged{shift; return App::400::SQL::a400::get("App::400::SQL::a400",@_,
	select_order		=>	"changetime DESC",
	select_arch		=>	0,
	select_arch_allow	=>	1,
	select_union		=>	0,
	select_union_allow	=>	0,
	link_disable		=>	1,
);}
=cut

1;
