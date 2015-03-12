var visibleLimit;
var productListLoadUrl;
var offset = 0;

$(document).ready(function() {
	
	productList = $("#product-list-main");
	visibleLimit = productList.data("limit");
	productListLoadUrl = productList.data("load-url");
	console.log($("#product-list-main").data("is-last"));
	if (typeof $("#product-list-main").data("is-last") === "undefined") {
		initLoadMore();
	}
	
	initSizesButtons();
	
	// FILTER
	if (typeof window.filterParams !== "undefined") {

		
		$("#filter-sizes").filterButtonset();
		$("#filter-brands").filterButtonset();
		
		$(".filter .dropdown-btn").each(function(i,e) {
			dropdown = $(e).siblings(".dropdown");
			
			dropdown.filterButtonset();
			$(e).dropdown(dropdown);
			
		});
		
		$("#filter-colors").on( "buttonsetcreate", function( event, ui ) {
				var labels = $(this).find("label");
				labels.each(function(i,e) {
					var color = $(e).css("background-color");
					$(e).addClass(getContrastColor(color))
				})
		});	
		$("#filter-colors").filterButtonset();
			var priceMin;
			var priceMax;
			if ((typeof priceMinLimit !== "undefined") && (typeof priceMaxLimit !== "undefined")) {
				priceMin = priceMinLimit;
				priceMax = priceMaxLimit;
			} else {
				priceMin = 0;
				priceMax = 300;
			}
			var priceFilteredMin;
			var priceFilteredMax;
			if (typeof window.filterParams.price_filtered_min !== "undefined") {
				
				priceFilteredMin = window.filterParams.price_filtered_min;
				priceFilteredMax = window.filterParams.price_filtered_max;
			} else {
				priceFilteredMin = priceMin;
				priceFilteredMax = priceMax;
			}
		$("#filter-price-range").filterSlider(false, priceMin, priceMax, priceFilteredMin, priceFilteredMax);
		$("#filter-sortby-options").filterSortBy();
		$("#filter-sortby").dropdown($("#filter-sortby-options"));	
	}
	$("#bestsellers").carousel(240);
	$("#new").carousel(240).removeClass("active");
	$("#special").carousel(240).removeClass("active");
	
	$("#brandscarousel").carousel(80);
	
	$("#product-teaser-tabs").tabs();
	
	// AVAILABILITY
	
	$(".stock-status").each(function(i,e){
		//$(e).children(".max").first().show();
	});
	
	// PSEUDO LINKS 
	/*
	$(".product-list .item a").click(function() {
		window.location.href="?page=product_view";
	});
	*/
});

// LOAD MORE

var initLoadMore = function()  {
	console.log('init load more');
	offset = 0;
	//displayedProducts.hide();
	loadMoreProducts();

	$('#product-list-load-more').show().off().click(function() {
		console.log('load more click');
		productList.find(".item").show();
		loadMoreProducts();
	});
}

var loadMoreProducts = function(replace) {
	offset += visibleLimit-1;
	if (typeof productListLoadUrl !== "undefined") {
		$.get(productListLoadUrl+"&offset="+offset+" #ajax-body", function(data) {
			data = $("<div>").html(data).find("#ajax-body").contents();
			
			//console.log("ajax body ",data.find("#ajax-body"));
			data.find(".item").hide();
			
			var dropdowns = data.find(".sizes.dropdown .content");
			
			var loadbox = $('#product-list-loadbox');
			
			loadbox.append(data);
			
			initSizesButtons(loadbox.find(".sizes.dropdown .content"));
			
			attachToBasketEvents();
			attachToFavoritesEvents();
			initProductTooltips();
			
			loadedWrap = $("#product-list-ajax-"+offset);
			var isLast = $("#product-list-ajax-"+offset).data("is-last");
			if (isLast) {
				productList.find(".item").show();
				$('#product-list-load-more').hide();
				$('#product-list-no-more-products').show();
			}	
		});
	}
}

var loadFilteredResults = function() {
	var URL = cyclone3.domain + "?type=ajax_product_list"
	if (shop_path != "") {
		URL += "&shop_path="+shop_path;
	}
	
	for (var param in window.filterParams) {
		if (window.filterParams[param]	instanceof Array) {
			for (var i = 0; i<window.filterParams[param].length; i++) {
				URL += "&"+param+"="+window.filterParams[param][i];
			}
		} else {
			if (param != "") {
				URL += "&"+param+"="+window.filterParams[param]		
			}
		}
	}
	// pass URL to global var for load more function
	productListLoadUrl = URL;
	try {filterRequest.abort();} catch(err) {};
	filterRequest = $.get(URL, function(data) {
		console.log('filter request');
		data = $("<div>").html(data).find("#ajax-body").contents();
		var isLast = $("<div>").html(data).find(".product-list-ajax").data("is-last");
		$('#product-list-loadbox').html(data);
		var items = productList.find(".item");
		if (isLast) {
			$('#product-list-load-more').hide();
			//initLoadMore();
		} else {
			offset = 0;
			if(items.length > 0) {
				loadMoreProducts();
				$('#product-list-load-more').show();
			} else {
				//console.log('no items');
			}
			
		}
		
		initSizesButtons();
		attachToBasketEvents();
		attachToFavoritesEvents();
		initProductTooltips();
	});
}

// COLOR UTILITIES

var getContrastColor = function(rgbstring)
{
	var triplet = rgbstringToTriplet(rgbstring);
	var resultColor;
	// black or white:
	var total = 0; for (var i=0; i<triplet.length; i++) { total += triplet[i]; } 
	if(total > (3*256/2)) {
		resultColor = 'black';
	} else {
		resultColor = 'white';
	}
	return resultColor;
}

var rgbstringToTriplet = function(rgbstring)
{
   if(!rgbstring.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/)) {
      hex = hexToRgb(rgbstring);
		if (hex!=null) {
			rgbstring = "rgb("+hex.r+","+hex.g+","+hex.b+")";
		}
   }
   var commadelim = rgbstring.substring(4,rgbstring.length-1);
   var strings = commadelim.split(",");
   var numeric = [];
   for(var i=0; i<3; i++) { numeric[i] = parseInt(strings[i]); }
   return numeric;
}

var hexToRgb = function(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}