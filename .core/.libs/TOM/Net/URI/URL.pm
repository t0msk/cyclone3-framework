package TOM::Net::URI::URL;

=head1 NAME

TOM::Net::URI::URL

=head1 DESCRIPTION

URL functions

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use Encode;
use bytes;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<TOM::Net::HTTP::CGI|source-doc/".core/.libs/TOM/Net/HTTP/CGI.pm">

=back

=cut

use TOM::Net::HTTP::CGI;

our $debug=0;

# List of valid characters in QUERY_STRING
my $URLENCODE_VALID = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.";

# Prepare list of valid and invalid characters (hex)
my @urlencode_valid;
	$urlencode_valid[ord "$_"]="$_" foreach (split('', $URLENCODE_VALID));
	$urlencode_valid[ord " "]="+"; # translate all spaces to '+' characters
for (0..255)
{
	next if defined $urlencode_valid[$_];
	$urlencode_valid[$_]=sprintf("%%%02X", $_);
}



=head1 FUNCTIONS

=head2 url_encode()

Return encoded part of a string

 my $string=TOM::Net::URI::URL::url_encode('string');

=cut

sub url_encode
{
	my $toencode = shift;
	my $out=join('', map { $urlencode_valid[ord "$_"] } split('', $toencode));
	main::_log("url_encode '$toencode'->'$out'") if $debug;
	return $out;
}

sub url_var_encode
{
	my $toencode = shift;
	$toencode=~s|["><=]||g;
	return url_encode($toencode);
}



=head2 url_decode()

Return decoded part of a string

 my $string=TOM::Net::URI::URL::url_decode('string');

=cut

sub url_decode
{
	my $toencode = shift;
	url_decode_($toencode);#=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg; # URL decode
	return $toencode;
}



=head2 url_decode_()

Decode given variable

 TOM::Net::URI::URL::url_decode_($string);

=cut

sub url_decode_
{
	$_[0]=~s|\+| |g;
	$_[0]=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
}



=head2 hash_encode()

From given QUERY_STRING, creates hashed QUERY_STRING in form: ?__${hash}-${code}-v3

 my $query_hashed=TOM::Net::URI::URL::hash_encode('variable=value&variable2=value2');

=cut

sub hash_encode
{
	my $link=shift;
	my $key_name=shift;
	
=head1
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
=cut
	
	if ($link)
	{
		$link=MIME::Base64::encode_base64($link);
		$link=~s|[\n\r]||;
		$link=~s|==$||;
		$link=TOM::Net::URI::URL::url_encode($link) if $link; # hex encoding
#		$link="__".$link."-".$key_name."-v3";
		$link="__".$link."-v4";
	}
	
	return $link;
}



=head2 genGET()

From given %hash generates QUERY_STRING

 my $query_string=TOM::Net::URI::URL::genGET(%hash);

=cut

sub genGET
{
	my $t0=track TOM::Debug(__PACKAGE__."::genGET()") if $debug;
	my %form=@_;
	my $GET;
	
	if ($App::210::path2name && $form{'a210_path'})
	{
		$form{'a210_name'}=$form{'a210_path'};
		delete $form{'a210_path'};
		$form{'a210_name'}=~s|^.*/||;
	}
	
	if ($form{'a210_ID'})
	{
		delete $form{'a210_path'};
		delete $form{'a210_name'};
		require App::210::_init;
		my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
		my %sth0=TOM::Database::SQL::execute(qq{SELECT ID,name_url FROM `$App::210::db_name`.a210_page WHERE ID_entity = ? AND lng = ? LIMIT 1},
			'bind'=>[$form{'a210_ID'},($form{'__lng'} || $tom::lng)],
			'-slave' => 1,
			'-cache' => 600,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%sql_def),
			'-quiet' => 1);
		my %page=$sth0{'sth'}->fetchhash();
		if ($App::210::path2name)
		{
			$form{'a210_name'} = $page{'name_url'};
		}
		else
		{
			foreach my $p(
				App::020::SQL::functions::tree::get_path(
					$page{'ID'},
					%sql_def,
					'columns' => { '*' => 1 },
					'-slave' => 1,
					'-cache' => 600
				)
			)
			{
				$form{'a210_path'}.="/".$p->{'name_url'};
			}
			$form{'a210_path'}=~s|^/||;
		}
		delete $form{'a210_ID'};
	}
	
	foreach (sort keys %form)
	{
		next if $_ eq "multipart";
		next if $_=~/_file$/;
		
		next if (!$form{$_} && $form{$_} ne "0");
		next if length($form{$_})>1024;
		
		if ($_=~/\[\]$/ && ref($form{$_}) eq "ARRAY")
		{
			foreach my $arr_val(@{$form{$_}})
			{
				next if (!$arr_val && $arr_val ne "0");
				next if length($arr_val)>1024;
				$GET.="$_=".url_encode($arr_val)."&";
			}
		}
		else
		{
			$GET.=url_var_encode($_)."=".url_encode($form{$_})."&";
		}
	}
	$GET=~s|&$||;
	
	main::_log("output '$GET'") if $debug;
	$t0->close() if $debug;
	return $GET;
}



=head2 exclude()

From given QUERY_STRING deletes list of variables

 my $query_string=TOM::Net::URI::URL::exclude($QUERY_STRING,'variable','variable2');

=cut

sub exclude
{
	my $URI=shift;
	my @vars=@_;
	
	my %form=TOM::Net::HTTP::CGI::get_QUERY_STRING($URI);
	foreach (@vars)
	{
		delete $form{$_};
	}
	$URI=genGET(%form);
	
	return $URI;
}

=head1 SEE ALSO

L<TOM::Net::HTTP::CGI|source-doc/".core/.libs/TOM/Net/HTTP/CGI.pm">

=cut

=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut


1;
