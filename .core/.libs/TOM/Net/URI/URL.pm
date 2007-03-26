package TOM::Net::URI::URL;
use open ':utf8', ':std';
use encoding 'utf8';
use Encode;
use enc3;
use bytes;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

# List of valid characters in QUERY_STRING
my $URLENCODE_VALID = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-+.=";

# Prepare list of valid and invalid characters (hex)
my @urlencode_valid;
$urlencode_valid[ord $_]=$_ foreach (split('', $URLENCODE_VALID));

for (0..255)
{
	next if $urlencode_valid[$_];
	$urlencode_valid[$_]=sprintf("%%%02X", $_);
}


sub url_encode
{
	my $toencode = shift;
	return join('', map { $urlencode_valid[ord $_] } split('', $toencode));
}

sub url_decode
{
	my $toencode = shift;
	url_decode_($toencode);#=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg; # URL decode
	return $toencode;
}

sub url_decode_ {$_[0]=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;}

#
#	CODING
#

sub hash_encode
{
	my $link=shift;
	my $key_name=shift;
	
	if ($key_name && $tom::code_keys{$key_name}{key})
	{
		# okay, nechavam si keyname co som si poslal natvrdo
	}
	elsif ($TOM::engine eq "pub")
	{
		# idem sa rozhodovat aky kluc pouzijem
		if (not $TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{agent_type}=~/browser/)
		{
			#$key_name=$tom::code_keys{$tom::code_key_root}{key};
			$key_name=$tom::code_key_root;
		}
		else
		{
			$key_name=$tom::type_code[int(rand(@tom::type_code))];
		}
	}
	else
	{
		# inak pouzijem root kluc
		#$key_name=$tom::code_keys{$tom::code_key_root}{key};
		$key_name=$tom::code_key_root;
	}
	
	if ($link)
	{
		$link=enc3::xor($link,$tom::code_keys{$key_name}{key});
		$link=MIME::Base64::encode_base64($link);
		$link=~s|[\n\r]||;
		$link=~s|==$||;
		$link=TOM::Net::URI::URL::url_encode($link) if $link; # hex encoding
		$link="__".$link."-".$key_name."-v3";
	}
	
	return $link;
}

# generate GET line from %hash
sub genGET
{
	my $t0=track TOM::Debug(__PACKAGE__."::genGET()");
	my %form=@_;
	my $GET;
	foreach (sort keys %form)
	{
		next unless $form{$_};
		next if length($form{$_})>1024;
#		main::_log("'$_'='$form{$_}'");
		$GET.="$_=".url_encode($form{$_})."&";
	}
	$GET=~s|&$||;
	
	main::_log("output '$GET'");
	$t0->close();
	return $GET;
}


sub exclude
{
	my $URI=shift;
	my @vars=@_;
	
	my %form=TOM::Net::HTTP::CGI::GetQuery($URI,'-lite'=>1);
	foreach (@vars)
	{
		delete $form{$_};
	}
	$URI=genGET(%form);
	
	return $URI;
}


#$ENV{'QUERY_STRING'}=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg; # URL decode

1;