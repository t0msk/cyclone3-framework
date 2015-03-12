$(document).ready(function() {

	$("#order-summary-btn").unbindEventOnFull("click",function() {
		$("#order-summary-content").slideToggle();
	});

	
	$("#create-account-check").button().click(function(e) {
		showFieldsIfChecked($("#create-account-check"),$("#create-account-data"));
	});
	
	
	// DELIVERY
	
	var addressesSameCheck = $("#addresses-same").button().click(function() {
		checkAddressesSame(this);
	});

	checkAddressesSame(addressesSameCheck);

	showFieldsIfChecked($("#create-account-check"),$("#create-account-data"));
	
	$("#delivery-type").buttonset();
	
	/* open and close functions are workarounds to keep tooltip open when hovering mouse over it to be able to click links inside */
	$(document).tooltip({
		items: "#invoice-data-country",
		content: function() {
         return $("#country-tooltip").html()
      },
		 open: function(event, ui)
		{
        if (typeof(event.originalEvent) === 'undefined')
        {
            return false;
        }
        var $id = $(ui.tooltip).attr('id');
        //$('div.ui-tooltip').not('#' + $id).remove();
		},
		 close: function(event, ui)
		{
        ui.tooltip.hover(function()
        {
            $(this).stop(true).fadeTo(400, 1); 
        },
        function()
        {
            $(this).fadeOut('400', function()
            {
                $(this).remove();
            });
        });
        
		},
		create: function(event,ui) {
			$(ui.tooltip).tooltip("open");
		}
	});
		
	// PAYMENT
	
	$("#payment-options").buttonset();
	$("#accept-terms").button();
	
	$("#order-data-email .title").data("enabled","enabled");
	
	$(".order-data form").bind('submit', function (e) {
		e.preventDefault();
	});
	
	
	// ADD DELIVERY TO SUMMARY AND RECALCULATE TOTAL
	var summaryName = $("#summary-delivery-name");
	var summaryPrice =  $("#summary-delivery-price");
	var summaryRow = $("#summary-delivery-row");
	var summaryTotal = $("#summary-total");
	var summarySubtotal = $("#summary-subtotal").data("summary-subtotal");
	$("#delivery-type label").click(function(e) {
		tgt = $(e.currentTarget);
		var deliveryName = tgt.data("delivery-name");
		var deliveryPrice = tgt.data("delivery-price");
		if(!summaryRow.is(":visible")) {
			summaryRow.slideDown();
		}
		summaryName.html(deliveryName);
		summaryPrice.html(formatPrice(deliveryPrice,cyclone3.currency_symbol));
		var priceFinal = Number(summarySubtotal)+Number(deliveryPrice);
		//console.log('delivery price: '+deliveryPrice+' summary price: '+summarySubtotal);
		summaryTotal.html(formatPrice(Number(priceFinal),cyclone3.currency_symbol));
		
	})
});

var checkAddressesSame = function(elem) {
	
	if ($(elem).is(":checked")) {
		$("#delivery-address input").attr("disabled","disabled");	
		$("#delivery-address").slideUp();
	} else {
		$("#delivery-address input").removeAttr("disabled");
		$("#delivery-address").slideDown();
	}
}

var showFieldsIfChecked = function(check,fields) {
	console.log('checking ',check,'to show ',fields);
	console.log(check);
	if (check.is(":checked")) {
		console.log('is checked ');
		$(fields).slideDown();
	} else {
		console.log('is unchecked ');
		
		$(fields).slideUp();
	}
}

var initForm = function(formToPostID,sectionToOpenID,validatorFields,callback) {
	initValidator(formToPostID, validatorFields, function() {
		//console.log('validator callback, open ');
		var action = cyclone3.domain+"?type=ajax_order_data_update";
		$.ajax({
			type: "POST",
			url: action,
			data: $("#"+formToPostID).serialize(),
			success: function(data){
				var responseStatus = $(data).find("#order-data-update-response").html();
				if(responseStatus == "success") {
					$("#"+sectionToOpenID).openingSection("open");
					callback();
				} else {
					$("#"+formToPostID+"-error").show();
				}
			}
		});
		return false;
	});
}

// INIT SECTIONS

var initInvoiceData = function() {
	//console.log('init invoice data');
	$("#order-data-invoice .title").data("enabled","enabled");
	initForm('invoice-data-form','order-data-delivery',invoiceDataFields,function() {
		// send data also to register module 
		if ($("#create-account-check:checked").length>0) {
			$.ajax({
				type: "POST",
				url: cyclone3.domain+"?type=ajax_user_register",
				data: $("#invoice-data-form").serialize(),
				success: function(data){
					//console.log('user register loaded');
				}
			});
		}
		initDeliveryData();
	});
}

var initDeliveryData = function() {
	//console.log('init delivery data');
	$("#order-data-delivery .title").data("enabled","enabled");
	initForm('delivery-data-form','order-data-payment',deliveryDataFields,function() {
		initPaymentData();
	});
}

var initPaymentData = function() {
	$("#order-data-payment .title").data("enabled","enabled");
	initForm('payment-data-form','',paymentDataFields,function() {
		sendOrder();
	});
}

var sendOrder = function() {
	window.location.href = cyclone3.domain+"?type=order_send";
}