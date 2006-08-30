###########################
# HTML PROCESSOR
###########################

sub info_create # initialize
{
 my %env=@_;

 my $str=$ENV{'QUERY_STRING'};
 $str=~s|&page=.*?&|&|g;

 my $html="<div id=\"info\" style=\"display:none;\"><table width=100% cellspacing=0 cellpadding=0 border=0 height=100% background=\"$tom::H_media/grf/admin/win_top_0_back.gif\"><tr>";

if ($env{icon})
{
 $html.=<<" HEADER";
	<td><img src="$tom::H_media/grf/admin/win_top_0_btn2.gif" border=0 $env{icon}><BR></td>
 HEADER
}

if ($env{new})
{
 $html.=<<" HEADER";
	<td style="cursor:hand;" onclick="load_box('core.pl?type=$form{type}-edit')"><img src="$tom::H_media/grf/admin/win_top_0_btn5.gif" border=0><BR></td>
 HEADER
}

if ($env{title})
{
 $html.=<<" HEADER";
	<td width=100% style="FONT:bold 10px Verdana;">&nbsp;<font color=white>$env{title}</font></td>
 HEADER
}

if (defined $env{prev})
{
 my $page=$env{prev}-1;
 if ($page>=0)
 {
 $html.=<<" HEADER";
	<td style="FONT:bold 10px Verdana;cursor:hand;" onclick="load('core.pl?$str&page=$page')"><img src="$tom::H_media/grf/admin/win_top_0_btn4.gif" border=0><BR></td>
 HEADER
 }
}

if (defined $env{next})
{
 my $page=$env{next}+1;
 $html.=<<" HEADER";
	<td style="FONT:bold 10px Verdana;cursor:hand;" onclick="load('core.pl?$str&page=$page')"><img src="$tom::H_media/grf/admin/win_top_0_btn3.gif" border=0><BR></td>
 HEADER
}

 return $html."<td><img src=\"$tom::H_media/grf/admin/win_top_0_end.gif\" border=0><BR></td></tr></table></div>\n\n";
}


1;













