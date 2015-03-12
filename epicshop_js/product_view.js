$(document).ready(function() {
	
	 
	$("#size-table").fancybox();
	 

	$("#product-view-sizes").buttonset();
	var spinner = $("#amount-spinner").spinner({
		min: 1,
		numberFormat: "n"
	});
	
		
	$("#product-view-sizes input").click(function(e) {
		console.log('click');
		var modificationPrice = $(e.currentTarget).data("modification-price");
		var modificationAvailability = $(e.currentTarget).data("modification-availability");
		$(".stock-status").children().hide();
		$(".stock-status").children("."+modificationAvailability).first().show();
		
		if (typeof modificationPrice !== "undefined") {
			$(".price strong").html(modificationPrice);
		} else {
			console.log($("#product-view-price-primary"));
			$("#product-view-price-primary strong").html($("#product-view-price-primary").data("price-primary"));
		}
	});
	

	if ($(document).width()>getMobileWidth()) {
		$("#gallery a").fancybox({
			openMethod: "zoomIn",
			closeMethod: "zoomOut",
			openEffect: "elastic",
			closeEffect: "elastic"
		});
	}
	
	// product question
	$("#product-question").fancybox({
		type: 'iframe',
		iframe: {
			scrolling: 'no'
		},
		maxWidth: '400',
		minHeight: '250',
		autoSize: true
	});
	
});



