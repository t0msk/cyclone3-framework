package TOM::L10n;

=head1 NAME

TOM::L10n

=head1 DESCRIPTION

Localization management

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

use File::Path;
use XML::XPath;
use XML::XPath::XMLParser;
use TOM::L10n::codes;

our $debug=$main::debug || 0;
our $stats||=0;
our %objects;
our $id;

=head1 new

 my $L10n=TOM::L10n::new(
  'level' => "auto", # auto/local/master/global, default is 'auto'
  #'addon' => "a400",
  #'name' => "email-stats", # default is 'default'
  #'lng' => "en-US" # default is 'en-US'
 )

Print string

 print $L10n->{'string'}{$string};

Map directly to hash

 my %L10n=%{new TOM::L10n('lng' => "sk-SK")->{'string'}};
 print $L10n{$string};

L10n source can be as

 everything.L10n # this is xml file

=cut

sub new
{
	my $class=shift;
	my %env=@_;
	undef $env{'lng'} if $env{'lng'} eq "auto";
	TOM::L10n::codes::trans($env{'lng'});
	$env{'lng'}="en-US" unless $env{'lng'};
	$env{'level'}="auto" unless $env{'level'};
	$env{'name'}="default" unless $env{'name'};
	my $t=track TOM::Debug(__PACKAGE__."->new($env{'level'}/$env{'addon'}/$env{'name'}.$env{'lng'})") if $debug;
	
	my $obj=bless {}, $class;
	
	foreach my $key(keys %env)
	{
		main::_log("input '$key'='$env{$key}'") if $debug;
	}
	
	# add params into object
	%{$obj->{'ENV'}}=%env;
	$obj->{'string'}={};
	$obj->{'string_'}={};
	
	# find where is the source file/files
	$obj->prepare_location();
	if (!$obj->{'location'})
	{
		main::_log("can't create L10n object",1) if $debug;
		$t->close() if $debug;
		return undef;
	}
	$obj->{'uid'}=$obj->{'location'}.'/'.$env{'lng'};
	
	# modifytime of location
	$obj->{'config'}->{'mtime'} = (stat($obj->{'location'}))[9];
	
#	main::_log("trying '$obj->{'uid'}' in mem=".do{if($objects{$obj->{'uid'}}){"1"}}." no-cache=".$env{'no-cache'},3,"l10n");
	
	my $object={};
		$object=$objects{$obj->{'uid'}}
			unless $env{'no-cache'};
	
	if (!$object && $TOM::CACHE_memcached && $main::cache)
	{
		# try memcached
		$object = 
			$Ext::CacheMemcache::cache->get(
				'namespace' => "l10ncache",
				'key' => $TOM::P_uuid.':'.$obj->{'uid'}
			);
	}
	
	if ($object && ($obj->{'config'}->{'mtime'} > $object->{'config'}->{'mtime'} || !$main::cache))
	{
		main::_log("{L10n} '$obj->{'location'}' expired, modified before ".( $obj->{'config'}->{'mtime'}-$object->{'config'}->{'mtime'} )."s");
		undef $object;
	}
	
	# check if same location is already loaded in another object
	# (location is unique identification of L10n)
	# when no, proceed parsing this L10n source
	if (!$object)
	{
		main::_log("<={L10n} '$obj->{'location'}'/'$obj->{'ENV'}->{'lng'}'");# if $debug;
		# add this object into global $TOM::L10n::objects{} hash
		$object=$obj;
		$id++;$L10n::id{$obj->{'uid'}}=$id; # add unique number to every one object
		$obj->{'id'}=$id;
		# add this location into ignore list
		push @{$obj->{'ENV'}->{'ignore'}}, $obj->{'uid'};
		$obj->prepare_xml();
		$obj->{'config'}->{'mtime'}=(stat( $obj->{'location'} ))[9];
		$obj->parse_header();
		$obj->parse_string();
	}
	else
	{
		main::_log("<={L10n}{cache".(do{
			if ($objects{$obj->{'uid'}} && !$env{'no-cache'})
			{
				":mem";
			}
		})."} '$obj->{'location'}'/'$obj->{'ENV'}->{'lng'}'") if $debug;
#		main::_log("load cached L10n ".$obj->{'uid'});
		
		$objects{$obj->{'uid'}}=$object
			unless $env{'no-cache'};
		
		$t->close() if $debug;
		return $object;
	}
	
	# create copy of object to return it as unique
	# this is important to allow changing variables
	# without affecting original objects
	
	my $obj_return=bless {}, $class;
		$obj_return->{'location'}=$obj->{'location'};
		$obj_return->{'uid'}=$obj->{'uid'};$obj_return->{'id'}=$obj->{'id'};
		%{$obj_return->{'ENV'}}=%env;
		if ($obj->{'location'})
		{
			%{$obj_return->{'string'}}=%{$object->{'string'}};
			%{$obj_return->{'string_'}}=%{$object->{'string_'}};
			# recovery header config to new object
			%{$obj_return->{'config'}}=%{$object->{'config'}};
		}
		%L10n::string=%{$object->{'string'}};
		# replace_variables only in root level of L10n not in l10n's called by <extend*>
		$obj_return->process_string() if (caller)[0] ne "TOM::L10n";
		my $i;
		my $id=$L10n::id{$obj->{'uid'}}; # get unique number of object
		
		# create a copy of actual strings into public
		# obsolete, remove it as soon as possible
		foreach (sort keys %L10n::string)
		{
			$i++;
			#main::_log('#'.$obj->{'id'}.'#'.$i);
			$L10n::num{'#'.$obj->{'id'}}{$_}=$i;
			$L10n::obj{'#'.$obj->{'id'}.'#'.$i}=$L10n::string{$_};
		}
	
	if ($TOM::CACHE_memcached && !$env{'no-cache'})
	{
		$objects{$obj->{'uid'}}=$object;
		$Ext::CacheMemcache::cache->set(
			'namespace' => "l10ncache",
			'key' => $TOM::P_uuid.':'.$obj->{'uid'},
			'value' => $obj_return,
			'expiration' => '3600S'
		);
	}
	
	$t->close() if $debug;
	return $obj_return;
}

sub TO_JSON { return { %{ shift() } }; }

=head1 METHODS



=cut


sub prepare_location
{
	my $self=shift;
	
	return $self->{'location'} if $self->{'location'};
	
	# get list of possible dirs
	my @dirs=get_L10n_dirs
	(
		'level' => $self->{'ENV'}->{'level'},
		'addon'=> $self->{'ENV'}->{'addon'}
	);
	
	foreach (@dirs)
	{
		main::_log("dir='$_'") if $debug;
		
		$self->{'location'}=$_.'/'.$self->{'ENV'}->{'name'}.'.L10n';
		
		if (-e $self->{'location'})
		{
			foreach my $ignore_dir (@{$self->{'ENV'}->{'ignore'}})
			{
				#main::_log("check ignore dir='$ignore_dir' to '$self->{'location'}'");
				if ($self->{'location'}.'/'.$self->{'ENV'}->{'lng'} eq $ignore_dir)
				{
					undef $self->{'location'};
					last;
				}
			}
		}
		else
		{
			undef $self->{'location'};
		}
		
		last if $self->{'location'};
	}
	
	if (!$self->{'location'})
	{
		main::_log("can't find location for L10n '".$self->{'ENV'}->{'name'}.".".$self->{'ENV'}->{'lng'}."' (L10n not exists, or already loaded as dependency)",1);
		return undef;
	}
	else
	{
#		main::_log("XML '$self->{'location'}'");# if $debug;
#		main::_log("<={L10n} '$self->{'location'}'/'$self->{'ENV'}->{'lng'}'");# if $debug;
	}
	
	return $self->{'location'};
}



sub prepare_xml
{
	my $self=shift;
	
	$self->{'xp'} = XML::XPath->new(filename => $self->{'location'});
	
}



sub parse_header
{
	my $self=shift;
	
	my $nodeset = $self->{'xp'}->find('/L10n/header/*'); # find all items
	
	foreach my $node ($nodeset->get_nodelist)
	{
		my $name=$node->getName();
		#main::_log("node '$name'");
		
		if ($name eq "extend")
		{
			# level, name, addon, lng
			my $level=$node->getAttribute('level');
			my $addon=$node->getAttribute('addon');
			my $name=$node->getAttribute('name');
			my $lng=$node->getAttribute('lng');
			$lng=$self->{'ENV'}->{'lng'} unless $lng;
			$lng=$self->{'ENV'}->{'lng'} if $lng eq "auto";
			
			main::_log("request to extend by level='$level' addon='$addon' name='$name' lng='$lng'") if $debug;
			
			my $extend=new TOM::L10n(
				'level' => $level,
				'addon' => $addon,
				'name' => $name,
				'lng' => $lng,
				'ignore' => $self->{'ENV'}{'ignore'},
				'no-cache' => 1
			);
			
			# add entries from inherited L10n
			foreach (keys %{$extend->{'string'}})
			{
#				print "set $_\n";
				$self->{'string'}{$_}=$extend->{'string'}{$_};
				$self->{'string_'}{$_}=$extend->{'string_'}{$_};
			}
			
			next;
		}
		
	}
	
	
}



sub parse_string
{
	my $self=shift;
	
	my $nodeset = $self->{'xp'}->find('/L10n/string'); # find all strings
	
	my @strs;
	
	foreach my $node ($nodeset->get_nodelist)
	{
		my $name=$node->getName();
		
		if ($node->getAttribute('disabled') eq "true")
		{
			next;
		}
		
		my $id=$node->getAttribute('id');
		
		if (!$id)
		{
			my $nodeset2 = $node->find('en-US');
			my $node2=($nodeset2->get_nodelist())[0];
			$id=$node2->string_value();
		}
		
		if ($node->getAttribute('automap') eq "true")
		{
#			main::_log("setup string id='$id' automap") if $debug;
			$self->{'string'}{$id}=$id;
		}
		else
		{
			my $nodeset2 = $node->find($self->{'ENV'}{'lng'}); # find all strings
			if (my $node2=($nodeset2->get_nodelist())[0])
			{
				$self->{'string'}{$id}=$node2->string_value();
			}
			elsif ($self->{'ENV'}{'lng'} eq "en-US")
			{
				$self->{'string'}{$id}="{".$id."}";
			}
			else
			{
#				main::_log("missing string '" . $id . "' in laguage code '" . $self->{'ENV'}{'lng'} . "' L10n def '" . $self->{'location'} . "'" , 4 , 'L10n');
				$self->{'string'}{$id}="{".$id."}";
			}
			
#			main::_log("setup string id='$id' with length(".(length($self->{'string'}{$id})).")") if $debug;
		}
		
		$self->{'string_'}{$id}{'replace_variables'}=$node->getAttribute('replace_variables');
		$self->{'string_'}{$id}{'location'}=$self->{'location'};
		push @strs, $id;
	}
	
#	main::_log("strings '".(join "','",@strs)."'") unless $debug;
	
}



sub process_string
{
	my $self=shift;
	
	foreach my $string (keys %{$self->{'string'}})
	{
		if ($self->{'string_'}{$string}{'replace_variables'} eq "true")
		{
			main::_log("replace_variables in string '$string'") if $debug;
			TOM::Utils::vars::replace($self->{'string'}{$string});
		}
	}
	
}


=head1 FUNCTIONS



=cut

sub get_L10n_dirs
{
	my %env=@_;
	
	my @dirs;
	my $subdir;
	
	# find this L10n
	if ($env{'addon'})
	{
		if ($env{'addon'}=~s/^a//)
		{
			$subdir="_addons/App/".$env{'addon'}."/_dsgn";
		}
		elsif ($env{'addon'}=~s/^e//)
		{
			$subdir="_addons/Ext/".$env{'addon'}."/_dsgn";
		}
	}
	else
	{
		$subdir="_dsgn";
	}
	
	if ($env{'level'} eq "auto")
	{
		# local
		push @dirs,$tom::P."/".$subdir if $tom::P;
		# master
		push @dirs,$tom::Pm."/".$subdir if ($tom::Pm && $tom::Pm ne $tom::P);
	}
	elsif ($env{'level'} eq "local")
	{
		# master
		push @dirs,$tom::P."/".$subdir if $tom::P;
	}
	elsif ($env{'level'} eq "master")
	{
		# master
		push @dirs,$tom::Pm."/".$subdir if $tom::Pm;
	}
	# else
	
	# overlays
	main::_log("allowed overlays=$env{'overlays'}") if $debug;
	foreach (@TOM::Overlays::item)
	{
		push @dirs,$TOM::P."/_overlays/".$_."/".$subdir;
	}
	
	# global (backup for every option)
	push @dirs,$TOM::P."/".$subdir;
	
	return @dirs;
}


1;
