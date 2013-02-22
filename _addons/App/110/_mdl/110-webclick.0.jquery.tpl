<?xml version="1.0" encoding="UTF-8"?>
<template>
	
	<entity id="main"><![CDATA[
<script type="text/javascript">
<!--
	$(document.body).mousedown(function(event){
		if (event.target.tagName == 'BODY' || event.target.tagName == 'HTML'){return true;}
//		cyclone3.log('tagName = ' + event.target.tagName);
		eventC = Math.round(event.pageX - ($(window).width()/2));
		eventY = event.pageY;
//		cyclone3.log('event center=' + eventC + ' top=' + eventY);
		objectC = Math.round($(event.target).offset().left - ($(window).width()/2));
		objectY = Math.round($(event.target).offset().top);
		objectW = Math.round($(event.target).width());
		objectH = Math.round($(event.target).height());
//		cyclone3.log('object center=' + objectC + ' top=' + objectY + ' width=' + objectW);
		
		var overlay_found;
		var overlay_group=$(event.target).parents().filter(function() {
//			cyclone3.log('check ' + $(this).prop('tagName') + ' z-index ' + $(this).css('z-index'));
			if ($(this).css('z-index') != 'auto' && $(this).css('z-index') > 0)
			{
				overlay_found=1;
				return $(this);
			}
		});
		var overlay_group_name='';
		if (overlay_found)
		{
			overlay_group_name = 
				overlay_group.attr('c3_clickgroup')
				|| overlay_group.attr('id')
				|| overlay_group.attr('class')
				|| overlay_group.css('z-index');
//			cyclone3.log('overlay_group ' + overlay_group_name + ' z-index:' + overlay_group.css('z-index'));
		}
		
		$.ajax({
			url: "/wc.tom",
			type: "GET",
			data: {
				'TID': '[%request.param.TID%]',
				'x': eventC,
				'y': eventY,
				'u': '[%user.ID_user%]',
				'l': '[%user.logged%]',
				'oc': objectC,
				'oy': objectY,
				'ow': objectW,
				'oh': objectH,
				'g': overlay_group_name
			}
		});
		return true;
	});
//-->
</script>
	]]></entity>
	
</template>