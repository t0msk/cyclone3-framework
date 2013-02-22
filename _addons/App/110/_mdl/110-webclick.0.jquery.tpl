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
				'oh': objectH
			}
		});
		return true;
	});
//-->
</script>
	]]></entity>
	
</template>