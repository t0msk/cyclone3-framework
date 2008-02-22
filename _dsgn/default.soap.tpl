<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		<L10n level="auto" name="xml" lng="auto"/>
	</header>
	
	
	<entity id="page.error" replace_L10n="false" replace_variables="false"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope
	xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
	SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Header>
		<generator>Cyclone<$TOM::core_version>.<$TOM::core_build> (r<$TOM::core_revision>)</generator>
		<hostname><$TOM::hostname></hostname>
		<domain><$tom::H></domain>
		<process><$$></process>
		<request_code><$main::request_code></request_code>
		<method><$main::FORM{'type'}></method>
		<TypeID><$main::FORM{'TID'}></TypeID>
	</SOAP-ENV:Header>
	<SOAP-ENV:Body>
		<SOAP-ENV:Fault>
			<faultcode>SOAP-ENV:Server</faultcode>
			<faultstring>Server error</faultstring>
			<detail>
				<message><![CDATA[[<%message%>]]&gt;</message>
			</detail>
		</SOAP-ENV:Fault>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>
	]]>
	</entity>
	
	
	<entity id="page.warning" replace_L10n="false" replace_variables="false"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope
	xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
	SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Header>
		<generator>Cyclone<$TOM::core_version>.<$TOM::core_build> (r<$TOM::core_revision>)</generator>
		<hostname><$TOM::hostname></hostname>
		<domain><$tom::H></domain>
		<process><$$></process>
		<request_code><$main::request_code></request_code>
		<method><$main::FORM{'type'}></method>
		<TypeID><$main::FORM{'TID'}></TypeID>
	</SOAP-ENV:Header>
	<SOAP-ENV:Body>
		<SOAP-ENV:Fault>
			<faultcode>SOAP-ENV:Client</faultcode>
			<faultstring>Client error</faultstring>
			<detail>
				<message><![CDATA[[<%message%>]]&gt;</message>
			</detail>
		</SOAP-ENV:Fault>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>
]]></entity>
	
	
	<entity id="body.notfound" replace_L10n="true" replace_variables="false"><![CDATA[
<SOAP-ENV:Fault>
	<faultcode>SOAP-ENV:Client</faultcode>
	<faultstring>Client error</faultstring>
	<detail>
		<message><$(The page or service type cannot be found)></message>
	</detail>
</SOAP-ENV:Fault>
]]></entity>
	
	
	<entity id="box.error" replace_variables="true" replace_L10n="true"><![CDATA[
<SOAP-ENV:Fault>
	<faultcode>SOAP-ENV:Server</faultcode>
	<faultstring>Server error</faultstring>
	<detail>
		<message><![CDATA[<%MODULE%> <$(This service is currently not available)>. <%ERROR%> <%PLUS%>]]&gt;</message>
	</detail>
</SOAP-ENV:Fault>
]]></entity>
	
	
</template>