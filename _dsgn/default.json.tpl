<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		
		<L10n level="auto" name="xhtml" lng="auto"/>
		
	</header>
	
	
	<entity id="page.error" replace_variables="false"><![CDATA[
{ "success": false, "errors": { "reason": "<$main::FORM{'TID'}>: <!--ERROR-->" }}
	]]>
	</entity>
	
	
	<entity id="page.warning" replace_L10n="true" replace_variables="false"><![CDATA[
{ "success": false, "errors": { "reason": "<$main::FORM{'TID'}>: <%message%>" }}
]]></entity>
	
	
	<entity id="body.notfound" replace_L10n="true" replace_variables="false"><![CDATA[
{ "success": false, "errors": { "reason": "<$main::FORM{'TID'}>: <$(The page or service type cannot be found)>" }}
]]></entity>
	
	
	<entity id="box.error" replace_variables="true" replace_L10n="true"><![CDATA[
{ "success": false, "errors": { reason: "<$(This service is currently not available)>", error: "<%ERROR%> <%PLUS%>" }}
]]></entity>
	
	
</template>