<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		<!--
		<L10n level="auto" name="user_creation" addon="a301" lng="auto" />
		-->
	</header>
	
	<entity id="email.body" replace_variables="true">
		<![CDATA[
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	</head>
	<body>
		<style>
		</style>
		<div id="page">
			<h1>User Account Creation</h1>
			<div id="content">
<p>Service <$tom::Hm> created new user account '<%username%>' to <%email%>.</p>
<br/>
You can enter this service with your password '<%pass%>'<br/>
<br/>
Thanks,<br/>
<$tom::Hm> Team<br/>
<$tom::Hm_www>
			</div>
		</div>
	</body>
</html>
		]]>
	</entity>
	
	<entity id="email.subject" replace_variables="true">Your User Account has been created</entity>
	
</template>
