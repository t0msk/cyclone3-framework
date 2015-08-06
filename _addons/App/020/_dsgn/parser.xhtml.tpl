<?xml version="1.0" encoding="UTF-8"?>
<template>
	
	<entity id="img.a030_youtube"><![CDATA[
		<iframe width="100%" height="315" frameborder="0" allowfullscreen="" src="//www.youtube.com/embed/[%entity.id.ID_entity%]"></iframe>
	]]></entity>
	
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
	class="[%IF entity.attr.class;" " _ entity.attr.class|xml;END;%]"
	alt="[%entity.attr.alt || entity.db.name | xml%]"
	align="[%entity.attr.align|xml%]"
	src="[%domain.url_a510%]/video/part/file/[%entity.db.file_part_path%]"
>
</video>
	]]></entity>
	
	<entity id="img.a510_video_part"><![CDATA[[%USE dumper;USE a510;USE a501%]
<video
	class="[%IF entity.attr.class;" " _ entity.attr.class|xml;END;%]"
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
	
	<entity id="a.a401_article"><![CDATA[[%USE dumper;FILTER collapse;
		attr_ignore={'/'=>1,id=>'1','href'=>1,'title'=>1,'class'=>1};
%]
		<a
			class="a401_article[%IF entity.attr.class;" " _ entity.attr.class|xml;END;%]"
			title="[%entity.attr.title || entity.db.name | xml%]"
			href="[%
				IF entity.db.a210.link == 'direct';
					'?|?a210_path=' _ entity.db.a210.path_url;
				ELSIF entity.db.a210;
					'?|?a210_path=' _ entity.db.a210.path_url;
					'&ID_entity=' _ entity.db.ID_entity;
					'&name_url=' _ entity.db.name_url;
					'&type=article_view';
				ELSE;
					'?|?ID_entity=' _ entity.db.ID_entity;
					'&name_url=' _ entity.db.name_url;
					'&type=article_view';
				END;
			%]"
[%
	FOREACH attr IN entity.attr;
		NEXT IF attr_ignore.item(attr.key);
		" " _ attr.key _ "=\"";
			attr.value | xml;
		"\"";
	END;
%]>
	[%END%]]]></entity>
	
	<entity id="a.a542_file"><![CDATA[[%USE dumper;FILTER collapse;
		attr_ignore={'/'=>1,id=>'1','href'=>1,'title'=>1,'class'=>1};
%]
		<a
			class="a542_file[%IF entity.attr.class;" " _ entity.attr.class|xml;END;%]"
			title="[%entity.attr.title || entity.db.name | xml%]"
			href="[%domain.url%]/download.tom?ID=[%entity.db.ID_entity%]&hash=[%entity.db.hash_secure%]"
[%
	FOREACH attr IN entity.attr;
		NEXT IF attr_ignore.item(attr.key);
		" " _ attr.key _ "=\"";
			attr.value | xml;
		"\"";
	END;
%]>
	[%END%]]]></entity>
	
	
	<entity id="pre.script"><![CDATA[[%]]></entity><entity id="pre.script.close"><![CDATA[%]]]></entity>
	<entity id="var.script"><![CDATA[[%]]></entity><entity id="var.script.close"><![CDATA[%]]]></entity>
	
	
</template>
