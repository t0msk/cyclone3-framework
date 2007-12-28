package TOM::Security::form;
use strict;

=head1 NAME

TOM::Security::form

=head1 DESCRIPTION

Protect to SQL injection or HTML injection

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 FUNCTIONS

=head2 check_form(%)


=cut

sub check_form
{
	my %env=@_;
	return 1 unless $main::FORM{$env{'variable'}};
	main::_log("check_form variable='$env{'variable'}' type='$env{'type'}' action='$env{'action'}'");
	
	my $bad;
	
	if ($env{'type'} eq "int")
	{
		$bad=1 unless $main::FORM{$env{'variable'}}=~/^([0-9]+)$/;
	}
	elsif ($env{'type'} eq "string")
	{
	}
	elsif (!$env{'type'})
	{
		$bad=2;
		# do the action
	}
	
	if ($bad)
	{
		if ($bad==1)
		{
			main::_log("trying to inject value '$main::FORM{$env{'variable'}}' to '$env{'variable'}'",1);
			main::_log("trying to inject value '$main::FORM{$env{'variable'}}' to '$env{'variable'}'",4,"secure");
			main::_log("[$tom::H] trying to inject value '$main::FORM{$env{'variable'}}' to '$env{'variable'}'",4,"secure",1);
		}
		
		if ($env{'action'} eq "destroy" || !$env{'action'})
		{
			undef $main::FORM{$env{'variable'}};
		}
		elsif ($env{'action'} eq "sql_escape")
		{
			$main::FORM{$env{'variable'}} = $main::DB{'main'}->quote( $main::FORM{$env{'variable'}} );
			$main::FORM{$env{'variable'}} =~s|^'||;
			$main::FORM{$env{'variable'}} =~s|'$||;
			#main::_log("quoted to '$main::FORM{$env{'variable'}}'");
		}
		else
		{
			
		}
	}
	else
	{
		return 1;
	}
}


sub check_email
{
	my $email=shift;
	return undef if $email=~/\.\./;
	return 1 if $email=~/^[a-zA-Z0-9_\.\-]{2,50}\@[a-zA-Z0-9_\.\-]{2,100}\.[a-zA-Z0-9]{2,10}$/;
	return undef;
}


sub html_input_value_escape
{
	my $val=shift;
	$val=~s|&|&amp;|g;
	$val=~s|"|&quot;|g;
	return $val;
}


1;
