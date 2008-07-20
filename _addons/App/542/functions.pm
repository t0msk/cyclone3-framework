#!/bin/perl
package App::542::functions;

=head1 NAME

App::542::functions

=head1 DESCRIPTION

Functions to handle basic actions with files.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::542::_init|app/"542/_init.pm">

=item *

L<App::160::_init|app/"160/_init.pm">

=item *

L<App::542::mimetypes|app/"542/mimetypes.pm">

=item *

File::Path

=item *

Digest::MD5

=item *

Digest::SHA1

=item *

File::Type

=item *

Movie::Info

=back

=cut

use App::542::_init;
use App::160::_init;
use App::542::mimetypes;
use File::Path;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Type;



=head1 FUNCTIONS

=head2 file_add()

Adds new file to storage, or updates old file

 %file=file_add
 (
   'file' => '/path/to/file',
 # 'file.ID' => '',
 # 'file.ID_entity' => '',
 
 #  'file_attrs.ID_category' => '',
 #  'file_attrs.name' => '',
 #  'file_attrs.description' => '',
 
 #  'file_item.ID' => '',
 #  'file_item.lng' => '',
 
 );

=cut

sub file_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::file_add()");
	my $tr=new TOM::Database::SQL::transaction('db_h'=>"main");
	
	# detect name of file
	if ($env{'file'} && -e $env{'file'})
	{
		if (!$env{'filename'})
		{
			$env{'filename'}=$env{'file'};
			$env{'filename'}=~s|^.*/||;
			main::_log("detect filename='$env{'filename'}'");
		}
	}
	if ($env{'filename'} && !$env{'file_attrs.name'})
	{
		my $ext=$env{'filename'};
		$ext=~s|^.*\.||;
		$env{'file_attrs.name'}=$env{'filename'};
		$env{'file_attrs.name'}=~s|\.$ext$||;
		main::_log("file_attrs.name='$env{'file_attrs.name'}'");
	}
	if ($env{'filename'} && !$env{'file_attrs.name_ext'})
	{
		$env{'file_attrs.name_ext'}=$env{'filename'};
		if ($env{'file_attrs.name_ext'}=~s|^.*\.||)
		{
		}
		else
		{
			# ext not defined
			$env{'file_attrs.name_ext'}='';
		}
		main::_log("file_attrs.name_ext='$env{'file_attrs.name_ext'}'");
	}
	
	my %category;
	if ($env{'file_attrs.ID_category'})
	{
		# detect language
		%category=App::020::SQL::functions::get_ID(
			'ID' => $env{'file_attrs.ID_category'},
			'db_h' => "main",
			'db_name' => $App::542::db_name,
			'tb_name' => "a542_file_dir",
			'columns' => {'*'=>1}
		);
		$env{'file_attrs.lng'}=$category{'lng'};
		main::_log("setting lng='$env{'file_attrs.lng'}' from file_attrs.ID_category");
	}
	
	$env{'file_attrs.lng'}=$tom::lng unless $env{'file_attrs.lng'};
	main::_log("lng='$env{'file_attrs.lng'}'");
	
	
	# FILE
	
	my %file;
	my %file_attrs;
	if ($env{'file.ID'})
	{
		# detect language
		%file=App::020::SQL::functions::get_ID(
			'ID' => $env{'file.ID'},
			'db_h' => "main",
			'db_name' => $App::542::db_name,
			'tb_name' => "a542_file",
			'columns' => {'*'=>1}
		);
		$env{'file.ID_entity'}=$file{'ID_entity'} unless $env{'file.ID_entity'};
	}
	
	
	# check if this symlink with same ID_category not exists
	# and file.ID is unknown
	if ($env{'file_attrs.ID_category'} && !$env{'file.ID'} && $env{'file.ID_entity'} && !$env{'forcesymlink'})
	{
		main::_log("\$env{'file_attrs.ID_category'} && !\$env{'file.ID'} && \$env{'file.ID_entity'} -> search for file.ID");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::542::db_name`.`a542_file_view`
			WHERE
				ID_entity_file=$env{'file.ID_entity'} AND
				( ID_category = $env{'file_attrs.ID_category'} OR ID_category IS NULL ) AND
				status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID'})
		{
			$env{'file.ID'}=$db0_line{'ID_file'};
			$env{'file_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup file.ID='$db0_line{'ID_file'}'");
		}
	}
	
	if (!$file{'ID'} && $env{'file.ID_entity'})
	{
		# check if this file exists
		# - not necessary :)
	}
	
	main::_log("status file.ID='$env{'file.ID'}' file.ID_entity='$env{'file.ID_entity'}'");
	
	
	if (!$env{'file.ID'})
	{
		# generating new file!
		main::_log("adding new file");
		
		my %columns;
		
		$columns{'ID_entity'}=$env{'file.ID_entity'} if $env{'file.ID_entity'};
		
		$env{'file.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::542::db_name,
			'tb_name' => "a542_file",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		main::_log("generated file.ID='$env{'file.ID'}'");
	}
	
	
	if (!$env{'file.ID_entity'})
	{
		if ($file{'ID_entity'})
		{
			$env{'file.ID_entity'}=$file{'ID_entity'};
		}
		elsif ($env{'file.ID'})
		{
			%file=App::020::SQL::functions::get_ID(
				'ID' => $env{'file.ID'},
				'db_h' => "main",
				'db_name' => $App::542::db_name,
				'tb_name' => "a542_file",
				'columns' => {'*'=>1}
			);
			$env{'file.ID_entity'}=$file{'ID_entity'};
		}
		else
		{
			die "ufff\n";
		}
	}
	
	
	
	# FILE ITEM
	
	# tu pridat file item
	if ($env{'file'} && -e $env{'file'})
	{
		# create new secure hash
		my $hash_secure=TOM::Utils::vars::genhash(32);
		
		# file must be analyzed
		
		# size
		my $file_size=(stat($env{'file'}))[7];
		main::_log("file size='$file_size'");
		
		# checksum
		open(CHKSUM,'<'.$env{'file'});
		my $ctx = Digest::SHA1->new;
		$ctx->addfile(*CHKSUM);
		my $checksum = $ctx->hexdigest;
		my $checksum_method = 'SHA1';
		main::_log("file checksum $checksum_method:$checksum");
		
		my $out=`file -b $env{'file'}`;chomp($out);
		main::_log("file -b = '$out'");
#		my $file_ext=$env{'file_attrs.name_ext'};#
		
		# find if this file type exists
		foreach my $reg (@App::542::mimetypes::filetype_ext)
		{
			next if $env{'file_attrs.name_ext'};
			if ($out=~/$reg->[0]/){$env{'file_attrs.name_ext'}=$reg->[1];last;}
		}
		$env{'file_attrs.name_ext'}='bin' unless $env{'file_attrs.name_ext'};
		
		my $mimetype=$App::542::mimetypes::ext{$env{'file_attrs.name_ext'}};
		
		main::_log("type='$out' ext='$env{'file_attrs.name_ext'}' mimetype='$mimetype'");
		
		my $name=file_newhash();
		
		
		# Check if file_item if exists
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::542::db_name`.`a542_file_item`
			WHERE
				ID_entity='$env{'file.ID_entity'}' AND
				lng='$env{'file_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash)
		{
			# file updating
			main::_log("check for update file_item");
			main::_log("checkum in database = '$db0_line{'file_checksum'}'");
			main::_log("checkum from file = '$checksum_method:$checksum'");
			if ($db0_line{'file_checksum'} eq "$checksum_method:$checksum")
			{
				main::_log("same checksum, just enabling file when disabled");
				my %columns;
				App::020::SQL::functions::update(
					'ID' => $db0_line{'ID'},
					'db_h' => 'main',
					'db_name' => $App::542::db_name,
					'tb_name' => 'a542_file_item',
					'columns' =>
					{
						'mimetype' => "'$mimetype'",
						'hash_secure' => "'$hash_secure'",
						'status' => "'Y'",
						%columns
					},
					'-journalize' => 1,
					'-posix' => 1,
				);
			}
			else
			{
				main::_log("checksum differs");
				my %columns;
				App::020::SQL::functions::update(
					'ID' => $db0_line{'ID'},
					'db_h' => 'main',
					'db_name' => $App::542::db_name,
					'tb_name' => 'a542_file_item',
					'columns' =>
					{
						'name' => "'$name'",
						'mimetype' => "'$mimetype'",
						'hash_secure' => "'$hash_secure'",
						'file_size' => "'$file_size'",
						'file_checksum' => "'$checksum_method:$checksum'",
						'file_ext' => "'$env{'file_attrs.name_ext'}'",
						'status' => "'Y'",
						%columns
					},
					'-journalize' => 1,
					'-posix' => 1,
				);
				my $path=$tom::P.'/!media/a542/file/item/'._file_item_genpath
				(
					$env{'file_attrs.lng'},
					$db0_line{'ID'},
					$name,
					$env{'file_attrs.name_ext'}
				);
				main::_log("copy to $path");
				File::Copy::copy($env{'file'},$path);
			}
		}
		else
		{
			# file creating
			main::_log("creating file_item");
			my %columns;
#			$columns{'file_alt_src'}="'$env{'file'}'" if $env{'file_nocopy'};
			
			my $ID=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::542::db_name,
				'tb_name' => "a542_file_item",
				'columns' =>
				{
					'ID_entity' => $env{'file.ID_entity'},
					'name' => "'$name'",
					'mimetype' => "'$mimetype'",
					'hash_secure' => "'$hash_secure'",
					'file_size' => "'$file_size'",
					'file_checksum' => "'$checksum_method:$checksum'",
					'file_ext' => "'$env{'file_attrs.name_ext'}'",
					'status' => "'Y'",
					'lng' => "'$env{'file_attrs.lng'}'",
					%columns
				},
				'-journalize' => 1,
				'-posix' =>1
			);
			if (!$ID)
			{
				$t->close();
				return undef
			};
			$ID=sprintf("%08d",$ID);
			main::_log("ID='$ID'");
			
			my $path=$tom::P.'/!media/a542/file/item/'._file_item_genpath
			(
				$env{'file_attrs.lng'},
				$ID,
				$name,
				$env{'file_attrs.name_ext'}
			);
			main::_log("copy to $path");
			my $out=File::Copy::copy($env{'file'},$path);
			if (!$out)
			{
				main::_log("can't copy file $!",1);
				$t->close();
				return undef;
			}
		}
		
	}
	
	
	
	# FILE ATTRS
	
	if (!$env{'file_attrs.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::542::db_name`.`a542_file_attrs`
			WHERE
				ID_entity='$env{'file.ID'}' AND
				lng='$env{'file_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%file_attrs=$sth0{'sth'}->fetchhash();
		$env{'file_attrs.ID'}=$file_attrs{'ID'};
	}
	if (!$env{'file_attrs.ID'})
	{
		# create one language representation of video
		my %columns;
		$columns{'ID_category'}=$env{'file_attrs.ID_category'} if $env{'file_attrs.ID_category'};
		$columns{'status'}="'$env{'file_attrs.status'}'" if $env{'file_attrs.status'};
		
		$env{'file_attrs.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::542::db_name,
			'tb_name' => "a542_file_attrs",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'file.ID'},
				'lng' => "'$env{'file_attrs.lng'}'",
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		%file_attrs=App::020::SQL::functions::get_ID(
			'ID' => $env{'file_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::542::db_name,
			'tb_name' => "a542_file_attrs",
			'columns' => {'*'=>1}
		);
	}
	
	# update if necessary
	if ($file_attrs{'ID'} &&
	(
		# name
		($env{'file_attrs.name'} && ($env{'file_attrs.name'} ne $file_attrs{'name'})) ||
		# name_ext
		($env{'file_attrs.name_ext'} && ($env{'file_attrs.name_ext'} ne $file_attrs{'name_ext'})) ||
		# ID_category
		($env{'file_attrs.ID_category'} && ($env{'file_attrs.ID_category'} ne $file_attrs{'ID_category'}))
	))
	{
		my %columns;
		
		# name
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'file_attrs.name'})."'"
			if ($env{'file_attrs.name'} && ($env{'file_attrs.name'} ne $file_attrs{'name'}));
		# name_url
		$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'file_attrs.name'}))."'"
			if ($env{'file_attrs.name'} && ($env{'file_attrs.name'} ne $file_attrs{'name'}));
		# name_ext
		$columns{'name_ext'}="'".TOM::Security::form::sql_escape($env{'file_attrs.name_ext'})."'"
			if ($env{'file_attrs.name_ext'} && ($env{'file_attrs.name_ext'} ne $file_attrs{'name_ext'}));
		# ID_category
		$columns{'ID_category'}="'".TOM::Security::form::sql_escape($env{'file_attrs.ID_category'})."'"
			if ($env{'file_attrs.ID_category'} && ($env{'file_attrs.ID_category'} ne $file_attrs{'ID_category'}));
		
		App::020::SQL::functions::update(
			'ID' => $file_attrs{'ID'},
			'db_h' => "main",
			'db_name' => $App::542::db_name,
			'tb_name' => "a542_file_attrs",
			'columns' => {%columns},
			'-journalize' => 1,
			'-posix' => 1,
		);
	}
	
	
	# FILE ENT
	
	my %file_ent;
	if (!$env{'file_ent.ID_entity'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::542::db_name`.`a542_file_ent`
			WHERE
				ID_entity='$env{'file.ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%file_ent=$sth0{'sth'}->fetchhash();
		$env{'file_ent.ID_entity'}=$file_ent{'ID_entity'};
		$env{'file_ent.ID'}=$file_ent{'ID'};
	}
	if (!$env{'file_ent.ID_entity'})
	{
		# create one entity representation of file
		my %columns;
		
		$env{'file_ent.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::542::db_name,
			'tb_name' => "a542_file_ent",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'file.ID_entity'},
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
	}
	
	if (!$file_ent{'posix_owner'} && !$env{'file_ent.posix_owner'})
	{
		$env{'file_ent.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update if necessary
	if ($env{'file_ent.ID'} &&
	(
		# posix_author
		($env{'file_ent.posix_author'} && ($env{'file_ent.posix_author'} ne $file_ent{'posix_author'})) ||
		# posix_owner
		($env{'file_ent.posix_owner'} && ($env{'file_ent.posix_owner'} ne $file_ent{'posix_owner'}))
	))
	{
		my %columns;
		$columns{'posix_author'}="'".$env{'file_ent.posix_author'}."'"
			if ($env{'file_ent.posix_author'} && ($env{'file_ent.posix_author'} ne $file_ent{'posix_author'}));
		$columns{'posix_owner'}="'".$env{'file_ent.posix_owner'}."'"
			if ($env{'file_ent.posix_owner'} && ($env{'file_ent.posix_owner'} ne $file_ent{'posix_owner'}));
		App::020::SQL::functions::update(
			'ID' => $env{'file_ent.ID'},
			'db_h' => "main",
			'db_name' => $App::542::db_name,
			'tb_name' => "a542_file_ent",
			'columns' => {%columns},
			'-journalize' => 1,
			'-posix' => 1,
		);
	}
	
	main::_log("file.ID='$env{'file.ID'}' added");
	
	$tr->close(); # commit transaction
	$t->close();
	return %env;
}


=head2 file_newhash()

Find new unique hash for file

=cut

sub file_newhash
{
	my $optimal_hash=shift;
	if ($optimal_hash)
	{
		$optimal_hash=Int::charsets::encode::UTF8_ASCII($optimal_hash);
		$optimal_hash=~tr/[A-Z]/[a-z]/;
		$optimal_hash=~s|[^a-z0-9]|_|g;
		1 while ($optimal_hash=~s|__|_|g);
		my $max=120;
		if (length($optimal_hash)>$max)
		{
			$optimal_hash=substr($optimal_hash,0,$max);
		}
		main::_log("optimal_hash='$optimal_hash'");
	}
	
	my $okay=0;
	my $hash;
	
	while (!$okay)
	{
		
		$hash=$optimal_hash || TOM::Utils::vars::genhash(8);
		main::_log("testing hash='$hash'");
		my $sql=qq{
			(
				SELECT ID
				FROM
					`$App::542::db_name`.a542_file_item
				WHERE
					name LIKE '$hash'
				LIMIT 1
			)
			UNION ALL
			(
				SELECT ID
				FROM
					`$App::542::db_name`.a542_file_item_j
				WHERE
					name LIKE '$hash'
				LIMIT 1
			)
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (!$sth0{'sth'}->fetchhash())
		{
			main::_log("found hash '$hash'");
			$okay=1;
			last;
		}
		undef $optimal_hash;
	}
	
	return $hash;
}


sub _file_item_genpath
{
	my $language=shift;
	my $ID=shift;
	my $name=shift;
	my $ext=shift;
	$ID=~s|^(....).*$|\1|;
	
	my $pth=$tom::P.'/!media/a542/file/item/'.$language.'/'.$ID;
	if (!-d $pth)
	{
		File::Path::mkpath($tom::P.'/!media/a542/file/item/'.$language.'/'.$ID);
	}
	return "$language/$ID/$name.$ext";
};




sub file_item_info
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::file_item_info()");
	
	my $sql=qq{
		SELECT
			view.*,
			IF
			(
				(SELECT COUNT(*) FROM `$App::542::db_name`.a542_file_view WHERE ID_entity_file=view.ID_entity_file AND status IN ('Y','N')) > 1,
				'Y','N'
			) AS symlink
		FROM
			`$App::542::db_name`.a542_file_view AS view
		WHERE
			ID_file = '$env{'file.ID'}' AND
			ID_category = '$env{'file_attrs.ID_category'}'
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
			
			$data{'ID'}=$db0_line{'ID_file'};
			$data{'ID_entity'}=$db0_line{'ID_entity_file'};
			
#			my %author=App::301::authors::get_author($db0_line{'posix_author'});
#			foreach (keys %author){$data{'author_'.$_}=$author{$_};}
			
#			my %editor=App::301::authors::get_author($db0_line{'posix_editor'});
#			foreach (keys %editor){$data{'editor_'.$_}=$editor{$_};}
			
			# check relations
			foreach my $relation (App::160::SQL::get_relations(
				'db_name' => $App::542::db_name,
				'l_prefix' => 'a542',
				'l_table' => 'file',
				'l_ID_entity' => $db0_line{'ID_entity_file'},
#				'rel_type' => $env{'rel_type'},
#				'r_prefix' => "a501",
#				'r_table' => "image",
				'status' => "Y"
			))
			{
				$data{'relation_status'}='Y';
			}
			
			$data{'size'}=TOM::Text::format::bytes($db0_line{'file_size'});
			
			$data{'ico_mime'}=$db0_line{'mimetype'};
			$data{'ico_mime'}=~s|[/\.+]|-|g;
			
		}
		
	}
	else
	{
		main::_log("can't select",1);
	}
	
	$t->close();
	return %data;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
