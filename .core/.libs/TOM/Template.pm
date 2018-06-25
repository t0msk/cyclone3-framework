package TOM::Template;

=head1 NAME

TOM::Template

=head1 DESCRIPTION

Templates management

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

use File::Path;
use File::Copy;
use XML::LibXML;
use TOM::L10n;
use TOM::Template::contenttypes;
use Ext::Redis::_init;
use JSON;
our $json = JSON::XS->new->ascii->convert_blessed;

BEGIN
{
	if ($tom::P_media)
	{
		if (!-e $tom::P_media.'/tpl' && -e $tom::P.'/local.conf')
		{
			main::_log("mkpath '$tom::P_media/tpl'");
			File::Path::mkpath $tom::P_media.'/tpl';
			chmod (0777, $tom::P_media.'/tpl');
		}
		elsif (!-e $tom::P_media.'/tpl')
		{
			File::Path::mkpath $tom::P_media.'/tpl';
			chmod (0777, $tom::P_media.'/tpl');
		}
	}
	else
	{
		main::_log("\$tom::P_media is not defined in TOM::Template (loaded without TOM::Domain?)",1);
	}
	
	use Template;
	use Template::Config;
	eval {require Template::Stash::XS};
	if (!$@){$Template::Config::STASH = 'Template::Stash::XS'}
	
}

our $debug=$TOM::Template::debug || 0;
our %objects;


=head1 SYNOPSIS

 my $tpl=TOM::Template::new(
  'level' => "global", # auto/local/master/global
  #'addon' => "a400",
  #'name' => "email-stats",
  'content-type' => "xhtml" # default is XML
 )
 print $tpl->{'entity'}{'test'};

=cut



=head1 TPL EXAMPLES

 <?xml version="1.0" encoding="UTF-8"?>
 <template>
   <header>
     <!--<L10n level="auto" name="xhtml" lng="auto"/>-->
     <!--<tt enabled="false" />-->
     <extract>
       <!--
       <file location="cyclone3-150x44.png"/>
       <file location=".htaccess"/>
       -->
       <file location="css/main.css" replace_variables="true"/>
       <file location="grf/a400/logo.gif"/>
     </extract>
   </header>

   <entity id="parser.a501_image" replace_variables="false"><![CDATA[
    <table>
     <#tag#>
    </table>
   ]]>
   </entity>
 </template>

=cut


=head1 FUNCTIONS


=head2 new

 my $tpl=TOM::Template::new(
  'level' => "global", # auto/local/master/global
  #'addon' => "a400",
  #'name' => "email-stats",
  'content-type' => "xhtml" # default is XML
  'lng' => "en"
 )

tpl source can be as

	everything.content-type.tpl # this is xml file
	everything.content-type.tpl.d/_init.xml
	everything.content-type.ztpl # this is zipped directory (currently not supported)


=cut

sub new
{
	my $class=shift;
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."->new($env{'level'}/$env{'addon'}/$env{'name'}.$env{'content-type'})") if $debug;
	
	my $obj=bless {}, $class;
	
	foreach my $key(keys %env)
	{
		main::_log("input '$key'='$env{$key}'") if $debug;
	}
	
	$env{'content-type'}="xml" unless $env{'content-type'};
	$env{'name'}="default" unless $env{'name'};
	TOM::Template::contenttypes::trans($env{'content-type'});
	$env{'level'}="auto" unless $env{'level'};
	
	$env{'lng'}||= $tom::lng || $tom::LNG || $TOM::LNG;
	
	# add params into object
	%{$obj->{'ENV'}}=%env;
	$obj->{'entity'}={};
	$obj->{'entity_'}={}; # hash form of entity
	$obj->{'L10n'}={};
	$obj->{'file'}={};
	$obj->{'file_'}={};
	$obj->{'mfile'}={}; # list of files on which we control changes
	$obj->{'config'}={};
	
	# find where is the definition file/files
	if ($env{'location'})
	{
		$obj->{'location'}=$env{'location'};
		if (! -e $obj->{'location'})
		{
			$t->close() if $debug;
			return undef;
		}
		# modifytime
		$obj->{'mfile'}{$obj->{'location'}}=TOM::file_mtime($obj->{'location'});
	}
	else
	{
		$obj->prepare_location();
		if (!$obj->{'location'})
		{
			main::_log("can't create template object",1) if $debug;
			$t->close() if $debug;
			return undef;
#			return bless {}, $class;;
		}
	}
	
	if (!$objects{$obj->{'location'}} && $Redis && $main::cache)
	{
		$objects{$obj->{'location'}} = $Redis->get('C3|tpl|'.$TOM::P_uuid.':'.$obj->{'location'});
		Ext::Redis::_uncompress(\$objects{$obj->{'location'}});
		$objects{$obj->{'location'}}=$json->decode($objects{$obj->{'location'}})
			if $objects{$obj->{'location'}};
		delete $objects{$obj->{'location'}} if ref($objects{$obj->{'location'}}) eq "SCALAR";
	}
	
	if ($objects{$obj->{'location'}})
	{
		# time to check changes
		$objects{$obj->{'location'}}->{'config'}{'ctime'} = time();
		my $object_modified=0;
		foreach (keys %{$objects{$obj->{'location'}}->{'mfile'}})
		{
			if (TOM::file_mtime($_) > $objects{$obj->{'location'}}->{'mfile'}{$_})
			{
				main::_log("{Template} '$obj->{'location'}' expired, file '$_' modified");
				$object_modified=1;
				last;
			}
		}
		if ($object_modified)
		{
			delete $objects{$obj->{'location'}};
		}
	}
	
	$obj->{'config'}->{'tt'}=1 if $env{'tt'};
	
	# check if same location is already loaded in another object
	# (location is unique identification of template)
	# when no, proceed parsing this tpl source
	if ($obj->{'location'} && !$objects{$obj->{'location'}})
	{
		main::_log("<={Template} '$obj->{'location'}'");
		
		# add this object into global $TOM::Template::objects{} hash
		$objects{$obj->{'location'}}=$obj;
		
		# add this location into ignore list
#		main::_log("addding to ignore ".$obj->{'location'});
		push @{$obj->{'ENV'}->{'ignore'}}, $obj->{'location'};
		$obj->prepare_xml();
		# save time of object creation (last-check time)
		$obj->{'config'}->{'ctime'} = time();
		# save modifytime of xml definition file_
		# will be override posibly with higher times in tpl dependencies or files (by parse_header)
		$obj->{'config'}->{'mtime'} = TOM::file_mtime($obj->{'location'});
		$obj->parse_header();
		# save config from header to object memory cache
		%{$objects{$obj->{'location'}}->{'config'}}=%{$obj->{'config'}};
		$obj->parse_entity();
		
		if ($obj->{'config'}->{'tt'}) # extend by Template Toolkit
		{
			main::_log("creating new Template::Toolkit object") if $debug;
			$obj->{'tt'} = Template->new({
#				'EVAL_PERL' => 1,
#				'STASH' => $stash,
#				},
#				'LOAD_PERL' => 1,
#				'PLUGINS' => {
#					'date' => 'Template::Plugin::Date'
#				'RECURSION' => 1,
				'VARIABLES' => {
					'devel' => $tom::devel,
					'version' => 'version'
				},
				'INCLUDE_PATH' => [$tom::P.'/_dsgn',$tom::Pm.'/_dsgn'],
				'COMPILE_DIR' => $tom::P.'/_temp',
				'COMPILE_EXT' => '.ttc2',
			});
		}
		
		if ($Redis)
		{
			my $key = 'C3|tpl|'.$TOM::P_uuid.':'.$obj->{'location'};
			$Redis->set($key,
				Ext::Redis::_compress(\$json->encode({
					'ENV' => $obj->{'ENV'},
					'config' => $obj->{'config'},
					'mfile' => $obj->{'mfile'},
					'entity' => $obj->{'entity'},
					'entity_' => $obj->{'entity_'},
					'L10n' => $obj->{'L10n'},
					'file' => $obj->{'file'},
					'file_' => $obj->{'file_'},
					'location' => $obj->{'location'},
					'engine' => $TOM::engine,
					'request_code' => $main::request_code,
				})),sub {} # in pipeline
			);
			$Redis->expire($key,86400,sub {}); # set expiration time in pipeline
		}
		
	}
	else
	{
#		main::_log("<={Template}{cache} '$obj->{'location'}'");
	}
	
	
	# create copy of object to return it as unique
	# this is important to allow changing variables
	# without affecting original objects
	
	my $obj_return=bless {}, $class;
		$obj_return->{'location'}=$obj->{'location'};
		%{$obj_return->{'ENV'}}=%env;
		if ($obj->{'location'})
		{
			%{$obj_return->{'entity'}}=%{$objects{$obj->{'location'}}{'entity'}};
			%{$obj_return->{'entity_'}}=%{$objects{$obj->{'location'}}{'entity_'}};
			%tpl::entity=%{$objects{$obj->{'location'}}{'entity'}};
			%{$obj_return->{'L10n'}}=%{$objects{$obj->{'location'}}{'L10n'}};
			# when L10n differs, initialize new L10n object
			if ($obj_return->{'L10n'} && $obj_return->{'ENV'}->{'lng'} ne $obj_return->{'L10n'}{'lng'})
#				|| (!$obj_return->{'L10n'}{'obj'} && $obj_return->{'L10n'} && $obj_return->{'ENV'}->{'lng'})
			{
				$obj_return->{'L10n'}{'obj'}=new TOM::L10n(
					'level' => $obj_return->{'L10n'}{'level'},
					'addon' => $obj_return->{'L10n'}{'addon'},
					'name' => $obj_return->{'L10n'}{'name'},
					'lng' => $obj_return->{'ENV'}->{'lng'} || $tom::lng || $tom::LNG || $TOM::LNG,
				);
			}
			# recovery header config to new object
			%{$obj_return->{'config'}}=%{$objects{$obj->{'location'}}{'config'}};
			$obj_return->{'config'}->{'tt'}||=$env{'tt'};
			# get tt reference from objects cache
			if ($obj_return->{'config'}->{'tt'})
			{
				# in config is tt enabled, but object is missing (when loaded from cache)
				if (!$objects{$obj->{'location'}}{'tt'}) # extend by Template Toolkit
				{
					# in object cache is missing tt reference, because is loaded from cache
					main::_log("creating new Template::Toolkit object") if $debug;
					$objects{$obj->{'location'}}{'tt'} = Template->new({
						'INCLUDE_PATH' => [$tom::P.'/_dsgn',$tom::Pm.'/_dsgn'],
						'COMPILE_DIR' => $tom::P.'/_temp',
						'COMPILE_EXT' => '.ttc2',
					});
				}
				$obj_return->{'tt'}=$objects{$obj->{'location'}}{'tt'};
			}
		}
		$obj_return->{'config'}->{'tt'}||=$env{'tt'};
		if ($obj_return->{'config'}->{'tt'}) # extend by Template Toolkit
		{
			# regenerate reference
			$obj_return->{'tt'}->{'SERVICE'}->{'CONTEXT'}->{'tpl'}=$obj_return; # reference from Template Toolkit to TOM::Template
			# default set of variables for tt
			my $lang=$TOM::L10n::codes::trans{$obj_return->{'ENV'}->{'lng'} || $tom::lng} || $obj_return->{'ENV'}->{'lng'} || $tom::lng;
				$lang=~s|\-|_|g;
			$obj_return->{'variables'}={
				'lng' => $obj_return->{'ENV'}->{'lng'} || $tom::lng,
				'lang' => $lang
			};
		}
		
		# replace_variables only in root level of Template not in templates called by <extend*>
		$obj_return->process_entity() if (caller)[0] ne "TOM::Template";
		if ($obj->{'location'})
		{
			%{$obj_return->{'file'}}=%{$objects{$obj->{'location'}}{'file'}};
			%{$obj_return->{'file_'}}=%{$objects{$obj->{'location'}}{'file_'}};
			%{$obj_return->{'mfile'}}=%{$objects{$obj->{'location'}}{'mfile'}};
		}
	
	
	$t->close() if $debug;
	return $obj_return;
}

sub TO_JSON { return { %{ shift() } }; }






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
			'addon' => $self->{'ENV'}->{'addon'},
			'filename' => $self->{'ENV'}->{'name'}.".".$self->{'ENV'}->{'content-type'}
		);
		
		if ($self->{'location'})
		{
			foreach my $ignore_dir (@{$self->{'ENV'}->{'ignore'}})
			{
#				main::_log("check ignore dir='$ignore_dir' to '$self->{'location'}'");
				if ($self->{'location'} eq $ignore_dir)
				{
					main::_log("already loaded from '$ignore_dir'",1) if $debug;
					undef $self->{'location'};
					last;
				}
			}
		}
		
		last if $self->{'location'};
	}
	
	if (!$self->{'location'})
	{
		main::_log("can't find location for template '".$self->{'ENV'}->{'name'}.".".$self->{'ENV'}->{'content-type'}."' (template not exists, or already loaded as dependency)",1);
		return undef;
	}
	
	if ($self->{'location'}=~/\/_init.xml$/)
	{
		$self->{'dir'}=$self->{'location'};
		$self->{'dir'}=~s/\/_init.xml$//;
	}
	
	$self->{'mfile'}{$self->{'location'}}=TOM::file_mtime($self->{'location'});
	
	return $self->{'location'};
}



sub prepare_xml
{
	my $self=shift;
	
	$self->{'xp'} = 'XML::LibXML'->load_xml(location => $self->{'location'});
}

sub _directory_tree
{
	next undef unless $_[0];
	next undef unless -d $_[0];
	opendir (DIR, $_[0]) || return undef;
	my @files;
	foreach (readdir(DIR))
	{
		next if $_=~/^\.+$/;
		next unless -e $_[0].'/'.$_;
		if (-d $_[0].'/'.$_)
		{
#			main::_log("dir $_[0]/$_");
			push @files,_directory_tree($_[0].'/'.$_);
			next;
		}
		
#		main::_log("add $_[0]/$_");
		push @files,$_[0].'/'.$_;
	}
	return @files;
}

sub parse_header
{
	my $self=shift;
	
	foreach my $node ($self->{'xp'}->findnodes('/template/header/*'))
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
				'ignore' => $self->{'ENV'}{'ignore'},
				'lng' => $self->{'ENV'}{'lng'}
			);
			
			if (!$extend)
			{
				main::_log("can't extend byt template $level/$addon/$name/$content_type",1) if $debug;
				next;
			}
			
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
			
			# if modifytime of dependency is higher than master object
			if ($self->{'config'}->{'mtime'} < $extend->{'config'}->{'mtime'})
			{
				$self->{'config'}->{'mtime'} = $extend->{'config'}->{'mtime'};
			}
			
			# add modify files from inherited tpl
			foreach (keys %{$extend->{'mfile'}})
			{
				$self->{'mfile'}{$_}=$extend->{'mfile'}{$_};
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
			
			$self->{'L10n'}{'obj'}=new TOM::L10n(
				'level' => $self->{'L10n'}{'level'},
				'addon' => $self->{'L10n'}{'addon'},
				'name' => $self->{'L10n'}{'name'},
				'lng' => $self->{'ENV'}->{'lng'} || $tom::lng || $tom::LNG || $TOM::LNG,
			);
			
		}
		elsif ($name eq "tt")
		{
			if ($node->getAttribute('enabled') eq "true")
			{
				$self->{'config'}->{'tt'}=1;
				main::_log("request to extend by tt (Template Toolkit)") if $debug;
			}
#			
		}
		
	}
	
	
	if ($self->{'dir'} && $tom::P_media) # extract only in domain service with defined P_media
	{
		# proceed extracting files only when tpl is a tpl.d/ type
		foreach my $node ($self->{'xp'}->findnodes('/template/header/extract/*'))
		{
			my $name=$node->getName();
			
			if ($name eq "directory")
			{
				my $location=$node->getAttribute('location');
				my $destination=$node->getAttribute('dest') || $node->getAttribute('destination');
				
				my $replace_variables=$node->getAttribute('replace_variables');
				my $replace_L10n=$node->getAttribute('replace_L10n');
				
				main::_log("extract directory '$location' from '$self->{'dir'}' to '$destination' replace_variables='$replace_variables' replace_L10n='$replace_L10n'") if $debug;
				
				if (!-d $self->{'dir'}.'/'.$location)
				{
					main::_log("source file is directory, weee sorry!");
					next;
				}
				
				foreach my $location_ (_directory_tree($self->{'dir'}.'/'.$location))
				{
					#$location=$location_;
					$location_=~s|^$self->{'dir'}/||;
					$location_=~s|^$location/||;# if $destination=~/\/$/;

					my $destination_=$destination;
					
					my $destination_dir=$tom::P_media.'/tpl/'.$destination_.'/'.$location_;
						$destination_dir=~s|^(.*)/(.*?)$||;
						$destination_dir=$1;
					my $destination_file=$2;
					
					my $src=$self->{'dir'}.'/'.$location.'/'.$location_;
					my $src_file=$location.'/'.$location_;
					my $dst=$destination_dir.'/'.$destination_file;
					
					# added to mfile
					$self->{'mfile'}{$src}=TOM::file_mtime($src);
					
					# if modifytime of file is higher than definition file modifytime
					if ($self->{'config'}->{'mtime'} < $self->{'mfile'}{$src})
					{
						$self->{'config'}->{'mtime'} = $self->{'mfile'}{$src};
					}
					
					# check if this file is not oveerided, or already exists in
					# destination directory
					$self->{'file'}{$src_file}{'src'}=$src;
					$self->{'file'}{$src_file}{'dst'}=$dst;
					
					if (!-e $dst)
					{
						main::_log("extract '$src_file'") unless $debug;
						if (!-e $destination_dir)
						{
							File::Path::mkpath $destination_dir;
							chmod (0777,$destination_dir);
						}
						File::Copy::copy($src, $dst);
						chmod (0666,$dst);
						#symlink($src,$dst);
						next;
					}
					
					main::_log("file '$src_file' already exists") if $debug;
					
					my $src_stat=(stat($src))[7];
					my $dst_stat=(stat($dst))[7];
					
					if ($src_stat ne $dst_stat)
					{
						main::_log("not same filesize, rewrite by source") if $debug;
						main::_log("extract override '$location'") unless $debug;
						File::Copy::copy($src, $dst);
						chmod (0666,$dst);
						#symlink($src,$dst);
						next;
					}
					
				}
				
				next;
			}
			elsif ($name eq "file")
			{
				my $location=$node->getAttribute('location');
				my $destination=$node->getAttribute('dest') || $node->getAttribute('destination');
					$destination.=$location if $destination=~/\/$/;
					$destination.=$location unless $destination;
				my $destination_dir=$tom::P_media.'/tpl/'.$destination;
					$destination_dir=~s|^(.*)/(.*?)$|$1|;
				my $destination_file=$2;
					
				my $replace_variables=$node->getAttribute('replace_variables');
				my $replace_L10n=$node->getAttribute('replace_L10n');
				
				main::_log("extract file '$location' from '$self->{'dir'}' to '$destination' replace_variables='$replace_variables' replace_L10n='$replace_L10n'") if $debug;
				
				if (-d $self->{'dir'}.'/'.$location)
				{
					main::_log("source file is directory, weee sorry!");
					next;
				}
				
				# added to mfile
				$self->{'mfile'}{$self->{'dir'}.'/'.$location}=TOM::file_mtime($self->{'dir'}.'/'.$location);
				
				# if modifytime of file is higher than definition file modifytime
				if ($self->{'config'}->{'mtime'} < $self->{'mfile'}{$self->{'dir'}.'/'.$location})
				{
					$self->{'config'}->{'mtime'} = $self->{'mfile'}{$self->{'dir'}.'/'.$location};
				}
				
				# check if this file is not oveerided, or already exists in
				# destination directory
				
				my $src=$self->{'dir'}.'/'.$location;
				my $dst=$destination_dir.'/'.$destination_file;
				
				$self->{'file'}{$location}{'src'}=$src;
				$self->{'file'}{$location}{'dst'}=$dst;
				
#				print "$location\n";
				
				if (!-e $dst)
				{
					main::_log("extract '$location'") unless $debug;
					if (!-e $destination_dir)
					{
						File::Path::mkpath $destination_dir;
						chmod (0777,$destination_dir);
					}
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
	
	my @ents;
	foreach my $node ($self->{'xp'}->findnodes('/template/entity'))
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
		$self->{'entity_'}{$id}{'replace_variables'}=$node->getAttribute('replace_variables')
			if $node->getAttribute('replace_variables');
		$self->{'entity_'}{$id}{'tt'}=$node->getAttribute('tt');
		$self->{'entity_'}{$id}{'replace_L10n'}=$node->getAttribute('replace_L10n');
		$self->{'entity_'}{$id}{'location'}=$self->{'location'}; # the source of entity
		main::_log("setup entity id='$id' with length(".(length($self->{'entity'}{$id})).")") if $debug;
		push @ents, $id;
	}
	
#	main::_log("entities '".(join "','",@ents)."'") unless $debug;
	
}



sub process_entity
{
	my $self=shift;
	
	if (exists $self->{'L10n'})
	{
		my $lng=$self->{'L10n'}{'lng'};
		if (!$lng || $lng eq "auto")
		{
#			main::_log("$tom::lng $tom::LNG $TOM::LNG");
			$lng=$self->{'ENV'}->{'lng'} || $tom::lng || $tom::LNG || $TOM::LNG;
			# main::_log("process in lng $lng");
		}
		my $L10n=$self->{'L10n'}{'obj'};#new TOM::L10n(
		#	'level' => $self->{'L10n'}{'level'},
		#	'addon' => $self->{'L10n'}{'addon'},
		#	'name' => $self->{'L10n'}{'name'},
		#	'lng' => $lng,
		#);
		
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
		if ($env{'addon'})
		{
			push @dirs,$tom::P."/_dsgn" if $tom::P;
		}
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
		if ($_=~/^\//)
		{
			push @dirs,$_.'/'.$subdir;
		}
		else
		{
			push @dirs,$TOM::P."/_overlays/".$_."/".$subdir;
		}
	}
	
	# global (backup for every option)
	push @dirs,$TOM::P."/".$subdir;
	
	return @dirs;
}


sub get_tpl_xml
{
	my %env=@_;
	
	foreach my $ext(
		".tpl.d/_init.xml",
#		".ztpl",
		".tpl"
	)
	{
		if ($env{'addon'})
		{
			my $filename="$env{'dir'}/$env{'addon'}-$env{'filename'}$ext";
			main::_log(" touching in '".$filename."'") if $debug;
			if (-e $filename)
			{
				main::_log(" found ".$filename) if $debug;
				return $filename;
			}
		}
		my $filename="$env{'dir'}/$env{'filename'}$ext";
		main::_log(" touching in '".$filename."'") if $debug;
		if (-e $filename)
		{
			main::_log(" found ".$filename) if $debug;
			return $filename;
		}
	}
	
	return undef;
}


sub variables_push
{
	my $self=shift;
	my $entry0=shift; # place or variables
	my $entry1=shift; # variables
	
	$self->{'variables'}={} unless $self->{'variables'};
	
	if ($entry1) # if sended variables, place also defined
	{
		$entry0='items' unless $entry0;
		if (!$self->{'variables'}->{$entry0})
		{
			$self->{'variables'}->{$entry0}=[];
			push @{$self->{'variables'}->{$entry0}},$entry1;
		}
		elsif (ref $self->{'variables'}->{$entry0} eq "ARRAY")
		{
			push @{$self->{'variables'}->{$entry0}},$entry1;
		}
	}
	else
	{
		if (!$self->{'variables'}->{'items'})
		{
			$self->{'variables'}->{'items'}=[];
			push @{$self->{'variables'}->{'items'}},$entry0;
		}
		elsif (ref $self->{'variables'}->{'items'} eq "ARRAY")
		{
			push @{$self->{'variables'}->{'items'}},$entry0;
		}
	}
	
}


sub process
{
	# just process the template!
	my $self=shift;
	my $vars=shift;
	my $fnc=shift || 'main';
	
	if ($self->{'config'}->{'tt'})
	{
		# ah, template toolkit available here!
		my $tt=$self->{'tt'};
		
		# variables HASH
		my $vars_process={};
		$self->{'variables'}={} unless $self->{'variables'};
		# copy reference to HASH
		$vars_process=$self->{'variables'};
		# create test string
		$vars_process->{'test'}="this is test string";
		
		# override when required
		$vars_process = $vars if $vars;
		
		# test variable
		$vars_process->{'test'}="test string";
		
		$Tomahawk::module::TPL->{'variables'}->{'devel'}=$tom::devel;
		$Tomahawk::module::TPL->{'variables'}->{'devel_branch'}=$tom::devel_branch
			if $tom::devel_branch;
		$Tomahawk::module::TPL->{'variables'}->{'devel_branch_behind'}=$tom::devel_branch_behind
			if $tom::devel_branch_behind;
		$Tomahawk::module::TPL->{'variables'}->{'hostname'}=$TOM::hostname;
		
		# domain variables
		$vars_process->{'domain'}={
			'name' => $tom::H,
			'name_master' => $tom::Hm,
			'url' => $tom::H_www,
			'url_orig' => $tom::H_www_orig || $tom::H_www,
			'url_master' => $tom::Hm_www || $tom::H_www,
			'url_media' => $tom::H_media,
			'url_tpl' => $tom::H_tpl || $tom::H_media.'/tpl',
			'url_grf' => $tom::H_grf || $tom::H_media.'/grf',
			'url_css' => $tom::H_css || $tom::H_media.'/css',
			'url_js' => $tom::H_js || $tom::H_media.'/js',
			'url_a501' => $tom::H_a501,
			'url_a510' => $tom::H_a510,
			'lng' => $tom::LNG, # default lng
			'lang' => $tom::LANG, # default lang
			'setup' => \%tom::setup
		};
		# request params
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'protocol'}=exists $main::ENV{'HTTPS'} ? 'https' : 'http';
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'param'}=\%main::FORM;
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'timestamp'}=$main::time_current;
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'RPC'}=$main::RPC;
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'ENV'}=\%main::ENV;
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'cookie'}=\%main::COOKIES_all;
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'a210'}=\%main::a210;
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'code'}=$main::request_code;
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'key'}=\%main::key;
		$Tomahawk::module::TPL->{'variables'}->{'request'}->{'lng'}=$tom::lng;
		%{$Tomahawk::module::TPL->{'variables'}->{'request'}->{'env'}}=%main::env;
			delete $Tomahawk::module::TPL->{'variables'}->{'request'}->{'env'}{'cache'};
		# user variables
#=head1
		if (%main::USRM)
		{
			%{$Tomahawk::module::TPL->{'variables'}->{'user'}}=%main::USRM;
			undef $Tomahawk::module::TPL->{'variables'}->{'user'}->{'session'};
			if (ref($main::USRM{'session'}) eq "HASH")
			{
				# copy hash, not tied
				%{$Tomahawk::module::TPL->{'variables'}->{'user'}->{'session'}}
					= %{$main::USRM{'session'}};
			}
			# remove unwanted
			delete $Tomahawk::module::TPL->{'variables'}->{'user'}->{'cookies'};
			delete $Tomahawk::module::TPL->{'variables'}->{'user'}->{'pass'};
			delete $Tomahawk::module::TPL->{'variables'}->{'user'}->{'saved_cookies'};
			delete $Tomahawk::module::TPL->{'variables'}->{'user'}->{'session_save'};
			
			# alias
			%{$Tomahawk::module::TPL->{'variables'}->{'USRM'}}=%{$Tomahawk::module::TPL->{'variables'}->{'user'}};
		}
#=cut
		# process
		undef $self->{'output'};
		undef $self->{'error'};
		$tt->process(
			$fnc,
			$vars_process,\$self->{'output'}
		) || do {
			main::_log($tt->error(),1);
			$self->{'error'}=$tt->error();
			return undef
		};
		
	}
	else
	{
		main::_log("this tpl can't be processed. Template::Toolkit extension not enabled",1);
	}
	
	return 1;
}

1;
