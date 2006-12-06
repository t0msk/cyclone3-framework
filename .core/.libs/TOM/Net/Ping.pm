package TOM::Net::Ping;

=head1 NAME

TOM::Net::Ping

=head1 DESCRIPTION

Knižnica poskytuje služby pre overovanie dostupnosti a iné sieťové služby

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

knižnice:

  Net::Ping;

=cut

use Net::Ping;

=head1 FUNCTIONS

=cut

=head2 host_availability

Toto je na toto

=cut

sub host_availability
{
	my $url = $_[0];

	if ( !$url )
	{
		main::_log("URL not specified!");
		return 0;
	}

	# Resolving host from url
	$url =~ /^http:\/\/([^\/]+)/; my $host = $1;
	if ( !$host ) { $url =~ /^([^\/]+)/; $host = $1; }

	main::_log( "Url: $url" );

	if ( !$host )
	{
		main::_log("Cant`t resolve host");
		return 0;
	}
	
	main::_log( "Host: $host" );

	# Ping host
	my $p = Net::Ping->new("tcp", 3);
	$p->{port_num} = getservbyname("http", "tcp");
	
	if ( $p->ping( $host ) )
	{
		$p->close();
		main::_log("Host OK");
		return 1;
	}

	$p->close();
	main::_log("Host ERR");
	return 0;
}

1;

=head1 AUTHOR

Matej Gregor

=cut