#!/usr/bin/perl

package TOM::Net::HTTP::Media;
use strict;
use warnings;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}




our %type=
(
	'mobile' => 'm',
	'smartphone' => 'p',
	'tablet' => 't',
	'screen' => 's',
	'unknown' => 'X',
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
	
	{name=>'iPad',
		regexp => ['iPad'],
		media_type => "tablet",
	},
	
	{name=>'iPhone',
		regexp => ['iPhone'],
		media_type => "smartphone",
	},
	
	{name=>'PocketPC',
		regexp => ['MSIE .*PPC'],
		media_type => "smartphone",
	},
	
	{name=>'NetFront',
		regexp => ['NetFront'],
		media_type => "mobile",
	},
	
	{name=>'Android',
		regexp => ['Android.*Mobile Safari'],
		media_type => "smartphone",
	},
	
	{name=>'Mobile (unknown)',
		regexp => ['Mobile'],
		media_type => "mobile",
	},
	
	{name=>'MSIE',
		regexp => ['MSIE'],
		media_type => "screen",
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
		foreach my $regexp (@{$table[$i]{'regexp'}})
		{
			return ($i,$table[$i]{'name'},$table[$i]{'media_type'}) if $user_agent=~/$regexp/i;
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
