#!/bin/perl
package App::020::a160;

=head1 NAME

App::020::a160

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to generic L<a020|app/"020/">

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::020::_init;
use TOM::Database::SQL;

our $VERSION='$Rev$';
our $DEBUG;
our $db_h='main';

sub get_relation_iteminfo
{
	my $from=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."<-".$from."::get_relation_iteminfo() ");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	my %def=$from->def;
	
	# define db_h
	$env{'db_h'}=$env{'db_h'} || $def{'table'}{$env{'r_table'}}{'db_h'} || $def{'db_h'} || 'main';
	# define column in which is stored row name
	$env{'column'}=$def{'table'}{$env{'r_table'}}{'name_column'} || 'name';
	# define database name
	$env{'r_db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'r_db_name'};
	# define prefix
	$env{'r_prefix'}=$from;$env{'r_prefix'}=~s|::a160||;
	$env{'r_prefix'}=~s|^App::|a|;$env{'r_prefix'}=~s|^Ext::|e|;
	
	main::_log("def db_h='$env{'db_h'}' r_prefix='$env{r_prefix}' r_db_name='$env{'r_db_name'}' column='$env{'column'}'");
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity,
			$env{'column'},
			status
		FROM
			`$env{'r_db_name'}`.`$env{'r_prefix'}_$env{'r_table'}`
		WHERE
			ID_entity=$env{'r_ID_entity'}
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'});
	my %db0_line=$sth0{'sth'}->fetchhash();
	
	# define info hash
	my %info;
	$info{'name'}=$db0_line{$env{'column'}};
	$info{'status'}=$db0_line{'status'};
	
	$t->close();
	return %info;
}

1;