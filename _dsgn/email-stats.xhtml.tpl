<?xml version="1.0" encoding="UTF-8"?>
<!--<!DOCTYPE template PUBLIC "-//Cyclone3//DTD Template XML V1.0//EN"
"/www/TOM/_data/dtd/template.dtd">-->
<template>
	<header>
		<extend level="global" name="default"/>
		<!--
		<extend level="global" addon="a400" name="default" content-type="xml"/>
		-->
		<!--<include level="current" name="a400"/>-->
		
	</header>
	
	<entity id="color.h1">#90bf56</entity>
	
	<entity id="email.xhtml" replace_variables="true">
		<![CDATA[
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	</head>
	<body>
		<style>
			body { font-family: Arial, Verdana; font-size: 14px;}
			#page { width: 650px; }
			h1 { color: <$tpl::entity{'color.h1'}>; clear: left; }
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


			#content { clear: both; }
			#content table { width: 450px; }
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
	
	
	<entity id="email.table">
	<![CDATA[
		<table cellpadding="0" cellspacing="0">
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
		</table>
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
	
	
	<entity id="email.table.col.name">
	<![CDATA[
		<th><%name%></th>
		<#email.table.col.name#>
	]]>
	</entity>
	
	
	<entity id="email.table.col.value">
	<![CDATA[
		<td><%value%></td>
		<#email.table.col.value#>
	]]>
	</entity>
	
	
</template>