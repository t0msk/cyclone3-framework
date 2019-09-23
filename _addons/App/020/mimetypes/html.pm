#!/bin/perl
package App::020::mimetypes::html;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



use App::020::_init;
use App::160::SQL;
use base "HTML::Parser";

our $cache=300;
# our $cache=0;
our $debug=0;
our $a_external_blank = $App::020::mimetypes::html::a_external_blank || 0;

sub new
{
	my ($class, %env) = @_;
	my $self = $class->SUPER::new();
	
	$self->{'lng'} = $env{'lng'} || $tom::lng;
#	main::_log("lng=" . $self->{'lng'});
	
	$self->{'tpl'}=new TOM::Template(
		'level' => "auto",
		'addon' => "a020",
		'tt' => 1, # enable tt processing
		'name' => "parser",
		'content-type' => "xhtml",
		'lng' => $self->{'lng'}
	);
	
	if ($env{'tpl_ext'})
	{
		$self->{'tpl_ext'}=$env{'tpl_ext'};
	}
	
	if ($env{'env'})
	{
		$self->{'env'}=$env{'env'};
	}
	
	return $self;
}


sub parse
{
	my $class=shift;
	# reset previous variables
	delete $class->{'entity'};
	delete $class->{'addon'};
	delete $class->{'counter'};
	delete $class->{'thumbnail'};
	delete $class->{'output'};
	delete $class->{'output.inline'};
	delete $class->{'count'};
	return $class->SUPER::parse(@_);
}


sub text
{
	my ($self, $text) = @_;
	
	$self->{'count'}->{'text.length'}+=length($text);
	
	if ($self->{'level.inline'} && $self->{'level.inline'} <= $self->{'level'})
	{
		$self->{'output.inline'}.=$text;
		return;
	}

	if ($self->{'level.ignore'} && $self->{'level.ignore'} <= $self->{'level'})
	{
		return;
	}
	
	if ($self->{'stop'})
	{
		return;
	}
	
	# just print out the original text
	$self->{'output'}.=$text;
	
	if ($self->{'config'}->{'length.stop'} && (!$self->{'stop'}))
	{
		if ($self->{'config'}->{'length.stop'} <= $self->{'count'}->{'text.length'})
		{
			$self->{'stop'}=1;
			$self->{'stop.level'}=$self->{'level'};
		}
	}
}


sub comment
{
	my ($self, $comment) = @_;
	# print out original text with comment marker
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


sub _parse_style
{
	my $style=shift;
	my %env;
	foreach my $part (split(';',$style))
	{
		my ($name,$value)=split(':',$part,2);
		$name=~s|^[ ]+||;
		$name=~s|[ ]+$||;
		$value=~s|^[ ]+||;
		$value=~s|[ ]+$||;
		$env{$name}=$value;
	}
	return %env;
}


sub _gen_style
{
	my %env=@_;
	my $style;
	foreach (sort keys %env)
	{
		$style.="; ".$_.": ".$env{$_};
	}
	$style=~s|"|'|g;
	$style=~s|^; ||;
	return $style;
}


sub _escape_attr
{
	my $attr=shift;
	$attr=~s|"|'|g;
	$attr=~s|&|&amp;|g;
	return $attr;
}


sub start
{
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;
	$tag=~s|/$||;
	
	$self->{'level'}++;
	$self->{'attr'}[$self->{'level'}]=$attr;

	delete $self->{'entity_tt'};
	
	# fix not closed tags
	$attr->{'/'}='/' if $tag=~/^hr|br|img$/;
	
	if ($self->{'stop'} && $self->{'stop.level'} <= $self->{'level'})
	{
		$self->{'level'}-- if $attr->{'/'};
		return;
	}
	
	if ($self->{'level.inline'} && $self->{'level.inline'} <= $self->{'level'})
	{
		$self->{'output.inline'}.=$origtext;
		$self->{'level'}-- if $attr->{'/'};
		return;
	}

	# fix style attribute
	if ($attr->{'style'})
	{
		my %style=_parse_style($attr->{'style'});
#		if ($tag=~/^p|span|div$/)
#		{
#			delete $style{'color'};
#			delete $style{'font-size'};
#			delete $style{'font-family'};
#			delete $style{'background'};
#			delete $style{'background-color'};
#		}
		$attr->{'style'}=_gen_style(%style);
		delete $attr->{'style'} unless $attr->{'style'};
	}
	
	if ($self->{'level.ignore'} && $self->{'level.ignore'} < $self->{'level'})
	{
		if ($attr->{'/'})
		{
			$self->{'level'}--;
		}
		return;
	}
	
	if (not $tag=~/^(br|strong|em|i|u|b|font|div|object|param|embed)$/) # don't display info about not important tags
	{
		main::_log("[".$self->{'level'}."] tag='$tag' origtext='$origtext'") if $debug;
	}
	
	if ($tag eq "a" 
		&& $App::020::mimetypes::html::a_external_blank
		&& (not $attr->{'href'}=~/^$tom::H_www_orig/))
	{
		$attr->{'target'} = "_blank";
	}
	
	my $tag_output;
	
	if ($tag eq "section")
	{
		main::_log("found section") if $debug;
		
#		$self->{'level.ignore'}=$self->{'level'};
		undef $self->{'output.inline'};
		$self->{'level.inline'}=$self->{'level'};

		# selection which entry name in tpl will be used to process
		my $tpl_src='tpl';
		my $tpl_entity;
		# if tpl is extended by module tpl, then search for entries with prefix "parser."
		if ($self->{'tpl_ext'} && $self->{'env'}->{'prefix'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$self->{'env'}->{'prefix'}.'.'.$tag})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$self->{'env'}->{'prefix'}.'.'.$tag;
		}
		elsif ($self->{'tpl_ext'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$tag})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$tag;
		}
		# otherwise use native entry from tpl
		elsif ($self->{'env'}->{'prefix'}
			&& exists $self->{'tpl'}->{'entity'}{$self->{'env'}->{'prefix'}.'.'.$tag})
		{
			$tpl_entity=$self->{'env'}->{'prefix'}.'.'.$tag;
		}
		elsif (exists $self->{'tpl'}->{'entity'}{$tag})
		{
			$tpl_entity=$tag;
		}
		
		# if found entry name, process it by tt2
		if ($tpl_entity) # tt2 process
		{
			my %variables;
			%{$variables{'request'}->{'env'}}=%main::env;
			%{$variables{'request'}->{'ENV'}}=%main::ENV;
			$variables{'request'}->{'param'}=\%main::FORM;
			$variables{'request'}->{'timestamp'}=$main::time_current;
			if ($self->{$tpl_src}->process({
				'entity' => {
					'tag' => $tag,
					'attr' => $attr,
#					'id' => \%vars,
#					'db' => \%db_entity
				},
				'lng' => $self->{'lng'},
				'env' => $self->{'env'},
				'count' => {
					'tag' => $self->{'count'}{'tag'}{$tag},
#					'addon' => $self->{'count'}{'addon'}{$entity}
				},
				'domain' => {
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
					'setup' => \%tom::setup
				},
				%variables
#				'entity'=>\%db0_line
				},$tpl_entity))
			{
				$tag_output=$self->{$tpl_src}->{'output'};
			}
			else
			{
				$tag_output=$self->{$tpl_src}->{'error'}
			}
		}


		my $tpl_src='tpl';
		my $tpl_entity;
		
		# if tpl is extended by module tpl, then search for entries with prefix "parser."
		if ($self->{'tpl_ext'}
			&& $self->{'env'}->{'prefix'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$self->{'env'}->{'prefix'}.'.'.$tag.'.close'})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$self->{'env'}->{'prefix'}.'.'.$tag.'.close';
		}
		elsif ($self->{'tpl_ext'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$tag.'.close'})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$tag.'.close';
		}
		# otherwise use native entry from tpl
		elsif ($self->{'env'}->{'prefix'}
			&& exists $self->{'tpl'}->{'entity'}{$self->{'env'}->{'prefix'}.'.'.$tag.'.close'})
		{
			$tpl_entity=$self->{'env'}->{'prefix'}.'.'.$tag.'.close';
		}
		elsif (exists $self->{'tpl'}->{'entity'}{$tag.'.close'})
		{
			$tpl_entity=$tag.'.close';
		}

		$self->{'closetag'}->[$self->{'level'}] = $self->{$tpl_src}->{'entity'}{$tpl_entity};
	}
	elsif ($attr->{'id'} && $attr->{'id'}=~/^([a-zA-Z0-9_]+):(.*)$/) # Cyclone3 entity
	{
		my $entity=$1;
		my %vars=_parse_id($2);
		main::_log("<$tag> \@id=$entity\...");
		
		$self->{'count'}{'tag'}{$tag}++;
		$self->{'count'}{'addon'}{$entity}++;
		
		my $db_name=App::020::SQL::functions::_detect_db_name(
			($entity=~/^(.*?)_/)[0]
		) if $tom::addons{($entity=~/^(.*?)_/)[0]};
			$db_name = $TOM::DB{'main'}{'name'} unless $db_name;
		
#		main::_log("ID_entity=$vars{'ID_entity'} ID=$vars{'ID'} chk addon=".($entity=~/^(.*?)_/)[0]." a=".$tom::addons{($entity=~/^(.*?)_/)[0]});
		
		if (!$vars{'ID_entity'} && $vars{'ID'} && $tom::addons{($entity=~/^(.*?)_/)[0]})
		{
			my %sql_def=('db_h' => "main",'db_name' => $db_name,'tb_name' => $entity);
			my %row=App::020::SQL::functions::get_ID(
				%sql_def,
				'ID'      => $vars{'ID'},
				'columns' => { 'ID_entity' => 1 },
				'-slave' => 1,
				'-cache' => 86400,
				'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%sql_def)
			);
			$vars{'ID_entity'}=$row{'ID_entity'};
		}# elsif (!$vars{'ID_entity'} && $vars{'ID'}){$vars{'ID_entity'}=$vars{'ID'};}
		
		push @{$self->{'entity'}},{
#			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => $entity,
			'ID' => $vars{'ID'},
			'ID_entity' => $vars{'ID_entity'},
			'tag' => {
				'attr' => $attr
			},
#			'id-tag' => \%vars,
			'count' => {
				'tag' => $self->{'count'}->{'tag'}->{$tag},
				'addon' => $self->{'count'}->{'addon'}->{$entity}
			}
		};
		push @{$self->{'addon'}{$entity}},$self->{'entity'}[-1];
		
		my %db_entity;
		if ($entity eq "a210_page")
		{
			# get data
			require App::210::_init;
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					*
				FROM $App::210::db_name.a210_page
				WHERE
					ID_entity = ?
					AND lng = ?
				ORDER BY
					ID_charindex DESC
				LIMIT 1
			},'db_h'=>'main','log'=>0,'quiet'=>1,'bind'=>[$vars{'ID_entity'},$self->{'lng'}],'-cache'=>86400,
				'-cache_changetime' => App::020::SQL::functions::_get_changetime(
					{'db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => 'a210_page','ID_entity'=>$vars{'ID_entity'}}
				)
			);
			%db_entity=$sth0{'sth'}->fetchhash();
			my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => 'a210_page');
			foreach my $p(
				App::020::SQL::functions::tree::get_path(
					$db_entity{'ID'},
					%sql_def,
					'-slave' => 1,
					'-cache' => 86400
				)
			)
			{
				$db_entity{'path_url'}.="/".$p->{'name_url'};
			}
			$db_entity{'path_url'}=~s|^/||;
		}
		elsif ($entity eq "a401_article")
		{
			# get data
			require App::401::_init;
#			main::_log("get article $tom::lng");
			
			my $sql_where;
			my @sql_bind;
			
			if ($vars{'ID_entity'})
			{
				$sql_where.=" AND article.ID_entity=?";
				push @sql_bind,$vars{'ID_entity'};
			}
			elsif ($vars{'ID'})
			{
				$sql_where.=" AND article.ID=?";
				push @sql_bind,$vars{'ID'};
			}
			
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					article.ID_entity,
					article.ID,
					article_attrs.ID_category,
					article_cat.ID AS cat_ID,
					article_cat.name AS cat_name,
					article_cat.name_url AS cat_name_url,
					article_attrs.name,
					article_attrs.name_url
				FROM $App::401::db_name.a401_article_ent AS article_ent
				INNER JOIN $App::401::db_name.a401_article AS article ON
				(
					article_ent.ID_entity = article.ID_entity
				)
				INNER JOIN $App::401::db_name.a401_article_attrs AS article_attrs ON
				(
					article_attrs.ID_entity = article.ID AND
					article_attrs.status IN ('Y')
				)
				INNER JOIN $App::401::db_name.a401_article_content AS article_content ON
				(
					article_content.ID_entity = article.ID_entity AND
					article_content.status = 'Y' AND
					article_content.lng = article_attrs.lng
				)
				INNER JOIN $App::401::db_name.a401_article_cat AS article_cat ON
				(
					article_cat.ID = article_attrs.ID_category
				)
				LEFT JOIN $App::401::db_name.a301_ACL_user_group AS ACL_world ON
				(
					ACL_world.ID_entity = 0 AND
					r_prefix = 'a401' AND
					r_table = 'article' AND
					r_ID_entity = article.ID_entity
				)
				WHERE
					article_ent.status = 'Y'
					AND article.status = 'Y'
					AND article_attrs.lng = ?
					$sql_where
				LIMIT
					1
			},'bind'=>[$self->{'lng'},@sql_bind],'quiet'=>1,'-slave'=>1,
				'-changetime'=>App::020::SQL::functions::_get_changetime(
					{
						'db_h'=>"main",
						'db_name' => $App::401::db_name,
						'tb_name' => "a401_article",
						'ID_entity' => do{$vars{'ID_entity'} if $vars{'ID_entity'}=~/^\d+$/}
					}),
			);
			%db_entity=$sth0{'sth'}->fetchhash();
			main::_log("found ID=$db_entity{'ID'} ID_entity=$db_entity{'ID_entity'}");
			
			# search for a210_page linked to this
			use App::210::_init;
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					a210_page.*
				FROM
					`$App::210::db_name`.a210_page
				INNER JOIN `$App::210::db_name`.a160_relation ON
				(
					a160_relation.l_prefix = 'a210' AND
					a160_relation.l_table = 'page' AND
					a160_relation.l_ID_entity = a210_page.ID AND
					a160_relation.r_prefix = 'a401' AND
					a160_relation.r_table = 'article' AND
					a160_relation.r_ID_entity = ? AND
					a160_relation.rel_type = 'link' AND
					a160_relation.status = 'Y'
				)
				WHERE
					a210_page.status = 'Y'
				LIMIT 1
			},'bind'=>[$db_entity{'ID_entity'}],'quiet'=>1);
			if ($sth0{'rows'})
			{
				my %a210=$sth0{'sth'}->fetchhash();
				my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
				foreach my $p(
					App::020::SQL::functions::tree::get_path(
						$a210{'ID_entity'},
						%sql_def,
						'-slave' => 1,
						'-cache' => 86400*7
					)
				)
				{
					push @{$db_entity{'a210'}{'IDs'}}, $p->{'ID'};
					push @{$db_entity{'a210'}{'nodes'}}, $p;
					$db_entity{'a210'}{'link'}='direct';
					$db_entity{'a210'}{'path_url'}.="/".$p->{'name_url'};
				}
				$db_entity{'a210'}{'path_url'}=~s|^/||;
			}
			
			if ($db_entity{'ID_category'} && !$db_entity{'a210'})
			{
				# link to a210_page
				require App::210::_init;
				if (my $category=App::401::functions::_a210_by_cat([$db_entity{'ID_category'}],'lng'=>$self->{'lng'}))
				{
					my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
					foreach my $p(
						App::020::SQL::functions::tree::get_path(
							$category,
							%sql_def,
							'-slave' => 1,
							'-cache' => 86400*7
						)
					)
					{
						push @{$db_entity{'a210'}{'IDs'}}, $p->{'ID'};
						push @{$db_entity{'a210'}{'nodes'}}, $p;
						$db_entity{'a210'}{'path_url'}.="/".$p->{'name_url'};
					}
					$db_entity{'a210'}{'path_url'}=~s|^/||;
				}
			}
			
		}
		elsif ($entity eq "a710_org")
		{
			# get data
			require App::710::_init;
#			main::_log("get article $tom::lng");
			
			my $sql_where;
			my @sql_bind;
			
			if ($vars{'ID_entity'})
			{
				$sql_where.=" AND org.ID_entity=?";
				push @sql_bind,$vars{'ID_entity'};
			}
			elsif ($vars{'ID'})
			{
				$sql_where.=" AND org.ID=?";
				push @sql_bind,$vars{'ID'};
			}
			
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					org.ID_entity,
					org.ID,
					org.name,
					org.name_url,
					org.name_code,
					org_lng.name_short,
					org_cat.ID AS cat_ID,
					org_cat.name AS cat_name,
					org_cat.name_url AS cat_name_url
				FROM $App::710::db_name.a710_org AS org
				LEFT JOIN $App::710::db_name.a710_org_lng AS org_lng ON
				(
					org_lng.ID_entity = org.ID AND
					org_lng.lng = '$self->{'lng'}'
				)
				LEFT JOIN $App::710::db_name.a710_org_rel_cat AS org_rel_cat ON
				(
					org_rel_cat.ID_org = org.ID_entity
				)
				LEFT JOIN $App::710::db_name.a710_org_cat AS org_cat ON
				(
					org_cat.ID_entity = org_rel_cat.ID_category AND
					org_cat.lng = '$self->{'lng'}'
				)
				WHERE
							org.status = 'Y'
					AND	org_lng.lng = '$self->{'lng'}'
					$sql_where
				LIMIT
					1
			},'bind'=>[@sql_bind],'quiet'=>1,'-slave'=>1,
				'-changetime'=>App::020::SQL::functions::_get_changetime(
					{
						'db_h'=>"main",
						'db_name' => $App::710::db_name,
						'tb_name' => "a710_org",
						'ID_entity' => do{$vars{'ID_entity'} if $vars{'ID_entity'}=~/^\d+$/}
					}),
			);
			%db_entity=$sth0{'sth'}->fetchhash();
			main::_log("found ID=$db_entity{'ID'} ID_entity=$db_entity{'ID_entity'}");
			
			# search for a210_page linked to this
			use App::210::_init;
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					a210_page.*
				FROM
					`$App::210::db_name`.a210_page
				INNER JOIN `$App::210::db_name`.a160_relation ON
				(
					a160_relation.l_prefix = 'a210' AND
					a160_relation.l_table = 'page' AND
					a160_relation.l_ID_entity = a210_page.ID AND
					a160_relation.r_prefix = 'a710' AND
					a160_relation.r_table = 'org' AND
					a160_relation.r_ID_entity = ? AND
					a160_relation.rel_type = 'link' AND
					a160_relation.status = 'Y'
				)
				WHERE
					a210_page.status = 'Y'
				LIMIT 1
			},'bind'=>[$db_entity{'ID_entity'}],'quiet'=>1);
			if ($sth0{'rows'})
			{
				my %a210=$sth0{'sth'}->fetchhash();
				my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
				foreach my $p(
					App::020::SQL::functions::tree::get_path(
						$a210{'ID_entity'},
						%sql_def,
						'-slave' => 1,
						'-cache' => 86400*7
					)
				)
				{
					push @{$db_entity{'a210'}{'IDs'}}, $p->{'ID'};
					push @{$db_entity{'a210'}{'nodes'}}, $p;
					$db_entity{'a210'}{'link'}='direct';
					$db_entity{'a210'}{'path_url'}.="/".$p->{'name_url'};
				}
				$db_entity{'a210'}{'path_url'}=~s|^/||;
			}
			
		}
		elsif ($entity eq "a411_poll")
		{
			require App::411::_init;
			
			my $sql_where;
			my @sql_bind;
			
			if ($vars{'ID_entity'})
			{
				$sql_where.=" AND `poll`.`ID_entity` = ?";
				push @sql_bind,$vars{'ID_entity'};
				$sql_where.=" AND `poll`.`lng` = ?";
				push @sql_bind, $self->{'lng'};
			}
			elsif ($vars{'ID'})
			{
				$sql_where.=" AND `poll`.`ID` = ?";
				push @sql_bind,$vars{'ID'};
			}
			
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					
					`poll`.*
					
				FROM
					`$App::411::db_name`.`a411_poll` AS `poll`
				LEFT JOIN
					`$App::411::db_name`.`a411_poll_cat` AS `poll_cat` ON
					(
						`poll_cat`.`ID` = `poll`.`ID_category`
					)
				WHERE
					`poll`.`status` IN ('Y','N','W')
					$sql_where
				LIMIT
					1
			},'bind'=>[@sql_bind],'quiet'=>1,'-slave'=>1,
				'-changetime'=>App::020::SQL::functions::_get_changetime(
					{
						'db_h'=>"main",
						'db_name' => $App::411::db_name,
						'tb_name' => "a411_poll",
						'ID_entity' => do{$vars{'ID_entity'} if $vars{'ID_entity'}=~/^\d+$/}
					}),
			);
			%db_entity=$sth0{'sth'}->fetchhash();
			main::_log("found ID=$db_entity{'ID'} ID_entity=$db_entity{'ID_entity'} '$db_entity{'name'}'");
			
			my $p=new App::020::mimetypes::html(
				'tpl_ext' => $self->{'tpl_ext'},
				'lng' => $self->{'lng'}
			);
			$p->config_from($self);
			delete $p->{'config'}->{'editable'};
			$p->{'config'}->{'inline'}=1; # this is inline poll
			$p->parse($db_entity{'description'});
			$p->eof();
			undef $p->{'config'}->{'inline'};
			
			$db_entity{'description_parser'}={
				'output' => $p->{'output'},
				'addon' => $p->{'addon'},
				'entity' => $p->{'entity'},
				'thumbnail' => $p->{'thumbnail'},
			};
			
			my %sth1=TOM::Database::SQL::execute(qq{
				SELECT
					`poll_answer`.*
				FROM
					`$App::411::db_name`.`a411_poll_answer` AS `poll_answer`
				WHERE
							`poll_answer`.`ID_poll` = ?
					AND	`poll_answer`.`lng`='$self->{'lng'}'
					AND	`poll_answer`.`status` = 'Y'
				ORDER BY
					`poll_answer`.`ID_entity`
			},'bind'=>[$db_entity{'ID_entity'}],'log_'=>1,'-slave'=>1);
			
			while (my %answer=$sth1{'sth'}->fetchhash())
			{
				push @{$db_entity{'answers'}}, \%answer;
			}
		}
		elsif ($entity eq "a420_static")
		{
			require App::420::_init;
			
			my $sql_where;
			my @sql_bind;
			
			if ($vars{'ID_entity'})
			{
				$sql_where.=" AND `static`.ID_entity = ?";
				push @sql_bind,$vars{'ID_entity'};
				$sql_where.=" AND `static`.lng = ?";
				push @sql_bind, $self->{'lng'};
			}
			elsif ($vars{'ID'})
			{
				$sql_where.=" AND `static`.ID = ?";
				push @sql_bind,$vars{'ID'};
			}
			
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					
					`static`.`ID_entity`,
					`static`.`ID`,
					`static`.`ID_category`,
					
					`static_cat`.`ID` AS `cat_ID`,
					`static_cat`.`ID_entity` AS `cat_ID_entity`,
					`static_cat`.`name` AS `cat_name`,
					`static_cat`.`name_url` AS `cat_name_url`,
					
					`static`.`name`,
					`static`.`name_url`,
					`static`.`alias_url`,
					`static`.`posix_owner`,
					`static`.`posix_modified`,
					`static`.`datetime_start`,
					`static`.`datetime_stop`,
					`static`.`body`,
					`static`.`metadata`,
					`static`.`status`
					
				FROM `$App::420::db_name`.`a420_static` AS `static`
				LEFT JOIN `$App::420::db_name`.`a420_static_cat` AS `static_cat` ON
				(
					`static_cat`.`ID` = `static`.`ID_category`
				)
				WHERE
					static.status = 'Y'
					$sql_where
				LIMIT 1
			},'bind'=>[@sql_bind],'quiet'=>1,'-slave'=>1,
				'-changetime'=>App::020::SQL::functions::_get_changetime(
					{
						'db_h'=>"main",
						'db_name' => $App::420::db_name,
						'tb_name' => "a420_static",
						'ID_entity' => do{$vars{'ID_entity'} if $vars{'ID_entity'}=~/^\d+$/}
					}),
			);
			%db_entity=$sth0{'sth'}->fetchhash();
			main::_log("found ID=$db_entity{'ID'} ID_entity=$db_entity{'ID_entity'} '$db_entity{'name'}'");
			
			if ($tag eq "div")
			{
				my $t=track TOM::Debug("embed");
				
				$self->{'level.ignore'}=$self->{'level'};
				
#				if (!$self->{'config'}->{'inline'})
#				{
					
					my $p=new App::020::mimetypes::html(
						'tpl_ext' => $self->{'tpl_ext'},
						'lng' => $self->{'lng'}
					);
					$p->config_from($self);
					delete $p->{'config'}->{'editable'};
					$p->{'config'}->{'inline'}=1; # this is inline article
					$p->parse($db_entity{'body'});
					$p->eof();
					undef $p->{'config'}->{'inline'};
					
					$db_entity{'body_parser'}={
						'output' => $p->{'output'},
						'addon' => $p->{'addon'},
						'entity' => $p->{'entity'},
						'thumbnail' => $p->{'thumbnail'},
					};
					
					main::_log("here is divid",1) if $p->{'output'}=~/\<divid/;
					
#				}
				$t->close();
			}
			
		}
		elsif ($entity eq "a501_image")
		{
			# get data
			require App::501::_init;
			%db_entity=App::501::functions::get_image_file(
				'image.ID' => $vars{'ID'},
				'image.ID_entity' => $vars{'ID_entity'},
				'image_file.ID_format' => $App::501::image_format_original_ID,
				'image_attrs.lng' => $tom::lng
			);
			delete $db_entity{'ID_image'};
			delete $db_entity{'ID_entity_image'};
			push @{$self->{'thumbnail'}},$vars{'ID_entity'} if $tag eq "img";
		}
		
		if ($entity eq "a501_image_set")
		{
			require App::501::_init;
			my @IDS =split(';',$vars{'ID_entity'});
			foreach (@IDS)
			{
				my %image=App::501::functions::get_image_file(
					'image.ID_entity' => $_,
					'image_file.ID_format' => $App::501::image_format_original_ID,
					'image_attrs.lng' => $tom::lng
				);					
				if ($image{'ID_entity'}) 
				{	
					delete $image{'ID_image'};
					delete $image{'ID_entity_image'};
					push @{$db_entity{'image_set'}}, \%image;
				}	
			}
		}
		elsif ($entity eq "a510_video")
		{
			# get data
			require App::510::_init;
			%db_entity=App::510::functions::get_video_part_file(
				'video.ID_entity' => $vars{'ID_entity'},
				'video_part.part_id' => 1,
				'video_part_file.ID_format' => $vars{'ID_format'} || 1,
				'video_attrs.lng' => $tom::lng
			);
			
			if ($db_entity{'ID_category'})
			{
				# link to a210_page
				require App::210::_init;
				if (my $category=App::510::functions::_a210_by_cat([$db_entity{'ID_category'}],'lng'=>$tom::lng))
				{
					my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
					foreach my $p(
						App::020::SQL::functions::tree::get_path(
							$category,
							%sql_def,
							'-slave' => 1,
							'-cache' => 86400*7
						)
					)
					{
						push @{$db_entity{'a210'}{'IDs'}}, $p->{'ID'};
						push @{$db_entity{'a210'}{'nodes'}}, $p;
						$db_entity{'a210'}{'path_url'}.="/".$p->{'name_url'};
					}
					$db_entity{'a210'}{'path_url'}=~s|^/||;
				}
			}
			
			if ($db_entity{'ID_part'})
			{
				my $relation=(App::160::SQL::get_relations(
					'l_prefix' => 'a510',
					'l_table' => 'video_part',
					'l_ID_entity' => $db_entity{'ID_part'},
					'rel_type' => 'thumbnail',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'limit' => 1
				))[0];
				if ($relation->{'ID'})
				{
					$db_entity{'thumbnail'}=$relation->{'r_ID_entity'};
					push @{$self->{'thumbnail'}},$relation->{'r_ID_entity'} if $tag eq "img";
				}
			}
			
		}
		elsif ($entity eq "a510_video_part")
		{
			# get data
			require App::510::_init;
			%db_entity=App::510::functions::get_video_part_file(
				'video_part.ID' => $vars{'ID'},
				'video_part_file.ID_format' => $vars{'ID_format'} || 1,
				'video_attrs.lng' => $tom::lng
			);
			
			if ($db_entity{'ID_category'})
			{
				# link to a210_page
				require App::210::_init;
				if (my $category=App::510::functions::_a210_by_cat([$db_entity{'ID_category'}],'lng'=>$tom::lng))
				{
					my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
					foreach my $p(
						App::020::SQL::functions::tree::get_path(
							$category,
							%sql_def,
							'-slave' => 1,
							'-cache' => 86400*7
						)
					)
					{
						push @{$db_entity{'a210'}{'IDs'}}, $p->{'ID'};
						push @{$db_entity{'a210'}{'nodes'}}, $p;
						$db_entity{'a210'}{'path_url'}.="/".$p->{'name_url'};
					}
					$db_entity{'a210'}{'path_url'}=~s|^/||;
				}
			}
			
			if ($db_entity{'ID_part'})
			{
				my $relation=(App::160::SQL::get_relations(
					'l_prefix' => 'a510',
					'l_table' => 'video_part',
					'l_ID_entity' => $db_entity{'ID_part'},
					'rel_type' => 'thumbnail',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'limit' => 1
				))[0];
				if ($relation->{'ID'})
				{
					$db_entity{'thumbnail'}=$relation->{'r_ID_entity'};
					push @{$self->{'thumbnail'}},$relation->{'r_ID_entity'} if $tag eq "img";
				}
			}
			
		}
		elsif ($entity eq "a520_audio")
		{
			# get data
			require App::520::_init;
			%db_entity=App::520::functions::get_audio_part_file(
				'audio.ID_entity' => $vars{'ID_entity'},
				'audio_part.part_id' => 1,
				'audio_part_file.ID_format' => $vars{'ID_format'} || 1,
				'audio_attrs.lng' => $tom::lng
			);
			
			if ($db_entity{'ID_category'})
			{
				# link to a210_page
#				require App::210::_init;
#				if (my $category=App::520::functions::_a210_by_cat([$db_entity{'ID_category'}],'lng'=>$tom::lng))
#				{
#					my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
#					foreach my $p(
#						App::020::SQL::functions::tree::get_path(
#							$category,
#							%sql_def,
#							'-slave' => 1,
#							'-cache' => 86400*7
#						)
#					)
#					{
#						push @{$db_entity{'a210'}{'IDs'}}, $p->{'ID'};
#						push @{$db_entity{'a210'}{'nodes'}}, $p;
#						$db_entity{'a210'}{'path_url'}.="/".$p->{'name_url'};
#					}
#					$db_entity{'a210'}{'path_url'}=~s|^/||;
#				}
			}
			
			if ($db_entity{'ID_part'})
			{
				my $relation=(App::160::SQL::get_relations(
					'l_prefix' => 'a520',
					'l_table' => 'audio_part',
					'l_ID_entity' => $db_entity{'ID_part'},
					'rel_type' => 'thumbnail',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'limit' => 1
				))[0];
				if ($relation->{'ID'})
				{
					$db_entity{'thumbnail'}=$relation->{'r_ID_entity'};
					push @{$self->{'thumbnail'}},$relation->{'r_ID_entity'} if $tag eq "img";
				}
			}
			
		}
		elsif ($entity eq "a542_file")
		{
			# get data
			require App::542::_init;
			
			my $sql_where;
			my @sql_bind;
			
			if ($vars{'ID_entity'})
			{
				$sql_where.=" AND file.ID_entity=?";
				push @sql_bind, $vars{'ID_entity'};
			}
			elsif ($vars{'ID'})
			{
				$sql_where.=" AND file.ID=?";
				push @sql_bind, $vars{'ID'};
			}
			
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					file.ID_entity AS ID_entity,
					file.ID AS ID,
					file_attrs.ID AS attrs_ID,
					file_item.ID AS item_ID,
					
					file_attrs.ID_category,
					file_dir.name AS dir_name,
					file_dir.name_url AS dir_name_url,
					
					file_ent.posix_owner,
					file_ent.posix_author,
					file_ent.datetime_publish_start,
					file_ent.datetime_publish_stop,
					
					file_item.hash_secure,
					file_item.datetime_create,
					
					file_attrs.name,
					file_attrs.name_url,
					file_attrs.name_ext,
					
					file_item.mimetype,
					file_item.name AS file_name,
					file_item.file_ext,
					file_item.file_size,
					file_item.lng,
					
					file_ent.downloads,
					
					file_attrs.status,
					
					CONCAT(file_item.lng,'/',SUBSTR(file_item.ID,1,4),'/',file_item.name,'.',file_item.file_ext) AS file_path
					
				FROM
					`$App::542::db_name`.`a542_file` AS file
				INNER JOIN `$App::542::db_name`.`a542_file_ent` AS file_ent ON
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
					file_ent.ID AND
					file_attrs.ID AND
					file_item.ID
					$sql_where
			},'quiet'=>1,'bind'=>[@sql_bind],'-slave'=>1,
				'-changetime'=>App::020::SQL::functions::_get_changetime(
					{
						'db_h'=>"main",
						'db_name' => $App::542::db_name,
						'tb_name' => "a542_file",
						'ID_entity' => do{$vars{'ID_entity'} if $vars{'ID_entity'}=~/^\d+$/}
					})
			);
			
			%db_entity=$sth0{'sth'}->fetchhash();
			main::_log("found ID=$db_entity{'ID'} ID_entity=$db_entity{'ID_entity'}");
			
		}
		elsif ($entity eq "a900_banner")
		{
			# get data
			require App::900::_init;
			
			my $sql_where;
			my @sql_bind;
			
			if ($vars{'ID_entity'})
			{
				$sql_where.=" AND banner.ID_entity=?";
				push @sql_bind, $vars{'ID_entity'};
			}
			elsif ($vars{'ID'})
			{
				$sql_where.=" AND banner.ID=?";
				push @sql_bind, $vars{'ID'};
			}
			
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
				
					`banner`.*,
					`banner_lng`.*,
					`banner`.ID,
					`banner`.ID_entity,
					`banner_lng`.ID AS lng_ID,
					`banner_lng`.ID_entity AS lng_ID_entity,
					
					`banner_zonetarget`.name AS zonetarget_name,
					
					`banner_cat`.`ID` AS `cat_ID`,
					`banner_cat`.`ID_entity` AS `cat_ID_entity`,
					`banner_cat`.`name` AS `cat_name`
					
				FROM `$App::900::db_name`.`a900_banner` AS `banner`
				
				INNER JOIN $App::900::db_name.a900_banner_lng AS banner_lng ON
				(
					banner_lng.ID_entity = banner.ID_entity AND
					banner_lng.lng = ?
				)
				LEFT JOIN `$App::900::db_name`.a900_banner_zonetarget AS banner_zonetarget ON
				(
					banner_zonetarget.ID_entity = banner.ID_zonetarget
				)
				LEFT JOIN $App::900::db_name.a900_banner_rel_cat AS banner_rel_cat ON
				(
					banner_rel_cat.ID_banner = banner.ID_entity
				)
				LEFT JOIN $App::900::db_name.a900_banner_cat AS banner_cat ON
				(
					banner_cat.ID_entity = banner_rel_cat.ID_category AND
					banner_cat.status IN ('Y','N','L')
				)
				LEFT JOIN $App::900::db_name.a900_banner_rel_domain AS banner_rel_domain ON
				(
					banner_rel_domain.ID_banner = banner.ID_entity
				)
				LEFT JOIN $App::900::db_name.a900_banner_domain AS banner_domain ON
				(
					banner_domain.ID_entity = banner_rel_domain.ID_domain AND
					banner_domain.status IN ('Y','N','L')
				)
				WHERE
					`banner`.status IN ('Y','N','L','W')
					$sql_where
				LIMIT
					1
			},'quiet'=>1,'bind'=>[$self->{'lng'},@sql_bind],'-slave'=>1,
				'-changetime'=>App::020::SQL::functions::_get_changetime(
					{
						'db_h'=>"main",
						'db_name' => $App::900::db_name,
						'tb_name' => "a900_banner",
						'ID_entity' => do{$vars{'ID_entity'} if $vars{'ID_entity'}=~/^\d+$/}
					})
			);
			
			%db_entity=$sth0{'sth'}->fetchhash();
			main::_log("found ID=$db_entity{'ID'} ID_entity=$db_entity{'ID_entity'}");
			
		}
		
		# selection which entry name in tpl will be used to process
		my $tpl_src='tpl';
		my $tpl_entity;
		# if tpl is extended by module tpl, then search for entries with prefix "parser."
		if ($self->{'tpl_ext'} && $self->{'env'}->{'prefix'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity;
		}
		elsif ($self->{'tpl_ext'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$tag.'.'.$entity})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$tag.'.'.$entity;
		}
		# otherwise use native entry from tpl
		elsif ($self->{'env'}->{'prefix'}
			&& exists $self->{'tpl'}->{'entity'}{$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity})
		{
			$tpl_entity=$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity;
		}
		elsif (exists $self->{'tpl'}->{'entity'}{$tag.'.'.$entity})
		{
			$tpl_entity=$tag.'.'.$entity;
		}
		
		# if found entry name, process it by tt2
		if ($tpl_entity) # tt2 process
		{
			my %variables;
			%{$variables{'request'}->{'env'}}=%main::env;
			%{$variables{'request'}->{'ENV'}}=%main::ENV;
			$variables{'request'}->{'param'}=\%main::FORM;
			$variables{'request'}->{'timestamp'}=$main::time_current;
			if ($self->{$tpl_src}->process({
				'entity' => {
					'tag' => $tag,
					'attr' => $attr,
					'id' => \%vars,
					'db' => \%db_entity
				},
				'lng' => $self->{'lng'},
				'env' => $self->{'env'},
				'count' => {
					'tag' => $self->{'count'}{'tag'}{$tag},
					'addon' => $self->{'count'}{'addon'}{$entity}
				},
				'domain' => {
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
					'setup' => \%tom::setup
				},
				%variables
#				'entity'=>\%db0_line
				},$tpl_entity))
			{
				$tag_output=$self->{$tpl_src}->{'output'};
			}
			else
			{
				$tag_output=$self->{$tpl_src}->{'error'}
			}
		}
		
#		main::_log("$tag src=$tpl_src entity=$tpl_entity");
		
#	{
#		$self->{'entity_tt'}=$name
#			if $tpl->{'entity_'}{$name}{'tt'} eq "true";
#		return $tpl->{'entity'}{$name};
#	}
		
	}
	
	if (($tag eq "var" || $tag eq "pre") && $attr->{'class'} eq "script")
	{
		my $entity='script';
		
		# selection which entry name in tpl will be used to process
		my $tpl_src='tpl';
		my $tpl_entity;
		
		# if tpl is extended by module tpl, then search for entries with prefix "parser."
		if ($self->{'tpl_ext'}
			&& $self->{'env'}->{'prefix'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity;
		}
		elsif ($self->{'tpl_ext'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$tag.'.'.$entity})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$tag.'.'.$entity;
		}
		# otherwise use native entry from tpl
		elsif ($self->{'env'}->{'prefix'}
			&& exists $self->{'tpl'}->{'entity'}{$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity})
		{
			$tpl_entity=$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity;
		}
		elsif (exists $self->{'tpl'}->{'entity'}{$tag.'.'.$entity})
		{
			$tpl_entity=$tag.'.'.$entity;
		}
		
		$tag_output=$self->{'tpl'}->{'entity'}{$tpl_entity};
		
		
		my $tpl_entity;
		
		# if tpl is extended by module tpl, then search for entries with prefix "parser."
		if ($self->{'tpl_ext'}
			&& $self->{'env'}->{'prefix'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity.'.close'})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity.'.close';
		}
		elsif ($self->{'tpl_ext'}
			&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$tag.'.'.$entity.'.close'})
		{
			$tpl_src.='_ext';
			$tpl_entity='parser.'.$tag.'.'.$entity.'.close';
		}
		# otherwise use native entry from tpl
		elsif ($self->{'env'}->{'prefix'}
			&& exists $self->{'tpl'}->{'entity'}{$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity.'.close'})
		{
			$tpl_entity=$self->{'env'}->{'prefix'}.'.'.$tag.'.'.$entity.'.close';
		}
		elsif (exists $self->{'tpl'}->{'entity'}{$tag.'.'.$entity.'.close'})
		{
			$tpl_entity=$tag.'.'.$entity.'.close';
		}
		
		$self->{'closetag'}->[$self->{'level'}] = $self->{'tpl'}->{'entity'}{$tpl_entity};
		
	}
	
	if ($tag eq "p")
	{
		if (!$attr->{'id'} && $attr->{'entity_part'} && $self->{'config'}->{'editable'})
		{
			$attr->{'rel'}="editable";
		}
		
		if (!$self->{'config'}->{'editable'})
		{
			delete $attr->{'entity_part'};
			delete $attr->{'rel'};
		}
		
	}
	
	if (!$tag_output)
	{
#		main::_log("rebuild tag '$tag'");
		# rebuild a tag
		my %attrs_;
		my $tag_tmp="<$tag";
		foreach (@{$attrseq})
		{
			next if $_ eq '/';
			next unless exists $attr->{$_};
			$tag_tmp.=' '.$_.'="'._escape_attr($attr->{$_}).'"';
			$attrs_{$_}=1;
		}
		foreach (keys %{$attr})
		{
			next if $_ eq '/';
			next if $attrs_{$_};
			$tag_tmp.=' '.$_.'="'._escape_attr($attr->{$_}).'"';
		}
		$tag_tmp.=" /" if $attr->{'/'};
		$tag_tmp.=">";
		
#		main::_log("generate output '$tag_output'");
		
		# fill into out_full
		$tag_output=$tag_tmp;
	}
	else
	{
#		main::_log("just output '$tag_output'");
	}
	
	if ($attr->{'/'})
	{
		$self->{'level'}--;
	}
	
	if ($self->{'level.inline'} && ($self->{'level'} > $self->{'level.inline'}
		|| ($attr->{'/'} && $self->{'level'} >= $self->{'level.inline'})
	))
	{
		$self->{'output.inline'}.=$tag_output;
	}
	else
	{
		$self->{'output'}.=$tag_output;
	}
}



sub end
{
	my ($self, $tag, $origtext) = @_;
	
	if ($self->{'stop'})
	{
		if ($self->{'stop.level'} < $self->{'level'})
		{
			$self->{'level'}--;
			return;
		}
		elsif ($self->{'stop.level'} == $self->{'level'})
		{
			$self->{'stop.level'}--;
		}
	}
	
	if ($self->{'level.ignore'} && ($self->{'level.ignore'} < $self->{'level'}))
	{
		$self->{'level'}--;
		return;
	}
	elsif ($self->{'level.ignore'} == $self->{'level'})
	{
		delete $self->{'level.ignore'};
	}
	
	if ($self->{'level.inline'} && $self->{'level.inline'} <= $self->{'level'})
	{

		if ($self->{'level.inline'} == $self->{'level'})
		{
			delete $self->{'level.inline'};

			# process inline
			my $t=track TOM::Debug("section embed");

			my $p=new App::020::mimetypes::html(
				'tpl_ext' => $self->{'tpl_ext'},
				'lng' => $self->{'lng'}
			);
			$p->config_from($self);
			delete $p->{'config'}->{'editable'};
			$p->{'config'}->{'inline'}=1; # this is inline article
			$p->parse($self->{'output.inline'});
			$p->eof();
			undef $p->{'config'}->{'inline'};
			my %entity;
			$entity{'parser'}={
				'output' => $p->{'output'},
				'addon' => $p->{'addon'},
				'entity' => $p->{'entity'},
				'thumbnail' => $p->{'thumbnail'},
			};
			$t->close();

			# process output
			my $tpl_src='tpl';
			my $tpl_entity;
			my $tag='section.inline';
			my $tag_output;

			# if tpl is extended by module tpl, then search for entries with prefix "parser."
			if ($self->{'tpl_ext'} && $self->{'env'}->{'prefix'}
				&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$self->{'env'}->{'prefix'}.'.'.$tag})
			{
				$tpl_src.='_ext';
				$tpl_entity='parser.'.$self->{'env'}->{'prefix'}.'.'.$tag;
			}
			elsif ($self->{'tpl_ext'}
				&& exists $self->{'tpl_ext'}->{'entity'}{'parser.'.$tag})
			{
				$tpl_src.='_ext';
				$tpl_entity='parser.'.$tag;
			}
			# otherwise use native entry from tpl
			elsif ($self->{'env'}->{'prefix'}
				&& exists $self->{'tpl'}->{'entity'}{$self->{'env'}->{'prefix'}.'.'.$tag})
			{
				$tpl_entity=$self->{'env'}->{'prefix'}.'.'.$tag;
			}
			elsif (exists $self->{'tpl'}->{'entity'}{$tag})
			{
				$tpl_entity=$tag;
			}

			# if found entry name, process it by tt2
			if ($tpl_entity) # tt2 process
			{
				my %variables;
				%{$variables{'request'}->{'env'}}=%main::env;
				%{$variables{'request'}->{'ENV'}}=%main::ENV;
				$variables{'request'}->{'param'}=\%main::FORM;
				$variables{'request'}->{'timestamp'}=$main::time_current;
				if ($self->{$tpl_src}->process({
					'entity' => {
						'tag' => $tag,
						'attr' => $self->{'attr'}[$self->{'level'}],
						'parser' => $entity{'parser'}
					},
					'lng' => $self->{'lng'},
					'env' => $self->{'env'},
					'domain' => {
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
						'setup' => \%tom::setup
					},
					%variables,
#					'entity'=>\%entity
					},$tpl_entity))
				{
					$tag_output=$self->{$tpl_src}->{'output'};
				}
				else
				{
					$tag_output=$self->{$tpl_src}->{'error'}
				}
			}

			$self->{'output'}.=$tag_output;

			$self->{'output'}.=$self->{'closetag'}[$self->{'level'}] || $origtext;

			# clean
			
			delete $self->{'output.inline'};
		}
		else
		{
			$self->{'output.inline'}.=$self->{'closetag'}[$self->{'level'}] || $origtext;
		}

		delete $self->{'closetag'}[$self->{'level'}];
		delete $self->{'attr'}[$self->{'level'}];

		$self->{'level'}--;
		return;
	}

	# print out original text
	$self->{'output'}.=$self->{'closetag'}[$self->{'level'}] || $origtext;
	
	delete $self->{'closetag'}[$self->{'level'}];
	delete $self->{'attr'}[$self->{'level'}];
	
	$self->{'level'}--;
}



sub config_from
{
	my $self=shift; # new object
	my $self_old=shift; # old object
	
#	foreach (keys %{$self_old->{'entity'}})
#	{
#		$self->{'entity'}{$_}=$self_old->{'entity'}{$_};
#	}
	
#	foreach (keys %{$self_old->{'config'}})
#	{
#		$self->{'config'}->{$_}=$self_old->{'config'}->{$_};
#	}
	
#	foreach (keys %{$self_old->{'count'}})
#	{
#		$self->{'count'}->{$_}=$self_old->{'count'}->{$_};
#	}
	
#	foreach (keys %{$self_old->{'out_var'}})
#	{
#		$self->{'out_var'}->{$_}=$self_old->{'out_var'}->{$_};
#	}
	
#	foreach (keys %{$self_old->{'out_addon'}})
#	{
#		$self->{'out_addon'}->{$_}=$self_old->{'out_addon'}->{$_};
#	}
	
#	foreach (keys %{$self_old->{'out_tag'}})
#	{
#		$self->{'out_tag'}->{$_}=$self_old->{'out_tag'}->{$_};
#	}
	
}



sub config
{
	my $self=shift;
	my %config=@_;
	
}



1;
