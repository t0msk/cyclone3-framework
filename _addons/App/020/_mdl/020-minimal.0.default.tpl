<?xml version="1.0" encoding="UTF-8"?>
<template>
	<header>
		<extend level="auto" name="default" />
		<L10n level="auto" name="default" lng="auto"/>
	</header>
	
	<entity id="main"><![CDATA[[%USE L10n;USE dumper%]
[%
	testing={
		'a' => 2
	};
%]
	[%testing.a%]
	]]></entity>
	
</template>