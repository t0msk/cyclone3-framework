#!/bin/perl
package App::401::functions;

=head1 NAME

App::401::functions

=head1 DESCRIPTION



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

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::401::_init;
use TOM::Security::form;



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
	my $t=track TOM::Debug(__PACKAGE__."::article_add()");
	
	$env{'article_content.mimetype'}="plain/text" unless $env{'article_content.mimetype'};
	
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
	
	if (!$env{'article.ID'})
	{
		$env{'article.ID'}=$article{'ID'} if $article{'ID'};
	}
	
	
	$env{'article_attrs.lng'}=$tom::lng unless $env{'article_attrs.lng'};
	main::_log("lng='$env{'article_attrs.lng'}'");
	
	
	# check if this symlink with same ID_category not exists
	# and article.ID is unknown
	if ($env{'article_attrs.ID_category'} && !$env{'article.ID'} && $env{'article.ID_entity'})
	{
		main::_log("search for ID");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::401::db_name`.`a401_article_view`
			WHERE
				ID_entity_article=$env{'article.ID_entity'} AND
				( ID_category = $env{'article_attrs.ID_category'} OR ID_category IS NULL )
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
	
	
	
	my %article_attrs;
	if (!$env{'article_attrs.ID'})
	{
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::401::db_name`.`a401_article_attrs`
			WHERE
				ID_entity='$env{'article.ID'}' AND
				lng='$env{'article_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%article_attrs=$sth0{'sth'}->fetchhash();
		$env{'article_attrs.ID'}=$article_attrs{'ID'};
	}
	if (!$env{'article_attrs.ID'})
	{
		# create one language representation of article in content structure
		my %columns;
		$columns{'ID_category'}=$env{'article_attrs.ID_category'} if $env{'article_attrs.ID_category'};
		$columns{'datetime_start'}=$env{'article_attrs.datetime_start'} if $env{'article_attrs.datetime_start'};
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
	}
	if ($env{'article_attrs.ID'} && !$article_attrs{'ID_category'})
	{
		%article_attrs=App::020::SQL::functions::get_ID(
			'ID' => $env{'article_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_attrs",
			'columns' => {'*'=>1}
		);
	}
	if ($env{'article_attrs.ID'} &&
	(
		$env{'article_attrs.name'} ||
		($env{'article_attrs.ID_category'} ne $article_attrs{'ID_category'})
	))
	{
		my %columns;
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'article_attrs.name'})."'"
			if $env{'article_attrs.name'};
		$columns{'ID_category'}=$env{'article_attrs.ID_category'}
			if $env{'article_attrs.ID_category'} ne $article_attrs{'ID_category'};
		$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'article_attrs.name'}))."'"
			if $env{'article_attrs.name'};
		App::020::SQL::functions::update(
			'ID' => $env{'article_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_attrs",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	my %article_content;
	if (!$env{'article_content.ID'})
	{
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::401::db_name`.`a401_article_content`
			WHERE
				ID_entity='$env{'article.ID_entity'}' AND
				lng='$env{'article_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%article_content=$sth0{'sth'}->fetchhash();
		$env{'article_content.ID'}=$article_content{'ID'};
	}
	if (!$env{'article_content.ID'})
	{
		# create one language representation of article
		my %columns;
		
		$env{'article_content.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_content",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'article.ID_entity'},
				'lng' => "'$env{'article_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
	}
	if (
		!$env{'article_content.keywords'} &&
		(
			$env{'article_content.abstract'} ||
			$env{'article_content.body'}
		)
	)
	{
		my %keywords=article_content_extract_keywords(%env);
		foreach (keys %keywords)
		{
			$env{'article_content.keywords'}.=", ".$_;
		}
		$env{'article_content.keywords'}=~s|^, ||;
	}
	if ($env{'article_content.ID'} &&
	(
		$env{'article_content.subtitle'} ||
		$env{'article_content.mimetype'} ||
		$env{'article_content.abstract'} ||
		$env{'article_content.keywords'} ||
		$env{'article_content.body'}
	))
	{
		my %columns;
		
		$columns{'subtitle'}="'".TOM::Security::form::sql_escape($env{'article_content.subtitle'})."'"
			if $env{'article_content.subtitle'};
		$columns{'mimetype'}="'".TOM::Security::form::sql_escape($env{'article_content.mimetype'})."'"
			if $env{'article_content.mimetype'};
		$columns{'abstract'}="'".TOM::Security::form::sql_escape($env{'article_content.abstract'})."'"
			if $env{'article_content.abstract'};
		$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'article_content.keywords'})."'"
			if $env{'article_content.keywords'};
		$columns{'body'}="'".TOM::Security::form::sql_escape($env{'article_content.body'})."'"
			if $env{'article_content.body'};
		
		App::020::SQL::functions::update(
			'ID' => $env{'article_content.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_content",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	
	
	my %article_ent;
	if (!$env{'article_ent.ID_entity'})
	{
		my $sql=qq{
			SELECT
				ID_entity
			FROM
				`$App::401::db_name`.`a401_article_ent`
			WHERE
				ID_entity='$env{'article.ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%article_ent=$sth0{'sth'}->fetchhash();
		$env{'article_ent.ID_entity'}=$article_ent{'ID_entity'};
	}
	if (!$env{'article_ent.ID_entity'})
	{
		# create one entity representation of article
		my %columns;
		
		$env{'article_ent.ID_entity'}=App::020::SQL::functions::new(
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
	if ($env{'article_ent.ID_entity'} &&
	(
		$env{'article_ent.ID_author'}
	))
	{
		my %columns;
		$columns{'ID_author'}="'".$env{'article_ent.ID_author'}."'" if $env{'article_ent.ID_author'};
		App::020::SQL::functions::update(
			'ID' => $env{'article_ent.ID_entity'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_ent",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	$t->close();
	return %env;
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
	my $t=track TOM::Debug(__PACKAGE__."::article_content_extract_keywords()");
	$env{'article_content.mimetype'}="plain/text" unless $env{'article_content.mimetype'};
	
	my %keywords;
	
	if ($env{'article_content.mimetype'}="text/html")
	{
		%keywords=App::401::keywords::html_extract($env{'article_content.body'});
	}
	
	
	foreach (keys %keywords)
	{
		#main::_log("key $_");
	}
	
	
	$t->close();
	return %keywords;
}



=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
