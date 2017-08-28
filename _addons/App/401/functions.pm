#!/bin/perl
package App::401::functions;

=head1 NAME

App::401::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::401::_init|app/"401/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::401::_init;
use TOM::Security::form;
use Time::HiRes qw(usleep);
use Ext::TextHyphen::_init;
use Ext::Redis::_init;
use Ext::Elastic::_init;

our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head2 article_add()

Adds new article to category, or updates old article

Add new article (uploading new content)

 article_add
 (
   'article.ID' => '',
   'article.ID_entity' => '',
   'article_ent.ID_author' => '',
   'article_attrs.ID_category' => '',
   'article_attrs.name' => '',
   'article_attrs.lng' => '',
   'article_content.ID_editor' => '',
   'article_content.subtitle' => '',
   'article_content.mimetype' => '',
   'article_content.abstract' => '',
   'article_content.body' => '',
   #'article_content.keywords' => '',
   'article_content.lng' => '',
 );

Add new symlink to article in another directory (or the same with another name)

 article_add
 (
   'article.ID_entity' => '',
   'article_attrs.ID_category' => '',
 );

Move article to another directory (new ID of category for symlink defined)

 article_add
 (
   'article.ID' => '',
   'article_attrs.ID_category' => '',
 );

=cut

sub article_add
{
	my %env=@_;
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::401::db_name,'class'=>'fifo'}); # do it in background
	}
	
	my $t=track TOM::Debug(__PACKAGE__."::article_add()",'timer'=>1);
	
	$env{'article_content.mimetype'}="text/html" unless $env{'article_content.mimetype'};
	
	my $content_updated=0; # boolean if important content attributes was updated
	my $content_reindex=0; # boolean if is required to update searchindex
	
	# detect language
	my %article_cat;
	if ($env{'article_attrs.ID_category'})
	{
		# detect language
		%article_cat=App::020::SQL::functions::get_ID(
			'ID' => $env{'article_attrs.ID_category'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_cat",
			'columns' => {'*'=>1}
		);
		$env{'article_attrs.lng'}=$article_cat{'lng'};
		main::_log("setting lng='$env{'article_attrs.lng'}' from article_attrs.ID_category='$env{'article_attrs.ID_category'}'");
	}
	
	$env{'article_attrs.lng'}=$tom::lng unless $env{'article_attrs.lng'};
	main::_log("lng='$env{'article_attrs.lng'}' (first try)");
	
	# ARTICLE
	
	my %article;
	if ($env{'article.ID'})
	{
		# detect language
		%article=App::020::SQL::functions::get_ID(
			'ID' => $env{'article.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article",
			'columns' => {'*'=>1}
		);
		$env{'article.ID_entity'}=$article{'ID_entity'} if $article{'ID_entity'};
	}
	
#	if (!$env{'article.ID'})
#	{
#		$env{'article.ID'}=$article{'ID'} if $article{'ID'};
#	}
	
	
	# check if this symlink with same ID_category not exists
	# and article.ID is unknown
	if ($env{'article_attrs.ID_category'} && !$env{'article.ID'} && $env{'article.ID_entity'} && !$env{'forcesymlink'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::401::db_name`.`a401_article_view`
			WHERE
				ID_entity_article=$env{'article.ID_entity'} AND
				( ID_category = $env{'article_attrs.ID_category'} OR ID_category IS NULL ) AND
				status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID'})
		{
			$env{'article.ID'}=$db0_line{'ID_article'};
			$env{'article_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup article.ID='$db0_line{'ID_article'}'");
		}
	}
	
	if (!$article{'ID'} && $env{'article.ID_entity'})
	{
		# check if this article exists
		# - not necessary :)
		
	}
	
	main::_log("status article.ID='$env{'article.ID'}' article.ID_entity='$env{'article.ID_entity'}'");
	
	
	if (!$env{'article.ID'})
	{
		# generating new article!
		main::_log("adding new regular article");
		
		my %columns;
		$columns{'ID_entity'}=$env{'article.ID_entity'} if $env{'article.ID_entity'};
		
		$env{'article.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		
		main::_log("generated article ID='$env{'article.ID'}'");
		$content_updated=1;
	}
	
	
	if (!$env{'article.ID_entity'})
	{
		if ($article{'ID_entity'})
		{
			$env{'article.ID_entity'}=$article{'ID_entity'};
		}
		elsif ($env{'article.ID'})
		{
			%article=App::020::SQL::functions::get_ID(
				'ID' => $env{'article.ID'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article",
				'columns' => {'*'=>1}
			);
			$env{'article.ID_entity'}=$article{'ID_entity'};
		}
		else
		{
			die "ufff\n";
		}
	}
	
	if (!$env{'article.ID_entity'})
	{
		die "ufff, missing article.ID_entity\n";
	}
	
	
	# ARTICLE_ATTRS
	
	my %article_attrs;
	if (!$env{'article_attrs.ID'})
	{
		main::_log("!\$env{'article_attrs.ID'} -> SELECT");
		my $sql=qq{
			SELECT
				ID,lng
			FROM
				`$App::401::db_name`.`a401_article_attrs`
			WHERE
				ID_entity='$env{'article.ID'}' AND
				lng='$env{'article_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%article_attrs=$sth0{'sth'}->fetchhash();
		if ($article_attrs{'ID'})
		{
			$env{'article_attrs.ID'}=$article_attrs{'ID'};
			$env{'article_attrs.lng'}=$article_attrs{'lng'};
			main::_log("setup article_attrs.lng='$env{'article_attrs.lng'}'");
		}
	}
	if (!$env{'article_attrs.ID'})
	{
		main::_log("!\$env{'article_attrs.ID'} -> new()");
		# create one language representation of article in content structure
		my %columns;
		$columns{'ID_category'}=$env{'article_attrs.ID_category'} if $env{'article_attrs.ID_category'};
		$columns{'datetime_start'}="'".$env{'article_attrs.datetime_start'}."'" if $env{'article_attrs.datetime_start'};
		$columns{'datetime_start'}=$env{'article_attrs.datetime_start'} if ($env{'article_attrs.datetime_start'} && (not $env{'article_attrs.datetime_start'}=~/^\d/));
		$columns{'datetime_start'}="NOW()" unless $columns{'datetime_start'};
		
		$env{'article_attrs.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_attrs",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'article.ID'},
#				'order_id' => $order_id,
				'lng' => "'$env{'article_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
		
		if ($columns{'ID_category'}) # article_cat.ID (i need ID_entity)
		{
			my %cat=App::020::SQL::functions::get_ID(
				'ID' => $columns{'ID_category'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article_cat",
				'columns' => {'ID_entity'=>1}
			);
			App::020::SQL::functions::_save_changetime(
				{'db_h'=>'main','db_name'=>$App::401::db_name,'tb_name'=>'a401_article_cat','ID_entity'=>$cat{'ID_entity'}}
			);
		}
		
		$content_updated=1;
		$content_reindex=1;
	}
	if ($env{'article_attrs.ID'} && !$article_attrs{'ID_category'})
	{
		main::_log("\$env{'article_attrs.ID'} && !\$article_attrs{'ID_category'} -> get_ID()");
		%article_attrs=App::020::SQL::functions::get_ID(
			'ID' => $env{'article_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_attrs",
			'columns' => {'*'=>1}
		);
		$env{'article_attrs.lng'}=$article_attrs{'lng'};
	}
	
	# update if necessary
	if ($env{'article_attrs.ID'})
	{
		my %columns;
		# name
		$env{'article_attrs.name'}=~s|$soft_hyphen||g;
		if ($env{'article_attrs.name'} && ($env{'article_attrs.name'} ne $article_attrs{'name'}))
		{
			$columns{'name'}="'".TOM::Security::form::sql_escape($env{'article_attrs.name'})."'";
			$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'article_attrs.name'}))."'";
			$columns{'name_hyphens'}="'". TOM::Security::form::sql_escape(join(",",Ext::TextHyphen::get_hyphens($env{'article_attrs.name'},'lng'=>$article_attrs{'lng'}))) ."'";
		}
		# ID_category
		$columns{'ID_category'}=$env{'article_attrs.ID_category'}
			if ($env{'article_attrs.ID_category'} && ($env{'article_attrs.ID_category'} ne $article_attrs{'ID_category'}));
		# datetime_start
		$columns{'datetime_start'}="'".$env{'article_attrs.datetime_start'}."'"
			if ($env{'article_attrs.datetime_start'} && ($env{'article_attrs.datetime_start'} ne $article_attrs{'datetime_start'}));
		$columns{'datetime_start'}=$env{'article_attrs.datetime_start'}
			if (($env{'article_attrs.datetime_start'} && ($env{'article_attrs.datetime_start'} ne $article_attrs{'datetime_start'})) && (not $env{'article_attrs.datetime_start'}=~/^\d/));
			
		# datetime_stop
		if (exists $env{'article_attrs.datetime_stop'} && ($env{'article_attrs.datetime_stop'} ne $article_attrs{'datetime_stop'}))
		{
			if (!$env{'article_attrs.datetime_stop'})
			{
				$columns{'datetime_stop'}="NULL";
			}
			else
			{
				$columns{'datetime_stop'}="'".$env{'article_attrs.datetime_stop'}."'";
			}
		}
		# status
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'article_attrs.status'})."'"
			if ($env{'article_attrs.status'} && ($env{'article_attrs.status'} ne $article_attrs{'status'}));

		# alias_url		
		$columns{'alias_url'}="'".TOM::Security::form::sql_escape($env{'article_attrs.alias_url'})."'"
			if (exists $env{'article_attrs.alias_url'} && ($env{'article_attrs.alias_url'} ne $article_attrs{'alias_url'}));
		$columns{'alias_url'}="NULL" if $columns{'alias_url'} eq "''";

		# priority_A
		$columns{'priority_A'}="'".$env{'article_attrs.priority_A'}."'"
			if (exists $env{'article_attrs.priority_A'} && ($env{'article_attrs.priority_A'} ne $article_attrs{'priority_A'}));
		$columns{'priority_A'}="NULL" if $columns{'priority_A'} eq "''";
		# priority_B
		$columns{'priority_B'}="'".$env{'article_attrs.priority_B'}."'"
			if (exists $env{'article_attrs.priority_B'} && ($env{'article_attrs.priority_B'} ne $article_attrs{'priority_B'}));
		$columns{'priority_B'}="NULL" if $columns{'priority_B'} eq "''";
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'article_attrs.ID'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1 if $columns{'name'};
			$content_reindex=1 if $columns{'status'};
			
			if ($columns{'ID_category'}) # article_cat.ID (i need ID_entity)
			{
				my %cat=App::020::SQL::functions::get_ID(
					'ID' => $columns{'ID_category'},
					'db_h' => "main",
					'db_name' => $App::401::db_name,
					'tb_name' => "a401_article_cat",
					'columns' => {'ID_entity'=>1}
				);
				App::020::SQL::functions::_save_changetime( # changed all categories too (the content is added/removed)
					{'db_h'=>'main','db_name'=>$App::401::db_name,'tb_name'=>'a401_article_cat'}
				);
				App::020::SQL::functions::_save_changetime(
					{'db_h'=>'main','db_name'=>$App::401::db_name,'tb_name'=>'a401_article_cat','ID_entity'=>$cat{'ID_entity'}}
				);
			}
		}
	}
	
	main::_log("article_attrs.lng='$env{'article_attrs.lng'}' (real)");
	
	# ARTICLE_CONTENT
	
	my %article_content;
	$env{'article_content.lng'} = $env{'article_attrs.lng'} unless $env{'article_content.lng'};
	$env{'article_content.version'} = '0' unless $env{'article_content.version'};
	
	main::_log("processing article_content.version='$env{'article_content.version'}'");
	
	# NULL fix - ugly hack
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			ID,
			version
		FROM
			`$App::401::db_name`.`a401_article_content`
		WHERE
			ID_entity=? AND
			lng=? AND
			version IS NULL
	},'bind'=>[$env{'article.ID_entity'},$env{'article_content.lng'}],'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		TOM::Database::SQL::execute(qq{
			UPDATE
				`$App::401::db_name`.`a401_article_content`
			SET
				version=0
			WHERE
				ID_entity=? AND
				lng=? AND
				version IS NULL
		},'bind'=>[$env{'article.ID_entity'},$env{'article_content.lng'}],'quiet'=>1);
	}
	
	if (!$env{'article_content.ID'})
	{
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::401::db_name`.`a401_article_content`
			WHERE
				ID_entity=? AND
				lng=? AND
				version=?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[
			$env{'article.ID_entity'},
			$env{'article_content.lng'},
			$env{'article_content.version'}
		],'quiet'=>1);
		%article_content=$sth0{'sth'}->fetchhash();
		$env{'article_content.ID'}=$article_content{'ID'};
#		$env{'article_content.lng'}=$article_content{'lng'};
	}
	if (!$env{'article_content.ID'})
	{
		# create one language representation of article
		my %columns;
		$columns{'status'} = "'Y'";
		
		# when creating new version, then this version is by default disabled
		if ($env{'article_content.version'} != '0')
		{
			$columns{'status'} = "'N'";
		}
		
		$env{'article_content.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_content",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'article.ID_entity'},
				'lng' => "'$env{'article_content.lng'}'",
				'version' => "'$env{'article_content.version'}'",
			},
			'-journalize' => 1,
		);
		$content_updated=1;
		$content_reindex=1;
	}
	
	# get article_content
	if ($env{'article_content.ID'} && !$article_content{'body'})
	{
		%article_content=App::020::SQL::functions::get_ID(
			'ID' => $env{'article_content.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_content",
			'columns' => {'*'=>1}
		);
	}
	
	# generate keywords
	$env{'article_content.keywords'}=(split('#',$env{'article_content.keywords'}))[1] if ($env{'article_content.keywords'}=~/#/);
	
	if (exists $env{'article_content.keywords'})
	{
		my @ref=split('#',$article_content{'keywords'});
		$ref[1]=$env{'article_content.keywords'};
		1 while ($ref[0]=~s|^ ||);1 while ($ref[1]=~s|^ ||);
		1 while ($ref[0]=~s| $||);1 while ($ref[1]=~s| $||);
		$env{'article_content.keywords'}=$ref[0].' # '.$ref[1];
	}
	else {$env{'article_content.keywords'}=$article_content{'keywords'};}
	if (exists $env{'article_content.abstract'} || exists $env{'article_content.body'})
	{
		my @ref=split('#',$env{'article_content.keywords'});
		$ref[0]='';
		my %keywords=article_content_extract_keywords(%env);
		foreach (keys %keywords)
		{$ref[0].=", ".$_;}
		$ref[0]=~s|^, ||;
		1 while ($ref[0]=~s|^ ||);1 while ($ref[1]=~s|^ ||);
		1 while ($ref[0]=~s| $||);1 while ($ref[1]=~s| $||);
		$env{'article_content.keywords'}=$ref[0].' # '.$ref[1];
	}
	$env{'article_content.keywords'}='' if ($env{'article_content.keywords'} eq ' # ');
	$env{'article_content.keywords'}=~s|^[ ]?#[ ]?||;
	
	# update if necessary
	if ($env{'article_content.ID'})
	{
		main::_log("check for update article_content.ID=$env{'article_content.ID'}");
		my %columns;
		my %data;
		$env{'article_content.subtitle'}=~s|$soft_hyphen||g if (exists $env{'article_content.subtitle'});
		if (exists $env{'article_content.subtitle'} && ($env{'article_content.subtitle'} ne $article_content{'subtitle'}))
		{
			$columns{'subtitle'}="'".TOM::Security::form::sql_escape($env{'article_content.subtitle'})."'";
			$columns{'subtitle_hyphens'}="'". TOM::Security::form::sql_escape(join(",",Ext::TextHyphen::get_hyphens($env{'article_content.subtitle'},'lng'=>$article_content{'lng'}))) ."'";
		}
		$columns{'mimetype'}="'".TOM::Security::form::sql_escape($env{'article_content.mimetype'})."'"
			if ($env{'article_content.mimetype'} && ($env{'article_content.mimetype'} ne $article_content{'mimetype'}));
		$env{'article_content.abstract'}=~s|$soft_hyphen||g;
		if ($env{'article_content.abstract'} && ($env{'article_content.abstract'} ne $article_content{'abstract'}))
		{
			$columns{'abstract'}="'".TOM::Security::form::sql_escape($env{'article_content.abstract'})."'";
			my $text_plain=$env{'article_content.abstract'};
				$text_plain=~s/<(.*?)>/"<" . "*" x length($1) . ">"/ge;;
			$columns{'abstract_hyphens'}="'". TOM::Security::form::sql_escape(join(",",Ext::TextHyphen::get_hyphens($text_plain,'lng'=>$article_content{'lng'}))) ."'";
		}
		$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'article_content.keywords'})."'"
			if (exists $env{'article_content.keywords'} && ($env{'article_content.keywords'} ne $article_content{'keywords'}));
		$env{'article_content.body'}=~s|$soft_hyphen||g;
		if ($env{'article_content.body'} && ($env{'article_content.body'} ne $article_content{'body'}))
		{
			$data{'body'}=$env{'article_content.body'};
			my $text_plain=$env{'article_content.body'};
				$text_plain=~s/<(.*?)>/"<" . "*" x length($1) . ">"/ge;;
			$data{'body_hyphens'}=join(",",Ext::TextHyphen::get_hyphens($text_plain,'lng'=>$article_content{'lng'}));
		}
		# datetime_modified
		# datetime_stop
		if (exists $env{'article_content.datetime_modified'} && ($env{'article_content.datetime_modified'} ne $article_content{'datetime_modified'}))
		{
			if (!$env{'article_content.datetime_modified'}){$columns{'datetime_modified'}="NULL";}
			else {$columns{'datetime_modified'}="'".$env{'article_content.datetime_modified'}."'";}
		}
		if (exists $env{'article_content.status'} && ($env{'article_content.status'} ne $article_content{'status'}))
		{
			$columns{'status'}="'".TOM::Security::form::sql_escape($env{'article_content.status'})."'";
			if ($env{'article_content.status'} eq "Y")
			{
				# enabling version, also find all other enabled versions
				my $sql=qq{
					SELECT
						ID,
						version
					FROM
						`$App::401::db_name`.`a401_article_content`
					WHERE
						ID_entity=? AND
						lng=? AND
						status='Y' AND
						version != ?
				};
				my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[
					$env{'article.ID_entity'},
					$env{'article_content.lng'},
					$env{'article_content.version'}
				],'quiet'=>1);
				while (my %db0_line=$sth0{'sth'}->fetchhash())
				{
					main::_log("disable article_content.ID='$db0_line{'ID'}' with version='$db0_line{'version'}'");
					App::020::SQL::functions::update(
						'ID' => $db0_line{'ID'},
						'db_h' => "main",
						'db_name' => $App::401::db_name,
						'tb_name' => "a401_article_content",
						'columns' => {'status' => "'N'"},
						'-journalize' => 1
					);
				}
				$content_reindex=1;
			}
		}
		$columns{'ID_editor'}="'".TOM::Security::form::sql_escape($env{'article_content.ID_editor'})."'"
			if (exists $env{'article_content.ID_editor'} && ($env{'article_content.ID_editor'} ne $article_content{'ID_editor'}));
		
		if (keys %columns || keys %data)
		{
			$env{'article_content.ID_editor'}=$main::USRM{'ID_user'} unless $env{'article_content.ID_editor'};
			$columns{'ID_editor'}="'".$env{'article_content.ID_editor'}."'";
			
			if ($env{'update_type'} eq "main")
			{
				# when this is main update, and content is REALLY changed, then update modified datetime to current datetime
				$columns{'datetime_modified'}="NOW()";
			}
			
			foreach (keys %columns)
			{
				main::_log("column $_='$columns{$_}'");
			}
			
			App::020::SQL::functions::update(
				'ID' => $env{'article_content.ID'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article_content",
				'data' => {%data},
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1 if $columns{'body'};
			$content_reindex=1 if $columns{'abstract'};
			$content_reindex=1 if $columns{'subtitle'};
			$content_reindex=1 if $columns{'keywords'};
		}
		
		# check if there is one enabled version
		my $sql=qq{
			SELECT
				ID,
				version
			FROM
				`$App::401::db_name`.`a401_article_content`
			WHERE
				ID_entity=? AND
				lng=? AND
				status='Y'
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[
			$env{'article.ID_entity'},
			$env{'article_content.lng'}
		],'quiet'=>1);
		if (!$sth0{'rows'})
		{
			# ouch, problem
			# find the lowest disabled version to enable it
			main::_log("any article_content entry is enabled!, trying to fix",1);
			my $sql=qq{
				SELECT
					ID,
					version
				FROM
					`$App::401::db_name`.`a401_article_content`
				WHERE
					ID_entity=? AND
					lng=? AND
					status='N'
				ORDER BY
					version
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[
				$env{'article.ID_entity'},
				$env{'article_content.lng'}
			],'quiet'=>1);
			if (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				main::_log("enabling article_content.ID='$db0_line{'ID'}' version='$db0_line{'version'}'");
				App::020::SQL::functions::update(
					'ID' => $db0_line{'ID'},
					'db_h' => "main",
					'db_name' => $App::401::db_name,
					'tb_name' => "a401_article_content",
					'columns' => {'status'=>"'Y'"},
					'-journalize' => 1
				);
				$content_reindex=1;
			}
		}
	}
	
	# ARTICLE_ENT
	
	my %article_ent;
	if (!$env{'article_ent.ID_entity'})
	{
		#main::_log("!\$env{'article_ent.ID_entity'}, loading article_ent");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::401::db_name`.`a401_article_ent`
			WHERE
				ID_entity='$env{'article.ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%article_ent=$sth0{'sth'}->fetchhash();
		$env{'article_ent.ID_entity'}=$article_ent{'ID_entity'};
		$env{'article_ent.ID'}=$article_ent{'ID'};
	}
	if (!$env{'article_ent.ID_entity'})
	{
		# create one entity representation of article
		my %columns;
		#main::_log("!\$env{'article_ent.ID_entity'}, creating article_ent");
		$env{'article_ent.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_ent",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'article.ID_entity'},
			},
			'-journalize' => 1,
		);
	}
	
	#main::_log("\$env{'article_ent.ID_entity'}=$env{'article_ent.ID_entity'} \$env{'article_ent.posix_owner'}=$env{'article_ent.posix_owner'}");
	if (!$article_ent{'posix_owner'} && !$env{'article_ent.posix_owner'})
	{
		$env{'article_ent.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update if necessary
	if ($env{'article_ent.ID'})
	{
		my %columns;
		$columns{'ID_author'}="'".$env{'article_ent.ID_author'}."'"
			if ($env{'article_ent.ID_author'} && ($env{'article_ent.ID_author'} ne $article_ent{'ID_author'}));
		$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'article_ent.posix_owner'})."'"
			if ($env{'article_ent.posix_owner'} && ($env{'article_ent.posix_owner'} ne $article_ent{'posix_owner'}));
		$columns{'sources'}="'".TOM::Security::form::sql_escape($env{'article_ent.sources'})."'"
			if (exists $env{'article_ent.sources'} && ($env{'article_ent.sources'} ne $article_ent{'sources'}));
		$columns{'visits'}="'".TOM::Security::form::sql_escape($env{'article_ent.visits'})."'"
			if (exists $env{'article_ent.visits'} && ($env{'article_ent.visits'} ne $article_ent{'visits'}));
		$columns{'rating_score'}="'".TOM::Security::form::sql_escape($env{'article_ent.rating_score'})."'"
			if (exists $env{'article_ent.rating_score'} && ($env{'article_ent.rating_score'} ne $article_ent{'rating_score'}));
		$columns{'rating_votes'}="'".TOM::Security::form::sql_escape($env{'article_ent.rating_votes'})."'"
			if (exists $env{'article_ent.rating_votes'} && ($env{'article_ent.rating_votes'} ne $article_ent{'rating_votes'}));
		$columns{'rating'}="'".TOM::Security::form::sql_escape($env{'article_ent.rating'})."'"
			if (exists $env{'article_ent.rating'} && ($env{'article_ent.rating'} ne $article_ent{'rating'}));
		$columns{'published_mark'}="'".TOM::Security::form::sql_escape($env{'article_ent.published_mark'})."'"
			if (exists $env{'article_ent.published_mark'} && ($env{'article_ent.published_mark'} ne $article_ent{'published_mark'}));
		
		# metadata
		if ((not exists $env{'article_ent.metadata'}) && (!$article_ent{'metadata'})){$env{'article_ent.metadata'}=$App::401::metadata_default;}
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'article_ent.metadata'})."'"
		if (exists $env{'article_ent.metadata'} && ($env{'article_ent.metadata'} ne $article_ent{'metadata'}));
		
		if ($columns{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::401::db_name,
				'tb_name' => 'a401_article_ent',
				'ID' => $env{'article_ent.ID'},
				'metadata' => {App::020::functions::metadata::parse($env{'article_ent.metadata'})}
			);
			$content_reindex=1;
		}
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'article_ent.ID'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article_ent",
				'columns' => {%columns},
				'-journalize' => 1
			);
		}
	}
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::401::db_name,'tb_name'=>'a401_article','ID_entity'=>$env{'article.ID_entity'}});
	}
	
	if ($content_reindex)
	{
		# reindex this article;
		_article_index('ID_entity'=>$env{'article.ID_entity'});
	}
	
	$t->close();
	return %env;
}


sub _article_index_all
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::401::db_name}); # do it in background
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			ID_entity
		FROM
			$App::401::db_name.a401_article_ent
	},'quiet'=>1);
	my $i;
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		_article_index('ID_entity' => $db0_line{'ID_entity'});
	}
	main::_log("created pool");
}


sub _article_index
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::401::db_name,'class'=>'indexer'}); # do it in background
	
	my %env=@_;
	return undef unless $env{'ID_entity'};
	
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my $t=track TOM::Debug(__PACKAGE__."::_article_index::elastic(".$env{'ID_entity'}.")",'timer'=>1);
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				article.ID
			FROM `$App::401::db_name`.a401_article_ent AS article_ent
			INNER JOIN `$App::401::db_name`.a401_article AS article ON
			(
				article_ent.ID_entity = article.ID_entity
			)
			WHERE
				article.ID_entity = ? AND
				article.status IN ('Y','N','L') AND
				article_ent.status IN ('Y','N','L')
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		if (!$sth0{'rows'})
		{
			main::_log("article.ID_entity=$env{'ID_entity'} not found",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::401::db_name,
				'type' => 'a401_article',
				'id' => $env{'ID_entity'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::401::db_name,
					'type' => 'a401_article',
					'id' => $env{'ID_entity'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %article;
		
		# article_content
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				$App::401::db_name.a401_article_content
			WHERE
				status='Y'
				AND ID_entity=?
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$article{'locale'}{$db0_line{'lng'}}{'body'}=$db0_line{'body'}
				if $db0_line{'body'};
			$article{'locale'}{$db0_line{'lng'}}{'abstract'}=$db0_line{'abstract'}
				if $db0_line{'abstract'};
			$article{'locale'}{$db0_line{'lng'}}{'keywords'}=$db0_line{'keywords'}
				if $db0_line{'keywords'};
			$article{'locale'}{$db0_line{'lng'}}{'subtitle'}=$db0_line{'subtitle'}
				if $db0_line{'subtitle'};
		}
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				article_attrs.ID,
				article_attrs.name,
				article_attrs.name_url,
				article_attrs.lng,
				article_attrs.datetime_start,
				article_attrs.datetime_stop,
				article_attrs.status,
				article_ent.ID_author,
				article_cat.name AS cat_name,
				article_cat.ID AS cat_ID,
				article_cat.ID_entity AS cat_ID_entity,
				article_cat.ID_charindex
			FROM
				$App::401::db_name.a401_article AS article
			LEFT JOIN $App::401::db_name.a401_article_ent AS article_ent ON
			(
				article_ent.ID_entity = article.ID_entity
			)
			LEFT JOIN $App::401::db_name.a401_article_attrs AS article_attrs ON
			(
				article_attrs.ID_entity = article.ID
			)
			LEFT JOIN $App::401::db_name.a401_article_cat AS article_cat ON
			(
				article_cat.ID = article_attrs.ID_category
			)
			WHERE
				article_ent.ID_entity=?
				AND article.status='Y'
				AND article_attrs.status='Y'
			ORDER BY
				article_attrs.datetime_start DESC
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		$article{'status'}="N";
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			push @{$article{'name'}},$db0_line{'name'};
			push @{$article{'name_url'}},$db0_line{'name_url'};
#			push @{$article{'datetime_start'}},$db0_line{'datetime_start'}
#				if $db0_line{'datetime_start'};

			push @{$article{'cat'}},$db0_line{'cat_ID_entity'}
				if $db0_line{'cat_ID_entity'};
			push @{$article{'cat_charindex'}},$db0_line{'ID_charindex'}
				if $db0_line{'ID_charindex'};
			
			push @{$article{'cat_charindex'}},$db0_line{'ID_charindex'}
				if $db0_line{'ID_charindex'};
			
			push @{$article{'locale'}{$db0_line{'lng'}}{'name'}},$db0_line{'name'};
			push @{$article{'locale'}{$db0_line{'lng'}}{'name_url'}},$db0_line{'name_url'};
			
#			$db0_line{'datetime_start'}=~s| (\d\d)|T$1|;
#			$db0_line{'datetime_start'}.="Z";
#			main::_log("datetime_start=$db0_line{'datetime_start'}");
			push @{$article{'article_attrs'}},{
				'name' => $db0_line{'name'},
				'cat' => $db0_line{'cat_ID_entity'},
				'cat_charindex' => $db0_line{'ID_charindex'},
				'datetime_start' => $db0_line{'datetime_start'}
			};
			
			$article{'status'}="Y"
				if $db0_line{'status'} eq "Y";
		}
		
#		use Data::Dumper;print Dumper(\%article);
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		$Elastic->index(
			'index' => 'cyclone3.'.$App::401::db_name,
			'type' => 'a401_article',
			'id' => $env{'ID_entity'},
			'body' => {
				%article,
				'_datetime_index' => 
					$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
					.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z'
			}
		);
		
#		use Data::Dumper;
#		print Dumper(\%article);
		
		$t->close();
	}
	
	return 1 unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_article_index::solr(".$env{'ID_entity'}.")",'timer'=>1);
	
	my %content;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::401::db_name.a401_article_content
		WHERE
			status='Y'
			AND ID_entity=?
	},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("article_content ID='$db0_line{'ID'}' lng='$db0_line{'lng'}' version='$db0_line{'version'}'");
		
		for my $part('body','abstract')
		{
			$db0_line{$part}=~s|<.*?>||gms;
			$db0_line{$part}=~s|&nbsp;| |gms;
			$db0_line{$part}=~s|  | |gms;
			for (0,1,2,4)
			{$db0_line{$part}=~s|\x{$_}||g;}
		}
		
		if (length($db0_line{'body'})<20)
		{
			main::_log("using abstract instead of '$db0_line{'body'}'");
			$db0_line{'body'} = $db0_line{'abstract'};
#			exit 0;
		}
		
		$content{$db0_line{'lng'}}{'text'}=WebService::Solr::Field->new( 'text' => $db0_line{'body'} );
		$content{$db0_line{'lng'}}{'description'}=WebService::Solr::Field->new( 'description' => $db0_line{'abstract'} );
		$content{$db0_line{'lng'}}{'keywords'}=WebService::Solr::Field->new( 'keywords' => $db0_line{'keywords'} );
		$content{$db0_line{'lng'}}{'subject'}=WebService::Solr::Field->new( 'subject' => $db0_line{'subtitle'} );
		
		if ($db0_line{'datetime_modified'})
		{
			$db0_line{'datetime_modified'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_modified'}.="Z";
			$content{$db0_line{'lng'}}{'last_modified'}=WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_modified'} );
		}
		
		# name
		# cat (multi)
		# title (multi)
		# subject
		# comments
		# author
		# category
		# last_modified
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				article_attrs.ID,
				article_attrs.name,
				article_attrs.name_url,
				article_attrs.lng,
				article_attrs.datetime_start,
				article_attrs.status,
				article_ent.ID_author,
				article_cat.name AS cat_name,
				article_cat.ID AS cat_ID,
				article_cat.ID_charindex
			FROM
				$App::401::db_name.a401_article AS article
			LEFT JOIN $App::401::db_name.a401_article_ent AS article_ent ON
			(
				article_ent.ID_entity = article.ID_entity
			)
			LEFT JOIN $App::401::db_name.a401_article_attrs AS article_attrs ON
			(
				article_attrs.ID_entity = article.ID
			)
			LEFT JOIN $App::401::db_name.a401_article_cat AS article_cat ON
			(
				article_cat.ID = article_attrs.ID_category
			)
			WHERE
				article_ent.ID_entity=?
				AND article.status='Y'
				AND article_attrs.status='Y'
			ORDER BY
				article_attrs.datetime_start DESC
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			main::_log("article_attrs ID='$db1_line{'ID'}' lng='$db1_line{'lng'}' name='$db1_line{'name'}' cat_name='$db1_line{'cat_name'}' datetime_start='$db1_line{'datetime_start'}'");
			
			push @{$content{$db0_line{'lng'}}{'title'}},WebService::Solr::Field->new( 'status_sm' => $db1_line{'status'} )
				if $db1_line{'status'};
			
			if ($db1_line{'name'})
			{
				$content{$db0_line{'lng'}}{'name'}=WebService::Solr::Field->new( 'name' => $db1_line{'name'} );
				push @{$content{$db0_line{'lng'}}{'title'}},WebService::Solr::Field->new( 'title' => $db1_line{'name'} );
			}
			if ($db1_line{'cat_name'})
			{
				push @{$content{$db0_line{'lng'}}{'cat'}},WebService::Solr::Field->new( 'cat' => $db1_line{'cat_name'} );
			}
			
			if ($db1_line{'ID_charindex'})
			{
				push @{$content{$db0_line{'lng'}}{'cat'}},WebService::Solr::Field->new( 'cat_charindex_sm' =>  $db1_line{'ID_charindex'});
				my %sql_def=('db_h' => "main",'db_name' => $App::401::db_name,'tb_name' => "a401_article_cat");
				foreach my $p(
					App::020::SQL::functions::tree::get_path(
						$db1_line{'cat_ID'},
						%sql_def,
						'-cache' => 86400*7
					)
				)
				{
					push @{$content{$db0_line{'lng'}}{'cat'}},WebService::Solr::Field->new( 'cat_path_sm' =>  $p->{'ID_entity'});
				}
			}
			
			if (!$content{$db0_line{'lng'}}{'last_modified'})
			{
				$db1_line{'datetime_start'}=~s| (\d\d)|T$1|;
				$db1_line{'datetime_start'}.="Z";
				$content{$db0_line{'lng'}}{'last_modified'}=WebService::Solr::Field->new( 'last_modified' => $db1_line{'datetime_start'} )
			}
			
		}
	}
	
	my $solr = Ext::Solr::service();
	
	# how many articles of this type we have indexed?
	my $response = $solr->search( "id:".$App::401::db_name.".a401_article.* AND ID_entity_i:$env{'ID_entity'}" );
	for my $doc ( $response->docs )
	{
		my $lng=$doc->value_for( 'lng_s' );
		if (!$content{$lng})
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
	}
	
	foreach my $lng (keys %content)
	{
		my $id=$App::401::db_name.".a401_article.".$lng.".".$env{'ID_entity'};
		main::_log("index id='$id'");
		
		my $doc = WebService::Solr::Document->new();
		
		$doc->add_fields((
			WebService::Solr::Field->new( 'id' => $id ),
                        WebService::Solr::Field->new( 'db_s' => $App::401::db_name ),
                        WebService::Solr::Field->new( 'addon_s' => 'a401_article' ),
                        WebService::Solr::Field->new( 'lng_s' => $lng ),
                        WebService::Solr::Field->new( 'ID_entity_i' => $env{'ID_entity'} ),
			
			$content{$lng}{'text'},
			$content{$lng}{'description'},
			$content{$lng}{'keywords'},
			$content{$lng}{'subject'},
			$content{$lng}{'name'},
#			$content{$lng}{'status'},
			@{$content{$lng}{'title'}},
			@{$content{$lng}{'cat'}},
			$content{$lng}{'last_modified'}
		));
		
		$solr->add($doc);
	}
	
	$t->close();
	return 1;
}


sub _article_cat_index
{
	my %env=@_;
	return undef unless $env{'ID'};
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_article_cat_index()",'timer'=>1);
	
	my $solr = Ext::Solr::service();
	
	my %content;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::401::db_name.a401_article_cat
		WHERE
			status IN ('Y','L')
			AND ID=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("found");
		
		my $id=$App::401::db_name.".a401_article_cat.".$db0_line{'lng'}.".".$db0_line{'ID'};
		main::_log("index id='$id'");
		
		my $doc = WebService::Solr::Document->new();
		
		$db0_line{'description'}=~s|<.*?>||gms;
		$db0_line{'description'}=~s|&nbsp;| |gms;
		$db0_line{'description'}=~s|  | |gms;
		
		$db0_line{'datetime_create'}=~s| (\d\d)|T$1|;
		$db0_line{'datetime_create'}.="Z";
		
		
		$doc->add_fields((
			WebService::Solr::Field->new( 'id' => $id ),
			
			WebService::Solr::Field->new( 'name' => $db0_line{'name'} ),
			WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} || ''),
			WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
			
			WebService::Solr::Field->new( 'description' => $db0_line{'description'} ),
			
			WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_create'} ),
			
			WebService::Solr::Field->new( 'db_s' => $App::401::db_name ),
			WebService::Solr::Field->new( 'addon_s' => 'a401_article_cat' ),
			WebService::Solr::Field->new( 'lng_s' => $db0_line{'lng'} ),
			WebService::Solr::Field->new( 'ID_i' => $db0_line{'ID'} ),
			WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} ),
		));
		
		$solr->add($doc);
		
#		main::_log("Solr commiting...");
#		$solr->commit;
#		main::_log("commited.");
		
	}
	else
	{
		main::_log("not found active ID",1);
		my $response = $solr->search( "id:".$App::401::db_name.".a401_article_cat.* AND ID_i:$env{'ID'}" );
		for my $doc ( $response->docs )
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
#		$solr->commit;
	}
	
	$t->close();
}

=head2 article_content_extract_keywords()

Extracts keywords from article_content.abstract/body

 article_content_extract_keywords
 (
   'article_content.mimetype' => '',
   'article_content.abstract' => '',
   'article_content.body' => '',
 );

=cut

sub article_content_extract_keywords
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::article_content_extract_keywords()") if $debug;
	$env{'article_content.mimetype'}="text/html" unless $env{'article_content.mimetype'};
	
	my %keywords;
	
	if ($env{'article_content.mimetype'}="text/html")
	{
		%keywords=App::401::keywords::html_extract($env{'article_content.abstract'}.' '.$env{'article_content.body'});
	}
	
	
	foreach (keys %keywords)
	{
		#main::_log("key $_");
	}
	
	
	$t->close() if $debug;
	return %keywords;
}


sub article_alias_url
{
	my %env=@_;
	my $alias_url;
	my $t=track TOM::Debug(__PACKAGE__."::article_alias_url()");
	
	if (!$env{'ID_category'})
	{
		$t->close();
		return undef;
	}
	
	# check alternate url
	my %categories;
	my @categories_pool;
	my $ID_category=$env{'ID_category'};
	push @categories_pool,$ID_category;
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
	$categories{$ID_category}=$data{'name_url'};
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
		$categories{$ID_category}=$data{'name_url'};
		push @categories_pool,$ID_category;
		if ($data{'alias_url'})
		{
			$alias_url=$data{'alias_url'};
			last;
		}
	}
	
	main::_log("alias_url='$alias_url'");
	
	$t->close();
	return $alias_url;
}


sub article_item_info
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::article_item_info()");
	
	my $sql_where;
	if ($env{'article_attrs.ID_category'})
	{
		if ($env{'article_attrs.ID_category'} eq 'NULL')
		{
			$sql_where='ID_category IS NULL';
		} else
		{
			$sql_where="ID_category = $env{'article_attrs.ID_category'}";
		}
	}
	else {
		$sql_where='ID_category IS NULL';
	}

	my $sql=qq{
		SELECT
			view.*,
			IF
			(
				(SELECT COUNT(*) FROM `$App::401::db_name`.a401_article_view WHERE ID_entity_article=view.ID_entity_article AND status IN ('Y','N')) > 1,
				'Y','N'
			) AS symlink,
			IF
			(
				(
					status LIKE 'Y' AND
					NOW() >= datetime_start AND
					(datetime_stop IS NULL OR NOW() <= datetime_stop)
				),
			 	'Y', 'N'
			) AS datetime_status
		FROM
			`$App::401::db_name`.a401_article_view AS view
		WHERE
			ID_article = '$env{'article.ID'}' AND
			$sql_where
		LIMIT
			1
	};
	
	my %data;
	
	my %sth0=TOM::Database::SQL::execute($sql,'log'=>1);
	if ($sth0{'sth'})
	{
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			
			foreach (keys %db0_line){$data{'db_'.$_}=$db0_line{$_};}
			
			$data{'ID'}=$db0_line{'ID_article'};
			$data{'ID_entity'}=$db0_line{'ID_entity_article'};
			
			my %author=App::301::authors::get_author($db0_line{'posix_author'});
			($author{'fullname'},$author{'shortname'})=App::301::authors::get_fullname(%author);
			foreach (keys %author){$data{'author_'.$_}=$author{$_};}
			
			my %editor=App::301::authors::get_author($db0_line{'posix_editor'});
			($editor{'fullname'},$editor{'shortname'})=App::301::authors::get_fullname(%editor);
			foreach (keys %editor){$data{'editor_'.$_}=$editor{$_};}
			
			# check relations
			foreach my $relation (App::160::SQL::get_relations(
				'db_name' => $App::401::db_name,
				'l_prefix' => 'a401',
				'l_table' => 'article',
				'l_ID_entity' => $db0_line{'ID_entity_article'},
#				'rel_type' => $env{'rel_type'},
#				'r_prefix' => "a501",
#				'r_table' => "image",
				'status' => "Y"
			))
			{
				if ($relation->{'r_prefix'} eq "a542" && $relation->{'r_table'} eq "file" && $relation->{'rel_type'} eq "attachment")
				{$data{'attachment_status'}='Y';next};
				if ($relation->{'r_prefix'} eq "a821" && $relation->{'r_table'} eq "discussion" && $relation->{'rel_type'} eq "discussion")
				{$data{'discussion_status'}='Y';next};
				$data{'relation_status'}='Y';
			}
			
			# check relations
			if ($db0_line{'keywords'}){$data{'keywords_status'}='Y';}
			
			$data{'size'}=TOM::Text::format::bytes(length($db0_line{'abstract'}.$db0_line{'body'}));
			
		}
		
	}
	else
	{
		main::_log("can't select",1);
	}
	
	$t->close();
	return %data;
}


=head2 article_visit()

Increase number of article visits

=cut

sub article_visit
{
	my $ID_entity=shift;
	
	if ($Redis)
	{
		my $key='main::'.$App::401::db_name.'::a401_article_ent::'.$ID_entity;
		my $count_visits = $Redis->hmget('C3|db_entity|'.$key,'_firstvisit','visits');
		if (
			($count_visits->[0] <= ($main::time_current - 1800)) # save every 30 minutes
			|| $count_visits->[1] >= 1000)
		{
			# it's time to save
			TOM::Database::SQL::execute(qq{
				UPDATE `$App::401::db_name`.a401_article_ent
				SET visits = visits + ?
				WHERE ID_entity = $ID_entity
				LIMIT 1
			},'quiet'=>1,'-jobify'=>1,'bind'=>[$count_visits->[1]]) if $count_visits->[1];
			$Redis->hmset('C3|db_entity|'.$key,
				'visits',1,
				'_firstvisit', $main::time_current
#				,sub {}
			);
			$Redis->expire($key,86400
#				,sub {}
			);
		}
		else
		{
#			main::_log("last visit $count_visits->[0] $count_visits->[1]");
#			$Redis->hset('C3|db_entity|'.$key,'_firstvisit',$main::time_current,sub {});
			$Redis->hincrby('C3|db_entity|'.$key,'visits',1
#				,sub {}
			);
			if (!$count_visits->[0])
			{
				$Redis->expire($key,(86400*7)
#					,sub {}
				);
			}
		}
		return 1;
	}
	
	# check if this visit is in article
	my $cache={};
	$cache=$Ext::CacheMemcache::cache->get(
		'namespace' => $App::401::db_name.".a401_article_ent.visit",
		'key' => $ID_entity
	) if $TOM::CACHE_memcached;
	if (!$cache->{'time'} && $TOM::CACHE_memcached)# try again when memcached sends empty key (bug)
	{
		usleep(3000); # 3 miliseconds
		$cache=$Ext::CacheMemcache::cache->get(
			'namespace' => $App::401::db_name.".a401_article_ent.visit",
			'key' => $ID_entity
		);
	}
	
	if (!$cache->{'time'})
	{
		$cache->{'visits'}=1;
		$Ext::CacheMemcache::cache->set
		(
			'namespace' => $App::401::db_name.".a401_article_ent.visit",
			'key' => $ID_entity,
			'value' =>
			{
				'time' => time(),
				'visits' => $cache->{'visits'}
			},
			'expiration' => "24H"
		) if $TOM::CACHE_memcached;
		# update SQL
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::401::db_name`.a401_article_ent
			SET visits=visits+1
			WHERE ID_entity=?
			LIMIT 1
		},'bind'=>[$ID_entity],'quiet'=>1,'-jobify'=>1) unless $TOM::CACHE_memcached;
		return 1;
	}
	
	# return unless memcached available
	return 1 unless $TOM::CACHE_memcached;
	
	$cache->{'visits'}++;
	
	my $old=time()-$cache->{'time'};
	
	if ($old > (60*5))
	{
		# update database
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::401::db_name`.a401_article_ent
			SET visits=visits+$cache->{'visits'}
			WHERE ID_entity=$ID_entity
			LIMIT 1
		},'quiet'=>1,'-jobify'=>1);
		$cache->{'visits'}=0;
		$cache->{'time'}=time();
	}
	
	$Ext::CacheMemcache::cache->set
	(
		'namespace' => $App::401::db_name.".a401_article_ent.visit",
		'key' => $ID_entity,
		'value' =>
		{
			'time' => $cache->{'time'},
			'visits' => $cache->{'visits'}
		},
		'expiration' => "24H"
	) if $TOM::CACHE_memcached;
	
	return 1;
}

use Data::Dumper;
sub _a210_by_cat_original
{
	my $cats=shift;
	my %env=@_;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	my $cache_key=$env{'lng'}.'::'.join('::',@{$cats});
	
	# changetimes
	my $changetime_a401=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::401::db_name,
		'tb_name' => 'a401_article_cat',
	});
	my $changetime_a210=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::210::db_name,
		'tb_name' => 'a210_page',
	});
	
	if ($TOM::CACHE && $TOM::CACHE_memcached && $main::cache)
	{
#		main::_log("get cached");
		my $cache=$Ext::CacheMemcache::cache->get(
			'namespace' => "fnc_cache",
			'key' => 'App::401::functions::_a210_by_cat::'.$cache_key
		);
		if (($cache->{'time'} > $changetime_a210) && ($cache->{'time'} > $changetime_a401))
		{
#			print "value=$cache->{'value'} time=$cache->{'time'} key=$cache_key\n";
#			main::_log("found, return");
			return $cache->{'value'};
		}
	}
	
	# find path
	my @categories;
	my %sql_def=('db_h' => "main",'db_name' => $App::401::db_name,'tb_name' => "a401_article_cat");
	foreach my $cat(@{$cats})
	{
#		print "mam $cat";
		my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID FROM $App::401::db_name.a401_article_cat WHERE ID_entity=? AND lng=? LIMIT 1},
			'bind'=>[$cat,$env{'lng'}],'log'=>0,'quiet'=>1,
			'-cache' => 600,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime({
				'db_name' => $App::401::db_name,
				'tb_name' => 'a401_article_cat',
			})
		);
		next unless $sth0{'rows'};
		my %db0_line=$sth0{'sth'}->fetchhash();
		my $i;
		foreach my $p(
			App::020::SQL::functions::tree::get_path(
				$db0_line{'ID'},
				%sql_def,
				'-slave' => 1,
				'-cache' => 3600
				# autocached by changetime
			)
		)
		{
			push @{$categories[$i]},$p->{'ID_entity'};
			$i++;
		}
	}
	
#	print Dumper(\@categories);
	
	my $category;
	for my $i (1 .. @categories)
	{
		foreach my $cat (@{$categories[-$i]})
		{
#			push @{$product->{'log'}},"find $i ".$cat;
#			print "aha $i $cat\n";
			my %db0_line;
			foreach my $relation(App::160::SQL::get_relations(
				'db_name' => $App::210::db_name,
				'l_prefix' => 'a210',
				'l_table' => 'page',
				#'l_ID_entity' = > ???
				'r_prefix' => "a401",
				'r_table' => "article_cat",
				'r_ID_entity' => $cat,
				'rel_type' => "link",
				'status' => "Y"
			))
			{
#				print "fakt mam\n";
				# je toto relacia na moju jazykovu verziu a je aktivna?
				my %sth0=TOM::Database::SQL::execute(
				qq{SELECT ID FROM $App::210::db_name.a210_page WHERE ID_entity=? AND lng=? AND status IN ('Y','L') LIMIT 1},
				'bind'=>[$relation->{'l_ID_entity'},$env{'lng'}],'quiet'=>1,
					'-cache' => 600,
					'-cache_changetime' => App::020::SQL::functions::_get_changetime({
						'db_name' => $App::210::db_name,
						'tb_name' => 'a210_page',
					})
				);
				next unless $sth0{'rows'};
				%db0_line=$sth0{'sth'}->fetchhash();
				last;
			}
			
			next unless $db0_line{'ID'};
			
			$category=$db0_line{'ID'};
			
			last;
		}
		last if $category;
	}
	
	if ($TOM::CACHE && $TOM::CACHE_memcached)
	{
		$Ext::CacheMemcache::cache->set(
			'namespace' => "fnc_cache",
			'key' => 'App::401::functions::_a210_by_cat::'.$cache_key,
			'value' => {
				'time' => time(),
				'value' => $category
			},
			'expiration' => '3600S'
		);
	}
	
	return $category;
}



sub _a210_by_cat
{
	my $cats=shift;
	my %env=@_;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	my $cache_key=$App::210::db_name.'::'.$env{'lng'}.'::'.join('::',@{$cats});
	
	# changetimes
	my $changetime_a401=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::401::db_name,
		'tb_name' => 'a401_article_cat',
	});
	my $changetime_a210=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::210::db_name,
		'tb_name' => 'a210_page',
	});
	
	if ($TOM::CACHE && $TOM::CACHE_memcached && $main::cache && 0)
	{
		my $cache=$Ext::CacheMemcache::cache->get(
			'namespace' => "fnc_cache",
			'key' => 'App::401::functions::_a210_by_cat::'.$cache_key
		);
		if (($cache->{'time'} > $changetime_a210) && ($cache->{'time'} > $changetime_a401))
		{
			return $cache->{'value'};
		}
	}
	
	# find path
	my @categories;
	my %sql_def=('db_h' => "main",'db_name' => $App::401::db_name,'tb_name' => "a401_article_cat");
	foreach my $cat(@{$cats})
	{
		main::_log("cat $cat") if $env{'debug'};
		
		my $i;
		foreach my $p(
			App::020::SQL::functions::tree::get_path(
				$cat,
				%sql_def,
				'-slave' => 1,
				'-cache' => 86400*7
				# autocached by changetime
			)
		)
		{
			main::_log(" subcat $p->{'ID_entity'}") if $env{'debug'};
			push @{$categories[$i]},$p->{'ID_entity'};
			$i++;
		}
	}
	
	my $category;
	for my $i (1 .. @categories)
	{
		main::_log("test No. $i") if $env{'debug'};
		foreach my $cat (@{$categories[-$i]})
		{
			main::_log(" cat $cat") if $env{'debug'};
			my %db0_line;
			foreach my $relation(App::160::SQL::get_relations(
				'db_name' => $App::210::db_name,
				'l_prefix' => 'a210',
				'l_table' => 'page',
				#'l_ID_entity' = > ???
				'r_prefix' => "a401",
				'r_table' => "article_cat",
				'r_ID_entity' => $cat,
				'rel_type' => "link",
				'status' => "Y",
			))
			{
				main::_log("relation category $cat to a210 $relation->{'r_ID_entity'}") if $env{'debug'};
				# je toto relacia na moju jazykovu verziu a je aktivna?
				my %sth0=TOM::Database::SQL::execute(
				qq{SELECT ID FROM $App::210::db_name.a210_page WHERE ID_entity=? AND lng=? AND status IN ('Y','L') LIMIT 1},
				'bind'=>[$relation->{'l_ID_entity'},$env{'lng'}],'quiet'=>1,
					'-cache' => 86400*7,
					'-cache_changetime' => App::020::SQL::functions::_get_changetime({
						'db_name' => $App::210::db_name,
						'tb_name' => 'a210_page',
					})
				);
				next unless $sth0{'rows'};
				%db0_line=$sth0{'sth'}->fetchhash();
				last;
			}
			
			next unless $db0_line{'ID'};
			
			$category=$db0_line{'ID'};
			
			last;
		}
		last if $category;
	}
	
	if ($TOM::CACHE && $TOM::CACHE_memcached)
	{
		$Ext::CacheMemcache::cache->set(
			'namespace' => "fnc_cache",
			'key' => 'App::401::functions::_a210_by_cat::'.$cache_key,
			'value' => {
				'time' => time(),
				'value' => $category
			},
			'expiration' => '86400S'
		);
	}
	
	return $category;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
