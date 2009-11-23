package Net::DOC::base;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use vars qw{$AUTOLOAD};



sub message
{
	my $self=shift;
	foreach (@_)
	{
		$self->a("<!-- ".$_." -->");
	}
}



sub i # insert at begin
{
	my $self=shift;
	return undef unless my $code=shift;
	$self->{OUT}{BODY} = $code . "\n" . $self->{OUT}{BODY};
	return 1;
}

sub rh # replace only in header
{
	my $self=shift;
	return undef unless my $what=shift;
	return undef unless my $code=shift;
	return undef unless $self->{OUT}{HEADER}=~s|$what|$code|g;
	return 1;
}

sub r # replace
{
	my $self=shift;
	return undef unless my $what=shift;
	return undef unless my $code=shift;
	return undef unless $self->{OUT}{BODY}=~s|$what|$code|g;
	return 1;
}

sub r_ # replace next
{
	my $self=shift;
	return undef unless my $what=shift;
	return undef unless my $code=shift;
	return undef unless $self->{OUT}{BODY}=~s|$what|$code\n$what|g;
	return 1;
}


sub a # append
{
	my $self=shift;
	return undef unless my $code=shift;
	$self->{OUT}{BODY} .= "\n" . $code;
	return 1;
}


sub OUT # get full code
{
	my $self=shift;
	return $self->{OUT}{HEADER}.$self->{OUT}{BODY}.$self->{OUT}{FOOTER};
}



sub BODY # get body code
{
	my $self=shift;
	return $self->{OUT}{BODY};
}


sub OUT_ # get clean code
{
	my $self=shift;
	$self->{OUT}{BODY}=~s|<%.*?%>||gs;
	$self->{OUT}{BODY}=~s|<#.*?#>||gs;
	$self->{OUT}{BODY}=~s|<![^-].*?!>||g;# unless $main::IAdm;
	$self->{OUT}{BODY}=~s|<!---->||g;# unless $main::IAdm;
	$self->{OUT}{HEADER}=~s|<%.*?%>||gs;
	$self->{OUT}{HEADER}=~s|<#.*?#>||gs;
	$self->{OUT}{HEADER}=~s|<!.*?!>||g;# unless $main::IAdm;
	my $doc=$self->{OUT}{HEADER}.$self->{OUT}{BODY}.$self->{OUT}{FOOTER};
	1 while ($doc=~s|\n\n$|\n|g);
	utf8::decode($doc) unless utf8::is_utf8($doc);
	return $doc;
}


sub AUTOLOAD
{
	my $self = shift;
	my $name = $AUTOLOAD;
	main::_log("Unknown Net::DOC method '$name'",1);
}


sub DESTROY
{
	my $self=shift; 
	$self={};
}





sub url_replace
{
	my $url_cache_enabled=1;
	my $debug_url=0;
	
	
	my $link_begin; # character before ?|?
	my $link; # link
	my $link_end; # character after link
	
	my $newlink_prefix;
	
	if ($tom::rewrite)
	{
		$link_begin=$_[0]; # ked je www_pre='/', tak to znamena ze linkujem na iny portal
		$link=$_[1];
		$link_end=$_[2];
		$newlink_prefix=$tom::H_www."/" if $link_begin=~/['"]/;
		main::_log("URL link_begin='$link_begin' link='$link' link_end='$link_end'") if $debug_url;
	}
	else
	{
		$link=$_[0];
		$link_end=$_[1];
	}
	
	main::_log("URL newlink_prefix='$newlink_prefix'") if $debug_url;
	
	my $cache_key="$newlink_prefix".'/'."$link";
	if ($main::url_cache{$cache_key} && not $link=~/^\|/)
	{
		main::_log("URL cached for key '$cache_key'") if $debug_url;
		main::_log("output URL '$main::url_cache{$cache_key}$link_end'") if $debug_url;
		return "$link_begin$main::url_cache{$cache_key}$link_end";
	}
	
	# neviem odkial by sa tu vzali &amp;, ale pre istotu keby to niekto tymto stylom
	# zapisal do XSGN alebo DSGN
	# ide o linku v zapise ?ahoj=nieco&amp;ahoj2=nieco2&amp;...
	# ide o standardny zapis i ked my ho nepouzivame ( zatial )
	$link=~s|&amp;|&|g;
	
	my %form;
	# pridam systemovo posielane premenne __nieco
	foreach (keys %main::FORM){$_=~/^__/ && do{$form{$_}=$main::FORM{$_};};}
	#foreach (keys %form){main::_log("key $_")};
	# parsing $link to %form
	
	if ($link=~s/^\|//)
	{
		main::_log("first pipe, adding QUERY_STRING_FULL") if $debug_url;
		foreach my $cc (keys %main::pp)
		{
			$form{$cc}=$main::pp{$cc};
			main::_log("set '$cc' = '$form{$cc}'") if $debug_url;
		}
	}
	
	my %form_array; # only statuses
	foreach my $cc(split('&',$link))
	{
		my @ref=split('=',$cc);
		if (not $cc=~/=/)
		{
			delete $form{$ref[0]};
			next;
		}
		if ($ref[0]=~/\[\]$/)
		{
			delete $form{$ref[0]} unless $form_array{$ref[0]};
			$form_array{$ref[0]}++;
			push @{$form{$ref[0]}},$ref[1];
		}
		else
		{
			$form{$ref[0]}=$ref[1];
		}
#		$form{$ref[0]}=$ref[1];
	}
	
	# ochrana proti ukazaniu IAdm kluca ked dekodujem stranku v IAdm mode
	delete $form{__key} if (($main::IAdm)&&($main::FORM{_IAdm_decode}));
	delete $form{__key_} if (($main::IAdm)&&($main::FORM{_IAdm_decode}));
	delete $form{__key_file} if (($main::IAdm)&&($main::FORM{_IAdm_decode}));
	delete $form{__key} if (($main::ITst)&&($main::FORM{_ITst_decode}));
	delete $form{__key_} if (($main::ITst)&&($main::FORM{_ITst_decode}));
	delete $form{__key_file} if (($main::ITst)&&($main::FORM{_ITst_decode}));
	
	# POSLEDNE UPRAVY
	delete $form{_dsgn} if $form{_dsgn} eq $tom::dsgn_;
	delete $form{_lng} if $form{_lng} eq $tom::lng_;
	# spracujem %form este cez rewrite a mozno z %form budu este vyhodne
	# nadbytocne veci
	if
	(
		($newlink_prefix ne "http://null/")&&
		($tom::rewrite)&&
		(my $rewrite=TOM::Net::URI::rewrite::parse_hash(\%form))
	)
	{
		# REWRITE TREBA DECODOVAT!!!
		$rewrite=TOM::Net::URI::URL::url_encode($rewrite);
		$rewrite=~s|%2F|/|g;
		$newlink_prefix.=$rewrite;
	}
	
	# vygenerujem z %hash string
	$link='';
	if (keys %form > 0)
	{
		$link=TOM::Net::URI::URL::genGET(%form);
	}
	
	# nasleduje spracovanie stringu
	# aby som ho mal v zakodovanej podobe
	# idem teda kodovat
	if
		(
			($TOM::type_code) # kodujem
			&&
			($link) # v link vobec nieco je?
			&&
			(
				($main::IAdm && !$main::FORM{_IAdm_decode})
				||
				(!$main::IAdm)
			)
			&&
			(
				($main::ITst && !$main::FORM{_ITst_decode})
				||
				(!$main::ITst)
			)
		)
	{
		if (
				($main::IAdm)||($main::ITst)||($main::ENV{'HTTP_USER_AGENT'}=~/wget/i)
			)
		{
			my $link_md5=Digest::MD5::md5_hex(Encode::encode_utf8($link));
			$main::DB{sys}->Query("
				REPLACE INTO TOM._url
				(
					hash,
					url,
					inserttime
				)
				VALUES
				(
					'$link_md5',
					'$link',
					'$tom::time_current'
				)
			");
			main::_log("output URL '$newlink_prefix?__$link_md5$link_end'") if $debug_url;
			$main::url_cache{$cache_key}="$newlink_prefix?__$link_md5" if $url_cache_enabled;
			return "$link_begin$newlink_prefix?__$link_md5$link_end";
		}
		else  # klasicke kodovanie
		{
			# tomu http://null/ uz vobec nerozumiem
			$newlink_prefix="" if ($newlink_prefix eq "http://null/");
			my $link_hash=TOM::Net::URI::URL::hash_encode($link);
			main::_log("output URL '$newlink_prefix?$link_hash$link_end'") if $debug_url;
			$main::url_cache{$cache_key}="$newlink_prefix?$link_hash" if $url_cache_enabled;
			return "$link_begin$newlink_prefix?$link_hash$link_end";
		}
	}
	
	# pokial nekodujem linku, tak oddelovace premennych '&' musia byt v linke
	# v HTML kode ako &amp; (je to tak podla standardov)
	$link=~s|&|&amp;|g unless $TOM::type_code;
	$newlink_prefix="" if ($newlink_prefix eq "http://null/");
	
	if ($tom::rewrite && !$link) # nechcem zbytocne vypisovat ?
	{
		main::_log("output URL '$newlink_prefix$link_end'") if $debug_url;
		$main::url_cache{$cache_key}="$newlink_prefix" if $url_cache_enabled;
		return "$link_begin$newlink_prefix$link_end";
	}
	else
	{
		main::_log("output URL '$newlink_prefix?$link$link_end'") if $debug_url;
		$main::url_cache{$cache_key}="$newlink_prefix?$link" if $url_cache_enabled;
		return "$link_begin$newlink_prefix?$link$link_end";
	}
	
}


1;