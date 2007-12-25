package TOM::Net::email;
use TOM::Utils::vars;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

TOM::Net::email

=cut

=head1 DESCRIPTION

Allow you to send and manage emails

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 FUNCTIONS

=head2 send()

Write email to database or to email. Cron system module L<a130|source-doc/".core/.libs/App/a130/"> sends this emails automatically.

=over

=item *

B<from> - only information ( not saved to email header )

=item *

B<to> - real email adresses ( not saved to email header )

=item *

B<body> - body of email

=item *

B<priority> - default '1' ( higher priority means sending sooner )

=back

=cut

sub send
{
	my $ID=time()."-".$$."-".sprintf("%07d",int(rand(10)));
	my %env=@_;
	
	$env{'time'}=time() unless $env{'time'};
	$env{'priority'}=1 unless $env{'priority'};
	$env{'from'}=$TOM::contact{'from'} unless $env{'from'};
	
	# spracovanie duplikatov emailovych adries
	$env{to}=TOM::Utils::vars::unique_split($env{to});
	
	#
	# najprv zistim ci mozem tento email zapisovat do databazy, potom
	# ci su vobec emaily z databazy posielane
	#
	eval
	{
		my %sth0=TOM::Database::SQL::execute("SELECT ID FROM TOM.a130_send LIMIT 1");
		my %db0_line=$sth0{'sth'}->fetchhash();
		die "can't select ID from a130_send" unless $db0_line{'ID'};
	};
	
	if (!$@)
	{
		main::_log("sending email over a130 to '$env{to}'");
		
		$env{body}=~s|'|\\'|g;
		
		my %sth0=TOM::Database::SQL::execute(qq{
			INSERT INTO TOM.a130_send
			(
				ID_md5,
				sendtime,
				priority,
				from_name,
				from_email,
				from_host,
				from_service,
				to_name,
				to_email,
				body
			)
			VALUES
			(
				'$env{md5}',
				'$env{time}',
				'$env{priority}',
				'Cyclone3',
				'$env{from}',
				'$tom::H',
				'Cyclone3',
				'$env{to_name}',
				'$env{to}',
				'$env{body}'
			)
		});
		if ($sth0{'rows'})
		{
			main::_log(" sended");
			return 1;
		}
	}
	
	#
	# zapisanie emailu ako file je az ako posledna moznost
	#
	main::_log("sending email over file '$ID' to to '$env{to}'");
	
	open(HND_mail,">".$TOM::P."/_temp/_email-".$ID) || die "can't send email over file!\n";
	print HND_mail "$env{'from'}\n";
	print HND_mail "$env{'to'}\n";
	#print HND_mail "---\n";
	print HND_mail $env{'body'}."\n";
	#print HND_mail "---\n";
	close (HND_mail);
	chmod 0666, $TOM::P."/_temp/_email-".$ID;
	
	return 1;
}

=head2 convert_TO('email@domain.tld;my@domain.tld')

Converts comma separated list of emails to string which is usable in email header

=cut

sub convert_TO
{
	my $to=shift;
	$to=~s|;|>, <|g;
	$to='<'.$to.'>';
	return $to;
}

=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;