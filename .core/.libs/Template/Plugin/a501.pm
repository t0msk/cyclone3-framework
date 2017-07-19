package Template::Plugin::a501;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::501::_init;

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

sub get_image
{
	my $self = shift;
	my $env = shift;
	
	$env->{'image_attrs.lng'}=$tom::lng unless $env->{'image_attrs.lng'};
	
	my $sql_where;
	my @sql_bind;
	
	if ($env->{'image_attrs.name'})
	{
		$sql_where.="AND image_attrs.name LIKE ? AND image_attrs.status = 'Y' ";
		push @sql_bind,$env->{'image_attrs.name'};
	}
	if ($env->{'image_cat.ID'})
	{
		$sql_where.="AND image_cat.ID LIKE ? AND image_attrs.status = 'Y' AND image_cat.status = 'Y' ";
		push @sql_bind,$env->{'image_cat.ID'};
	}
	if ($env->{'image_cat.ID_entity'})
	{
		$sql_where.="AND image_cat.ID_entity LIKE ? ";
		push @sql_bind,$env->{'image_cat.ID_entity'};
	}
	
	
	$sql_where=~s|^AND ||;
	
	my $sql=qq{
		SELECT
			image.ID_entity,
			image.ID,
			image_attrs.name,
			CASE image_attrs.lng
				WHEN '$env->{'image_attrs.lng'}' THEN '1'
				ELSE '0'
			END AS lng_relevance
		FROM
			`$App::501::db_name`.`a501_image` AS image
		LEFT JOIN `$App::501::db_name`.`a501_image_ent` AS image_ent ON
		(
			image_ent.ID_entity = image.ID_entity
		)
		LEFT JOIN `$App::501::db_name`.`a501_image_attrs` AS image_attrs ON
		(
			image_attrs.ID_entity = image.ID
		)
		LEFT JOIN `$App::501::db_name`.`a501_image_cat` AS image_cat ON
		(
			image_cat.ID_entity = image_attrs.ID_category AND
			image_cat.lng = image_attrs.lng
		)
		WHERE
			$sql_where
		ORDER BY
			lng_relevance DESC
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1,
		'-cache' => 86400*7, #24H max
		'-cache_changetime' => App::020::SQL::functions::_get_changetime({
			'db_h'=>"main",'db_name'=>$App::501::db_name,'tb_name'=>"a501_image",
			'ID_entity' => $env->{'image.ID_entity'}
		}),
#		'-recache' => $env->{'-recache'},
		'bind' => [@sql_bind]
	);
	my %db0_line=$sth0{'sth'}->fetchhash();
	
	return \%db0_line;
}

sub get_image_file {
	my $self = shift;
	my $env=shift;
	
	use JSON;
	
	my %image=App::501::functions::get_image_file(%{$env});
	$image{'ID_entity'}=$image{'ID_entity_image'};
	
#	main::_log("get_image_file input=".to_json($env)." output=".to_json(\%image),3,"debug");
	
	if ($env->{'resize'} && $image{'ID'})
	{
		%{$image{'resized'}}=App::501::functions::image_file_resize(
			'image_file.ID' => $image{'ID_file'},
			'width' => $env->{'resize'}->{'width'},
			'height' => $env->{'resize'}->{'height'},
			'method' => $env->{'resize'}->{'method'} || 'auto',
		);
	}
	elsif ($env->{'crop'} && $image{'ID'})
	{
		%{$image{'cropped'}}=App::501::functions::image_file_crop(
			'image_file.ID' => $image{'ID'},
			'crop' => $env->{'crop'}
		);
	}
	
	return \%image;
}

1;
