    
    var interId,category,subcategory;
    if (window.location.href.indexOf('emailsupport') != -1){
        interId = setInterval(init, 100);
    } 

    function init() {
        category = document.getElementById("Caviar_Topic__c");
        if (category != null){
            debugger;
            deInit();
            category.onchange = catChange;
            subcategory = document.getElementById("Caviar_Type_of_Request__c");
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
        if (category.value == "Account Question"){
            addOption(subcatopts,"Change of Ownership");
            addOption(subcatopts,"Dashboard");
            addOption(subcatopts,"iPad / Merchant App");
            addOption(subcatopts,"Payouts");
            addOption(subcatopts,"Other");
        } else if (category.value == "Getting Started - Onboarding"){
            addOption(subcatopts,"Completing your profile");
            addOption(subcatopts,"Creating items");
            addOption(subcatopts,"Getting your menu setup");
            addOption(subcatopts,"Receiving orders");
            addOption(subcatopts,"Other");
        } else if (category.value == "Marketing/Growth"){
            addOption(subcatopts,"Branded print material");
            addOption(subcatopts,"Caviar link for my website/website build");
            addOption(subcatopts,"Growing orders");
        } else if (category.value == "Menu Change"){
            addOption(subcatopts,"Add photos only");
            addOption(subcatopts,"Change entire menu");
            addOption(subcatopts,"Changes to prices only");
            addOption(subcatopts,"Change to part of my menu (10 or less items)");                
            addOption(subcatopts,"Change to part of my menu (More than 10 items)");
            addOption(subcatopts,"Hours Update");
            addOption(subcatopts,"NMB");
            addOption(subcatopts,"Request Photoshoot");
            addOption(subcatopts,"Other"); 	
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