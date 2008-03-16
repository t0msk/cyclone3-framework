<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		
		<L10n level="auto" name="default" lng="auto"/>
		
	</header>
	
	<entity id="page.error" replace_variables="false"><![CDATA[
domain:<$tom::H>
engine:<$TOM::engine>
TypeID:<$main::FORM{'TID'}>
request.code:<$main::request_code>
<!--ERROR-->
	]]>
	</entity>
	
	
	<entity id="page.warning" replace_L10n="true" replace_variables="false"><![CDATA[
page.warning
]]></entity>
	
	
	<entity id="body.notfound" replace_L10n="true" replace_variables="false"><![CDATA[
body.notfound
]]></entity>
	
	
	<entity id="box.error" replace_variables="true" replace_L10n="true"><![CDATA[
module:<%MODULE%>
<$(This service is currently not available)>. <$(We're trying to fix this problem at the moment and apologize for any inconvenience)>.
error:<%ERROR%> <%PLUS%>
]]></entity>
	
	
</template>