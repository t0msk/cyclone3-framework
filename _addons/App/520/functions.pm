#!/bin/perl
package App::520::functions;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::520::_init;
use App::520::brick;
use App::160::_init;
use App::542::mimetypes;
use File::Path;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Type;
use File::Which qw(where);
use Time::HiRes qw(usleep);
use Ext::Redis::_init;
use Ext::Elastic::_init;
use Number::Bytes::Human qw(format_bytes);

our $ffmpeg_exec = (where('ffmpeg'))[0];main::_log("ffmpeg in '$ffmpeg_exec'");
our $mencoder_exec = (where('mencoder'))[0];main::_log("mencoder in '$mencoder_exec'");
our $mplayer_exec = (where('mplayer'))[0];main::_log("mplayer in '$mplayer_exec'");
our $avconv_exec = (where('avconv'))[0];main::_log("avconv in '$avconv_exec'");


sub audio_add
{
	my %env=@_;
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::520::db_name,'class'=>'fifo'}); # do it in background
	}
	my $t=track TOM::Debug(__PACKAGE__."::audio_add()");
	my $tr=new TOM::Database::SQL::transaction('db_h'=>"main");
	
	$env{'audio_format.ID'}=$App::520::audio_format_original_ID unless $env{'audio_format.ID'};
	$env{'audio_part.part_id'}=1 unless $env{'audio_part.part_id'};
	
	$env{'audio.ID_entity'}=$env{'audio_ent.ID_entity'} if $env{'audio_ent.ID_entity'};
	
	my $content_updated=0;
	my $content_reindex=0;
	
	# check if thumbnail file is correct
	if ($env{'file_thumbnail'})
	{
		main::_log("checking file_thumbnail='$env{'file_thumbnail'}'");
		if (!-e $env{'file_thumbnail'})
		{
			main::_log("file_thumbnail file not exists",1);
			delete $env{'file_thumbnail'};
		}
		elsif (-s $env{'file_thumbnail'} == 0)
		{
			main::_log("file_thumbnail file is empty",1);
			delete $env{'file_thumbnail'};
		}
	}
	
	my %category;
	if ($env{'audio_cat.ID'} && $env{'audio_cat.ID'} ne 'NULL')
	{
		# detect language
		%category=App::020::SQL::functions::get_ID(
			'ID' => $env{'audio_cat.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_cat",
			'columns' => {'*'=>1}
		);
		$env{'audio_attrs.lng'}=$category{'lng'};
		$env{'audio_attrs.ID_category'}=$category{'ID_entity'};
		main::_log("setting lng='$env{'audio_attrs.lng'}' from audio_attrs.ID_category");
		main::_log("setting audio_attrs.ID_category='$env{'audio_attrs.ID_category'}' from audio_cat.ID='$env{'audio_cat.ID'}'");
	}
	$env{'audio_attrs.ID_category'}='NULL' if $env{'audio_cat.ID'} eq 'NULL';
	
	$env{'audio_attrs.lng'}=$tom::lng unless $env{'audio_attrs.lng'};
	main::_log("lng='$env{'audio_attrs.lng'}'");
	
	
	# if only audio_part.ID is defined, not audio.ID or audio.ID_entity
	my %audio_part;
	if ($env{'audio_part.ID'} && !$env{'audio.ID'} && !$env{'audio.ID_entity'})
	{
		main::_log("\$env{'audio_part.ID'} && !\$env{'audio.ID'} && !\$env{'audio.ID_entity'} -> search");
		%audio_part=App::020::SQL::functions::get_ID(
			'ID' => $env{'audio_part.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_part",
			'columns' => {'*'=>1}
		);
		if ($audio_part{'ID_entity'})
		{
			$env{'audio.ID_entity'}=$audio_part{'ID_entity'};
			main::_log("found audio.ID_entity=$env{'audio.ID_entity'}");
		}
		else
		{
			return undef;
		}
	}
	
	
	
	# audio
	
	my %audio;
	my %audio_attrs;
	if ($env{'audio.ID'})
	{
		# detect language
		%audio=App::020::SQL::functions::get_ID(
			'ID' => $env{'audio.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio",
			'columns' => {'*'=>1}
		);
		$env{'audio.ID_entity'}=$audio{'ID_entity'} unless $env{'audio.ID_entity'};
	}
	
	# check if this symlink with same ID_category not already exists
	# and audio.ID is unknown
	if (!$env{'audio.ID'} && $env{'audio.ID_entity'} && !$env{'forcesymlink'})
	{
		$env{'audio_attrs.ID_category'}=0 unless $env{'audio_attrs.ID_category'};
		main::_log("search for audio.ID by audio_attrs.ID_category='$env{'audio_attrs.ID_category'}' and audio.ID_entity='$env{'audio.ID_entity'}'");
		my $sql=qq{
			SELECT
				audio.ID AS ID_audio,
				audio_attrs.ID AS ID_attrs
			FROM
				`$App::520::db_name`.a520_audio AS audio
			LEFT JOIN `$App::520::db_name`.a520_audio_attrs AS audio_attrs
				ON ( audio.ID = audio_attrs.ID_entity )
			WHERE
				audio.ID_entity=$env{'audio.ID_entity'} AND
				( audio_attrs.ID_category = $env{'audio_attrs.ID_category'} OR ID_category IS NULL ) AND
				audio_attrs.status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID_audio'})
		{
			$env{'audio.ID'}=$db0_line{'ID_audio'};
			$env{'audio_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup audio.ID='$db0_line{'ID_audio'}' audio_attrs.ID='$env{'audio_attrs.ID'}'");
		}
	}
	
=head1
	if ($env{'audio_attrs.ID_category'} && $env{'audio.ID_entity'} && $env{'audio_attrs.lng'} && !$env{'audio_attrs.ID'} && !$env{'audio.ID'} && $env{'forcesymlink'})
	{
		main::_log("finding compatible audio_attrs.ID_entity (also audio.ID)");
		
		my $sql=qq{
			SELECT
				audio.ID AS ID_audio,
				audio_attrs.ID AS ID_attrs
			FROM
				`$App::520::db_name`.a520_audio AS audio
			LEFT JOIN `$App::520::db_name`.a520_audio_attrs AS audio_attrs
				ON ( audio.ID = audio_attrs.ID_entity )
			WHERE
				audio.ID_entity=$env{'audio.ID_entity'} AND
				audio_attrs.ID_category = $env{'audio_attrs.ID_category'} AND
				audio_attrs.lng != '$env{'audio_attrs.lng'}' AND
				audio_attrs.status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID_audio'})
		{
			$env{'audio.ID'}=$db0_line{'ID_audio'};
			$env{'audio_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup audio.ID='$db0_line{'ID_audio'}' audio_attrs.ID='$env{'audio_attrs.ID'}'");
		}
		
	}
=cut
	
=head1
	# check if this lng mutation of audio_attrs exists
	if ($env{'audio_attrs.ID'} && $env{'audio_attrs.lng'} && $env{'audio.ID'})
	{
		main::_log("check if lng='$env{'audio_attrs.lng'}' of audio.ID='$env{'audio.ID'}' exists");
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::520::db_name`.a520_audio_attrs
			WHERE
				ID_entity=? AND
				lng=?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$env{'audio.ID'},$env{'audio_attrs.lng'}],'quiet'=>1);
		if (!$sth0{'rows'})
		{
			main::_log("not exists, also reset audio_attrs.ID");
			undef $env{'audio_attrs.ID'};
		}
		else
		{
			
		}
		# if not remove audio_attrs.ID
	}
=cut
	
	
	if (!$env{'audio.ID'})
	{
		# generating new audio!
		main::_log("adding new audio");
		
		my %columns;
		
		$columns{'datetime_rec_start'}="NOW()";
		$columns{'ID_entity'}=$env{'audio.ID_entity'} if $env{'audio.ID_entity'};
		
		$env{'audio.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		main::_log("generated audio.ID='$env{'audio.ID'}'");
		$content_updated=1;
		$content_reindex=1;
	}
	
	
	if (!$env{'audio.ID_entity'})
	{
		if ($audio{'ID_entity'})
		{
			$env{'audio.ID_entity'}=$audio{'ID_entity'};
		}
		elsif ($env{'audio.ID'})
		{
			%audio=App::020::SQL::functions::get_ID(
				'ID' => $env{'audio.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_audio",
				'columns' => {'*'=>1}
			);
			$env{'audio.ID_entity'}=$audio{'ID_entity'};
		}
		else
		{
			die "ufff\n";
		}
	}
	
	# update if necessary
	if ($audio{'ID'})
	{
		my %columns;
		
		# datetime_rec_start
		$columns{'datetime_rec_start'}="'".$env{'audio.datetime_rec_start'}."'"
			if ($env{'audio.datetime_rec_start'} && ($env{'audio.datetime_rec_start'} ne $audio{'datetime_rec_start'}));
		$columns{'datetime_rec_start'}=$env{'audio.datetime_rec_start'}
			if ($env{'audio.datetime_rec_start'}=~/^FROM/ && ($env{'audio.datetime_rec_start'} ne $audio{'datetime_rec_start'}));
		# datetime_rec_stop
		if (exists $env{'audio.datetime_rec_stop'} && ($env{'audio.datetime_rec_stop'} ne $audio{'datetime_rec_stop'}))
		{
			if (!$env{'audio.datetime_rec_stop'})
			{$columns{'datetime_rec_stop'}="NULL";}
			else
			{$columns{'datetime_rec_stop'}="'".$env{'audio.datetime_rec_stop'}."'";}
		}
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $audio{'ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_audio",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
	}
	
	
	if (!$env{'audio_attrs.ID'})
	{
		main::_log("finding audio_attrs.ID by audio.ID=$env{'audio.ID'} and audio_attrs.lng='$env{'audio_attrs.lng'}'");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.`a520_audio_attrs`
			WHERE
				ID_entity='$env{'audio.ID'}' AND
				lng='$env{'audio_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%audio_attrs=$sth0{'sth'}->fetchhash();
		$env{'audio_attrs.ID'}=$audio_attrs{'ID'};
		main::_log("audio_attrs.ID='$env{'audio_attrs.ID'}'");
	}
	
	if (!$env{'audio_attrs.ID'} && !$env{'audio_attrs.ID_category'} && $env{'audio.ID'})
	{ # find target ID_category if not defined
		main::_log("finding audio_attrs.ID_category by audio.ID=$env{'audio.ID'}");
		my $sql=qq{
			SELECT
				ID_category
			FROM
				`$App::520::db_name`.`a520_audio_attrs`
			WHERE
				ID_entity='$env{'audio.ID'}' AND
				status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'audio_attrs.ID_category'}=$db0_line{'ID_category'};# if $sth0{'rows'};
		main::_log("audio_attrs.ID_category='$env{'audio_attrs.ID_category'}'");
	}
	
	if (!$env{'audio_attrs.ID'})
	{
		# create one language representation of audio
		my %columns;
		$columns{'ID_category'}=$env{'audio_attrs.ID_category'} if $env{'audio_attrs.ID_category'};
		#$columns{'status'}="'$env{'audio_attrs.status'}'" if $env{'audio_attrs.status'};
		$columns{'datetime_publish_start'}="'".$env{'audio_attrs.datetime_publish_start'}."'" if $env{'audio_attrs.datetime_publish_start'};
		$columns{'datetime_publish_start'}=$env{'audio_attrs.datetime_publish_start'} if ($env{'audio_attrs.datetime_publish_start'} && (not $env{'audio_attrs.datetime_publish_start'}=~/^\d/));
		$columns{'datetime_publish_start'}="NOW()" unless $columns{'datetime_publish_start'};
		
		$env{'audio_attrs.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_attrs",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'audio.ID'},
#				'order_id' => $order_id,
				'lng' => "'$env{'audio_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
#		%audio_attrs=App::020::SQL::functions::get_ID(
#			'ID' => $env{'audio_attrs.ID'},
#			'db_h' => "main",
#			'db_name' => $App::520::db_name,
#			'tb_name' => "a520_audio_attrs",
#			'columns' => {'*'=>1}
#		);
		$content_updated=1;
		$content_reindex=1;
	}
	
	
	# audio_ENT
	
	my %audio_ent;
	if (!$env{'audio_ent.ID_entity'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.`a520_audio_ent`
			WHERE
				ID_entity='$env{'audio.ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%audio_ent=$sth0{'sth'}->fetchhash();
		$env{'audio_ent.ID_entity'}=$audio_ent{'ID_entity'};
		$env{'audio_ent.ID'}=$audio_ent{'ID'};
	}
	if (!$env{'audio_ent.ID_entity'})
	{
		# create one entity representation of audio
		my %columns;
		$columns{'datetime_rec_start'}="NOW()" unless $columns{'datetime_rec_start'};
		$env{'audio_ent.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_ent",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'audio.ID_entity'},
			},
			'-journalize' => 1,
		);
		$content_updated=1;
		$content_reindex=1;
	}
	
	if (!$audio_ent{'posix_owner'} && !$env{'audio_ent.posix_owner'})
	{
		$env{'audio_ent.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update if necessary
	if ($env{'audio_ent.ID'})
	{
		my %columns;
		$columns{'posix_author'}="'".$env{'audio_ent.posix_author'}."'"
			if ($env{'audio_ent.posix_author'} && ($env{'audio_ent.posix_author'} ne $audio_ent{'posix_author'}));
		$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'audio_ent.posix_owner'})."'"
			if ($env{'audio_ent.posix_owner'} && ($env{'audio_ent.posix_owner'} ne $audio_ent{'posix_owner'}));
		$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'audio_ent.keywords'})."'"
			if (exists $env{'audio_ent.keywords'} && ($env{'audio_ent.keywords'} ne $audio_ent{'keywords'}));
		
		$columns{'movie_release_year'}="'".TOM::Security::form::sql_escape($env{'audio_ent.movie_release_year'})."'"
			if (exists $env{'audio_ent.movie_release_year'} && ($env{'audio_ent.movie_release_year'} ne $audio_ent{'movie_release_year'}));
		$columns{'movie_release_date'}="'".TOM::Security::form::sql_escape($env{'audio_ent.movie_release_date'})."'"
			if (exists $env{'audio_ent.movie_release_date'} && ($env{'audio_ent.movie_release_date'} ne $audio_ent{'movie_release_date'}));
		$columns{'movie_country_code'}="'".TOM::Security::form::sql_escape($env{'audio_ent.movie_country_code'})."'"
			if (exists $env{'audio_ent.movie_country_code'} && ($env{'audio_ent.movie_country_code'} ne $audio_ent{'movie_country_code'}));
		$columns{'movie_imdb'}="'".TOM::Security::form::sql_escape($env{'audio_ent.movie_imdb'})."'"
			if (exists $env{'audio_ent.movie_imdb'} && ($env{'audio_ent.movie_imdb'} ne $audio_ent{'movie_imdb'}));
		$columns{'movie_catalog_number'}="'".TOM::Security::form::sql_escape($env{'audio_ent.movie_catalog_number'})."'"
			if (exists $env{'audio_ent.movie_catalog_number'} && ($env{'audio_ent.movie_catalog_number'} ne $audio_ent{'movie_catalog_number'}));
		$columns{'movie_length'}="'".TOM::Security::form::sql_escape($env{'audio_ent.movie_length'})."'"
			if (exists $env{'audio_ent.movie_length'} && ($env{'audio_ent.movie_length'} ne $audio_ent{'movie_length'}));
		$columns{'movie_note'}="'".TOM::Security::form::sql_escape($env{'audio_ent.movie_note'})."'"
			if (exists $env{'audio_ent.movie_note'} && ($env{'audio_ent.movie_note'} ne $audio_ent{'movie_note'}));
		
		if ((not exists $env{'audio_ent.metadata'}) && (!$audio_ent{'metadata'})){$env{'audio_ent.metadata'}=$App::520::metadata_default;}
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'audio_ent.metadata'})."'"
			if (exists $env{'audio_ent.metadata'} && ($env{'audio_ent.metadata'} ne $audio_ent{'metadata'}));
		
		if ($columns{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::520::db_name,
				'tb_name' => 'a520_audio_ent',
				'ID' => $env{'audio_ent.ID'},
				'metadata' => {App::020::functions::metadata::parse($env{'audio_ent.metadata'})}
			);
		}
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'audio_ent.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_audio_ent",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
	}
	
	
	my %env0=audio_part_add
	(
		'file' => $env{'file'},
		'file_nocopy' => $env{'file_nocopy'},
		'file_thumbnail' => $env{'file_thumbnail'},
		'file_dontcheck' => $env{'file_dontcheck'},
		'audio.ID_entity' => $env{'audio.ID_entity'},
		'audio.datetime_rec_start' => $audio{'datetime_rec_start'},
		'audio_attrs.name' => $audio_attrs{'name'},
		'audio_format.ID' => $env{'audio_format.ID'},
		'audio_part.ID' => $env{'audio_part.ID'},
		'audio_part.ID_brick' => $env{'audio_part.ID_brick'},
		'audio_part.keywords' => $env{'audio_part.keywords'},
		'audio_part.part_id' => $env{'audio_part.part_id'},
		'audio_part.datetime_air' => $env{'audio_part.datetime_air'},
		'audio_part_attrs.lng' => $env{'audio_attrs.lng'},
		'audio_part_attrs.name' => $env{'audio_part_attrs.name'},
		'audio_part_attrs.description' => $env{'audio_part_attrs.description'},
	);
	$env{'audio_part.ID'} = $env0{'audio_part.ID'} if $env0{'audio_part.ID'};
	if (!$env{'audio_part.ID'})
	{
		$t->close();
		return undef
	};
	
	if ($env{'audio_attrs.ID'})
	{
		# detect language
		%audio_attrs=App::020::SQL::functions::get_ID(
			'ID' => $env{'audio_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_attrs",
			'columns' => {'*'=>1}
		);
		main::_log("loaded %audio_attrs audio_attrs.ID='$audio_attrs{'ID'}' audio_attrs.ID_category='$audio_attrs{'ID_category'}'");
	}
	
	main::_log("audio_attrs.ID='$env{'audio_attrs.ID'}' audio_attrs.ID_category='$env{'audio_attrs.ID_category'}' audio_attrs{ID_category}='$audio_attrs{'ID_category'}'");
	if ($env{'audio_attrs.ID'} &&
	(
		# ID_category
		($env{'audio_attrs.ID_category'} && ($env{'audio_attrs.ID_category'} ne $audio_attrs{'ID_category'}))
	))
	{
		my %columns;
		main::_log("audio_attrs.ID='$audio_attrs{'ID'}' audio_attrs.status='$audio_attrs{'status'}'");
		$columns{'ID_category'}=$env{'audio_attrs.ID_category'};
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::520::db_name`.a520_audio_attrs
			WHERE
				ID_entity=$audio_attrs{'ID_entity'} AND
				status IN ('Y','N','L')
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
#			main::_log("update audio_attrs.ID='$db0_line{'ID'}'");
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a520_audio_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
		
	}
	
	# MUST be rewrited - update only if necessary
	if ($env{'audio_attrs.ID'})
	{
		my %columns;
		
#		$columns{'ID_category'}=$env{'audio_attrs.ID_category'}
#			if ($env{'audio_attrs.ID_category'} && ($env{'audio_attrs.ID_category'} ne $audio_attrs{'ID_category'}));
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'audio_attrs.name'})."'"
			if ($env{'audio_attrs.name'} && ($env{'audio_attrs.name'} ne $audio_attrs{'name'}));
		$columns{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'audio_attrs.name'})."'"
			if ($env{'audio_attrs.name'} && ($env{'audio_attrs.name'} ne $audio_attrs{'name'}));
		$columns{'description'}="'".TOM::Security::form::sql_escape($env{'audio_attrs.description'})."'"
			if (exists $env{'audio_attrs.description'} && ($env{'audio_attrs.description'} ne $audio_attrs{'description'}));
		# datetime_start
		$columns{'datetime_publish_start'}="'".$env{'audio_attrs.datetime_publish_start'}."'"
			if ($env{'audio_attrs.datetime_publish_start'} && ($env{'audio_attrs.datetime_publish_start'} ne $audio_attrs{'datetime_publish_start'}));
		$columns{'datetime_publish_start'}=$env{'audio_attrs.datetime_publish_start'}
			if (($env{'audio_attrs.datetime_publish_start'} && ($env{'audio_attrs.datetime_publish_start'} ne $audio_attrs{'datetime_publish_start'})) && (not $env{'audio_attrs.datetime_publish_start'}=~/^\d/));
		# datetime_stop
		if (exists $env{'audio_attrs.datetime_publish_stop'} && ($env{'audio_attrs.datetime_publish_stop'} ne $audio_attrs{'datetime_publish_stop'}))
		{
			if (!$env{'audio_attrs.datetime_publish_stop'})
			{
				$columns{'datetime_publish_stop'}="NULL";
			}
			else
			{
				$columns{'datetime_publish_stop'}="'".$env{'audio_attrs.datetime_publish_stop'}."'";
			}
		}
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'audio_attrs.status'})."'"
			if ($env{'audio_attrs.status'} && ($env{'audio_attrs.status'} ne $audio_attrs{'status'}));
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'audio_attrs.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_audio_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
	}
	
	main::_log("audio.ID='$env{'audio.ID'}' added/updated");
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::520::db_name,'tb_name'=>'a520_audio'});
	}
	
	if ($content_reindex)
	{
		_audio_index('ID_entity'=>$env{'audio.ID_entity'});
	}
	
	$tr->close(); # commit transaction
	$t->close();
	return %env;
}



sub audio_part_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::audio_part_add()");
	
	$env{'audio_format.ID'}=$App::520::audio_format_original_ID unless $env{'audio_format.ID'};
	
	my $content_updated=0;
	my $content_reindex=0;
	
	# get audio informations
	
	my %audio;
	if ($env{'audio.ID'})
	{
		# detect language
		%audio=App::020::SQL::functions::get_ID(
			'ID' => $env{'audio.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio",
			'columns' => {'*'=>1}
		);
		$env{'audio.ID_entity'}=$audio{'ID_entity'} unless $env{'audio.ID_entity'};
	}
	if (!$env{'audio.ID'})
	{
		$env{'audio.ID'}=$audio{'ID'} if $audio{'ID'};
	}
	
#	if (!$env{'audio_part.ID'} && !$env{'audio_part.part_id'} && !$env{'file'})
#	{
#		$env{'audio_part.part_id'}=1;
#	}
	
	$env{'audio_part_attrs.lng'}=$tom::lng unless $env{'audio_part_attrs.lng'};
	main::_log("lng='$env{'audio_part_attrs.lng'}'");
	
	
	# try to find audio_part by defined audio_part.part_id
	my %audio_part;
	if ($env{'audio_part.part_id'} && !$env{'audio_part.ID'})
	{
		main::_log("audio_part.part_id='$env{'audio_part.part_id'}', audio.ID_entity='$env{'audio.ID_entity'}', !audio_part.ID = checking if part_id exists");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.`a520_audio_part`
			WHERE
				ID_entity='$env{'audio.ID_entity'}' AND
				part_id='$env{'audio_part.part_id'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%audio_part=$sth0{'sth'}->fetchhash();
		$env{'audio_part.ID'}=$audio_part{'ID'} if $audio_part{'ID'};
		main::_log("audio_part.ID='$env{'audio_part.ID'}'");
		
		if ($env{'file_thumbnail'} && $audio_part{'thumbnail_lock'} ne 'Y' && $audio_part{'ID'})
		{
			# lock this thumbnail to not regenerate it
			App::020::SQL::functions::update(
				'ID' => $audio_part{'ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_audio_part",
				'columns' =>
				{
					'thumbnail_lock' => "'Y'"
				},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
		
	}
	
	if (!$env{'audio_part.ID'})
	{
		# finding free part_id
		if (!$env{'audio_part.part_id'})
		{
			my $sql=qq{
				SELECT MAX(part_id) AS part_id
				FROM `$App::520::db_name`.`a520_audio_part`
				WHERE ID_entity='$env{'audio.ID_entity'}'
				LIMIT 1;
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
			my %db0_line=$sth0{'sth'}->fetchhash();
			$env{'audio_part.part_id'}=$db0_line{'part_id'}+1;
			main::_log("new audio_part.part_id='$env{'audio_part.part_id'}'");
		}
		# generating new audio_part!
		main::_log("adding new audio_part");
		my %columns;
		$columns{'ID_entity'}=$env{'audio.ID_entity'};
		$columns{'keywords'}=$env{'audio_part.keywords'} if $env{'audio_part.keywords'};
		$columns{'part_id'}=$env{'audio_part.part_id'} if $env{'audio_part.part_id'};
		$columns{'thumbnail_lock'}="'Y'" if $env{'file_thumbnail'};
		$columns{'ID_brick'}=$env{'audio_part.ID_brick'} || $App::520::brick_default || 'NULL';
		
		if ($env{'audio_part.datetime_air'})
		{
			$columns{'datetime_air'}="'".$env{'audio_part.datetime_air'}."'";
		}
		else
		{
			$columns{'datetime_air'}="NOW()";
		}
		
		$env{'audio_part.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_part",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		main::_log("generated audio_part ID='$env{'audio_part.ID'}'");
		$content_updated=1;
		$content_reindex=1;
	}
	
	# update if necessary
	if ($env{'audio_part.ID'})
	{
		my %columns;
		$columns{'keywords'}="'".$env{'audio_part.keywords'}."'"
			if (exists $env{'audio_part.keywords'} && ($env{'audio_part.keywords'} ne $audio_part{'keywords'}));
		$columns{'datetime_air'}="'".$env{'audio_part.datetime_air'}."'"
			if ($env{'audio_part.datetime_air'} && ($env{'audio_part.datetime_air'} ne $audio_part{'datetime_air'}));
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'audio_part.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_audio_part",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
		
		%audio_part=App::020::SQL::functions::get_ID(
			'ID' => $env{'audio_part.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_part",
			'columns' => {'*'=>1}
		);
		
	}
	
	my %audio_part_attrs;
	if (!$env{'audio_part_attrs.ID'})
	{
		main::_log("finding audio_part_attrs.ID");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.`a520_audio_part_attrs`
			WHERE
				ID_entity='$env{'audio_part.ID'}' AND
				lng='$env{'audio_part_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%audio_part_attrs=$sth0{'sth'}->fetchhash();
		$env{'audio_part_attrs.ID'}=$audio_part_attrs{'ID'};
		main::_log("audio_part_attrs.ID=$env{'audio_part_attrs.ID'}");
	}
	
	
	if (!$env{'audio_part_attrs.ID'})
	{
		# create one language representation of audio_part
		my %columns;
		#$columns{'ID_category'}=$env{'audio_attrs.ID_category'} if $env{'audio_attrs.ID_category'};
		$env{'audio_part_attrs.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_part_attrs",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'audio_part.ID'},
				'lng' => "'$env{'audio_part_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
		$content_updated=1;
		$content_reindex=1;
	}
	
	
	if ($env{'file'})
	{
		main::_log("file='$env{'file'}', audio_part.ID='$env{'audio_part.ID'}', audio_format.ID='$env{'audio_format.ID'}' is specified, so updating audio_part_file");
		
		$env{'audio_part_file.ID'}=audio_part_file_add
		(
			'file' => $env{'file'},
			'file_nocopy' => $env{'file_nocopy'},
			'file_thumbnail' => $env{'file_thumbnail'},
			'file_dontcheck' => $env{'file_dontcheck'},
			'audio_part.ID' => $env{'audio_part.ID'},
			'audio_format.ID' => $env{'audio_format.ID'},
			'from_parent' => "N",
			# used to detect optimal filename
			'audio.datetime_rec_start' => $env{'audio.datetime_rec_start'},
			'audio_attrs.name' => $env{'audio_attrs.name'},
			'audio_part_attrs.name' => $env{'audio_part_attrs.name'},
		);
		if (!$env{'audio_part_file.ID'})
		{
			$t->close();
			return undef;
		}
	}
	
	if ($env{'audio_part_attrs.ID'})
	{
		my %columns;
		
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'audio_part_attrs.name'})."'"
			if ($env{'audio_part_attrs.name'} && ($env{'audio_part_attrs.name'} ne $audio_part_attrs{'name'}));
		$columns{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'audio_part_attrs.name'})."'"
			if ($env{'audio_part_attrs.name'} && ($env{'audio_part_attrs.name'} ne $audio_part_attrs{'name'}));
		$columns{'description'}="'".TOM::Security::form::sql_escape($env{'audio_part_attrs.description'})."'"
			if (exists $env{'audio_part_attrs.description'} && ($env{'audio_part_attrs.description'} ne $audio_part_attrs{'description'}));
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'audio_part_attrs.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_audio_part_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
	}
	
	main::_log("audio_part.ID='$env{'audio_part.ID'}' added/updated");
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::520::db_name,'tb_name'=>'a520_audio',
			'ID_entity'=>$env{'audio.ID_entity'}});
	}
	
	if ($content_reindex)
	{
		_audio_index('ID_entity'=>$env{'audio.ID_entity'});
	}
	
	$t->close();
	return %env;
}



sub audio_part_file_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::audio_part_file_add()");
	
	my $content_updated=0; # not yet implemented
	
	# check if audio_part_file already not exists
	if (!$env{'file'})
	{
		main::_log("missing param file",1);
		$t->close();
		return undef;
	}
	
	if (! -e $env{'file'})
	{
		main::_log("file is missing or can't be read",1);
		$t->close();
		return undef;
	}
	
	if (!$env{'audio_part.ID'})
	{
		main::_log("missing param audio_part.ID",1);
		$t->close();
		return undef;
	}
	
	if (!$env{'audio_format.ID'})
	{
		main::_log("missing param audio_format.ID",1);
		$t->close();
		return undef;
	}
	
	
	my %part=App::020::SQL::functions::get_ID(
		'ID' => $env{'audio_part.ID'},
		'db_h' => "main",
		'db_name' => $App::520::db_name,
		'tb_name' => "a520_audio_part",
		'columns' => {'*'=>1}
	);
	
	my %brick;
	%brick=App::020::SQL::functions::get_ID(
		'ID' => $part{'ID_brick'},
		'db_h' => "main",
		'db_name' => $App::520::db_name,
		'tb_name' => "a520_audio_brick",
		'columns' => {'*'=>1}
	) if $part{'ID_brick'};
	
	# override modifytime
	App::020::SQL::functions::_save_changetime({
		'db_h' => 'main',
		'db_name' => $App::520::db_name,
		'tb_name' => 'a520_audio',
		'ID_entity' => $part{'ID_entity'}
	});
	
	my $sql=qq{
		SELECT
			audio.ID_entity AS ID_entity_audio,
			audio.ID AS ID_audio,
			audio_attrs.ID AS ID_attrs,
			audio_part.ID AS ID_part,
			audio_part_attrs.ID AS ID_part_attrs,
			
			LEFT(audio.datetime_rec_start, 16) AS datetime_rec_start,
			LEFT(audio_attrs.datetime_create, 18) AS datetime_create,
			LEFT(audio.datetime_rec_start,10) AS date_recorded,
			LEFT(audio.datetime_rec_stop, 16) AS datetime_rec_stop,
			
			audio_attrs.ID_category,
			
			audio_attrs.name,
			audio_attrs.name_url,
			audio_attrs.description,
			audio_attrs.order_id,
			audio_attrs.priority_A,
			audio_attrs.priority_B,
			audio_attrs.priority_C,
			audio_attrs.lng,
			
			audio_part_attrs.name AS part_name,
			audio_part_attrs.description AS part_description,
			audio_part.part_id AS part_id,
			audio_part.keywords AS part_keywords,
			audio_part.visits,
			audio_part_attrs.lng AS part_lng,
			
			audio_part.rating_score,
			audio_part.rating_votes,
			(audio_part.rating_score/audio_part.rating_votes) AS rating,
			
			audio_attrs.status,
			audio_part.status AS status_part
			
		FROM
			`$App::520::db_name`.`a520_audio` AS audio
		INNER JOIN `$App::520::db_name`.`a520_audio_ent` AS audio_ent ON
		(
			audio_ent.ID_entity = audio.ID_entity
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_attrs` AS audio_attrs ON
		(
			audio_attrs.ID_entity = audio.ID
		)
		INNER JOIN `$App::520::db_name`.`a520_audio_part` AS audio_part ON
		(
			audio_part.ID_entity = audio.ID_entity
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_part_attrs` AS audio_part_attrs ON
		(
			audio_part_attrs.ID_entity = audio_part.ID AND
			audio_part_attrs.lng = audio_attrs.lng
		)
		
		WHERE
			audio.ID AND
			audio_attrs.ID AND
			audio_part.ID=$env{'audio_part.ID'}
		
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %audio_db=$sth0{'sth'}->fetchhash();
	main::_log("audio.ID='$audio_db{'ID_audio'}' audio.name='$audio_db{'name'}'");
	$env{'from_parent'}='N' unless $env{'from_parent'};
	
	return undef unless $audio_db{'ID_audio'};
	
	# file must be analyzed
	
	# size
	my $file_size=(stat($env{'file'}))[7];
	main::_log("file size='$file_size'");
	
	if (!$file_size)
	{
		$t->close();
		return undef;
	}
	
	my $checksum;
	my $checksum_method;
	
	# checksum
	if ($env{'file_dontcheck'})
	{
		main::_log("calculating checksum 'size'");
		$checksum = $file_size;
		$checksum_method = 'size';
	}
	else
	{
		main::_log("calculating checksum SHA1");
		open(CHKSUM,'<'.$env{'file'});
		my $ctx = Digest::SHA1->new;
		$ctx->addfile(*CHKSUM); # when script hangs here, check file permissions
		$checksum = $ctx->hexdigest;
		$checksum_method = 'SHA1';
	}
	main::_log("file checksum $checksum_method:$checksum");
	
	my $out;
	if ($^O eq 'linux'){$out=`file -b $env{'file'}`;chomp($out);}
	my $file_ext;#
	
	# find if this file type exists
	foreach my $reg (@App::542::mimetypes::filetype_ext)
	{
		if ($out=~/$reg->[0]/){$file_ext=$reg->[1];last;}
	}
	$file_ext='mp3' unless $file_ext;
	$file_ext=$env{'ext'} if $env{'ext'};
	
	main::_log("type='$out' ext='$file_ext'");
	
	
	my $vd = Movie::Info->new || die "Couldn't find an mplayer to use\n";
	
	# file must be copied to have correct extension
	# if (not already has it)
	my $file3=new TOM::Temp::file('ext'=>$file_ext,'dir'=>$main::ENV{'TMP'},'nocreate'=>1);
	my %audio;
	if ((not $env{'file'}=~/\.$file_ext$/) && (!$env{'file_dontcheck'}))
	{
		# this can be very very slow
		main::_log("copying and detecting filetype");
		File::Copy::copy($env{'file'},$file3->{'filename'});
		%audio = $vd->info($file3->{'filename'});
	}
	elsif (!$env{'file_dontcheck'})
	{
		# this can be very slow
		main::_log("detecting filetype");
		%audio = $vd->info($env{'file'});
	}
	else
	{
		
	}
	
	# output audio info
	foreach (keys %audio)
	{
		main::_log("key $_='$audio{$_}'");
	}
	
	# override extension by audiofile metadata
#	$file_ext='mp3' if $audio{'ID_audio_FORMAT'} eq "1FLV";
	
	
	# generate new unique hash
	
	main::_log("get audio_part_file_path");
	my $brick_class='App::520::brick';
		$brick_class.="::".$brick{'name'}
			if $brick{'name'};
	my $audio_=$brick_class->audio_part_file_path({
		'audio_part.ID' => $env{'audio_part.ID'},
		'audio_format.ID' => $env{'audio_format.ID'},
#		'audio_part_file.name' => $name,
		'audio_part_file.file_ext' => $file_ext,
		'audio_part.datetime_air' => $part{'datetime_air'},
		
		'audio.datetime_rec_start' => ($env{'audio.datetime_rec_start'} || $audio_db{'datetime_rec_start'}),
		'audio_attrs.name' => ($env{'audio_attrs.name'} || $audio_db{'name'} || $audio_db{'ID_audio'}),
		'audio_part_attrs.name' => ($env{'audio_part_attrs.name'} || $audio_db{'part_name'})
	});
	
	my $name=$audio_->{'audio_part_file.name'};
	
	
	# Check if audio_part_file for this format exists
	my $sql=qq{
		SELECT
			*
		FROM
			`$App::520::db_name`.`a520_audio_part_file`
		WHERE
			ID_entity=$env{'audio_part.ID'} AND
			ID_format=$env{'audio_format.ID'}
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash)
	{
		# file updating
		main::_log("check for update audio_part_file");
		main::_log("checkum in database = '$db0_line{'file_checksum'}'");
		main::_log("checkum from file = '$checksum_method:$checksum'");
		if ($db0_line{'file_checksum'} eq "$checksum_method:$checksum")
		{
			main::_log("same checksum, just enabling file when disabled");
			
			my %columns;
			
			if ($env{'file_nocopy'})
			{$columns{'file_alt_src'}="'".$env{'file'}."'";}
			else
			{$columns{'file_alt_src'}='NULL';}
			
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => 'main',
				'db_name' => $App::520::db_name,
				'tb_name' => 'a520_audio_part_file',
				'columns' =>
				{
					'audio_codec' => "'$audio{'audio_codec'}'",
					'audio_bitrate' => "'$audio{'audio_bitrate'}'",
					'length' => "SEC_TO_TIME(".int($audio{'length'}).")",
					'file_size' => "'$file_size'",
					'from_parent' => "'$env{'from_parent'}'",
					'regen' => "'N'",
					'status' => "'Y'",
#					'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
					%columns
				},
				'-journalize' => 1,
			);
			$t->close();
			
			# override modifytime
			App::020::SQL::functions::_save_changetime({
				'db_h' => 'main',
				'db_name' => $App::520::db_name,
				'tb_name' => 'a520_audio',
				'ID_entity' => $part{'ID_entity'}
			});
#			audio_part_smil_generate('audio_part.ID' => $env{'audio_part.ID'});
			_audio_index('ID_entity'=>$part{'ID_entity'});
			return $db0_line{'ID'};
		}
		else
		{
			main::_log("checksum differs");
			my %columns;
			
			if ($env{'file_nocopy'})
			{$columns{'file_alt_src'}="'".$env{'file'}."'";}
			else
			{$columns{'file_alt_src'}='NULL';}
			
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => 'main',
				'db_name' => $App::520::db_name,
				'tb_name' => 'a520_audio_part_file',
				'columns' =>
				{
					'name' => "'$name'",
					'audio_bitrate' => "'$audio{'bitrate'}'",
					'audio_codec' => "'$audio{'audio_codec'}'",
					'audio_bitrate' => "'$audio{'audio_bitrate'}'",
					'length' => "SEC_TO_TIME(".int($audio{'length'}).")",
					'file_size' => "'$file_size'",
					'file_checksum' => "'$checksum_method:$checksum'",
					'file_ext' => "'$file_ext'",
					'from_parent' => "'$env{'from_parent'}'",
					'regen' => "'N'",
					'status' => "'Y'",
#					'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
					%columns
				},
				'-journalize' => 1,
			);
			if (!$env{'file_nocopy'})
			{
				
				my $audio_=$brick_class->audio_part_file_path({
					'audio_part.ID' => $part{'ID'},
					'audio_part.datetime_air' => $part{'datetime_air'},
	#				'audio.ID' => $audio{'ID_audio'},
					'audio_part_file.ID' => $db0_line{'ID'},
					'audio_format.ID' => $env{'audio_format.ID'},
					'audio_part_file.name' => $name,
					'audio_part_file.file_ext' => $file_ext,
				});
				
				my $path=$audio_->{'dir'}.'/'.$audio_->{'file_path'};
				
#				my $path=$tom::P_media.'/a520/audio/part/file/'._audio_part_file_genpath
#				(
#					$env{'audio_format.ID'},
#					$db0_line{'ID'},
#					$name,
#					$file_ext
#				);
				main::_log("copy to $path");
				if (File::Copy::copy($env{'file'},$path))
				{
				}
				else
				{
					main::_log("file can't be copied: $!",1);
					$t->close();
					return undef;
				}
			}
			$t->close();
			# override modifytime
			App::020::SQL::functions::_save_changetime({
				'db_h' => 'main',
				'db_name' => $App::520::db_name,
				'tb_name' => 'a520_audio',
				'ID_entity' => $part{'ID_entity'}
			});
#			audio_part_smil_generate('audio_part.ID' => $env{'audio_part.ID'});
			_audio_index('ID_entity'=>$part{'ID_entity'});
			return $db0_line{'ID'};
		}
	}
	else
	{
		# file creating
		main::_log("creating audio_part_file");
		my %columns;
		$columns{'file_alt_src'}="'$env{'file'}'" if $env{'file_nocopy'};
		
		$columns{'status'}="'Y'";
		$columns{'status'}="'W'" if $env{'file_dontcheck'};
		
		my $ID=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_audio_part_file",
			'columns' =>
			{
				'ID_entity' => $env{'audio_part.ID'},
				'ID_format' => $env{'audio_format.ID'},
				'name' => "'$name'",
				'audio_bitrate' => "'$audio{'bitrate'}'",
				'audio_codec' => "'$audio{'audio_codec'}'",
				'audio_bitrate' => "'$audio{'audio_bitrate'}'",
				'length' => "SEC_TO_TIME(".int($audio{'length'}).")",
				'file_size' => "'$file_size'",
				'file_checksum' => "'$checksum_method:$checksum'",
				'file_ext' => "'$file_ext'",
				'from_parent' => "'$env{'from_parent'}'",
#				'status' => "'Y'",
#				'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
				%columns
			},
			'-journalize' => 1
		);
		if (!$ID)
		{
			$t->close();
			return undef
		};
		$ID=sprintf("%08d",$ID);
		main::_log("ID='$ID'");
		
		if (!$env{'file_nocopy'})
		{
			
			my $audio_=$brick_class->audio_part_file_path({
				'audio_part.ID' => $env{'audio_part.ID'},
				'audio_part.datetime_air' => $part{'datetime_air'},
#				'audio.ID' => $audio{'ID_audio'},
				'audio_part_file.ID' => $ID,
				'audio_format.ID' => $env{'audio_format.ID'},
				'audio_part_file.name' => $name,
				'audio_part_file.file_ext' => $file_ext,
			});
			
#			use Data::Dumper;print Dumper($audio_);
#			$audio{'dir'}=$audio_->{'dir'};
#			$audio{'file_part_path'}=$audio_->{'file_path'};
			
			my $path=$audio_->{'dir'}.'/'.$audio_->{'file_path'};
#			my $path=$tom::P_media.'/a520/audio/part/file/'._audio_part_file_genpath
#			(
#				$env{'audio_format.ID'},
#				$ID,
#				$name,
#				$file_ext
#			);
			main::_log("copy to $path");
			if (File::Copy::copy($env{'file'},$path))
			{
			}
			else
			{
				main::_log("file can't be copied: $!",1);
				$t->close();
				return undef;
			}
		}
		$t->close();
		# override modifytime
		App::020::SQL::functions::_save_changetime({
			'db_h' => 'main',
			'db_name' => $App::520::db_name,
			'tb_name' => 'a520_audio',
			'ID_entity' => $part{'ID_entity'}
		});
#		audio_part_smil_generate('audio_part.ID' => $env{'audio_part.ID'});
		_audio_index('ID_entity'=>$part{'ID_entity'});
		return $ID;
	}
	
	$t->close();
	# override modifytime
	App::020::SQL::functions::_save_changetime({
		'db_h' => 'main',
		'db_name' => $App::520::db_name,
		'tb_name' => 'a520_audio',
		'ID_entity' => $part{'ID_entity'}
	});
	
#	audio_part_smil_generate('audio_part.ID' => $env{'audio_part.ID'});
	_audio_index('ID_entity'=>$part{'ID_entity'});
	
	return 1;
}


sub audio_part_file_generate
{
	my %env=@_;
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{
			'routing_key' => 'db:'.$App::520::db_name,
			'class' => 'encoder',
			'deduplication' => 1}); # do it in background
	}
	
	my $t=track TOM::Debug(__PACKAGE__."::audio_part_file_generate($env{'audio_part.ID'},".
		($env{'audio_format.ID'}||$env{'audio_format.name'}).")");
	
	# get info about audio_part
	my %audio_part=App::020::SQL::functions::get_ID(
		'ID' => $env{'audio_part.ID'},
		'db_h' => 'main',
		'db_name' => $App::520::db_name,
		'tb_name' => 'a520_audio_part',
		'columns' =>
		{
			'*' => 1,
#			'ID_brick' => 1,
		}
	);
	
	my %brick;
	%brick=App::020::SQL::functions::get_ID(
		'ID' => $audio_part{'ID_brick'},
		'db_h' => "main",
		'db_name' => $App::520::db_name,
		'tb_name' => "a520_audio_brick",
		'columns' => {'*'=>1}
	) if $audio_part{'ID_brick'};
	
	main::_log("audio_part.ID='$audio_part{'ID'}' part_id='$audio_part{'part_id'}' status='$audio_part{'status'}'");
	
	if ($audio_part{'status'} ne "Y" && $audio_part{'status'} ne "N")
	{
		main::_log("audio_part is not available",1);
		$t->close();
		return undef;
	}
	
	my %format;
	
	if ($env{'audio_format.ID'})
	{
		%format=App::020::SQL::functions::get_ID(
			'ID' => $env{'audio_format.ID'},
			'db_h' => 'main',
			'db_name' => $App::520::db_name,
			'tb_name' => 'a520_audio_format',
			'columns' =>
			{
				'name' => 1,
				'process' => 1,
				'definition' => 1,
			}
		);
		$env{'audio_format.name'}=$format{'name'};
	}
	
	# lock time to this current
	$main::time_current=$tom::time_current=time();
	
	main::_log("audio_format ID='$format{'ID'}' name='$format{'name'}' status='$format{'status'}'");
	
	if ($format{'status'} ne "Y" &&  $format{'status'} ne "L")
	{
		main::_log("audio_format is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	
	# find parent
	my %format_parent=App::020::SQL::functions::tree::get_parent_ID(
		'ID' => $format{'ID'},
		'db_h' => 'main',
		'db_name' => $App::520::db_name,
		'tb_name' => 'a520_audio_format'
	);
	
	if ($format{'ID'} eq $App::520::audio_format_original_ID && $format{'process'})
	{
		main::_log("regenerate audio_part_file");
		%format_parent=%format;
	}
	elsif ($format_parent{'status'} ne "Y" &&  $format_parent{'status'} ne "L")
	{
		main::_log("parent audio_format is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	# find audio_part_file defined by parent audio_format (to convert from)
	
	# audio.ID_entity is related to audio_part_file.ID_entity
	
	my $sql=qq{
		SELECT
			*
		FROM
			`$App::520::db_name`.`a520_audio_part_file`
		WHERE
			ID_entity=$audio_part{'ID'} AND
			ID_format=$format_parent{'ID'}
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %file_parent=$sth0{'sth'}->fetchhash();
	
	if ($file_parent{'status'} ne "Y")
	{
		main::_log("parent audio_part_file.ID='$file_parent{'ID'}' is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	my $brick_class='App::520::brick';
		$brick_class.="::".$brick{'name'}
			if $brick{'name'};
	
	my $sql=qq{
		INSERT INTO `$App::520::db_name`.`a520_audio_part_file_process`
		(
			`ID_part`,
			`ID_format`,
			`hostname`,
			`hostname_PID`,
			`process`,
			`datetime_start`
		)
		VALUES
		(
			'$audio_part{'ID'}',
			'$format{'ID'}',
			'$TOM::hostname',
			'$$',
			'',
			NOW()
		)
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my $process_ID=$sth0{'sth'}->insertid();
	
	
	my $audio_=$brick_class->audio_part_file_path({
		'audio_part.ID' => $audio_part{'ID'},
		'audio_part.datetime_air' => $audio_part{'datetime_air'},
#		'audio.ID' => $audio{'ID_audio'},
		'audio_part_file.ID' => $file_parent{'ID'},
		'audio_format.ID' => $format_parent{'ID'},
		'audio_part_file.name' => $file_parent{'name'},
		'audio_part_file.file_ext' => $file_parent{'file_ext'},
	});
	
	my $audio1_path=$file_parent{'file_alt_src'} || $audio_->{'dir'}.'/'.$audio_->{'file_path'};
	
#	main::_log("path=$path",1);
#	my $audio1_path=$file_parent{'file_alt_src'} || $tom::P_media.'/a520/audio/part/file/'._audio_part_file_genpath
#	(
#		$format_parent{'ID'},
#		$file_parent{'ID'},
#		$file_parent{'name'},
#		$file_parent{'file_ext'}
#	);
	
	main::_log("path to parent audio_part_file='$audio1_path'");
	
	my $audio1={};
	no strict;
	if (${$brick_class.'::copybeforeencode'})
#	if ($brick_class->{'copybeforeencode'})
	{
		$audio1=new TOM::Temp::file('dir'=>$main::ENV{'TMP'},'nocreate'=>1);
		main::_log("copy parent audio to '$audio1->{'filename'}'");
		File::Copy::copy($audio1_path, $audio1->{'filename'});
		$audio1_path=$audio1->{'filename'};
	}
	
	my $audio2=new TOM::Temp::file('dir'=>$main::ENV{'TMP'},'nocreate'=>1);
	
	my %out=audio_part_file_process(
		'audio1' => $audio1_path,
		'audio2' => $audio2->{'filename'},
		'process' => $env{'process'} || $format{'process'},
		'process_force' => $env{'process_force'},
		'definition' => $format{'definition'}
	);
	
	main::_log("return=$out{'return'}");
	
	if ($out{'return'})
	{
		main::_log("parent audio_part_file can't be processed",1);
#		exit;
#		if ($file_parent{'ID_format'} == $App::520::audio_format_original_ID && ($out <=> 512))
#		{
#			main::_log("lock processing of audio_part.ID='$env{'audio_part.ID'}'",1);
#			App::020::SQL::functions::update(
#				'ID' => $env{'audio_part.ID'},
#				'db_h' => "main",
#				'db_name' => $App::520::db_name,
#				'tb_name' => "a520_audio_part",
#				'columns' =>
#				{
#					'process_lock' => "'E'"
#				},
#				'-journalize' => 1
#			);
			
			# create empty audio_part_file
			# Check if audio_part_file for this format exists
			my $sql=qq{
				SELECT
					*
				FROM
					`$App::520::db_name`.`a520_audio_part_file`
				WHERE
					ID_entity=$env{'audio_part.ID'} AND
					ID_format=$format{'ID'}
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
			if (my %db0_line=$sth0{'sth'}->fetchhash)
			{
				if ($db0_line{'ID_format'} eq "1")
				{
					main::_log("can't set source format as invalid",1);
					App::020::SQL::functions::update(
						'ID' => $db0_line{'ID'},
						'db_h' => 'main',
						'db_name' => $App::520::db_name,
						'tb_name' => 'a520_audio_part_file',
						'columns' =>
						{
							'from_parent' => "'Y'",
							'regen' => "'N'",
							'status' => "'E'",
						},
						'-journalize' => 1,
					);
				}
				else
				{
					App::020::SQL::functions::update(
						'ID' => $db0_line{'ID'},
						'db_h' => 'main',
						'db_name' => $App::520::db_name,
						'tb_name' => 'a520_audio_part_file',
						'columns' =>
						{
							'name' => "''",
							'audio_bitrate' => "''",
							'audio_codec' => "''",
							'audio_bitrate' => "''",
							'length' => "''",
							'file_alt_src' => "''",
							'file_size' => "''",
							'file_checksum' => "''",
							'file_ext' => "''",
							'from_parent' => "'Y'",
							'regen' => "'N'",
							'status' => "'E'",
						},
						'-journalize' => 1,
					);
				}
			}
			else
			{
				my $ID=App::020::SQL::functions::new(
					'db_h' => "main",
					'db_name' => $App::520::db_name,
					'tb_name' => "a520_audio_part_file",
					'columns' =>
					{
						'ID_entity' => $env{'audio_part.ID'},
						'ID_format' => $format{'ID'},
						'name' => "''",
						'audio_bitrate' => "''",
						'audio_codec' => "''",
						'audio_bitrate' => "''",
						'length' => "''",
						'file_alt_src' => "''",
						'file_size' => "''",
						'file_checksum' => "''",
						'file_ext' => "''",
						'from_parent' => "'Y'",
						'regen' => "'N'",
						'status' => "'E'",
					},
					'-journalize' => 1
				);
			}
#		}
		
		my $sql=qq{
			UPDATE `$App::520::db_name`.`a520_audio_part_file_process`
			SET datetime_stop=NOW(), status='E'
			WHERE ID=$process_ID
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		
		$t->close();
		return undef;
	}
	
	audio_part_file_add
	(
		'file' => $audio2->{'filename'},
		'ext' => $out{'ext'},
		'audio_part.ID' => $audio_part{'ID'},
		'audio_format.ID' => $format{'ID'},
		'from_parent' => "Y",
		'thumbnail_lock_ignore' => $env{'thumbnail_lock_ignore'}
	) || do {
		my $sql=qq{
			UPDATE `$App::520::db_name`.`a520_audio_part_file_process`
			SET datetime_stop=NOW(), status='E'
			WHERE ID=$process_ID
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		$t->close();return undef
	};
	
	my $sql=qq{
		UPDATE `$App::520::db_name`.`a520_audio_part_file_process`
		SET datetime_stop=NOW(), status='Y'
		WHERE ID=$process_ID
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	$t->close();
	return 1;
}


sub audio_part_file_process
{
	my %env=@_;
	my %outret;
	my $t=track TOM::Debug(__PACKAGE__."::audio_part_file_process()");
	main::_log("audio1='$env{'audio1'}'");
	main::_log("audio2='$env{'audio2'}'");
	
	my $temp_passlog=new TOM::Temp::file('unlink_ext'=>'*','ext'=>'log','dir'=>$main::ENV{'TMP'},'nocreate_'=>1);
	my $temp_statslog=new TOM::Temp::file('unlink_ext'=>'*','ext'=>'log','dir'=>$main::ENV{'TMP'},'nocreate_'=>1);
	
	my $procs; # how many changes have been made in audio2 file
	
	if (!$env{'ext'})
	{
		$env{'ext'}=$App::520::audio_format_ext_default;
		$procs++;
	}
	
	# read the first audio
	main::_log("reading file '$env{'audio1'}'");
	my $movie1 = Movie::Info->new || die "Couldn't find an mplayer to use\n";
	my %movie1_info = $movie1->info($env{'audio1'});
	foreach (keys %movie1_info)
	{
		main::_log("key $_='$movie1_info{$_}'");
	}
	
	my $target_is_same=0;
	foreach my $line(split('\n',$env{'definition'}))
	{
		$line=~s|\r||;
		next unless $line;
		my @ref=split('=',$line);
		main::_log("target definition key $ref[0]='$ref[1]'");
		
		my $ref1_same=0;
		foreach (split(';',$ref[1])){$ref1_same=1 if $movie1_info{$ref[0]} eq $_};
		if (!$ref1_same){$target_is_same=0;last;}
		
		$target_is_same=1;
	}
	
	$target_is_same=0 if $env{'process_force'};
	
	if ($target_is_same)
	{
		main::_log("target audio is the same as source");
		main::_log("copying the file...");
		File::Copy::copy($env{'audio1'}, $env{'audio2'});
		$t->close();
		$outret{'return'}=0;
		return %outret;
	}
	
	$env{'fps'}=$movie1_info{'fps'} if $movie1_info{'fps'};
	
	my @files;
	my %files_key;
	$env{'process'}=~s|\r\n|\n|g;
	$env{'process'}=~s|\s+$||m;
	$env{'process'}.="\nencode()" unless $env{'process'}=~/encode\(\)$/m;
	
#	if (-e 'frameno.avi'){main::_log("removing frameno.avi");unlink 'frameno.avi'}
	
	foreach my $function(split('\n',$env{'process'}))
	{
		$function=~s|\s+$||g;
		$function=~s|^\s+||g;
		
		next if $function=~/^#/;
		next unless $function=~/^([\w_]+)\((.*)\)/;
		
		my $function_name=$1;
		my $function_params=$2;
		
		my @params;
		foreach my $param (split(',',$function_params,2))
		{
			if ($param=~/^'.*'$/){$param=~s|^'||;$param=~s|'$||;}
			if ($param=~/^".*"$/){$param=~s|^"||;$param=~s|"$||;}
			push @params, $param;
		}
		
		if ($function_name eq "set_env")
		{
			main::_log("exec $function_name($params[0],$params[1])");
			#push @env0, '-'.$params[0].' '.$params[1];
			$env{$params[0]}=$params[1];
			#$procs++;
			next;
		}
		
		if ($function_name eq "del_env")
		{
			main::_log("exec $function_name(@params)");
			foreach (@params){delete $env{$_};}
			next;
		}
		
		if ($function_name eq "stop")
		{
			main::_log("exec $function_name()");
			last;
		}
		
		if ($function_name eq "encode")
		{
			main::_log("exec $function_name()");
			
			# add params in this order
			my @encoder_env;
			my $ext='mp3';
			if (!$env{'encoder'} || $env{'encoder'} eq "avconv")
			{
				$env{'encoder'}="avconv";
				if ($env{'pass'})
				{
					push @encoder_env, '-pass '.$env{'pass'};
					push @encoder_env, '-passlogfile '.$temp_passlog->{'filename'};
#					push @encoder_env, '-stats '.$temp_statslog->{'filename'};
				}
				if ($env{'vframes'}){push @encoder_env, '-vframes '.$env{'vframes'};}
				if ($env{'f'}){push @encoder_env, '-f '.$env{'f'};}
				if ($env{'map'}){push @encoder_env, '-map '.$env{'map'};}
				if ($env{'map0'}){push @encoder_env, '-map '.$env{'map0'};}
				if ($env{'map1'}){push @encoder_env, '-map '.$env{'map1'};}
				if ($env{'map2'}){push @encoder_env, '-map '.$env{'map2'};}
				if (exists $env{'an'} && !$env{'acodec'}){push @encoder_env, '-an'}
				if (exists $env{'sameq'}){push @encoder_env, '-sameq '}
				if (exists $env{'deinterlace'}){push @encoder_env, '-deinterlace '}
				if ($env{'flags'}){push @encoder_env, '-flags '.$env{'flags'};}
				if ($env{'flags2'}){push @encoder_env, '-flags2 '.$env{'flags2'};}
				if ($env{'cmp'}){push @encoder_env, '-cmp '.$env{'cmp'};}
				if ($env{'subcmp'}){push @encoder_env, '-subcmp '.$env{'subcmp'};}
				if ($env{'mbcmp'}){push @encoder_env, '-mbcmp '.$env{'mbcmp'};}
				if ($env{'ildctcmp'}){push @encoder_env, '-ildctcmp '.$env{'ildctcmp'};}
				if ($env{'precmp'}){push @encoder_env, '-precmp '.$env{'precmp'};}
				if ($env{'skipcmp'}){push @encoder_env, '-skipcmp '.$env{'skipcmp'};}
				if (exists $env{'mv0'}){push @encoder_env, '-mv0 ';}
				if ($env{'mbd'}){push @encoder_env, '-mbd '.$env{'mbd'};}
				if ($env{'inter_matrix'}){push @encoder_env, '-inter_matrix '.$env{'inter_matrix'};}
				if ($env{'pred'}){push @encoder_env, '-pred '.$env{'pred'};}
				if ($env{'partitions'}){push @encoder_env, '-partitions '.$env{'partitions'};}
				if ($env{'me'}){push @encoder_env, '-me '.$env{'me'};}
				if ($env{'subq'}){push @encoder_env, '-subq '.$env{'subq'};}
				if ($env{'trellis'}){push @encoder_env, '-trellis '.$env{'trellis'};}
				if ($env{'refs'}){push @encoder_env, '-refs '.$env{'refs'};}
				if ($env{'bf'}){push @encoder_env, '-bf '.$env{'bf'};}
				if ($env{'b_strategy'}){push @encoder_env, '-b_strategy '.$env{'b_strategy'};}
				if ($env{'coder'}){push @encoder_env, '-coder '.$env{'coder'};}
				if ($env{'me_range'}){push @encoder_env, '-me_range '.$env{'me_range'};}
				if ($env{'q'}){push @encoder_env, '-q '.$env{'q'};}
				if ($env{'g'}){push @encoder_env, '-g '.$env{'g'};}
				if ($env{'strict'}){push @encoder_env, '-strict '.$env{'strict'};}
				if ($env{'keyint_min'}){push @encoder_env, '-keyint_min '.$env{'keyint_min'};}
#				if ($env{'keyint'}){push @encoder_env, '-keyint '.$env{'keyint'};}
				if ($env{'sc_threshold'}){push @encoder_env, '-sc_threshold '.$env{'sc_threshold'};}
				if ($env{'i_qfactor'}){push @encoder_env, '-i_qfactor '.$env{'i_qfactor'};}
				if ($env{'bt'}){push @encoder_env, '-bt '.$env{'bt'};}
				if ($env{'rc_eq'}){push @encoder_env, "-rc_eq '".$env{'rc_eq'}."'";}
				if ($env{'qcomp'}){push @encoder_env, '-qcomp '.$env{'qcomp'};}
				if ($env{'qblur'}){push @encoder_env, '-qblur '.$env{'qblur'};}
				if ($env{'qmin'}){push @encoder_env, '-qmin '.$env{'qmin'};}
				if ($env{'qmax'}){push @encoder_env, '-qmax '.$env{'qmax'};}
				if ($env{'qdiff'}){push @encoder_env, '-qdiff '.$env{'qdiff'};}
				if ($env{'vcodec'}){push @encoder_env, '-vcodec '.$env{'vcodec'};}
#				if ($env{'vpre'}){push @encoder_env, '-vpre '.$env{'vpre'};}
				if ($env{'preset'}){push @encoder_env, '-preset '.$env{'preset'};}
				if ($env{'tune'}){push @encoder_env, '-tune '.$env{'tune'};}
				if ($env{'profile'}){push @encoder_env, '-profile '.$env{'profile'};}
				if ($env{'pass'})
				{
					push @encoder_env, '-stats '.$temp_statslog->{'filename'};
				}
				if (exists $env{'threads'}){push @encoder_env, '-threads '.$env{'threads'};}
				if ($env{'b'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'bitrate'})
					{ # check for upscale
						my $bitrate=$env{'b'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'bitrate'})
						{
							push @encoder_env, '-b '.$movie1_info{'bitrate'};
						}
						else
						{
							push @encoder_env, '-b '.$env{'b'};
						}
					}
					else
					{
						push @encoder_env, '-b '.$env{'b'};
					}
				}
				if ($env{'s'}){push @encoder_env, '-s '.$env{'s'};}
				if ($env{'r'}){push @encoder_env, '-r '.$env{'r'};}
				if ($env{'acodec'}){
					push @encoder_env, '-acodec '.$env{'acodec'};
					if ($env{'acodec'})
					{
						push @encoder_env, '-strict -2';
					}
				}
				if ($env{'ab'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'audio_bitrate'})
					{ # check for upscale
						my $bitrate=$env{'ab'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'audio_bitrate'})
						{
							push @encoder_env, '-ab '.$movie1_info{'audio_bitrate'};
						}
						else
						{
							push @encoder_env, '-ab '.$env{'ab'};
						}
					}
					else
					{
						push @encoder_env, '-ab '.$env{'ab'};
					}
				}
				if ($env{'b:a'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'audio_bitrate'})
					{ # check for upscale
						my $bitrate=$env{'b:a'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'audio_bitrate'})
						{
							push @encoder_env, '-b:a '.$movie1_info{'audio_bitrate'};
						}
						else
						{
							push @encoder_env, '-b:a '.$env{'b:a'};
						}
					}
					else
					{
						push @encoder_env, '-b:a '.$env{'b:a'};
					}
				}
				if ($env{'ar'}){push @encoder_env, '-ar '.$env{'ar'};}
				if ($env{'ac'}){push @encoder_env, '-ac '.$env{'ac'};}
				if ($env{'fs'}){push @encoder_env, '-fs '.$env{'fs'};}
				if ($env{'ss'}){push @encoder_env, '-ss '.$env{'ss'};}
				if ($env{'t'}){push @encoder_env, '-t '.$env{'t'};}
				if ($env{'async'}){push @encoder_env, '-async '.$env{'async'};}
				
				# suggest extension
				$ext='mp3' if $env{'f'} eq "mp3";
				$ext='mp4' if $env{'f'} eq "mp4";
				$ext='flv' if $env{'f'} eq "flv";
			}
			
			$outret{'ext'}=$ext;
			
			my $temp_audio;
			if ($env{'pass'})
			{
				if ($files_key{'pass'})
				{
					main::_log("using same file for pass encoding ".$files_key{'pass'}->{'filename'});
					$temp_audio=$files_key{'pass'};
				}
				else
				{
					$temp_audio=new TOM::Temp::file('ext'=>$ext,'dir'=>$main::ENV{'TMP'},'nocreate_'=>1);
					$files_key{'pass'}=$temp_audio;
				}
			}
			$temp_audio=new TOM::Temp::file('ext'=>$ext,'dir'=>$main::ENV{'TMP'},'nocreate_'=>1) unless $temp_audio;
			# don't erase files after partial encode()
			push @files, $temp_audio;
			$files_key{$env{'o_key'}}=$temp_audio if $env{'o_key'};
			
			
			#main::_log("encoding to file '$temp_audio->{'filename'}'");
			my $ff=$env{'audio1'};
			$ff=~s| |\\ |g;
			
#			my $cmd="/usr/bin/mencoder ".$ff." -o ".($env{'o'} || $temp_audio->{'filename'});
			my $cmd="cd $main::ENV{'TMP'};$avconv_exec -y -i ".$ff;
			#$cmd="cd $main::ENV{'TMP'};$ffmpeg_exec -y -i ".$ff if $env{'encoder'} eq "ffmpeg";
			#$cmd="cd $main::ENV{'TMP'};$avconv_exec -y -i ".$ff if $env{'encoder'} eq "avconv";
			
			foreach (@encoder_env){$cmd.=" $_";}
#			$cmd.=" ".($env{'o'} || $temp_audio->{'filename'}) if $env{'encoder'} eq "ffmpeg";
			$cmd.=" ".($env{'o'} || $temp_audio->{'filename'}) if $env{'encoder'} eq "avconv";
			main::_log("cmd=$cmd");
			
			$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
#			$outret{'return'}=undef if $outret{'return'}==256;
			if ($outret{'return'} && $outret{'return'} != 11){$t->close();return %outret}
			
			$procs++;
			next;
		}
		
		main::_log("unknown '$function'",1);
		$t->close();
		return %outret;
		
	}
	
	if ($procs)
	{
		main::_log("copying last processed file '$files[-1]->{'filename'}' ext='$env{'ext'}'");
		File::Copy::copy($files[-1]->{'filename'}, $env{'audio2'});
		$t->close();
		$outret{'return'}=0;return %outret;
	}
	else
	{
		main::_log("copying same file '$env{'audio2'}' ext='$env{'ext'}'");
		File::Copy::copy($env{'audio1'}, $env{'audio2'});
		chmod 0666, $env{'audio2'};
		$t->close();
		$outret{'return'}=0;return %outret;
	}
	
	$t->close();
	return %outret;
}


sub _a210_by_cat
{
	my $cats=shift;
	my %env=@_;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	$env{'db_name'}=$App::210::db_name unless $env{'db_name'};
	my $cache_key=$env{'db_name'}.'::'.$env{'lng'}.'::'.join('::',@{$cats});
	
	# changetimes
	my $changetime_a520=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::520::db_name,
		'tb_name' => 'a520_audio_cat',
	});
	my $changetime_a210=App::020::SQL::functions::_get_changetime({
		'db_name' => $env{'db_name'},
		'tb_name' => 'a210_page',
	});
	
	if ($TOM::CACHE && $TOM::CACHE_memcached && $main::cache)
	{
		my $cache=$Ext::CacheMemcache::cache->get(
			'namespace' => "fnc_cache",
			'key' => 'App::520::functions::_a210_by_cat::'.$cache_key
		);
		if (($cache->{'time'} > $changetime_a210) && ($cache->{'time'} > $changetime_a520))
		{
			return $cache->{'value'};
		}
	}
	
	# find path
	my @categories;
	my %sql_def=('db_h' => "main",'db_name' => $App::520::db_name,'tb_name' => "a520_audio_cat");
	foreach my $cat(@{$cats})
	{
		my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID FROM $App::520::db_name.a520_audio_cat WHERE ID_entity=? AND lng=? LIMIT 1},
			'bind'=>[$cat,$env{'lng'}],'log'=>0,'quiet'=>1,
			'-cache' => 86400*7,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime({
				'db_name' => $App::520::db_name,
				'tb_name' => 'a520_audio_cat',
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
				'-cache' => 86400*7
				# autocached by changetime
			)
		)
		{
			push @{$categories[$i]},$p->{'ID_entity'};
			$i++;
		}
	}
	
	my $category;
	for my $i (1 .. @categories)
	{
		foreach my $cat (@{$categories[-$i]})
		{
			my %db0_line;
			foreach my $relation(App::160::SQL::get_relations(
				'db_name' => $env{'db_name'},
				'l_prefix' => 'a210',
				'l_table' => 'page',
				#'l_ID_entity' = > ???
				'r_prefix' => "a520",
				'r_table' => "audio_cat",
				'r_ID_entity' => $cat,
				'rel_type' => "link",
				'status' => "Y"
			))
			{
				# je toto relacia na moju jazykovu verziu a je aktivna?
				my %sth0=TOM::Database::SQL::execute(
				qq{SELECT ID FROM $env{'db_name'}.a210_page WHERE ID_entity=? AND lng=? AND status IN ('Y','L') LIMIT 1},
				'bind'=>[$relation->{'l_ID_entity'},$env{'lng'}],'quiet'=>1,
					'-cache' => 86400*7,
					'-cache_changetime' => App::020::SQL::functions::_get_changetime({
						'db_name' => $env{'db_name'},
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
			'key' => 'App::520::functions::_a210_by_cat::'.$cache_key,
			'value' => {
				'time' => time(),
				'value' => $category
			},
			'expiration' => '86400S'
		);
	}
	
	return $category;
}


sub audio_part_visit
{
	my $ID_part=shift;
	
	if ($Redis)
	{
		my $key='main::'.$App::520::db_name.'::a520_audio_part::ID_'.$ID_part;
		my $count_visits = $Redis->hmget('C3|db_entity|'.$key,'_firstvisit','visits');
		if (
			($count_visits->[0] <= ($main::time_current - 1200)) # save every 10 minutes
			|| $count_visits->[1] >= 1000)
		{
			# it's time to save
			TOM::Database::SQL::execute(qq{
				UPDATE `$App::520::db_name`.a520_audio_part
				SET visits = visits + $count_visits->[1]
				WHERE ID = $ID_part
				LIMIT 1
			},'quiet'=>1,'-jobify'=>1) if $count_visits->[1];
			$Redis->hmset('C3|db_entity|'.$key,
				'visits',1,
				'_firstvisit', $main::time_current,
				sub {}
			);
			$Redis->expire($key,(86400 * 7 * 4),sub {});
		}
		else
		{
			$Redis->hincrby('C3|db_entity|'.$key,'visits',1,sub {});
			if (!$count_visits->[0])
			{
				$Redis->expire($key,(86400 * 7 * 4),sub {});
			}
		}
		return 1;
	}
	
	# check if this visit is in audio_part
	my $cache={};
	$cache=$Ext::CacheMemcache::cache->get(
		'namespace' => $App::520::db_name.".a520_audio_part.visit",
		'key' => $ID_part
	) if $TOM::CACHE_memcached;
	if (!$cache->{'time'} && $TOM::CACHE_memcached)# try again when memcached sends empty key (bug)
	{
		usleep(3000); # 3 miliseconds
		$cache=$Ext::CacheMemcache::cache->get(
			'namespace' => $App::520::db_name.".a520_audio_part.visit",
			'key' => $ID_part
		)
	}
	
	if (!$cache->{'time'})
	{
		$cache->{'visits'}=1;
		$Ext::CacheMemcache::cache->set
		(
			'namespace' => $App::520::db_name.".a520_audio_part.visit",
			'key' => $ID_part,
			'value' =>
			{
				'time' => time(),
				'visits' => $cache->{'visits'}
			},
			'expiration' => "24H"
		) if $TOM::CACHE_memcached;
		# update SQL
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::520::db_name`.a520_audio_part
			SET visits=visits+1
			WHERE ID=$ID_part
			LIMIT 1
		},'quiet'=>1,'-jobify'=>1) unless $TOM::CACHE_memcached;
		return 1;
	}
	
	# return unless memcached available
	return 1 unless $TOM::CACHE_memcached;
	
	$cache->{'visits'}++;
	
	my $old=time()-$cache->{'time'};
	
	if ($old > (60*10))
	{
		# update database
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::520::db_name`.a520_audio_part
			SET visits=visits+$cache->{'visits'}
			WHERE ID=$ID_part
			LIMIT 1
		},'quiet'=>1,'-jobify'=>1);
		$cache->{'visits'}=0;
		$cache->{'time'}=time();
	}
	
	$Ext::CacheMemcache::cache->set
	(
		'namespace' => $App::520::db_name.".a520_audio_part.visit",
		'key' => $ID_part,
		'value' =>
		{
			'time' => $cache->{'time'},
			'visits' => $cache->{'visits'}
		},
		'expiration' => "24H"
	) if $TOM::CACHE_memcached;
	
	return 1;
}


sub get_audio_part_file
{
	my %env=@_;
	
	if (!$env{'audio.ID_entity'} && !$env{'audio_part.ID'})
	{
		return undef;
	}
	
	$env{'audio_part_file.ID_format'} = $App::520::audio_format_full_ID unless $env{'audio_part_file.ID_format'};
	$env{'audio_attrs.lng'}=$tom::lng unless $env{'audio_attrs.lng'};
	
	my $sql=qq{
		SELECT
			audio.ID_entity,
			audio.ID,
			
			audio.ID_entity AS ID_entity_audio,
			audio.ID AS ID_audio,
			audio_attrs.ID AS ID_attrs,
			audio_part.ID AS ID_part,
			audio_part_attrs.ID AS ID_part_attrs,
			audio_part.ID_brick AS part_ID_brick,
			audio_brick.name AS brick_name,
			
			audio_ent.keywords,
			
			LEFT(audio.datetime_rec_start, 18) AS datetime_rec_start,
			LEFT(audio_attrs.datetime_create, 18) AS datetime_create,
			LEFT(audio.datetime_rec_start,10) AS date_recorded,
			LEFT(audio_ent.datetime_rec_stop, 18) AS datetime_rec_stop,
			
			audio_attrs.ID_category,
			audio_cat.name AS ID_category_name,
			
			audio_attrs.name,
			audio_attrs.name_url,
			
			audio_part_attrs.name AS part_name,
			audio_part_attrs.description AS part_description,
			audio_part.keywords AS part_keywords,
			audio_part.datetime_air AS part_datetime_air,
			
			audio_part_file.ID AS file_ID,
			audio_part_file.audio_bitrate,
			audio_part_file.length,
			audio_part_file.file_size,
			audio_part_file.file_ext,
			audio_part_file.file_alt_src,
			audio_part_file.name AS file_name,
			
			audio_format.ID AS format_ID,
			audio_format.name AS audio_format_name,
			
			CONCAT(audio_part_file.ID_format,'/',SUBSTR(audio_part_file.ID,1,4),'/',audio_part_file.name,'.',audio_part_file.file_ext) AS file_part_path
	};
	
	if ($env{'audio.ID_entity'})
	{
		$env{'audio_part.part_id'} = 1 unless $env{'audio_part.part_id'};
		$sql.=qq{
		FROM
			`$App::520::db_name`.`a520_audio` AS audio
		INNER JOIN `$App::520::db_name`.`a520_audio_ent` AS audio_ent ON
		(
			audio_ent.ID_entity = audio.ID_entity
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_attrs` AS audio_attrs ON
		(
			audio_attrs.ID_entity = audio.ID
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_part` AS audio_part ON
		(
			audio_part.ID_entity = audio.ID_entity
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_part_attrs` AS audio_part_attrs ON
		(
			audio_part_attrs.ID_entity = audio_part.ID AND
			audio_part_attrs.lng = audio_attrs.lng
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_part_file` AS audio_part_file ON
		(
			audio_part_file.ID_entity = audio_part.ID
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_cat` AS audio_cat ON
		(
			audio_cat.ID_entity = audio_attrs.ID_category
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_brick` AS audio_brick ON
		(
			audio_brick.ID = audio_part.ID_brick
		)
		INNER JOIN `$App::520::db_name`.`a520_audio_format` AS audio_format ON
		(
			audio_format.ID = audio_part_file.ID_format
		)
		WHERE
			audio.ID_entity=$env{'audio.ID_entity'} AND
			audio_part.part_id=$env{'audio_part.part_id'} AND
			audio_part_file.ID_format=$env{'audio_part_file.ID_format'} AND
			audio_attrs.lng='$env{'audio_attrs.lng'}'
		LIMIT 1
		};
	}
	else
	{
		# get ID_entity for cache
		my %sth0=TOM::Database::SQL::execute(qq{SELECT ID_entity FROM `$App::520::db_name`.`a520_audio` WHERE ID='$env{'audio.ID'}' LIMIT 1},'quiet'=>1,'-slave'=>1,'-cache'=>3600);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'audio.ID_entity'}=$db0_line{'ID_entity'};
		
		$sql.=qq{
		FROM
			`$App::520::db_name`.`a520_audio_part` AS audio_part
		LEFT JOIN `$App::520::db_name`.`a520_audio` AS audio ON
		(
			audio_part.ID_entity = audio.ID_entity
		)
		INNER JOIN `$App::520::db_name`.`a520_audio_ent` AS audio_ent ON
		(
			audio_ent.ID_entity = audio.ID_entity
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_attrs` AS audio_attrs ON
		(
			audio_attrs.ID_entity = audio.ID
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_part_attrs` AS audio_part_attrs ON
		(
			audio_part_attrs.ID_entity = audio_part.ID AND
			audio_part_attrs.lng = audio_attrs.lng
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_part_file` AS audio_part_file ON
		(
			audio_part_file.ID_entity = audio_part.ID
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_cat` AS audio_cat ON
		(
			audio_cat.ID_entity = audio_attrs.ID_category
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_brick` AS audio_brick ON
		(
			audio_brick.ID = audio_part.ID_brick
		)
		INNER JOIN `$App::520::db_name`.`a520_audio_format` AS audio_format ON
		(
			audio_format.ID = audio_part_file.ID_format
		)
		WHERE
			audio_part.ID=$env{'audio_part.ID'} AND
			audio_part_file.ID_format=$env{'audio_part_file.ID_format'} AND
			audio_attrs.lng='$env{'audio_attrs.lng'}'
		LIMIT 1
		};
	}
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1,
		'-cache' => 3600, #24H max
#		'-cache_min' => 600, # when changetime before this limit 10min
		'-cache_changetime' => App::020::SQL::functions::_get_changetime({
			'db_h'=>"main",'db_name'=>$App::520::db_name,'tb_name'=>"a520_audio",
			'ID_entity' => $env{'audio.ID_entity'}
		})
	);
	if ($sth0{'rows'})
	{
		my %audio=$sth0{'sth'}->fetchhash();
		my $brick_class='App::520::brick';
			$brick_class.="::".$audio{'brick_name'}
				if $audio{'brick_name'};
			my $audio_=$brick_class->audio_part_file_path({
				'audio_part.ID' => $audio{'ID_part'},
				'audio_part.datetime_air' => $audio{'part_datetime_air'},
				'audio.ID' => $audio{'ID_audio'},
				'audio_part_file.ID' => $audio{'file_ID'},
				'audio_format.ID' => $audio{'format_ID'},
				'audio_part_file.file_ext' => $audio{'file_ext'},
				'audio_part_file.file_alt_src' => $audio{'file_alt_src'},
				'audio_part_file.name' => $audio{'file_name'},
			});
			$audio{'dir'}=$audio_->{'dir'};
			$audio{'file_part_path'}=$audio_->{'file_path'};
		return %audio;
	}
	
	return 1;
}


sub get_audio_part_file_process_front
{
	my %env=@_;
	$env{'limit'}=10 unless $env{'limit'};
	
	my $sql_where;
	my @sql_bind;
	
	if ($env{'audio_part_file.ID_entity'})
	{
		$sql_where.=" AND audio_part.ID=?";
		push @sql_bind, $env{'audio_part_file.ID_entity'}
	}
	elsif ($env{'audio_part.ID'})
	{
		$sql_where.=" AND audio_part.ID=?";
		push @sql_bind, $env{'audio_part.ID'}
	}
	
	my @data;
	my $sql=qq{
		SELECT
			audio_part.ID_entity AS ID_entity_audio,
			audio_part.ID AS ID_part,
			audio_format.ID_entity AS ID_entity_format,
			audio_format.datetime_create AS format_datetime_create,
			audio_format_p.ID_entity AS ID_entity_format_p,
			audio_part_file.ID AS ID_file,
			audio_part_file.datetime_create AS file_datetime_create,
			audio_part_file.status AS file_status,
			audio_part_file_process.status AS process,
			audio_part.ID_brick,
			audio_brick.dontprocess AS brick_dontprocess
		FROM
			`$App::520::db_name`.a520_audio_part AS audio_part
		
		
		INNER JOIN `$App::520::db_name`.a520_audio AS audio ON
		(
			audio_part.ID_entity = audio.ID_entity
		)
		LEFT JOIN `$App::520::db_name`.a520_audio_attrs AS audio_attrs ON
		(
			audio_attrs.ID_entity = audio.ID
		)
		
		
		LEFT JOIN `$App::520::db_name`.a520_audio_format AS audio_format ON
		(
			audio_format.status IN ('Y','L')
--			AND audio_format.name NOT LIKE 'original'
		)
		LEFT JOIN `$App::520::db_name`.a520_audio_part_file AS audio_part_file ON
		(
			audio_part.ID = audio_part_file.ID_entity AND
			audio_part_file.ID_format = audio_format.ID_entity AND
			audio_part_file.status IN ('Y','N','E','W')
		)
		LEFT JOIN `$App::520::db_name`.a520_audio_part_file_process AS audio_part_file_process ON
		(
			audio_part_file_process.ID_part = audio_part.ID AND
			audio_part_file_process.ID_format = audio_format.ID_entity AND
			audio_part_file_process.datetime_start >= audio_format.datetime_create AND
			audio_part_file_process.datetime_start <= NOW() AND
			audio_part_file_process.status = 'W' AND
			audio_part_file_process.datetime_stop IS NULL
		)
		
		/* join parent format */
		LEFT JOIN `$App::520::db_name`.a520_audio_format AS audio_format_p ON
		(
			audio_format_p.status IN ('Y','L') AND
			audio_format_p.ID_charindex LIKE LEFT(audio_format.ID_charindex,LENGTH(audio_format.ID_charindex)-4)
		)
		LEFT JOIN `$App::520::db_name`.a520_audio_part_file AS audio_part_file_p ON
		(
			audio_part.ID = audio_part_file_p.ID_entity AND
			audio_part_file_p.ID_format = audio_format_p.ID_entity AND
			audio_part_file_p.status IN ('Y','E')
		)
		LEFT JOIN `$App::520::db_name`.a520_audio_part_file_process AS audio_part_file_process_p ON
		(
			audio_part_file_process_p.ID_part = audio_part.ID AND
			audio_part_file_process_p.ID_format = audio_format_p.ID_entity AND
			audio_part_file_process_p.datetime_start >= audio_format_p.datetime_create AND
			audio_part_file_process_p.datetime_start <= NOW() AND
			audio_part_file_process_p.status = 'W' AND
			audio_part_file_process_p.datetime_stop IS NULL
		)
		
		LEFT JOIN `$App::520::db_name`.a520_audio_brick AS audio_brick ON
		(
			audio_part.ID_brick = audio_brick.ID
		)
		
		WHERE
			/* only not trashed audio parts */
			audio_part.status IN ('Y') AND
			
			/* only not trashed audios */
			audio.status IN ('Y') AND
			
			/* only not trashed audio_attrs */
			audio_attrs.status IN ('Y','N') AND
			
			/* skip audios locked */
			audio_part.process_lock = 'N' AND
			
			/* skip audio bricks locked */
			(audio_part.ID_brick IS NULL OR audio_brick.dontprocess != 'Y') AND
			
			/* skip audios in processing */
			audio_part_file_process.ID IS NULL AND
			/* skip audios where depending format is in processing */
			audio_part_file_process_p.ID IS NULL
			
			/* parent audio file must exists or we are processing 'original' */
			AND
			(
				audio_format.name LIKE 'original'
				OR
				(
					audio_part_file_p.ID
					AND audio_part_file_p.status='Y'
				)
			)
			
			/* cases when audio_part_file must be re-encoded */
			AND
			(
				(
					/* audio_part_file is missing, but required */
					audio_format.name != 'original' AND
					audio_part_file.ID IS NULL AND
					audio_format.required='Y' AND
					(
						audio_format.required_min_bitrate IS NULL
						OR (audio_format.required_min_bitrate <= audio_part_file_p.audio_bitrate)
					)
				)
				OR
				(
					/* can be in error state, but the error state is older than new audio format definition */
					audio_format.name != 'original' AND
					audio_part_file.ID IS NOT NULL AND
					audio_format.datetime_create > audio_part_file.datetime_create
				)
				OR
				(
					/* or parent file has been changed */
					audio_format.name != 'original' AND
					audio_part_file.ID IS NOT NULL AND
					audio_part_file.datetime_create < audio_part_file_p.datetime_create
				)
				OR
				(
					/* or regeneration is required */
--					audio_format.name != 'original' AND
					audio_part_file.regen = 'Y'
				)
				OR
				(
					/* or regeneration is awaiting */
--					audio_format.name != 'original' AND
					audio_part_file.status = 'W'
				)
				OR
				(
					/* or original file must be re-encoded, because is new */
					audio_format.name = 'original'
					AND audio_format.process IS NOT NULL
					AND audio_format.process != ''
					AND audio_part_file.from_parent = 'N'
				)
			)
			$sql_where
		GROUP BY
			audio_part.ID, audio_format.ID
	};
	my $i;
	if ($env{'count'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT COUNT(*) AS cnt FROM ($sql) AS t2
		},'bind'=>[@sql_bind]);
		my %db0_line=$sth0{'sth'}->fetchhash();
		return $db0_line{'cnt'};
	}
	my %sth0=TOM::Database::SQL::execute($sql.qq{
		ORDER BY
			audio_format.ID_charindex ASC, audio.datetime_create DESC
		LIMIT $env{'limit'}
	},'bind'=>[@sql_bind]);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$i++;
		main::_log("[$i/$sth0{'rows'}] brick='$db0_line{'ID_brick'}/$db0_line{'brick_dontprocess'}' audio.ID_entity=$db0_line{'ID_entity_audio'} audio_part.ID=$db0_line{'ID_part'} audio_format.ID_entity='$db0_line{'ID_entity_format'}' audio_format.datetime_create='$db0_line{'format_datetime_create'}' audio_part_file.ID=$db0_line{'ID_file'} audio_part_file.datetime_create='$db0_line{'file_datetime_create'}' audio_part_file.status='$db0_line{'file_status'}' audio_format_p.ID_entity='$db0_line{'ID_entity_format_p'}'");
		push @data,{%db0_line};
	}
	
	return @data;
}



sub audio_part_brick_change
{
	my %env=@_;
	return undef unless $env{'audio_part.ID'};
	return undef unless defined $env{'audio_part.ID_brick'};
	my $t=track TOM::Debug(__PACKAGE__."::audio_part_brick_change($env{'audio_part.ID'},$env{'audio_part.ID_brick'})");
	
	my %part=App::020::SQL::functions::get_ID(
		'ID' => $env{'audio_part.ID'},
		'db_h' => "main",
		'db_name' => $App::520::db_name,
		'tb_name' => "a520_audio_part",
		'columns' => {'*'=>1}
	);
	
	if (!$part{'ID'})
	{
		main::_log("brick not found",1);
		$t->close();
		return undef;
	}
	
	if ($part{'ID_brick'} eq $env{'audio_part.ID_brick'})
	{
		main::_log("already changed ID_brick to '$part{'ID_brick'}'");
		$t->close();
		return 1;
	}
	
	my $sql=qq{
		SELECT
			audio.ID_entity AS ID_entity_audio,
			audio.ID AS ID_audio,
			audio_attrs.ID AS ID_attrs,
			audio_part.ID AS ID_part,
			audio_part_attrs.ID AS ID_part_attrs,
			
			LEFT(audio.datetime_rec_start, 16) AS datetime_rec_start,
			LEFT(audio_attrs.datetime_create, 18) AS datetime_create,
			LEFT(audio.datetime_rec_start,10) AS date_recorded,
			LEFT(audio.datetime_rec_stop, 16) AS datetime_rec_stop,
			
			audio_attrs.ID_category,
			
			audio_attrs.name,
			audio_attrs.name_url,
			audio_attrs.description,
			audio_attrs.order_id,
			audio_attrs.priority_A,
			audio_attrs.priority_B,
			audio_attrs.priority_C,
			audio_attrs.lng,
			
			audio_part_attrs.name AS part_name,
			audio_part_attrs.description AS part_description,
			audio_part.part_id AS part_id,
			audio_part.keywords AS part_keywords,
			audio_part.visits,
			audio_part_attrs.lng AS part_lng,
			
			audio_part.rating_score,
			audio_part.rating_votes,
			(audio_part.rating_score/audio_part.rating_votes) AS rating,
			
			audio_attrs.status,
			audio_part.status AS status_part
			
		FROM
			`$App::520::db_name`.`a520_audio` AS audio
		INNER JOIN `$App::520::db_name`.`a520_audio_ent` AS audio_ent ON
		(
			audio_ent.ID_entity = audio.ID_entity
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_attrs` AS audio_attrs ON
		(
			audio_attrs.ID_entity = audio.ID
		)
		INNER JOIN `$App::520::db_name`.`a520_audio_part` AS audio_part ON
		(
			audio_part.ID_entity = audio.ID_entity
		)
		LEFT JOIN `$App::520::db_name`.`a520_audio_part_attrs` AS audio_part_attrs ON
		(
			audio_part_attrs.ID_entity = audio_part.ID AND
			audio_part_attrs.lng = audio_attrs.lng
		)
		
		WHERE
			audio.ID AND
			audio_attrs.ID AND
			audio_part.ID=?
		
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$part{'ID'}],'quiet'=>1);
	my %audio_db=$sth0{'sth'}->fetchhash();
	
	my %brick_src;
	%brick_src=App::020::SQL::functions::get_ID(
		'ID' => $part{'ID_brick'},
		'db_h' => "main",
		'db_name' => $App::520::db_name,
		'tb_name' => "a520_audio_brick",
		'columns' => {'*'=>1}
	) if $part{'ID_brick'};
	
	my $brick_src_class='App::520::brick';
		$brick_src_class.="::".$brick_src{'name'}
			if $brick_src{'name'};
	
	main::_log("source brick class = '$brick_src_class'");
	
	my %brick_dst=App::020::SQL::functions::get_ID(
		'ID' => $env{'audio_part.ID_brick'},
		'db_h' => "main",
		'db_name' => $App::520::db_name,
		'tb_name' => "a520_audio_brick",
		'columns' => {'*'=>1}
	);
	
	my $brick_dst_class='App::520::brick';
		$brick_dst_class.="::".$brick_dst{'name'}
			if $brick_dst{'name'};
	
	main::_log("destination brick class = '$brick_dst_class'");
	
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::520::db_name`.a520_audio_part_file
		WHERE
			ID_entity=?
			AND status IN ('Y','N','L','W')
		ORDER BY
			ID_format
	},'bind'=>[$env{'audio_part.ID'}],'quiet'=>1);
	my @files_move;
	while (my %db1_line=$sth1{'sth'}->fetchhash())
	{
		main::_log("audio_part_file.ID=$db1_line{'ID'} format.ID=$db1_line{'ID_format'} name=$db1_line{'name'}");
		
		my $audio_=$brick_src_class->audio_part_file_path({
			'audio_part.ID' => $part{'ID'},
			'audio_format.ID' => $db1_line{'ID_format'},
			'audio_part_file.ID' => $db1_line{'ID'},
			'audio_part_file.file_alt_src' => $db1_line{'file_alt_src'},
			'audio_part_file.name' => $db1_line{'name'},
			'audio_part_file.file_ext' => $db1_line{'file_ext'},
			'audio_part.datetime_air' => $part{'datetime_air'},
		});
		my $src_dir=$audio_->{'dir'};
		my $src_file_path=$audio_->{'file_path'};
		
		
		my $audio_=$brick_dst_class->audio_part_file_path({
			'audio_part.ID' => $part{'ID'},
			'audio_format.ID' => $db1_line{'ID_format'},
			'audio_part_file.ID' => $db1_line{'ID'},
#			'audio_part_file.name' => $db1_line{'name'},
			'audio_part_file.file_ext' => $db1_line{'file_ext'},
			'audio_part.datetime_air' => $part{'datetime_air'},
			
			'audio.datetime_rec_start' => $audio_db{'datetime_rec_start'},
			'audio_attrs.name' => ($audio_db{'name'} || $audio_db{'ID_audio'}),
			'audio_part_attrs.name' => $audio_db{'part_name'}
		});
		my $dst_dir=$audio_->{'dir'};
		my $dst_file_path=$audio_->{'file_path'};
		
		main::_log(" file src '$src_dir/$src_file_path'");
		main::_log(" file dst '$dst_dir/$dst_file_path'");
		
		if ($src_dir=~/skvid/)
		{
			next;
		}
		elsif ($src_dir.'/'.$src_file_path eq $dst_dir.'/'.$dst_file_path)
		{
			main::_log("src file same as destination",1);
			next;
		}
		elsif (-e $src_dir && !-e $src_dir.'/'.$src_file_path)
		{
			main::_log("src file can't be found, dir exits",1);
#			App::020::SQL::functions::update(
#				'ID' => $db1_line{'ID'},
#				'db_h' => "main",
#				'db_name' => $App::520::db_name,
#				'tb_name' => "a520_audio_part",
#				'data' =>
#				{
#					'status' => "'E'"
#				},
#				'-journalize' => 1
#			);
			$t->close();
			return undef;
		}
		elsif (!-e $src_dir.'/'.$src_file_path)
		{
			main::_log("src file can't be found",1);
			$t->close();
			return undef;
		}
		push @files_move,[
			$src_dir.'/'.$src_file_path,
			$dst_dir.'/'.$dst_file_path,
			$db1_line{'ID'}, # ID
			$audio_->{'audio_part_file.name'}
		];
	}
	
	# copy files
	use File::Copy;
	my $i=0;
	foreach (@files_move)
	{
		$i++;
		my $src_file=$_->[0];
		my $dst_file=$_->[1];
		
		if ($brick_dst_class->can('upload'))
		{
			main::_log(" upload file [$i] size=".format_bytes((stat $src_file)[7]));
			$brick_dst_class->upload(
				$src_file,
				$dst_file
			) || do {
				main::_log("$!",1);
				$t->close();
				return undef;
			};
		}
		else
		{
			main::_log(" copy file [$i] size=".format_bytes((stat $src_file)[7]));
			copy($src_file,$dst_file) || do {
				main::_log("$!",1);
				$t->close();
				return undef;
			};
		}
	}
	
	# rename files in db to new names
	my $i=0;
	foreach (@files_move)
	{
		$i++;
		my $id=$_->[2];
		my $name=$_->[3];
		main::_log(" rename file in db [$i] to '$name'");
		my %sth0=TOM::Database::SQL::execute(qq{
			UPDATE
				`$App::520::db_name`.a520_audio_part_file
			SET
				name=?,
				file_alt_src=NULL
			WHERE
				ID=?
			LIMIT 1
		},'bind'=>[$name,$id],'quiet'=>1);
		# noooo, don't change datetime_create
#		App::020::SQL::functions::update(
#			'ID' => $id,
#			'db_h' => 'main',
#			'db_name' => $App::520::db_name,
#			'tb_name' => 'a520_audio_part_file',
#			'data' =>
#			{
#				'name' => $name
#			},
#			'columns' => 
#			{
#				'file_alt_src' => 'NULL'
#			},
#			'-journalize' => 1,
#		);
	}
	
	# update audio_part.ID_brick
	App::020::SQL::functions::update(
		'ID' => $part{'ID'},
		'db_h' => "main",
		'db_name' => $App::520::db_name,
		'tb_name' => "a520_audio_part",
		'columns' =>
		{
			'ID_brick' => $env{'audio_part.ID_brick'}
		},
		'-journalize' => 1
	);
	
	# remove old files
	# TODO: delay this for couple of hours
	my $i=0;
	foreach (@files_move)
	{
		$i++;
		my $src_file=$_->[0];
		my $dst_file=$_->[1];
		main::_log(" unlink file [$i]");
		unlink($src_file) || do {
			main::_log("$!",1);
			# sorry, can't stop this process now
		}
	}
	
	$t->close();
	return 1;
}




sub broadcast_program_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::broadcast_program_add()");
	
	my %program;
	if ($env{'program.ID'})
	{
		%program=App::020::SQL::functions::get_ID(
			'ID' => $env{'program.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_broadcast_program",
			'columns' => {'*'=>1}
		);
	}
	elsif ($env{'program.ID_entity'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.`a520_broadcast_program`
			WHERE
				ID_entity=?
			LIMIT 1
		},'-bind'=>[$env{'program.ID_entity'}],'quiet'=>1);
		if (%program=$sth0{'sth'}->fetchhash())
		{
			$env{'program.ID'}=$program{'ID'};
				$env{'program.ID_entity'}=$program{'ID_entity'};
		}
	}
	elsif ($env{'program.program_code'})
	{
		if ($env{'program.datetime_air_start'})
		{
			if ($env{'program.ID_channel'})
			{
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						*
					FROM
						`$App::520::db_name`.a520_broadcast_program
					WHERE
						program_code=?
						AND ID_channel=?
						AND ABS(TIME_TO_SEC(TIMEDIFF(?,datetime_air_start))) <= 7200
					ORDER BY
						ABS(TIME_TO_SEC(TIMEDIFF(?,datetime_air_start))) ASC
					LIMIT 1
				},'bind'=>[
					$env{'program.program_code'},
					$env{'program.ID_channel'},
					$env{'program.datetime_air_start'},
					$env{'program.datetime_air_start'}
				],'quiet'=>1);
				if (%program=$sth0{'sth'}->fetchhash())
				{
					$env{'program.ID'}=$program{'ID'};
					$env{'program.ID_entity'}=$program{'ID_entity'};
				}
			}
			else
			{
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						*
					FROM
						`$App::520::db_name`.a520_broadcast_program
					WHERE
						program_code=?
						AND ABS(TIME_TO_SEC(TIMEDIFF(?,datetime_air_start))) <= 7200
	--					AND status IN ('Y','N','L','W')
					ORDER BY
						ABS(TIME_TO_SEC(TIMEDIFF(?,datetime_air_start))) ASC
					LIMIT 1
				},'bind'=>[
					$env{'program.program_code'},
					$env{'program.datetime_air_start'},
					$env{'program.datetime_air_start'}
				],'quiet'=>1);
				if (%program=$sth0{'sth'}->fetchhash())
				{
					$env{'program.ID'}=$program{'ID'};
					$env{'program.ID_entity'}=$program{'ID_entity'};
				}
			}
		}
		else
		{
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					*
				FROM
					`$App::520::db_name`.a520_broadcast_program
				WHERE
					program_code=?
--					AND status IN ('Y','N','L','W')
				LIMIT 1
			},'bind'=>[$env{'program.program_code'}],'quiet'=>1);
			if (%program=$sth0{'sth'}->fetchhash())
			{
				$env{'program.ID'}=$program{'ID'};
				$env{'program.ID_entity'}=$program{'ID_entity'};
			}
		}
	}
	# preco tu mam toto, ale v a520 nie?
	elsif ($env{'program.ID_channel'} && $env{'program.datetime_air_start'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.a520_broadcast_program
			WHERE
				ID_channel=?
				AND datetime_air_start=?
			LIMIT 1
		},'bind'=>[
			$env{'program.ID_channel'},
			$env{'program.datetime_air_start'}
		],'quiet'=>1);
		if (%program=$sth0{'sth'}->fetchhash())
		{
			$env{'program.ID'}=$program{'ID'};
			$env{'program.ID_entity'}=$program{'ID_entity'};
			main::_log("found program.ID=$env{'program.ID'}");
		}
	}
	
	if (!$env{'program.ID'})
	{
		main::_log("new program.ID");
		
		$env{'program.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_broadcast_program",
			'data' =>
			{
				'ID_entity' => $env{'program.ID_entity'},
				'ID_channel' => $env{'program.ID_channel'},
				'name' => $env{'program.name'},
				'status' => $env{'program.status'} || 'N',
			},
			'columns' => 
			{
				'datetime_air_start' => 'NOW()',
				'datetime_air_stop' => 'DATE_ADD(NOW(), INTERVAL 3600 SECOND)'
			},
			'-posix' => 1,
			'-journalize' => 1,
		);
		# reload
		%program=App::020::SQL::functions::get_ID(
			'ID' => $env{'program.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_broadcast_program",
			'columns' => {'*'=>1}
		);
		$env{'program.ID'}=$program{'ID'};
		$env{'program.ID_entity'}=$program{'ID_entity'};
	}
	
	# update if necessary
	if ($env{'program.ID'})
	{
		my %columns;
		my %data;
		
		$data{'ID_channel'}=$env{'program.ID_channel'}
			if ($env{'program.ID_channel'} && ($env{'program.ID_channel'} ne $program{'ID_channel'}));
		$data{'name'}=$env{'program.name'}
			if (exists $env{'program.name'} && ($env{'program.name'} ne $program{'name'}));
		$env{'program.name_url'}=TOM::Net::URI::rewrite::convert($env{'program.name'})
			if $env{'program.name'};
		$data{'name_url'}=$env{'program.name_url'}
			if (exists $env{'program.name_url'} && ($env{'program.name_url'} ne $program{'name_url'}));
		
		foreach (
			'ID_series',
			'ID_audio',
			'ID_channel',
			'name_original',
			'subtitle',
			'synopsis',
			'description',
			'program_code',
			'program_type_code',
			'authoring_country',
			'authoring_year',
			'authoring_cast',
			'authoring_authors',
			'series_ID',
			'series_type',
			'series_code',
			'series_episode',
			'series_episodes',
			'audio_mode',
			'audio_dubbing',
			'rating_pg',
			'accessibility_deaf',
			'accessibility_cc',
			'status_archive',
			'status_live',
			'status_live_geoblock',
			'status_premiere',
			'status_internet',
			'status_geoblock',
			'recording',
			'datetime_real_start',
			'datetime_real_start_msec',
			'datetime_real_stop',
			'datetime_real_stop_msec',
			'datetime_real_status',
			'license_valid_to',
			'metadata'
		)
		{
			if (exists $env{'program.'.$_} && ($env{'program.'.$_} ne $program{$_}))
			{
				main::_log("$_: '$program{$_}'<>'".$env{'program.'.$_}."'");
				if ($env{'program.'.$_} || $env{'program.'.$_} eq "0")
				{
					$data{$_}=$env{'program.'.$_};
				}
				else
				{
					$columns{$_}='NULL';
				}
			}
		}
		
		$data{'datetime_air_start'}=$env{'program.datetime_air_start'}
			if ($env{'program.datetime_air_start'} && ($env{'program.datetime_air_start'} ne $program{'datetime_air_start'}));
		
		main::_log("dur='$env{'program.datetime_air_duration'}' start='$env{'program.datetime_air_start'}'")
			if $env{'program.datetime_air_duration'};
		
		if ($env{'program.datetime_air_duration'} && $env{'program.datetime_air_start'}=~/^(\d\d\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d):(\d\d)/)
		{
			use DateTime;
			my $dt=DateTime->new(
				'year' => $1,
				'month' => $2,
				'day' => $3,
				'hour' => $4,
				'minute' => $5,
				'second' => $6
			);
			$dt->add('seconds' => $env{'program.datetime_air_duration'});
			$env{'program.datetime_air_stop'} = $dt->strftime("%F %T");
			main::_log_stdout(" $env{'program.datetime_air_start'}/$env{'program.datetime_air_duration'} air_stop=$env{'program.datetime_air_stop'}");
		}
		$data{'datetime_air_stop'}=$env{'program.datetime_air_stop'}
			if ($env{'program.datetime_air_stop'} && ($env{'program.datetime_air_stop'} ne $program{'datetime_air_stop'}));
		
		$data{'datetime_depth'}=$env{'program.datetime_depth'}
			if (defined $env{'program.datetime_depth'} && ($env{'program.datetime_depth'} ne $program{'datetime_depth'}));
		
		$data{'status'}=$env{'program.status'}
			if ($env{'program.status'} && ($env{'program.status'} ne $program{'status'}));
			
		if (keys %columns || keys %data)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'program.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_broadcast_program",
				'columns' => {%columns},
				'data' => {%data},
				'-posix' => 1,
				'-journalize' => 1
			);
			# reload
			%program=App::020::SQL::functions::get_ID(
				'ID' => $env{'program.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_broadcast_program",
				'columns' => {'*'=>1}
			);
			_broadcast_program_index('ID_entity' => $env{'program.ID_entity'});
		}
	}
	
	if (
		$program{'ID'} &&
		$program{'ID_channel'} &&
		$program{'program_code'} &&
		$program{'datetime_air_start'} &&
		$program{'status'}=~/^[YNLW]$/
	)
	{
		my $threshold='5 MINUTE';
		
		# najst konflikty a trashovat
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.a520_broadcast_program
			WHERE
				ID != ?
				AND ID_channel=?
				AND (datetime_air_start >= DATE_ADD(?,INTERVAL $threshold) AND datetime_air_start < DATE_SUB(?,INTERVAL $threshold))
				AND status IN ('Y','N','L','W')
				AND datetime_depth = ?
		},'bind'=>[
			$program{'ID'},
			$program{'ID_channel'},
			$program{'datetime_air_start'},
			$program{'datetime_air_start'},
			$program{'datetime_depth'}
		],'quiet'=>1);
		while (my %program0=$sth0{'sth'}->fetchhash())
		{
			main::_log("conflict start with $program0{'ID'}",1);
			App::020::SQL::functions::update(
				'ID' => $program0{'ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_broadcast_program",
				'columns' => {'status'=>'"T"'},
				'-journalize' => 1
			);
			_broadcast_program_index('ID_entity' => $program0{'ID_entity'});
		}
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.a520_broadcast_program
			WHERE
				ID != ?
				AND ID_channel=?
				AND datetime_air_start < DATE_SUB(?,INTERVAL $threshold)
				AND datetime_air_stop >= DATE_ADD(?,INTERVAL $threshold)
				AND status IN ('Y','N','L','W')
				AND datetime_depth = ?
		},'bind'=>[
			$program{'ID'},
			$program{'ID_channel'},
			$program{'datetime_air_stop'},
			$program{'datetime_air_stop'},
			$program{'datetime_depth'}
		],'quiet'=>1);
		while (my %program0=$sth0{'sth'}->fetchhash())
		{
			main::_log("conflict stop with $program0{'ID'}",1);
			App::020::SQL::functions::update(
				'ID' => $program0{'ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_broadcast_program",
				'columns' => {'status'=>'"T"'},
				'-journalize' => 1
			);
			_broadcast_program_index('ID_entity' => $program0{'ID_entity'});
		}
		
	}
	
	$t->close();
	foreach (%program){$env{'program.'.$_}=$program{$_}};
	return %env;
}


sub broadcast_series_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::broadcast_series_add()");
	
	my %series;
	if ($env{'series.ID'})
	{
		%series=App::020::SQL::functions::get_ID(
			'ID' => $env{'series.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_broadcast_series",
			'columns' => {'*'=>1}
		);
	}
	elsif ($env{'series.ID_entity'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::520::db_name`.`a520_broadcast_series`
			WHERE
				ID_entity=?
			LIMIT 1
		},'-bind'=>[$env{'series.ID_entity'}],'quiet'=>1);
		if (%series=$sth0{'sth'}->fetchhash())
		{
			$env{'series.ID'}=$series{'ID'};
				$env{'series.ID_entity'}=$series{'ID_entity'};
		}
	}
	
	if (!$env{'series.ID'})
	{
		main::_log("new series.ID");
		
		$env{'series.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_broadcast_series",
			'data' =>
			{
				'ID_entity' => $env{'series.ID_entity'},
				'ID_channel' => $env{'series.ID_channel'},
#				'name' => $env{'program.name'},
#				'status' => $env{'program.status'},
			},
#			'columns' => 
#			{
#				'datetime_air_start' => 'NOW()',
#				'datetime_air_stop' => 'DATE_ADD(NOW(), INTERVAL 3600 SECOND)'
#			},
			'-posix' => 1,
			'-journalize' => 1,
		);
		# reload
		%series=App::020::SQL::functions::get_ID(
			'ID' => $env{'series.ID'},
			'db_h' => "main",
			'db_name' => $App::520::db_name,
			'tb_name' => "a520_broadcast_series",
			'columns' => {'*'=>1}
		);
		$env{'series.ID'}=$series{'ID'};
		$env{'series.ID_entity'}=$series{'ID_entity'};
	}
	
	# update if necessary
	if ($env{'series.ID'})
	{
		my %columns;
		my %data;
		
#		$data{'ID_channel'}=$env{'program.ID_channel'}
#			if ($env{'program.ID_channel'} && ($env{'program.ID_channel'} ne $program{'ID_channel'}));
		$data{'name'}=$env{'series.name'}
			if (exists $env{'series.name'} && ($env{'series.name'} ne $series{'name'}));
		$env{'series.name_url'}=TOM::Net::URI::rewrite::convert($env{'series.name'})
			if $env{'series.name'};
		$data{'name_url'}=$env{'series.name_url'}
			if (exists $env{'series.name_url'} && ($env{'series.name_url'} ne $series{'name_url'}));
		
		$data{'body'}=$env{'series.body'}
			if (exists $env{'series.body'} && ($env{'series.body'} ne $series{'body'}));
		
		# with NULL
		foreach (
			'name_original',
			'program_code',
			'program_type_code',
			'synopsis',
			'ID_channel',
			'parent_ID',
			'series_ID',
			'series_type',
			'series_code',
			'series_episodes',
			'authoring_country',
			'authoring_year',
			'authoring_cast',
			'authoring_authors'
		)
		{
			if (exists $env{'series.'.$_} && ($env{'series.'.$_} ne $series{$_}))
			{
				main::_log("$_: '$series{$_}'<>'".$env{'series.'.$_}."'");
				if ($env{'series.'.$_} || $env{'series.'.$_} eq "0")
				{
					$data{$_}=$env{'series.'.$_};
				}
				else
				{
					$columns{$_}='NULL';
				}
			}
		}
		
		$data{'status'}=$env{'series.status'}
			if ($env{'series.status'} && ($env{'series.status'} ne $series{'status'}));
			
		if (keys %columns || keys %data)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'series.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_broadcast_series",
				'columns' => {%columns},
				'data' => {%data},
				'-posix' => 1,
				'-journalize' => 1
			);
			# reload
			%series=App::020::SQL::functions::get_ID(
				'ID' => $env{'series.ID'},
				'db_h' => "main",
				'db_name' => $App::520::db_name,
				'tb_name' => "a520_broadcast_series",
				'columns' => {'*'=>1}
			);
			_broadcast_series_index('ID_entity' => $env{'series.ID_entity'});
		}
	}
	
	$t->close();
	foreach (%series){$env{'series.'.$_}=$series{$_}};
	return %env;
}


sub _audio_index
{
}

sub _broadcast_program_index
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::520::db_name,'class'=>'indexer'}); # do it in background
	
	my %env=@_;
	return undef unless $env{'ID_entity'};
	
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my $t=track TOM::Debug(__PACKAGE__."::_broadcast_program_index::elastic(".$env{'ID_entity'}.")",'timer'=>1);
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				a520_broadcast_program.*
			FROM `$App::520::db_name`.a520_broadcast_program
			WHERE
				a520_broadcast_program.ID_entity = ? AND
				a520_broadcast_program.status IN ('Y','L')
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		if (!$sth0{'rows'})
		{
			main::_log("broadcast_program.ID_entity=$env{'ID_entity'} not found, removing from index",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::520::db_name,
				'type' => 'a520_broadast_program',
				'id' => $env{'ID_entity'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::520::db_name,
					'type' => 'a520_broadast_program',
					'id' => $env{'ID_entity'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %program=$sth0{'sth'}->fetchhash();
		delete $program{'datetime_depth'};
		foreach (keys %program){delete $program{$_} unless $program{$_};}
		$Elastic->index(
			'index' => 'cyclone3.'.$App::520::db_name,
			'type' => 'a520_broadcast_program',
			'id' => $env{'ID_entity'},
			'body' => {
				%program
			}
		);
		
		$t->close();
#		return 1;
	}
	
	return 1 unless $Ext::Solr;
	
	
	
	return 1;
}


sub _broadcast_series_index
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::520::db_name,'class'=>'indexer'}); # do it in background
	
	my %env=@_;
	return undef unless $env{'ID_entity'};
	
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my $t=track TOM::Debug(__PACKAGE__."::_broadcast_series_index::elastic(".$env{'ID_entity'}.")",'timer'=>1);
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				a520_broadcast_series.*
			FROM `$App::520::db_name`.a520_broadcast_series
			WHERE
				a520_broadcast_series.ID_entity = ? AND
				a520_broadcast_series.status IN ('Y','L')
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		if (!$sth0{'rows'})
		{
			main::_log("broadcast_series.ID_entity=$env{'ID_entity'} not found, removing from index",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::520::db_name,
				'type' => 'a520_broadcast_series',
				'id' => $env{'ID_entity'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::520::db_name,
					'type' => 'a520_broadcast_series',
					'id' => $env{'ID_entity'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %series=$sth0{'sth'}->fetchhash();
		foreach (keys %series){delete $series{$_} unless $series{$_};}
		$Elastic->index(
			'index' => 'cyclone3.'.$App::520::db_name,
			'type' => 'a520_broadcast_series',
			'id' => $env{'ID_entity'},
			'body' => {
				%series
			}
		);
		
		$t->close();
		return 1;
	}
	
	return undef unless $Ext::Solr;
	
	
	
	return 1;
}


1;
