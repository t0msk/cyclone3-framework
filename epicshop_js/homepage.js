$(document).ready(function() {
	
	$("#bestsellers").carousel(240);
	$("#new").carousel(240).removeClass("active");
	$("#special").carousel(240).removeClass("active");
	//console.log($("#special").carousel(170));
	
	$("#brandscarousel").carousel(80);
	
	$("#product-teaser-tabs").tabs();
	
	$("#hometeaser").teaser(5000);
	
	// PSEUDO LINKS 
	
	//$(".product-list .item a").click(function() {
	//	window.location.href="?page=product_view";
	//});
	
	$("#rss-feed").carousel(200);
	
	// QUICKLINKS - SHOW MORE
	var quicklinks = $(".quicklinks");
	var quicklinksInner = $("#quicklinks-inner");
	var defaultHeight = quicklinks.height();
	var hiddenHeight = quicklinksInner[0].scrollHeight;
	var defaultInnerHeight = quicklinksInner.height();
	console.log('quicklinks default inner height: ',defaultInnerHeight);
	var totalHeight = (defaultHeight-defaultInnerHeight) + hiddenHeight;
	console.log('default height: ',defaultHeight);
	$("#quicklinks-show-all").click(function() {
		
		var currentHeight = quicklinks.height();
		var heightTo = totalHeight;
		var innerHeightTo = hiddenHeight;
		var showLabel = "less";
		console.log('quicklinks inner: ',hiddenHeight);
		
		if (defaultHeight < currentHeight) {
			heightTo = defaultHeight;
			innerHeightTo = defaultInnerHeight;
			showLabel = "more";
		}
		console.log('animate height: ',heightTo);
		quicklinks.animate({"height" : heightTo});
		quicklinksInner.animate({"height" : innerHeightTo});
		$(this).find("."+showLabel).show();
		console.log('span ',quicklinks.find("span"));
		console.log('showlabel ',quicklinks.find("."+showLabel));
		console.log($(this).find("span").not("."+showLabel));
		$(this).find("span").not("."+showLabel).hide();
	})
	
});



