    
    var interId,category,subcategory;
    if (window.location.href.indexOf('contactsupport-staging') != -1){
        interId = setInterval(init, 100);
    }

    function init() {
        category = document.getElementById("Caviar_courier_category__c");
        if (category != null){
            deInit();
            category.onchange = catChange;
            subcategory = document.getElementById("Caviar_Courier_Subcategory__c");
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
        if (category.value == "Account"){
            addOption(subcatopts,"Activation status");
            addOption(subcatopts,"Add new vehicle");
            addOption(subcatopts,"Forgot password");
            addOption(subcatopts,"Password Assistance");
            addOption(subcatopts,"Rating");
            addOption(subcatopts,"Other");
        } else if (category.value == "Sign-up and Orientation"){
            addOption(subcatopts,"Activation Kit");
            addOption(subcatopts,"Background check");
            addOption(subcatopts,"Orientation");
            addOption(subcatopts,"Sign-up status");
            addOption(subcatopts,"Other");
        } else if (category.value == "Payments"){
            addOption(subcatopts,"Fast Pay");
            addOption(subcatopts,"Missing weekly payment");
            addOption(subcatopts,"Order pay-out-of pocket reimbursement");
            addOption(subcatopts,"Pay Incentives");
            addOption(subcatopts,"Referrals");
            addOption(subcatopts,"Other");
        } else if (category.value == "Troubleshooting"){
            addOption(subcatopts,"Caviar App: Android");
            addOption(subcatopts,"Caviar App: iOS");
            addOption(subcatopts,"Other");
        } else if (category.value == "Order Support"){
            addOption(subcatopts,"Other");
        } else if (category.value == "Health, Safety or Legal Concern") {
            addOption(subcatopts,"Other");
        } else if (category.value == "Other"){
			addOption(subcatopts,"Report an accident, safety, or legal concern");
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