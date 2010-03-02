<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		<extend level="global" name="default" />
		<!--
		<extend level="global" addon="a400" name="default" content-type="xml"/>
		-->
		<!--<include level="current" name="a400"/>-->
		
	</header>
	
	<entity id="color.h1">#90bf56</entity>
	<entity id="color.h2">#90bf56</entity>
	<entity id="content.width">555</entity>
	
	<entity id="email.xhtml" replace_variables="true">
		<![CDATA[
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	</head>
	<body>
		<style>
			body { font-family: Arial, Verdana; font-size: 14px;}
			#page { width: <$tpl::entity{'content.width'}>px; }
			h1 { color: <$tpl::entity{'color.h1'}>; clear: left; }
			h2 { color: <$tpl::entity{'color.h2'}>; clear: left; }
			.main-logo { float: left; margin: 0 15px 15px 0; }
			.main-title { font-size: 0.65em; font-weight: bold; }
			.main-term { font-size: 0.4em; font-weight: normal; }
			.main-desc
			{
				color: #808285;
				margin: 10px 0 20px 0; font-size: 0.4em; font-weight: normal;
				border: 10px solid gray; border-width: 0 0 0 10px;
				padding: 0 0 0 10px;
			}
			.sum
			{
				color: gray;
				font-weight: bold;
				background: #e5e5e5;
			}
			
			#content { clear: both }
			#content .graph
			{
				border: 2px dotted <$tpl::entity{'color.h1'}>;
				margin-bottom: 20px;
			}
			table
			{
				border: 1px dotted gray; border-width: 1px 1px 0 0;
				font-size: 0.8em;
				margin-bottom: 20px;
			}
			table td, table th
			{
				border: 1px dotted gray; border-width: 0 0 1px 1px;
				padding: 2px;
				text-align: left;
			}
			table th { background: #e5e5e5; color: gray; }
		</style>
		<div id="page">
			<h1>
				<img class="main-logo" src="cid:logo@cyclone3.org" alt="Cyclone3 logo" border="0" />
				<div class="main-title"><%main-title%></div>
				<div class="main-term"><%main-term%></div>
				<div class="main-desc"><%main-desc%></div>
			</h1>
			<div id="content">
<#email.content#>
			</div>
		</div>
	</body>
</html>
		]]>
	</entity>
	
	
	<entity id="email.table" replace_variables="true">
	<![CDATA[
		<table width="<$tpl::entity{'content.width'}>" cellpadding="0" cellspacing="0">
			<thead>
				<tr>
					<th colspan="<%colscount%>"><%title%></th>
				</tr>
				<!--
				<tr>
					<th colspan="<%colscount%>"><%subtitle%></th>
				</tr>
				-->
				<tr>
					<#email.table.col.name#>
				</tr>
			</thead>
			<tbody>
				<#email.table.line#>
			</tbody>
		</table><br/>
	]]>
	</entity>
	
	
	<entity id="email.table.line">
	<![CDATA[
		<tr>
			<#email.table.col.value#>
		</tr>
		<#email.table.line#>
	]]>
	</entity>
	
	
	<entity id="email.table.line_sum">
	<![CDATA[
		<tr class="sum">
			<#email.table.col.value#>
		</tr>
		<#email.table.line#>
	]]>
	</entity>
	
	
	<entity id="email.table.col.name">
	<![CDATA[
		<th><%name%></th>
		<#email.table.col.name#>
	]]>
	</entity>
	
	
	<entity id="email.table.col.value">
	<![CDATA[
		<td align="<%align%>"><%value%></td>
		<#email.table.col.value#>
	]]>
	</entity>
	
	<entity id="email.table.col.value_span">
	<![CDATA[
		<td colspan="<%span%>"><%value%></td>
		<#email.table.col.value#>
	]]>
	</entity>
	
	<entity id="email.table.col.value_sum">
	<![CDATA[
		<td class="sum"><%value%></td>
		<#email.table.col.value#>
	]]>
	</entity>
	
	
</template>
