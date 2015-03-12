$(document).ready(function() {
	
	bindEmailCheckSubmit();
	
	var loggedEmail = $("#email-logged-in");
	console.log( $("#email-logged-in").length);
	
	if (loggedEmail.length) {
		console.log('logged, moving to invoice data');	
		initInvoiceData();
		$("#order-data-invoice").openingSection("open");
	}
	
	var vipCardCheckElem = $("#vip-card-check").button().click(function(e) {		
		vipCardCheck(this);
	});
	if (vipCardCheckElem.length > 0) {
		vipCardCheck(vipCardCheckElem);
	} else {
		// we're in customer zone, already logged in
		initVipCard();
	}
		
	$("#regtype-selection").buttonset({
		create: function() {
			//console.log('which is checked: ',$("#regtype-selection").children("input:checked"));
			checkRegType($("#regtype-selection").children("input:checked"));
		}
	}).children("input").change(function() {
		checkRegType($(this));
		//console.log(selectedOption);
	});
	
	
	$("#newsletter-check").button();
	
});

var initVipCardCheckBtn = function() {
	vipCardCheckElem = $("#vip-card-check").button().click(function(e) {		
		vipCardCheck(this);
	});
}

var vipCardCheck = function(elem) {
	console.log('vip card check');
	if ($(elem).is(":checked")) {
		$("#vip-card-section").show();
	} else {
		console.log('hiding vip card section');
		$("#vip-card-section").hide();
	}
}


bindEmailCheckSubmit = function() {
	attachSectionClicks();
	$("#email-check-form").bind('submit', function (e) {
		e.preventDefault();
		
		var action = $("#email-check-form").attr("action")
		if (cyclone3.type == "order_data") {
			action += "&return_type=order_data";
		}
		console.log('login action ',action);
		var email = $("#email-to-check").val();
		if (typeof email === "undefined") {
			console.log('e is undefined');
			email = $("#email-checked-free").val();
		}
		console.log('email ',$("#email-to-check"));
		if((email != "") && (typeof email !== "undefined")) {
			
			console.log('ajax post');
			var vipCardIsChecked = $("#vip-card-check").is(":checked");
			$.post( action, 
				$("#email-check-form").serialize(),
				function(data){
					
					$("#email-check-loadbox").html(data);
					var freeEmail = $(data).find("#email-checked-free");
					var loggedIn = $(data).find("#user-logged-in");
					
					bindEmailCheckSubmit();
					initVipCardCheckBtn();
					
					console.log('free email ', freeEmail);
					if(freeEmail.length) {
						if (cyclone3.type == "order_data") {
							initInvoiceData();
						} else {
							// is registration
							initInvoiceDataReg();
						}
						/*$("#vip-card-check").button().click(function(e) {		
							vipCardCheck(this);
						});*/
						//vipCardCheckInit();
						var section = "#order-data-invoice";
						console.log('vip card elem, ', $("#vip-card-check"));
						if (vipCardIsChecked) {
							console.log('vip card checked');
							section = "#vip-card-section";
							initVipCard();
						}
						$(section).openingSection("open");
						$("#email-free-hidden, #vip-card-email").val(freeEmail.val());
						console.log();
						//bindEmailCheckSubmit();
					} else if (loggedIn.length) {
						console.log('logged in');
						location.reload();
					}
				});
			return false;
		}
		else
		{
		 // no email submitted
			return false;
		}
	});
}
		
var initValidator = function(form, fields, callback) {
	console.log('valid init');

	validator = new FormValidator(form, fields,
		function(errors, event) {
				$(".error").hide();
				
			if (errors.length > 0) {
				console.log('has errors ',errors);
				
				
				console.log('form corrupted');
				errorLength = errors.length;
				for (var i=0; i<errorLength; i++) {
					fieldToShow = $(".error."+errors[i].name);
					
					//console.log('fieldToSHow',fieldToShow);
					fieldToShow.show();
				}
			} else {
				//console.log('form validated');
				callback();
			}
		}
	);
}

var initInvoiceDataReg = function() {
	initValidator('invoice-data-form',invoiceDataFields,function() {
	});
}

var initVipCard = function() {
	console.log('init vip card');
	$("#vip-card-form").unbind().bind('submit', function (e) {
		
		console.log('card code form submited');
		e.preventDefault();
		action = $("#vip-card-form").attr("action");
		$("#vip-card-email").val($("#email-checked-free").val());
		//console.log($("#vip-card-email").val());
		
		if ($('#vip-card-code-input').val() != "" && $("#vip-card-email").val() != "") {
			console.log('have some code');
			console.log('serialized ',$("#vip-card-form").serialize());
			$.post( action, 
				$("#vip-card-form").serialize(),
				function(data){
					
					$("#vip-card-loadbox").html(data);
					
					var validCard = $(data).find("#valid-card-code");
					initVipCard();
					
					if(validCard.length) {
						$("#card-code").val(validCard.val());
						$("#card-code-continue").click(function() {
							if($("#order-data-invoice").length>0) {
								$("#order-data-invoice").openingSection("open");
							} else {
								location.reload();
							}
						});
					}
				});
		}
	});
}

var attachSectionClicks = function() {
	$(".section .title").off().click(function(e) {
		//console.log('click to open');
		//console.log('enabled data', $(e.currentTarget).data("enabled"));
		if ($(e.currentTarget).data("enabled")=="enabled") {
			//console.log("is enabled, opening");
			var selector = "#" + $(this).parents(".section").attr("id");
			$(selector).openingSection("open");
		}
	});
}


var checkRegType = function(elem) {
	var orgData = $('#org-data');
	var selectedOption = $(elem).attr("id");
	//console.log('selected option',selectedOption);
	if (selectedOption == "regtype-org"  && orgData.not(":visible")) {
		//initValidator(validatorFields.concat(validatorOrgFields));
		orgData.slideDown();
	} else if (selectedOption == "regtype-personal" && orgData.is(":visible")) {
		orgData.slideUp();
		//initValidator(validatorFields);
	}
}