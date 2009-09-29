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

our $cache=300;
#our $cache=0;
our $debug=0;
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
#	main::_log("text=$text") if $debug;
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
	
	if (not $tag=~/^(br|strong|em|i|u|b|font|div|object|param|embed)$/) # don't display info about not important tags
	{
		main::_log("tag='$tag' origtext='$origtext'") if $debug;
	}
	
	my $out_full="<#tag#>";
	
	my $out_tag;
	my $out_addon_type;
	my $out_cnt;
	my %vars;
	
	# modify
	if ($tag eq "img")
	{
		$self->{'count'}->{'img'}++;
		$out_cnt=$self->{'count'}->{'img'};$out_tag='img';
		$attr->{'alt'}='' unless exists $attr->{'alt'};
		#$attr->{'align'}='left' unless exists $attr->{'align'};
		if ($attr->{'id'}=~/^a010_(.*?):(.*)$/)
		{
			my $type=$1;
			%vars=_parse_id($2);
			
			# override default tag representation
			$out_full=$self->{'entity'}{'a010_'.$type}
				|| $tpl->{'entity'}{'parser.a010_'.$type}
				|| $out_full;
			
			$out_full=~s|<%var_(.*?)%>|$vars{$1}|g;
			
		}
		elsif ($attr->{'id'}=~/^a030_youtube:(.*)$/)
		{
			$self->{'count'}->{'video'}++;
			my $type=$1;
			%vars=_parse_id($1);
			
			$attr->{'width_forced'}=$attr->{'width'};
			$attr->{'height_forced'}=$attr->{'height'};
			
			$attr->{'width'}='425' unless $attr->{'width'};
			$attr->{'height'}='355' unless $attr->{'height'};
			
			$attr->{'src'}='http://img.youtube.com/vi/'.$vars{'ID'}.'/0.jpg';
			
			# override default tag representation
			$out_full=
				$self->{'entity'}{'a030_youtube.'.$out_cnt}
				|| $self->{'entity'}{'a030_youtube'}
				|| $tpl->{'entity'}{'parser.a030_youtube.'.$out_cnt}
				|| $tpl->{'entity'}{'parser.a030_youtube'}
				|| $out_full;
			
			$out_full=~s|<%var_(.*?)%>|$vars{$1}|g;
			
		}
		elsif ($attr->{'id'}=~/^a030_vimeo:(.*)$/)
		{
			$self->{'count'}->{'video'}++;
			my $type=$1;
			%vars=_parse_id($1);
			
			$attr->{'width_forced'}=$attr->{'width'};
			$attr->{'height_forced'}=$attr->{'height'};
			
			$attr->{'width'}='400' unless $attr->{'width'};
			$attr->{'height'}='302' unless $attr->{'height'};
			
			# override default tag representation
			$out_full=
				$self->{'entity'}{'a030_vimeo.'.$out_cnt}
				|| $self->{'entity'}{'a030_vimeo'}
				|| $tpl->{'entity'}{'parser.a030_vimeo.'.$out_cnt}
				|| $tpl->{'entity'}{'parser.a030_vimeo'}
				|| $out_full;
			
			$out_full=~s|<%var_(.*?)%>|$vars{$1}|g;
			
		}
		elsif ($attr->{'id'}=~/^a501_image:(.*)$/)
		{
			require App::501::_init;
			%vars=_parse_id($1);
			if ($vars{'important'} eq "1")
			{
				$vars{'ID_format'}=
					$vars{'ID_format'}
					|| $self->{'config'}->{'a501_image_file.ID_format'}
					|| $App::501::image_format_thumbnail_ID;
			}
			else
			{
				$vars{'ID_format'}=
					$self->{'config'}->{'a501_image_file.ID_format.'.$out_cnt}
					|| $self->{'config'}->{'a501_image_file.ID_format'}
					|| $vars{'ID_format'}
					|| $App::501::image_format_thumbnail_ID;
			}
			#$vars{'format'}=$App::501::image_format_thumbnail_ID unless $vars{'format'};
			if ($vars{'ID'} || $vars{'ID_entity'})
			{
				main::_log("find a501_image ID_entity='$vars{'ID_entity'} 'ID='$vars{'ID'}' ID_format='$vars{'ID_format'}'") if $debug;
				my %db0_line=App::501::functions::get_image_file(
					'image.ID_entity' => $vars{'ID_entity'},
					'image.ID' => $vars{'ID'},
					'image_file.ID_format' => $vars{'ID_format'},
					'image_attrs.lng' => $tom::lng
				);
				if ($db0_line{'ID_image'})
				{
					$attr->{'src'}=$tom::H_a501.'/image/file/'.$db0_line{'file_path'};
					main::_log("found image src='$attr->{'src'}'") if $debug;
					$attr->{'alt'}=$db0_line{'name'} unless $attr->{'alt'};
					
					$attr->{'width_forced'}=$attr->{'width'};
					$attr->{'height_forced'}=$attr->{'height'};
					
					$attr->{'width'}=$db0_line{'image_width'} unless $attr->{'width'};
					$attr->{'height'}=$db0_line{'image_height'} unless $attr->{'height'};
					
				}
				# fullsize
				my %db1_line=App::501::functions::get_image_file(
					'image.ID_entity' => $vars{'ID_entity'},
					'image.ID' => $vars{'ID'},
					'image_file.ID_format' => $App::501::image_format_fullsize_ID,
					'image_attrs.lng' => $tom::lng
				);
				if ($db1_line{'ID_image'})
				{
					$attr->{'fullsize.src'}=$tom::H_a501.'/image/file/'.$db1_line{'file_path'};
				}
				# extra format
				if ($self->{'config'}->{'a501_image_file.ID_format.extra'})
				{
					my %db2_line=App::501::functions::get_image_file(
						'image.ID_entity' => $vars{'ID_entity'},
						'image.ID' => $vars{'ID'},
						'image_file.ID_format' => $self->{'config'}->{'a501_image_file.ID_format.extra'},
						'image_attrs.lng' => $tom::lng
					);
					if ($db2_line{'ID_image'})
					{
						$attr->{'extra.src'}=$tom::H_a501.'/image/file/'.$db2_line{'file_path'};
					}
				}
				
				# override default tag representation
				if ($db1_line{'image_width'}<=($db0_line{'image_width'}*1.2))
				{ # fullsize is not better quality than this image_format
					$out_full=
						$self->{'entity'}{'a501_image.'.$out_cnt}
						|| $self->{'entity'}{'a501_image.nofullsize'}
						|| $self->{'entity'}{'a501_image'}
						|| $tpl->{'entity'}{'parser.a501_image.'.$out_cnt}
						|| $tpl->{'entity'}{'parser.a501_image'}
						|| $out_full;
				}
				else
				{
					$out_full=
						$self->{'entity'}{'a501_image.'.$out_cnt}
						|| $self->{'entity'}{'a501_image'}
						|| $tpl->{'entity'}{'parser.a501_image.'.$out_cnt}
						|| $tpl->{'entity'}{'parser.a501_image'}
						|| $out_full;
				}
				
				$out_full=~s|<%db_(.*?)%>|$db0_line{$1}|g;
				
			}
			
			$self->{'out_var'}->{'img.'.$out_cnt.'.src'}=$attr->{'src'};
			$self->{'out_var'}->{'img.'.$out_cnt.'.extra.src'}=$attr->{'extra.src'} if $attr->{'extra.src'};
		}
		elsif ($attr->{'id'}=~/^a510_video:(.*)$/)
		{
			$self->{'count'}->{'video'}++;
			$self->{'count'}->{'a510_video'}++;my $addon_cnt=$self->{'count'}->{'a510_video'};
			$self->{'count'}->{'a510_video_part'}++;my $addon_part_cnt=$self->{'count'}->{'a510_video_part'};
			require App::510::_init;
			%vars=_parse_id($1);
			$vars{'ID_format'}=
				$self->{'config'}->{'a510_video_part_file.ID_format.'.$out_cnt}
				|| $self->{'config'}->{'a510_video_part_file.ID_format'}
				|| $vars{'ID_format'}
				|| $App::510::video_format_full_ID;
			if ($vars{'ID_entity'})
			{
				main::_log("find a510_video ID_entity='$vars{'ID_entity'}'") if $debug;
				
				my %db0_line=App::510::functions::get_video_part_file
				(
					'video.ID_entity' => $vars{'ID_entity'},
					'video_part.part_id' => 1,
					'video_part_file.ID_format' => $vars{'ID_format'},
					'video_attrs.lng' => $tom::lng
				);
				
				if ($db0_line{'ID_entity_video'})
				{
					$attr->{'src'}='';
					$attr->{'width'}=$db0_line{'video_width'} unless $attr->{'width'};
					$attr->{'height'}=$db0_line{'video_height'} unless $attr->{'height'};
					$attr->{'video'}=$tom::H_a510.'/video/part/file/'.$db0_line{'file_part_path'};
					
					if (!$attr->{'alt'})
					{
						$attr->{'alt'}=$db0_line{'part_name'} || $db0_line{'name'};
					}
					
					$self->{'out_addon'}->{'a510_video_part'}[$addon_part_cnt]{'ID_part'}=$db0_line{'ID_part'};
					$self->{'out_addon'}->{'a510_video_part'}[$addon_part_cnt]{'src'}=$tom::H_a510.'/video/part/file/'.$db0_line{'file_part_path'};
					
					# override default tag representation
					$out_full=
						$self->{'entity'}{'a510_video.'.$out_cnt}
						|| $self->{'entity'}{'a510_video'}
						|| $tpl->{'entity'}{'parser.a510_video.'.$out_cnt}
						|| $tpl->{'entity'}{'parser.a510_video'}
						# or as image
						|| $self->{'entity'}{'a501_image.'.$out_cnt}
						|| $self->{'entity'}{'a501_image'}
						|| $tpl->{'entity'}{'parser.a501_image.'.$out_cnt}
						|| $tpl->{'entity'}{'parser.a501_image'}
						|| $out_full;
					
					$out_full=~s|<%db_(.*?)%>|$db0_line{$1}|g;
					$out_full=~s|<%attr_height_plus%>|$attr->{'height'}+60|eg;
					
					# find thumbnail image to first part
					my $relation=(App::160::SQL::get_relations(
						'l_prefix' => 'a510',
						'l_table' => 'video_part',
						'l_ID_entity' => $db0_line{'ID_part'},
						'rel_type' => 'thumbnail',
						'r_db_name' => $App::501::db_name,
						'r_prefix' => 'a501',
						'r_table' => 'image',
						'limit' => 1
					))[0];
					if ($relation->{'ID'})
					{
						main::_log("find a501_image ID='$relation->{'r_ID_entity'}'") if $debug;
						
						my $img_ID_format=
							$self->{'config'}->{'a501_image_file.ID_format.'.$out_cnt}
							|| $self->{'config'}->{'a501_image_file.ID_format'}
							|| $App::501::image_format_fullsize_ID;
						
						my %db1_line=App::501::functions::get_image_file(
							'image.ID_entity' => $relation->{'r_ID_entity'},
							'image_file.ID_format' => $img_ID_format,
							'image_attrs.lng' => $tom::lng
						);
						if ($db1_line{'file_path'})
						{
							$attr->{'src'}=$tom::H_a501.'/image/file/'.$db1_line{'file_path'};
							$out_full=~s|<%img\.db_(.*?)%>|$db1_line{$1}|g;
							$self->{'out_addon'}->{'a510_video_part'}[$addon_part_cnt]{'img.src'}=$attr->{'src'};
							$self->{'out_addon'}->{'a510_video_part'}[$addon_part_cnt]{'ID_image'}=$db1_line{'ID_image'};
						}
						# extra format
						if ($self->{'config'}->{'a501_image_file.ID_format.extra'})
						{
							my %db1_line=App::501::functions::get_image_file(
								'image.ID_entity' => $relation->{'r_ID_entity'},
								'image_file.ID_format' => $self->{'config'}->{'a501_image_file.ID_format.extra'},
								'image_attrs.lng' => $tom::lng
							);
							if ($db1_line{'ID_image'})
							{
								$attr->{'extra.src'}=$tom::H_a501.'/image/file/'.$db1_line{'file_path'};
							}
						}
					}
					
				}
				
			}
			$self->{'out_var'}->{'img.'.$out_cnt.'.src'}=$attr->{'src'};
			$self->{'out_var'}->{'img.'.$out_cnt.'.extra.src'}=$attr->{'extra.src'} if $attr->{'extra.src'};
		} # if $attr->{'id'}=~/
		elsif ($attr->{'id'}=~/^a510_video_part:(.*)$/)
		{
			$self->{'count'}->{'video'}++;
			$self->{'count'}->{'a510_video_part'}++;my $addon_cnt=$self->{'count'}->{'a510_video_part'};
			require App::510::_init;
			%vars=_parse_id($1);
			$vars{'ID_format'}=
				$self->{'config'}->{'a510_video_part_file.ID_format.'.$out_cnt}
				|| $self->{'config'}->{'a510_video_part_file.ID_format'}
				|| $vars{'ID_format'}
				|| $App::510::video_format_full_ID;
			
			if ($vars{'ID'})
			{
				main::_log("find a510_video_part ID='$vars{'ID'}'") if $debug;
				
				my %db0_line=App::510::functions::get_video_part_file
				(
					'video_part.ID' => $vars{'ID'},
					'video_part_file.ID_format' => $vars{'ID_format'},
					'video_attrs.lng' => $tom::lng
				);
				
				if ($db0_line{'ID_entity_video'})
				{
					main::_log("found video_part") if $debug;
					$attr->{'src'}='';
					$attr->{'width'}=$db0_line{'video_width'} unless $attr->{'width'};
					$attr->{'height'}=$db0_line{'video_height'} unless $attr->{'height'};
					$attr->{'video'}=$tom::H_a510.'/video/part/file/'.$db0_line{'file_part_path'};
					if (!$attr->{'alt'})
					{
						$attr->{'alt'}=$db0_line{'part_name'} || $db0_line{'name'};
					}
					
					$self->{'out_addon'}->{'a510_video_part'}[$addon_cnt]{'ID_part'}=$db0_line{'ID_part'};
					$self->{'out_addon'}->{'a510_video_part'}[$addon_cnt]{'src'}=$tom::H_a510.'/video/part/file/'.$db0_line{'file_part_path'};
					
					# override default tag representation
					$out_full=
						$self->{'entity'}{'a510_video_part.'.$out_cnt}
						|| $self->{'entity'}{'a510_video_part'}
						|| $tpl->{'entity'}{'parser.a510_video_part.'.$out_cnt}
						|| $tpl->{'entity'}{'parser.a510_video_part'}
						# or as image
						|| $self->{'entity'}{'a501_image.'.$out_cnt}
						|| $self->{'entity'}{'a501_image'}
						|| $tpl->{'entity'}{'parser.a501_image.'.$out_cnt}
						|| $tpl->{'entity'}{'parser.a501_image'}
						|| $out_full;
					
					$out_full=~s|<%db_(.*?)%>|$db0_line{$1}|g;
					$out_full=~s|<%attr_height_plus%>|$attr->{'height'}+20|eg;
					
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
						
						my $img_ID_format=
							$self->{'config'}->{'a501_image_file.ID_format.'.$out_cnt}
							|| $self->{'config'}->{'a501_image_file.ID_format'}
							|| $App::501::image_format_fullsize_ID;
							
						main::_log("find a501_image ID_entity='$relation->{'r_ID_entity'}' ID_format='$img_ID_format'") if $debug;
						
						my %db1_line=App::501::functions::get_image_file(
							'image.ID_entity' => $relation->{'r_ID_entity'},
							'image_file.ID_format' => $img_ID_format,
							'image_attrs.lng' => $tom::lng
						);
						if ($db1_line{'file_path'})
						{
							$attr->{'src'}=$tom::H_a501.'/image/file/'.$db1_line{'file_path'};
							main::_log("found thumbnail image src=".$attr->{'src'}) if $debug;
							$out_full=~s|<%img\.db_(.*?)%>|$db1_line{$1}|g;
							$self->{'out_addon'}->{'a510_video_part'}[$addon_cnt]{'img.src'}=$attr->{'src'};
							$self->{'out_addon'}->{'a510_video_part'}[$addon_cnt]{'ID_image'}=$db1_line{'ID_image'};
						}
						else
						{
							main::_log("not found thumbnail image",1) if $debug;
						}
						# extra format
						if ($self->{'config'}->{'a501_image_file.ID_format.extra'})
						{
							my %db1_line=App::501::functions::get_image_file(
								'image.ID_entity' => $relation->{'r_ID_entity'},
								'image_file.ID_format' => $self->{'config'}->{'a501_image_file.ID_format.extra'},
								'image_attrs.lng' => $tom::lng
							);
							if ($db1_line{'ID_image'})
							{
								$attr->{'extra.src'}=$tom::H_a501.'/image/file/'.$db1_line{'file_path'};
							}
						}
					}
					
				}
				
			}
			
			$self->{'out_var'}->{'img.'.$out_cnt.'.src'}=$attr->{'src'};
			$self->{'out_var'}->{'img.'.$out_cnt.'.extra.src'}=$attr->{'extra.src'} if $attr->{'extra.src'};
		} # if $attr->{'id'}=~/
	} # if tag=''
	elsif ($tag eq "a")
	{
		if ($attr->{'id'}=~/^a542_file:(.*)$/)
		{
			require App::542::_init;
			%vars=_parse_id($1);
			
			if ($vars{'ID_entity'})
			{
				main::_log("find a542_file ID_entity='$vars{'ID_entity'}'") if $debug;
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						file.ID_entity AS ID_entity_file,
						file.ID AS ID_file,
						file_attrs.ID AS ID_attrs,
						file_item.ID AS ID_item,
						
						file_attrs.ID_category,
						file_dir.name AS ID_dir_name,
						file_dir.name_url AS ID_dir_name_url,
						
						file_ent.posix_owner,
						file_ent.posix_author,
						
						file_item.hash_secure,
						file_item.datetime_create,
						
						file_attrs.name,
						file_attrs.name_url,
						file_attrs.name_ext,
						
						file_item.mimetype,
						file_item.file_ext,
						file_item.file_size,
						file_item.lng,
						
						file_ent.downloads,
						
						file_attrs.status,
						
						CONCAT(file_item.lng,'/',SUBSTR(file_item.ID,1,4),'/',file_item.name,'.',file_attrs.name_ext) AS file_path
						
					FROM
						`$App::542::db_name`.`a542_file` AS file
					LEFT JOIN `$App::542::db_name`.`a542_file_ent` AS file_ent ON
					(
						file_ent.ID_entity = file.ID_entity
					)
					LEFT JOIN `$App::542::db_name`.`a542_file_attrs` AS file_attrs ON
					(
						file_attrs.ID_entity = file.ID
					)
					LEFT JOIN `$App::542::db_name`.`a542_file_item` AS file_item ON
					(
						file_item.ID_entity = file.ID_entity AND
						file_item.lng = file_attrs.lng
					)
					LEFT JOIN `$App::542::db_name`.`a542_file_dir` AS file_dir ON
					(
						file_dir.ID = file_attrs.ID_category
					)
					WHERE
						file.ID_entity=$vars{'ID_entity'} AND
						file_attrs.lng='$tom::lng'
					LIMIT 1;
				},'quiet'=>1,'-cache'=>$cache);
				my %db0_line=$sth0{'sth'}->fetchhash();
				if ($db0_line{'ID_entity_file'})
				{
#					$attr->{'src'}=$tom::H_a542.'/file/item/'.$db0_line{'file_path'};
					$attr->{'href'}=$tom::H_www.'/download.tom?ID='.$db0_line{'ID_entity_file'}.'&hash='.$db0_line{'hash_secure'};
					main::_log("found file src='$attr->{'src'}'") if $debug;
					$attr->{'alt'}=$db0_line{'name'} unless $attr->{'alt'};
					
					# override default tag representation
					$out_full=
						$self->{'entity'}{'a542_file.'.$out_cnt}
						|| $self->{'entity'}{'a542_file'}
						|| $tpl->{'entity'}{'parser.a542_file.'.$out_cnt}
						|| $tpl->{'entity'}{'parser.a542_file'}
						|| $out_full;
					
					$out_full=~s|<%db_(.*?)%>|$db0_line{$1}|g;
				}
			}
		}
		elsif ($attr->{'id'}=~/^a210_page:(.*)$/)
		{
			require App::210::_init;
			%vars=_parse_id($1);
			
			if ($vars{'ID'})
			{
				main::_log("find a210_page ID='$vars{'ID'}'") if $debug;
				my %sql_def=('db_h' => "main",'db_name' => $TOM::DB{'main'}{'name'},'tb_name' => "a210_page");
				my %a210=App::020::SQL::functions::get_ID(
					%sql_def,
					'ID'      => "'$vars{'ID'}'",
					'columns' => { '*' => 1 },
					'-slave' => 1,
					'-cache' => 3600,
					'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%sql_def)
				);
				my $a210_path;
				# musim vygenerovat default path pre automaticky 301 code
				foreach my $p(
					App::020::SQL::functions::tree::get_path(
						$vars{'ID'},
						%sql_def,
						'-slave' => 1,
						'-cache' => 3600
					)
				)
				{
					push @{$a210{'IDs'}}, $p->{'ID'};
					$a210_path.="/".$p->{'name_url'};
				}
				$a210_path=~s|^/||;
				
				if ($TOM::LNG_permanent)
				{
					$attr->{'href'}=$tom::H_www.'/?|?a210_path='.$a210_path;
				}
				else
				{
					$attr->{'href'}=$tom::H_www.'/?|?a210_path='.$a210_path.'&__lng='.$a210{'lng'};
				}
				
				# override default tag representation
				$out_full=
					$self->{'entity'}{'a210_page.'.$out_cnt}
					|| $self->{'entity'}{'a210_page'}
					|| $tpl->{'entity'}{'parser.a210_page.'.$out_cnt}
					|| $tpl->{'entity'}{'parser.a210_page'}
					|| $out_full;
				
				$out_full=~s|<%db_(.*?)%>|$a210{$1}|g;
			}
			
		}
		elsif ($attr->{'id'}=~/^a401_article:(.*)$/)
		{
			%vars=_parse_id($1);
			
			my $sql=qq{
				SELECT
					article.ID_entity,
					article.ID,
					article_attrs.ID_category,
					article_cat.name AS ID_category_name,
					article_cat.name_url AS ID_category_name_url,
					article_attrs.name,
					article_attrs.datetime_start,
					article_attrs.name_url
				FROM `$App::401::db_name`.a401_article AS article
				LEFT JOIN `$App::401::db_name`.a401_article_attrs AS article_attrs ON
				(
					article_attrs.ID_entity = article.ID
				)
				LEFT JOIN `$App::401::db_name`.`a401_article_ent` AS article_ent ON
				(
					article_ent.ID_entity = article.ID_entity
				)
				LEFT JOIN `$App::401::db_name`.`a401_article_cat` AS article_cat ON
				(
					article_cat.ID = article_attrs.ID_category
				)
				WHERE
			};
			
			if ($vars{'ID'} && $vars{'ID_entity'})
			{
				$sql.=qq{
					article.ID=$vars{'ID'} OR
					article.ID_entity=$vars{'ID_entity'}
				};
			}
			elsif ($vars{'ID'})
			{
				$sql.=qq{
					article.ID=$vars{'ID'}
				};
			}
			else
			{
				$sql.=qq{
					article.ID='$vars{'ID_entity'}'
				};
			}
			
			$sql.=qq{
				ORDER BY
					article_attrs.datetime_start DESC
				LIMIT
					1
			};
			
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1,'-cache'=>600);
			my %db0_line=$sth0{'sth'}->fetchhash();
			if ($db0_line{'ID_entity'})
			{
		      my %datetime=TOM::Utils::datetime::datetime_collapse($db0_line{'datetime_start'});
		      $db0_line{'datetime_start.year'}=$datetime{'year'};
		      $db0_line{'datetime_start.month'}=$datetime{'month'};
		      $db0_line{'datetime_start.mday'}=$datetime{'mday'};
		      $db0_line{'datetime_start.hour'}=$datetime{'hour'};
		      $db0_line{'datetime_start.min'}=$datetime{'min'};
		      $db0_line{'datetime_start.sec'}=$datetime{'sec'};
				
				my $ID_category=$db0_line{'ID_category'};
				my $alias_url;
				my %data=App::020::SQL::functions::get_ID(
					'ID' => $ID_category,
					'db_h' => 'main',
					'db_name' => $App::401::db_name,
					'tb_name' => 'a401_article_cat',
					'columns' => {'*' => 1},
					'-cache' => 3600,
					'-slave' => 1,
				);
				$alias_url=$data{'alias_url'} if $data{'alias_url'};
				while ($ID_category && !$alias_url)
				{
					my %data=App::020::SQL::functions::tree::get_parent_ID(
						'ID' => $ID_category,
						'db_h' => 'main',
						'db_name' => $App::401::db_name,
						'tb_name' => 'a401_article_cat',
						'columns' => {'*' => 1},
						'-cache' => 3600,
						'-slave' => 1,
					);
					$ID_category=$data{'ID'};
					if ($data{'alias_url'}){$alias_url=$data{'alias_url'};last;}
				}
				
				if ($alias_url){$db0_line{'alias_url'}=$alias_url;}
				else {$db0_line{'alias_url'}=$tom::H_www;}
				
				$db0_line{'alias_url_orig'}=$alias_url;
				
				# override default tag representation
				$out_full=
					$self->{'entity'}{'a401_article.'.$out_cnt}
					|| $self->{'entity'}{'a401_article'}
					|| $tpl->{'entity'}{'parser.a401_article.'.$out_cnt}
					|| $tpl->{'entity'}{'parser.a401_article'}
					|| $out_full;
				
				$out_full=~s|<%db_(.*?)%>|$db0_line{$1}|g;
				
			}
			
		}
		
		
	}
	
	# fix not closed tags
	if ($tag=~/^hr|br|img$/)
	{
		$attr->{'/'}='/';
	}
	
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
	
	if ($vars{'important'} ne "1" && $out_tag && $out_cnt && ($self->{'ignore'}->{$out_tag} || $self->{'ignore'}->{$out_tag.'.'.$out_cnt}))
	{
		main::_log("ignore placing '$out_tag.$out_cnt'") if $debug;
	}
	else
	{
		$self->{'out'}.=$out_full;
	}
	
	if ($out_tag)
	{
		main::_log("added to out_tag '$out_tag.$out_cnt'") if $debug;
		$self->{'out_tag'}->{$out_tag.'.'.$out_cnt}=$out_full;
	}
	
	#print $origtext;
}



sub end
{
	my ($self, $tag, $origtext) = @_;
	# print out original text
#	main::_log("end tag=$tag text=$origtext") if $debug;
	$self->{'out'}.=$origtext;
	#print $origtext;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
