#!/bin/perl
package App::411::functions;

=head1 NAME

App::411::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::411::_init|app/"411/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::411::_init;
use TOM::Security::form;

our $debug=0;
our $quiet;$quiet=1 unless $debug;



sub poll_item_info
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::article_item_info()");
	
	my $sql=qq{
		SELECT
			*,
			IF
			(
				(
					status LIKE 'Y' AND
					NOW() >= datetime_start AND
					(datetime_stop IS NULL OR NOW() <= datetime_stop)
				),
			 	'Y', 'N'
			) AS datetime_status
		FROM
			`$App::411::db_name`.a411_poll
		WHERE
			ID = '$env{'poll.ID'}' AND
			ID_category = '$env{'poll.ID_category'}'
		LIMIT
			1
	};
	
	my %data;
	
	my %sth0=TOM::Database::SQL::execute($sql,'log'=>1);
	if ($sth0{'sth'})
	{
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			
			foreach (keys %db0_line){$data{'db_'.$_}=$db0_line{$_};}
			
			# check relations
			foreach my $relation (App::160::SQL::get_relations(
				'db_name' => $App::411::db_name,
				'l_prefix' => 'a411',
				'l_table' => 'poll',
				'l_ID_entity' => $db0_line{'ID_entity'},
				'status' => "Y"
			))
			{
				$data{'relation_status'}='Y';
			}
         
		}
		
	}
	else
	{
		main::_log("can't select",1);
	}
	
	$t->close();
	return %data;
}

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
