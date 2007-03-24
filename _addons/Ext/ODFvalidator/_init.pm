#!/bin/perl
package Ext::ODFvalidator;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension ODFvalidator

=head1 DESCRIPTION

Extension that supports OpenDocument validation

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

our $DIR=(__FILE__=~/^(.*)\//)[0];

=head1 DEPENDS

=over

=item *

L<Ext::OpenDocument4CMS::_init|ext/"OpenDocument4CMS/_init.pm">

=item *

XML::LibXML

=back

=cut

use Ext::OpenDocument4CMS::_init;
use XML::LibXML;


# SETUP SOME DATA STRUCTURES

our %uris;
our %mimes;
our %exts;

do
{
	
	my @odf_uris = qw(
		office
		meta
		config
		text
		table
		drawing
		presentation
		dr3d
		animation
		chart
		form
		script
		style
		datastyle
		manifest
	);
	
	map { $_ = "urn:oasis:names:tc:opendocument:xmlns:$_:1.0"; } @odf_uris;
	
	my @compat_uris = qw(xsl-fo svg smil);
	
	map { $_ = "urn:oasis:names:tc:opendocument:xmlns:$_-compatible:1.0"; } @compat_uris;
	
	my @extern_uris = qw(
		http://purl.org/dc/elements/1.1/
		http://www.w3.org/1999/xlink
		http://www.w3.org/1998/Math/MathML
		http://www.w3.org/2002/xforms
	);
	
	$uris{$_}++ foreach (@odf_uris, @compat_uris, @extern_uris);
	
	my %odf_mimes = (
		'text' => 't',
		'graphics' => 'g',
		'presentation' => 'p',
		'spreadsheet' => 's',
		'chart' => 'c',
		'image' => 'i',
		'formula' => 'f',
		'text-master' => 'm',
		'text-web' => 'h'
	);
	
	foreach my $mime (keys %odf_mimes)
	{
		my $ext = $odf_mimes{$mime};
		my $true_mime = "application/vnd.oasis.opendocument.$mime";
		my $true_ext = 'od' . $ext;
		$mimes{$true_mime} = $true_ext;
		$exts{$true_ext} = $true_mime;
		if ($mime !~ /text-/)
		{
			$true_mime .= '-template';
			$true_ext = 'ot' . $ext;
			$mimes{$true_mime} = $true_ext;
			$exts{$true_ext} = $true_mime;
		}
	}
	
};



=head1 FUNCTIONS

=head2 validate()

 my $obj=Ext::ODFvalidator->validate('file:/');
 $obj->{errors};
 $obj->{warnings};
 $obj->{solutions};

=cut

sub validate
{
	my $class=shift;
	my $file=shift;
	my %env=@_;
	my $self={};
	my $t=track TOM::Debug(__PACKAGE__."->validate()");
	# bless empty object
	my $self=bless $self,$class;
	
	main::_log("input file='$file'");
	$self->{'file'}=$file;
	
	# extract
	$self->{'extract'}=Ext::OpenDocument4CMS->extract($self->{'file'},'extract'=>"*");
	
	if (!$self->{'extract'})
	{
		main::_log("file is not extracted",1);
		$t->close();
		return undef;
	}
	
	$self->{'tmpdir'}=$self->{'extract'}->{'tmpdir'};
	main::_log("extracted to directory '".$self->{'tmpdir'}."'");
	
	# process validation by default
	$self->process() if not $env{'noprocess'};
	
	$t->close();
	return $self;
}


sub process
{
	my $self=shift;
	
	my $t=track TOM::Debug(__PACKAGE__."->process()");
	
	# exists mimetype file?
	if (not -e $self->{'tmpdir'}.'/mimetype')
	{
		$self->error('does not contain a mimetype. This is a SHOULD in OpenDocument 1.0');
		$t->close();
		return undef;
	}
	
	# checking content of mimetype, and if is known
	do
	{
		local $/;
		open(HND,'<',$self->{'tmpdir'}.'/mimetype') || die "$!";
		$self->{'mimetype'}=<HND>;
	};
	
	main::_log("mimetype readed as '$self->{'mimetype'}'");
	
	if (!$self->{'mimetype'})
	{
		$self->error('does not contain a mimetype. This is a SHOULD in OpenDocument 1.0');
	}
	else
	{
		my ($ext) = ($self->{'file'} =~ /\.([^\.]+)$/);
		main::_log("ext defined as '$ext'");
		
		if (! exists $mimes{$self->{'mimetype'}})
		{
			$self->error("mimetype '$self->{'mimetype'}' is not defined by OpenDocument 1.0");
		}
		else
		{
			$self->{'ext_proposed'}=$mimes{$self->{'mimetype'}};
		}
		
		if (!$ext)
		{
			if (!$self->{'ext_proposed'})
			{
				$self->error("filename should have an OpenDocument extension");
			}
			else
			{
				$self->error("filename missing OpenDocument .$self->{'ext_proposed'} extension");
			}
		}
		
		if (!$exts{$ext})
		{
			$self->error("file extension '$ext' not defined in OpenDocument");
		}
		
		if ($ext ne $self->{'ext_proposed'} && $self->{'ext_proposed'})
		{
			$self->{'mimetype_proposed'}=$exts{$ext};
			$self->error("file extension $ext disagrees with file mimetype $self->{'mimetype'}");
			$self->solution("change extension to .$self->{'ext_proposed'}");
			$self->solution("change mime type to $self->{'mimetype_proposed'}")
				if $self->{'mimetype_proposed'};
		}
		
	}
	
	# manifest validation
	
	if (not -e $self->{'tmpdir'}.'/META-INF/manifest.xml')
	{
		$self->error('does not contain a manifest.'); # is this a JAR thing, or what?
	}
	else
	{
		$self->xmlvalidate(
			'xml' => $self->{'tmpdir'}.'/META-INF/manifest.xml',
			'rng' => $DIR.'/OpenDocument-manifest-schema-v1.0-os.rng'
		);
	}
	
	my @xmlfiles = ('content.xml', 'styles.xml', 'settings.xml', 'meta.xml');
	foreach my $xmlfile (@xmlfiles)
	{
		if (not -e $self->{'tmpdir'}.'/'.$xmlfile)
		{
			$self->error("$xmlfile is missing");
			next;
		}
		$self->xmlvalidate(
			'xml' => $self->{'tmpdir'}.'/'.$xmlfile,
			'rng' => $DIR.'/OpenDocument-schema-v1.0-os.rng'
		);
		#other_checks($file, $xmlfile);
	}
	
	$t->close();
	return 1;
}

# methods

sub xmlvalidate
{
	my $self=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."->xmlvalidate()");
	
	foreach (keys %env){main::_log("input '$_'='$env{$_}'");}
	
	my $rngschema = XML::LibXML::RelaxNG->new( location => $env{'rng'} );
	my $parser = XML::LibXML->new;
	
	my $doc;
	eval
	{
		$doc = $parser->parse_file($env{'xml'});
	};
	if ($@)
	{
		my $msg=$@;
		$msg=~s|^.*_temp/[a-zA-Z0-9]+||; # don't display info where is the file stored
		$self->error((split("\n",$msg))[0]);
		$t->close();
		return;
	}
	
	eval
	{
		$rngschema->validate($doc);
	};
	if ($@)
	{
		$self->error($@);
	}
	
	$t->close();
	return 1;
}

sub error
{
	my $self=shift;
	my $msg=shift;
	main::_log($msg,1);
	push @{$self->{'errors'}}, $msg;
	return 1;
}

sub warning
{
	my $self=shift;
	my $msg=shift;
	main::_log('!'.$msg);
	push @{$self->{'warnings'}}, $msg;
	return 1;
}

sub solution
{
	my $self=shift;
	my $msg=shift;
	main::_log($msg);
	push @{$self->{'solutions'}}, $msg;
	return 1;
}


sub DESTROY
{
	my $self=shift;
}

=head1 CODE NOT IMPLEMENTED YET

	# other_checks($file, $xmlfile)
	#		Performs other checks other than schema validation. For
	#		example, it warns if the document uses non-ODF namespaces.
	sub other_checks {
		my ($file, $subfile) = @_;
		my $content = '';
		{
			local $/;
			$content = `unzip -p $file $subfile`;
		}
		# Looks like OOo doesn't include new-line chars either.
		#my $last_char = substr($content,length($content)-1,1);
		#if ($last_char ne "\n") {
		#	warning("$subfile does not end in a new-line character.");
		#}
		my %saw = ($content =~ m/xmlns:(.*?)="([^\"]+)"/gms);
		foreach my $ns (keys %saw) {
			# remove OpenDocument name spaces
			my $uri = $saw{$ns};
			if (exists $uris{$uri}) {
				delete $saw{$ns};
			}
		}
		# look at non-OpenDocument name spaces
		foreach my $ns (keys %saw) {
			my $uri = $saw{$ns};
			my @uses = ($content =~ m/[<|\s]$ns:/gms);
			my $use = $#uses;
			if ($use > 0) {
				warning("$subfile: non-ODF xmlns $ns ($uri) used $use time(s)");
			}
		}
	}

=cut

=head1 AUTHORS

Implemented to Cyclone3 and modified by Roman Fordinal (roman.fordinal@comsultia.com)

Original odfvalidator.in script by Alex Hudson (alex@stratagia.co.uk) for OpenDocument Fellowship

=cut

=head1 COPYRIGHT

Copyright 2006 Alex Hudson, 2007 Roman Fordinal

This is free software. You may redistribute it under the terms
GNU General Public License Version 2 or at your option any later
version.

=cut


1;
