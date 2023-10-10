    
    var interId,category,subcategory;
    if (window.location.href.indexOf('emailsupport') != -1){
        interId = setInterval(init, 100);
    }

    function init() {
        category = document.getElementById("Caviar_Diner_Category__c");
        if (category != null){
            deInit();
            category.onchange = catChange;
            subcategory = document.getElementById("Subcategory_Caviar_Diner__c");
            subcategory.options = [];
            subcategory.disabled = true;
        }
    };
    
    function deInit(){
        clearInterval(interId);
    }
    
    function catChange(){
        var subcatopts = [{label:"-None-", value:"", selected:true}];
        subcategory.options = [];
        // english
        if (category.value == "Account Settings"){
            addOption(subcatopts,"Deactivate Caviar Account");
            addOption(subcatopts,"Edit Account Information");
            addOption(subcatopts,"Email/Text Unsubscription Request");
            addOption(subcatopts,"Issues with 2FA");
            addOption(subcatopts,"Password Assistance");
            addOption(subcatopts,"Reactivate Caviar Account");
        } else if (category.value == "Payments"){
            addOption(subcatopts,"Credit and Refund Status");
            addOption(subcatopts,"Order Receipt Request");
            addOption(subcatopts,"Promotions and Discounts Questions");
            addOption(subcatopts,"Referral Credits Questions");
            addOption(subcatopts,"Report Unauthorized Charges");
        } else if (category.value == "App Troubleshooting"){
            addOption(subcatopts,"Issues with Caviar app: Android");
            addOption(subcatopts,"Issues with Caviar app: iOS");
            addOption(subcatopts,"Issue with trycaviar.com");
        } else if (category.value == "Order In-Progress Support"){
            addOption(subcatopts,"Adjust Courier Tip");
            addOption(subcatopts,"Courier Feedback");
            addOption(subcatopts,"Did Not Receive Order");
            addOption(subcatopts,"Missing or Incorrect Items from Order");                
            addOption(subcatopts,"No-Contact Delivery");
            addOption(subcatopts,"Order is late");
            addOption(subcatopts,"Restaurant Feedback");
        } else if (category.value == "Post Delivery Support"){
            addOption(subcatopts,"Other");
        } else if (category.value == "Health, Safety or Legal Concern (including allergies or allergic reactions)") {
			addOption(subcatopts,"Report an Accident, Safety or Legal Concern");
        } else if (category.value == "Other"){
			addOption(subcatopts,"About Caviar");
            addOption(subcatopts,"Restaurant Menu Issues");
            addOption(subcatopts,"Restaurant Ratings");
            addOption(subcatopts,"DassPass Questions");
		} else {
            // common options
           
        }

        subcategory.options=subcatopts;
        //subcategory.options[0].selected=true;
        subcategory.value = "";
        subcategory.focus();
        if (subcatopts.length == 1){
            subcategory.disabled = true;
        } else {
            subcategory.disabled = false;
        }
        
    }

    function addOption(arr, lbl, val){
        if (val){
            arr.push({label: lbl, value:val});
        } else {
            arr.push({label: lbl, value:lbl});
        }
    }

    function findGetParameter(parameterName) {
        var result = null,
            tmp = [];
        location.search
            .substr(1)
            .split("&")
            .forEach(function (item) {
              tmp = item.split("=");
              if (tmp[0] === parameterName) result = decodeURIComponent(tmp[1]);
            });
        return result;
    }