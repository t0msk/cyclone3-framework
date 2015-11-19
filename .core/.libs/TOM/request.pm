package TOM::request;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use Encode;
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Ext::Redis::_init;

our $debug=0;

sub new
{
	my $class=shift;
	my $self={};
	
	my $env=shift;
	
	if ($Redis)
	{	
#		main::_log("request ".$env->{'request'});
		
		$Redis->hmset('c3process|'.$TOM::hostname.':'.$$,
			'time' => time(),
			'start' => $TOM::time_start,
			'count' => $tom::count,
			'request_code' => $main::request_code,
			'host' => ($env->{'host'} || ''),
			'request' => ($env->{'request'} || ''),
			sub {}
		);
		
		$Redis->expire('c3process|'.$TOM::hostname.':'.$$, 86400, sub {});
	}
	
	return bless $self, $class;
}


sub DESTROY
{
	my $self=shift;
	
	if ($Redis)
	{
#		main::_log("destroy");
		$Redis->hdel('c3process|'.$TOM::hostname.':'.$$, 'request_code', sub {});
#		$Redis->del('c3process|'.$TOM::hostname.':'.$$, sub {});
	}
	
	return undef;
}

1;
