#!/bin/perl
package App::401::mimetypes::html;

=head1 NAME

App::401::mimetypes::html

=head1 DESCRIPTION

Handle html article source processing

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::401::_init|app/"401/_init.pm">

=item *

HTML::Parser

=back

=cut

use App::401::_init;
use base "HTML::Parser";

our $tpl=new TOM::Template(
	'level' => "auto",
	'addon' => "a401",
#	'name' => "parse",
	'content-type' => "xhtml" # default is XML
);



=head1 SYNOPSIS



=cut



sub text
{
	my ($self, $text) = @_;
	# just print out the original text
	
	$self->{'out'}.=$text;
	
	#print $text;
}



sub comment
{
	my ($self, $comment) = @_;
	# print out original text with comment marker
	#print "";
}



sub _parse_id
{
	my $id=shift;
	my %env;
	foreach(split(':',$id))
	{
		my @ref=split('=',$_);
		$env{$ref[0]}=$ref[1];
	}
	return %env;
}



sub start
{
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;
	
	main::_log("tag=$tag origtext=$origtext");
	
	my $out_full="<#tag#>";
	
	# modify
	if ($tag eq "img")
	{
		$attr->{'alt'}='' unless exists $attr->{'alt'};
		$attr->{'align'}='left' unless exists $attr->{'align'};
		if ($attr->{'id'}=~/^a501_image:(.*)$/)
		{
			use App::501::_init;
			my %vars=_parse_id($1);
			$vars{'format'}=$App::501::image_format_thumbnail_ID unless $vars{'format'};
			if ($vars{'ID'})
			{
				main::_log("find a501_image ID='$vars{'ID'}'");
				my $sql=qq{
					SELECT
						*
					FROM
						`$App::501::db_name`.`a501_image_view`
					WHERE
						ID_image=$vars{'ID'} AND
						ID_format=$vars{'format'}
					LIMIT 1
				};
				my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
				my %db0_line=$sth0{'sth'}->fetchhash();
				if ($db0_line{'ID'})
				{
					$attr->{'src'}=$tom::H_media.'/a501/image/file/'.$db0_line{'file_path'};
					$attr->{'alt'}=$db0_line{'name'};
					$attr->{'width'}=$db0_line{'image_width'};
					$attr->{'height'}=$db0_line{'image_height'};
					
					# override default tag representation
					$out_full=$self->{'entity'}{'a501_image'}
						|| $tpl->{'entity'}{'parser.a501_image'}
						|| $out_full;
					
					$out_full=~s|<%db_(.*?)%>|$db0_line{$1}|g;
					
					if (!$self->{'thumbnail'})
					{
						$self->{'thumbnail'}->{'src'}=$tom::H_media.'/a501/image/file/'.$db0_line{'file_path'};
						$self->{'thumbnail'}->{'alt'}=$db0_line{'name'};
						$self->{'thumbnail'}->{'width'}=$db0_line{'image_width'};
						$self->{'thumbnail'}->{'height'}=$db0_line{'image_height'};
					}
				}
			}
		}
		elsif ($attr->{'id'}=~/^a510_video_part:(.*)$/)
		{
			use App::510::_init;
			my %vars=_parse_id($1);
			$vars{'format'}=$App::510::video_format_full_ID unless $vars{'format'};
			
			if ($vars{'ID'})
			{
				main::_log("find a510_video_part ID='$vars{'ID'}'");
				
				my $sql=qq{
					SELECT
						*
					FROM
						`$App::510::db_name`.`a510_video_view`
					WHERE
						ID_part=$vars{'ID'} AND
						ID_format=$vars{'format'} AND
						lng='$tom::lng'
					LIMIT 1
				};
				my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
				my %db0_line=$sth0{'sth'}->fetchhash();
				if ($db0_line{'ID'})
				{
					$attr->{'src'}='video';
					$attr->{'width'}=$db0_line{'video_width'};
					$attr->{'height'}=$db0_line{'video_height'};
					$attr->{'alt'}=$db0_line{'part_name'} || $db0_line{'name'};
					
					my $relation=(App::160::SQL::get_relations(
						'l_prefix' => 'a510',
						'l_table' => 'video_part',
						'l_ID_entity' => $vars{'ID'},
						'rel_type' => 'thumbnail',
						'r_db_name' => $App::501::db_name,
						'r_prefix' => 'a501',
						'r_table' => 'image',
						'limit' => 1
					))[0];
					if ($relation->{'ID'})
					{
						main::_log("find a501_image ID='$relation->{'r_ID_entity'}'");
						my $sql=qq{
							SELECT
								*
							FROM
								`$App::501::db_name`.`a501_image_view`
							WHERE
								ID_entity_image=$relation->{'r_ID_entity'} AND
								ID_format=$App::501::image_format_fullsize_ID
							LIMIT 1
						};
						my %sth1=TOM::Database::SQL::execute($sql,'quiet'=>1);
						my %db1_line=$sth1{'sth'}->fetchhash();
						if ($db1_line{'ID'})
						{
							$attr->{'src'}=$tom::H_media.'/a501/image/file/'.$db1_line{'file_path'};
						}
						
						$out_full= $self->{'entity'}{'a510_video_part'}
							|| $tpl->{'entity'}{'parser.a510_video_part'}
							|| $self->{'entity'}{'a501_image'}
							|| $tpl->{'entity'}{'parser.a501_image'}
							|| $out_full;
						
						$out_full=~s|<%db_(.*?)%>|$db0_line{$1}|g;
						$out_full=~s|<%db_img_(.*?)%>|$db1_line{$1}|g;
						$out_full=~s|<%attr_height_plus%>|$db0_line{'video_height'}+20|eg;
						
						# thumbnail
						my $sql=qq{
							SELECT
								*
							FROM
								`$App::501::db_name`.`a501_image_view`
							WHERE
								ID_entity_image=$relation->{'r_ID_entity'} AND
								ID_format=$App::501::image_format_thumbnail_ID
							LIMIT 1
						};
						my %sth1=TOM::Database::SQL::execute($sql,'quiet'=>1);
						my %db1_line=$sth1{'sth'}->fetchhash();
						if ($db1_line{'ID'})
						{
							if (!$self->{'thumbnail'})
							{
								$self->{'thumbnail'}->{'src'}=$tom::H_media.'/a501/image/file/'.$db1_line{'file_path'};
								$self->{'thumbnail'}->{'alt'}=$db0_line{'part_name'} || $db0_line{'name'};
								$self->{'thumbnail'}->{'width'}=$db1_line{'image_width'};
								$self->{'thumbnail'}->{'height'}=$db1_line{'image_height'};
							}
						}
						
					}
					
				}
				
			}
			
		} # if $attr->{'id'}=~/
	
	} # if tag=''
	
	# rebuild a tag
	my %attrs_;
	my $out="<$tag";
	foreach (@{$attrseq})
	{
		next if $_ eq '/';
		next unless exists $attr->{$_};
		$out.=' '.$_.'="'.$attr->{$_}.'"';
		$attrs_{$_}=1;
	}
	foreach (keys %{$attr})
	{
		next if $_ eq '/';
		next if $attrs_{$_};
		$out.=' '.$_.'="'.$attr->{$_}.'"';
	}
	$out.=" /" if $attr->{'/'};
	$out.=">";
	
	# fill into out_full
	$out_full=~s|<#tag#>|$out|g;
	$out_full=~s|<%attr_(.*?)%>|$attr->{$1}|g;
	my $rand=int(rand(10000));
	$out_full=~s|<%rand%>|$rand|ge;
	
	$self->{'out'}.=$out_full;
	#print $origtext;
}



sub end
{
	my ($self, $tag, $origtext) = @_;
	# print out original text
	$self->{'out'}.=$origtext;
	#print $origtext;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
