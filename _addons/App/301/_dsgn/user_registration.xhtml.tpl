<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		<L10n level="auto" name="user_registration" addon="a301" lng="auto" />
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
			<h1>User Registration</h1>
			<div id="content">
<p><$tom::H> received a request to registration of username '<%username%>' to <%email%>.</p>
<br/>
Accept this subscription follow this link:<br/>
<$tom::H_www>/user/activation?code=<%ID_user%></br>
<br/>
Thanks,<br/>
<$tom::H> Team<br/>
<$tom::H_www>
			</div>
		</div>
	</body>
</html>
		]]>
	</entity>
	
</template>
