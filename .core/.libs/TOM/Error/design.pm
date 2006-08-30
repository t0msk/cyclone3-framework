package TOM::Error::design;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/
	$color_gray
	$color_red
	$engine_email
	$email_crontype
	$email_project
	$email_project_pub
	$email_module
	$email_ENV_
	$module_email
	/;

our $color_gray="#F2F2F2";
our $color_red="#CD4545";
our $color_black="#000000";

our $engine_email=<<"HEADER";
From: "<%DOMAIN%>($TOM::hostname)" <TOM\@$TOM::hostname>
To: <%TO%>
Subject: [ERR][ENGINE-$TOM::engine]<%SUBJ%>
Date: <%DATE%>
List-Id: TOM3
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Type: multipart/related; boundary="------------060509090608000908080106"

This is a multi-part message in MIME format.
--------------060509090608000908080106
Content-Type: text/html;charset="utf-8"
Content-Transfer-Encoding: 7bit

<html>
	<head>
	</head>
	<body>
	
		<style>
		<!--
			body
			{
				color: $color_black;
			}
			td
			{
				font-family: Verdana;
				font-size: 12px;
			}
			.var
			{
				font-weight: bold;
			}
		-->
		</style>
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;">Error</td>
			</tr>
			<tr>
				<td bgcolor="$color_gray" class="value"><%ERROR%></td>
			</tr>
		</table>
		<br/>
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;">Engine $TOM::engine</td>
			</tr>
			<tr>
				<td bgcolor="$color_gray">
				
				<table width="100%">
					
					<tr>
						<td class="var" nowrap="nowrap">core:</td>
						<td class="value" width="100%">$TOM::core_name$TOM::core_version.$TOM::core_build (r$TOM::core_revision)</td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">process:</td>
						<td class="value" width="100%">$$</td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">engine started:</td>
						<td class="value" width="100%"><\$TOM::time_start></td>
					</tr>
					
				</table>
				
				</td>
			</tr>
		</table>
		<br/>
<#PROJECT#>
		<br/>
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;">Full Environment</td>
			</tr>
			<tr>
				<td bgcolor="$color_gray">
				<table width="100%">
<#ENV#>
				</table>
			</tr>
		</table>
		
	</body>
</html>
--------------060509090608000908080106--
HEADER


our $email_crontype=<<"HEADER";
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;">Project <\$tom::H></td>
			</tr>
			<tr>
				<td bgcolor="$color_gray">
				
				<table width="100%">
					
					<tr>
						<td class="var" nowrap="nowrap">project manager:</td>
						<td class="value" width="100%"><\$TOM::contact{'manager'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">TOM:</td>
						<td class="value" width="100%"><\$TOM::contact{'TOM'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">TECH:</td>
						<td class="value" width="100%"><\$TOM::contact{'TECH'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">TECH_farm:</td>
						<td class="value" width="100%"><\$TOM::contact{'TECH_farm'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">WEB:</td>
						<td class="value" width="100%"><\$TOM::contact{'WEB'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">DEV:</td>
						<td class="value" width="100%"><\$TOM::contact{'DEV'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">CONT:</td>
						<td class="value" width="100%"><\$TOM::contact{'CONT'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">send to:</td>
						<td class="value" width="100%"><%to%></td>
					</tr>
					
				</table>
				
				</td>
			</tr>
		</table>
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_gray">
				
				<table width="100%">
					
					<tr>
						<td class="var" nowrap="nowrap">original URI:</td>
						<td class="value" width="100%"><%uri-orig%></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">parsed URI:</td>
						<td class="value" width="100%"><%uri-parsed%></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">referer URI:</td>
						<td class="value" width="100%"><%uri-referer%></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">request number:</td>
						<td class="value" width="100%"><\$tom::count> of <\$TOM::max_count></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">unique hash:</td>
						<td class="value" width="100%"><\$main::request_code></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">TypeID:</td>
						<td class="value" width="100%"><\$main::FORM{TID}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">IAdm:</td>
						<td class="value" width="100%"><\$main::IAdm></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">ITst:</td>
						<td class="value" width="100%"><\$main::ITst></td>
					</tr>
					
				</table>
				
				</td>
			</tr>
		</table>
HEADER


our $email_project=<<"HEADER";
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;">Project <\$tom::H></td>
			</tr>
			<tr>
				<td bgcolor="$color_gray">
				
				<table width="100%">
					
					<tr>
						<td class="var" nowrap="nowrap">project manager:</td>
						<td class="value" width="100%"><\$TOM::contact{'manager'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">TOM:</td>
						<td class="value" width="100%"><\$TOM::contact{'TOM'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">TECH:</td>
						<td class="value" width="100%"><\$TOM::contact{'TECH'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">TECH_farm:</td>
						<td class="value" width="100%"><\$TOM::contact{'TECH_farm'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">WEB:</td>
						<td class="value" width="100%"><\$TOM::contact{'WEB'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">DEV:</td>
						<td class="value" width="100%"><\$TOM::contact{'DEV'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">CONT:</td>
						<td class="value" width="100%"><\$TOM::contact{'CONT'}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">send to:</td>
						<td class="value" width="100%"><%to%></td>
					</tr>
					
				</table>
				
				</td>
			</tr>
		</table>
HEADER

our $email_project_pub=<<"HEADER";
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_gray">
				
				<table width="100%">
					
					<tr>
						<td class="var" nowrap="nowrap">original URI:</td>
						<td class="value" width="100%"><a href="<%uri-orig%>"><%uri-orig%></a></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">parsed URI:</td>
						<td class="value" width="100%"><a href="<%uri-parsed%>"><%uri-parsed%></a></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">referer URI:</td>
						<td class="value" width="100%"><a href="<%uri-referer%>"><%uri-referer%></a></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">request number:</td>
						<td class="value" width="100%"><\$tom::count> of <\$TOM::max_count></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">unique hash:</td>
						<td class="value" width="100%"><\$main::request_code></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">TypeID:</td>
						<td class="value" width="100%"><\$main::FORM{TID}></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">IAdm:</td>
						<td class="value" width="100%"><\$main::IAdm></td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">ITst:</td>
						<td class="value" width="100%"><\$main::ITst></td>
					</tr>
					
				</table>
				
				</td>
			</tr>
		</table>
HEADER

our $email_module=<<"HEADER";
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;">Module <%MODULE%>
			</tr>
			<tr>
				<td bgcolor="$color_gray">
				
				<table width="100%">
					
					<tr>
						<td class="var" nowrap="nowrap">module owner(s):</td>
						<td class="value" width="100%"><\$Tomahawk::module::authors></td>
					</tr>
					
					
				</table>
				
				</td>
			</tr>
		</table>
HEADER

our $email_ENV_=<<"HEADER";
					<tr>
						<td class="var" nowrap="nowrap"><%var%>:</td>
						<td class="value" width="100%"><%value%></td>
					</tr>
HEADER






our $module_email=<<"HEADER";
From: "<%DOMAIN%>($TOM::hostname)" <TOM\@$TOM::hostname>
To: <%TO%>
Subject: [<%TYPE%>][MODULE-$TOM::engine]<%SUBJ%>
Date: <%DATE%>
List-Id: TOM3
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Type: multipart/related; boundary="------------060509090608000908080106"

This is a multi-part message in MIME format.
--------------060509090608000908080106
Content-Type: text/html;charset="utf-8"
Content-Transfer-Encoding: 7bit

<html>
	<head>
	</head>
	<body>
	
		<style>
		<!--
			body
			{
				color: $color_black;
			}
			td
			{
				font-family: Verdana;
				font-size: 12px;
			}
			.var
			{
				font-weight: bold;
			}
		-->
		</style>
		
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;"><%TYPE_%></td>
			</tr>
			<tr>
				<td bgcolor="$color_gray" class="value"><%ERROR%></td>
			</tr>
			<tr>
				<td bgcolor="$color_gray" class="value"><%ERROR-PLUS%></td>
			</tr>
		</table>
		<br/>
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;">Engine $TOM::engine</td>
			</tr>
			<tr>
				<td bgcolor="$color_gray">
				
				<table width="100%">
					
					<tr>
						<td class="var" nowrap="nowrap">core:</td>
						<td class="value" width="100%">$TOM::core_name$TOM::core_version.$TOM::core_build (r$TOM::core_revision)</td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">process:</td>
						<td class="value" width="100%">$$</td>
					</tr>
					
					<tr>
						<td class="var" nowrap="nowrap">engine started:</td>
						<td class="value" width="100%"><\$TOM::time_start></td>
					</tr>
					
				</table>
				
				</td>
			</tr>
		</table>
		<br/>
<#PROJECT#>
		<br/>
<#MODULE#>
		<br/>
		<table width="100%" cellspacing=1 cellpadding=3 bgcolor="#000000">
			<tr>
				<td bgcolor="$color_red" style="color:white;font-weight: bold;">Full Environment</td>
			</tr>
			<tr>
				<td bgcolor="$color_gray">
				<table width="100%">
<#ENV#>
				</table>
			</tr>
		</table>
		
	</body>
</html>
--------------060509090608000908080106--
HEADER


1;
