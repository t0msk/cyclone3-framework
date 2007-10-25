<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		<L10n level="auto" name="xml" lng="auto"/>
	</header>
	
	<entity id="page.error" replace_L10n="false" replace_variables="false"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<methodResponse>
	<fault>
		<value>
			<struct>
				<member>
					<name>faultCode</name>
					<value><int>505</int></value>
				</member>
				<member>
					<name>faultString</name>
					<value><string><%message%></string></value>
				</member>
			</struct>
		</value>
	</fault>
</methodResponse>
	]]>
	</entity>
	
	
	<entity id="page.warning" replace_L10n="false" replace_variables="false"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<methodResponse>
	<fault>
		<value>
			<struct>
				<member>
					<name>faultCode</name>
					<value><int>300</int></value>
				</member>
				<member>
					<name>faultString</name>
					<value><string><%message%></string></value>
				</member>
			</struct>
		</value>
	</fault>
</methodResponse>
]]></entity>
	
	
	<entity id="body.notfound" replace_L10n="true" replace_variables="false"><![CDATA[
<fault>
	<value>
		<struct>
			<member>
				<name>faultCode</name>
				<value><int>404</int></value>
			</member>
			<member>
				<name>faultString</name>
				<value><string><$main::FORM{'TID'}>: <$(The page or service type cannot be found)>. </string></value>
			</member>
		</struct>
	</value>
</fault>
]]></entity>
	
	
	<entity id="box.error" replace_variables="true" replace_L10n="true"><![CDATA[<!-- <%MODULE%> <$(This service is currently not available)>. <%ERROR%> <%PLUS%> -->]]></entity>
	
	
</template>