#!/bin/perl
package App::020::mimetypes::html_save;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



use App::020::_init;
use base "HTML::Parser";


sub _escape_attr
{
	my $attr=shift;
	$attr=~s|"|'|g;
	return $attr;
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

sub text
{
	my ($self, $text) = @_;
	
	if ($self->{'embed'} && $self->{'embed'}->{'tag'})
	{
		main::_log(" process '$self->{'embed'}->{'tag'}' with '$text' in embed '$self->{'embed'}->{'name'}'");
		
		if ($self->{'embed'}->{'tag'} eq "li")
		{
			push @{$self->{'embed'}->{'data'}->{'answer'}}, {
				'id' => $self->{'embed'}->{'tag.attr'}->{'id'},
				'text' => $text
			};
		}
		elsif ($self->{'embed'}->{'tag'} eq "p")
		{
			$self->{'embed'}->{'data'}->{'question'} = $text;
		}
		elsif ($self->{'embed'}->{'tag'} eq "h4")
		{
			$self->{'embed'}->{'data'}->{'name'} = $text;
		}
		
		# processed
		delete $self->{'embed'}->{'tag'}; # last tag found in "embed"
		delete $self->{'embed'}->{'tag.attr'};
	}
	
	if ($self->{'level.ignore'} && $self->{'level.ignore'} <= $self->{'level'})
	{
		return;
	}
	
	$self->{'out'}.=$text;
}


sub comment
{
	my ($self, $comment) = @_;
}


sub start
{
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;
	$tag=~s|/$||;
	
	$self->{'level'}++;
	
	main::_log("[$tag] level=".$self->{'level'});
	
	# fix not closed tags
	$attr->{'/'}='/' if $tag=~/^hr|br|img$/;
	
	if ($self->{'embed'})
	{
#		main::_log(" process '$tag' embed");
		$self->{'embed'}->{'tag'} = $tag;
		$self->{'embed'}->{'tag.attr'} = $attr;
	}
	
	if ($self->{'level.ignore'} && $self->{'level.ignore'} < $self->{'level'})
	{
		if ($attr->{'/'})
		{
			$self->{'level'}--;
		}
		return;
	}
	
	if ($tag eq "div")
	{
		if ($attr->{'class'} eq "a411_poll")
		{
			main::_log("ignore level=".$self->{'level'});
			$self->{'level.ignore'}=$self->{'level'};
			$self->{'embed'}={
				'name' => 'a411_poll',
				'attr' => $attr,
				'attrseq' => $attrseq
			};
		}
		elsif ($attr->{'class'} eq "a030_instagram")
		{
			main::_log("ignore level=".$self->{'level'});
			$self->{'level.ignore'}=$self->{'level'};
			$self->{'embed'}={
				'name' => 'a030_instagram',
				'attr' => $attr,
				'attrseq' => $attrseq
			};
		}
	}
	elsif ($tag eq "p")
	{
		if (!$attr->{'id'})
		{
			# bezny tag s obsahom
			if (!$attr->{'entity_part'} || $self->{'entity_parts'}->{$attr->{'entity_part'}})
			{
				# chyba unikatne oznacenie, doplnime
				$attr->{'entity_part'}=Utils::vars::genhash_N(4);
				$self->{'entity_parts'}->{$attr->{'entity_part'}}++;
			}
			else
			{
				$self->{'entity_parts'}->{$attr->{'entity_part'}}++;
			}
		}
	}
	elsif ($tag eq "img")
	{
		if ($attr->{'style'}=~s|width:[ ]?(\d+)px[;]?[ ]?||)
		{
			$attr->{'width'}=$1.'px';
		}
		if ($attr->{'style'}=~s|height:[ ]?(\d+)px[;]?[ ]?||)
		{
			$attr->{'height'}=$1.'px';
		}
	}
	
	delete $attr->{'style'} unless $attr->{'style'};
	
	# rebuild a tag
	my %attrs_;
	my $out="<$tag";
	if (!$self->{'embed'})
	{
		foreach (@{$attrseq})
		{
			next if $_ eq '/';
			next unless exists $attr->{$_};
			$out.=' '.$_.'="'.(_escape_attr($attr->{$_})).'"';
			$attrs_{$_}=1;
		}
		foreach (keys %{$attr})
		{
			next if $_ eq '/';
			next if $attrs_{$_};
			$out.=' '.$_.'="'.(_escape_attr($attr->{$_})).'"';
		}
		$out.=" /" if $attr->{'/'};
		$out.=">";
	}
	
	if ($attr->{'/'})
	{
		$self->{'level'}--;
	}
	
	$self->{'out'}.=$out;
}


sub end
{
	my ($self, $tag, $origtext) = @_;
	
	if ($self->{'level.ignore'} && ($self->{'level.ignore'} < $self->{'level'}))
	{
		$self->{'level'}--;
		return;
	}
	elsif ($self->{'level.ignore'} == $self->{'level'})
	{
		delete $self->{'level.ignore'};
		
		if ($self->{'embed'})
		{
			main::_log(" stopping embed '$self->{'embed'}->{'name'}', processing");
			
			$self->{'embed'}->{'attr'}->{'id'}=~s|^(.*?):||;
			%{$self->{'embed'}->{'id'}}=_parse_id($self->{'embed'}->{'attr'}->{'id'});
			
			$self->{'embed'}->{'attr'}->{'id'}=$self->{'embed'}->{'name'};
			if ($self->{'embed'}->{'name'} eq "a411_poll")
			{
				my %poll;
				if (!$self->{'embed'}->{'id'}->{'ID_entity'}) # create a new one
				{
					delete $self->{'embed'}->{'id'};
#					$self->{'embed'}->{'id'}->{'ID_entity'}='321';
					require App::411::_init;
					$self->{'embed'}->{'id'}->{'ID_entity'}=App::020::SQL::functions::new(
						'db_h' => "main",
						'db_name' => $App::411::db_name,
						'tb_name' => "a411_poll",
						'-journalize' => 1,
						'data' => {
							'name' => $self->{'embed'}->{'data'}->{'name'},
							'lng' => $tom::lng,
							'status' => 'Y'
						},
						'columns' =>
						{
#							'name' => "'".(TOM::Security::form::sql_escape($env{'poll.name'}))."'",
							'ID_category' => $App::411::system_cat_ID_entity,
							'datetime_start' => 'NOW()',
							'datetime_voting_start' => 'NOW()',
#							'lng'  => "'$env{'lng'}'",
#							'status'  => "'N'",
						}
					);
				}
				else
				{
					my %sth0=TOM::Database::SQL::execute(qq{
						SELECT
							*
						FROM
							`$App::411::db_name`.a411_poll
						WHERE
							ID_entity= ?
						LIMIT 1
					},'bind'=>[$self->{'embed'}->{'id'}->{'ID_entity'}],'quiet'=>1);
					%poll=$sth0{'sth'}->fetchhash();
				}
				
				my %data;
				$data{'name'}=$self->{'embed'}->{'data'}->{'name'}
					if ($poll{'name'} ne $self->{'embed'}->{'data'}->{'name'});
				$data{'description'}=$self->{'embed'}->{'data'}->{'question'}
					if ($poll{'description'} ne $self->{'embed'}->{'data'}->{'question'});
				if (keys %data)
				{
					App::020::SQL::functions::update(
						'db_h' => "main",
						'db_name' => $App::411::db_name,
						'tb_name' => "a411_poll",
						'ID' => $self->{'embed'}->{'id'}->{'ID_entity'},
						'-journalize' => 1,
						'data' => {%data}
					);
				}
				
				# answers
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						*
					FROM
						`$App::411::db_name`.a411_poll_answer
					WHERE
						ID_poll = ?
						AND status = 'Y'
					ORDER BY
						ID
				},'quiet' => 1,'bind' => [
					$self->{'embed'}->{'id'}->{'ID_entity'}
				]);
				while (my %db0_line=$sth0{'sth'}->fetchhash())
				{
					my $found;
					foreach my $answer (@{$self->{'embed'}->{'data'}->{'answer'}})
					{
						if ($answer->{'id'} == $db0_line{'ID'})
						{
							if ($answer->{'text'} ne $db0_line{'name'})
							{
								App::020::SQL::functions::update(
									'db_h' => "main",
									'db_name' => $App::411::db_name,
									'tb_name' => "a411_poll_answer",
									'ID' => $db0_line{'ID'},
									'data' => {
										'name' => $answer->{'text'}
									},
									'-journalize' => 1,
								);
							}
							undef $answer->{'text'};
							undef $answer->{'id'};
							$found=1;
							last;
						}
					}
					if (!$found)
					{
						main::_log("not found answer in definition",1);
						App::020::SQL::functions::to_trash(
							'db_h' => "main",
							'db_name' => $App::411::db_name,
							'tb_name' => "a411_poll_answer",
							'ID' => $db0_line{'ID'},
							'-journalize' => 1,
						);
					}
				}
				foreach my $answer (@{$self->{'embed'}->{'data'}->{'answer'}})
				{
					next unless $answer->{'text'};
					main::_log("writing new answer '$answer->{'text'}'");
					$answer->{'id'}=App::020::SQL::functions::new(
						'db_h' => "main",
						'db_name' => $App::411::db_name,
						'tb_name' => "a411_poll_answer",
						'-journalize' => 1,
						'data' => {
							'name' => $answer->{'text'},
							'lng'  => $tom::lng,
						},
						'columns' =>
						{
							'ID_poll' => $self->{'embed'}->{'id'}->{'ID_entity'},
							'status'  => "'Y'",
						}
					);
				}
				
			}
			elsif ($self->{'embed'}->{'name'} eq "a030_instagram")
			{
				
#				$self->{'embed'}->{'id'}->{'ID'}='a';
				
			}
			
			$self->{'embed'}->{'attr'}->{'id'}.=":ID_entity=".$self->{'embed'}->{'id'}->{'ID_entity'}
				if $self->{'embed'}->{'id'}->{'ID_entity'};
			$self->{'embed'}->{'attr'}->{'id'}.=":ID=".$self->{'embed'}->{'id'}->{'ID'}
				if $self->{'embed'}->{'id'}->{'ID'};
			
			my $out;
			my %attrs_;
			my $attrseq=$self->{'embed'}{'attrseq'};
			my $attr=$self->{'embed'}{'attr'};
			foreach (@{$attrseq})
			{
				next if $_ eq '/';
				next unless exists $attr->{$_};
				$out.=' '.$_.'="'.(_escape_attr($attr->{$_})).'"';
				$attrs_{$_}=1;
			}
			foreach (keys %{$attr})
			{
				next if $_ eq '/';
				next if $attrs_{$_};
				$out.=' '.$_.'="'.(_escape_attr($attr->{$_})).'"';
			}
			$out.=" /" if $attr->{'/'};
			$out.=">";
			
			$origtext=$out.$origtext;
		}
		
		delete $self->{'embed'};
	}
	
	main::_log("[/$tag] level=".$self->{'level'});
	
	$self->{'level'}--;
	
	$self->{'out'}.=$origtext;
}


1;
