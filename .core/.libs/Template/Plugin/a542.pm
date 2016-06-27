package Template::Plugin::a542;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::542::_init;

our $VERSION = 1.00;
our $DEBUG   = 0 unless defined $DEBUG;
our $AUTOLOAD;

#==============================================================================
#                      -----  CLASS METHODS -----
#==============================================================================

sub new {
	my ($class, $context, $params) = @_;
	my ($key, $val);
	$params ||= { };

	bless { 
		_CONTEXT => $context, 
	}, $class;
}

sub get_file {
	my $self = shift;
	my $env = shift;
	my %file;
	
	my @bind;
	my %sql_env;
	
	push @bind, $self->{'_CONTEXT'}->{'tpl'}->{'ENV'}->{'lng'};
	push @bind, $self->{'_CONTEXT'}->{'tpl'}->{'ENV'}->{'lng'};
	
	my $sql_where;
	
	if (ref($env) eq 'SCALAR' || !ref($env))
	{
		if ($env=~/^\d+$/)
		{
			$sql_where .= qq{ AND `file`.`ID_entity`=?};
			push @bind,$env;
		}
	}
	else
	{
		use Data::Dumper;
		
		if ($env->{'file.ID'}=~/^\d+$/)
		{
			$sql_where .= qq{ AND `file`.`ID`=?};
			push @bind, $env->{'file.ID'};
		}
		if ($env->{'file.ID_entity'}=~/^\d+$/)
		{
			$sql_where .= qq{ AND `file`.`ID_entity`=?};
			push @bind, $env->{'file.ID_entity'};
		}
	}
	
	my $sql=qq{
		SELECT
			`file`.`ID`,
			`file`.`ID_entity`,
			`file_ent`.`datetime_publish_start`,
			`file_ent`.`datetime_publish_stop`,
			`file_ent`.`posix_owner` AS `ent_posix_owner`,
			`file_ent`.`posix_author` AS `ent_posix_author`,
			`file_attrs`.`name`,
			`file_attrs`.`name_url`,
			`file_attrs`.`name_ext`,
			`file_dir`.`ID` AS `cat_ID`,
			`file_dir`.`ID_entity` AS `cat_ID_entity`,
			`file_dir`.`ID_charindex` AS `cat_ID_charindex`,
			`file_dir`.`name` AS `cat_name`,
			`file_dir`.`name_url` AS `cat_name_url`,
			`file_item`.`ID` AS `file_item_ID`,
			`file_item`.`hash_secure`,
			`file_item`.`file_size`,
			`file_item`.`mimetype`,
			IF
			(
				(`ACL_world`.`perm_R`='Y' OR `ACL_world`.`perm_R` IS NULL),
				'Y', 'N'
			) AS `world_status`
			
		FROM
			`$App::542::db_name`.`a542_file` AS `file`
		INNER JOIN `$App::542::db_name`.`a542_file_ent` AS `file_ent` ON
		(
					`file_ent`.`ID_entity` = `file`.`ID_entity`
			AND	`file_ent`.`status` IN ('Y','L')
		)
		INNER JOIN `$App::542::db_name`.`a542_file_attrs` AS `file_attrs` ON
		(
					`file_attrs`.`ID_entity` = `file`.`ID`
			AND	`file_attrs`.`lng` = ?
			AND	`file_attrs`.`status` IN ('Y','L')
		)
		INNER JOIN `$App::542::db_name`.`a542_file_item` AS `file_item` ON
		(
					`file_item`.`ID_entity` = `file`.`ID`
			AND	`file_item`.`lng` = ?
			AND	`file_item`.`status` IN ('Y','L')
		)
		LEFT JOIN `$App::542::db_name`.`a542_file_dir` AS file_dir ON
		(
					`file_dir`.`ID_entity` = `file_attrs`.`ID_category`
			AND	`file_dir`.`lng` = `file_attrs`.`lng`
			AND	`file_dir`.`status` IN ('Y','L')
		)
		LEFT JOIN `$App::401::db_name`.`a301_ACL_user_group` AS `ACL_world` ON
		(
					`ACL_world`.`ID_entity` = 0
			AND	`r_prefix` = 'a542'
			AND	`r_table` = 'file'
			AND	`r_ID_entity` = `file`.`ID_entity`
		)
		WHERE
			`file`.`status` IN ('Y','L')
			$sql_where
		LIMIT
			1
	};
		
	#use Data::Dumper;
	#open(HND,'>'.$tom::P.'/!www/dump.dump');
	#print HND Dumper($self->{'_CONTEXT'}->{'tpl'}->{'ENV'});
	#close (HND);
	#main::_log("lng is ".Dumper($self->{'_CONTEXT'}),3,"debug");
	
	my %sth0=TOM::Database::SQL::execute(
		$sql,
		'bind'=>[
			@bind
		],
		'log'=>1,
		%sql_env
	);
	%file=$sth0{'sth'}->fetchhash();
	
	return \%file;
}

1;
