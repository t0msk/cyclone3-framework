$(document).ready(function() {
		
	var spinner = $(".amount-spinner input").spinner().spinner({
		min: 1,
		numberFormat: "n"
	});
	
	
	
	$("#to-checkout").click(function() {
		window.location.href = "?page=order_data";
	})
	
});



