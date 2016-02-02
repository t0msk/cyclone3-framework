package Template::Plugin::a210;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::210::_init;

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

sub get_path_url {
	my $self = shift;
	my $env = shift;
#	my @relations=App::160::SQL::get_relations(%{$env});
#	return \@relations;
	
	my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
	
	if ($env->{'ID'})
	{
		my %page=App::020::SQL::functions::get_ID(
			%sql_def,
			'ID'      => $env->{'ID'},
			'columns' => { '*' => 1 },
			'-slave' => 1,
			'-cache' => 86400,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%sql_def)
		);
		$env->{'ID_entity'}=$page{'ID_entity'};
	}
	
#	main::_log("search ".$env->{'ID_entity'}." lng=".$env->{'lng'},3,"debug");
	
	if ($env->{'ID_entity'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::210::db_name`.a210_page
			WHERE
				ID_entity = ?
				AND lng = ?
		},
		'-slave' => 1,
		'-cache' => 600,
		'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%sql_def),
		'bind' => [
			$env->{'ID_entity'},
			$env->{'lng'} || $tom::lng
		]);
		return undef unless $sth0{'rows'};
		my %page=$sth0{'sth'}->fetchhash();
		
		my $a210_path;
		
		foreach my $p(
			App::020::SQL::functions::tree::get_path(
				$page{'ID'},
				%sql_def,
				'-slave' => 1,
				'-cache' => 86400
			)
		)
		{
			$a210_path.="/".$p->{'name_url'};
		}
		
		$a210_path=~s|^/||;
		return $a210_path;
	}
	
}

sub get_node {
	my $self = shift;
	my $env = shift;
#	my @relations=App::160::SQL::get_relations(%{$env});
#	return \@relations;
	
	my %sql_def=('db_h' => "main",'db_name' => $App::210::db_name,'tb_name' => "a210_page");
	
	if ($env->{'ID'})
	{
		my %page=App::020::SQL::functions::get_ID(
			%sql_def,
			'ID'      => $env->{'ID'},
			'columns' => { '*' => 1 },
			'-slave' => 1,
			'-cache' => 86400,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%sql_def)
		);
		$env->{'ID_entity'}=$page{'ID_entity'};
	}
	
#	main::_log("search ".$env->{'ID_entity'}." lng=".$env->{'lng'},3,"debug");
	my %page;
	if ($env->{'ID_entity'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::210::db_name`.a210_page
			WHERE
				ID_entity = ?
				AND lng = ?
		},
		'-slave' => 1,
		'-cache' => 600,
		'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%sql_def),
		'bind' => [
			$env->{'ID_entity'},
			$env->{'lng'} || $tom::lng
		]);
		return undef unless $sth0{'rows'};
		%page=$sth0{'sth'}->fetchhash();
		
		foreach my $p(
			App::020::SQL::functions::tree::get_path(
				$page{'ID'},
				%sql_def,
				'-slave' => 1,
				'-cache' => 86400
			)
		)
		{
			$page{'path_url'}.="/".$p->{'name_url'};
		}
		
		$page{'path_url'}=~s|^/||;
		
		use JSON;
		
		my $tmpjson = $page{'t_keys'};
		$tmpjson =~s|^#json||;
		$page{'keys'} = from_json($tmpjson) if $tmpjson;
		
		return \%page;
	}
	
#	return \%page;
}

1;
