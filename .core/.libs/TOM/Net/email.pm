package TOM::Net::email;
use TOM::Utils::vars;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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

B<from> - DEPRECATED only information ( not saved to email header )
B<from_email> - only information ( not saved to email header )

=item *

B<from_name> - sender name

=item *

B<to> - DEPRECATED real email adresses ( not saved to email header )
B<to_email> - real email adresses ( not saved to email header )

=item *

B<to_name> - recipient name

=item *

B<body> - body of email

=item *

B<priority> - default '1' ( higher priority means sending sooner )

=back

=cut

sub send
{
#	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => '_global','class'=>'email'}); # do it in background
	my %env=@_;
	
	my $ID=time()."-".$$."-".sprintf("%07d",int(rand(10)));
	
	$env{'time'}=time() unless $env{'time'};
	$env{'priority'}=1 unless $env{'priority'};
	
	$env{'from_service'}='Cyclone3' unless $env{'from_service'};
	
	$env{'from_email'}=$env{'from'} unless $env{'from_email'}; #covering deprecated calls
	$env{'from_email'}=$TOM::contact{'from'} unless $env{'from_email'};
	
	$env{'from_name'}="Cyclone3" unless $env{'from_name'};
	
	$env{'to_email'}=$env{'to'} unless $env{'to_email'}; #covering deprecated calls
	
	# spracovanie duplikatov emailovych adries
	$env{'to_email'}=TOM::Utils::vars::unique_split($env{'to_email'});
	$env{'to_email_orig'}=$env{'to_email'};
	
	my %rcpt=map {$_ => 1} split(';',$env{'to_email'});
	foreach (keys %rcpt)
	{
		if ($tom::devel)
		{
			if ($App::130::rcpt_regex_forced)
			{
				delete $rcpt{$_}
					unless $_=~/$App::130::rcpt_regex_forced/;
			}
			else
			{
				delete $rcpt{$_};
			}
		}
	}
	
	$env{'to_email'}=join(';',sort keys %rcpt);
	
	if (!$env{'to_email'} && $tom::devel)
	{
		main::_log("sending email's to '$env{'to_email_orig'}' not allowed, tom::devel enabled (edit \$App::130::rcpt_regex_forced to allow send emails to specific email addresses)",{
			'facility' => 'email',
			'severity' => 4
		});
		return
	}
	
	#
	# najprv zistim ci mozem tento email zapisovat do databazy, potom
	# ci su vobec emaily z databazy posielane
	#
	eval
	{
		my %sth0=TOM::Database::SQL::execute("SELECT ID FROM TOM.a130_send LIMIT 1",'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
	};
	
	my $subject;
	if ($env{'body'}=~/Subject: (.*?)\n/)
	{
		$subject=$1;
	}
	
	if (!$@)
	{
#		main::_log("creating email over a130 to '$env{'to_email'}'");
		
		my %sth0=TOM::Database::SQL::execute(qq{
			INSERT INTO TOM.a130_send
			(ID_md5,sendtime,priority,from_name,from_email,from_host,from_service,to_name,to_email,datetime_create)
			VALUES
			('$env{'md5'}',?,?,?,?,?,?,?,?,NOW())
		},'bind'=>[
			$env{'time'},
			$env{'priority'},
			($env{'from_name'} || ''),
			($env{'from_email'} || ''),
			($tom::H || ''),
			($env{'from_service'} || ''),
			($env{'to_name'} || ''),
			($env{'to_email'} || '')
		],'quiet'=>1);
		if ($sth0{'rows'})
		{
			my $ID=$sth0{'sth'}->insertid();
			
			App::020::SQL::functions::_save_changetime(
				{'db_h'=>'main','db_name'=>'TOM','tb_name'=>'a130_send','ID_entity'=>$ID}
			);
			
			if (!$ID)
			{
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						ID
					FROM
						TOM.a130_send
					WHERE
						sendtime = ? AND
						from_name = ? AND
						from_email = ? AND
						from_host = ? AND
						from_service = ? AND
						to_name = ? AND
						to_email = ?
					LIMIT 1
				},'bind'=>[
					$env{'time'},
					$env{'from_name'},
					$env{'from_email'},
					$tom::H,
					$env{'from_service'},
					$env{'to_name'},
					$env{'to_email'}
				],'quiet'=>1);
				my %db0_line=$sth0{'sth'}->fetchhash();
				$ID=$db0_line{'ID'};
			}
			
			if (!$ID)
			{
				main::_log("can't write email into database (insertid() not returned), inserting email to filesystem",3,"email",1);
			}
			else
			{
				# save body into file
				my $dir=int($ID/900);
				if (!-d $TOM::P.'/_data/email/'.$dir)
				{
					mkdir($TOM::P.'/_data/email/'.$dir,0777);
				}
				open(EMAILBODY,'>'.$TOM::P.'/_data/email/'.$dir.'/body_'.$ID.'.eml');
				binmode(EMAILBODY);
				print EMAILBODY $env{'body'};
				close(EMAILBODY);
				chmod 0666, $TOM::P.'/_data/email/'.$dir.'/body_'.$ID.'.eml';
				
				use Encode qw/encode decode/;
				
				main::_log("[$ID] created email to a130",{
					'facility' => 'email',
					'severity' => 3,
					'data' => {
						'id_i' => $ID,
						'email_s' => [split(';',$env{'to_email'})],
						'subject_t' => decode('MIME-Header',$subject)
					}
				});
				
				if (!-e $TOM::P.'/_data/email/'.$dir.'/body_'.$ID.'.eml')
				{
					main::_log("can't write email.ID='$ID' into filesystem, inserting email body to database",3,"email",1);
					
					# error writing email to filesystem
					TOM::Database::SQL::execute(qq{
						UPDATE TOM.a130_send
						SET body=?
						WHERE ID=?
						LIMIT 1
					},'bind'=>[$env{'body'},$ID],'quiet'=>1);
				}
				
				return 1;
			}
		}
	}
	
	#
	# zapisanie emailu ako file je az ako posledna moznost
	#
	main::_log("sending email over file '$ID' to '$env{'to_email'}'");
	
	open(HND_mail,">".$TOM::P."/_temp/_email-".$ID) || die "can't send email over file!\n";
	binmode(HND_mail);
	print HND_mail "$env{'from_email'}\n";
	print HND_mail "$env{'to_email'}\n";
	print HND_mail $env{'body'}."\n";
	close (HND_mail);
	chmod 0666, $TOM::P."/_temp/_email-".$ID;
	
	return $ID;
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
