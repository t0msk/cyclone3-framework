package TOM::TypeID;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


#
# Loads reparsed <SHIFT> into \%tom::type_c{}
#
sub parse_conf
{
	my $t=track TOM::Debug(__PACKAGE__."::parse_conf()");
	main::_log('parsing type.conf data into \%tom::type_c{}');
	
	my $data=shift;
	%tom::type_c=();
	
	foreach my $line(split('\n',$data))
	{
		next unless $line;
		next if $line=~/^#/;
		
		# v line si necham zoznam type, do $1 dostanem TypeID
		$line=~s/^(.*?)\s*?=\s*?"(.*?)"/$2/;
		
		my $TypeID=$1;
		foreach my $type(split(';',$line))
		{
			next unless $type;
			$tom::type_c{$type}=$TypeID;
			main::_log("type:'$type'=TypeID:'$TypeID'");
		}
	}
	
	$t->close();
	return 1;
}






1;