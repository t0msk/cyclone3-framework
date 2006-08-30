#!/usr/bin/perl

package TOM::Net::HTTP::Media;
use strict;
use warnings;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}




our %type=
(
	'mobile'   => 'm',
	'pda'      => 'p',
	'screen'   => 's',
	'unknown'  => 'X',
);







our @table=
(

	# DEFAULT UNKNOWN MEDIA
	# tento agent nezistujem regexpom
	# ked nezistim o akeho agenta ide, pouzijem tohto, lebo ide o ID=0
	#
	{name=>'unknown',
#		regexp=>[''],
#		agent_type	=>	"browser",
#		agent_group	=>	"",
#		USRM_disable	=>	1,
	},
	
	{name=>'PocketPC MSIE 4.X',
		regexp		=>	['MSIE 4.*PPC'],
		media_type	=>	"pda",
	},
	
	{name=>'MSIE',
		regexp		=>	['MSIE'],
		media_type	=>	"screen",
	},
	
	
	
);



sub analyze
{
	my $user_agent=shift @_;
	return undef unless $user_agent;
	my %env=@_;
	
	# my $var=0;
	foreach my $i(1..@table-1)
	{
		foreach my $regexp (@{$table[$i]{regexp}})
		{
			return ($i,$table[$i]{name}) if $user_agent=~/$regexp/i;
		}
	}
	return undef;
};


sub getIDbyName
{
	my $name=shift @_;
	foreach my $i(0..@table-1)
	{
		return $i if $table[$i]{name} eq $name;
	}
	return undef;
}

# END
1;# DO NOT CHANGE !
