#!/bin/perl
package App::401::a301;

=head1 NAME

App::401::a301

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a301 enhancement to a401

=cut

=head1 DEPENDS

=over

=item *

L<App::401::_init|app/"401/_init.pm">

=item *

L<App::301::perm|app/"301/perm.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::401::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='$Rev$';
our $debug=0;


# addon functions
our %functions=(
	# article data
	'addon' => 1,
#	'data.article.visits' => 1,
#	'data.article.title' => 1,
#	'data.article.datetime_start' => 1,
#	'data.article.datetime_stop' => 1,
#	'data.article.priority_A' => 1,
#	'data.article.priority_B' => 1,
#	'data.article.priority_C' => 1,
#	'data.article.editor' => 1,
#	'data.article.subtitle' => 1,
#	'data.article.content' => 1,
	
	# actions
#	'action.article.enable' => 1,
);


# addon roles
our %roles=(
	'addon' => [
		'addon'
	],
#	'article.content' => [
#		'data.article.title',
#		'data.article.subtitle',
#		'data.article.content',
#	],
#	'article.planning' => [
#		'data.article.datetime_start',
#		'data.article.datetime_stop',
#		'data.article.priority_A',
#		'data.article.priority_B',
#		'data.article.priority_C'
#	],
#	'article.publishing' => [
#		'action.article.enable'
#	],
);


# default groups related to addon roles with defined permissions
our %groups=(
	'world' => {
#		'article' => 'r  '
	},
	'editor' => {
		'addon' => 'rwx',
#		'article.planning' => 'rwx',
#		'article.publishing' => 'rwx'
	}
);


# ACL role override
our %ACL_roles=(
	'owner' => {
#		'article' => 'rwx',
#		'article.content' => 'rwx',
#		'article.planning' => 'rwx',
	},
#	'manager' => {
#		'article.planning' => 'r x',
#	},
);


# register this definition

App::301::perm::register(
	'addon' => 'a401',
	'functions' => \%functions,
	'roles' => \%roles,
	'ACL_roles' => \%ACL_roles,
	'groups' => \%groups
);



sub get_owner
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_owner()") if $debug;
	
	if ($debug)
	{
		foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	}
	
	if ($env{'r_table'} eq "article")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::401::db_name`.a401_article_ent
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1,'-slave'=>0);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$t->close() if $debug;
		return $db0_line{'posix_owner'};
	}
	elsif ($env{'r_table'} eq "article_cat")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::401::db_name`.a401_article_cat
			WHERE
				ID='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1,'-slave'=>0);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$t->close() if $debug;
		return $db0_line{'posix_owner'};
	}
	
	$t->close() if $debug;
	return undef;
}


sub set_owner
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::set_owner()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	if ($env{'r_table'} eq "article_cat")
	{
		App::020::SQL::functions::update(
			'ID' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::401::db_name,
			'tb_name' => 'a401_article_cat',
			'columns' =>
			{
				'posix_owner' => "'".$env{'posix_owner'}."'"
			},
			'-journalize' => 1,
			'-posix' => 1
		);
		$t->close();
		return 1;
	}
	elsif ($env{'r_table'} eq "article")
	 {
		  my @IDs=App::020::SQL::functions::get_ID_entity
		  (
				'ID_entity' => $env{'r_ID_entity'},
				'db_h' => 'main',
				'db_name' => $App::401::db_name,
				'tb_name' => 'a401_article_ent',
		  );
		  if ($IDs[0]->{'ID'})
		  {
				App::020::SQL::functions::update(
					 'ID' => $IDs[0]->{'ID'},
					 'db_h' => 'main',
					 'db_name' => $App::401::db_name,
					 'tb_name' => 'a401_article_ent',
					 'columns' =>
					 {
						  'posix_owner' => "'".$env{'posix_owner'}."'"
					 },
					 '-journalize' => 1,
					 '-posix' => 1
				);
				$t->close();
				return 1;
		  }
	 }
	
	$t->close();
	return undef;
}



1;