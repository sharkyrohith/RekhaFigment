({
    initCmp: function(component, event, helper) {
        component.set("v.spinner", true);
        var comm = helper.getCommunity(component, event, helper);
        var lang = helper.getURLParam('language');
        if (!lang){
            lang = 'en_US';
        }
        var page = helper.getPage(component, event, helper);
        component.set("v.community",comm);
        component.set("v.language",lang);
        component.set("v.page",page);
        var action = component.get("c.initCommunityWebCase");
        action.setParams({  community : comm, language: lang, page : page });
        action.setCallback(this, function(response) {
            component.set("v.spinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var wcObj = response.getReturnValue();
                component.set("v.webCaseObj", wcObj);
                component.set("v.subcatOptions", wcObj.emptyOptions);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('ERROR:'  + errors[0].message);
                    }
                } else {
                    console.log('ERROR:'  + "Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },
    checkIPaddress : function(component, event, helper) {
        var clientRSP = JSON.parse('{"subnational_division_code":"wa","country_code":"us"}');
        var regionURL = $A.get("$Label.c.DDCommunity_IP_Region_URL");
        console.log(clientRSP); console.log(regionURL);
        try {
            var xhttp_GEO = new XMLHttpRequest();
            xhttp_GEO.open('GET', regionURL);
            xhttp_GEO.send();
            xhttp_GEO.onreadystatechange = function() {
                if(xhttp_GEO.readyState == 4 && xhttp_GEO.status === 200) {
                    clientRSP = JSON.parse(xhttp_GEO.responseText);
                    console.log(clientRSP);
                    var country  = clientRSP.country_code;
                    var state = clientRSP.subnational_division_code;
                    console.log(country);   console.log(state);
                    if (((country !== undefined) && (country !== 'us')) || ((state !== undefined) && (state !== 'ca'))) {
                        console.log("Suppressing California Dasher Questions");
                        component.set("v.suppress", true);
                    } else {
                        component.set("v.suppress", false);
                    }
                } 
            }
        } catch(err) {
            console.log(err);
        } finally {
            var country  = clientRSP.country_code;
            var state = clientRSP.subnational_division_code;
            console.log(country);   console.log(state);
            if (((country !== undefined) && (country !== 'us')) || ((state !== undefined) && (state !== 'ca'))) {
                console.log("Suppressing California Dasher Questions");
                component.set("v.suppress", true);
            }
        }
    },
    onCategoryChange : function(component, event, helper) {
        var comm = helper.getCommunity(component, event, helper);
        var lang = helper.getURLParam('language');
        if (!lang){
            lang = 'en_US';
        }
    
        var wcObj = component.get("v.webCaseObj");
        var catVal = wcObj.category;
        var catSubcatOptions = wcObj.catSubcatOptions;
        var subcatOptions = wcObj.emptyOptions;
        if (catVal != "") {
            for (var opt in catSubcatOptions) {
                if (catSubcatOptions[opt].picklistVal === catVal){
                    subcatOptions = catSubcatOptions[opt].dependentPicklists;
                }
            }
            component.set("v.subcatOptions", subcatOptions);
            
            if(subcatOptions.length > 1){
                component.set("v.disableSubcategory" , false);  
            }else{
                component.set("v.disableSubcategory" , true); 
            }
            
        } else {
            component.set("v.subcatOptions", subcatOptions);
            component.set("v.disableSubcategory" , true);
        }
    },
    initVerifyRecaptcha: function(component, event, helper) {
        var self = this;
        var isCaviar = window.location.href.includes('trycaviar');
        document.addEventListener('grecaptchaVerified', $A.getCallback(function(e) {
            if (e.detail.action !== 'submitCase') {
                return;
            }

            var action = component.get("c.verifyRecaptcha");
            action.setParams({
                recaptchaResponse: e.detail.response,
                isCaviar: isCaviar
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    if (response.getReturnValue()){
                        component.set("v.recaptchaVerified", true);
                    } else {
                        component.set("v.recaptchaVerified", false);
                    }
                    self.onSubmitCase(component,event,self);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log('ERROR:'  + errors[0].message);
                        }
                    } else {
                        console.log('ERROR:'  + "Unknown error");
                    }
                }
            });
            
            $A.enqueueAction(action);
        }));
    },
    onSubmitCase: function(component, event, helper) {
        // begin prevent double click
        let button = component.find("submitButton");
        //if (button.get('v.disabled') == true) return;
        //button.set('v.disabled', true);
        //  end  prevent double click
        var page = component.get("v.page");
        var errors = this.validateCaseFields(component, event, helper, page);
        if (errors.length === 0){
            component.set("v.spinner", true);
            component.set("v.saveError", false);
            component.set("v.errorMessages", errors);
            var wcObj = component.get("v.webCaseObj");
            var comm = component.get("v.community");
            var lang = component.get("v.language");
            if (!lang){
                lang = "en_US";
            }
            var action = component.get("c.saveCommunityWebCase");
            action.setParams({  community: comm, language: lang, wrpString: JSON.stringify(wcObj), page: page});
            action.setCallback(this, function(response) {
                component.set("v.spinner", false); 
                var state = response.getState();
                if (state === "SUCCESS") {
                    var resp = JSON.parse(response.getReturnValue());
                    if (resp.success){ 
                        component.set("v.saved", true);
                    } else {
                        component.set("v.saveError", true);
                        button.set('v.disabled', false);
                        console.log('ERROR:'  + resp[0].message);
                    }

                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log('ERROR:'  + errors[0].message);
                        }
                    } else {
                        console.log('ERROR:'  + "Unknown error");
                    }
                    component.set("v.saveError", true);
                    button.set('v.disabled', false);
                }
            });
            $A.enqueueAction(action);
        } else {
            component.set("v.spinner", false); 
            component.set("v.errorMessages", errors);
            button.set('v.disabled', false);
        }
      
    },
    validateCaseFields: function(component, event, helper, page) {
        var comm = component.get("v.community");
        var requiredMsg = $A.get("$Label.c.DdCommunity_Required")
        var recaptchaMsg = $A.get("$Label.c.DdCommunity_Recaptcha_Error")
        var retVal = [];
        var wcObj = component.get("v.webCaseObj");
        var verified = component.get("v.recaptchaVerified");
        if (!verified){
            retVal.push(recaptchaMsg);
        }

        if (page == "contactsupport"){
            if (comm == "consumers"){
                if (this.isEmpty(wcObj.name)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
                }
        
                if (this.isEmpty(wcObj.email)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
                }

                if (this.isEmpty(wcObj.phone)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
                }

                if (this.isEmpty(wcObj.category)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.categoryLabel));
                }
        
                if (this.isEmpty(wcObj.subcategory)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.subcategoryLabel));
                }
            } else if (comm == "dashers"){
                if (this.isEmpty(wcObj.name)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
                }
        
                if (this.isEmpty(wcObj.email)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
                }

                if (this.isEmpty(wcObj.phone)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
                }

                if (this.isEmpty(wcObj.category)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.categoryLabel));
                }
        
                if (this.isEmpty(wcObj.subcategory)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.subcategoryLabel));
                }
            } else if (comm == "merchants"){
                if (this.isEmpty(wcObj.restaurantName)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.restaurantNameLabel));
                }
                if (this.isEmpty(wcObj.storeId)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.storeIdLabel));
                }
                if (this.isEmpty(wcObj.name)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
                }
        
                if (this.isEmpty(wcObj.email)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
                }

                if (this.isEmpty(wcObj.phone)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
                }

                if (this.isEmpty(wcObj.category)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.categoryLabel));
                }
        
                if (this.isEmpty(wcObj.subcategory)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.subcategoryLabel));
                }
            } else if (comm == "diners"){
                if (this.isEmpty(wcObj.name)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
                }
        
                if (this.isEmpty(wcObj.email)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
                }

                if (this.isEmpty(wcObj.phone)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
                }

                if (this.isEmpty(wcObj.category)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.categoryLabel));
                }
        
                if (this.isEmpty(wcObj.subcategory)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.subcategoryLabel));
                }
            } else if (comm == "couriers"){
                if (this.isEmpty(wcObj.name)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
                }
        
                if (this.isEmpty(wcObj.email)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
                }

                if (this.isEmpty(wcObj.caviarServiceRegion)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.caviarServiceRegionLabel));
                }
                if (this.isEmpty(wcObj.issueTopic)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.issueTopicLabel));
                }
            } else if (comm == "restaurants"){
                if (this.isEmpty(wcObj.restaurantName)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.restaurantNameLabel));
                }

                if (this.isEmpty(wcObj.restaurantAddress)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.restaurantAddressLabel));
                }

                if (this.isEmpty(wcObj.name)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
                }
        
                if (this.isEmpty(wcObj.email)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
                }

                if (this.isEmpty(wcObj.phone)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
                }

                if (this.isEmpty(wcObj.category)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.categoryLabel));
                }
        
                if (this.isEmpty(wcObj.subcategory)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.subcategoryLabel));
                }
            } else if (comm == "work"){
                if (this.isEmpty(wcObj.name)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
                }
        
                if (this.isEmpty(wcObj.email)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
                }

                if (this.isEmpty(wcObj.company)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.companyLabel));
                }

                if (this.isEmpty(wcObj.phone)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
                }

                if (this.isEmpty(wcObj.issueCategory)){
                    retVal.push(requiredMsg.replace("{0}", wcObj.issueCategoryLabel));
                }
            }
        } else if (page == "healthandsafety"){
            if (this.isEmpty(wcObj.name)){
                retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
            }
    
            if (this.isEmpty(wcObj.email)){
                retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
            }

            if (this.isEmpty(wcObj.phone)){
                retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
            }

            if (this.isEmpty(wcObj.typeOfIncident)){
                retVal.push(requiredMsg.replace("{0}", wcObj.typeOfIncidentLabel));
            }
        
        } else if (page == 'emailcfcsupport'){
            if (this.isEmpty(wcObj.name)){
                retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
            }
    
            if (this.isEmpty(wcObj.email)){
                retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
            }

            if (this.isEmpty(wcObj.phone)){
                retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
            }

            if (this.isEmpty(wcObj.restaurantName)){
                retVal.push(requiredMsg.replace("{0}", wcObj.restaurantNameLabel));
            }

            if (this.isEmpty(wcObj.restaurantAddress)){
                retVal.push(requiredMsg.replace("{0}", wcObj.restaurantAddressLabel));
            }

            if (this.isEmpty(wcObj.caviarServiceRegion)){
            retVal.push(requiredMsg.replace("{0}", wcObj.caviarServiceRegionLabel));
            }
        
            if (this.isEmpty(wcObj.issueCategory)){
                retVal.push(requiredMsg.replace("{0}", wcObj.issueCategoryLabel));
            }
        } else if (page == 'emailliveopssupport'){
            if (this.isEmpty(wcObj.name)){
                retVal.push(requiredMsg.replace("{0}", wcObj.nameLabel));
            }
    
            if (this.isEmpty(wcObj.email)){
                retVal.push(requiredMsg.replace("{0}", wcObj.emailLabel));
            }

            if (this.isEmpty(wcObj.phone)){
                retVal.push(requiredMsg.replace("{0}", wcObj.phoneLabel));
            }

            if (this.isEmpty(wcObj.caviarServiceRegion)){
            retVal.push(requiredMsg.replace("{0}", wcObj.caviarServiceRegionLabel));
            }
        
            if (this.isEmpty(wcObj.issueCategory)){
                retVal.push(requiredMsg.replace("{0}", wcObj.issueCategoryLabel));
            }
        }

        if (this.isEmpty(wcObj.description)){
            retVal.push(requiredMsg.replace("{0}", wcObj.descriptionLabel));
        }

        return retVal;
    },
    getCommunity: function(component, event, helper) {
        var url = window.location.href.split("/");
        return url[3];
        
    },
    getPage: function(component, event, helper) {
        var url = window.location.href;
        if (url.includes('contactsupport') 
            || url.includes('emailsupport')){
            return "contactsupport";
        } else if (url.includes('healthandsafety')){
            return "healthandsafety";
        } else if (url.includes('emailcfcsupport')){
            return "emailcfcsupport";
        } else if (url.includes('emailliveopssupport')){
            return "emailliveopssupport";
        }
    },
    getURLParam : function (parameterName) {
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
    },
    showToast : function(component, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": msg
        });
        toastEvent.fire();
    },
    isEmpty: function (str) {
        return (!str || 0 === str.length);
    }
});