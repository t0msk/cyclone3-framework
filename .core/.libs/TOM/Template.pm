package TOM::Template;

=head1 NAME

TOM::Template

=head1 DESCRIPTION

Templates management

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

use XML::XPath;
use XML::XPath::XMLParser;

our %objects;

=head1 new

 my $tpl=TOM::Template::new(
  'level' => "global", # auto/local/master/global
  #'addon' => "a400",
  #'name' => "email-stats",
  'content-type' => "xhtml" # default is XML
 )

tpl moze byt ako
	nieco.content-type.tpl # this is xml file
	nieco.content-type.tpl.d/_init.xml
	nieco.content-type.ztpl # this is zipped directory


=cut

sub new
{
	my $class=shift;
	my $self={};
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."->new($env{'level'}/$env{'addon'}/$env{'name'}.$env{'content-type'})");
	
	my $obj=bless $self, $class;
	
	foreach my $key(keys %env)
	{
		main::_log("input '$key'='$env{$key}'");
	}
	
	$env{'content-type'}="xml" unless $env{'content-type'};
	$env{'level'}="auto" unless $env{'level'};
	
	# add params into object
	%{$obj->{'ENV'}}=%env;
	
	# find where is the source file/files
	$obj->prepare_location();
	
	# check if same location is already loaded in another object
	# (location is unique identification of template)
	# when yes, return reference to this object
	if ($objects{$obj->{'location'}})
	{
		main::_log("returning cached object");
		$t->close();
		return $objects{$obj->{'location'}};
	}
	
	# add this object into global $TOM::Template::objects{} hash
	$objects{$obj->{'location'}}=$obj;
	
	# add this location into ignore list
	push @{$self->{'ENV'}->{'ignore'}}, $obj->{'location'};
	$obj->prepare_xml();
	$obj->parse_header();
	$obj->parse_entry();
	
	$t->close();
	return $obj;
}

=head1 METHODS



=cut


sub prepare_location
{
	my $self=shift;
	
	return $self->{'location'} if $self->{'location'};
	
	# get list of possible dirs
	my @dirs=get_tpl_dirs
	(
		'level' => $self->{'ENV'}->{'level'},
		'addon'=> $self->{'ENV'}->{'addon'}
	);
	
	foreach (@dirs)
	{
		main::_log("dir='$_'");
		
		# 
		$self->{'location'}=get_tpl_xml
		(
			'dir' => $_,
			'filename' => $self->{'ENV'}->{'name'}.".".$self->{'ENV'}->{'content-type'}
		);
		
		if ($self->{'location'})
		{
			foreach my $ignore_dir (@{$self->{'ENV'}->{'ignore'}})
			{
				#main::_log("check ignore dir='$ignore_dir' to '$self->{'location'}'");
				if ($self->{'location'} eq $ignore_dir)
				{
					undef $self->{'location'};
					last;
				}
			}
		}
		
		last if $self->{'location'};
	}
	
	if (!$self->{'location'})
	{
		main::_log("this Template not exists",1);
	}
	else
	{
		main::_log("xml location '$self->{'location'}'");
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
	
	my $nodeset = $self->{'xp'}->find('/template/header/*'); # find all items
	
	foreach my $node ($nodeset->get_nodelist)
	{
		my $name=$node->getName();
		#main::_log("node '$name'");
		
		if ($name eq "extend")
		{
			# level, name, addon, content-type
			my $level=$node->getAttribute('level');
			my $addon=$node->getAttribute('addon');
			my $name=$node->getAttribute('name');
			my $content_type=$node->getAttribute('content-type');
			$content_type=$self->{'ENV'}->{'content-type'} unless $content_type;
			
			main::_log("request to extend by level='$level' addon='$addon' name='$name' content-type='$content_type'");
			
			my $extend=new TOM::Template(
				'level' => $level,
				'addon' => $addon,
				'name' => $name,
				'content-type' => $content_type,
				'ignore' => $self->{'ENV'}{'ignore'}
			);
			
			foreach (keys %{$extend->{'entry'}})
			{
				$self->{'entry'}{$_}=$extend->{'entry'}{$_};
			}
			
			next;
		}
		
	}
	
	
	my $nodeset = $self->{'xp'}->find('/template/header/extract/*'); # find all extract items
	
	foreach my $node ($nodeset->get_nodelist)
	{
		my $name=$node->getName();
		#main::_log("extract '$name'");
		
		if ($name eq "file")
		{
			my $location=$node->getAttribute('location');
			my $replace_variables=$node->getAttribute('replace_variables');
			
			main::_log("extract file '$location' replace_variables='$replace_variables'");
			#my $level=$node->getAttribute('level');
			
			next;
		}
		
	}
	
	
	
	
}



sub parse_entry
{
	my $self=shift;
	
	my $nodeset = $self->{'xp'}->find('/template/entry'); # find all entries
	
	foreach my $node ($nodeset->get_nodelist)
	{
		my $name=$node->getName();
		my $id=$node->getAttribute('id');
		$self->{'entry'}{$id}=XML::XPath::XMLParser::as_string($node);
		main::_log("setup entry id='$id' with length(".(length($self->{'entry'}{$id})).")");
	}
	
}


=head1 FUNCTIONS



=cut

sub get_tpl_dirs
{
	my %env=@_;
	
	my @dirs;
	my $subdir;
	
	# find this tpl
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
	main::_log("allowed overlays=$env{'overlays'}");
	foreach (@TOM::Overlays::item)
	{
		push @dirs,$TOM::P."/_overlays/".$_."/".$subdir;
	}
	
	# global (backup for every option)
	push @dirs,$TOM::P."/".$subdir;
	
	return @dirs;
}


sub get_tpl_xml
{
	my %env=@_;
	
	foreach my $ext(".ztpl",".tpl.d/_init.xml",".tpl")
	{
		my $filename="$env{'dir'}/$env{'filename'}$ext";
		#main::_log("find $env{'dir'}/$env{'filename'}$ext");
		
		# if checking ztpl, unpack them into .tpl.d extension and return included xml
		
		return $filename if -e $filename;
	}
	
	return undef;
}



1;