#!/bin/perl

package App::540::dir;

use App::540;
use App::540::file;
use strict;

sub get
{
	my %args;
# ID only get
	if (@_==1)
	{
			$args{ID}=shift;
	}
	else
# Get By Hash
	{
			%args = @_;
	}
# Execute
	$args{table}="a540_dir";
	return App::540::sql_get(%args);
}

sub del
{
	my %args;
# ID only get
	if (@_==1)
	{
			$args{ID}=shift;
	}
	else
# Get By Hash
	{
			%args = @_;
	}

# Execute
	my @dirs = get( %args );
	alarm 30;
	for (my $i=0;$i< scalar(@dirs);$i++)
	{
		App::540::sql_del ( ID=>$dirs[$i]{ID}, table=>"a540_dir" );
		my @mutations = get( return=>"count(*) as count", ID_dir=>$dirs[$i]{ID_dir});
		if ($mutations[0]{count} eq 0)
		{
			App::540::file::del ( ID_dir=>"%$dirs[$i]{ID_dir}%" ) ;
			del ( ID_dir=>"%$dirs[$i]{ID_dir}%" ) ;
		}
	}
	return 1;
}

sub new
{
	my %args;
 	if (@_<1 )
{
	main::_log("App::540::dir::new : Argument funkcie musí byť hash",0);
	return -1;
}
 	else
# Get By Hash
{
 		%args = @_;
}

	if (not exists $args{name})
	{
			main::_log("App::540::dir::new : Treba predať 'name' adresára",1);
			return -1;
	}
	if (not exists $args{ID_dir})
	{
			main::_log("App::540::dir::new : Treba predať 'ID_dir' adresára",1);
			return -1;
	}

	$args{table}="a540_dir";
	return App::540::sql_insert( %args );
}

sub set
{
	my %args;
 	if (@_<1 )
{
	main::_log("App::540::dir::set : Argument funkcie musí byť hash",0);
	return -1;
}
 	else
# Get By Hash
{
 		%args = @_;
}

	if (not exists $args{ID})
{
			main::_log("App::540::dir::set : Treba predať 'ID' adresára",1);
			return -1;
}

	my @dirs = get($args{ID});
	my $size = scalar( @dirs );
	if ($size == 0 )
{
	main::_log("App::540::dir::set : adresár s ID=".$args{ID}." neexistuje",0);
	return -1;
}
# Merge updates
	foreach my $key (keys %{$dirs[0]})
{
		my $value = $dirs[0]{$key};
		$args{$key} = $value if (not exists $args{$key});
}

	$args{table}="a540_dir";
	return App::540::sql_insert( %args );
}
1;