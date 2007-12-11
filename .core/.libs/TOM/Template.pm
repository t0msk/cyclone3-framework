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

use File::Path;
use File::Copy;
use XML::XPath;
use XML::XPath::XMLParser;
use TOM::L10n;
use TOM::Template::contenttypes;

BEGIN
{
	if (!-e $tom::P.'/!media/tpl' && -e $tom::P.'/local.conf')
	{
		main::_log("mkpath '$tom::P/!media/tpl'");
		File::Path::mkpath $tom::P.'/!media/tpl';
		chmod (0777, $tom::P.'/!media/tpl');
	}
	elsif (!-e $TOM::P.'/!media/tpl')
	{
		File::Path::mkpath $TOM::P.'/!media/tpl';
		chmod (0777, $TOM::P.'/!media/tpl');
	}
}

our $debug=0;
our %objects;

=head1 new

 my $tpl=TOM::Template::new(
  'level' => "global", # auto/local/master/global
  #'addon' => "a400",
  #'name' => "email-stats",
  'content-type' => "xhtml" # default is XML
 )

tpl source can be as

	everything.content-type.tpl # this is xml file
	everything.content-type.tpl.d/_init.xml
	everything.content-type.ztpl # this is zipped directory


=cut

sub new
{
	my $class=shift;
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."->new($env{'level'}/$env{'addon'}/$env{'name'}.$env{'content-type'})");
	
	my $obj=bless {}, $class;
	
	foreach my $key(keys %env)
	{
		main::_log("input '$key'='$env{$key}'") if $debug;
	}
	
	$env{'content-type'}="xml" unless $env{'content-type'};
	TOM::Template::contenttypes::trans($env{'content-type'});
	$env{'level'}="auto" unless $env{'level'};
	
	# add params into object
	%{$obj->{'ENV'}}=%env;
	$obj->{'entity'}={};
	$obj->{'entity_'}={};
	$obj->{'L10n'}={};
	$obj->{'file'}={};
	$obj->{'file_'}={};
	
	# find where is the source file/files
	$obj->prepare_location();
	
	# check if same location is already loaded in another object
	# (location is unique identification of template)
	# when no, proceed parsing this tpl source
	if (!$objects{$obj->{'location'}})
	{
		# add this object into global $TOM::Template::objects{} hash
		$objects{$obj->{'location'}}=$obj;
		
		# add this location into ignore list
		push @{$obj->{'ENV'}->{'ignore'}}, $obj->{'location'};
		$obj->prepare_xml();
		$obj->parse_header();
		$obj->parse_entity();
	}
	
	# create copy of object to return it as unique
	# this is important to allow changing variables
	# without affecting original objects
	
	my $obj_return=bless {}, $class;
		$obj_return->{'location'}=$obj->{'location'};
		%{$obj_return->{'ENV'}}=%env;
		%{$obj_return->{'entity'}}=%{$objects{$obj->{'location'}}{'entity'}};
		%{$obj_return->{'entity_'}}=%{$objects{$obj->{'location'}}{'entity_'}};
		%tpl::entity=%{$objects{$obj->{'location'}}{'entity'}};
		%{$obj_return->{'L10n'}}=%{$objects{$obj->{'location'}}{'L10n'}};
		# replace_variables only in root level of Template not in templates called by <extend*>
		$obj_return->process_entity() if (caller)[0] ne "TOM::Template";
		%{$obj_return->{'file'}}=%{$objects{$obj->{'location'}}{'file'}};
		%{$obj_return->{'file_'}}=%{$objects{$obj->{'location'}}{'file_'}};
	$t->close();
	return $obj_return;
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
		main::_log("dir='$_'") if $debug;
		
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
		main::_log("XML '$self->{'location'}'");# if $debug;
	}
	
	
	if ($self->{'location'}=~/\/_init.xml$/)
	{
		$self->{'dir'}=$self->{'location'};
		$self->{'dir'}=~s/\/_init.xml$//;
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
			
			main::_log("request to extend by level='$level' addon='$addon' name='$name' content-type='$content_type'") if $debug;
			
			my $extend=new TOM::Template(
				'level' => $level,
				'addon' => $addon,
				'name' => $name,
				'content-type' => $content_type,
				'ignore' => $self->{'ENV'}{'ignore'}
			);
			
			# add entries from inherited tpl
			foreach (keys %{$extend->{'entity'}})
			{
				$self->{'entity'}{$_}=$extend->{'entity'}{$_};
				$self->{'entity_'}{$_}=$extend->{'entity_'}{$_};
			}
			
			# add L10n
			%{$self->{'L10n'}}=%{$extend->{'L10n'}};
			
			# add files from inherited tpl
			foreach (keys %{$extend->{'file'}})
			{
				$self->{'file'}{$_}=$extend->{'file'}{$_};
				$self->{'file_'}{$_}=$extend->{'file_'}{$_};
			}
			
			next;
		}
		elsif ($name eq "L10n")
		{
			$self->{'L10n'}{'level'}=$node->getAttribute('level');
			$self->{'L10n'}{'addon'}=$node->getAttribute('addon');
			$self->{'L10n'}{'name'}=$node->getAttribute('name');
			$self->{'L10n'}{'lng'}=$node->getAttribute('lng');
			main::_log("request to load L10n level='$self->{'L10n'}{'level'}' addon='$self->{'L10n'}{'addon'}' name='$self->{'L10n'}{'name'}' lng='$self->{'L10n'}{'lng'}'") if $debug;
		}
		
	}
	
	
	if ($self->{'dir'})
	{
		# proceed extracting files only when tpl is a tpl.d/ type
		
		my $nodeset = $self->{'xp'}->find('/template/header/extract/*'); # find all extract items
		
		foreach my $node ($nodeset->get_nodelist)
		{
			my $name=$node->getName();
			
			if ($name eq "file")
			{
				my $location=$node->getAttribute('location');
				my $replace_variables=$node->getAttribute('replace_variables');
				my $replace_L10n=$node->getAttribute('replace_L10n');
				
				main::_log("extract file '$location' from '$self->{'dir'}' replace_variables='$replace_variables' replace_L10n='$replace_L10n'") if $debug;
				
				# check if this file is not oveerided, or already exists in
				# destination directory
				
				my $src=$self->{'dir'}.'/'.$location;
				my $dst=$tom::P.'/!media/tpl/'.$location;
				
				$self->{'file'}{$location}{'src'}=$src;
				$self->{'file'}{$location}{'dst'}=$dst;
				
				if (!-e $dst)
				{
					main::_log("extract '$location'") unless $debug;
					File::Copy::copy($src, $dst);
					chmod (0666,$dst);
					#symlink($src,$dst);
					next;
				}
				
				main::_log("file '$location' already exists") if $debug;
				
				my $src_stat=(stat($src))[7];
				my $dst_stat=(stat($dst))[7];
				#main::_log("src size '$src_stat' dst size '$dst_stat'") if $debug;
				if ($src_stat ne $dst_stat)
				{
					main::_log("not same filesize, rewrite by source") if $debug;
					main::_log("extract override '$location'") unless $debug;
					File::Copy::copy($src, $dst);
					chmod (0666,$dst);
					#symlink($src,$dst);
					next;
				}
				
				next;
			}
			
		}
		
	}
	
	
}



sub parse_entity
{
	my $self=shift;
	
	my $nodeset = $self->{'xp'}->find('/template/entity'); # find all entries
	
	my @ents;
	
	foreach my $node ($nodeset->get_nodelist)
	{
		my $name=$node->getName();
		my $id=$node->getAttribute('id');
		if ($node->getAttribute('map'))
		{
			main::_log("entity id='$id' map id='".$node->getAttribute('map')."'") if $debug;
			$self->{'entity'}{$id}=$self->{'entity'}{$node->getAttribute('map')};
		}
		else
		{
			$self->{'entity'}{$id}=$node->string_value();
		}
		$self->{'entity_'}{$id}{'replace_variables'}=$node->getAttribute('replace_variables');
		$self->{'entity_'}{$id}{'replace_L10n'}=$node->getAttribute('replace_L10n');
		main::_log("setup entity id='$id' with length(".(length($self->{'entity'}{$id})).")") if $debug;
		push @ents, $id;
	}
	
	main::_log("entities '".(join "','",@ents)."'") unless $debug;
	
}



sub process_entity
{
	my $self=shift;
	
	if (exists $self->{'L10n'})
	{
		my $lng=$self->{'L10n'}{'lng'};
		if (!$lng || $lng eq "auto")
		{
			main::_log("$tom::lng $tom::LNG $TOM::LNG");
			$lng=$tom::lng;
			$lng=$tom::LNG unless $lng;
			$lng=$TOM::LNG unless $lng;
		}
		my $L10n=new TOM::L10n(
			'level' => $self->{'L10n'}{'level'},
			'addon' => $self->{'L10n'}{'addon'},
			'name' => $self->{'L10n'}{'name'},
			'lng' => $lng,
		);
		
		foreach my $entity (keys %{$self->{'entity'}})
		{
			if ($self->{'entity_'}{$entity}{'replace_L10n'} eq "true")
			{
				main::_log("replace_L10n in entity '$entity'") if $debug;
				while ($self->{'entity'}{$entity}=~s/<\$\((.{1,1024}?)\)>/<!L10N!>/)
				{
					my $string=$1;
					#main::_log("replace L10n string='$string'");
					my $number=$L10n::num{'#'.$L10n->{'id'}}{$string};
					if (!$number)
					{
						$self->{'entity'}{$entity}=~s/<!L10N!>/$string/;
					}
					my $variable='<$L10n::obj{\'#'.$L10n->{'id'}.'#'.$number.'\'}>';
					#main::_log("replaced by L10n id='$variable'");
					$self->{'entity'}{$entity}=~s/<!L10N!>/$variable/;
				}
				
			}
		}
		
	}
	
	foreach my $entity (keys %{$self->{'entity'}})
	{
		if ($self->{'entity_'}{$entity}{'replace_variables'} eq "true")
		{
			main::_log("replace_variables in entity '$entity'") if $debug;
			TOM::Utils::vars::replace($self->{'entity'}{$entity});
		}
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
	main::_log("allowed overlays=$env{'overlays'}") if $debug;
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
	
	foreach my $ext(".tpl.d/_init.xml",".ztpl",".tpl")
	{
		my $filename="$env{'dir'}/$env{'filename'}$ext";
		#main::_log("find $env{'dir'}/$env{'filename'}$ext");
		
		# if checking ztpl, unpack them into _temp .tpl.d extension
		# (check if not alredy actual exists) and return included xml
		
		return $filename if -e $filename;
	}
	
	return undef;
}



1;