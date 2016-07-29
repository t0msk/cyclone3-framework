#!/bin/perl
package App::510::a160;

=head1 NAME

App::510::a160

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a510

=cut

=head1 DEPENDS

=over

=item *

L<App::510::_init|app/"510/_init.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::020::a160|app/"020/a160.pm">

=back

=cut

use App::510::_init;
use App::020::_init;
use App::020::a160;

our $VERSION='1';

sub get_relation_iteminfo
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_relation_iteminfo()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	# if db_name is undefined, use local name
	$env{'r_db_name'}=$App::510::db_name unless $env{'r_db_name'};
	
	my $lng_in;
	
	if ($env{'lng'})
	{
		$lng_in="AND lng='".$env{'lng'}."'";
	}
	
	my %info;
	
	if ($env{'r_table'} eq "video")
	{
		my $lng_in2 = $lng_in;
		$lng_in2=~s|AND lng|AND `video_attrs`.`lng`|;
		my $sql=qq{
			SELECT
				`video`.`ID`,
				`video_cat`.`ID` AS `ID_category`,
				`video_attrs`.`name`,
				`video`.`datetime_rec_start`,
				`video_attrs`.`lng`
			FROM
				`$env{'r_db_name'}`.`a510_video` AS `video`
			INNER JOIN `$App::510::db_name`.`a510_video_attrs` AS `video_attrs` ON
			(
						`video_attrs`.`ID_entity` = `video`.`ID`
				AND	`video_attrs`.`lng` = '$env{'lng'}'
				AND	`video_attrs`.`status` IN ('Y','L')
			)
			LEFT JOIN `$App::510::db_name`.`a510_video_cat` AS `video_cat` ON
			(
						`video_cat`.`ID_entity` = `video_attrs`.`ID_category`
				AND	`video_cat`.`lng` = `video_attrs`.`lng`
				AND	`video_cat`.`status` IN ('Y','L')
			)
			WHERE
				`video`.`ID_entity` = $env{'r_ID_entity'}
				$lng_in2
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID'};
			$info{'ID_category'}=$db0_line{'ID_category'};
			$info{'lng'}=$db0_line{'lng'};
			
			my $datetime_rec_start=$db0_line{'datetime_rec_start'};
			$datetime_rec_start=~s|:\d\d$||;
			$info{'name_plus'}=$datetime_rec_start;
			
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	if ($env{'r_table'} eq "video_part")
	{
		my $sql=qq{
			SELECT
				ID_part,
				ID_category,
				name,
				part_name,
				datetime_rec_start,
				lng
			FROM
				`$env{'r_db_name'}`.a510_video_view
			WHERE
				ID_part=$env{'r_ID_entity'}
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'}.' - '.$db0_line{'part_name'};
			$info{'ID'}=$db0_line{'ID_part'};
			$info{'ID_category'}=$db0_line{'ID_category'};
			$info{'lng'}=$db0_line{'lng'};
			
			my $datetime_rec_start=$db0_line{'datetime_rec_start'};
			$datetime_rec_start=~s|:\d\d$||;
			$info{'name_plus'}=$datetime_rec_start;
			
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	if ($env{'r_table'} eq "video_cat")
	{
		my $sql=qq{
			SELECT
				ID,
				name,
				lng
			FROM
				`$env{'r_db_name'}`.a510_video_cat
			WHERE
				ID_entity=$env{'r_ID_entity'}
				$lng_in
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID'};
			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	if ($env{'r_table'} eq "broadcast_channel")
	{
		my $sql=qq{
			SELECT
				ID,
				name
			FROM
				`$env{'r_db_name'}`.a510_broadcast_channel
			WHERE
				ID_entity=$env{'r_ID_entity'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$info{'name'}=$db0_line{'name'};
			$info{'ID'}=$db0_line{'ID'};
#			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	$t->close();
	return undef;
}



1;
