#!/bin/perl
package App::110::SQL;

=head1 NAME

App::110::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

Functions above SQL database to manipulate with statistics

=cut

=head1 DEPENDS

=over

=item *

L<App::110::_init|app/"110/_init.pm">

=back

=cut

use App::110::_init;

our $DEBUG=0;


=head1 FUNCTIONS

=head2 get_last_active_request()

Returns informations about last active request in TOM.a110_weblog_rqs

 my %data=get_last_active_request();

When this request take very long time, then your database server is very slow, also upgrade it!

=cut

sub get_last_active_request()
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_last_active_request()");
	
	my %data;
	
	my $sql=qq{
		SELECT
			page_code,
			reqtime,
			reqdatetime,
			DATE(reqdatetime) as reqdate
		FROM
			TOM.a110_weblog_rqs
--		WHERE
--			active='Y'
		ORDER BY
			reqdatetime DESC
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>undef,'log'=>$DEBUG,'db_h'=>'stats');
	
	my %data=$sth0{'sth'}->fetchhash();
	
	main::_log("returning datetime='$data{'reqdatetime'}'");
	
	$t->close();
	return %data;
}



=head2 get_first_active_request()

Returns informations about first active request in TOM.a110_weblog_rqs

 my %data=get_first_active_request();

=cut

sub get_first_active_request()
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_first_active_request()");
	
	my %data;
	
	my $sql=qq{
		SELECT
			page_code,
			reqtime,
			reqdatetime,
			DATE(reqdatetime) as reqdate
		FROM
			TOM.a110_weblog_rqs
		WHERE
			active='Y'
		ORDER BY
			reqdatetime ASC
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>undef,'log'=>$DEBUG,'db_h'=>'stats');
	
	my %data=$sth0{'sth'}->fetchhash();
	
	main::_log("returning datetime='$data{'reqdatetime'}'");
	
	$t->close();
	return %data;
}


=head2 get_last_collected_hour()

Returns informations about last collected hour in TOM.a110_weblog_hour

 my %data=get_last_collected_hour();

 my %data=get_last_collected_hour('domain' => "example.tld");

=cut

sub get_last_collected_hour
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_last_collected_hour()");
	
	my %data;
	my $where;
	
	if ($env{'domain'})
	{
		$where.="AND domain='$env{'domain'}' ";
	}
	
	my $sql=qq{
		SELECT
			reqdatetime,
			DATE(reqdatetime) as reqdate
		FROM
			TOM.a110_weblog_hour
		WHERE
			domain_sub=''
			$where
		ORDER BY
			reqdatetime DESC
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'log'=>$DEBUG,'db_h'=>"stats");
	
	my %data=$sth0{'sth'}->fetchhash();
	
	main::_log("returning datetime='$data{'reqdatetime'}'");
	
	$t->close();
	return %data;
}



=head2 get_last_collected_day()

Returns informations about last collected day in TOM.a110_weblog_day

 my %data=get_last_collected_day();

=cut

sub get_last_collected_day()
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_last_collected_day()");
	
	my %data;
	
	my $sql=qq{
		SELECT
			reqdatetime,
			DATE(reqdatetime) AS reqdate
		FROM
			TOM.a110_weblog_day
		WHERE
			domain_sub=''
		ORDER BY
			reqdatetime DESC
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'log'=>$DEBUG,'db_h'=>"stats");
	
	my %data=$sth0{'sth'}->fetchhash();
	
	main::_log("returning date='$data{'reqdate'}'");
	
	$t->close();
	return %data;
}



=head2 get_last_collected_week()

Returns informations about last collected week in TOM.a110_weblog_week

 my %data=get_last_collected_hour();

=cut

sub get_last_collected_week()
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_last_collected_week()");
	
	my %data;
	
	my $sql=qq{
		SELECT
			reqdatetime
		FROM
			TOM.a110_weblog_week
		WHERE
			domain_sub=''
		ORDER BY
			reqdatetime DESC
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'log'=>$DEBUG,'db_h'=>"stats");
	
	my %data=$sth0{'sth'}->fetchhash();
	
	main::_log("returning datetime='$data{'reqdatetime'}'");
	
	$t->close();
	return %data;
}

=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;
