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
	<entry id="main">
		<![CDATA[
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	</head>
	<body>
	<style>
		body
		{ font-family: Arial, Verdana; }
		h1 {
			color: #808285;
			font-family: Arial, Verdana;
		}
		
		/*.domain { color: #555555; text-align: left; font-size: 15px;  }
		.term { font-size: 14px; font-weight: normal; }
		.info { font-size: 18px; }*/
	
		.domain { font-size: 18px; }
		.term { font-size: 14px; font-weight: normal; }
		.info { font-size: 14px; font-weight: normal; }
		
		#page table { margin-bottom: 30px; }
		
		#page td { border: 1px solid gray; }
		#page th { border: 1px solid gray; text-align: left; }
		#domains td, #domains th { border: none; }
		#domains .tableinfos td, #domains .tableinfos th { border: 1px solid #000; }
	</style>
		<h1>
			<img src="cid:part1.webcom.logo\@webcom.sk" alt="webcom logo" border="0" /><br /><br />
			<span class="domain"><%header%></span><br />
			<span class="term"><%term%></span><br />
			<span class="info"><%info%></span>
		</h1>
		<div id="page">
			
			<#BODY#>
			
		</div>
	</body>
</html>
		]]>
	</entry>
	<entry id="line">asdfsdfasdfasdf</entry>
	<entry id="adsfasdf@a400">
		<![CDATA[asdfasfd]]>
	</entry>
</template>