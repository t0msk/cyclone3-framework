#!/bin/perl
package Chart::2D;
use Chart;
use strict;

our @ISA=("Chart");






# najprv vykreslim BLOK
sub prepare_block
{
	my $self=shift;
	$self->{block_left}=int($self->{ENV}{x}*0.07);
	$self->{block_right}=int($self->{ENV}{x}-($self->{ENV}{x}*0.20));
	
	if (!$self->{ENV}{show_legend})
	{
		$self->{block_right}=int($self->{ENV}{x}-($self->{ENV}{x}*0.05));
	}
	
	$self->{block_up}=int($self->{ENV}{y}*0.15);
	$self->{block_down}=int($self->{ENV}{y}-($self->{ENV}{y}*0.25));
	
	if ($self->{ENV}{show_legend_label})
	{
		$self->{block_down}=int($self->{ENV}{y}-($self->{ENV}{y}*0.05));
	}
 
	my $g = $self->{SVG}->gradient
	(
		-type => "linear",
		id    => "gr_back01",
		x1    =>"0%",
		y1    =>"0%",
		x2    =>"0%",
		y2    =>"100%",
	);
	$g->stop
	(
		offset=>"0%",
		style=>"stop-color:rgb(179,179,179);stop-opacity:1"
	);
	$g->stop
	(
		offset=>"100%",
		style=>"stop-color:rgb(248,248,248);stop-opacity:1"
	);
 
	my $plus=5;
	$self->{SVG}->polyline(
		points	=>	
			($self->{block_left}+$plus).",".($self->{block_up}+$plus)." ".
			($self->{block_right}+$plus).",".($self->{block_up}+$plus)." ".
			($self->{block_right}+$plus).",".($self->{block_down}+$plus)." ".
			($self->{block_left}+$plus).",".($self->{block_down}+$plus)." ".
			($self->{block_left}+$plus).",".($self->{block_up}+$plus),
		'stroke-width'	=>"0pt" ,
		'stroke'		=>"black",
	#	'stroke-'		=>"black",
		'stroke-linecap'	=>"round",
		'stroke-linejoin'	=>"round",
		'fill'			=>"black",
		'fill-opacity'	=>"0.4",
	#	'fill'			=>"rgb(230,230,230)",
	#	'stroke-linecap'=>"square",
	); 
 
	my $block=$self->{SVG}->polyline(
		points	=>	
			$self->{block_left}.",".$self->{block_up}." ".
			$self->{block_right}.",".$self->{block_up}." ".
			$self->{block_right}.",".$self->{block_down}." ".
			$self->{block_left}.",".$self->{block_down}." ".
			$self->{block_left}.",".$self->{block_up},
		'stroke-width'	=>"0.2pt" ,
		'stroke'		=>"black",
	#	'stroke-'		=>"black",
		'stroke-linecap'	=>"round",
		'stroke-linejoin'	=>"round",
		'fill'			=>"url(#gr_back01)",
	#	'fill'			=>"rgb(230,230,230)",
	#	'stroke-linecap'=>"square",
	); 
	
	$self->{block_width}=$self->{block_right}-$self->{block_left}; # sirka bloku
	$self->{block_height}=$self->{block_down}-$self->{block_up}; # vyska bloku 
	
	return 1;
	
}


sub prepare_axis
{
 my $self=shift; 
 my $block=$self->{SVG}->polyline(
	points	=>	
		$self->{block_left}.",".$self->{block_up}." ".
		$self->{block_left}.",".$self->{block_down}." ".
		$self->{block_right}.",".$self->{block_down}." ",
	'stroke-width'	=>"1.0pt",
	'stroke'		=>"black",
#	'stroke-'		=>"black",
	'stroke-linecap'	=>"round",
	'stroke-linejoin'	=>"round",
#	'fill'			=>"rgb(230,230,230)",
	'fill-opacity'	=>"0",
#	'stroke-linecap'=>"square",
 ); 
 return 1;
}




sub prepare_axis_calculate
{
 my $self=shift;
 
 
 #
 # VYPOCET POCTU LINESOV KOLMYCH NA OS X
 # A VYPOCET MAX A MIN
 # 

 $self->{grid_x_main_lines}=$self->GetNumRows();
 $self->{grid_x_main_lines}++ if $self->{type} eq "columns";
 
 $self->{value_max}=$self->GetMax();
 $self->{value_min}=$self->GetMin(); 
 #die "cannot prepare this Chart, none data inserted in rows" if $self->{value_max}==$self->{value_min}; 
 #$self->{value_min}=0 unless $self->{value_min};
 #$self->{value_max}=$self->{value_min}+10 if $self->{value_max}==$self->{value_min}; 
 
 #print "$self->{value_min} $self->{value_max}\n";
 
 foreach (keys %{$self->{row}{labelH}})
 {$self->{value_max_all}=$self->GetRowSum($_) if $self->{value_max_all}<$self->GetRowSum($_);} 
 $self->{value_max}=$self->{value_max_all} if $self->{ENV}{type}=~/stacked/;
 
 #print "$self->{value_min} $self->{value_max}\n";
   
 if ($self->{ENV}{type}=~/percentage/)
 {
  $self->{value_max}=100;
  $self->{value_min}=0;
  $self->{grid_y_suffix}="%";
 }

	$self->{grid_y_suffix}=$self->{ENV}{grid_y_suffix} if $self->{ENV}{grid_y_suffix};

 # OSETRENIE PRAZDNEHO GRAFU!!!
 $self->{value_min}=0 unless $self->{value_min};
 $self->{value_max}=$self->{value_min}+10 if $self->{value_max}==$self->{value_min}; 
 
 #print "----------- $self->{value_max} - $self->{value_min}\n";
    
 #
 # VYPOCITAM POCET HODNOT KTORE ZOBRAZIM NA OS Y
 #
 #$self->{grid_y_scale_minimum}=$self->{ENV}{grid_y_scale_minimum}; 
 $self->{grid_y_scale_minimum}=$self->{value_min} unless exists $self->{ENV}{grid_y_scale_minimum}; 
 $self->{grid_y_scale_maximum}=$self->{value_max} unless $self->{grid_y_scale_maximum}; 
 
 $self->{grid_y_scale_maximum}=$self->{grid_y_scale_minimum}+10
 	if $self->{grid_y_scale_maximum}==$self->{grid_y_scale_minimum}; 
 
 #print "----------- $self->{grid_y_scale_minimum} - $self->{grid_y_scale_maximum}\n";

 #print "pred spracovanim\n";

 $self->{grid_y_main_lines}=0;#=0;   
 (
  $self->{grid_y_scale_minimum},
  $self->{grid_y_scale_maximum},
  $self->{grid_y_main_lines}
 ) =	$self->CalculateMinMax(
	$self->{grid_y_scale_minimum},
	$self->{grid_y_scale_maximum},
	int($self->{block_height}/40),
	int($self->{block_height}/10),
	);
	
 #print "po spracovani\n";
	
 $self->{grid_y_scale}=$self->{grid_y_scale_maximum}-$self->{grid_y_scale_minimum};
 # VYPOCITAT SPACING!!!
 $self->{grid_y_main_spacing}=$self->{grid_y_scale}/$self->{grid_y_main_lines} unless $self->{grid_y_main_spacing};  
 $self->{block_height_scale} = $self->{grid_y_main_spacing} / ($self->{grid_y_scale} / $self->{block_height});
 
 #print "spacing=$self->{grid_y_main_spacing} $self->{grid_y_main_lines}\n";
 
 
 #
 # VYPOCITAM POCET HODNOT KTORE ZOBRAZIM NA OS X
 # 
 
 my $maximal=int($self->{block_width}/15);
 $self->{grid_x_main_skipfull}=int($self->{grid_x_main_lines}/$maximal);
 $self->{grid_x_main_skipfull}=1 unless $self->{grid_x_main_skipfull};
 $self->{block_width_scale}=$self->{block_width}/($self->{grid_x_main_lines}-1);
 
 #print "spacing=$self->{grid_y_main_spacing} $self->{grid_y_main_lines}\n";
 return 1;
}

















sub prepare_axis_y
{
 my $self=shift;
 

 for (0..$self->{grid_y_main_lines}) # je to X+1
 {
  my $y=int($self->{block_down}-($_*$self->{block_height_scale}));
  if ((($_*$self->{grid_y_main_spacing})+$self->{grid_y_scale_minimum})==0)
  {
   $self->{SVG}->line(
	x1	=>	int($self->{block_left}-30),
	y1	=>	$y,
	x2	=>	int($self->{block_right}-0),
	y2	=>	$y,
	'stroke-width'	=>"1pt" ,
	'stroke'		=>"black",
	'stroke-linecap'	=>"round",
	'stroke-linejoin'	=>"round",
#	'fill'			=>"black",
#	'stroke-linecap'=>"square",
   );  
  }
  else
  {
   $self->{SVG}->line(
	x1	=>	int($self->{block_left}-30),
	y1	=>	$y,
	x2	=>	int($self->{block_right}-0),
	y2	=>	$y,
	'stroke-width'	=>"0.2pt" ,
	'stroke'		=>"black",
	'stroke-linecap'	=>"round",
	'stroke-linejoin'	=>"round",
#	'fill'			=>"black",
#	'stroke-linecap'=>"square",
   );  
  }

#=head1
  $self->{SVG}->text
  (
	x	=>	int($self->{block_left}-5),
	y	=>	$y-2,
        style => {
		'text-anchor'	=>	'end',
		'font-family'	=> 'Verdana',
		'font-size'	=> 10,
		'fill'		=> "black",
        },	
   )->cdata((($_*$self->{grid_y_main_spacing})+$self->{grid_y_scale_minimum}).$self->{grid_y_suffix});
#=cut

 }
 return 1;
} 










sub prepare_axis_x
{
	my $self=shift; 
	#
	# VYKRESLENIE LINESOV NA OSI X
	#
	my $to=$self->{grid_x_main_lines}-1;
	#$to=$self->{grid_x_main_lines}-2 if $self->{type} eq "columns";
	
	my $textsize=$self->{ENV}{show_label_textsize};$textsize=8 unless $textsize;
	
	for (0..$to)
	{
		if (
				(( $_/$self->{grid_x_main_skipfull} == int($_/$self->{grid_x_main_skipfull}) )
				||($_==($self->{grid_x_main_lines}-1)))
				&&  ($self->{ENV}{show_grid_x})
			)
		{
			
			
=head1
			$self->{SVG}->path(
				d=>
				"M".int($self->{block_left}+($_*$self->{block_width_scale}))." ".$self->{block_up}." ".
				"L".int($self->{block_left}+($_*$self->{block_width_scale}))." ".$self->{block_down}." ".
				"L".(int($self->{block_left}+($_*$self->{block_width_scale}))+3)." ".($self->{block_down}+10)." Z",
				'stroke-width'	=>"0.2pt" ,
				'stroke'		=>"black",
				'stroke-linecap'	=>"round",
				'stroke-linejoin'	=>"round",
				'fill' =>"white",
				'fill-opacity' => "0",
			);
=cut
			
			$self->{SVG}->line(
				x1	=>	int($self->{block_left}+($_*$self->{block_width_scale})),
				y1	=>	$self->{block_up},
				x2	=>	int($self->{block_left}+($_*$self->{block_width_scale})),
				y2	=>	$self->{block_down},
				'stroke-width'	=>"0.2pt" ,
				'stroke'		=>"black",
				'stroke-linecap'	=>"round",
				'stroke-linejoin'	=>"round",
			);
			
			if (!$self->{ENV}{show_legend_label})
			{
			
				$self->{SVG}->line(
					x1	=>	int($self->{block_left}+($_*$self->{block_width_scale})),
					y1	=>	$self->{block_down},
					x2	=>	int($self->{block_left}+($_*$self->{block_width_scale}))+7,
					y2	=>	$self->{block_down}+20,
					'stroke-width'	=>"0.2pt" ,
					'stroke'		=>"black",
					'stroke-linecap'	=>"round",
					'stroke-linejoin'	=>"round",
				);
				
				my $null=$self->{row}{label}[$_];
				$null=$_ unless $null;
				$null="" if $self->{type} eq "columns" && $_ == $to;
				
				my $x1=int($self->{block_left}+($_*$self->{block_width_scale})+($textsize/2)+1);
				
				#$x1+=($self->{block_width_scale}/2)-5 if $self->{type} eq "columns";
				
				my $g=$self->{SVG}->g(
					x=>$x1,
					y=>$self->{block_down}+6,
					style =>
					{
						'font-family'	=> 'Verdana',
						'font-size'	=> $textsize,
						'fill'		=> "black",
	#					'writing-mode'	=>	"tb",
					}
				);
				my $txt=$g->text(
					transform=>"translate(".int($x1).",".($self->{block_down}+8).") rotate(70)",
	#				cursor=>"move",
				)->cdata($null);
				
				$g->animate
				(
					'attributeName'=>"font-weight",
					'begin'=>"mouseover",
					'end'=>"mouseout",
	#				'from'=>"900",
	#				'to'=>"900",
					'values'=>"900",
	#				'dur'=>"10s",
					#	'repeatDur'=>"freeze"
					'restart'=>"whenNotActive"
				);
				$g->animate
				(
					'attributeName'=>"font-size",
					'begin'=>"mouseover",
					'end'=>"mouseout",
	#				'from'=>$textsize*1.2,
	#				'to'=>$textsize*1.2,
					'values'=>$textsize*1.2,
	#				'dur'=>"10s",
					#	'repeatDur'=>"freeze"
					'restart'=>"whenNotActive"
				);
			
			}
			
			
		}
		else
		{
			$self->{SVG}->line(
				x1	=>	int($self->{block_left}+($_*$self->{block_width_scale})),
				y1	=>	$self->{block_down}-10,
				x2	=>	int($self->{block_left}+($_*$self->{block_width_scale})),
				y2	=>	$self->{block_down}+5,
				'stroke-width'	=>"0.1pt" ,
				'stroke'		=>"black",
				'stroke-linecap'	=>"round",
				'stroke-linejoin'	=>"round",
			);  
		}  
	}
	return 1;
} 



sub prepare_legend_label
{
	my $self=shift;
	
	return undef unless $self->{ENV}{show_legend_label};
	
	#print "znova\n";
	
	my $to=$self->{grid_x_main_lines}-1;
	#$to=$self->{grid_x_main_lines}-2 if $self->{type} eq "columns";
	
	my $textsize=$self->{ENV}{show_label_textsize};
	$textsize=int($self->{block_width_scale}/2) unless $textsize;
	$textsize=10 if $textsize>10;
	
	for (0..$to)
	{
		#main::_log("row $_");
		if (
				( $_/$self->{grid_x_main_skipfull} == int($_/$self->{grid_x_main_skipfull}))
				||($_==($self->{grid_x_main_lines}-1))
			)
		{
			
			#main::_log("kreslim");
			
			my $null=$self->{row}{label}[$_];
			$null=$_ unless $null;
			$null="" if $self->{type} eq "columns" && $_ == $to;
			
			my $x1=int($self->{block_left}+($_*$self->{block_width_scale})+($self->{block_width_scale}/2)+($textsize/4));
			
			#$x1+=($self->{block_width_scale}/2)-5 if $self->{type} eq "columns";
			
			#print "kreslim\n";
			
			my $g=$self->{SVG}->g(
				x=>$x1,
				y=>$self->{block_down},
				style =>
				{
					'font-family'	=> 'Verdana',
					'font-size'	=> $textsize,
					'fill'		=> "black",
#					'stroke-width'=>"0.5pt",
#					'stroke'=>"black",
#					'font-weight' => "bold"
#					'writing-mode'	=>	"tb",
				}
			);
			my $txt=$g->text(
				transform=>"translate(".int($x1).",".($self->{block_down}-6).") rotate(-90)",
#				cursor=>"move",
			)->cdata($null);
			
#=head1
			$g->animate
			(
				'attributeName'=>"font-weight",
				'begin'=>"mouseover",
				'end'=>"mouseout",
#				'from'=>"900",
#				'to'=>"900",
				'values'=>"900",
#				'dur'=>"10s",
				#	'repeatDur'=>"freeze"
				'restart'=>"whenNotActive"
			);
=head1
			$g->animate
			(
				'attributeName'=>"font-size",
				'begin'=>"mouseover",
				'end'=>"mouseout",
#				'from'=>$textsize*1.2,
#				'to'=>$textsize*1.2,
				'values'=>$textsize*1.2,
#				'dur'=>"10s",
				#	'repeatDur'=>"freeze"
				'restart'=>"whenNotActive"
			);
=cut
			
		}
	}
	
	
	return 1;
}









sub prepare_axis_x_mark
{
 my $self=shift; 
 my %env=@_;

 for (0..$self->{grid_x_main_lines}-1)
 {
  if 	($self->{row}{markH}{$self->{row}{label}[$_]}) # MARK
  {
  
   next if $self->{row}{markH}{$self->{row}{label}[$_]}{front} && !$env{front};
   next if !$self->{row}{markH}{$self->{row}{label}[$_]}{front} && $env{front};
  
   my $size=$self->{row}{markH}{$self->{row}{label}[$_]}{size};$size=1 unless $size;
   
   my $color=$self->{row}{markH}{$self->{row}{label}[$_]}{color};
   $color="black" unless $color;
   $color="black" unless $Chart::colors::table{$color};  
   
   $self->{SVG}->line(
	x1	=>	int($self->{block_left}+($_*$self->{block_width_scale})),
	y1	=>	$self->{block_up}-7,
	x2	=>	int($self->{block_left}+($_*$self->{block_width_scale})),
	y2	=>	$self->{block_down},
	'stroke-width'	=>$size."pt" ,
	'stroke'		=>"rgb(".$Chart::colors::table{$color}{N2}.")",
	'stroke-opacity'	=>"1",
	'stroke-linecap'	=>"round",
	'stroke-linejoin'	=>"round",
   );
   $self->{SVG}->circle(
	cx=>int($self->{block_left}+($_*$self->{block_width_scale})),
	cy=>$self->{block_up}-10,
	r=>2,
	'fill'		=>	"white",
	'stroke'		=>"rgb(".$Chart::colors::table{$color}{N2}.")",
	'stroke-width'	=>	"1pt",
   );
   if ($self->{row}{markH}{$self->{row}{label}[$_]}{show_label})
   {
    my $null=$self->{row}{label}[$_];
    $null=$_ unless $null;   
    $self->{SVG}->text(
	x=>int($self->{block_left}+($_*$self->{block_width_scale}))+5,
	y=>$self->{block_up}-7,
        style => {
		'font-family'	=> 'Verdana',
		'font-size'		=> 8,
		'fill'			=> "black",
		
        }
     )->cdata($null);
   }
  }  
 }

 return 1;
} 












sub prepare_axis_y_mark
{
 my $self=shift; 
 my %env=@_;

 foreach my $mark (keys %{$self->{ValueMarkH}})
 {
  next if $self->{ValueMarkH}{$mark}{front} && !$env{front};
  next if !$self->{ValueMarkH}{$mark}{front} && $env{front};  
  next if $mark>$self->{grid_y_scale_maximum};
  next if $mark<$self->{grid_y_scale_minimum};
  
  my $size=$self->{ValueMarkH}{$mark}{size};$size=1 unless $size;
  
  my $color=$self->{ValueMarkH}{$mark}{color};
  $color="black" unless $color;
  $color="black" unless $Chart::colors::table{$color};  
    
  my $height=(($mark-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);
  $height=int($height*100)/100;
    
  if (!$self->{ValueMarkH}{$mark}{right})
  {
   $self->{SVG}->line(
	x1	=>	8,
	y1	=>	$self->{block_down}-$height,
	x2	=>	$self->{block_right},
	y2	=>	$self->{block_down}-$height,
	'stroke-width'	=>$size."pt" ,
	'stroke'		=>"rgb(".$Chart::colors::table{$color}{N1}.")",
	'stroke-linecap'	=>"round",
	'stroke-linejoin'	=>"round",
   );
   $self->{SVG}->circle(
	cx=>8,
	cy=>$self->{block_down}-$height,
	r=>2,
	'fill'			=>	"white",
	'stroke'		=>	"rgb(".$Chart::colors::table{$color}{N1}.")",
	'stroke-width'	=>	"1pt",
   );
  }
  else
  {
   $self->{SVG}->line(
	x1	=>	$self->{block_left},
	y1	=>	$self->{block_down}-$height,
	x2	=>	$self->{block_right}+10,
	y2	=>	$self->{block_down}-$height,
	'stroke-width'	=>$size."pt" ,
	'stroke'		=>"rgb(".$Chart::colors::table{$color}{N1}.")",
	'stroke-linecap'	=>"round",
	'stroke-linejoin'	=>"round",
   );
   $self->{SVG}->circle(
	cx=>$self->{block_right}+10,
	cy=>$self->{block_down}-$height,
	r=>2,
	'fill'			=>	"white",
	'stroke'		=>	"rgb(".$Chart::colors::table{$color}{N1}.")",
	'stroke-width'	=>	"1pt",
   );
  }
  
  if ($self->{ValueMarkH}{$mark}{show_label})
  {
   my $null=$self->{ValueMarkH}{$mark}{show_label_text};
   $null=$mark unless $null;
   
   #$null=$_ unless $null;   
   if (!$self->{ValueMarkH}{$mark}{right})
   {
     $self->{SVG}->text(
	x=>5,
	y=>$self->{block_down}-$height-5,
        style => {
#		'text-anchor'	=> 'end',
		'font-family'	=> 'Verdana',
		'font-size'		=> 8,
		'fill'			=> "black",
        }
      )->cdata($null);  
    }
    else
    {
     $self->{SVG}->text(
		x=>$self->{block_right}+8,
		y=>$self->{block_down}-$height-4,
        style => {
#		'text-anchor'	=> 'end',
		'font-family'	=> 'Verdana',
		'font-size'		=> 8,
		'fill'			=> "black",
        }
      )->cdata($null);  
    }
  }
  
  
 }
 

 return 1;
} 


sub prepare_axis_y_markArea
{
 my $self=shift; 
 my %env=@_;

 foreach my $mark (keys %{$self->{ValueMarkAH}})
 {
  if ($mark eq "_start")
  {
   die "minimal value not defined" unless exists $self->{grid_y_scale_minimum};
   my $newmark=$self->{grid_y_scale_minimum};
   #die "minimal value not defined" unless $newmark;
   %{$self->{ValueMarkAH}{$newmark}}=%{$self->{ValueMarkAH}{$mark}};
   delete $self->{ValueMarkAH}{$mark};
   $mark=$newmark;
  }  
  next if $self->{ValueMarkAH}{$mark}{front} && !$env{front};
  next if !$self->{ValueMarkAH}{$mark}{front} && $env{front};  
  
  my $color=$self->{ValueMarkAH}{$mark}{color};
  $color="yellow" unless $color;
  $color="yellow" unless $Chart::colors::table{$color};
  
  
  $self->{ValueMarkAH}{$mark}{end}=$self->{grid_y_scale_maximum} 
  	if ($self->{ValueMarkAH}{$mark}{end}>$self->{grid_y_scale_maximum} || !$self->{ValueMarkAH}{$mark}{end});
    
  my $height0=(($mark-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);
  $height0=int($height0*100)/100;
  $height0=0 if $height0 < 0;
  $height0=$self->{block_height} if $height0 > $self->{block_height};
  
  my $height1=(($self->{ValueMarkAH}{$mark}{end} - $self->{grid_y_scale_minimum}) / ($self->{grid_y_scale}/100)) * ($self->{block_height}/100);
  $height1=int($height1*100)/100;
  $height1=0 if $height1 < 0;
  $height1=$self->{block_height} if $height1 > $self->{block_height};
  
  
	my $opacity=$self->{ValueMarkAH}{$mark}{'opacity'};
		$opacity="0.1" unless $opacity;
  
  
  $self->{SVG}->polyline(
	points	=>	
		$self->{block_left}.",".($self->{block_down}-$height1)." ".
		$self->{block_right}.",".($self->{block_down}-$height1)." ".
		$self->{block_right}.",".($self->{block_down}-$height0)." ".
		$self->{block_left}.",".($self->{block_down}-$height0),
#	'stroke-width'	=>"1.5pt",
#	'stroke'		=>"black",
#	'stroke-linecap'	=>"round",
#	'stroke-linejoin'	=>"round",
	'fill'			=>"rgb(".$Chart::colors::table{$color}{B1}.")",
	'fill-opacity'	=>$opacity,
#	'stroke-linecap'=>"square",
  );  
  
  
  
 }
 return 1;
} 



sub prepare_axis_x_markArea
{
 my $self=shift; 
 my %env=@_;

 

 
 foreach my $mark (keys %{$self->{row}{markAH}})
 {
  if ($mark eq "_start")
  {
   my $newmark=$self->{row}{label}[0];
   
   die "first label of row not defined" unless $newmark;
   %{$self->{row}{markAH}{$newmark}}=%{$self->{row}{markAH}{$mark}};
   delete $self->{row}{markAH}{$mark};
   $mark=$newmark;
  }
 
  next if $self->{row}{markAH}{$mark}{front} && !$env{front};
  next if !$self->{row}{markAH}{$mark}{front} && $env{front};  
  
  my $row_start=$self->GetNumRow($mark);
  
  
  my $row_end=$self->GetNumRows()-1;
  
  $row_end=$self->GetNumRow($self->{row}{markAH}{$mark}{end}) if $self->{row}{markAH}{$mark}{end};
  
#  my $size=$self->{row}{markAH}{$mark}{size};$size=1 unless $size;
  
  my $color=$self->{row}{markAH}{$mark}{color};
  $color="yellow" unless $color;
  $color="yellow" unless $Chart::colors::table{$color};
  
  print "mam farbu $color a end je $row_end $self->{row}{markAH}{$mark}{end}\n";
  
  my $row_x1=int($self->{block_left}+($row_start*$self->{block_width_scale}));
  my $row_x2=int($self->{block_left}+($row_end*$self->{block_width_scale}));


	my $opacity=$self->{row}{markAH}{$mark}{'opacity'};
		$opacity="0.2" unless $opacity;

#  my $color=$self->{row}{markH}{$self->{row}{label}[$_]}{color};$color="black" unless $color;
  $self->{SVG}->polyline(
	points	=>	
		$row_x1.",".($self->{block_up})." ".
		$row_x2.",".($self->{block_up})." ".
		$row_x2.",".$self->{block_down}." ".
		$row_x1.",".$self->{block_down},
#	'stroke-width'	=>"1.5pt",
#	'stroke'		=>"black",
#	'stroke-linecap'	=>"round",
#	'stroke-linejoin'	=>"round",
	'fill'			=>"rgb(".$Chart::colors::table{$color}{N2}.")",
	'fill-opacity'	=>$opacity,
#	'stroke-linecap'=>"square",
  );  
 }

 return 1;
} 






 

1;
