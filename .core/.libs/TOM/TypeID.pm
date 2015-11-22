package TOM::TypeID;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


sub read_conf
{
	my $filename=shift;
	my $t=track TOM::Debug(__PACKAGE__."::read_conf($filename)");
	%tom::type_c=();
	_read_conf($filename);
	$tom::type_time=time();
	$t->close();
	return 1;
}


sub _read_conf
{
	my $filename=shift;
	my $t=track TOM::Debug(__PACKAGE__."::_read_conf($filename)");
	
	open(TCONF,'<'.$filename);
	my $data;
	while (my $line=<TCONF>)
	{
		$data.=$line;
	}
	close(TCONF);
	
	parse_conf($data);
	
	$t->close();
	return 1;
}


#
# Loads reparsed <SHIFT> into \%tom::type_c{}
#
sub parse_conf
{
	my $t=track TOM::Debug(__PACKAGE__."::parse_conf()");
	main::_log('parsing type.conf data into \%tom::type_c{}');
	
	my $data=shift;
	
	foreach my $line(split('\n',$data))
	{
		#chomp($line);
		$line=~s|[\n\r]||g;
		next unless $line;
		next if $line=~/^#/;
		
		if ($line=~s/^%//)
		{
			my $important=1;
			if ($line=~s|^\?||)
			{
				undef $important;
			}
			
			my @cmd=split("=",$line,2);
			main::_log("command $cmd[0]($cmd[1])");
			if ($cmd[0] eq "import")
			{
				# local
				if (-e $tom::P.'/type.'.$cmd[1].'.conf')
				{
					_read_conf($tom::P.'/type.'.$cmd[1].'.conf');
				}
				# master
				elsif (-e $tom::Pm.'/type.'.$cmd[1].'.conf')
				{
					_read_conf($tom::Pm.'/type.'.$cmd[1].'.conf');
				}
				# global
				elsif (-e $TOM::P.'/_config/type.'.$cmd[1].'.conf')
				{
					_read_conf($TOM::P.'/_config/type.'.$cmd[1].'.conf');
				}
				# superglobal
				elsif (-e $TOM::P.'/.core/_config/type.'.$cmd[1].'.conf')
				{
					_read_conf($TOM::P.'/.core/_config/type.'.$cmd[1].'.conf');
				}
				else
				{
					die "can't import type.conf named 'type.$cmd[1].conf'" if $important;
					main::_log("can't found type.conf named 'type.$cmd[1].conf'");
				}
			}
			next;
		}
		
		# v line si necham zoznam type, do $1 dostanem TypeID
		$line=~s/^(.*?)\s*?=\s*?"(.*?)"/$2/;
		
		my $TypeID=$1;
		foreach my $type(split(';',$line))
		{
			#chomp($type);
			next unless $type;
			$tom::type_c{$type}=$TypeID;
			main::_log("type:'$type'=TypeID:'$TypeID'");
		}
	}
	
	$t->close();
	return 1;
}






1;
