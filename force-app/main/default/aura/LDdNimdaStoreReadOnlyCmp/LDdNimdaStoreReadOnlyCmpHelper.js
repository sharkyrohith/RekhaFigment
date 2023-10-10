({
    init : function(component) {
        var self = this;
        self.showInfoDialog(component, true, component.get("v.INFO_MESSAGE_RETRIEVING_SALESFORCE"));
        // Get store request from Salesforce
        self.getStoreRequest(component
            , function(result) {
                self.showInfoDialog(component, true, component.get("v.INFO_MESSAGE_RETRIEVING_SALESFORCE"));
                self.getDataModelTemplate(component
                    , function(result) {
                        self.showInfoDialog(component, true, component.get("v.INFO_MESSAGE_RETRIEVING_MIDDLEWARE"));
                        // Get store from Nimda
                        self.getStore(component
                            , component.get("v.storeId")
                            , function(result) {
                                try {
                                    // Parse data and retrieve relevant attributes
                                    let data = JSON.parse(result);
                                    self.getStoreData(component, data);
                                    self.getCheckforTrialOpportunity(component);
                                    self.getStorePartnershipData(component, data.store_partnership);
                                    // Get Data from MFS API
                                    self.getMxAffiliatePrgmAPIData(component , data
                                    , function(response){
                                        self.getDDFeeAttributes(component, data);
                                    	self.getCaviarFeeAttributes(component, data);
                                    	self.getStoreFrontFeeAttributes(component, data);
                                        self.showInfoDialog(component, false, null);
                                    } 
                                    , function(error){
                                        self.showInfoDialog(component, false, null);  
                                        self.handleException(component, error);
                                    }
                                    );
                                    self.showInfoDialog(component, false, null);
                                } catch(e) {
                                    self.showInfoDialog(component, false, null);                       
                                    component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                                    component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                                }                       
                            }
                            , function(error) {
                                self.showInfoDialog(component, false, null);  
                                self.handleException(component, error);
                            }
                        );
                    }
                    , function(error) {
                        self.showInfoDialog(component, false, null);  
                        self.handleException(component, error);
                    }                        
                )
            }
            , function(error) {
                self.showInfoDialog(component, false, null);
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
    getStoreData: function(component, data, success, failure){
        var self = this;
        var storeData = component.get("v.storeModelTemplate"); //Default store model template
        var storeRequest = component.get("v.storeRequest"); //original data from Salesforce
        var ORDER_PROTOCOL_POS = component.get("v.ORDER_PROTOCOL_POINT_OF_SALE");
        var account = component.get("v.account");
        var countryCode = account.BillingCountryCode;
        var businessId = (!$A.util.isEmpty(account.Parent) ? account.Parent.Business_ID__c : null);      
        try {
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
                        storeData[i].newValue = (!$A.util.isEmpty(businessId) ? businessId : null);   
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
                        storeData[i].oldValue = ( property === 'phone_number'
                                                    ? self.formatPhoneNumber(oldValue, countryCode)
                                                    : self.formatFaxNumber(oldValue, countryCode)
                                                )                                                
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
                success.call(self, data);
            }                    
        } catch(e) {
            component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
            component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
            if (failure) {
                failure.call(self, e);
            }                    
        }                       
    },
    getStorePartnershipData: function(component, data, success, failure){
        var self = this;
        var storePartnershipData = component.get("v.storePartnershipModelTemplate"); //Default store partnership model template
        var storeRequest = component.get("v.storeRequest"); //original data from Salesforce
        if (!$A.util.isEmpty(data)){
            try {
                // Populate the store data 
                for (var i=0; i<storePartnershipData.length; i++){
                    var property = storePartnershipData[i].property;
                    // process each store partnership data property
                    var oldValue = self.getValue(data[property], storePartnershipData[i].type, storePartnershipData[i].scale);
                    var newValue = self.getValue(storeRequest[property], storePartnershipData[i].type, storePartnershipData[i].scale);
                    storePartnershipData[i].oldValue = oldValue;
                    storePartnershipData[i].newValue = (newValue!=null ? newValue : oldValue);
                }
                component.set("v.storePartnershipData", storePartnershipData);
                if (success) {
                    success.call(self, data);
                }                    
            } catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                if (failure) {
                    failure.call(self, e);
                }                    
            }                       
        } else {
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
        }
    },
    getMxAffiliatePrgmAPIData : function(component, data, success, failure) {
        // This method returns the data from MFS API for a given StoreId
        var self = this;
        var mxDoorDashAttr = [];
        var mxCaviarAttr = [];
        var mxStoreFrontAttr = [];
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getmxAffiliateProgram'
                , { storeId : component.get("v.storeId") }
                , function(result) {
                     // Parse data and retrieve relevant attributes
                    var response = result.length ? JSON.parse(result) : '';
                    var mxprograms = [];
                    mxprograms = response.programs; // response.hasOwnProperty['programs'] ? response['programs'] : '';
                    if (!$A.util.isEmpty(mxprograms)){
                        for (var i=0; i<mxprograms.length; i++) {
                            let experience = (mxprograms[i].hasOwnProperty('experience')) ? mxprograms[i].experience : null;
                            if(experience == null || experience == 'DOORDASH') { 
                                for(var j=0; j<mxprograms[i].fee_attributes.length; j++) {
                                    let feerate = mxprograms[i].fee_attributes[j].hasOwnProperty('fee_rate') ? mxprograms[i].fee_attributes[j].fee_rate : mxprograms[i].fee_attributes[j].hasOwnProperty('flat_fee_in_cents') ? mxprograms[i].fee_attributes[j].flat_fee_in_cents : null;
                                    mxDoorDashAttr.push({key: mxprograms[i].fee_attributes[j].name, value: feerate});
                                    component.set("v.ddFeeAttributes",mxDoorDashAttr);
                                }
                            }
                            if(experience == 'CAVIAR'){
                                for(var j=0; j<mxprograms[i].fee_attributes.length; j++) {
                                    let feerate = mxprograms[i].fee_attributes[j].hasOwnProperty('fee_rate') ? mxprograms[i].fee_attributes[j].fee_rate : null;
                                    mxCaviarAttr.push({key: mxprograms[i].fee_attributes[j].name, value: feerate});
                                    component.set("v.caviarFeeAttributes",mxCaviarAttr);
                                }
                            }
                            if(experience == 'WHITE_LABELED' || experience == 'STOREFRONT'){
                                for(var j=0; j<mxprograms[i].fee_attributes.length; j++) {
                                    //Additional check for Storefront ,since Storefront has flat fee and fee rate
                                    let feerate = mxprograms[i].fee_attributes[j].hasOwnProperty('fee_rate') ? mxprograms[i].fee_attributes[j].fee_rate : mxprograms[i].fee_attributes[j].hasOwnProperty('flat_fee_in_cents') ? mxprograms[i].fee_attributes[j].flat_fee_in_cents : null;
                                    mxStoreFrontAttr.push({key: 'storefront_'+mxprograms[i].fee_attributes[j].name, value: feerate});
                                    component.set("v.storeFrontFeeAttributes",mxStoreFrontAttr);
                                }
                            }
                        }
                        if (success) {
                            success.call(self, result);
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
    getDDFeeAttributes: function(component, data , success, failure){
        //Get Fee Attributes for DoorDash
        var self = this;
        var opportunity = component.get("v.opportunity");
        var storeRequest = component.get("v.storeRequest");
        var isTrial = component.get("v.isTrialOpp");
        var mxDDVar =  JSON.parse(JSON.stringify(component.get("v.ddFeeAttributes")));
        var mxAffiliatePrgmModelTemplate = component.get("v.ddModelTemplate");
        var mxAffiliatePrgmData = [];
        for (var i=0; i<mxAffiliatePrgmModelTemplate.length; i++){
            mxAffiliatePrgmData.push(mxAffiliatePrgmModelTemplate[i]);
        }
        if (!$A.util.isEmpty(mxDDVar)){
            try {
                // Populate the store data 
                for (var i=0; i<mxAffiliatePrgmData.length; i++){
                    var feevalue = null;
                    var property = mxAffiliatePrgmData[i].property;
                    mxDDVar.forEach(item=>{
                        if(item.key === property){
                         feevalue = item.value;
                        }
                    })
                    // process each store partnership data property
                    var oldValue = self.getValue(feevalue, mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                    var newValue = self.getValue(storeRequest[property], mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                    mxAffiliatePrgmData[i].oldValue = isTrial ? newValue : oldValue;
                    mxAffiliatePrgmData[i].newValue = (newValue!=null ? newValue : oldValue);                      
                }
                component.set("v.ddPrgmData", mxAffiliatePrgmData);
                if (success) {
                    success.call(self, data);
                }                    
            } catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                if (failure) {  
                    failure.call(self, e);
                }                    
            }                       
        } else {
            for (var i=0; i<mxAffiliatePrgmData.length; i++){
                var property = mxAffiliatePrgmData[i].property;
                // process each store partnership data property
                var oldValue = isTrial ? newValue : oldValue;
                var newValue = self.getValue(storeRequest[property], mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                mxAffiliatePrgmData[i].oldValue = oldValue;
                mxAffiliatePrgmData[i].newValue = (newValue!=null ? newValue : oldValue);
            }
            component.set("v.ddPrgmData", mxAffiliatePrgmData);
            if (success) {
                success.call(self, null);
            } 
        }
    },
    getCaviarFeeAttributes: function(component, data , success, failure){
        //Get Fee Attributes for Caviar
        var self = this;
        var opportunity = component.get("v.opportunity");
        var storeRequest = component.get("v.storeRequest");
        var isTrial = component.get("v.isTrialOpp");
        var mxCaviarVar = component.get("v.caviarFeeAttributes");
        var caviarModelTemplate = component.get("v.caviarModelTemplate");
        var mxAffiliatePrgmData = [];
        for (var i=0; i<caviarModelTemplate.length; i++){
            mxAffiliatePrgmData.push(caviarModelTemplate[i]); 
        }
        if (!$A.util.isEmpty(mxCaviarVar)){
            try {
                // Populate the store data 
                for (var i=0; i<mxAffiliatePrgmData.length; i++){
                    var feevalue = null;
                    var property = mxAffiliatePrgmData[i].property;
                    mxCaviarVar.forEach(item=>{
                        if(item.key === property){
                            feevalue = item.value;
                        }
                    })
                    // process each store partnership data property
                    var oldValue = self.getValue(feevalue, mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                    var newValue = self.getValue(storeRequest[property], mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                    mxAffiliatePrgmData[i].oldValue = isTrial ? newValue : oldValue;
                    mxAffiliatePrgmData[i].newValue = (newValue!=null ? newValue : oldValue);                      
                }
                component.set("v.caviarPrgmData", mxAffiliatePrgmData);
                if (success) {
                    success.call(self, data);
                }                    
            } catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                if (failure) {  
                    failure.call(self, e);
                }                    
            }                       
        } else {
            for (var i=0; i<mxAffiliatePrgmData.length; i++){
                var property = mxAffiliatePrgmData[i].property;
                // process each store partnership data property
                var oldValue = null;
                var newValue = self.getValue(storeRequest[property], mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                mxAffiliatePrgmData[i].oldValue = isTrial ? newValue : oldValue;
                mxAffiliatePrgmData[i].newValue = (newValue!=null ? newValue : oldValue);
            }
            component.set("v.caviarPrgmData", mxAffiliatePrgmData);
            if (success) {
                success.call(self, null);
            } 
        }
    },
        getStoreFrontFeeAttributes: function(component, data , success, failure){
        //Get Fee Attributes for StoreFront
        var self = this;
        var opportunity = component.get("v.opportunity");
        var storeRequest = component.get("v.storeRequest");
        var isTrial = component.get("v.isTrialOpp");
        var mxstoreFrontVar = component.get("v.storeFrontFeeAttributes");
        var storeFrontTemp = component.get("v.storefrontTemplate");
        var mxAffiliatePrgmData = [];
        for (var i=0; i<storeFrontTemp.length; i++){
            mxAffiliatePrgmData.push(storeFrontTemp[i]); 
        }
        if (!$A.util.isEmpty(mxstoreFrontVar)){
            try {
                // Populate the store data 
                for (var i=0; i<mxAffiliatePrgmData.length; i++){
                    var feevalue = null;
                    var property = mxAffiliatePrgmData[i].property;
                    mxstoreFrontVar.forEach(item=>{
                        if(item.key === property){
                            feevalue = item.value;
                        }
                    })
                    // process each store partnership data property
                    var oldValue = self.getValue(feevalue, mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                    var newValue = self.getValue(storeRequest[property], mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                    mxAffiliatePrgmData[i].oldValue = isTrial ? newValue : oldValue;
                    mxAffiliatePrgmData[i].newValue = (newValue!=null ? newValue : oldValue);                      
                }
                component.set("v.storeFrontPrgmData", mxAffiliatePrgmData);
                if (success) {
                    success.call(self, data);
                }                    
            } catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                if (failure) {  
                    failure.call(self, e);
                }                    
            }                       
        } else {
            for (var i=0; i<mxAffiliatePrgmData.length; i++){
                var property = mxAffiliatePrgmData[i].property;
                // process each store partnership data property
                var oldValue = null;
                var newValue = self.getValue(storeRequest[property], mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                mxAffiliatePrgmData[i].oldValue = isTrial ? newValue : oldValue;
                mxAffiliatePrgmData[i].newValue = (newValue!=null ? newValue : oldValue);
            }
            component.set("v.storeFrontPrgmData", mxAffiliatePrgmData);
            if (success) {
                success.call(self, null);
            } 
        }
    },
    getValue: function(value, type, scale){
        var self = this;
        var retVal = null;
        if (!$A.util.isEmpty(value)){
            scale = $A.util.isEmpty(scale) ? 0 : scale;
            var dataType =  self.getDataType(value, type); 
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
    getCheckforTrialOpportunity : function (component, success, failure){
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getCheckforTrialOpportunity'
                , { opportunity : component.get("v.opportunity") }
                , function(result) {
                     component.set("v.isTrialOpp", result);
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
    getDataType: function(value, type){
        var dataType = null;
        // if type is not null, then evaluate for number, currency, percent 
        if (!$A.util.isEmpty(type)){
            switch (type){
                case 'number':
                case 'currency':
                case 'percent':
                    dataType = type;
                    break;
                default:
                    break;
            }
        }
        // if type is not one of the above - i.e. number, currency, percent, then evaluate the 'value' for data type 
        if ($A.util.isEmpty(dataType)){
            if (typeof value === 'boolean'){
                dataType = 'boolean';
            } else if ($A.util.isArray(value)) {
                dataType = 'array';
            } else {
                dataType = 'string';
            }
        }       
        return dataType;        
    },
    showInfoDialog : function(component, show, infoMessage){
        component.set("v.infoMessage", (!$A.util.isEmpty(infoMessage) ? infoMessage : ''));
        component.set("v.isLoading", show);       
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
        if ($A.util.isEmpty(phoneNumberString)){
            return retVal;            
        }
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
        if ($A.util.isEmpty(faxNumberString)){
            return retVal;            
        }
        switch (countryCode){
            case 'AU':
                var cleaned = ('' + faxNumberString).replace(/\s/g, '').replace(/\(/g, '').replace(/\)/g, '').replace(/\-/g, '').replace(/\+/g, '').replace(/\./g, '');
                if (cleaned.length >= 9){
                    var input = cleaned.substring(cleaned.length-9);
                    var match = input.match(/^(\d{3})(\d{3})(\d{3})$/)
                    if (match) {
                        retVal = match[1] + ' ' + match[2] + ' ' + match[3];
                    }
                }            
                break;
            default:
                var cleaned = ('' + faxNumberString).replace(/\s/g, '').replace(/\(/g, '').replace(/\)/g, '').replace(/\-/g, '').replace(/\+/g, '').replace(/\./g, '');
                if (cleaned.length >= 10){
                    var input = cleaned.substring(cleaned.length-10);
                    var match = input.match(/^(\d{3})(\d{3})(\d{4})$/)
                    if (match) {
                        retVal = '(' + match[1] + ') ' + match[2] + '-' + match[3];
                    }
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
    finish : function(component) {
        this.fireNimdaSyncEvent(component
            , component.get("v.FULL_ONBOARDING_UPDATE")
            , {}
        );
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
    getDataModelTemplate : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getDataModelTemplate'
                , { onboardingStepName : component.get("v.originatingOnboardingStep") }
                , function(result) {
                    try {
                        // Parse data and retrieve relevant attributes
                        let modelTemplate = JSON.parse(result);
                        component.set("v.storeModelTemplate", modelTemplate['Store']);
                        component.set("v.storePartnershipModelTemplate", modelTemplate['Store Partnership']);
                        component.set("v.storePosModelTemplate", modelTemplate['Store POS']);
                        component.set("v.ddModelTemplate", modelTemplate['MFS DoorDash']);
                        component.set("v.caviarModelTemplate", modelTemplate['MFS Caviar']);
                        component.set("v.storefrontTemplate", modelTemplate['MFS StoreFront']);
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
})