#!/bin/perl
package App::400::SQL::a400::get;
use App::400::SQL::a400; # potrebujem pre spetnu vezbu na @PRIMARY, etc...
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use App::0::SQL::select; # pre dedenie vyrazov na select
our @ISA=("App::0::SQL::select"); # dedim z neho


sub new
{
 my $class=shift;
 my $self={};
 my %env=@_;
  
=head1
 foreach (keys %env)
 {
 	main::_log("new key $_ $env{$_}");
 }
=cut
  
 if (ref($class)) # COPY OBJECT
 {
  # copying
  # %{$self}=%{$class};
  return undef;
 }
 else
 {
  # NEW CONSTRUCTOR
#  %{$self->{ENV}}=%env;
  return undef unless $self=$class->_new(%env);
 }
 
 @{$self->{PRIMARY}}=@App::400::SQL::a400::PRIMARY;
 @{$self->{REQUIRED}}=@App::400::SQL::a400::REQUIRED;
  
 return bless $self,$class;
}


sub prepare
{
 my $self=shift;
  
 undef $self->{s_left};
 undef $self->{s_left_a};
 undef $self->{s_where};
 undef $self->{s_order};
 undef $self->{s_order};
 undef $self->{s_limit};
 
 $self->_prepare(); #inicializacia prepare;
 
 # povolenie pre arch a union mozem dat iba tu!
 # je to kvoli tomu, lebo inicializator v App::0::query nevie
 # ktora aplikacia ma vobec archiv a ktora nema
 $self->{select_arch}=$self->{ENV}{select_arch}
	or $self->{select_arch_allow}=$self->{ENV}{select_arch_allow}
	or $self->{select_union_allow}=$self->{ENV}{select_union_allow}
	or $self->{select_union}=$self->{ENV}{select_union};
 
 if ($self->{ENV}{a400_category})
 {
  # WHERE - lng
  $self->{s_category_where}.=" AND (a400_category.lng='' OR a400_category.lng='$self->{ENV}{a400_category}{lng}')\n"
  	if $self->{ENV}{a400_category}{lng};
  # WHERE - active
  $self->{s_category_where}.=" AND a400_category.active='Y'\n" if $self->{ENV}{a400_category}{active};
 
  # SAMOTNY JOIN
  $self->{s_left}="LEFT JOIN ".$self->{db}.".a400_category AS a400_category ON\n";
  $self->{s_left}.="(\n";
  $self->{s_left}.=" a400.IDcategory = a400_category.ID\n";
  $self->{s_left}.=$self->{s_category_where}.")\n";  
  
  $self->{s_where}.="\tAND a400_category.ID<>''\n" if $self->{ENV}{a400_category_};
 }
	
	
	if ($self->{'ENV'}{'a120'})
	{
		# JOIN
		main::_log("LEFT JOIN a120");
		$self->{s_left}.=qq{
			LEFT JOIN $self->{db}.a120 AS a120_editor ON
			(
				a400.IDeditor = a120_editor.ID
				AND a120_editor.IDtype=1
			)
			LEFT JOIN $self->{db}.a120 AS a120_author ON
			(
				a400.IDauthor = a120_author.ID
				AND a120_author.IDtype=0
			)
		};
		
		$self->{ENV}{select}.=";a120_editor.ID AS a120_editor_ID";
		$self->{ENV}{select}.=";a120_editor.fullname AS a120_editor_fullname";
		$self->{ENV}{select}.=";a120_editor.nickname AS a120_editor_nickname";
		
		$self->{ENV}{select}.=";a120_author.ID AS a120_author_ID";
		$self->{ENV}{select}.=";a120_author.fullname AS a120_author_fullname";
		$self->{ENV}{select}.=";a120_author.nickname AS a120_author_nickname";
		
	}
	
	
 if ($self->{ENV}{a400_attrs})
 {   
  $self->{s_left_o}.="LEFT JOIN ".$self->{db}.".a400_attrs AS a400_attrs ON \n(\n a400.IDattrs IS NOT NULL\n AND a400_attrs.IDattrs = a400.IDattrs\n)\n";  
  $self->{s_left_a}.="LEFT JOIN ".$self->{db}.".a400_attrs_arch AS a400_attrs ON \n(\n a400.IDattrs IS NOT NULL\n AND a400_attrs.IDattrs = a400.IDattrs\n)\n";  
  $self->{s_where}.="\tAND a400_attrs.IDattrs<>''\n" if $self->{ENV}{a400_attrs_};
 }
 
 # WHERE
 $self->{s_where}.="\tAND \n\t(\n\t ".$self->{ENV}{select_where}."\n\t)\n" if $self->{ENV}{select_where};
 # WHERE-ID
 foreach (split (';',$self->{ENV}{a400}{ID})){next unless $_;$self->{s_where_ID}.="\t OR a400.ID='$_'\n";}
 $self->{s_where_ID}=~s|^\t OR |\t | if $self->{ENV}{a400}{ID};
 $self->{s_where}.="\tAND \n\t(\n".$self->{s_where_ID}."\t)\n" if $self->{s_where_ID};
 delete $self->{s_where_ID};
 # WHERE - ID_exclude
 foreach (split (';',$self->{ENV}{a400}{ID_exclude})){next unless $_;
 $self->{s_where}.="\tAND a400.ID<>'".$_."'\n";}   
 # WHERE - link_exclude
 foreach (split (';',$self->{ENV}{a400}{link_exclude})){next unless $_;
 $self->{s_where}.="\tAND a400.link<>'".$_."'\n";}     
 # WHERE - IDcategory
 foreach (split (';',$self->{ENV}{a400}{IDcategory})){next unless $_;  
 $self->{s_where_IDcategory}.="\t OR a400.IDcategory".do{($_=~/%$/)?" LIKE ":"="}."'$_'\n";}
 $self->{s_where_IDcategory}=~s|^\t OR |\t | if $self->{ENV}{a400}{IDcategory};
 $self->{s_where}.="\tAND \n\t(\n".$self->{s_where_IDcategory}."\t)\n" if $self->{s_where_IDcategory};
 delete $self->{s_where_IDcategory};
 # WHERE - IDcategory_exclude
 foreach (split (';',$self->{ENV}{a400}{IDcategory_exclude})){next unless $_;
 $self->{s_where}.="\tAND a400.IDcategory".do{($_=~/%$/)?" NOT LIKE ":"!="}."'$_'\n";}  
 # WHERE - link-disable
 $self->{s_where}.="\tAND a400.link='0'\n" if $self->{ENV}{link_disable};
 # WHERE - lng
 $self->{s_where}.="\tAND (a400.lng='' OR a400.lng='$self->{ENV}{a400}{lng}')\n" if $self->{ENV}{a400}{lng};
 # WHERE - starttime
 $self->{s_where}.=do{
 ($self->{ENV}{a400}{starttime}) ? "\tAND a400.starttime<=$self->{ENV}{a400}{starttime}\n":
 (exists $self->{ENV}{a400}{starttime}) ? "\tAND a400.starttime<=$main::time_current\n":""}; 
 # WHERE - endtime
 $self->{s_where}.="\tAND (a400.endtime=0 OR a400.endtime>=$main::time_current)\n" if $self->{ENV}{a400}{endtime};
 # WHERE - active
 $self->{s_where}.="\tAND a400.active='Y'\n" if $self->{ENV}{a400}{active}; 
 # WHERE END
 $self->{s_where}=~s|^\tAND |\n\t|;
 $self->{s_where}=~s|^\n\t\n|\n|;
 $self->{s_where}=~s|\n$||s;
 $self->{s_where}="WHERE ".$self->{s_where}."\n" if $self->{s_where};
    
 # ORDER
 $self->{s_order}=$self->{ENV}{select_order};
 $self->{s_order}="a400.starttime DESC" unless $self->{s_order}; 
 $self->{s_order}="ORDER BY ".$self->{s_order}."\n";
 
 # ORDER arch
 $self->{s_order_arch}=$self->{s_order};
 $self->{s_order_arch}=~s|([a-zA-Z0-9_]+)\.|$1_arch.|g;
 $self->{s_order_arch}=~s|a400_category_arch\.|a400_category.|g;

 # SELECT [WHAT?]
 #$self->s_what_collect(@App::400::SQL::a400::PRIMARY,@App::400::SQL::a400::REQUIRED,split(',|;',$env{select}));
# $self->s_what_collect(@App::400::SQL::a400::PRIMARY,@App::400::SQL::a400::REQUIRED,split(',|;',$self->{ENV}{select}));
#=head1
 $self->s_what_collect(
 	@App::400::SQL::a400::PRIMARY,
	@App::400::SQL::a400::REQUIRED,
	App::0::SQL::functions::normalize_select($self->{ENV}{select}));
#=cut
 $self->{s_what}="a400.ID" unless $self->{s_what};   
 
# QUERY
$self->{Query}="
SELECT $self->{s_what}
FROM ".$self->{db}.".a400 AS a400
$self->{s_left}$self->{s_left_o}$self->{s_where}$self->{s_order}$self->{s_limit}";

$self->{Query_orig}="
SELECT $self->{s_what}
FROM ".$self->{db}.".a400 AS a400
$self->{s_left}$self->{s_left_o}$self->{s_where}$self->{s_order}$self->{s_limit}";

$self->{Query_arch}="
SELECT $self->{s_what}
FROM ".$self->{db}.".a400_arch AS a400
$self->{s_left}$self->{s_left_a}$self->{s_where}$self->{s_order_arch}"; 

$self->{Query_union}="
(
SELECT $self->{s_what}
FROM ".$self->{db}.".a400 AS a400
$self->{s_left}$self->{s_left_o}$self->{s_where})
UNION ALL
(
SELECT $self->{s_what}
FROM ".$self->{db}.".a400_arch AS a400
$self->{s_left}$self->{s_left_a}$self->{s_where})
$self->{s_order}$self->{s_limit}"; 
  
 return 1;
# return $self->execute();
}






sub subquery_initialize
{
 my $self=shift; 
=head1
 main::_log("initialize subquery db:$self->{db} DBH:$self->{DBH}");
 foreach (keys %{$self->{env}})
 {
 	main::_log("init env key $_ ".$self->{env}{$_});
 }
 foreach (keys %{$self->{ENV}})
 {
 	main::_log("init ENV key $_ ".$self->{ENV}{$_});
 }
=cut
 return undef unless $self;
 if ($self->{_subquery}=App::400::SQL::a400::get->new(
#		%{$self->{env}},
		%{$self->{ENV}},
#		db	=>	$self->{db},
#		DBH	=>	$self->{DBH},	
		# a teraz zrusim nastavenia ktore su mi posielane...
		select			=>	"COUNT(ID) AS COUNT_ORIGIN",
		select_limit		=>	$self->{limit_from},
		select_arch		=>	0,
		select_arch_allow	=>	0,
		select_union		=>	0,
		))
 {
 }
 else
 {
  return undef;
 }
 return 1;
}


# toto sa mi vobec nepaci, nieje to sice taky strasny hack, ale
# pisat toto do kazdeho jedneho API, tak asi ma jebne :)
# chce to nejako aspon ciastocne globalizovat
#
sub get_link
{
 my $self=shift; 
 die "object not defined" unless $self;
 my %env=@_;
 my %nieco;
  
 my %hash=
 (
	db	=>	$self->{db},
	DBH	=>	$self->{DBH},	
	select		=>	$self->{env}{select},		# ziskavam z linky take iste data ako v originali
										# a pisem to skor ako kopy env{link} aby mal sancu env{link} to prepisat
	%{$self->{env}{link}},		
	select_limit		=>	"1",	# mam zaujem LEN o jediny original :) a nedovolim envlinku to prepisat a upravit. v ziadnom pripade!!!!
#	select_union		=>	0,	# do tohoto si tiez nenecham babrat!
#	select_arch		=>	0,	# do tohoto si tiez nenecham babrat!
#	select_arch_allow	=>	0,	# do tohoto si tiez nenecham babrat!
	link	=>	{
			%{$self->{env}{link}}, # odovzdavam podmienky pre a400 dalsiemu linku, ked bude hladat nahodou link
			},
 );

 # dodatocne upravy vo vnorenych castiach
 $hash{a400}{ID}=$env{link};
 $hash{a400}{link_exclude}=$self->{env}{a400}{link_exclude}.";".$env{exclude}; # nechcem hladat link v nekonecnom kolotoci, ze?
 
 
 my $query=App::400::SQL::a400::get->new(%hash);   
 if (($query->execute())&&(%nieco=$query->fetchhash())){$self->{Query_log}.=$query->{Query_log}."\n\n";} 
 return %nieco;
}



#
# App::400::SQL::a400::update::new(
# by mal v podstate  volat App::400::SQL::a400::get::new( a nad nim $obj->update
#
# neviem ako ale riesit hromadne update
#
# nie, update element po elemente je neunosne a tak radsej sa spravi neskor
# previazanie z $obj->update na App::400::SQL::a400::update::new(
# alebo rovno na nadtriedu App::0::SQL::update(
#
sub update # vytvori novy objekt bez dedenia
{
 my $class=shift;
 my $self={};
 
# %{$self}=%{$class}; # duplikacia
# $self=$class; # clone
 
 die "object not defined" unless $class; 
 die "object not defined" unless $class->{db};  
 die "no data input" unless $_[0];
 
 #foreach (keys %{$self}){print "$_\n";}
# print "$self $class\n";
  
$self->{Query_update}="
UPDATE ".$class->{db}.".a400 AS a400
SET $_[0]
WHERE ".$class->generate_primarywhere()."
LIMIT 1";
  
 $class->{Query_log}.=$self->{Query_update}."\n";

 die "cannot execute SQL query" unless $self->{return}=$class->_execute($self->{Query_update});
  
 return bless $self;
}




=head1
sub new
{
 my $class=shift;
 my $self={};
 my %env=@_;
  
 if (ref($class)) # COPY OBJECT
 {
  # copying
  %{$self}=%{$class};
  return undef;
 }
 else
 {
  # NEW ALLOCATION
  return undef unless $self=$class->allocate(%env);
 }
 
 @{$self->{PRIMARY}}=@App::400::SQL::a400::PRIMARY;
 @{$self->{REQUIRED}}=@App::400::SQL::a400::REQUIRED;

 # povolenie pre arch a union mozem dat iba tu!
 # je to kvoli tomu, lebo inicializator v App::0::query nevie
 # ktora aplikacia ma vobec archiv a ktora nema
 $self->{select_arch}=$env{select_arch} 
 	or $self->{select_arch_allow}=$env{select_arch_allow} 
	or $self->{select_union_allow}=$env{select_union_allow}
	or $self->{select_union}=$env{select_union};
 
 if ($env{a400_category})
 {
  # WHERE - lng
  $self->{s_category_where}.=" AND (a400_category.lng='' OR a400_category.lng='$env{a400_category}{lng}')\n"
  	if $env{a400_category}{lng};
  # WHERE - active
  $self->{s_category_where}.=" AND a400_category.active='Y'\n" if $env{a400_category}{active};
 
  # SAMOTNY JOIN
  $self->{s_left}="LEFT JOIN ".$self->{db}.".a400_category AS a400_category ON\n";
  $self->{s_left}.="(\n";
  $self->{s_left}.=" a400.IDcategory = a400_category.ID\n";
  $self->{s_left}.=$self->{s_category_where}.")\n";  
  
  $self->{s_where}.="\tAND a400_category.ID<>''\n" if $env{a400_category_};
 }
 
 if ($env{a400_attrs})
 {   
  $self->{s_left_o}.="LEFT JOIN ".$self->{db}.".a400_attrs AS a400_attrs ON \n(\n a400.IDattrs IS NOT NULL\n AND a400_attrs.IDattrs = a400.IDattrs\n)\n";  
  $self->{s_left_a}.="LEFT JOIN ".$self->{db}.".a400_attrs_arch AS a400_attrs ON \n(\n a400.IDattrs IS NOT NULL\n AND a400_attrs.IDattrs = a400.IDattrs\n)\n";  
  $self->{s_where}.="\tAND a400_attrs.IDattrs<>''\n" if $env{a400_attrs_};
 }
 

 # WHERE
 $self->{s_where}.="\tAND \n\t(\n\t ".$env{select_where}."\n\t)\n" if $env{select_where};
 # WHERE-ID
 foreach (split (';',$env{a400}{ID})){next unless $_;$self->{s_where_ID}.="\t OR a400.ID='$_'\n";}
 $self->{s_where_ID}=~s|^\t OR |\t | if $env{a400}{ID};
 $self->{s_where}.="\tAND \n\t(\n".$self->{s_where_ID}."\t)\n" if $self->{s_where_ID};
 delete $self->{s_where_ID};
 # WHERE - ID_exclude
 foreach (split (';',$env{a400}{ID_exclude})){next unless $_;
 $self->{s_where}.="\tAND a400.ID<>'".$_."'\n";}   
 # WHERE - link_exclude
 foreach (split (';',$env{a400}{link_exclude})){next unless $_;
 $self->{s_where}.="\tAND a400.link<>'".$_."'\n";}     
 # WHERE - IDcategory
 foreach (split (';',$env{a400}{IDcategory})){next unless $_;  
 $self->{s_where_IDcategory}.="\t OR a400.IDcategory".do{($_=~/%$/)?" LIKE ":"="}."'$_'\n";}
 $self->{s_where_IDcategory}=~s|^\t OR |\t | if $env{a400}{IDcategory};
 $self->{s_where}.="\tAND \n\t(\n".$self->{s_where_IDcategory}."\t)\n" if $self->{s_where_IDcategory};
 delete $self->{s_where_IDcategory};
 # WHERE - IDcategory_exclude
 foreach (split (';',$env{a400}{IDcategory_exclude})){next unless $_;
 $self->{s_where}.="\tAND a400.IDcategory".do{($_=~/%$/)?" NOT LIKE ":"!="}."'$_'\n";}  
 # WHERE - link-disable
 $self->{s_where}.="\tAND a400.link='0'\n" if $env{link_disable};
 # WHERE - lng
 $self->{s_where}.="\tAND (a400.lng='' OR a400.lng='$env{a400}{lng}')\n" if $env{a400}{lng};
 # WHERE - starttime
 $self->{s_where}.=do{
 ($env{a400}{starttime}) ? "\tAND a400.starttime<=$env{a400}{starttime}\n":
 (exists $env{a400}{starttime}) ? "\tAND a400.starttime<=$main::time_current\n":""}; 
 # WHERE - endtime
 $self->{s_where}.="\tAND (a400.endtime=0 OR a400.endtime>=$main::time_current)\n" if exists $env{a400}{endtime};
 # WHERE - active
 $self->{s_where}.="\tAND a400.active='Y'\n" if $env{a400}{active}; 
 # WHERE END
 $self->{s_where}=~s|^\tAND |\n\t|;
 $self->{s_where}=~s|^\n\t\n|\n|;
 $self->{s_where}=~s|\n$||s;
 $self->{s_where}="WHERE ".$self->{s_where}."\n" if $self->{s_where};
    
 # ORDER
 $self->{s_order}=$env{select_order};
 $self->{s_order}="a400.starttime DESC" unless $self->{s_order}; 
 $self->{s_order}="ORDER BY ".$self->{s_order}."\n";

 # SELECT [WHAT?]
 #$self->s_what_collect(@App::400::SQL::a400::PRIMARY,@App::400::SQL::a400::REQUIRED,split(',|;',$env{select}));
 $self->s_what_collect(@App::400::SQL::a400::PRIMARY,@App::400::SQL::a400::REQUIRED,split(',|;',$env{select}));
 $self->{s_what}="a400.ID" unless $self->{s_what};   
 
# QUERY
$self->{Query}="
SELECT $self->{s_what}
FROM ".$self->{db}.".a400 AS a400
$self->{s_left}$self->{s_left_o}$self->{s_where}$self->{s_order}$self->{s_limit}";

$self->{Query_orig}="
SELECT $self->{s_what}
FROM ".$self->{db}.".a400 AS a400
$self->{s_left}$self->{s_left_o}$self->{s_where}$self->{s_order}$self->{s_limit}";

$self->{Query_arch}="
SELECT $self->{s_what}
FROM ".$self->{db}.".a400_arch AS a400
$self->{s_left}$self->{s_left_a}$self->{s_where}$self->{s_order}"; 

$self->{Query_union}="
(
SELECT $self->{s_what}
FROM ".$self->{db}.".a400 AS a400
$self->{s_left}$self->{s_left_o}$self->{s_where}$self->{s_order})
UNION ALL
(
SELECT $self->{s_what}
FROM ".$self->{db}.".a400_arch AS a400
$self->{s_left}$self->{s_left_a}$self->{s_where}$self->{s_order})
$self->{s_order}$self->{s_limit}"; 
   
 return bless $self,$class;
}



sub copy
{
 my $class=shift;
 my $self={};
 my %env=@_;
  
 if (ref($class)) # COPY OBJECT
 {
  %{$self}=%{$class};
 }
 else
 {
  return undef
 }
 return bless $self; 
}




#=head1
sub subquery_initialize
{
 my $self=shift; 
 return undef unless $self;
 if ($self->{_subquery}=App::400::SQL::a400::get->new(
		%{$self->{env}},
		select			=>	"COUNT(ID) AS COUNT_ORIGIN",
		select_limit		=>	$self->{limit_from},
		select_arch		=>	0,
		select_arch_allow	=>	0,
		select_union		=>	0,
		))
 {
 }
 else
 {
  return undef;
 }
 return 1;
}


# toto sa mi vobec nepaci, nieje to sice taky strasny hack, ale
# pisat toto do kazdeho jedneho API, tak asi ma jebne :)
# chce to nejako aspon ciastocne globalizovat
#
sub get_link
{
 my $self=shift; 
 die "object not defined" unless $self;
 my %env=@_;
 my %nieco;
  
 my %hash=
 (
	db	=>	$self->{db},
	DBH	=>	$self->{DBH},	
	select		=>	$self->{env}{select},		# ziskavam z linky take iste data ako v originali
										# a pisem to skor ako kopy env{link} aby mal sancu env{link} to prepisat
	%{$self->{env}{link}},		
	select_limit		=>	"1",	# mam zaujem LEN o jediny original :) a nedovolim envlinku to prepisat a upravit. v ziadnom pripade!!!!
#	select_union		=>	0,	# do tohoto si tiez nenecham babrat!
#	select_arch		=>	0,	# do tohoto si tiez nenecham babrat!
#	select_arch_allow	=>	0,	# do tohoto si tiez nenecham babrat!
	link	=>	{
			%{$self->{env}{link}}, # odovzdavam podmienky pre a400 dalsiemu linku, ked bude hladat nahodou link
			},
 );

 # dodatocne upravy vo vnorenych castiach
 $hash{a400}{ID}=$env{link};
 $hash{a400}{link_exclude}=$self->{env}{a400}{link_exclude}.";".$env{exclude}; # nechcem hladat link v nekonecnom kolotoci, ze?
 
 
 my $query=App::400::SQL::a400::get->new(%hash);   
 if (($query->execute())&&(%nieco=$query->fetchhash())){$self->{Query_log}.=$query->{Query_log}."\n\n";} 
 return %nieco;
}



#
# App::400::SQL::a400::update::new(
# by mal v podstate  volat App::400::SQL::a400::get::new( a nad nim $obj->update
#
# neviem ako ale riesit hromadne update
#
# nie, update element po elemente je neunosne a tak radsej sa spravi neskor
# previazanie z $obj->update na App::400::SQL::a400::update::new(
# alebo rovno na nadtriedu App::0::SQL::update(
#
sub update # vytvori novy objekt bez dedenia
{
 my $class=shift;
 my $self={};
 
# %{$self}=%{$class}; # duplikacia
# $self=$class; # clone
 
 die "object not defined" unless $class; 
 die "object not defined" unless $class->{db};  
 die "no data input" unless $_[0];
 
 #foreach (keys %{$self}){print "$_\n";}
 print "$self $class\n";
  
$self->{Query_update}="
UPDATE ".$class->{db}.".a400 AS a400
SET $_[0]
WHERE ".$class->generate_primarywhere()."
LIMIT 1";
  
 $class->{Query_log}.=$self->{Query_update}."\n";

 die "cannot execute SQL query" unless $self->{return}=$class->_execute($self->{Query_update});
  
 return bless $self;
}

=cut


1;
