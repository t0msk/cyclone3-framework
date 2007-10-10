#!/bin/perl
package App::100::SQL;

=head1 NAME

App::100::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

 App::100

=cut

use App::100::_init;

our $debug=0;
our $quiet=0;$quiet=1 unless $debug;

=head1 FUNCTIONS

=head2 ticket_event_new

Vloží nový záznam

=head2 ticket_close

Uzavrie ticket

=cut



sub ticket_event_new
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::ticket_event_new()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}

	my $ID_ticket;

	# Ak existuje tiket z danym nazvom, tak
	my $sql = qq/
	SELECT
		ID, emails, status
	FROM
		TOM.a100_ticket
	WHERE
		domain='$env{'domain'}' AND
		name='$env{'name'}'
	/;
	my %sth0 = TOM::Database::SQL::execute( $sql, 'db_h'=>$env{'db_h'}, 'quiet'=>$quiet, 'log'=>$debug);
	
	if ( !$sth0{'rows'} )
	{
		# Este taky ticket nemam, musim ho vytvorit
		$ID_ticket = App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => "TOM",
			'tb_name' => "a100_ticket",
			'columns' => {
				'domain' => "'$env{'domain'}'",
				'name' => "'$env{'name'}'",
				'emails' => "'$env{'emails'}'",
				'status' => "'Y'",
			},
			'-journalize' => 1
		);
	}
	else
	{
		my %ticket = $sth0{'sth'}->fetchhash;
		$ID_ticket = $ticket{'ID'};
		my $journalize;
		$journalize=1 if $ticket{'status'} ne 'Y';
		App::020::SQL::functions::update(
			'db_h' => "main",
			'db_name' => "TOM",
			'tb_name' => "a100_ticket",
			'ID' => $ticket{'ID'},
			'columns' =>
			{
				'status' => "'Y'",
				'emails' => "'$env{'emails'}'",
			},
			'-journalize' => $journalize
		);
	}
	
	return 0 unless $ID_ticket;
	
	$env{'cvml'} =~ s|'|\\'|g;
	
	# Vytvaram ticket event
	my $ID_ticket_event = App::020::SQL::functions::new(
		'db_h' => "main",
		'db_name' => "TOM",
		'tb_name' => "a100_ticket_event",
		'columns' => {
			'ID_ticket' => $ID_ticket,
			'cvml' => "'$env{'cvml'}'",
			'status' => "'Y'",
		},
	);
	
	return 0 unless $ID_ticket_event;
	$t->close() if $debug;
	return 1;
}



sub ticket_close
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::ticket_close()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};

	return 0 unless $env{'ID'};

	App::020::SQL::functions::update(
		'db_h' => 'main',
		'db_name' => 'TOM',
		'tb_name' => 'a100_ticket',
		'ID' => $env{'ID'},
		'columns' =>
		{
			'status' => "'N'",
		},
		'-journalize' => 1
	);

	my $sql_events = qq/
	UPDATE TOM.a100_ticket_event
	SET
		status='N'
	WHERE
		ID_ticket=$env{'ID'}
	/;
	my %sth0 = TOM::Database::SQL::execute( $sql_events, 'db_h'=>$env{'db_h'} );

	$t->close();
	return 1;
}


=head2 ircbot_msg_new()

Saves message into table a100_ircbot_msg and ircbot it sends when it is running

Function return true or false

=cut

sub ircbot_msg_new
{
	my $message=shift;
	my $t=track TOM::Debug(__PACKAGE__."::ircbot_msg_new()");
	
	$message=TOM::Database::SQL::escape($message);
	
	my $ID= App::020::SQL::functions::new(
		'db_h' => "main",
		'db_name' => "TOM",
		'tb_name' => "a100_ircbot_msg",
		'columns' =>
			{
				'message' => "'$message'",
				'status' => "'Y'",
			},
			'-journalize' => 0
		);
	
	return 0 unless $ID;
	$t->close();
	return 1;
}


1;
