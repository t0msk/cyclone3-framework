package Template::Plugin::a710;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::710::_init;

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

sub get_org {
	my $self = shift;
	my $env=shift;
	
	my @sql_bind;
	my $sql_where;
	
	push @sql_bind,($env->{'lng'} || $env->{'org_lng.lng'} || $tom::lng);
	push @sql_bind,($env->{'lng'} || $env->{'org_lng.lng'} || $tom::lng);
	
	if ($env->{'ID'})
	{
		$sql_where.="AND org.ID = ? ";
		push @sql_bind, $env->{'ID'};
	}
	elsif ($env->{'ID_entity'})
	{
		$sql_where.="AND org.ID_entity = ? ";
		push @sql_bind, $env->{'ID_entity'};
	}
	elsif ($env->{'org.ID'})
	{
		$sql_where.="AND org.ID = ? ";
		push @sql_bind, $env->{'org.ID'};
	}
	elsif ($env->{'org.ID_entity'})
	{
		$sql_where.="AND org.ID_entity = ? ";
		push @sql_bind, $env->{'org.ID_entity'};
	}
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			org.ID_entity,
			org.ID,
			org.datetime_create,
			org.posix_owner,
			org.posix_modified,
			org.name,
			org.name_url,
			org.name_code,
			org.type,
			org.legal_form,
			org.ID_org,
			org.tax_number,
			org.VAT_number,
			org.bank_contact,
			org.country_code,
			org.state,
			org.county,
			org.district,
			org.city,
			org.ZIP,
			org.street,
			org.street_num,
			org.latitude_decimal,
			org.longitude_decimal,
			org.location_verified,
			org.address_postal,
			org.phone_1,
			org.phone_2,
			org.fax,
			org.email,
			org.web,
			org.note,
			org.metadata,
			org.datetime_evidence,
			org.mode,
			org.status,
			
			org_cat.ID AS cat_ID,
			org_cat.ID_entity AS cat_ID_entity,
			org_cat.name AS cat_name,
			
			org_lng.name_short,
			org_lng.about
			
		FROM `$App::710::db_name`.a710_org AS org
		LEFT JOIN `$App::710::db_name`.a710_org_lng AS org_lng ON
		(
			org_lng.ID_entity = org.ID AND
			org_lng.lng = ?
		)
		LEFT JOIN `$App::710::db_name`.a710_org_rel_cat AS org_rel_cat ON
		(
			org_rel_cat.ID_org = org.ID_entity
		)
		LEFT JOIN `$App::710::db_name`.a710_org_cat AS org_cat ON
		(
			org_cat.ID_entity = org_rel_cat.ID_category AND
			org_cat.lng = ?
		)
		
		WHERE
			org.status IN ('Y','L')
			$sql_where
		LIMIT
			1
	},'bind'=>[@sql_bind],'log'=>0);
	
	my %org=$sth0{'sth'}->fetchhash();
	
	%{$org{'metahash'}}=App::020::functions::metadata::parse($org{'metadata'});
	delete $org{'metadata'};
	
#	my %image=App::501::functions::get_image_file(%{$env});
#	$image{'ID_entity'}=$image{'ID_entity_image'};
	
	return \%org;
}

1;
