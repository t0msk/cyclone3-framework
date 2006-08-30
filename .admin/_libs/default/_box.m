###########################
# HTML PROCESSOR
###########################


sub box_create2
{
 my $name=shift;
 my %env=@_;
 $env{icon}="<img src=\"$tom::H_media/grf/admin/win_top_0_logo0.gif\" border=0 align=absmiddle>" unless $env{icon};
 $env{width}="140" unless $env{width};
 $env{height}="200" unless $env{height};
 $env{color_border0}="#000000" unless $env{color_border0};
 $env{color_title0}="#003399" unless $env{color_title0};
 $env{color_base0}="#EDF2FC" unless $env{color_base0};

 $env{resize}=1 unless $env{resize};

 my $buttons;



 my $resize;
 if ($env{resize})
 {
 $resize=<<"HEADER";
		<div style="float:right;">
			<img src="$tom::H_media/grf/admin/t.gif" drag_here="resize" style="height: 10px; width: 10px; cursor:se-resize;filter:Alpha(Opacity:50);" border=0 onmouseover="this.src='$tom::H_media/grf/admin/btn_mover.gif';" onmouseout="this.src='$tom::H_media/grf/t.gif';" width=10 height=10>
		</div>
HEADER
 }

my $html=<<"HEADER";
<div class="default-box">
	<div drag_here class="default-box-header">
		<div style="float: right">
			<img src="$tom::H_media/grf/admin/win_top_0_btn1.gif" class="box-header-button" border=0 onclick="box_erase();">
		</div>
		$env{icon}&nbsp;$name
	</div>
	<div class="default-box-in" style="width:$env{width};">
		$env{html}
	</div>
</div>
HEADER

 return $html;
}










sub article_box_create
{
 my $name=shift;
 my %env=@_;
 $env{icon}="<img src=\"$tom::H_media/grf/admin/win_top_0_logo0.gif\" border=0 align=absmiddle>" unless $env{icon};
 $env{width}="140" unless $env{width};
 $env{height}="200" unless $env{height};
 $env{color_border0}="#000000" unless $env{color_border0};
 $env{color_title0}="#003399" unless $env{color_title0};
 $env{color_base0}="#EDF2FC" unless $env{color_base0};

 $env{resize}=1 unless $env{resize};
 
 my $buttons;



 my $resize;
 if ($env{resize})
 {
 $resize=<<"HEADER";
<div align=right>
	<img src="$tom::H_media/grf/admin/t.gif" drag_here="resize" style="position:absolute;cursor:se-resize;filter:Alpha(Opacity:50);" border=0 onmouseover="this.src='$tom::H_media/grf/admin/btn_mover.gif';" onmouseout="this.src='$tom::H_media/grf/t.gif';" width=10 height=10><BR>
</div>
HEADER
 }

my $html=<<"HEADER";
<table width=100% cellspacing=0 cellpadding=0 border=0>
	<tr>
		<td>
			<div drag_here class="article-box-header" onMouseDown="lastOpenedArticleId='$env{article_id}';">
				<div style="float: right">
					<img src="$tom::H_media/grf/admin/win_top_0_btn0.gif" class="box-header-button" border=0 onclick="var subid=getElementById('article-box-in-$env{article_id}'); if (subid.style.display=='block'){subid.style.display='none';}else{subid.style.display='block';}">
					<img src="$tom::H_media/grf/admin/win_top_0_btn1.gif" class="box-header-button" border=0 onclick="box_erase();">
				</div>
				$env{icon}&nbsp;$name
			</div>
			<div id="article-box-in-$env{article_id}" class="article-box-in" style="display:block;">
				$env{html}
			</div>
		</td>
	</tr>
</table>
HEADER








my $htmlx=<<"HEADER";
<div drag="range" $div_plus class="article-box" id="box_$env{id}" style="position: absolute; z-index:$env{zindex}; width:140px; height:11px; top:$env{top}px; left:$env{left}px;">
	<div class="article-box-header" drag_here onMouseDown="lastOpenedArticleId='$env{article_id}';">
		<div style="float: right">
			<img src="$tom::H_media/grf/admin/win_top_0_btn0.gif" class="box-header-button" border=0 onclick="var subid=getElementById('article-box-in-$env{article_id}'); if (subid.style.display=='block'){subid.style.display='none';}else{subid.style.display='block';}">
			<img src="$tom::H_media/grf/admin/win_top_0_btn1.gif" class="box-header-button" border=0 onclick="box_erase();">
		</div>
		$env{icon}&nbsp;$name
	</div>
	<div id="article-box-in-$env{article_id}" class="article-box-in" style="display: block">
$env{html}
	</div>
		$resize
</div>
HEADER

my $htmlxx=<<"HEADER";
<table width=100% height=100% cellspacing=1 cellpadding=0 border=0>
<tr><td>

 <table width=100% cellspacing=1 cellpadding=0 border=0 bgcolor="#002040"><tr><td>
	<table width=100% height=100% cellspacing=0 cellpadding=0 border=0 bgcolor="#0B63F1" style="cursor:hand;">
	<tr>
	 <td drag_here>$env{icon}</td>
	 <td drag_here width=100%>
		<table width=100% height=100% cellspacing=0 cellpadding=0 border=0 onMouseDown="lastOpenedArticleId='$env{article_id}';">
		 <tr><td bgcolor="#0B5FDE"><img src=t.gif width=1 height=1 border=0><BR></td></tr>
		 <tr>
		  <td style="FONT:bold 10px Verdana;COLOR:white;" nowrap>&nbsp;$name</td>
		 </tr>
		 <tr><td bgcolor="#0036BB"><img src=t.gif width=1 height=1 border=0><BR></td></tr>
		</table>
	 </td>
	 <td>
	  <img src="$tom::H_media/grf/admin/win_top_0_btn0.gif" border=0 onclick="if (GetDrag(this).all['article-box-in'].style.display=='block'){GetDrag(this).all['article-box-in'].style.display='none';}else{GetDrag(this).all['article-box-in'].style.display='block';}"><BR>
	 </td>
	 <td>
	  <img src="$tom::H_media/grf/admin/win_top_0_btn1.gif"
		border=0
		onclick="box_erase();"><BR>
	 </td>
	</tr>
	</table>
 </td></tr></table>

</td></tr>
<tr><td>

 <div id="box_sub" style="display:block;">
 <table width=100% height=100% cellspacing=1 cellpadding=2 border=0 bgcolor="#000000"><tr height=100%><td bgcolor="#0B63F1" valign=top>$env{html}</td></tr></table>
 </div>

</td></tr>
<tr><td>

$resize

</td></tr>
</table>
HEADER

 return $html;
}
















sub box_create_new # initialize
{
 my $name=shift;
 my %env=@_;
 $env{icon}="<img src=\"$tom::H_media/grf/admin/win_top_0_logo0.gif\" border=0 align=absmiddle>" unless $env{icon};
 $env{id}=$name unless $env{id};
 $env{zindex}="0" unless $env{zindex};
 $env{color_base0}="#0B63F1" unless $env{color_base0};

# $env{resize}=1 unless $env{resize};
 $env{display}="block" unless $env{display};

 my $autoopen="none";

 my $buttons;

 my $div_plus;
 if ($env{autoopen})
 {
  $div_plus=<<"HEADER";
autoopen="$autoopen"
onmouseover="if (this.autopen == 'none'){this.all['box_sub'].style.display='block';}"
onmouseout="if (this.autopen == 'none'){this.all['box_sub'].style.display='none';}"
HEADER
  $buttons.=<<"HEADER";
  <img class="box-header-button"  src="$tom::H_media/grf/admin/win_top_0_btn2.gif" border=0 onclick=" if (GetDrag(this).autopen == 'none') {GetDrag(this).autopen='block';} else {GetDrag(this).autopen='none';}"><BR>
HEADER
 }

 $div_plus.=" drag_save=\"True\"" if $env{save};

 if ($env{resize})
 {$buttons.=<<"HEADER";
  <img class="box-header-button" src="$tom::H_media/grf/admin/win_top_0_btn0.gif" border=0 onclick="if (GetDrag(this).all['box_sub'].style.display=='block') {GetDrag(this).all['box_sub'].style.display='none';} else {GetDrag(this).all['box_sub'].style.display='block';}">
HEADER
 }


 if ($env{close})
 { $buttons.=<<"HEADER";
 <img class="box-header-button" src="$tom::H_media/grf/admin/win_top_0_btn1.gif" border=0 onclick="box_erase();"><BR>
HEADER
 }



 my $resize;
 if ($env{resize})
 {
 $resize=<<"HEADER";
<div align=right>
<img src="$tom::H_media/grf/admin/t.gif" drag_here="resize" style="position:absolute;cursor:se-resize;filter:Alpha(Opacity:50);" border=0 onmouseover="this.src='$tom::H_media/grf/admin/btn_mover.gif';" onmouseout="this.src='$tom::H_media/grf/t.gif';" width=10 height=10><BR>
</div>
HEADER
 }



my $html=<<"HEADER";
<div drag="range" $div_plus class="menu-box" id="box_$env{id}" style="position: absolute; z-index:$env{zindex}; width:140px; height:11px; top:$env{top}px; left:$env{left}px;">
	<div class="menu-box-header" drag_here><div style="float: right">$buttons</div>$env{icon}&nbsp;$name</div>
	<div class="menu-box-in">
		<div id="box_sub" style="display:$env{display};">
$env{html}
		</div>
		$resize
	</div>
</div>
HEADER

my $original_html=<<"HEADER";
<div drag="range"
	$div_plus
	id="box_$env{id}"
	style="	position: absolute;
		z-index:$env{zindex};
		width:140px;
		height:11px;
	    	top:$env{top}px;
	    	left:$env{left}px;">

<table width=100% height=100% cellspacing=0 cellpadding=0 border=0>
<tr><td>

 <table width=100% cellspacing=1 cellpadding=0 border=0 bgcolor="#204080"><tr><td>
	<table width=100% height=100% cellspacing=0 cellpadding=0 border=0 bgcolor="#0B63F1" style="cursor:hand;">
	<tr>
	 <td drag_here>$env{icon}</td>
	 <td drag_here width=100%>
		<table width=100% height=100% cellspacing=0 cellpadding=0 border=0>
		 <tr><td bgcolor="#0B5FDE"><img src=t.gif width=1 height=1 border=0><BR></td></tr>
		 <tr>
		  <td style="FONT:bold 10px Verdana;COLOR:white;" nowrap>&nbsp;$name</td>
		 </tr>
		 <tr><td bgcolor="#0036BB"><img src=t.gif width=1 height=1 border=0><BR></td></tr>
		</table>
	 </td>
	$buttons
	</tr>
	</table>
 </td></tr></table>

</td></tr>
<tr height=100%><td height=100% valign=top style="filter:Alpha(Opacity:$env{alpha});">

 <div id="box_sub" style="display:$env{display};">
 <table width=100% height=100% cellspacing=1 cellpadding=2 border=0 bgcolor="#204080"><tr height=100%><td bgcolor="$env{color_base0}" valign=top>$env{html}</td></tr></table>
 </div>

</td></tr>
<tr><td>

$resize

</td></tr>
</table>

</div>
HEADER


 return $html;
}

















sub box_create # initialize
{
 my $name=shift;
 my %env=@_;
 $env{drag}="range" unless $env{drag};
 $env{drag_open}="false";
 $env{drag_open}="true" if $env{autoopen};
 $env{id}=$name unless $env{id};
 $env{width}="140" unless $env{width};
 $env{height}="200" unless $env{height};
 $env{top}="100" unless $env{top};
 $env{left}="100" unless $env{left};
 $env{zindex}="0" unless $env{zindex};
 $env{alpha}="filter:Alpha(Opacity:$env{alpha});" if $env{alpha};
 $env{display_start}="none" unless $env{display_start};
 $env{cellspacing0}="0" unless defined $env{cellspacing0};
 $env{cellpadding0}="0" unless defined $env{cellpadding0};
 $env{cellspacing1}="0" unless defined $env{cellspacing1};
 $env{cellpadding1}="0" unless defined $env{cellpadding1};
 $env{cellspacing2}="1" unless defined $env{cellspacing2};
 $env{cellpadding2}="1" unless defined $env{cellpadding2};
 $env{height_start}="10" unless $env{height_start};
 $env{color_border0}="#003366" unless $env{color_border0};
 $env{color_base0}="#EDF2FC" unless $env{color_base0};

# $env{resize}=True unless $env{resize};
 

# if (defined $env{save})
# {
#  my $db_micro = $dbh->Query("SELECT ID,admin,type,variable,value,about,version FROM _admin_save WHERE admin='$ENV{REMOTE_USER}' AND type='box' AND variable='box_".$env{id}."' AND version='$env{version}' LIMIT 1");
#  if (my @db_micro_line=$db_micro->FetchRow())
#  {
#   my $form_box;
#   foreach (split('&',$db_micro_line[4]))
#   {
#    my ($a1,$a2)=split('=',$_,2);
#	$form_box{$a1}=$a2;
#   }
#   $env{left}=$form_box{left};
#   $env{top}=$form_box{top};
##   $env{height_start}=$form_box{height};
##   $env{height_start}=~s|px||;
#   if ($form_box{auto_open} ne "true")
#   {$env{display_start}=$form_box{box_sub};}
#   if ($env{autoopen}){$env{drag_open}=$form_box{auto_open};}
##   $env{width}=$form_box{width};
##   $env{width}=~s|px||;
##   $env{width}=$form_box{width};
##   $env{width}=~s|px||;
#  }
# }

 $env{div}.=" drag_save=\"True\"" if $env{save};
 
 $env{div}.=" drag_version=\"$env{version}\"" if $env{version};
 
 $env{div}.=" onmouseover=\"if (box_$env{id}.drag_open=='true'){box_$env{id}.style.height=$env{height};box_$env{id}.style.zIndex=zIndex_g+1;box_$env{id}.all['box_sub'].style.display='block';}\" onmouseout=\"if (box_$env{id}.drag_open=='true'){box_$env{id}.style.height=11;box_$env{id}.style.zIndex=zIndex_g+1;box_$env{id}.all['box_sub'].style.display='none';}\"" if defined $env{autoopen};
 
my $buttons;

if ($env{new})
{
 $buttons.=<<" HEADER";
	<td><img src="$tom::H_media/grf/admin/win_top_0_btn5.gif" border=0 onclick="$env{new}"><BR></td>
 HEADER
}

if ($env{autoopen})
{
 $buttons.=<<" HEADER";
	<td><img src="$tom::H_media/grf/admin/win_top_0_btn2.gif" border=0 onclick="if (box_$env{id}.drag_open=='true'){box_$env{id}.drag_open='false';}else{box_$env{id}.drag_open='true';}"><BR></td>
 HEADER
}
if ($env{open})
{
 $buttons.=<<" HEADER";
	<td><img src="$tom::H_media/grf/admin/win_top_0_btn0.gif" border=0 onclick="if (box_$env{id}.all['box_sub'].style.display=='none'){box_$env{id}.style.height=$env{height};box_$env{id}.all['box_sub'].style.display='block';}else{box_$env{id}.all['box_sub'].style.display='none';box_$env{id}.style.height=10;box_$env{id}.style.width=$env{width};}"><BR></td>
 HEADER
}
if ($env{close})
{
 $buttons.=<<" HEADER";
	<td><img src="$tom::H_media/grf/admin/win_top_0_btn1.gif" border=0 onclick="box_erase();"><BR></td>
 HEADER
}

my $resize;
if ($env{resize})
{
 $resize=<<"HEADER";
<tr><td align=right><img src="$tom::H_media/grf/t.gif" width=1 height=1 border=0><BR><img src="$tom::H_media/grf/t.gif" drag_here="resize" style="cursor:se-resize;filter:Alpha(Opacity:50);" border=0 width=15 height=15 onmouseover="this.src='$tom::H_media/grf/admin/btn_mover.gif';" onmouseout="this.src='$tom::H_media/grf/t.gif';"><BR></td></tr>
HEADER
}

my $html=<<"HEADER";
<div id="box_$env{id}"
	style="	display: block;
			position: absolute;
			top:$env{top}px;
			left:$env{left}px;
			width:$env{width}px;
			height:$env{height_start}px;
			z-index:$env{zindex};"
			drag="$env{drag}"
			drag_open="$env{drag_open}"
			$env{div}>
<table width=100% height=100% cellspacing=$env{cellspacing0} cellpadding=$env{cellpadding0} border=0>
<tr height=14><td>
	<table width=100% height=100% cellspacing=$env{cellspacing1} cellpadding=$env{cellpadding1} 
			border=0 bgcolor="#0B63F1" style="cursor:hand;">
	<tr>
	<td><img src="$tom::H_media/grf/admin/win_top_0_logo0.gif" border=0><BR></td>
	<td width=100% drag_here>
	
	
		<table width=100% height=100% cellspacing=0 cellpadding=0 border=0>
		 <tr><td bgcolor="#0B5FDE"><img src=t.gif width=1 height=1 border=0><BR></td></tr>
		 <tr>
		  <td style="FONT:bold 10px Verdana;COLOR:white;" nowrap>&nbsp;$name</td>
		 </tr>
		 <tr><td bgcolor="#0036BB"><img src=t.gif width=1 height=1 border=0><BR></td></tr>
		</table>
	
	
	</td>
	<td><img src="$tom::H_media/grf/admin/win_top_0_del.gif" border=0><BR></td>
	$buttons
	<td><img src="$tom::H_media/grf/admin/win_top_0_end.gif" border=0><BR></td>
	</tr>
	</table>
</td></tr>
<tr height=100%><td style="$env{alpha}" height=100% valing=top><table height=100% width=100% cellspacing=$env{cellspacing2} cellpadding=$env{cellpadding2} border=0 bgcolor=$env{color_border0}><tr height=100%><td bgcolor=$env{color_base0} valign=top height=100%><div id="box_sub" style="display:$env{display_start};">$env{html}</div></td></tr></table></td></td></tr>
$resize
</table>
</div>
HEADER


 return $html;
}



sub box_create2_old
{
 my $name=shift;
 my %env=@_; 
 $env{icon}="<img src=\"$tom::H_media/grf/admin/win.gif\" border=0 align=absmiddle>" unless $env{icon};
 $env{width}="140" unless $env{width};
 $env{height}="200" unless $env{height};
 $env{color_border0}="#000000" unless $env{color_border0};
 $env{color_title0}="#003399" unless $env{color_title0};
 $env{color_base0}="#EDF2FC" unless $env{color_base0};
 $env{id}=$current_time;

 $env{resize}=1 unless $env{resize};

 my $buttons;
 
if ($env{new})
{
 $buttons.=<<" HEADER";
	<td><img src="$tom::H_media/grf/admin/win_top_0_btn5.gif" border=0 onclick="$env{new}"><BR></td>
 HEADER
}

my $resize;
if ($env{resize})
{
 $resize=<<"HEADER";
<tr><td align=right><img src="$tom::H_media/grf/t.gif" width=1 height=1 border=0><BR><img src="$tom::H_media/grf/t.gif" drag_here="resize" style="cursor:se-resize;filter:Alpha(Opacity:50);" border=0 width=15 height=15 onmouseover="this.src='$tom::H_media/grf/admin/btn_mover.gif';" onmouseout="this.src='$tom::H_media/grf/t.gif';"><BR></td></tr>
HEADER
}

#<table width=140 height=$env{height} cellspacing=0 cellpadding=0 border=0>
 
my $html=<<"HEADER";
<table width=100% height=100% cellspacing=0 cellpadding=0 border=0>
<tr height=14><td>
	<table width=100% height=100% cellspacing=0 cellpadding=0 
			border=0 bgcolor="#0B63F1" baackground="$tom::H_media/grf/admin/win_top_0_back.gif" style="cursor:hand;">
	<tr>
	<td><img src="$tom::H_media/grf/admin/win_top_0_logo0.gif" border=0><BR></td>
	<td nowrap width=100% drag_here>

		<table width=100% height=100% cellspacing=0 cellpadding=0 border=0>
		 <tr><td bgcolor="#0B5FDE"><img src=t.gif width=1 height=1 border=0><BR></td></tr>
		 <tr>
		  <td style="FONT:bold 10px Verdana;COLOR:white;" nowrap>$name</td>
		 </tr>
		 <tr><td bgcolor="#0036BB"><img src=t.gif width=1 height=1 border=0><BR></td></tr>
		</table>	
	
	</td>
	<td><img src="$tom::H_media/grf/admin/win_top_0_del.gif" border=0><BR></td>
	$buttons
	<td><img src="$tom::H_media/grf/admin/win_top_0_btn0.gif" border=0 onclick="if (box_$env{id}_0.style.display=='none'){box_$env{id}_0.style.display='block';}else{box_$env{id}_0.style.display='none';checkDrag(this).style.height=11;checkDrag(this).style.width=$env{width};}"><BR></td>	
	<td><img src="$tom::H_media/grf/admin/win_top_0_btn1.gif" border=0 onclick="box_erase();"><BR></td>
	<td><img src="$tom::H_media/grf/admin/win_top_0_end.gif" border=0><BR></td>
	</tr>
	</table>
</td></tr>
<tr height=100%><td valign=top height=100%><table width=100% height=100% cellspacing=1 border=0 cellpadding=1 bgcolor=$env{color_border0}><tr height=100%><td bgcolor=$env{color_base0} height=100% valing=top><div id="box_$env{id}_0" style="FONT:12px Verdana;display:$env{display_start};width:$env{width}px;">$env{html}</div></td></tr></table></td></td></tr>
$resize
</table>
HEADER

 return $html;
}


































sub menu_create # initialize
{
 my %env=@_;
 $env{'link_base'}="core.pl?" unless $env{'link_base'};
 my $html="";
 foreach (sort keys %{$env{'link'}})
 {
  my $name=$_;
  my $icon="t.gif";
  (undef,$name,$icon)=split('\|',$_) if $_=~/\|/;
  $icon="t.gif" unless $icon;
  my @ref=split('\|',$env{link}{$_});
  $html.="			<div class=\"menu-box-link\" onmouseover=\"this.className='menu-box-link-hi';\" onmouseout=\"this.className='menu-box-link';\" onclick=\"load('$env{'link_base'}$ref[0]');$ref[1]\"><img src=\"$tom::H_media/grf/admin/$icon\" border=0>$name</div>\n";
 }
 return $html;
}



sub menu_create2 # initialize
{
 my %env=@_;
 $env{'color_back1'}="white" unless $env{'color_back1'};
 $env{'color_font1'}="white" unless $env{'color_font1'};
# return undef unless $env{'link'};
 my $html="<table width=100% cellspacing=0 cellpadding=1 border=0>";
# $html.="<tr height=5><td></td></tr>";
 foreach (sort keys %{$env{'link'}})
 {
  my $name=$_;
  my $icon="t.gif";
  (undef,$name,$icon)=split('\|',$_) if $_=~/\|/;
  $icon="t.gif" unless $icon;
  $html.="<div class=\"menu-box-link\" onmouseover=\"this.className='menu-box-link-hi';\" onmouseout=\"this.className='menu-box-link';\" onclick=\"$env{link}{$_}\"><img src=\"$tom::H_media/grf/admin/$icon\" border=0>&nbsp;$name</div>";
 }
 $html.="</table>";
 return $html;
}


sub select_create
{
 my %env=@_;
 # name
 # value
 # maxlength
 # width
 # select
 $env{width1}=$env{width} unless $env{width1};
 $env{height}="100" unless $env{height};
 if (defined $env{drag_resizeX})
 {
  $env{drag_resizeX}-=12;
  $env{drag_resizeX}=" drag_resizeX='$env{drag_resizeX}' ";
 }

 my $html=<<"HEADER";
<div class="dropdown">
	<input type=text id="VALUE" name="$env{name}" value="$env{value}" maxlenght=$env{maxlength} style="width:$env{width}px;" $env{drag_resizeX}>
	<input type=button value="+" class="dropdown-drop" style="cursor:hand;border-width: 1px 1px 1px 0px;" onclick="if(this.parentElement.all['SEL'].style.display=='block'){this.parentElement.all['SEL'].style.display='none';}else{this.parentElement.all['SEL'].style.display='block'}">$env{plus}<BR>
	<div id="SEL" onclick="this.style.display='none';"
		$env{drag_resizeX}
		class="dropdown-list"
		style="width: $env{width1}px; height: $env{height}px; display:none;">
	<div style="cursor:hand;"><B>&nbsp;<img src=$tom::H_media/grf/admin/close1.gif border=0></B></div>
		$env{select}
	</div>
</div>
HEADER

return $html}


sub select_add
{
 my %env=@_;

 return <<"HEADER";
<div class="dropdown-item" onmouseover="this.className='dropdown-item-hi';" onmouseout="this.className='dropdown-item';"
	onclick="this.parentElement.parentElement.all['VALUE'].value='$env{value}'; $env{plus}">&nbsp;$env{html}</div>

HEADER
}

1;













