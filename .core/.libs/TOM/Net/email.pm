package TOM::Net::email;
use TOM::Utils::vars;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub send
{
	my $ID=time()."-".$$."-".sprintf("%07d",int(rand(10)));
	my %env=@_;
	
	$env{'time'}=time() unless $env{'time'};
	$env{'priority'}=1 unless $env{'priority'};
	
	# spracovanie duplikatov emailovych adries
	$env{to}=TOM::Utils::vars::unique_split($env{to});
	
	#
	# najprv zistim ci mozem tento email zapisovat do databazy, potom
	# ci su vobec emaily z databazy posielane
	#
	eval
	{
		my $db0=$main::DB{main}->Query("SELECT ID FROM TOM.a130_send LIMIT 1");
		my %db0_line=$db0->fetchhash();
	};
	
	if (!$@)
	{
		main::_log("sending email over a130");
		
		$env{body}=~s|'|\\'|g;
		
		if (
			$main::DB{main}->Query("
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
				'TOM3',
				'$env{from}',
				'$tom::H',
				'TOM3',
				'$env{to_name}',
				'$env{to}',
				'$env{body}'
			)
		")
		)
		{
			main::_log(" sended");
			return 1;
		}
	}
	
	#
	# zapisanie emailu ako file je az ako posledna moznost
	#
	main::_log("sending email over file $ID");
	
	open(HND_mail,">".$TOM::P."/_temp/_email-".$ID) || die "can't send email over file!\n";
	print HND_mail "$env{from}\n";
	print HND_mail "$env{to}\n";
	#print HND_mail "---\n";
	print HND_mail $env{body}."\n";
	#print HND_mail "---\n";
	close (HND_mail);
	chmod 0666, $TOM::P."/_temp/_email-".$ID;
	
	return 1;
}


sub convert_TO
{
	my $to=shift;
	$to=~s|;|>, <|g;
	$to='<'.$to.'>';
	return $to;
}


1;