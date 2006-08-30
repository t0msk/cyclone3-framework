#!/bin/perl
package Chart::2D::columns;
use Chart::2D;
use strict;


our @ISA=("Chart::2D"); # dedim z neho



sub new
{
 my $class=shift;
 my %env=@_;
 my $self={};
    
 %{$self->{ENV}}=%env;
  
 $self->{grid_y_scale_minimum}=$env{grid_y_scale_minimum};
 $self->{grid_y_scale_maximum}=$env{grid_y_scale_maximum};
 $self->{grid_y_main_spacing}=$env{grid_y_main_spacing};
 
 $self->{type}="columns";
 
 return bless $self,$class;
}





sub prepare
{
	my $self=shift;
	
	$self->{SVG}=SVG->new(width=>$self->{ENV}{x},height=>$self->{ENV}{y});
	$self->{SVG}->script()->CDATA("setTimeout('reload()', ".($self->{ENV}{reload}*1000).");") if $self->{ENV}{reload};
	
	# vykreslim BLOCK
	$self->prepare_block(); 
	# hodim tam text
	$self->prepare_title();    
	# pripravim si columns
	$self->prepare_columns();
	
	#
	# VYPOCITANIE POCTU ROWSOV - $self->{grid_x_main_lines}
	# VYPOCITANIE MAX VALUE - $self->{value_max}
	#
	$self->prepare_axis_calculate();
	$self->prepare_axis_x_markArea(front=>0);
	$self->prepare_axis_x(); 
	$self->prepare_axis_x_mark(front=>0);
	
	$self->prepare_axis_y_markArea(front=>0);
	$self->prepare_axis_y();
	$self->prepare_axis_y_mark(front=>0);
	
	$self->prepare_legend();
	
	# obratim poradie poloziek pre vykreslenie aby boli v rovnakom poradi ako
	# bola nakreslena legenda
	if ($self->{ENV}{type}=~/stacked/)
	{
		#print "robim reverse\n";
		@{$self->{columnsA}}=reverse @{$self->{columnsA}};
	}
	
	
	foreach my $color(keys %Chart::colors::table)
	{
		print "color=$color\n";
		
		my $g = $self->{SVG}->gradient
		(
			'-type' => "linear",
			'id'    => "gr_".$color."_0",
			'x1'=>"0%",'y1'=>"0%",'x2'=>"100%",'y2'=>"0%",
		);
		$g->stop(offset=>"0%",style=>"stop-color:rgb(".$Chart::colors::table{$color}{'N0'}.");stop-opacity:1");
		$g->stop(offset=>"50%",style=>"stop-color:rgb(".$Chart::colors::table{$color}{'L1'}.");stop-opacity:1");
		$g->stop(offset=>"100%",style=>"stop-color:rgb(".$Chart::colors::table{$color}{'N0'}.");stop-opacity:1");
	}
	
	my $g = $self->{SVG}->gradient
	(
		'-type' => "linear",
		'id'    => "gr_highlight_0",
		'x1'=>"0%",'y1'=>"0%",'x2'=>"100%",'y2'=>"0%",
	);
	$g->stop(offset=>"0%",style=>"stop-color:rgb(0,0,0);stop-opacity:1");
	$g->stop(offset=>"50%",style=>"stop-color:rgb(100,100,100);stop-opacity:1");
	$g->stop(offset=>"100%",style=>"stop-color:rgb(0,0,0);stop-opacity:1");
	
	
	my $count=0;   
	foreach my $row(@{$self->{row}{label}})
	{
		$count++;
		
		main::_log("row '$row'");
		
		
		my $rows=0;
		my $data_a;
		#foreach my $column(keys %{$self->{columns}})
		foreach my $column(@{$self->{columnsA}})
		{
			main::_log("column '$column'");
			
			my $color=$self->{columns}->{$column}{ENV}{color};
			my %colors=%{$Chart::colors::table{$color}};
			
			my $data=$self->{columns}{$column}->{data}{$row};
			
			main::_log("data '$data'");
			
			$data=$data/($self->GetRowSum($row)/100) if $self->{ENV}{type}=~/percentage/;
			$data_a+=$data;
			my $data_o=$data; # data original
			my $data_w=$data; # data for display;
			
			my $del;
			my $x;
			my $height;
			my $height0;
			my $xm;
			
			next unless $data_o;
   
   if ($self->{ENV}{type}=~/stacked/)
   {
    $height=(($data_a-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);
    $height=int($height*100)/100;
    $height=0 if $height < 0;
    $height=$self->{block_height} if $height > $self->{block_height};
    
    my $min=$self->{grid_y_scale_minimum};$min=0 if $min<0;
    $height0=((($data_a-$data)-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);

    $del=($self->{block_width_scale}-8);
   
    $x=($count-1)*($self->{block_width}/($self->{grid_x_main_lines}-1));$x+=4;
   }
   elsif ($self->{ENV}{type}=~/overlap/)
   {
    $height=(($data-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);
    $height=int($height*100)/100;
    $height=0 if $height < 0;
    $height=$self->{block_height} if $height > $self->{block_height};
   
    my $min=$self->{grid_y_scale_minimum};$min=0 if $min<0;
    $height0=(($min-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);

    $del=(($self->{block_width_scale}-4)/($self->GetNumColumns()+1));
   
    $x=($count-1)*($self->{block_width}/($self->{grid_x_main_lines}-1));$x+=2;
   
    $x+=($rows*$del);
    
    $xm=-$del;
   }
   else
   {
    $height=(($data-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);
    $height=int($height*100)/100;
    $height=0 if $height < 0;
    $height=$self->{block_height} if $height > $self->{block_height};
   
    my $min=$self->{grid_y_scale_minimum};$min=0 if $min<0;
    $height0=(($min-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);

    $del=($self->{block_width_scale}-6)/$self->GetNumColumns();
   
    $xm=1;
    
    $x=($count-1)*($self->{block_width}/($self->{grid_x_main_lines}-1));$x+=3+($xm/2);
   
    $x+=($rows*$del);
    #$xm=2;
   }
   
   
   
	if ($del-$xm<0.5)
	{
		#print "block_width_scale:".$self->{'block_width_scale'}."\n";
		#print "del:".$del."\n";
		#print "xm:".$xm."\n";
		die "corrupt row size ".($del-$xm)." (too much rows? ".(@{$self->{row}{label}})." )\n";
	}
	
	
	
	

	
	
	my $cl=$self->{SVG}->polyline(
		points	=>	
			($self->{block_left}+$x).",".($self->{block_down}-$height0)." ".
			($self->{block_left}+$x+$del-$xm).",".($self->{block_down}-$height0)." ".
			($self->{block_left}+$x+$del-$xm).",".($self->{block_down}-$height)." ".
			($self->{block_left}+$x).",".($self->{block_down}-$height)." ".
			($self->{block_left}+$x).",".($self->{block_down}-$height0)." ",
		'stroke-width'	=>"0pt",
		#'stroke'		=>"rgb(".$colors{B2}.")",
		'stroke'		=>"rgb(0,0,0)",
	#	'stroke'		=>"black",
	#	'stroke-'		=>"black",
		'stroke-linecap'	=>"butt",
	#	'stroke-linejoin'	=>"butt",
		#'fill'			=>"rgb(".$colors{N0}.")",
	#	'fill'			=>"rgb(".$colors{N0}.")",
		'fill'			=>"url(#gr_".$color."_0)",
		'fill-opacity'	=>"1"
	);
	
=head1
	$cl->animate
	(
		'attributeName'=>"fill",
		'begin'=>"mouseover",
		'end'=>"mouseout",
#		'from'=>"1pt",
#		'to'=>"1pt",
		'values'=>"url(#gr_highlight_0)",
#		'dur'=>"10s",
	#	'repeatDur'=>"freeze"
		'restart'=>"whenNotActive"
	);
=cut
	
=head1
	$cl->animate
	(
		'attributeName'=>"fill",
		'begin'=>"mouseover",
		'end'=>"mouseout",
		'from'=>"rgb(".$colors{L0}.")",
		'to'=>"rgb(".$colors{N0}.")",
	#	'values'=>"30",
		'dur'=>"10s",
	#	'repeatDur'=>"freeze"
		'restart'=>"whenNotActive"
	);
	$cl->animate
	(
		'attributeName'=>"stroke",
		'begin'=>"mouseover",
		'end'=>"mouseout",
		'from'=>"rgb(".$colors{L0}.")",
		'to'=>"rgb(".$colors{B2}.")",
	#	'values'=>"30",
		'dur'=>"10s",
	#	'repeatDur'=>"freeze"
		'restart'=>"whenNotActive"
	);
=cut
	
	$data_w="0" unless $data_w;
	my $d_x=3;
	my $d_y=-2;
	
	if ($self->{ENV}{show_data_background} || $self->{columns}{$column}->{ENV}{show_data_background})
	{
		my $rx="2pt";
		my $ry="2pt";
		my $width=length($data_w)*5;
		my $fill="rgb(255,255,255)";
		my $fill_opacity="0.5";
		
		if ($self->{columns}{$column}->{ENV}{show_data_summary})
		{
			$width=length($self->GetRowSum($row))*5;
			$rx="0pt";
			$ry="0pt";
			$fill="rgb(255,255,255)";
			$fill_opacity="1";
		}
		
		$self->{SVG}->rect(
			'x' => (($self->{block_left}+$x)-1+$d_x),
			'y' => (($self->{block_down}-$height-3)-8+$d_y),
			'width' => $width+3,
			'height' => 10,
			'fill'	=>$fill,
			'fill-opacity'	=>$fill_opacity,
			'stroke'		=>"rgb(125,125,125)",
			'stroke-width'	=>"1pt",
			'stroke-linecap'	=>"round",
			'stroke-linejoin'	=>"round",
			'rx' => $rx,
			'ry' => $ry,
		);
		
	}
	
	if ($self->{ENV}{show_data} || $self->{columns}{$column}->{ENV}{show_data})
	{
		$self->{SVG}->text
		(
		'x'	=>	($self->{block_left}+$x+$d_x),
		'y'	=>	($self->{block_down}-$height-3+$d_y),
		style => {
			'font-family'	=> 'Verdana',
			'font-size'		=> 8,
			'font-weight'	=> 400,
	#		'fill'		=>	"rgb(".$colors{B3}.")",
			'fill'	=>	"rgb(0,0,0)",
	#		'stroke'		=>	"rgb(0,0,0)",
	#		'stroke-width'	=>	"1pt",
			'stroke-linecap'	=>"round",
			'stroke-linejoin'	=>"round",
			},
		)->cdata($data_w);
	}
	
	if ($self->{columns}{$column}->{ENV}{show_data_summary})
	{
		$self->{SVG}->text
		(
		'x'	=>	($self->{block_left}+$x+$d_x),
		'y'	=>	($self->{block_down}-$height-3+$d_y),
		style => {
			'font-family'	=> 'Verdana',
			'font-size'		=> 8,
			'font-weight'	=> 400,
	#		'fill'		=>	"rgb(".$colors{B3}.")",
			'fill'	=>	"rgb(0,0,0)",
	#		'stroke'		=>	"rgb(0,0,0)",
	#		'stroke-width'	=>	"1pt",
			'stroke-linecap'	=>"round",
			'stroke-linejoin'	=>"round",
			},
		)->cdata($self->GetRowSum($row));
	}

   
#   $width=int($width*100)/100;
   
   $rows++;
  }

 }
 
 
 
 
 
 # teraz vykreslim jednotlive ciary
=head1
 my @data_stacked;
 foreach my $column(keys %{$self->{columns}})
 {
  my $color=$self->{columns}->{$column}{ENV}{color};
  my %colors=%{$Chart::colors::table{$color}};
  
  my $count;
  my $points;

  foreach my $row(@{$self->{row}{label}})
  {
   my $data=$self->{columns}{$column}->{data}{$row};  
   my $data_o=$data; # data original
   my $data_w=$data; # data for display;
   $count++;   
   $data=$data/($self->GetRowSum($row)/100) if $self->{ENV}{type}=~/percentage/;   
   $data_stacked[$count]+=$data;
   #$data=$data_stacked[$count] if $self->{ENV}{type}=~/stacked/;
   if ($self->{ENV}{type}=~/stacked/)
   {
    if ($self->{ENV}{type}=~/percentage/)
    {
     #$data_w="$data_o(".((int($data*100))/100)."%)";
     $data_w=((int($data*100))/100)."%";
     $data=100-$data_stacked[$count]+$data;
    }
    else
    {
     #$data=$self->GetRowSum($count-1)-$data_stacked[$count]+$data;
     $data=$self->GetRowSum($row)-$data_stacked[$count]+$data;
    }
   }
   
   my $height=(($data-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);
   $height=int($height*100)/100;
   $height=0 if $height < 0;
   $height=$self->{block_height} if $height > $self->{block_height};
   
   my $width=($count-1)*($self->{block_width}/($self->{grid_x_main_lines}-1));
   
   $width+=($count*10);
   
   print "mam $count\n";
   
   $width=int($width*100)/100;
   

      
   $self->{SVG}->polyline(
	points	=>	
		($self->{block_left}+$width).",".($self->{block_down})." ".
		($self->{block_left}+$width+10).",".($self->{block_down})." ".
		($self->{block_left}+$width+10).",".($self->{block_down}-$height)." ".
		($self->{block_left}+$width).",".($self->{block_down}-$height)." ".
		($self->{block_left}+$width).",".($self->{block_down})." ",
	'stroke-width'	=>"1.5pt",
	'stroke'		=>"black",
#	'stroke-'		=>"black",
	'stroke-linecap'	=>"round",
	'stroke-linejoin'	=>"round",
	'fill'			=>"rgb(".$colors{N0}.")",
	'fill-opacity'	=>"0.5",
#	'stroke-linecap'=>"square",
   ); 
   
  }

}
=cut





 $self->prepare_axis_x_markArea(front=>1);
 $self->prepare_axis_x_mark(front=>1);
 $self->prepare_axis_y_markArea(front=>1);
 $self->prepare_axis_y_mark(front=>1);


 $self->prepare_axis();
 
 $self->prepare_legend_label();
 
 # posledny vystup 
 $self->{SVG_out}=$self->{SVG}->xmlify
 (
#	-namespace => "svg",
	-pubid => "-//W3C//DTD SVG 1.0//EN",
#	-inline   => 1
 );
 return $self->{SVG_out};
}







