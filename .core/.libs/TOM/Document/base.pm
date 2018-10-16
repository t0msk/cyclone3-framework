package TOM::Document::base;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

use List::MoreUtils qw(uniq);

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use vars qw{$AUTOLOAD};

our $url_relative_disable = $TOM::Document::base::url_relative_disable || 0;

$TOM::Document::base::copyright||=qq{  This service is powered by Cyclone3 v$TOM::core_version - professionals for better internet.
  Cyclone3 is a free open source Application Framework initially developed by Comsultia and licensed under GNU/GPLv2.
  Addons and overlays are copyright of their respective owners.
  Information and contribution at http://www.cyclone3.org} unless defined $TOM::Document::base::copyright;

$TOM::Document::frame_options||="ALLOWALL";

sub message
{
	my $self=shift;
	foreach (@_)
	{
		$self->a("<!-- ".$_." -->");
	}
}

sub add_obj {
	my $self=shift;
	my $obj=shift;
#	push @{$self->{'env'}->{'obj'}},$obj;
	@{$self->{'env'}->{'obj'}}=uniq(@{$self->{'env'}->{'obj'}},$obj);
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
	#return undef unless 
	my $code=shift;
	return undef unless $self->{OUT}{BODY}=~s|$what|$code|g;
	return 1;
}

sub r_ # replace next
{
	my $self=shift;
	return undef unless my $what=shift;
	return undef unless my $code=shift;
	return undef unless $self->{OUT}{BODY}=~s|$what|$code$what|g;
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


sub OUT_ # get cleaned code
{
	my $self=shift;
	$self->{'OUT'}{'BODY'}=~s|<%.*?%>||gs;
	$self->{'OUT'}{'BODY'}=~s|<#.*?#>||gs;
	$self->{'OUT'}{'BODY'}=~s|<![^-].*?!>||g;# unless $main::IAdm;
	$self->{'OUT'}{'BODY'}=~s|<!---->||g;# unless $main::IAdm;
	$self->{'OUT'}{'HEADER'}=~s|<%.*?%>||gs;
	$self->{'OUT'}{'HEADER'}=~s|<#.*?#>||gs;
	$self->{'OUT'}{'HEADER'}=~s|<!.*?!>||g;# unless $main::IAdm;
	1 while ($self->{'OUT'}{'BODY'}=~s|\n$||g);
	my $doc=$self->{'OUT'}{'HEADER'}.$self->{'OUT'}{'BODY'}.$self->{'OUT'}{'FOOTER'};
	1 while ($doc=~s|\n\n$|\n|g);
	if (@pub::DOC_HTTPS_autoreplace && $main::ENV{'HTTPS'} eq "on")
	{
		main::_log("autoreplace HTTPS",3,"debug");
		foreach my $replace (@pub::DOC_HTTPS_autoreplace)
		{
			use Data::Dumper;
#			main::_log(" replace=".Dumper($replace),3,"debug");
			main::_log(" $replace->[0] -> $replace->[1]",3,"debug");
			$doc=~s|$replace->[0]|$replace->[1]|gm;
#			main::_log(" $_='$main::ENV{$_}'",3,"debug");
		}
	}
	utf8::decode($doc) unless utf8::is_utf8($doc);
	return $doc;
}


sub AUTOLOAD
{
	my $self = shift;
	my $name = $AUTOLOAD;
	main::_log("Unknown TOM::Document method '$name'");
}


sub DESTROY
{
	my $self=shift; 
	$self={};
}


sub url_generate
{
	my %form_in;
	
	if (!ref($_[0]))
	{
		%form_in=TOM::Net::HTTP::CGI::get_QUERY_STRING($_[0],'quiet'=>1);
	}
	else
	{
		%form_in=%{$_[0]};
	}
	
	$tom::H_www_orig=$tom::H_www unless $tom::H_www_orig;
	$tom::H_www_external=0; # tato linka je externa?
	my $debug_url=0;
	
	my %form;
	# pridam systemovo posielane premenne __nieco
	foreach (keys %main::FORM){$_=~/^__/ && do{$form{$_}=$main::FORM{$_};};}
	
	my %form_array; # only statuses
	
	my $split_by='&';
		$split_by='&amp;';# if $link=~/&amp;/; # preffered
	
	foreach my $cc(keys %form_in)
	{
		if (!$form_in{$cc})
		{
			delete $form{$cc};
			next;
		}
		$form{$cc}=$form_in{$cc};
	}
	
	# POSLEDNE UPRAVY
	delete $form{_dsgn} if $form{_dsgn} eq $tom::dsgn_;
	delete $form{_lng} if $form{_lng} eq $tom::lng_;
	
	my $newlink_prefix='';
	if ($tom::rewrite)
	{
		$newlink_prefix=$tom::H_www."/";
	}
	else
	{
	}
	
	# spracujem %form este cez rewrite a mozno z %form budu este vyhodne
	# nadbytocne veci
	if ($tom::rewrite)
	{
		my ($rewrite_domain,$rewrite)=TOM::Net::URI::rewrite::parse_hash(\%form);
		main::_log("dom=$rewrite_domain url=$rewrite") if $debug_url;
		
		if ($rewrite_domain) # we are linking to external domain
		{
			$newlink_prefix=$rewrite_domain."/";
			$tom::H_www_external=1;
		}
		
		if ($rewrite)
		{
			# REWRITE TREBA DECODOVAT!!!
			$rewrite=TOM::Net::URI::URL::url_encode($rewrite);
			$rewrite=~s|%2F|/|g;
			$newlink_prefix.=$rewrite;
		}
	}
	
	main::_log("URL newlink_prefix='$newlink_prefix'") if $debug_url;
	
	# vygenerujem z %hash string
	my $link;
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
		)
	{
		my $link_hash=TOM::Net::URI::URL::hash_encode($link);
		main::_log("output URL '$newlink_prefix?$link_hash'") if $debug_url;
		return "$newlink_prefix?$link_hash";
	}
	
	# pokial nekodujem linku, tak oddelovace premennych '&' musia byt v linke
	# v HTML kode ako &amp; (je to tak podla standardov)
	$link=~s|&|&amp;|g unless $TOM::type_code;
	
	if ($tom::H_www ne $tom::H_www_orig) # ak som na alternativnej subdomene
	{
		if ($tom::H_www_external)
		{
			# ak je linka mimo hlavnej domeny, tak ju nechavam ako je
		}
		else
		{
			# vsetky ostatne linky smeruju na orig domenu
			$newlink_prefix=~s/(https?:\/\/)(.*?)\//$tom::H_www_orig.'\/'/e;
		}
	}
	else
	{
		
	}
	
	# mozem si dovolit optimalizovat linku na relativnu
#	if ($newlink_prefix=~/^$tom::H_www\//)
#	{
#		$newlink_prefix=~s/^$tom::H_www//;
#	}
	
	if ($tom::rewrite && !$link) # link je prazdny (titulka)
	{
		main::_log("output URL '$newlink_prefix'") if $debug_url;
		return "$newlink_prefix";
	}
	else
	{
		main::_log("output URL '$newlink_prefix?$link'") if $debug_url;
		return "$newlink_prefix?$link";
	}
	
}


sub doc_url_replace
{
	my $doc=$_[0];shift;
	my $data=shift;
	
	local $TOM::Document::base::url_relative_disable=1;
	
	local %main::FORM;
	$main::FORM{'__lng'}=$data->{'form'}->{'__lng'} || $tom::lng;
	
	my $url_regexp=qr'(.)\?\|\?(.*?)(["\'#])';
	if (!$tom::rewrite_time && open (KEY,"<".$tom::P."/rewrite.conf"))
	{
		local $/;
		my $data=<KEY>;close(KEY);
		TOM::Net::URI::rewrite::get($data);close(KEY);$tom::rewrite=1;
		
		$tom::rewrite_time=time;
	}
	
	$$doc=~s/$url_regexp/TOM::Document::base::url_replace($1,$2,$3)/eg;
	
#	print $$doc;
}

sub url_replace
{
	my $url_cache_enabled=0;
	my $debug_url=0;
	
	$tom::H_www_orig=$tom::H_www unless $tom::H_www_orig;
	$tom::H_www_external=0; # tato linka je externa?
	
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
#	$link=~s|&amp;|&|g;
	
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
	
	my $split_by='&';
		$split_by='&amp;' if $link=~/&amp;/; # preffered
	
	foreach my $cc(split($split_by,$link))
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
	
	# path2name
	if ($App::210::path2name && $form{'a210_path'})
	{
		$form{'a210_name'}=$form{'a210_path'};
		delete $form{'a210_path'};
		$form{'a210_name'}=~s|^.*/||;
	}
	
	# spracujem %form este cez rewrite a mozno z %form budu este vyhodne
	# nadbytocne veci
	if
	(
		($newlink_prefix ne "http://null/") &&
		($tom::rewrite)
	)
	{
		my ($rewrite_domain,$rewrite)=TOM::Net::URI::rewrite::parse_hash(\%form);
		main::_log("dom=$rewrite_domain url=$rewrite") if $debug_url;
		
		if ($rewrite_domain) # we are linking to external domain
		{
			$newlink_prefix=$rewrite_domain."/";
			$tom::H_www_external=1;
		}
		
		if ($rewrite)
		{
			# REWRITE TREBA DECODOVAT!!!
			$rewrite=TOM::Net::URI::URL::url_encode($rewrite);
			$rewrite=~s|%2F|/|g;
			$newlink_prefix.=$rewrite;
		}
	}
	
	main::_log("URL newlink_prefix='$newlink_prefix'") if $debug_url;
	
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
	
	if ($tom::H_www ne $tom::H_www_orig) # ak som na alternativnej subdomene
	{
		if ($tom::H_www_external)
		{
			# ak je linka mimo hlavnej domeny, tak ju nechavam ako je
		}
		else
		{
			# vsetky ostatne linky smeruju na orig domenu
			$newlink_prefix=~s/(https?:\/\/)(.*?)\//$tom::H_www_orig.'\/'/e;
		}
	}
	else
	{
		
	}
	
	# mozem si dovolit optimalizovat linku na relativnu
	if ($newlink_prefix=~/^$tom::H_www\// && $link_end eq '"' && !$TOM::Document::base::url_relative_disable)
	{
		if ($tom::H_www_by_HTTP_HOST || (
			$newlink_prefix=~/^https?:\/\/$main::ENV{'HTTP_HOST'}/
		))
		{
			$newlink_prefix=~s/^http[s]?:\/\/.*?\//\//;
		}
	}
	
	if ($tom::rewrite && !$link) # link je prazdny (titulka)
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
