({
    init : function(component) {
        var self = this;
        // Get store request from Salesforce
        self.getStoreRequest(component
            , function(result) {
                // Get store data from Nimda
                self.getStoreData(component
                    , component.get("v.storeId")
                    , function(result) {
                        // Get store partnership data from Nimda
                        self.getStorePartnershipData(component
                            , component.get("v.storeId")
                            , function(result) {
                                // Get store pos data from Nimda
                                self.getStorePosData(component
                                    , component.get("v.storeId")
                                    , function(result) {
                                        let paymentAcctId = component.get("v.paymentAcctId");
                                        if (!$A.util.isEmpty(paymentAcctId)){
                                            // Get payment account data from Nimda
                                            self.getPaymentAccountData(component
                                                , paymentAcctId
                                                , function(result) {
                                                    component.set("v.isLoading", false);
                                                }
                                                , function(error) {
                                                    component.set("v.isLoading", false);
                                                }
                                            );
                                        } else {
                                            component.set("v.isLoading", false);
                                        }
                                    }
                                    , function(error) {
                                        component.set("v.isLoading", false);
                                    }
                                );
                            }
                            , function(error) {
                                component.set("v.isLoading", false);
                            }
                        );
                    }
                    , function(error) {
                        component.set("v.isLoading", false);
                    }
                );
            }
            , function(error) {
                component.set("v.isLoading", false);
                self.handleException(component, error);  
            }
        );
    },    
    getPreviousStep : function(component) {
        // Store Id passed into the previous step is null. Reset store selection in the Search Store window
        this.fireNimdaSyncEvent(component, component.get("v.previousStep"), null);   
    },    
    fireNimdaSyncEvent: function(component, step, value) {
        var nimdaSyncEvent = component.getEvent("LDdNimdaSyncEvent");
        nimdaSyncEvent.setParams({
            step: step
            , value: value
            , version: component.get("v.version")
        });
        nimdaSyncEvent.fire();
    },
    handleValueChange: function(component, property, value, type, scale){
        switch (property) {
            case 'order_protocol':
                component.set("v.isOrderProtocolPOS", value == component.get("v.ORDER_PROTOCOL_POINT_OF_SALE"));             
                this.updateStoreData(component, 'confirm_protocol', this.getConfirmProtocol(value));                         
                break;
            case 'contact_emails':
                this.updateStoreData(component, 'error_report_emails', value);                         
                break;                
            default:
                this.updateStoreData(component, property, value, type, scale);
                this.updateStorePartnershipData(component, property, value, type, scale);   
                break;
        }        
    },
    updateStoreData: function(component, property, value, type, scale){
        var storeData = component.get("v.storeData");
        var hasChanged = false;
        for (var i=0; i<storeData.length; i++){
            if (storeData[i].property === property){
                var newValue;
                if (['number','currency','percent'].indexOf(storeData[i].type) > -1){
                    newValue = ( storeData[i].scale > 0
                                    ? parseFloat(value).toFixed(storeData[i].scale)
                                    : parseInt(value) 
                                ) 
                } else {
                    newValue = value;
                }
                storeData[i].newValue = newValue;
                hasChanged = true;
            }
        }
        if (hasChanged){
            component.set("v.storeData", storeData);
        }
    },
    updateStorePartnershipData: function(component, property, value, type, scale){
        var storePartnershipData = component.get("v.storePartnershipData");
        var hasChanged = false;
        for (var i=0; i<storePartnershipData.length; i++){
            if (storePartnershipData[i].property === property){
                storePartnershipData[i].newValue = value;
                hasChanged = true;
            }
        }
        if (hasChanged){
            component.set("v.storePartnershipData", storePartnershipData);
        }
    },    
    getConfirmProtocol: function(value){
        var confirmProtocol = null;
        switch (value) {
            case 'IPAD':
                confirmProtocol = 'ROBOCALL_LONG_DELAY';
                break;
            case 'EMAIL':
            case 'FAX':
                confirmProtocol = 'ROBOCALL_SIMPLE';
                break
            case 'OTHER':
            case 'POINT_OF_SALE':
            case 'PHONE':  
                confirmProtocol = 'NO_CONFIRMATION';
                break                                                           
            default:
                break;
        }
        return confirmProtocol;
    },
    getStoreData: function(component, storeId, success, failure){
        var self = this;
        this.clearErrors(component);        
        var storeData = component.get("v.DEFAULT_STORE_DATA"); //Default store data
        var storeRequest = component.get("v.storeRequest"); //original data from Salesforce
        var ORDER_PROTOCOL_POS = component.get("v.ORDER_PROTOCOL_POINT_OF_SALE");
        this.getStore(component
            , storeId
            , function(result) {
                try {
                    // Parse data and retrieve relevant attributes
                    let data = JSON.parse(result);
                    // Populate the store data 
                    for (var i=0; i<storeData.length; i++){
                        var property = storeData[i].property;
                        // process each store data property
                        var oldValue = self.getValue(data[property], storeData[i].type, storeData[i].scale);
                        var newValue = self.getValue(storeRequest[property], storeData[i].type, storeData[i].scale);                        
                        switch(property){
                            case 'id':
                                storeData[i].oldValue = oldValue;
                                storeData[i].newValue = (newValue!=null ? newValue : oldValue);   
                                break;
                            case 'name':
                                storeData[i].oldValue = oldValue;
                                storeData[i].newValue = (newValue!=null ? newValue : oldValue);   
                                component.set("v.storeName", data.name);
                                break;                                                            
                            case 'business_id':
                                storeData[i].oldValue = data.business.id;
                                storeData[i].newValue = (newValue!=null ? newValue : oldValue);   
                                break;
                            case 'market_id':
                                storeData[i].oldValue = data.market.id;
                                storeData[i].newValue = data.market.id;
                                break;
                            case 'submarket_id':
                                storeData[i].oldValue = data.submarket.id;
                                storeData[i].newValue = data.submarket.id;
                                break;
                            case 'street_address':
                                var street = data.address.street;
                                if ($A.util.isEmpty(street)){
                                    street = data.address.printable_address.split(',')[0];
                                }
                                storeData[i].oldValue = street;
                                storeData[i].newValue = (newValue!=null ? newValue : street);
                                break;
                            case 'city':
                                storeData[i].oldValue = data.address.city;
                                storeData[i].newValue = (newValue!=null ? newValue : data.address.city);
                                break; 
                            case 'state':
                                storeData[i].oldValue = data.address.state;
                                storeData[i].newValue = (newValue!=null ? newValue : data.address.state);
                                break;
                            case 'zipcode':
                                storeData[i].oldValue = data.address.zip_code;
                                storeData[i].newValue = (newValue!=null ? newValue : data.address.zip_code);
                                break;
                            case 'country':
                                storeData[i].oldValue = data.address.country;
                                storeData[i].newValue = data.address.country;
                                break;
                            case 'phone_number':
                            case 'fax_number':
                                storeData[i].oldValue = (data.address.country === 'Australia') 
                                                        ? ( property === 'phone_number'
                                                            ? self.formatPhoneNumber(oldValue, 'AU')
                                                            : self.formatFaxNumber(oldValue, 'AU')
                                                        )
                                                        : oldValue;
                                storeData[i].newValue = (newValue!=null ? newValue : storeData[i].oldValue);
                                storeData[i].placeholder = ((data.address.country === 'Australia') ? '### ### ###' : '(###) ###-####');
                                storeData[i].pattern = ((data.address.country === 'Australia') ? '^\d{3}\s\d{3}\s\d{3}' : '^\(\d{3}\)\s\d{3}-\d{4}');
                                break;
                            case 'payment_account_id':
                                storeData[i].oldValue = oldValue;
                                storeData[i].newValue = (newValue!=null ? newValue : oldValue);
                                component.set("v.paymentAcctId", oldValue); 
                                break;
                            case 'order_protocol':
                                storeData[i].oldValue = oldValue;
                                storeData[i].newValue = (newValue!=null ? newValue : oldValue);
                                if (storeData[i].newValue!=null && storeData[i].newValue === ORDER_PROTOCOL_POS){
                                    component.set("v.isOrderProtocolPOS", true);
                                } 
                                break;
                            case 'error_report_frequency':
                                switch(oldValue){
                                    case 'daily':
                                    case 'daily + weekly':
                                    case 'Daily + Weekly':
                                        storeData[i].oldValue = 'daily';
                                        storeData[i].newValue = newValue;   
                                        break;
                                    case 'weekly':
                                    case 'Weekly':
                                        storeData[i].oldValue = 'weekly';
                                        storeData[i].newValue = newValue;   
                                        break;                            
                                    default:
                                        storeData[i].oldValue = '';
                                        storeData[i].newValue = newValue;                            
                                        break;
                                }                    
                                break;                                                                                                
                            default:
                                storeData[i].oldValue = oldValue;
                                storeData[i].newValue = (newValue!=null ? newValue : oldValue);                            
                                break;
                        }
                    }
                    component.set("v.storeData", storeData);
                    if (success) {
                        success.call(self, result);
                    }                    
                } catch(e) {
                    component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                    component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                    if (failure) {
                        failure.call(self, e);
                    }                    
                }                       
            }
            , function(error) {
                self.handleException(component, error);
                if (failure) {
                    failure.call(self, error);
                }                                    
            }
        );
    },
    getStorePartnershipData: function(component, storeId, success, failure){
        var self = this;
        this.clearErrors(component);        
        var storePartnershipData = component.get("v.DEFAULT_STORE_PARTNERSHIP_DATA"); //Default store partnership data
        var storeRequest = component.get("v.storeRequest"); //original data from Salesforce
        this.getStorePartnership(component
            , storeId
            , function(result) {
                try {
                    // Parse data and retrieve relevant attributes
                    let data = JSON.parse(result);
                    // Populate the store data 
                    for (var i=0; i<storePartnershipData.length; i++){
                        var property = storePartnershipData[i].property;
                        // process each store partnership data property
                        var oldValue = self.getValue(data[property], storePartnershipData[i].type, storePartnershipData[i].scale);
                        var newValue = self.getValue(storeRequest[property], storePartnershipData[i].type, storePartnershipData[i].scale);
                        switch(property){
                            case 'subscription_commission_rate':
                            case 'subscription_flat_fee':
                                storePartnershipData[i].oldValue = oldValue;
                                storePartnershipData[i].newValue = newValue;   
                                break;
                            default:
                                storePartnershipData[i].oldValue = oldValue;
                                storePartnershipData[i].newValue = (newValue!=null ? newValue : oldValue);                            
                                break;
                        }                                
                    }
                    component.set("v.storePartnershipData", storePartnershipData);
                    if (success) {
                        success.call(self, result);
                    }                    
                } catch(e) {
                    component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                    component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                    if (failure) {
                        failure.call(self, e);
                    }                    
                }                       
            }
            , function(error) {
                let storePartnershipNotExists = false;
                if (error.message){
                    try {
                        let errorData = JSON.parse(error.message);
                        let errorMessage = '';
                        if (errorData.errorType == 'Response Error' && errorData.calloutResponse){
                            let calloutResponse = JSON.parse(errorData.calloutResponse);
                            for(var prop in calloutResponse) {
                                if (prop != 'statusCode'){
                                    errorMessage += (prop + ' : ' + calloutResponse[prop] + '; ');
                                }
                            }                    
                        }
                        if (errorMessage.indexOf('Store partnership does not exist')>-1){
                            storePartnershipNotExists = true;
                        }
                    } catch(e) {
                    }
                }
                if (storePartnershipNotExists){
                    for (var i=0; i<storePartnershipData.length; i++){
                        var property = storePartnershipData[i].property;
                        // process each store partnership data property
                        var oldValue = null;
                        var newValue = self.getValue(storeRequest[property], storePartnershipData[i].type, storePartnershipData[i].scale);
                        storePartnershipData[i].oldValue = oldValue;
                        storePartnershipData[i].newValue = (newValue!=null ? newValue : oldValue);
                    }
                    component.set("v.storePartnershipData", storePartnershipData);
                    if (success) {
                        success.call(self, null);
                    } 
                } else {
                    self.handleException(component, error);
                    if (failure) {
                        failure.call(self, error);
                    }
                }                                    
            }
        );
    },
    getStorePosData: function(component, storeId, success, failure){
        var self = this;
        this.clearErrors(component);        
        var storePosData = component.get("v.DEFAULT_STORE_POS_DATA"); //Default store pos data
        var storeRequest = component.get("v.storeRequest"); //original data from Salesforce
        this.getStorePOS(component
            , storeId
            , function(result) {
                try {
                    // Parse data and retrieve relevant attributes
                    let data = JSON.parse(result);
                    // Populate the store data 
                    for (var i=0; i<storePosData.length; i++){
                        var property = storePosData[i].property;
                        // process each store pos data property
                        var oldValue = self.getValue(data[property], storePosData[i].type, storePosData[i].scale);
                        var newValue = self.getValue(storeRequest[property], storePosData[i].type, storePosData[i].scale);
                        switch(property){
                            case 'location_id':
                            case 'provider_type':
                                storePosData[i].oldValue = oldValue;
                                storePosData[i].newValue = (newValue!=null ? newValue : oldValue);  
                                break;
                            default:
                                storePosData[i].oldValue = oldValue;
                                storePosData[i].newValue = (newValue!=null ? newValue : oldValue);                            
                                break;
                        }                                
                    }
                    component.set("v.storePosData", storePosData);
                    if (success) {
                        success.call(self, result);
                    }                    
                } catch(e) {
                    component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                    component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                    if (failure) {
                        failure.call(self, e);
                    }                    
                }                       
            }
            , function(error) {
                let storePosNotExists = false;
                if (error.message){
                    try {
                        let errorData = JSON.parse(error.message);
                        let errorMessage = '';
                        if (errorData.errorType == 'Response Error' && errorData.calloutResponse){
                            let calloutResponse = JSON.parse(errorData.calloutResponse);
                            for(var prop in calloutResponse) {
                                if (prop != 'statusCode'){
                                    errorMessage += (prop + ' : ' + calloutResponse[prop] + '; ');
                                }
                            }                    
                        }
                        if (errorMessage.indexOf('Not found')>-1){
                            storePosNotExists = true;
                        }
                    } catch(e) {
                    }
                }
                if (storePosNotExists){
                    for (var i=0; i<storePosData.length; i++){
                        var property = storePosData[i].property;
                        // process each store partnership data property
                        var oldValue = null;
                        var newValue = self.getValue(storeRequest[property], storePosData[i].type, storePosData[i].scale);
                        storePosData[i].oldValue = oldValue;
                        storePosData[i].newValue = (newValue!=null ? newValue : oldValue);
                    }
                    component.set("v.storePosData", storePosData);
                    if (success) {
                        success.call(self, null);
                    } 
                } else {
                    self.handleException(component, error);
                    if (failure) {
                        failure.call(self, error);
                    }
                }                                    
            }
        );
    },    
    getPaymentAccountData: function(component, paymentAccountId, success, failure){
        var self = this;
        this.clearErrors(component);        
        this.getPaymentAccount(component
            , paymentAccountId
            , function(result) {
                try {
                    // Parse data and retrieve relevant attributes
                    let data = JSON.parse(result);
                    if (!$A.util.isEmpty(data.stripe_account_id)){
                        component.set("v.stripeAcctId", String(data.stripe_account_id));
                    }
                    if (data.stripe_account && data.stripe_account.external_account && !$A.util.isEmpty(data.stripe_account.external_account.fingerprint)){
                        component.set("v.stripeBankAcctId", String(data.stripe_account.external_account.fingerprint));
                    }
                    if (success) {
                        success.call(self, result);
                    }                    
                } catch(e) {
                    if (success) {
                        success.call(self, result);
                    }             
                }                       
            }
            , function(error) {
                if (success) {
                    success.call(self, result);
                }                                    
            }
        );
    },    
    getValue: function(value, type, scale){
        var retVal = null;
        if (!$A.util.isEmpty(value)){
            type = $A.util.isEmpty(type) ? 'string' : type;
            scale = $A.util.isEmpty(scale) ? 0 : scale;
            var dataType =  (   (['number','currency','percent'].indexOf(type) > -1)
                            ?   type
                            :   (   (typeof value === 'boolean')
                                    ? 'boolean'
                                    :   (   $A.util.isArray(value)
                                            ? 'array'
                                            : 'string'
                                        )
                                )
                            ); 
            switch (dataType){
                case 'number':
                case 'currency':
                case 'percent':
                    retVal = (scale > 0 ? parseFloat(value).toFixed(scale) : parseInt(value));
                    break;
                case 'boolean':
                    retVal = value.toString();
                    break;
                case 'array':
                    retVal = value[0].toString();
                    break;                    
                default:
                    retVal = value.toString();
                    break;
            }
        }
        return retVal;
    },
    handleUpdateStorePos: function(component, success, failure){
        var self = this;
        var modifiedStorePosData = self.getModifiedStorePosData(component);
        var modifiedStorePosDataHasProperties = self.hasProperties(modifiedStorePosData);
        if (modifiedStorePosDataHasProperties){
            self.updateStorePOS(component
            , JSON.stringify(modifiedStorePosData)
            , function(result) {
                if (success) {
                    success.call(self, result);
                }
            }
            , function(error) {
                self.handleException(component, error);
                if (failure) {
                    failure.call(self, error);
                }
            });                                                            
        } else {
            if (success) {
                success.call(self);
            }            
        }               
    },    
    handleUpdateStore: function(component){
        var self = this;
        var modifiedStoreData = self.isFullOnboarding(component) ? self.getModifiedStoreData(component, false) : self.getModifiedStoreData(component);
        var modifiedStoreDataHasProperties = self.hasProperties(modifiedStoreData);
        var modifiedStorePartnershipData = self.getModifiedStorePartnershipData(component);
        var modifiedStorePartnershipDataHasProperties = self.hasProperties(modifiedStorePartnershipData);
        var modifiedAccountStoreData = self.getModifiedAccountStoreData(component);
        var modifiedOpportunityStoreData = self.getModifiedOpportunityStoreData(component);
        var modifiedDMStoreData = self.getModifiedDMStoreData(component);
        var nimdaHistoryData = self.isFullOnboarding(component) ? self.getNimdaHistoryData(component, false) : self.getNimdaHistoryData(component);
        var applyUpdateToAccountAndOpportunity = (!$A.util.isEmpty(modifiedAccountStoreData) 
                                                    || !$A.util.isEmpty(modifiedOpportunityStoreData)
                                                    || !$A.util.isEmpty(modifiedDMStoreData));

        console.log(modifiedAccountStoreData);
        console.log(modifiedOpportunityStoreData);
        console.log(modifiedDMStoreData);
        console.log(nimdaHistoryData);
        console.log('applyUpdateToAccountAndOpportunity = ' + applyUpdateToAccountAndOpportunity);

        if (modifiedStoreDataHasProperties || modifiedStorePartnershipDataHasProperties){
            component.set("v.isLoading", true);
            // Update store
            if (modifiedStoreDataHasProperties){
                self.updateStore(component
                    , JSON.stringify(modifiedStoreData)
                    , function(result) {
                        if (modifiedStorePartnershipDataHasProperties){
                            self.updateStore(component
                                , JSON.stringify(modifiedStorePartnershipData)
                                , function(result) {
                                    self.insertNimdaHistoryRecords(component
                                        , nimdaHistoryData
                                        , function(result) {
                                            if (applyUpdateToAccountAndOpportunity){
                                                self.updateAccountAndOpportunity(component
                                                    , modifiedAccountStoreData
                                                    , modifiedOpportunityStoreData
                                                    , modifiedDMStoreData
                                                    , function(result) {
                                                        self.finish(component, 'success', 'Store updated successfully!');
                                                    }
                                                    , function(error) {
                                                        self.handleException(component, error);
                                                        component.set("v.isLoading", false);  
                                                    }
                                                );
                                            } else {
                                                self.finish(component, 'success', 'Store updated successfully!');
                                            }                                            
                                        }
                                        , function(error) {
                                            self.handleException(component, error);
                                            component.set("v.isLoading", false);
                                        }
                                    );
                                }
                                , function(error) {
                                    self.handleException(component, error);
                                    component.set("v.isLoading", false);
                                }
                            );
                        } else {
                            self.insertNimdaHistoryRecords(component
                                , nimdaHistoryData
                                , function(result) {
                                    if (applyUpdateToAccountAndOpportunity){
                                        self.updateAccountAndOpportunity(component
                                            , modifiedAccountStoreData
                                            , modifiedOpportunityStoreData
                                            , modifiedDMStoreData
                                            , function(result) {
                                                self.finish(component, 'success', 'Store updated successfully!');
                                            }
                                            , function(error) {
                                                self.handleException(component, error);
                                                component.set("v.isLoading", false);  
                                            }
                                        );
                                    } else {
                                        self.finish(component, 'success', 'Store updated successfully!');
                                    }                                            
                                }
                                , function(error) {
                                    self.handleException(component, error);
                                    component.set("v.isLoading", false);
                                }
                            );
                        }
                    }
                    , function(error) {
                        component.set("v.isLoading", false); 
                        self.handleException(component, error);
                    }
                );
            } else if (modifiedStorePartnershipDataHasProperties){
                self.updateStore(component
                    , JSON.stringify(modifiedStorePartnershipData)
                    , function(result) {
                        self.insertNimdaHistoryRecords(component
                            , nimdaHistoryData
                            , function(result) {
                                if (applyUpdateToAccountAndOpportunity){
                                    self.updateAccountAndOpportunity(component
                                        , modifiedAccountStoreData
                                        , modifiedOpportunityStoreData
                                        , modifiedDMStoreData
                                        , function(result) {
                                            self.finish(component, 'success', 'Store updated successfully!');
                                        }
                                        , function(error) {
                                            self.handleException(component, error);
                                            component.set("v.isLoading", false);  
                                        }
                                    );
                                } else {
                                    self.finish(component, 'success', 'Store updated successfully!');
                                }                                            
                            }
                            , function(error) {
                                self.handleException(component, error);
                                component.set("v.isLoading", false);
                            }
                        );
                    }
                    , function(error) {
                        self.handleException(component, error);
                        component.set("v.isLoading", false);  
                    }
                );
            }
        } else if (applyUpdateToAccountAndOpportunity){
            component.set("v.isLoading", true);
            self.updateAccountAndOpportunity(component
                , modifiedAccountStoreData
                , modifiedOpportunityStoreData
                , modifiedDMStoreData
                , function(result) {
                    self.finish(component, 'success', 'Store updated successfully!');
                }
                , function(error) {
                    self.handleException(component, error);
                    component.set("v.isLoading", false);  
                }
            );
        } else {
            component.set("v.isLoading", true);
            self.finish(component, 'success', 'No changes found!');
        }       
    },
    getModifiedStoreData: function(component, postUpdate){
        var data = component.get("v.storeData");
        var account = component.get("v.account");
        var postUpdateProperties = component.get("v.POST_FULL_ONBOARDING_STORE_UPDATE_PROPERTIES");
        var countryCode = account.BillingCountryCode;
        var isModified = false;
        var modifiedData = {};
        var street_address = null;
        var city = null;
        var state = null;
        var zipcode = null;
        var country = null;
        var email = null;
        var phone_number = null;
        var fax_number = null;
        var hasAddressChanged = false;
        var hasOrderProtocolChanged = false;
        for (var i=0; i<data.length; i++){
            var property = data[i].property;
            var readOnly = data[i].readOnly;
            var oldValue = data[i].oldValue;
            var newValue = data[i].newValue;
            if  (   (typeof postUpdate !== 'undefined')
                    &&
                    (   (postUpdate && postUpdateProperties.indexOf(property) == -1)
                        ||
                        (!postUpdate && postUpdateProperties.indexOf(property) > -1)
                    )
                ) {
                continue;
            }            
            if (!$A.util.isEmpty(newValue)){
                if (oldValue !== newValue){
                    isModified = true;
                    // Only modified values are sent to Nimda
                    switch (property){
                        case 'contact_emails':
                        case 'error_report_emails':
                            modifiedData[property] = [newValue];
                            break;
                        case 'error_report_frequency':
                            if (newValue === 'daily'){
                                modifiedData[property] = 'daily';
                            }
                            if (newValue === 'weekly'){
                                modifiedData[property] = 'weekly';
                            }                            
                            break;                            
                        case 'payment_protocol':
                            if (newValue === 'Dasher Red Card'){
                                modifiedData[property] = 'dasher_red_card';
                            }
                            if (newValue === 'Direct Deposit'){
                                modifiedData[property] = 'direct_deposit';
                            }                            
                            break;
                        case 'street_address':
                        case 'city':
                        case 'state':
                        case 'zipcode':
                            hasAddressChanged = true; 
                            break;
                        case 'phone_number':
                        case 'fax_number':
                            modifiedData[property] = (countryCode == 'AU' ? ('+61' + newValue.replace(/\s/g, '')) : newValue);
                            break;
                        case 'order_protocol':
                            hasOrderProtocolChanged = true;
                            modifiedData[property] = newValue;
                            break;                                                            
                        default:
                            modifiedData[property] = newValue;
                            break;
                    }
                }
            }
            //collect address
            switch (property){
                case 'street_address':
                    street_address = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    break;
                case 'city':
                    city = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    break;
                case 'state':
                    state = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    break;
                case 'zipcode':
                    zipcode = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    break;
                case 'country':
                    country = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    break;
                case 'email':
                    email = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    break;
                case 'phone_number':
                    var phoneVal = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    if (!$A.util.isEmpty(phoneVal)){
                        phone_number = (countryCode == 'AU' ? ('+61' + phoneVal.replace(/\s/g, '')) : phoneVal);
                    } else {
                        phone_number = null;
                    }
                    break;
                case 'fax_number':
                    var faxVal = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    if (!$A.util.isEmpty(faxVal)){
                        fax_number = (countryCode == 'AU' ? ('+61' + faxVal.replace(/\s/g, '')) : faxVal);
                    } else {
                        fax_number = null;
                    }
                    break;                                    
            }
        }
        if (hasAddressChanged){
            modifiedData['address'] = {'printable_address' : street_address + ', ' + city + ', ' + state + ' ' + zipcode + ', ' + country};
        }
        if (hasOrderProtocolChanged && !$A.util.isEmpty(modifiedData['order_protocol'])){
            switch (modifiedData['order_protocol']){
                case 'EMAIL':
                    modifiedData['email'] = email;
                    break;
                case 'PHONE':
                    modifiedData['phone_number'] = phone_number;
                    break;
                case 'FAX':
                    modifiedData['fax_number'] = fax_number;
                    break;
                case 'POINT_OF_SALE':
                    modifiedData['special_instructions_max_length'] = '0';
                    break;                                                            
            }
        }
        return (isModified ? modifiedData : null);        
    },    
    getModifiedStorePartnershipData: function(component){
        var data = component.get("v.storePartnershipData");
        var isModified = false;
        var modifiedData = {};
        for (var i=0; i<data.length; i++){
            var property = data[i].property;
            var readOnly = data[i].readOnly;
            var oldValue = data[i].oldValue;
            var newValue = data[i].newValue;
            if (!$A.util.isEmpty(newValue)){
                if (oldValue !== newValue){
                    isModified = true;
                }
                // if a store partnership is modified, every non-null value counts as Nimda creates a new Store Partnership record
                modifiedData[property] = newValue; 
            }
        }
        return (isModified ? modifiedData : null);        
    },
    getModifiedStorePosData: function(component){
        var data = component.get("v.storePosData");
        var isModified = false;
        var modifiedData = {};
        var isOrderProtocolPOS = component.get("v.isOrderProtocolPOS");
        if (!isOrderProtocolPOS){
            return null;
        }
        for (var i=0; i<data.length; i++){
            var property = data[i].property;
            var readOnly = data[i].readOnly;
            var oldValue = data[i].oldValue;
            var newValue = data[i].newValue;
            if (!$A.util.isEmpty(newValue)){
                if (oldValue !== newValue){
                    isModified = true;
                }
                // if a store pos is modified, every non-null value counts as Nimda creates a new Store point of sale record
                modifiedData[property] = newValue; 
            }
        }
        return (isModified ? modifiedData : null);        
    },    
    getModifiedAccountStoreData: function(component){
        var self = this;
        var data = component.get("v.storeData");
        var isModified = false;
        var account = component.get("v.account");
        var nimdaToAccountPropertyMap = component.get("v.NIMDA_TO_ACCOUNT_PROPERTY_MAP");
        var modifiedAccountStoreData = {'sobjectType': 'Account', 'Id': account.Id};
        for (var i=0; i<data.length; i++){
            var property = data[i].property;
            var newValue = data[i].newValue;
            var accountProperty = nimdaToAccountPropertyMap[property];
            if (!$A.util.isEmpty(accountProperty) && (!$A.util.isEmpty(newValue))) {
                // Only modified values are sent to Salesforce
                switch (property){
                    case 'price_range':
                        var oldPropValue = (!$A.util.isEmpty(account[accountProperty])) ? account[accountProperty].length : null;
                        var newPropValue = newValue;
                        if (newPropValue != oldPropValue){
                            isModified = true;
                            var priceRangeMap = component.get("v.PRICE_RANGE_NIMDA_TO_ACCOUNT_MAP");
                            modifiedAccountStoreData[accountProperty] = priceRangeMap[newPropValue];                                
                        }
                        break;
                    case 'fulfills_own_deliveries_disabled':
                        var oldPropValue = (!$A.util.isEmpty(account[accountProperty])) ? account[accountProperty] : false;
                        var newPropValue = (newValue === 'true');
                        if (newPropValue != oldPropValue){
                            isModified = true;
                            modifiedAccountStoreData[accountProperty] = newPropValue;                                
                        }
                        break;                         
                    default:
                        if (self.isValueModified(account, accountProperty, newValue)){
                            isModified = true;
                            modifiedAccountStoreData[accountProperty] = newValue;
                        }                    
                        break;
                }                
            }
        }
        return (isModified ? modifiedAccountStoreData : null);        
    },    
    getModifiedOpportunityStoreData: function(component){
        var self = this;
        var data = component.get("v.storeData");
        var isModified = false;
        var opportunity = component.get("v.opportunity");
        var nimdaToOpportunityPropertyMap = component.get("v.NIMDA_TO_OPPORTUNITY_PROPERTY_MAP");
        var modifiedOpportunityStoreData = {'sobjectType': 'Opportunity', 'Id': opportunity.Id, 'Nimda_Sync_Step__c': component.get("v.STEP_UPDATE_STORE")
                                            , 'Nimda_Sync_Error_Type__c': '', 'Nimda_Sync_Error_Message__c': ''
                                            , 'Nimda_Sync_Callout_Request__c': '', 'Nimda_Sync_Callout_Response__c': ''};
        for (var i=0; i<data.length; i++){
            var property = data[i].property;
            var newValue = data[i].newValue;
            var opportunityProperty = nimdaToOpportunityPropertyMap[property];
            if (!$A.util.isEmpty(opportunityProperty) && (!$A.util.isEmpty(newValue))) {
                // Only modified values are sent to Salesforce
                switch (property){
                    default:
                        if (self.isValueModified(opportunity, opportunityProperty, newValue)){
                            isModified = true;
                            modifiedOpportunityStoreData[opportunityProperty] = newValue;
                        }                    
                        break;
                }                
            }
        }
        // Process for backfilling of Nimda properties on the Opportunity object
        var stripeAcctId = component.get("v.stripeAcctId");
        var stripeAcctIdProperty = 'Stripe_Account__c';
        if (!$A.util.isEmpty(stripeAcctId)) {
            if (self.isValueModified(opportunity, stripeAcctIdProperty, stripeAcctId)){
                isModified = true;
                modifiedOpportunityStoreData[stripeAcctIdProperty] = stripeAcctId;
            }
        }
        var stripeBankAcctId = component.get("v.stripeBankAcctId");
        var stripeBankAcctIdProperty = 'Stripe_Bank_Account__c';
        if (!$A.util.isEmpty(stripeBankAcctId)) {
            if (self.isValueModified(opportunity, stripeBankAcctIdProperty, stripeBankAcctId)){
                isModified = true;
                modifiedOpportunityStoreData[stripeBankAcctIdProperty] = stripeBankAcctId;
            }
        }         
        return (isModified ? modifiedOpportunityStoreData : null);        
    },
    getModifiedDMStoreData: function(component){
        var self = this;
        var data = component.get("v.storeData");
        var isModified = false;
        var opportunity = component.get("v.opportunity");
        var nimdaToDMPropertyMap = component.get("v.NIMDA_TO_DM_PROPERTY_MAP");
        var modifiedDMStoreData = {'sobjectType': 'Contact', 'Id': opportunity.Decision_Maker__c};
        for (var i=0; i<data.length; i++){
            var property = data[i].property;
            var newValue = data[i].newValue;
            var dmProperty = nimdaToDMPropertyMap[property];
            if (!$A.util.isEmpty(dmProperty) && (!$A.util.isEmpty(newValue))) {
                // Only modified values are sent to Salesforce
                switch (property){
                    case 'contact_emails':
                        if (self.isValueModified(opportunity, dmProperty, newValue)){
                            isModified = true;
                            modifiedDMStoreData['Email'] = newValue;
                        }                    
                        break;
                }                
            }
        }
        return (isModified ? modifiedDMStoreData : null);        
    },
    getNimdaHistoryData: function(component, postUpdate){
        var account = component.get("v.account");
        var opportunity = component.get("v.opportunity");
        var postUpdateProperties = component.get("v.POST_FULL_ONBOARDING_STORE_UPDATE_PROPERTIES");
        var data = [component.get("v.storeData"), component.get("v.storePartnershipData")];
        var nimdaHistoryTmpl = {'sobjectType': 'Nimda_History__c', 'Opportunity__c': opportunity.Id, 'Account__c': account.Id, 'Nimda_Table__c': '', 'Field__c': '', 'Original_Value__c': '', 'New_Value__c': ''};
        var nimdaHistoryData = [];
        for (var j=0; j<data.length; j++){
            var nimdaTable = (j==0 ? 'Store' : 'Store Partnership');
            for (var i=0; i<data[j].length; i++){
                var label = data[j][i].label;
                var property = data[j][i].property;
                var newValue = data[j][i].newValue;
                var oldValue = data[j][i].oldValue;
                if  (   (typeof postUpdate !== 'undefined')
                        &&
                        (   (postUpdate && postUpdateProperties.indexOf(property) == -1)
                            ||
                            (!postUpdate && postUpdateProperties.indexOf(property) > -1)
                        )
                    ) {
                    continue;
                }               
                if (!$A.util.isEmpty(newValue)){
                    if (oldValue !== newValue){
                        var historyRecord = JSON.parse(JSON.stringify(nimdaHistoryTmpl));
                        historyRecord['Nimda_Table__c'] = nimdaTable;
                        historyRecord['Field__c'] = label;
                        historyRecord['Original_Value__c'] = String(oldValue);
                        historyRecord['New_Value__c'] = String(newValue);
                        nimdaHistoryData.push(historyRecord);
                    }
                }
            }
        }
        return nimdaHistoryData;        
    },    
    handleFieldErrors : function(component, field, valid){
        this.clearErrors(component);
        var fieldErrors = (!$A.util.isEmpty(component.get("v.fieldErrors")) ? component.get("v.fieldErrors") : []);
        var fieldErrorIndex = -1;
        for (var i=0; i<fieldErrors.length; i++){
            if (field === fieldErrors[i]){
                fieldErrorIndex = i;
            }
        }
        if (!valid){
            if (fieldErrorIndex == -1){
                fieldErrors.push(field);
            }
        } else {
            if (fieldErrorIndex > -1){
                fieldErrors.splice(fieldErrorIndex, 1);
            }
        }
        component.set("v.fieldErrors", fieldErrors);
        if (fieldErrors.length>0){
            component.set("v.errorType", component.get("v.ERROR_TYPE_VALIDATION"));
            component.set("v.errorMessage", 'Please correct fields - ' + fieldErrors.toString());
        }
    },        
    handleException : function(component, error){
        var self = this;
        if (error.message){
            try {
                let errorData = JSON.parse(error.message);
                component.set("v.errorType", errorData.errorType);
                let errorMessage = '';
                if (errorData.errorType == 'Response Error' && errorData.calloutResponse){
                    let calloutResponse = JSON.parse(errorData.calloutResponse);
                    for(var prop in calloutResponse) {
                        if (prop != 'statusCode'){
                            errorMessage += (prop + ' : ' + calloutResponse[prop] + '; ');
                        }
                    }                    
                } else {
                    errorMessage = errorData.errorMessage;
                }
                console.log(errorMessage);
                component.set("v.errorMessage", errorMessage);
                component.set("v.calloutRequest", errorData.calloutRequest);
                component.set("v.calloutResponse", errorData.calloutResponse);
            } catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", error.message);
            }
        }
    },
    clearErrors : function(component) {
        component.set("v.errorType", "");
        component.set("v.errorMessage", "");
        component.set("v.calloutRequest", "");
        component.set("v.calloutResponse", "");
    },
    formatPhoneNumber: function(phoneNumberString, countryCode) {
        var retVal = null;
        switch (countryCode){
            case 'AU':
                var cleaned = ('' + phoneNumberString).replace(/\s/g, '').replace(/\(/g, '').replace(/\)/g, '').replace(/\-/g, '').replace(/\+/g, '');
                if (cleaned.length >= 9){
                    var input = cleaned.substring(cleaned.length-9);
                    var match = input.match(/^(\d{3})(\d{3})(\d{3})$/)
                    if (match) {
                        retVal = match[1] + ' ' + match[2] + ' ' + match[3];
                    }
                }            
                break;
            default:
                var cleaned = ('' + phoneNumberString).replace(/\D/g, '')
                var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/)
                if (match) {
                    retVal = '(' + match[1] + ') ' + match[2] + '-' + match[3];
                }            
                break;
        }
        return retVal;
    },
    formatFaxNumber: function(faxNumberString, countryCode) {
        var retVal = null;
        switch (countryCode){
            case 'AU':
                var cleaned = ('' + faxNumberString).replace(/\s/g, '').replace(/\(/g, '').replace(/\)/g, '').replace(/\-/g, '').replace(/\+/g, '');
                if (cleaned.length >= 9){
                    var input = cleaned.substring(cleaned.length-9);
                    var match = input.match(/^(\d{3})(\d{3})(\d{3})$/)
                    if (match) {
                        retVal = match[1] + ' ' + match[2] + ' ' + match[3];
                    }
                }            
                break;
            default:
                var match = faxNumberString.match(/^([+]1)(\d{3})(\d{3})(\d{4})$/)
                if (match) {
                    retVal = '(' + match[2] + ') ' + match[3] + '-' + match[4];
                }            
                break;
        }
        return retVal;
    },    
    hasProperties: function(obj){
        for(var prop in obj) {
            if(obj.hasOwnProperty(prop)){
                return true;
            }
        }
        return false;        
    },
    isValueModified: function(obj, prop, newValue){
        return !(!$A.util.isEmpty(obj[prop]) && (obj[prop] == newValue));
    },
    isFullOnboarding: function(component){
        return (component.get("v.selectedAction") === component.get("v.ACTION_FULL_ONBOARDING"));
    },
    finish : function(component, messageType, message) {
        self = this;
        switch (component.get("v.selectedAction")) {
            case component.get("v.ACTION_FULL_ONBOARDING"):
                self.fireNimdaSyncEvent(component
                                , component.get("v.ACTION_FULL_ONBOARDING")
                                ,   {   storeId: component.get("v.storeId"),
                                        paymentAcctId: component.get("v.paymentAcctId"),
                                        stripeAcctId: component.get("v.stripeAcctId"),
                                        stripeBankAcctId: component.get("v.stripeBankAcctId"),
                                        storeUpdateRequest: self.getModifiedStoreData(component, true),
                                        nimdaHistoryData: self.getNimdaHistoryData(component, true)  
                                    }
                            );
                break;
            case component.get("v.ACTION_STORE_UPDATE"):
                self.renderToastCmp(component, function(toastCmp){
                    toastCmp.showToastModel(messageType, message, function(){
                        self.navigateToPreviousPage(component);                
                    });
                });
                break;
            default:
                self.renderToastCmp(component, function(toastCmp){
                    toastCmp.showToastModel(messageType, message, function(){
                        self.navigateToPreviousPage(component);                
                    });
                });
                break;   
        }             
    },
    renderToastCmp: function(component, success){
        var targetCmp = component.find("toastCmpPlaceHolder");
        if ( ($A.util.isEmpty(targetCmp.get("v.body"))) ) {
            $A.createComponent(
                "c:LDdToastCmp",
                {
                    "aura:id" : "toastCmp",
                },
                function(newToastCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        targetCmp.set("v.body", newToastCmp);
                        if (success) {
                            success.call(this, newToastCmp);
                        }
                    }
                }
            );
        }
    },
    navigateToPreviousPage: function(component) {
        if (window.sforce && window.sforce.one){
            var navEvent = $A.get("e.force:navigateToSObject");
            navEvent.setParams({
                "recordId": component.get("v.recordId")
            });
            navEvent.fire();
        } else {         
            window.open("/" + component.get("v.recordId"), "_self");
        }
    },                
    getStore : function(component, storeId, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getStore'
                , { storeId : storeId }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },
    getStorePartnership : function(component, storeId, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getStorePartnership'
                , { storeId : storeId }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },
    getStorePOS : function(component, storeId, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getStorePOS'
                , { storeId : storeId }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },    
    getPaymentAccount : function(component, paymentAccountId, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getPaymentAccount'
                , { paymentAccountId : paymentAccountId }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },    
    getStoreRequest : function(component, success, failure) {
        var self = this;
        var account = component.get("v.account");
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getStoreRequest'
                , { businessId : component.get("v.businessId")
                    , account : component.get("v.account")
                    , opportunity : component.get("v.opportunity")
                }
                , function(result) {
                    try {
                        // Parse data and retrieve relevant attributes
                        let storeRequest = JSON.parse(result);
                        // Update specific properties i.e. remove hardcoding and prepare for Store Update
                        storeRequest.submarket_id = null;
                        storeRequest.is_partner = 'true';
                        storeRequest.is_active = null;
                        storeRequest.payment_protocol = 'Direct Deposit';
                        if (!$A.util.isEmpty(storeRequest.phone_number)){ 
                            storeRequest.phone_number = self.formatPhoneNumber(storeRequest.phone_number, account.BillingCountryCode);
                        }
                        if (!$A.util.isEmpty(storeRequest.fax_number)){ 
                            storeRequest.fax_number = self.formatFaxNumber(storeRequest.fax_number, account.BillingCountryCode);
                        }                        
                        // Get Opportunity record
                        var opportunity = component.get("v.opportunity");
                        storeRequest.contact_emails = (!$A.util.isEmpty(opportunity.DM_Email__c) ? [opportunity.DM_Email__c] : null);
                        storeRequest.error_report_emails = (!$A.util.isEmpty(opportunity.DM_Email__c) ? [opportunity.DM_Email__c] : null);
                        // Default to value 'daily'
                        storeRequest.error_report_frequency = 'daily';
                        // Populate the store request from Salesforce Account and Opportunity 
                        component.set("v.storeRequest", storeRequest);
                        if (success) {
                            success.call(self, result);
                        }                            
                    } catch(e) {
                        component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                        component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                        if (failure) {
                            failure.call(self, e);
                        }                            
                    }
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },
    updateStore : function(component, storeRequest, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'updateStore'
                , { storeId : component.get("v.storeId")
                    , storeRequest : storeRequest
                }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }                    
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },
    updateStorePOS : function(component, storeRequest, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'updateStorePOS'
                , { storeId : component.get("v.storeId")
                    , storeRequest : storeRequest
                }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }                    
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },    
    updateAccountAndOpportunity : function(component, account, opportunity, decisionMaker, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'updateAccountAndOpportunity'
                , { account : account
                    , opportunity : opportunity
                    , decisionMaker : decisionMaker
                }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }                    
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },
    insertNimdaHistoryRecords : function(component, nimdaHistoryData, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'insertNimdaHistoryRecords'
                , { nimdaHistoryRecordsJsonStr : JSON.stringify(nimdaHistoryData) }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }                    
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },                    
})