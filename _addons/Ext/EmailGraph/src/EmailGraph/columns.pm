#!/bin/perl
package EmailGraph::columns;
use Utils::vars;
use strict;

sub new
{
	my $self = shift; $self = bless {}, $self; my %env = @_;
	
	# Can be set from outside
	$self->{'title'} = $env{'title'} if $env{'title'};
	$self->{'y-title'} = $env{'y-title'} if $env{'y-title'};
	$self->{'x-title'} = $env{'x-title'} if $env{'x-title'};
	
	$self->{'height'} = int( $env{'height'} ) || 200;
	$self->{'margin'} = int( $env{'margin'} ) || 10;

	$self->{'font-size'} = int( $env{'font-size'} ) || 9;
	$self->{'font-size-title'} = int( $env{'font-size-title'} ) || $self->{'font-size'};
	$self->{'font-size-axis-title'} = int( $env{'font-size-axis-title'} ) || $self->{'font-size'};
	$self->{'font-size-column'} = int( $env{'font-size-column'} ) || $self->{'font-size'};

	$self->{'display-values'} = int( $env{'display-values'} ) || 0;

	$self->{'color1'} = $env{'color1'} || '#efefef';
	$self->{'color2'} = $env{'color2'} || '#e1e1e1';

	# Should not be set from outside
	@{$self->{'columns'}} = ();
	$self->{'max'} = 0;

	return $self;
}

sub addColumn
{
	my $self = shift;

	my $title = $_[0]; my $value = int($_[1]); my $even = $_[2] || 0;
	return 0 if !$title || $value<0;

	main::_log( "Pushing: \"$title\" => \"$value\" (even: $even)" );
	
	$self->{'max'} = $value if $self->{'max'} < $value;
	push @{$self->{'columns'}}, { 'title' => $title, 'value' => $value, 'even' => $even };

	return 1;
}

sub as_html
{
	my $self = shift;
	my $graph_perc = ($self->{'height'}-$self->{'margin'})/100;
	my $count = @{$self->{'columns'}};
	
	my $html = qq!
	<table cellpadding="0" cellspacing="2">
		<#TITLE#>
		<tr height="$self->{'height'}px">
			<#YTITLE#>
			<#COLUMNS#>
		</tr>
		<tr>
			<#XTITLE#>
			<#COLUMN_NAMES#>
		</tr>
	</table>
	!;

	my $title = qq!
	<tr>
		<th colspan="<\%count%>" style="font-size: <\%font-size%>px;"><\%title%></th>
	</tr>
	!;

	if ( $self->{'title'} )
	{
		$title =~ s|<%title%>|$self->{'title'}|g;
		$title =~ s|<%count%>|$count|g;
		$title =~ s|<%font-size%>|$self->{'font-size-title'}|g;
		$html =~ s|<#TITLE#>|$title|g;
	}
	else { $html =~ s|<#TITLE#>||g; }

	my $axis_title = qq!
	<th style="font-size: <\%font-size%>px;"><\%title%></th>
	!;

	if ( $self->{'x-title'} || $self->{'y-title'} )
	{
		my $x_title = $axis_title; $x_title =~ s|<%title%>|$self->{'x-title'}|g;
		my $y_title = $axis_title; $y_title =~ s|<%title%>|$self->{'y-title'}|g;
		$x_title =~ s|<%font-size%>|$self->{'font-size-axis-title'}|g;
		$y_title =~ s|<%font-size%>|$self->{'font-size-axis-title'}|g;
		$html =~ s|<#YTITLE#>|$y_title|g;
		$html =~ s|<#XTITLE#>|$x_title|g;
	}
	else
	{
		$html =~ s|<#YTITLE#>||g;
		$html =~ s|<#XTITLE#>||g;
	}

	my $column = qq!
	<td style="background: <\%color%>; vertical-align: bottom;">
		<#VALUE#>
		<div style="background: #f00; height: <\%height%>px;"></div>
	</td>
	<#COLUMNS#>
	!;

	my $column_value = qq!
	<div style="font-size: <\%font-size%>px;"><\%value%></div>
	!;
	
	my $column_name = qq!
	<td style="font-size: <\%font-size%>px;"><\%title%></td>
	<#COLUMN_NAMES#>
	!;

	foreach my $thash ( @{$self->{'columns'}} )
	{
		my %hash = %{$thash};
		
		my $perc = 0;
		$perc = int( ($hash{'value'}/$self->{'max'})*100 ) if $hash{'value'} && $self->{'max'}>0;
		my $height = int($perc*$graph_perc);
		my $bg = $self->{'color1'}; $bg = $self->{'color2'} if $hash{'even'};

		my $line_c = $column;
		my $line_cn = $column_name;
		main::_log("$hash{'title'}: $hash{'value'}; ($perc :: $height)");

		# Column
		if ( $self->{'display-values'} )
		{
			my $val_line = $column_value;
			$val_line =~ s|<%value%>|$hash{'value'}|g;
			$val_line =~ s|<%font-size%>|$self->{'font-size-column'}|g;
			$line_c =~ s|<#VALUE#>|$val_line|g;
		}
		else { $line_c =~ s|<#VALUE#>||g; }
		$line_c =~ s|<%color%>|$bg|g;
		$line_c =~ s|<%height%>|$height|g;

		# Column name
		$line_cn =~ s|<%title%>|$hash{'title'}|g;
		$line_cn =~ s|<%font-size%>|$self->{'font-size'}|g;

		$html =~ s|<#COLUMNS#>|$line_c|g;
		$html =~ s|<#COLUMN_NAMES#>|$line_cn|g;
	}

	$html =~ s|<#COLUMNS#>||g;
	$html =~ s|<#COLUMN_NAMES#>||g;

	return $html;
}

1;
