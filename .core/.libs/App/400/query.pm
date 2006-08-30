#!/bin/perl
package App::400::query;
use App::0::SQL_old; # abstrakcia
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @ISA=("App::0::SQL_old"); # pytam si abstrakciu

our @PRIMARY=("ID","starttime","active","lng","arch");

sub new
{
 my $class=shift;
 my $self={};
 my %env=@_;
  
 if (ref($class)) # COPY OBJECT
 {
  # copying
 }
 else
 {
  # NEW ALLOCATION
  return undef unless $self=$class->allocate(%env);
 } 

 # povolenie pre union mozem dat iba tu!
 $self->{select_union_allow}=$env{select_union_allow};

 if ($env{a400_category_active})
 {  
  # WHERE - lng
  $self->{s_category_where}.=" AND (a400_category.lng='' OR a400_category.lng='$env{a400_category_lng}')\n" if $env{a400_category_lng};
 
  $self->{s_left}="LEFT JOIN ".$self->{db}.".a400_category AS a400_category ON\n(\n a400.IDcategory = a400_category.ID\n".$self->{s_category_where}.")\n";
  $self->{s_where}.="\tAND a400_category.active='Y'\n";
 }

 # WHERE
 # WHERE - link-disable
 $self->{s_where}.="\tAND a400.link='0'\n" if $env{a400_link_disable};
 # WHERE - lng
 $self->{s_where}.="\tAND (a400.lng='' OR a400.lng='$env{a400_lng}')\n" if $env{a400_lng};
 # WHERE - starttime
 $self->{s_where}.=do{
 ($env{a400_starttime}) ? "\tAND a400.starttime<=$env{a400_starttime}\n":
 (exists $env{a400_starttime}) ? "\tAND a400.starttime<=$main::time_current\n":""}; 
 # WHERE - endtime
 $self->{s_where}.="\tAND (a400.endtime=0 OR a400.endtime>=$main::time_current)\n" if exists $env{a400_endtime};
 # WHERE - active
 $self->{s_where}.="\tAND a400.active='Y'\n" if $env{a400_active}; 
 # WHERE-ID
 foreach (split (';',$env{a400_ID})){next unless $_;$self->{s_where_ID}.="\t OR a400.ID='$_'\n";}
 $self->{s_where_ID}=~s|^\t OR |\t | if $env{a400_ID};
 $self->{s_where}.="\tAND \n\t(\n".$self->{s_where_ID}."\t)\n" if $self->{s_where_ID};
 delete $self->{s_where_ID};
 # WHERE - IDcategory
 foreach (split (';',$env{a400_IDcategory})){next unless $_;  
 $self->{s_where_IDcategory}.="\t OR a400.IDcategory".do{($_=~/%$/)?" LIKE ":"="}."'$_'\n";}
 $self->{s_where_IDcategory}=~s|^\t OR |\t | if $env{a400_IDcategory};
 $self->{s_where}.="\tAND \n\t(\n".$self->{s_where_IDcategory}."\t)\n" if $self->{s_where_IDcategory};
 delete $self->{s_where_IDcategory};
 # WHERE - IDcategory_exclude
 foreach (split (';',$env{a400_IDcategory_exclude})){next unless $_;
 $self->{s_where}.="\tAND a400.IDcategory".do{($_=~/%$/)?" NOT LIKE ":"!="}."'$_'\n";}   
 # WHERE END
 $self->{s_where}=~s|^\tAND |\n\t|s;
 $self->{s_where}=~s|\n$||s;
 $self->{s_where}="WHERE ".$self->{s_where}."\n" if $self->{s_where};
    
 # ORDER
 $self->{s_order}=$env{select_order};
 $self->{s_order}="a400.starttime DESC\n" unless $self->{s_order}; 
 $self->{s_order}="ORDER BY ".$self->{s_order}."\n";

 # SELECT [WHAT?]
 $self->{s_what}=$env{select} if $env{select};
 $self->{s_what}="a400.ID" unless $self->{s_what};   
   
#$self->{Query_count}="
#SELECT COUNT(ID)
#FROM ".$self->{db}.".a400 AS a400
#$self->{s_left}$self->{s_where}LIMIT $self->{limit_from}";

=head1
 # samotny select prejde az vo chvili ked vyselectujem riadky
 # z normalnej tabulky a je ich menej nez pozadujem :)
 if (($self->{select_union_allow})&&($self->{limit_from}))
 {
  $self->{_log}.="je tu allow union, pojdem selectovaaaaaat!\n";
  $self->{_subquery}=App::400::query->new(
		%env,
		select			=>	"COUNT(ID)",
		select_limit		=>	$self->{limit_from},
		select_union_allow	=>	0,
		);
 }
=cut
 
# QUERY
$self->{Query}="
SELECT $self->{s_what}
FROM ".$self->{db}.".a400 AS a400
$self->{s_left}$self->{s_where}$self->{s_order}$self->{s_limit}";

$self->{Query_arch}="
SELECT $self->{s_what}
FROM ".$self->{db}.".a400_arch AS a400
$self->{s_left}$self->{s_where}$self->{s_order}"; 
   
 return bless $self,$class;
}




#=head1
sub subquery_initialize
{
 my $self=shift; 
 $self->{_subquery}=App::400::query->new(
		%{$self->{env}},
		select			=>	"COUNT(ID) AS COUNT_ORIGIN",
		select_limit		=>	$self->{limit_from},
		select_union_allow	=>	0,
		);  
 return 1;
}

