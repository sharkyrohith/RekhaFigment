({
    initCmp: function(component, event, helper) {
        var prechatFields = component.find("prechatAPI").getPrechatFields();
        component.set("v.prechatFields", prechatFields);
        component.set("v.community", helper.getCommunity(component, event, helper));
        var dasherOptions = [{  label : $A.get("$Label.c.Community_Prechat_None"), 
                                value: ""},
                             {  label : $A.get("$Label.c.DdCommunity_Yes"), 
                                value: "Yes"},
                             {  label : $A.get("$Label.c.DdCommunity_No"), 
                                value: "No"}];
        component.set("v.dashOpts", dasherOptions);                       
        helper.getState(component, event, helper);
        helper.getFieldInfo(component, event, helper, prechatFields);
        helper.getCategoryOpts(component, event, helper);

    },
    getCategoryOpts: function(component, event, helper) { 
        var categoryFieldName = component.get("v.categoryFieldName");
        var subcategoryFieldName = component.get("v.subcategoryFieldName");
        var noneOpt = {label : $A.get("$Label.c.Community_Prechat_None"), 
                        value: ""};
        var action = component.get("c.initCommunityPrechat");
        action.setParams({
            objName : "Case",
            parentField : categoryFieldName,
            childField : subcategoryFieldName
        });
        action.setCallback(this, function(response){
         	var status = response.getState();
            if(status === "SUCCESS"){
                var resp = response.getReturnValue();
                component.set("v.allCatOptions", resp);
                component.set("v.showDasherW2", resp.showDasherW2);

                var catOptions = [];

                catOptions.push(noneOpt);

                for (var cat in resp.catPicklist) {
                    catOptions.push(resp.catPicklist[cat]);
                }

                component.set("v.catOptions", catOptions)
            }
        });
        
        $A.enqueueAction(action);
    },
    onCategoryChange : function(component, event, helper) {
        var noneOpt = { label : $A.get("$Label.c.Community_Prechat_None"), 
                        value: ""};
        var catVal = component.get("v.category");
        var allCatOptions = component.get("v.allCatOptions");
        if (catVal != noneOpt) {
            var subcatValues = allCatOptions.depPicklist[catVal];
            var subcatValueList = [];
            subcatValueList.push(noneOpt);
            for (var i = 0; i < subcatValues.length; i++) {
                subcatValueList.push(subcatValues[i]);
            }
            component.set("v.subcatOptions", subcatValueList);
            
            if(subcatValueList.length > 0){
                component.set("v.disableSubcategory" , false);  
            }else{
                component.set("v.disableSubcategory" , true); 
            }
            
        } else {
            component.set("v.subcatOptions", [noneOpt]);
            component.set("v.disableSubcategory" , true);
        }
      
    },
    onStartButtonClick: function(component, event, helper) {
        var errors = this.validateChatFields(component, event, helper);
        if (errors.length === 0){
            var fields = this.createChatFieldsArray(component, event, helper);
            if(component.find("prechatAPI").validateFields(fields).valid) {
                component.find("prechatAPI").startChat(fields);
            } else {
                console.log("Prechat fields not valid.");
            }
        } else {
            component.set("v.errorMessages", errors);
        }
      
    },
    validateChatFields: function(component, event, helper) {
        var requiredMsg = $A.get("$Label.c.DdCommunity_Required")
        var retVal = [];
        var firstNameLabel = component.get("v.firstNameLabel");
        var firstName = component.get("v.firstName");
        if (this.isEmpty(firstName)){
            retVal.push(requiredMsg.replace("{0}", firstNameLabel));
        }

        var lastNameLabel = component.get("v.lastNameLabel");
        var lastName = component.get("v.lastName");
        if (this.isEmpty(lastName)){
            retVal.push(requiredMsg.replace("{0}", lastNameLabel));
        }

        var emailLabel = component.get("v.emailLabel");
        var email = component.get("v.email");
        if (this.isEmpty(email)){
            retVal.push(requiredMsg.replace("{0}", emailLabel));
        }

        var phoneLabel = component.get("v.phoneLabel");
        var phone = component.get("v.phone");
        if (this.isEmpty(phone)){
            retVal.push(requiredMsg.replace("{0}", phoneLabel));
        }

        var categoryLabel = component.get("v.categoryLabel");
        var category = component.get("v.category");
        if (this.isEmpty(category)){
            retVal.push(requiredMsg.replace("{0}", categoryLabel));
        }

        var subcategoryLabel = component.get("v.subcategoryLabel");
        var subcategory = component.get("v.subcategory");
        if (this.isEmpty(subcategory)){
            retVal.push(requiredMsg.replace("{0}", subcategoryLabel));
        }

        return retVal;
    },
	createChatFieldsArray: function(component, event, helper) {
        var community = component.get("v.community");
        var retVal = [];
        retVal.push({
                        label: component.get("v.firstNameLabel"),
                        value: component.get("v.firstName"),
                        name: "FirstName"
                    });
        retVal.push({
                        label: component.get("v.lastNameLabel"),
                        value: component.get("v.lastName"),
                        name: "LastName"
                    });	
        retVal.push({
                        label: component.get("v.emailLabel"),
                        value: component.get("v.email"),
                        name: "Email"
                    });	
                    
        retVal.push({
                        label: component.get("v.phoneLabel"),
                        value: component.get("v.phone"),
                        name: "Phone"
                    });	
        retVal.push({
                        label: component.get("v.categoryLabel"),
                        value: component.get("v.category"),
                        name: component.get("v.categoryFieldName")
                    });
        retVal.push({
                        label: component.get("v.subcategoryLabel"),
                        value: component.get("v.subcategory"),
                        name: component.get("v.subcategoryFieldName")
                    });	

        if (community === 'merchant'){
            retVal.push({
                label: component.get("v.storeIDLabel"),
                value: component.get("v.storeID"),
                name: "Store_ID__c"
            });
        }
        if (community === 'dasher'){
            retVal.push({
                label: component.get("v.chatIssueDetailsLabel"),
                value: helper.getDasherInfo(component, event, helper),
                name: "Chat_Issue_Details__c"
            });
        }
        return retVal;
    },
    getFieldInfo: function(component, event, helper, prechatFields) {
        prechatFields.forEach(function(field) {
            if (field.name.includes('FirstName')){
                component.set("v.firstNameLabel", field.label);
            } else if (field.name.includes('LastName')){
                component.set("v.lastNameLabel", field.label);
            } else if (field.name.includes('Email')){
                component.set("v.emailLabel", field.label);
            } else if (field.name.includes('Phone')){
                component.set("v.phoneLabel", field.label);
            } else if (field.name.includes('Subcategory')){
                component.set("v.subcategoryLabel", field.label);
                component.set("v.subcategoryFieldName", field.name);
            } else if (field.name.includes('Category')){
                component.set("v.categoryLabel", field.label);
                component.set("v.categoryFieldName", field.name);
            } else if (field.name == "Store_ID__c"){
                component.set("v.storeIDLabel", field.label);
            } else if(field.name == "Chat_Issue_Details__c"){
                component.set("v.chatIssueDetailsLabel", field.label);
            }
        });
    },
    getCommunity: function(component, event, helper) {
        if (window.location.href.includes('consumers')){
            return 'consumer';
        } else if (window.location.href.includes('dasher')){
            return 'dasher';
        } else if (window.location.href.includes('merchants')){
            return 'merchant';
        } else if (window.location.href.includes('restaurants')){
            return 'merchant';
        } else if (window.location.href.includes('diners')){
            return 'consumer'
        }

        return '';
    },
    getState: function(component, event, helper) {
        var deflt = '';
        var regionURL = $A.get("$Label.c.DDCommunity_IP_Region_URL");
        var xhttp_GEO = new XMLHttpRequest();
        xhttp_GEO.open('GET', regionURL);
        try {
            xhttp_GEO.send();
            xhttp_GEO.onreadystatechange = function() {
                if(xhttp_GEO.readyState == 4 && xhttp_GEO.status === 200) {
                    var country = JSON.parse(xhttp_GEO.responseText);
                    var divisionCode = country.subnational_division_code; 
                    component.set('v.state', divisionCode);
                } 
            }
        } catch(err){
            console.log(err);
        }
        component.set('v.state', deflt);
    },
    getDasherInfo: function(component, event, helper) {
        var retVal = "";
        var californiaDasher = component.get("v.californiaDasher");
        var onADash = component.get("v.onADash");
        if (californiaDasher == "Yes" && onADash == "Yes"){
            retVal = "California Dasher on a Dash";
        } else if (californiaDasher == "Yes" && onADash == "No"){
            retVal = "California Dasher NOT on a Dash";
        } else if (californiaDasher == "No"){
            retVal = "Not a California Dasher";
        }
        return retVal;
    },
    isEmpty: function (str) {
        return (!str || 0 === str.length);
    }
});