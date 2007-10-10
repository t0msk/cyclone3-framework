<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		
		<L10n level="auto" name="xhtml" lng="auto"/>
		
	</header>
	
	<entity id="page.error" replace_variables="false"><![CDATA[
<service>
	<header>
		<domain><$tom::H></domain>
		<engine><$TOM::engine></engine>
		<TypeID><$main::FORM{'TID'}></TypeID>
		<request>
			<code><$main::request_code></code>
		</request>
	</header>
	<message>Error</message>
	<!--ERROR-->
</service>
	]]>
	</entity>
	
	
	<entity id="page.warning" replace_L10n="true" replace_variables="false"><![CDATA[
<service>
	<header>
		<domain><$tom::H></domain>
		<engine><$TOM::engine></engine>
		<TypeID><$main::FORM{'TID'}></TypeID>
		<request>
			<code><$main::request_code></code>
		</request>
	</header>
	<message><%message%></message>
</service>
]]></entity>
	
	
	<entity id="body.notfound" replace_L10n="true" replace_variables="false"><![CDATA[
<service>
	<header>
		<domain><$tom::H></domain>
		<engine><$TOM::engine></engine>
		<TypeID><$main::FORM{'TID'}></TypeID>
		<request>
			<code><$main::request_code></code>
		</request>
	</header>
	<message><$(The page or service type cannot be found)></message>
</service>
]]></entity>
	
	
	<entity id="box.error" replace_variables="true" replace_L10n="true"><![CDATA[
<module>
	<name><%MODULE%></name>
	<message><$(This service is currently not available)>. <$(We're trying to fix this problem at the moment and apologize for any incovnenience)>.</message>
	<error><%ERROR%> <%PLUS%></error>
</module>
]]></entity>
	
	
</template>