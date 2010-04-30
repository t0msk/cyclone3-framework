#!/bin/perl
package App::020::SQL::journal;

=head1 NAME

App::020::SQL::journal

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 DESCRIPTION

This is low level SQL API to database tables defined by L<DATA standard|standard/"DATA">.
Lists journal entries and row differences across entries for joined tables.

=cut

use App::301::_init;
use String::Diff;

=head1 FUNCTIONS

=head2 get_journal_list()

Usage:

	my %sources = 
	(
		'910' => {
			'product_ent' => {
						'f_key' => 'ID_entity', 		# foreign key
						'p_key' => 'ID',			# primary key
						'db_name' => $App::910::db_name		# database name
					},

			'product' => {
						'f_key' => 'ID_entity',
						'p_key' => 'ID',
						'db_name' => $App::910::db_name
						}
			}
	);

	my @resultset = App::020::SQL::journal::get_journal_list(
		'ID_entity' => "'".$env{'ID_entity'}."'",				# common foreign key value
		'sql_limit' => $env{'sql_limit'},					# sql_limit
		'sources' => { %sources }						# reference to the source tables hash
		);


	Produces an array of hashes

=cut

sub get_journal_list
{
	my %env=@_;

	$env{'sql_limit'}=~s|^,|0,|;$env{'sql_limit'}=~s|,$|,10|;
	$env{'sql_limit'}=50 unless $env{'sql_limit'};

	my $paging = 0;

	# inform the module that we will be using paging: some values need to be pre-fetched
	# 
	if ($env{'sql_limit'} =~ /^(\d+),\s*(\d+)$/) { if ($1 != 0) { $paging = 1; } }

	my $ID_entity = $env{'ID_entity'};
	

	# let's start building the union SQL 

	my $union_sql=qq{
		SELECT * FROM
		(
	};
	
	my $union_sql_counter = 0;
	my $union_clause;

	foreach my $addon (keys %{$env{'sources'}})
	{
		foreach my $table (keys %{$env{'sources'} -> {$addon}})
		{	
			my $localtable = $env{'sources'} -> {$addon} -> {$table};
			$table = 'a'.$addon.'_'.$table;

			my $sql=qq{
				SELECT
					$localtable->{'f_key'}
				FROM
					`$localtable->{'db_name'}`.$table
				WHERE
					$localtable->{'f_key'} = $ID_entity
				LIMIT
					1
			};	

			my %sth0=TOM::Database::SQL::execute($sql);
			
			# is any information on this entity in this particular table?
			# if so, add the table to UNION selection

			if (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				if ($db0_line{$localtable->{'f_key'}})
				{
					# add this to UNION
					main::_log( "$addon ".$localtable->{'table'}." foreign key : ".$db0_line{$localtable->{'f_key'}}. "\n");

					my $fkey = "\'".$db0_line{$localtable->{'f_key'}}."\'";
					

					my $union_sql_piece =qq{
				(
				SELECT
					'$localtable->{'db_name'}' AS db_name,
					'$addon' AS l_prefix,
					'$table' AS l_table,
					$localtable->{'f_key'} AS $localtable->{'f_key'},
					$localtable->{'f_key'} AS foreign_key_value,
					'$localtable->{'f_key'}' AS foreign_key_name, 
					'$localtable->{'p_key'}' AS primary_key_name, 
					$localtable->{'p_key'} AS primary_key_value, datetime_create
				FROM
					`$localtable->{'db_name'}`.${table}_j
				WHERE
					$localtable->{'f_key'} = $fkey
				ORDER BY
					datetime_create DESC
				)
					};

					if ($union_sql_counter++ >= 1) {$union_clause = "UNION ALL\n";} else {$union_clause = '';}

					$union_sql.=$union_clause.$union_sql_piece;
				}
			}	
		}
	}

	# add a tail to UNION sql

	my $union_sql_tail=qq{
			ORDER BY
				datetime_create DESC
			LIMIT $env{'sql_limit'}
		) AS uni ORDER BY datetime_create ASC
	};

	$union_sql .= $union_sql_tail;

	my %sth0=TOM::Database::SQL::execute($union_sql,'log'=>1,'slave'=>0, 'quiet'=>0);


	my %id;
	my %new_line;
	my %cache;
	my $addon;
	
	my %db0_line;

	my @results;

	my $repeat = 1;
	
	while ($repeat)
	{
		if (%db0_line=$sth0{'sth'}->fetchhash())
		{
			# let's save the last line of each addon/table

			$addon=$db0_line{'l_prefix'}.'_'.$db0_line{'l_table'};

			
			# if paging is enabled, and $new_line($addon) does not exist, pre-fetch some lines for it to compare to
			if ($paging)
			{
				unless ($new_line{$addon})
				{
					my $sql_prefetch=qq{
						SELECT
							*,
							'$db0_line{'l_prefix'}' AS l_prefix,
							'$db0_line{'l_table'}' AS l_table
						FROM
							$db0_line{'db_name'}.$db0_line{'l_table'}\_j
						WHERE
							$db0_line{'primary_key_name'} < '$db0_line{'primary_key_value'}' AND
							datetime_create < '$db0_line{'datetime_create'}'
						LIMIT 1;
						};

					my %sth1=TOM::Database::SQL::execute($sql_prefetch, 'log'=>1,'slave'=>0, 'quiet'=>0);

					if (my %dbp_line=$sth1{'sth'}->fetchhash())
					{
						foreach(keys %dbp_line){$new_line{$addon}{$_}=$dbp_line{$_}}
					}
				}
			}

			
			# get particular values for this table, this line, this ID
			my $sql_item=qq{
			SELECT
				*,
				'$db0_line{'l_prefix'}' AS l_prefix,
				'$db0_line{'l_table'}' AS l_table
			FROM
				$db0_line{'db_name'}.$db0_line{'l_table'}\_j
			WHERE
				$db0_line{'primary_key_name'} ='$db0_line{'primary_key_value'}' AND
				datetime_create='$db0_line{'datetime_create'}'
			LIMIT 1;
			};

			my %sth1=TOM::Database::SQL::execute($sql_item, 'log'=>1,'slave'=>0, 'quiet'=>0);
			if (my %db1_line=$sth1{'sth'}->fetchhash())
			{
				
				if ($new_line{$addon})
				{
					# some change exists, print differences	
					my $description;
					my $description_full;
					foreach (keys %db1_line)
					{
						next if $_ eq "datetime_create";
						next if $_ eq "posix_modified";
						next if $db1_line{$_} eq $new_line{$addon}{$_};
						
						
			
						main::_log(" $_: '$db1_line{$_}'<>'$new_line{$addon}{$_}'");
						$description.="$_, ";
						$description_full.="$_=".(String::Diff::diff($new_line{$addon}{$_},$db1_line{$_}))[1].", \n";
					}
					$description=~s|, $||;
					$description_full=~s|, $||;
					my %modified=App::301::authors::get_author($db1_line{'posix_modified'});
					($modified{'fullname'},$modified{'shortname'})=App::301::authors::get_fullname(%modified);

 					$db1_line{'l_table'} =~ s/(a\d+_)//;

					push(@results,
						{
							'datetime_create' => $db1_line{'datetime_create'},
							'posix_modified' => $db1_line{'posix_modified'},
							'description' => $description,
							'description_full' => $description_full,
							'l_prefix' => 'a'.$db1_line{'l_prefix'},
							'l_table' => $db1_line{'l_table'},
							'modified_fullname' => $modified{'fullname'},
							'modified_shortname' => $modified{'shortname'},
							$db0_line{'foreign_key_name'} => $db0_line{'foreign_key_value'},
							'test' => 'test test'
						}
					);

				} else
				{
					main::_log("NO CHANGE RECORDED!");
				}


				foreach(keys %db1_line){$new_line{$addon}{$_}=$db1_line{$_}}
			
			}
		} else
		{
			$repeat = 0;
		}	
	}

return @results;

}

1;