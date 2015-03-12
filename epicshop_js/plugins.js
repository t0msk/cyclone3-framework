var mobileWidth = 640;
var fullWidth = 1006;

function getMobileWidth() {
	return mobileWidth;
}

function getFullWidth() {
	return fullWidth;
}



(function ($) {

/********************
	TEASER 
**********************/

$.fn.teaser = function (ms) {
   var slides = this.find(".main");
	var tabWindow = this.find(".tabwindow");
	var tabsList = this.find("#tabs");
	var tabs = tabsList.children("li");
	var pointer = this.find("#pointer");
   var itemcount = slides.length;
   var tabHeight = tabs.first().height();
	 
	var currentPos = 0;
   delaySlide();
   
	var tick;
	
	
   function delaySlide() {
	   delay = ms;
	   tick = setInterval(function () {
		   //tabs.get(i).show();
		   clearInterval(tick);
		   i = currentPos;
		   i++;
		   if (i>=itemcount) {
			   i=0;
		   }
		   gotoSlide(i);
	   },delay);
	};
   
	function gotoSlide(i) {
		//console.log(slides.get(i));
		$(slides.get(currentPos)).fadeOut(1000);
		$(slides.get(i)).fadeIn(1000).css("display: block");
		currentPos = i;
		delaySlide(ms);
		var tabPosition = $(tabs.get(i)).position();
		pointer.animate({
			left: tabPosition.left + "px"
		})
	}
	 
	 /*
	 
   $(".arrow.right").click(function() {
	   clearInterval(tick);
	   next = currentPos+1;
	   if (next>=itemcount) {
		   next=0;
	   }
	   gotoSlide(next);
   });
 
   $(".arrow.left").click(function() {
	   clearInterval(tick);
	   previous = currentPos-1;
	   if (previous<0) {
		   previous=itemcount-1;
	   }
	   gotoSlide(previous);
   });
   
   */
	
	//console.log(tabs);

	tabs.click(function() {
		  clearInterval(tick);
		  gotoSlide($(this).index()-1)
	})
	
	this.find("#teasermore").click(function() {
		  //console.log('tabslist margin:',parseInt(tabsList.css("margin-top")));
		  var topMargin = parseInt(tabsList.css("margin-top"));
		  //console.log('marginlimit: ',tabHeight);
		  if (topMargin>(-tabHeight*(itemcount-1))) {
			  //console.log('posuvam');
			  tabsList.css("margin-top",parseInt(tabsList.css("margin-top"))-tabHeight);
			  //console.log(tabsList.css("margin-top"));
		  }
	});
 
};

/***************
 * CAROUSEL
****************/

$.fn.carousel = function(maxW) {

	var elem = this;
	var items = $(this).find(".items");
	
	var margin = 0;
	var maxMargin = 0;
	var itemWidAbs = 0;
	var numItems;
	
	
	var init = function() {
		margin = 0;
		var itemWindow = elem.find(".item-window");
		//console.log('window elem: ',itemWindow);
		var windowW = itemWindow.innerWidth(); // window width;
		//console.log('parrent of visible width',elem.parent().innerWidth());
		// if carousel is currently hidden, we can't detect width of item window
		// (happens only after additional init() call, e.g. after browser window resize)
		// item-window and parent of carousel elem cannot be hidden
		if (itemWindow.is(":hidden")) {
			//console.log('parrent of hidden width',elem.parent().innerWidth());
			var windowWPerc = itemWindow.css('width');
			// trim % sign
			windowWPerc = windowWPerc.substring(0, windowWPerc.length-1);
			//console.log('itemwindow css width',Number(windowWPerc));
			windowW = Math.round(elem.parent().innerWidth()*(windowWPerc/100));
			//console.log('hidden window width: '+windowW);
		}
			
		//console.log('window: '+elem.attr("id")+' windowwidth: '+windowW);
		numItems = Math.ceil(windowW/maxW);
		//console.log('numitems: '+numItems);
		items.attr("style", '');
		var itemWidRel = (100 / numItems)  + "%";
		//console.log('itemWidRel: '+itemWidRel);
		//elem.find(".item").css("width",itemWidRel);
		//itemWidAbs = itemWindow.find(".item").first().outerWidth();
		//console.log('normal window '+elem.attr("id")+' item width: '+itemWidAbs);
		/*if (itemWindow.is(":hidden")) {
			
			var itemClone = itemWindow.find(".item").first().clone().appendTo("<div>");
			itemWidAbs = itemClone.outerWidth();
			console.log('hidden window '+elem.attr("id")+' item width: '+itemWidAbs);
		}*/
		//console.log('itemWidAbs: '+itemWidAbs);
		itemWidAbs = windowW/numItems;
		elem.find(".item").css("width",itemWidAbs);
		var totalWidth = itemWidAbs * (items.find(".item").length+1);
		maxMargin = itemWidAbs * (items.find(".item").length - numItems - 1);
		//console.log('totalwidth pre '+elem.attr("id")+': '+totalWidth+' numitems: '+numItems+' windowW: '+windowW+' items length: '+items.find(".item").length);
		
		items.css("width", totalWidth + "px");
	}
	
	// bind resize event and reinit carousel only if stopped resizing for 100ms
	
	triggerAfterResizeDelay(init);
  
	var triggerEvent = "tap"
	if ($(document).width()>mobileWidth) {
		triggerEvent = "click";
	}
	
	this.find(".arrow.right").on(triggerEvent, function () {
		  slide("right",items);
	})

	this.find(".arrow.left").on(triggerEvent, function () {
		  slide("left",items);
	})
	
	 var slide = function (direction,items) {
		if (direction == "right" && margin >= (-maxMargin)) {
			//console.log('sliding right');
			//console.log(itemWidAbs);
			items.animate({
				 "margin-left": margin - itemWidAbs + "px",
			}, 300)
			margin -= itemWidAbs;
		} else if (direction == "left" && margin < 0) {
			items.animate({
				 "margin-left": margin + itemWidAbs + "px",
			}, 300)
			margin += itemWidAbs;
		}
		updateArrows();
	 }

	var updateArrows = function () {
		if (margin == -maxMargin) {
			elem.find(".arrow.right").addClass("inactive");
		} else {
			elem.find(".arrow.right").removeClass("inactive");
		}
		if (margin == 0) {
			elem.find(".arrow.left").addClass("inactive");
		} else {
			elem.find(".arrow.left").removeClass("inactive");
		}
	}
	//console.log(this);
	 

	 
	init();
	
	// init hammer gestures
	if (elem[0]) {
		new Hammer(elem[0], { dragLockToAxis: true }).on("release dragleft dragright swipeleft swiperight", handleHammer);
	}
   
	
	function handleHammer(ev) {
		// disable browser scrolling
		ev.gesture.preventDefault();

		switch(ev.type) {
			 case 'dragright':
			 case 'dragleft':
				  // stick to the finger
				  var pane_offset = margin;
				  var drag_offset = ((100/itemWidAbs)*ev.gesture.deltaX) / numItems;

				  // slow down at the first and last pane
				  /*
				  if((current_pane == 0 && ev.gesture.direction == "right") ||
						(current_pane == pane_count-1 && ev.gesture.direction == "left")) {
						drag_offset *= .4;
				  }
					*/
				  //setContainerOffset(drag_offset + pane_offset);
				  break;

			 case 'swipeleft':
				  slide("right",items);
				  ev.gesture.stopDetect();
				  break;

			 case 'swiperight':
				  slide("left",items);
				  ev.gesture.stopDetect();
				  break;

			 case 'release':
				  // more then 50% moved, navigate
				  if(Math.abs(ev.gesture.deltaX) > itemWidAbs/2) {
						if(ev.gesture.direction == 'right') {
							slide("left",items);
						} else {
							slide("right",items);
						}
				  }
				  else {
						//self.showPane(current_pane, true);
				  }
				  break;
		}
	}

	return this;
	
};


$.fn.popup = function(elem) {
	var popup = $(elem);
	var popupHidden = true;
	
	if ($(document).width()>getMobileWidth()) {
		  
		$(this).children("a").unbind();
		$(this).off().hover(
			function() {
				popup.stop().slideDown(100,
					function() {
						popup.attr('style','');	
					});
				
			},
			function () {
				popup.stop().slideUp(100);
			}
		)
		
	} else {
		$(this).off();
		$(this).children("a").unbind().on("click tap", function(e) {
			e.preventDefault();
			//console.log('popup mobile slide');
			if (popupHidden) {
				$(this).addClass('opened');
				popup.slideDown();
				popupHidden = false;
			} else {
				$(this).removeClass('opened');
				popup.slideUp();
				popupHidden = true;
			}
		})
	}
}


/*************************/
/* floater */
/*************************/

$.fn.floater = function(time,easing) {

	var floatElem = $(this);
	var offset = $(floatElem).offset();
	var topPadding = 0;
	
	var heightTopMenu = $('#top_menu').outerHeight();
	var heightHeader = $('header').outerHeight();
	
	var cartOffsetToFloat = heightTopMenu + heightHeader;
	var cartOffsetDefault = heightTopMenu;

	time = (time != undefined) ? time : 0;
	easing = (time != undefined) ? easing : 'linear';

	//floatElem.off();

		$(window).scroll(
			function () {
				if ($(document).width()>getMobileWidth()) {
					//console.log('cartOffsetToFloat: ',cartOffsetToFloat);
					cartOffsetToFloat = heightHeader;
					cartOffsetDefault = 0;
					//cyclone3.log(cartOffsetDefault + ' ' + cartOffsetToFloat)
					//cyclone3.log($(window).scrollTop())
					//console.log('cartOffsetToFloat: '+cartOffsetToFloat);
					//if ($(window).scrollTop() > offset.top + 100) {
					
					
					
					if ($(window).scrollTop() > cartOffsetToFloat) {
						 //console.log('animating');
						//console.log('offset.top: '+offset.top);
						//console.log('cartOffsetDefault: '+cartOffsetDefault);
						//console.log('scrollTop: '+$(window).scrollTop());
						$(floatElem).addClass('scrolled');
						
						/*
						 // use only for eased motion, problematic on resize
						 $(floatElem).stop().animate({
									marginTop: $(window).scrollTop() - offset.top + cartOffsetDefault
								},
								time,
								easing
						);*/
						//console.log('cart margin: '+$(sidebar).css("margin-top"))
					} else {
						(floatElem).stop().animate({
									marginTop: cartOffsetDefault
								},
								time,
								easing,
								function () {
									$(floatElem).removeClass('scrolled');
								}
						);
					}
				}
			});

}

$.fn.fillWidth = function(parent) {
	 
	if ($(document).width()>480) {
		var elems = $(this);
		var parentW = $(parent).width();
		var elemsW = 0;
		$(elems).each(function(i,e) {
			//console.log($(e).outerWidth(true));
			elemsW+=$(e).outerWidth(true);
		});
		//console.log(elemsW);
		//console.log(parentW);
		var wToAdd = (parentW - elemsW)/$(elems).length;
		//console.log(wToAdd);
		$(elems).each(function(i,e) {
			//console.log('before: ',$(e).outerWidth(true));
			$(e).width("20%");
			
			//console.log('after: ',$(e).outerWidth(true));
		});
		
		var first = $(elems).first();
		//first.width(first.width()+parseInt(first.css("margin-left")));
		first.css("margin-left",0);
		var last = $(elems).last();
		//console.log(last.width());
		//last.width(last.width()+parseInt(last.css("margin-right")));
		//console.log(last.width());
		last.css("margin-right",0);
	}
}

$.fn.addToBasket = function() {
	this.each(function(){
		var img = $(this).parents(".item").find('img:first');
		//console.log('parent:',$(this).parents(".item"));
		$(this).click(function(){
			flyToElement($(img), $('#basket-scroll'), $(this).data("product-id"));
			return false;
		});

  });
	function flyToElement(flyer, flyingTo, productID, callBack /*callback is optional*/) {
		var $func = $(this);
		//console.log('flyer',flyer);
		var divider = 3;

		var flyerClone = $(flyer).clone();
		$(flyerClone).css({
			position: 'absolute',
			top: $(flyer).offset().top + "px",
			left: $(flyer).offset().left + "px",
			opacity: 1,
			'z-index': 1000
		});
		$('body').append($(flyerClone));

		var gotoX = $(flyingTo).offset().left + ($(flyingTo).width() / 2) - ($(flyer).width()/divider)/2;
		var gotoY = $(flyingTo).offset().top + ($(flyingTo).height() / 2) - ($(flyer).height()/divider)/2;

		$(flyerClone).animate({
			opacity: 0.4,
			left: gotoX,
			top: gotoY,
			width: $(flyer).width()/divider,
			height: $(flyer).height()/divider
		}, 700,
		function () {
			 $(flyerClone).fadeOut('fast', function () {
					$(flyerClone).remove();
					$.ajax({
						type: "POST",
						url: "basketresponse.html",
						data: { productID: productID, action: "addToBasket"},
						success: function(data) {
							 
							 //console.log($(data).find("#ajax-content"));
							 if($("#ajax-content",data)) {
									$("#basket").html($(data).find("#basket").html());
							 }
						},
						error: function(xhr,status,error) {
							 //console.log(xhr,status,error);
						},
						dataType: 'html'
					});  
					
			 });
		});
	}
}

/*************************/
/* dropdown */
/*************************/

	$.fn.dropdown = function(target) {
		this.click(function() {
			//$(this).off("click");
			var self = $(this);
			target.toggle(1, function()  {
				//self.on("click");
				$(document).click(function(event) {
				
				
				if(!$(event.target).closest($(target)).length) {
					if($(target).is(":visible")) {
						$(target).hide(1, function() {
							$(document).off("click");
							//self.on("click");
						});
					}
				}
				});
				
			});
		});
	}
	

/*************************/
/* tabs */
/*************************/

	$.fn.tabs = function(target) {
		var tabsWrapper = this;
		var tabSwitchers = tabsWrapper.find(".tabs li a");
		//console.log(tabSwitchers);
		var tabsContents = tabsWrapper.siblings(".content");
		//console.log(tabsContents)
		//console.log(this);
		tabSwitchers.click(function() {
			if (!$(this).hasClass("active")) {
				$(tabSwitchers).add(tabsContents).removeClass("active");
				$(this).addClass('active');
				var tabContent = $("#"+$(this).data("target"));
				tabContent.addClass("active");
			}
			
		});
		
	}

/*************************/
/* filter related */
/*************************/

	var priceSliderChange = false;

	// init for buttonset
	$.fn.filterButtonset = function(callback) { 
		$(this).buttonset({
			create: function( event, ui ) {
				$(this).setFilterBoxes();
				if (typeof callback !== "undefined" ) {
					//console.log('callback object',$(this).find("span"));
					callback();
				}
			}
		});
	}
	
	// init for slider
	$.fn.filterSlider = function(reset, priceMin, priceMax, priceFilteredMin, priceFilteredMax) {
		
		var self = $(this);
		var parent = $(this).parents(".section").find(".title").text().trim();
		
		$(this).slider({
			range: true,
			min: Number(priceMin),
			max: Number(priceMax)+1,
			values: [ Number(priceFilteredMin), Number(priceFilteredMax)+1 ],
			create: function(e,ui) {
				//$(this).setFilterBoxes();
				
				var displayMin = formatPrice(priceFilteredMin, cyclone3.currency_symbol, false, true);
				var displayMax = formatPrice((priceFilteredMax+1), cyclone3.currency_symbol, false, true);
				$("#filter-price-number").val(displayMin + " - " + displayMax);
			},
			slide: function(e,ui) {
				//updateSliderTexts(ui)
			},
			change: function(e,ui) {
				updateSliderTexts(ui)
			}
		});
		
			//updateSliderTexts();
		
		if (reset=="reset") {
			$("#box-filter-price-range").remove();
			/*($(".filter .ui-slider")
				.slider("values", 0, $(".filter .ui-slider").slider("option", "min") )
				.slider("values", 1, $(".filter .ui-slider").slider("option", "max") );*/
		}

		function updateSliderTexts(ui) {
			/*var min = $(this).slider("values",0);
			var max = $(this).slider("values",1);*/
			var rangeText = Math.floor(ui.values[0]) + " " + cyclone3.currency_symbol + " - " +  Math.floor(ui.values[1]) + " " + cyclone3.currency_symbol;
			//console.log('slider change',priceSliderChange);
			if (!priceSliderChange) {
				addBox($("#filter-price-number"),"filter-price-range",parent);
				//$("#box-filter-price-range").append('<span id="box-filter-price-range-text"></span>');
			}
			$("#filter-price-number").val(rangeText);
			$("[data-filter-for=filter-price-range] .value").html(rangeText);
			priceSliderChange = true;
			window.filterParams['price_min'] = Math.floor(ui.values[0]);
			window.filterParams['price_max'] = Math.floor(ui.values[1]);		
			loadFilteredResults();
		}
	}

	$.fn.setFilterBoxes = function() {
		
		
		$(this).find("label.ui-state-active").each(function(i,e) {
			//console.log(e);
			var filterFor = $(this).attr("for");
			var parent = $(this).parent().siblings(".title").text().trim();
			addBox($(this),filterFox,parent);
		});
		
		$("#remove-all-filters").unbind().click(function() {
			
			$(".filter label.ui-state-active").each(function(i,e) {
				var filterFor = $(e).attr("for");
				removeBox(filterFor,$(e),true);
			});
			removeBox("filter-price-range",[],true);
			$("#remove-all-filters").hide();
			priceSliderChange = false;
		});
		
		$(this).find("label").click(function() {
			var filterFor = $(this).attr("for");
			var parent = $(this).parents(".section").find(".title").text().trim();
			if($(this).hasClass("ui-state-active")) {
				removeBox(filterFor,$(this));
			} else {
				addBox($(this),filterFor,parent);
			}
			loadFilteredResults();
			
		});
	}

	function addBox(checkbox,filterFor,parent) {
		var value = checkbox.text();
		if (!value) {
			value = checkbox.val();
		}
		var filterBoxTemplate = '<div class="filterbox"><span class="value">'+value+'</span><a href="javascript:;" class="remove">x</a></div>';

		//console.log('value',value);
		var boxToAdd = $(filterBoxTemplate).attr("data-filter-for",filterFor);
		var paramName = "filter_" + checkbox.data("param-name") + "[]";
		var paramValue = checkbox.data("param-value");
		if (typeof paramValue !== "undefined") {
			if(typeof window.filterParams[paramName] !== "undefined") {
				window.filterParams[paramName].push(paramValue);
			} else {
				//console.log('creating new param');
				window.filterParams[paramName] = [];
				window.filterParams[paramName].push(paramValue);
			}
		}
		
		//console.log('param name',paramName);
		//console.log('checkbox',checkbox);
		$("#remove-all-filters").show();
		
		boxToAdd.prepend('<span class="section">'+parent+': </span>');
		
		//console.log('boxToAdd',boxToAdd);
		//console.log('parent',parent);
		$("#selected-filters").append(boxToAdd);
		
		// "x" button
		boxToAdd.find(".remove").click(function() {
			removeBox(filterFor,$('label[for="'+$(this).parent().data('filter-for')+'"]'),true);
		});
		
	}
		
	function removeBox(filterFor,checkbox,refresh) {
		$('[data-filter-for="'+filterFor+'"]').remove();
		
		//console.log('checkbox length',checkbox.length);
		if (checkbox.length > 0 && checkbox.data("param-name")) {
			var paramName = "filter_" + checkbox.data("param-name") + "[]";
			var paramValue = checkbox.data("param-value");
			
				//console.log('checkbox',checkbox);
				//console.log('param name',paramName);
				//console.log('param value',paramValue);
				//console.log('filter param [name]',filterParams[paramName]);
				//console.log('checkbox',checkbox);
			window.filterParams[paramName].splice( $.inArray(paramValue, window.filterParams[paramName]), 1 );
		}
		if ($("#selected-filters .filterbox").length==0) {
			$("#remove-all-filters").hide();
		}
		if (refresh) {
			//console.log('filter for: ',filterFor);
			var filterForElem = $('#'+filterFor);
			filterForElem.removeAttr("checked");
			filterForElem.parents(".ui-buttonset").buttonset("refresh");
			//console.log('filterForElem',filterForElem);
			//$("#"+filterFor).slider("refresh");
			//console.log($("#"+filterFor).data());
			if (priceSliderChange && filterFor == "filter-price-range") {
				filterForElem
					.slider("values", 0, filterForElem.slider("option", "min") )
					.slider("values", 1, filterForElem.slider("option", "max") );
				priceSliderChange = false;	
			}
		}
			
		loadFilteredResults();
	}
	
	$.fn.filterSortBy = function() {
		var self = $(this);
		
		var options = $(this).buttonset().find("label");
		
		//console.log("options",options);
		$.each(options, function(i,e) {
		//console.log("each option",e);
			$(e).click(function(tgt) {
				//console.log("option click",tgt);
				currentTgt = $(tgt.currentTarget);
				window.filterParams['sortby'] = currentTgt.data("sortby-option");
				optionName = currentTgt.find('span').html();
				$("#filter-sortby").text(optionName);
				$("#filter-sortby-options").hide();
				$(document).off("click");
				loadFilteredResults();
			});
		})
		
	}

	/* ========================
		UNBIND EVENT ON FULLSIZE
	   ======================== */
	
	$.fn.unbindEventOnFull = function(event,fnc) {
		var elem = $(this);
		
		var bindIfSize = function() {
			if ($(window).width()>=getFullWidth()) {
				elem.unbind(event,fnc);
			} else {
				elem.unbind(event,fnc);
				elem.bind(event,fnc);
			}
		}
		bindIfSize();	
		$(window).resize(function() {
			bindIfSize();
		});
	}

	
$.fn.unbindEventOnFull = function(event,fnc) {
		var elem = $(this);
		
				
		var bindIfSize = function() {
			if ($(window).width()>=getFullWidth()) {
				elem.unbind(event,fnc);
			} else {
				elem.unbind(event,fnc);
				elem.bind(event,fnc);
			}
		}
		
		bindIfSize();	
		$(window).resize(function() {
			bindIfSize();
		});

		
}

$.fn.basketSpinner = function() {
	var elem = $(this);
	
	elem
		.spinner({
			min: 1,
			numberFormat: "n"
		})
		.bind("keydown", function (event) {
			event.preventDefault();
		})
		.focus(function () {
			$(this).blur();
		});
	
}

$.fn.openingSection = function(action) {
	var elem = $(this);
	console.log('opening section',elem);
	if(action == "open") {
		if (elem.children(".content").is(":hidden")) {
			$(".section .content").slideUp();
			console.log('showing');
			$(".section").removeClass("enabled").addClass("disabled");
			elem.addClass("enabled").removeClass("disabled");
			elem.children(".content").slideDown();
		}
	}
}

	
}(jQuery));
