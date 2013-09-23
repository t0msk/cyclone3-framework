<?xml version="1.0" encoding="UTF-8"?>
<template>
	
	<entity id="img.a501_image"><![CDATA[[%USE dumper;USE a501;FILTER collapse;
		attr_ignore={'/'=>1,id=>'1','src'=>1,'alt'=>1,'align'=>1,'class'=>1};
		image = a501.get_image_file(
			'image.ID_entity' => entity.id.ID_entity,
			'image_file.ID_format' => entity.id.ID_format || 2
		);
	%]
		<img
			class="a501_image[%IF entity.attr.class;" " _ entity.attr.class|xml;END;%]"
			alt="[%entity.attr.alt || entity.db.name | xml%]"
			align="[%entity.attr.align|xml%]"
			src="[%domain.url_a501%]/image/file/[%image.file_path%]"
[%
	FOREACH attr IN entity.attr;
		NEXT IF attr_ignore.item(attr.key);
		" " _ attr.key _ "=\"";
			attr.value | xml;
		"\"";
	END;
	" /" IF entity.attr.item('/')
%]>
	[%END%]]]></entity>
	
	
	<entity id="img.a510_video"><![CDATA[[%USE dumper;USE a510;USE a501;
#		image = a501.get_image_file(
#			'image.ID_entity' => entity.id.ID_entity,
#			'image.ID_format' => entity.id.ID_format || 2
#		);
	%]
<video
	class="a510_video[%IF entity.attr.class;" " _ entity.attr.class|xml;END;%]"
	alt="[%entity.attr.alt || entity.db.name | xml%]"
	align="[%entity.attr.align|xml%]"
	src="[%domain.url_a510%]/video/part/file/[%entity.db.file_part_path%]"
>
</video>
	]]></entity>
	
	
	<entity id="a.a510_video"><![CDATA[[%USE dumper;USE a510;FILTER collapse;
		attr_ignore={'/'=>1,id=>'1','href'=>1,'title'=>1,'class'=>1};
	%]
		<a
			class="a510_video[%IF entity.attr.class;" " _ entity.attr.class|xml;END;%]"
			title="[%entity.attr.title || entity.db.name | xml%]"
			href="?|?ID=[%entity.db.ID_entity%]&name_url=[%entity.db.name_url%]&a210_path=[%entity.db.a210.path_url%]"
[%
	FOREACH attr IN entity.attr;
		NEXT IF attr_ignore.item(attr.key);
		" " _ attr.key _ "=\"";
			attr.value | xml;
		"\"";
	END;
%]>
	[%END%]]]></entity>
	
	<entity id="a.a210_page"><![CDATA[[%USE dumper;FILTER collapse;
		attr_ignore={'/'=>1,id=>'1','href'=>1,'title'=>1,'class'=>1};
%]
		<a
			class="a210_page[%IF entity.attr.class;" " _ entity.attr.class|xml;END;%]"
			title="[%entity.attr.title || entity.db.name | xml%]"
			href="?|?a210_path=[%entity.db.path_url%]"
[%
	FOREACH attr IN entity.attr;
		NEXT IF attr_ignore.item(attr.key);
		" " _ attr.key _ "=\"";
			attr.value | xml;
		"\"";
	END;
%]>
	[%END%]]]></entity>
	
</template>