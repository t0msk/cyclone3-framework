$(document).ready(function() {
	
	
	initSizesButtons();
	
	// BETA WARNING
	
	var betaWarningClickMore = $("#beta-warning-more");
	var betaWarningURI = betaWarningClickMore.attr("href")
	betaWarningURI += "&ref_qs="+encodeURIComponent(location);
	betaWarningURI += "&ww="+$(window).width()+"&wh="+$(window).height();
	betaWarningURI += "&wiw="+window.innerWidth+"&wih="+window.innerHeight;
	betaWarningURI += "&wsw="+window.screen.width+"&wsh="+window.screen.height;
	
	betaWarningClickMore.fancybox(	{
		type: 'ajax',
		maxWidth:800,
		maxHeight:800,
		href: betaWarningURI,
		afterShow: function() {
        bindContactForm();
		}
	});
	
	if (!sessionStorage.betaWarningAlreadyViewed) {
		setTimeout(function(){
			$.fancybox.open({
				type: 'ajax',
				maxWidth:800,
				maxHeight:800,
				href: cyclone3.domain+"?type=ajax_article_view&article_ID=51"
			});
		},1000); 
		sessionStorage.betaWarningAlreadyViewed = "true";
	}
	
	
	// RESPONSIVE ELEMENTS
	
	$("#basket-wrapper").popup("#basket-popup");

	$("#navFloater").floater();

	initTopMenuPopups();
	
	if($(document).width() > getMobileWidth()) {
		initFull();
	} else {
		initPhone();
	}
	
	function initTopMenuPopups() {
		$.each($(".submenu-top"),function(i,e) {
			$($(e).parents(".menuitem-top")).popup(e);
		})
	}

	var timer;
	
	triggerAfterResizeDelay(function() {
		console.log('onresize');
		$("#phone-menu").unbind();
		$("#menuitem-products").unbind();
		$("#search").unbind();
		
		$("#menuitem-products").popup("#submenu-products");
		$("#navFloater").floater();
		//console.log($(document).width());
		initTopMenuPopups();
		
		if($(document).width() > getMobileWidth()) {
			initFull();
		} else {
			initPhone();
		}
	});
	
	// AUTOCOMPLETE SEARCH 
	
	$.ui.autocomplete.prototype._renderItem = function( ul, item){
	var term = this.term.split(' ').join('|');
	var re = new RegExp("(" + term + ")", "gi") ;
	var t = item.label.replace(re,"<b>$1</b>");
	return $( '<li></li>' )
	  .data( "item.autocomplete", item )
	  .append( '<a href="'+item.url+'">' + t + '</a>' )
	  .appendTo( ul );
	};
	
	$.widget( "custom.catcomplete", $.ui.autocomplete,
	{
		_create: function() {
		  this._super();
		  this.widget().menu( "option", "items", "> :not(.ui-autocomplete-category)" );
		},
		_renderMenu: function( ul, items ) {
		  var that = this,
			 currentCategory = "";
		  $.each( items, function( index, item ) {
			 var li;
			 if ( item.category != currentCategory ) {
				ul.append( "<li class='ui-autocomplete-category'><span>" + item.category + "</span></li>" );
				currentCategory = item.category;
			 }
			 li = that._renderItemData( ul, item );
			 if ( item.category ) {
				li.attr( "aria-label", item.category + " : " + item.label );
			 }
		  });
			$("#search-all-results")
				.clone()
				.attr("id","search-all-results-clone")
				.css("display","block")
				.attr("href",$(that.element).parents("form").attr("action")+"?q="+that.term)
				.appendTo(ul)
				.find("#search-results-string")
					.attr("id","search-results-string-clone")
					.html(that.term);
		}
	});
	
	$( "#searchfield" ).catcomplete({
		source: function(request, response) {
            /* local results: */
            var localResults = $.ui.autocomplete.filter(autocomplete_data, request.term);
				$("#search-loader").css("display","block");
            /* Remote results: */
				console.log('loading search');
            $.ajax({
                url: cyclone3.domain+"/json/?type=product_search&q="+request.term,
                dataType: 'json',
                success: function(data) {
						console.log('search loaded');
                    response(localResults.concat(data.items));
						  $("#search-loader").hide();
                }
            });
        }
	});
	
	$(".amount-spinner input").basketSpinner();

	// TOOLTIP IMAGE
	
	initProductTooltips();
	triggerAfterResizeDelay(initProductTooltips);

	// NEWSLETTER FANCYBOX
	var newsletterForm = $("#newsletter-form");
	newsletterForm.bind('submit', function (e) {
		e.preventDefault();
		var action = newsletterForm.attr("action");
		var email = $("#newsletter-email-input").val();
		
		console.log('email '+email);
		if(email!="") {
			$.post(
				action,
				newsletterForm.serialize(),
				function(data){
				  $.fancybox.open([
						{
						 content : data,
						 closeClick : true,
						 iframe : {
							  scrolling : 'no'
						  }
						}
				  ])
				}
			)
		}
	});
	
	// ARTICLE POPUP FANCYBOXES
	$(".article-popup").fancybox({
		type: 'ajax',
		maxWidth:1000,
		maxHeight:800
	});
	
	// BASKET
	basketView = $("#basket-popup");
	if (cyclone3.type == "basket_view" || cyclone3.type == "order_data") {
		$("#basket-scroll").remove();
		basketView = $("#basket-view");
	}

	var viewUrl = cyclone3.domain+"?type=ajax_basket_update #ajax-body";
	
	basketView.load(viewUrl,function() {
		attachBasketEvents();
				updateBasketInfo();
	});
	
	$("#login-popup-link").popup("#login-popup");	
	$("#login-popup-form").bind('submit', function (e) {
		var login = $("#login-popup-email").val();
		var pass = $("#login-popup-pass").val();  
		if(login == "" || pass == "" ) {
			e.preventDefault();
		}
	});
	
	attachToBasketEvents();
	attachToFavoritesEvents();
	
});

// RESPONSIVE ELEMENTS INITIALIZATIONS

function initFull() {
	$("#mainNav, #search").show();
	$("#reg-popup-link").popup("#reg-popup");
	$("#login-popup-link").popup("#login-popup");
	$("#basket-wrapper").popup("#basket-popup");
}

function initProductTooltips() {
	if ($(document).width()>getMobileWidth()) {
		$(".product-list img[rel]").tooltip({
			content: function()  {
				var s = $(this).attr('rel');
				return '<img class="clearfix" src='+s+'>'
			},
			items: "img[rel]",
			track: true,
			show: { effect: "fade", duration: 500 },
			hide: { effect: "fade", duration: 500 }
		});
	} else {
		try {
			$(".product-list img[rel]").tooltip("destroy");
		} catch(e) {
			
		}
	}
}

function initPhone() {
	$("#navFloater").attr("style","");
	$("#phone-menu").click(function() {
		if ($("#search").is(":visible")) {
			$("#phone-search").removeClass("open");
				$("#search").slideToggle("elastic", function() {
			});
		}
		$("#mainNav").slideToggle("elastic", function() {
		});
	});
	
	$("#phone-search").unbind().click(function() {
		if ($("#mainNav").is(":visible")) {
				$("#mainNav").slideToggle("elastic", function() {
			});
		}
		$(this).toggleClass("open");
		$("#search").slideToggle("elastic", function() {
		});
	});
}

function triggerAfterResizeDelay(triggerFnc) {
	var timer;
	$(window).bind('resize', function(){
		timer && clearTimeout(timer);
		timer = setTimeout(triggerFnc, 500); 
	})
}

// UTILITIES

function formatPrice(price, suffix, nbsp, floor) {
	console.log('price: '+price);
	price = Number(price).toFixed(2);
	if (price == "NaN") {
		return "?"
	}
	console.log('price to fixed: '+price);
	if (typeof floor !== "undefined") {
		console.log('flooring', floor);
		price = Math.floor(price);
	}
	if (typeof suffix === "undefined") {
		suffix = "";
	}
	var space = "&nbsp;";
	if (typeof nbsp !== "undefined" && !nbsp) {
		space = " ";
	}
	price = String(price).replace('.00',',-');
	var output = String(price).replace('.',',') + space + suffix;
	return output;
}

// BASKET RELATED

var initSizesButtons = function(dropdowns) {
	dropdowns = typeof dropdowns !== 'undefined' ? dropdowns : $(".sizes.dropdown  .content");
	dropdowns.each(function(i,e) {
		if($(e).is(":ui-buttonset")) {
			$(e).buttonset("destroy");
		} 
		$(e).buttonset(); 
	});
}

var attachToBasketEvents = function() {
	//console.log('attach to basket');
	$(".to-basket").not(".disabled").each(function(i,e) {
		$(e).off();
		$(e).on('click tap', function(event) {
			console.log('adding '+i);
			addToBasket(event.currentTarget);
		});
	});
}

var addToBasket = function(item) {
	var productID = $(item).data("product-id");
	var modifications = $(".product-modifications").find("input[data-primary-product-id='"+productID+"']:checked");
	// modification is clicked
	if ((typeof productID === "undefined") && (modifications.length == 0)) {
		console.log('modfis');
		productID = $(item).parents(".item").find(".to-basket").data("product-id");
		console.log($(item));
		modifications =  $(".product-modifications").find("#"+$(item).attr("for"));
		console.log(productID);
		console.log(modifications);
	}
	
	if (modifications.length>0) {
		
		if (modifications.length>1) {
			modifications = modifications.filter("[data-primary-product-id='"+productID+"']");
		}
		console.log('found modifications filtered',modifications);
		var primaryID = productID;
		productID = modifications.data("modification-id");
		
	}
	var amount = $(item).siblings(".amount-spinner").find("input").spinner("value");
	var action = "update";
	
	if ((typeof amount === "undefined") || amount.length<1) {
		amount = 1;
		action = "add";
	}
	
	var updateUrl = cyclone3.domain+"?type=ajax_basket_update&"+action+"_"+productID+"="+amount+" #ajax-body";
	//console.log('complete url ',updateUrl);
	modificationsDropdown = $(".sizes.dropdown[data-primary-product-id='"+productID+"']");
	console.log('modif dropdown length',modificationsDropdown.length);
	if ((modificationsDropdown.length > 0) && modifications.length < 1) {
		
		$(".sizes.dropdown[data-primary-product-id='"+productID+"']").slideDown(300, function(e) {
			// tap doesnt work on buttonset for modifications and we want to close dropdown after selection
			$(this).find("label.ui-button").on('click tap', function() {
				
				addToBasket($(this));
			});
		});
	} else {
		console.log('updating basket ');
		$(basketView)
			.load(updateUrl,function() {
				attachBasketEvents();
				updateBasketInfo();
				$(".sizes.dropdown[data-primary-product-id='"+primaryID+"']").slideUp();
			});
	}
}

var attachBasketEvents = function() {
	// unbind existing events to prevent duplicity
	$(".remove-from-basket").off();
	$(".basket-view .amount-spinner input").off();
	
	$(".remove-from-basket").click(function(e) {
		var productID = $(e.currentTarget).data("product-id");
		var deleteUrl = cyclone3.domain+"?type=ajax_basket_update&remove="+productID+" #ajax-body";
		$(basketView).load(deleteUrl,function() {
			attachBasketEvents();
			updateBasketInfo();
		});
	});
	
	$(".basket-view .amount-spinner input").basketSpinner();
	$(".basket-view .amount-spinner input").on("spin", function(e,ui) {
		
		updateBasketAmount($(e.currentTarget).data("product-id"),ui.value);
	});	
};

var attachToFavoritesEvents = function() {
	$(".fav:not(.active)").each(function(i,e) {
		attachAddToFavorites($(e));
	});
	$(".fav.active").each(function(i,e) {
		attachRemoveFromFavorites($(e));
	});
}

var attachAddToFavorites = function(favBtn) {
		favBtn.off();
		favBtn.on('click tap',function(event) {
			var productID = $(event.currentTarget).data("product-id");
			action = "add";
			var updateUrl = cyclone3.domain+"?type=ajax_favorites_update&"+action+"="+productID + " #ajax-body";
			console.log('complete url ',updateUrl);
				console.log('adding to favorites ');
				$.get(updateUrl,function() {
					favBtn.addClass("active");
					favBtn.children(".added").show();
					favBtn.children(".add").hide();
					
					attachRemoveFromFavorites(favBtn);
				});			
		});
}

var attachRemoveFromFavorites = function(favBtn) {
	favBtn.off();
	favBtn.click(function(event) {
		var productID = $(event.currentTarget).data("product-id");
		action = "remove";
		var updateUrl = cyclone3.domain+"?type=ajax_favorites_update&"+action+"="+productID + " #ajax-body";
		$.get(updateUrl,function() {
				favBtn.removeClass("active");
				favBtn.children(".add").show();
				favBtn.children(".added").hide();
				favBtn.off();
				
				if (cyclone3.type == "favorites_list") {
					favBtn.parents('.item').fadeOut();
				} else {
					attachAddToFavorites(favBtn);
				}
		});
	});
}

var updateBasketAmount = function(productID,amount) {
	
	var updateUrl = cyclone3.domain+"?type=ajax_basket_update&update_"+productID+"="+amount;

	$(basketView).load(updateUrl,function() {
		attachBasketEvents();
		updateBasketInfo();
	});
		
}

var updateBasketInfo = function() {
	var totalItems = $("#basket-subtotal").data("total-items");
	var totalPrice = $("#basket-subtotal").data("total-price");

	$("#basket-info-total-items, #basket-phone-total-items").html(totalItems);
	$("#basket-info-total-price, #basket-phone-total-price").html(totalPrice);
}

// CONTACT FORM AJAX SEND BIND

var bindContactForm = function() {
	console.log('binding contact form',$(".contact-form"));
	$(".contact-form").bind('submit', function (e) {
		e.preventDefault();
		var form = $(this);
		console.log('form',form);
		var action = $(this).attr("action");
	
		$.post(
			action,
			$(this).serialize(),
			function(data){
				data = $("<div>").html(data).find("#ajax-body").contents();
				console.log('form parent inside post',form.parents(".loadbox"));
				form.parents(".fancybox-inner").html(data);
				console.log('data response',data);
				$.fancybox.update();
			}
		)
	});
}
