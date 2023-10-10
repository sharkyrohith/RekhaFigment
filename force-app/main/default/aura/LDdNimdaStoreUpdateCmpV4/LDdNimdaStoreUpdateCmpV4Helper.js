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
                        this.getStore(component
                            , component.get("v.storeId")
                            , function(result) {
                                try {
                                    // Parse data and retrieve relevant attributes
                                    let data = JSON.parse(result);
                                    self.getCheckforTrialOpportunity(component);
                                    self.getStoreData(component, data);
                                    self.getStorePartnershipData(component, data.store_partnership);
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
                                    //self.getMxAffiliatePrgmSFData(component, data);
                                    //self.getCaviarSFData(component, data);
                                    //self.getStoreFrontSFData(component, data);
                                    self.getStorePosData(component, data.point_of_sale);
                                    // Use direct DSJ Api to get the payment account data
                                    self.getPaymentAccountData(component
                                        , data
                                        , function(result){
                                            self.showInfoDialog(component, false, null);
                                        } 
                                        , function(error){
                                            self.showInfoDialog(component, false, null);  
                                            self.handleException(component, error);
                                        }
                                    );
                                    
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
                );                        
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
            , isChangeOfOwnership: component.get("v.isChangeOfOwnership")
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
        var storeData = component.get("v.storeModelTemplate"); //Default store data
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
                        storeData[i].oldValue = data.business_id;
                        storeData[i].newValue = (!$A.util.isEmpty(businessId) ? businessId : null);   
                        break;
                    case 'experience':
                        storeData[i].oldValue = oldValue;
                        storeData[i].newValue = (newValue!=null ? newValue : oldValue);   
                        component.set("v.experience", data.experience);
                        break;                        
                    case 'market_id':
                        storeData[i].oldValue = data.market_id;
                        storeData[i].newValue = data.market_id;
                        break;
                    case 'submarket_id':
                        storeData[i].oldValue = data.submarket_id;
                        storeData[i].newValue = data.submarket_id;
                        break;
                    case 'phone_number':
                    case 'fax_number':
                        storeData[i].oldValue = ( property === 'phone_number'
                                                    ? self.formatPhoneNumber(oldValue, countryCode)
                                                    : self.formatFaxNumber(oldValue, countryCode)
                                                )                                                
                        storeData[i].newValue = (newValue!=null ? newValue : storeData[i].oldValue);
                        if (countryCode == 'AU'){
                            storeData[i].placeholder = '### ### ###';
                            storeData[i].pattern = '^\d{3}\s\d{3}\s\d{3}'; 
                        } else if (countryCode == 'JP'){
                            storeData[i].placeholder = '###-####-####';
                            storeData[i].pattern = '^\d{3}-\d{4}-\d{4}'; 
                        } else {
                            storeData[i].placeholder = '(###) ###-####';
                            storeData[i].pattern = '^\(\d{3}\)\s\d{3}-\d{4}'; 
                        }
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
                            case 'Daily':
                                storeData[i].oldValue = 'daily';
                                break;                                
                            case 'daily + weekly':
                            case 'Daily + Weekly':
                                storeData[i].oldValue = 'daily + weekly';
                                break;
                            case 'weekly':
                            case 'Weekly':
                                storeData[i].oldValue = 'weekly';
                                break;                            
                            default:
                                storeData[i].oldValue = '';
                                break;
                        }
                        storeData[i].newValue = (newValue!=null ? newValue : oldValue);                    
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
        var opportunity = component.get("v.opportunity");
        var storeRequest = component.get("v.storeRequest"); //original data from Salesforce
        var storePartnershipModelTemplate = component.get("v.storePartnershipModelTemplate");
        var storePartnershipData = [];
        for (var i=0; i<storePartnershipModelTemplate.length; i++){
            var property = storePartnershipModelTemplate[i].property;
            storePartnershipData.push(storePartnershipModelTemplate[i]); 
        }
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
        // This method returns the fee attribute details from MFS API
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
        // This method displays the fee values for DoorDash Experience.
        var self = this;
        var opportunity = component.get("v.opportunity");
        var storeRequest = component.get("v.storeRequest");
        var isTrial = component.get("v.isTrialOpp");
        var mxDDVar =  JSON.parse(JSON.stringify(component.get("v.ddFeeAttributes")));
        var mxAffiliatePrgmModelTemplate = component.get("v.ddModelTemplate");
        var mxAffiliatePrgmData = [];
        for (var i=0; i<mxAffiliatePrgmModelTemplate.length; i++){
            var property = mxAffiliatePrgmModelTemplate[i].property;
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
                    // process each DoorDash Fee Attribtues
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
                 // process each DoorDash Fee Attribtues
                var oldValue = null;
                var newValue = self.getValue(storeRequest[property], mxAffiliatePrgmData[i].type, mxAffiliatePrgmData[i].scale);
                mxAffiliatePrgmData[i].oldValue = isTrial ? newValue : oldValue;
                mxAffiliatePrgmData[i].newValue = (newValue!=null ? newValue : oldValue);
            }
            component.set("v.ddPrgmData", mxAffiliatePrgmData);
            if (success) {
                success.call(self, null);
            } 
        }
    },
    getCaviarFeeAttributes: function(component, data , success, failure){
        // This method displays the fee values for Caviar Experience.
        var self = this;
        var opportunity = component.get("v.opportunity");
        var isTrial = component.get("v.isTrialOpp");
        var storeRequest = component.get("v.storeRequest");
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
                    // process each Caviar Fee Attribtues
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
                // process each Caviar Fee Attribtues
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
        // This method displays the fee values for Storefront Experience.
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
                    // process each StoreFront Fee Attribtues
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
                // process each StoreFront Fee Attribtues
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
    getStorePosData: function(component, data, success, failure){
        var self = this;
        var storePosData = component.get("v.storePosModelTemplate"); //Default store pos data
        var storeRequest = component.get("v.storeRequest"); //original data from Salesforce
        if (!$A.util.isEmpty(data)){
            try {
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
        }
    },
    // Get payment account data by making the direct call to DSJ API    
    getPaymentAccountData: function(component, data, success, failure){
        var self = this;
        // Extract Payment Account Id
        if (!$A.util.isEmpty(data['payment_account_id'])){
            let paymentAcctId = String(data['payment_account_id']);
            component.set("v.paymentAcctId", paymentAcctId);
            // Check if payment account is in the data response from MuleSoft Get Store API Call
            if (!$A.util.isEmpty(data['payment_account'])){
                let paymentAccount = data['payment_account'];
                if (!$A.util.isEmpty(paymentAccount.stripe_account_id)){
                    component.set("v.stripeAcctId", String(paymentAccount.stripe_account_id));
                }
                if (paymentAccount.stripe_account && paymentAccount.stripe_account.external_account){
                    if (!$A.util.isEmpty(paymentAccount.stripe_account.external_account.fingerprint)){
                        component.set("v.stripeBankAcctId", String(paymentAccount.stripe_account.external_account.fingerprint));
                    }
                }
            }
        }
        if (success) {
            success.call(self, data);
        }                       
            /* DO NOT go to DSJ for Payment Account Data
            // Get payment account from Nimda
            self.getPaymentAccount(component
                , paymentAcctId
                , function(result) {
                    try {
                        // Parse data and retrieve relevant attributes
                        let data = JSON.parse(result);
                        if (!$A.util.isEmpty(data.stripe_account_id)){
                            component.set("v.stripeAcctId", String(data.stripe_account_id));
                        }
                        if (data.stripe_account && data.stripe_account.external_account){
                            if (!$A.util.isEmpty(data.stripe_account.external_account.fingerprint)){
                                component.set("v.stripeBankAcctId", String(data.stripe_account.external_account.fingerprint));
                            }
                        }
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
                    if (failure) {
                        failure.call(self, error);
                    }                                
                }
            );*/
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

        console.log(modifiedAccountStoreData);
        console.log(modifiedOpportunityStoreData);
        console.log(modifiedDMStoreData);
        console.log(nimdaHistoryData);

        self.showInfoDialog(component, true, component.get("v.INFO_MESSAGE_PROCESSING_SALESFORCE"));

        self.updateAccountAndOpportunity(component
            , modifiedAccountStoreData
            , modifiedOpportunityStoreData
            , modifiedDMStoreData
            , function(result) {
                switch (component.get("v.selectedAction")) {
                    case component.get("v.ACTION_FULL_ONBOARDING"):
                        self.finish(component);
                        break;
                    case component.get("v.ACTION_STORE_UPDATE"):
                        if (modifiedStoreDataHasProperties || modifiedStorePartnershipDataHasProperties){
                            self.showInfoDialog(component, true, component.get("v.INFO_MESSAGE_PROCESSING_MIDDLEWARE"));
                            self.updateStore(component
                                , function(result) {
                                    // handlePolledResult method subscribes to results returned from MuleSoft
                                    let pollingTimeout = component.get("v.NIMDA_SYNC_POLLING_TIMEOUT");
                                    console.log('LDdNimdaStoreUpdateCmpv4: Polling timeout = ' + pollingTimeout);
                                    window.setTimeout(
                                        $A.getCallback(function() {
                                            if ($A.util.getBooleanValue(component.get("v.isLoading"))){
                                                self.handlePolledResult(component, false);
                                            }
                                        }), pollingTimeout
                                    );                                    
                                } 
                                , function(error) {
                                    self.handleException(component, error);
                                    self.showInfoDialog(component, false, null);  
                                }
                            );
                        } else {
                            self.finish(component, 'success', 'No changes found!');
                        }
                        break;
                    default:
                        break;   
                }
            }
            , function(error) {
                self.handleException(component, error);
                self.showInfoDialog(component, false, null);  
            }
        );
    },
    handlePolledResult : function(component, success){
        var self = this;
        self.getNimdaSyncStatus(component, function(result){
            let opportunity = result;
            if (!$A.util.isEmpty(opportunity.Nimda_Sync_Error_Message__c)){
                component.set("v.errorType", opportunity.Nimda_Sync_Error_Type__c);
                if (!$A.util.isEmpty(opportunity.Nimda_Sync_Callout_Response__c)){
                    component.set("v.errorMessage", opportunity.Nimda_Sync_Callout_Response__c);
                } else {
                    component.set("v.errorMessage", opportunity.Nimda_Sync_Error_Message__c);
                }
                self.showInfoDialog(component, false, null); 
            } else {
                if (success){
                    self.finish(component, 'success', 'Store updated successfully!');
                } else {
                    component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                    component.set("v.errorMessage", component.get("v.ERROR_POLLING_TIMEOUT_MESSAGE"));
                    self.showInfoDialog(component, false, null);                         
                }
            }                    
        });        
    },    
    getModifiedStoreData: function(component, postUpdate){
        var data = component.get("v.storeData");
        var account = component.get("v.account");
        var postUpdateProperties = component.get("v.POST_FULL_ONBOARDING_STORE_UPDATE_PROPERTIES");
        var countryCode = account.BillingCountryCode;
        var isModified = false;
        var modifiedData = {};
        var email = null;
        var phone_number = null;
        var fax_number = null;
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
                        case 'phone_number':
                        case 'fax_number':
                            if (countryCode == 'AU'){
                                modifiedData[property] = ('+61' + newValue.replace(/\s/g, ''));
                            } else if (countryCode == 'JP') {
                                modifiedData[property] = ('+81' + newValue.replace(/\s/g, '').replace(/\-/g, ''));
                            } else {
                                modifiedData[property] = newValue;
                            }
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
            //collect properties
            switch (property){
                case 'email':
                    email = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    break;
                case 'phone_number':
                    var phoneVal = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    if (!$A.util.isEmpty(phoneVal)){
                        if (countryCode == 'AU'){
                            phone_number = ('+61' + phoneVal.replace(/\s/g, ''));
                        } else if (countryCode == 'JP') {
                            phone_number = ('+81' + phoneVal.replace(/\s/g, '').replace(/\-/g, ''));
                        } else {
                            phone_number = phoneVal;
                        }                        
                    } else {
                        phone_number = null;
                    }
                    break;
                case 'fax_number':
                    var faxVal = (!$A.util.isEmpty(newValue) ? newValue : oldValue);
                    if (!$A.util.isEmpty(faxVal)){
                        if (countryCode == 'AU'){
                            fax_number = ('+61' + faxVal.replace(/\s/g, ''));
                        } else if (countryCode == 'JP') {
                            fax_number = ('+81' + faxVal.replace(/\s/g, '').replace(/\-/g, ''));
                        } else {
                            fax_number = faxVal;
                        }                          
                    } else {
                        fax_number = null;
                    }
                    break;                                    
            }
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
        var countryCode = account.BillingCountryCode;
        var paymentAcctId = component.get("v.paymentAcctId");
        var stripeAcctId = component.get("v.stripeAcctId");
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
                    case 'phone_number':
                        var oldPropValue = (!$A.util.isEmpty(account[accountProperty])) ? self.formatPhoneNumber(account[accountProperty], countryCode) : null;
                        var newPropValue = newValue;
                        if (newPropValue != oldPropValue){
                            isModified = true;
                            if (!$A.util.isEmpty(newPropValue)){
                                if (countryCode == 'JP'){
                                    modifiedAccountStoreData[accountProperty] = ('+81' + ' ' + newPropValue);
                                } else {
                                    modifiedAccountStoreData[accountProperty] = newPropValue;
                                }                        
                            } else {
                                modifiedAccountStoreData[accountProperty] = null;
                            }                               
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
        // Handle Payment Account Id
        paymentAcctId = (!$A.util.isEmpty(stripeAcctId)) ? paymentAcctId : null;
        var paymentAcctIdProperty = 'Payment_Account_ID__c';
        if (self.isValueModified(account, paymentAcctIdProperty, paymentAcctId)){
            isModified = true;
            modifiedAccountStoreData[paymentAcctIdProperty] = paymentAcctId;
        }        
        return (isModified ? modifiedAccountStoreData : null);        
    },    
    getModifiedOpportunityStoreData: function(component){
        var self = this;
        var data = component.get("v.storeData");
        var isModified = false;
        var opportunity = component.get("v.opportunity");
        var nimdaToOpportunityPropertyMap = component.get("v.NIMDA_TO_OPPORTUNITY_PROPERTY_MAP");
        var modifiedOpportunityStoreData = {'sobjectType': 'Opportunity', 'Id': opportunity.Id, 'Nimda_Sync_Step__c': component.get("v.STEP_INITIALIZE")
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
        stripeAcctId = (!$A.util.isEmpty(stripeAcctId)) ? stripeAcctId : null;
        var stripeAcctIdProperty = 'Stripe_Account__c';
        if (self.isValueModified(opportunity, stripeAcctIdProperty, stripeAcctId)){
            isModified = true;
            modifiedOpportunityStoreData[stripeAcctIdProperty] = stripeAcctId;
        }

        var stripeBankAcctId = component.get("v.stripeBankAcctId");
        stripeBankAcctId = (!$A.util.isEmpty(stripeBankAcctId)) ? stripeBankAcctId : null;
        var stripeBankAcctIdProperty = 'Stripe_Bank_Account__c';
        if (self.isValueModified(opportunity, stripeBankAcctIdProperty, stripeBankAcctId)){
            isModified = true;
            modifiedOpportunityStoreData[stripeBankAcctIdProperty] = stripeBankAcctId;
        }
     
        return modifiedOpportunityStoreData;        
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
                            errorMessage += (prop + ' : ' + JSON.stringify(calloutResponse[prop]) + '; ');
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
                case 'NZ':
                
                    var cleaned = ('' + phoneNumberString).replace(/\s/g, '').replace(/\(/g, '').replace(/\)/g, '').replace(/\-/g, '').replace(/\+/g, '');
                    console.log('cleaned NZ '+cleaned);
                    //for AUS testing
                    var cleaned = cleaned.startsWith('64') ? cleaned.slice(2) : cleaned;
                    //remove after testing
                    if (cleaned.length >= 10){
                        var input = cleaned.substring(cleaned.length-10);
                        var match = input.match(/^(\d{2})(\d{4})(\d{4})$/)
                        if (match) {
                            retVal = match[1] + ' ' + match[2] + ' ' + match[3];
                            console.log('retVal 10'+retVal);
                        }
                    }
                    else if (cleaned.length >= 9){
                        var input = cleaned.substring(cleaned.length-9);
                        var match = input.match(/^(\d{3})(\d{3})(\d{3})$/)
                        if (match) {
                            retVal = match[1] + ' ' + match[2] + ' ' + match[3];
                        }
                    }
                    else if (cleaned.length >= 8){
                        var input = cleaned.substring(cleaned.length-9);
                        var match = input.match(/^(\d{2})(\d{3})(\d{3})$/)
                        if (match) {
                            retVal = match[1] + ' ' + match[2] + ' ' + match[3];
                        }
                    } 
                    break;
            case 'JP':
                var phoneNumber = phoneNumberString.startsWith('81') ? phoneNumberString.slice(2) : phoneNumberString;
                var cleaned = ('' + phoneNumber).replace(/\s/g, '').replace(/\(/g, '').replace(/\)/g, '').replace(/\-/g, '').replace(/\+/g, '');
                if (cleaned.length >= 11){
                    var input = cleaned.substring(cleaned.length-11);
                    var match = input.match(/^(\d{3})(\d{4})(\d{4})$/)
                    if (match) {
                        retVal = match[1] + '-' + match[2] + '-' + match[3];
                    }
                } else if (cleaned.length >= 10){
                    var input = cleaned.substring(cleaned.length-10);
                    var match = input.match(/^(\d{2})(\d{4})(\d{4})$/)
                    if (match) {
                        retVal = match[1] + '-' + match[2] + '-' + match[3];
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
            case 'JP':
                var faxNumber = faxNumberString.startsWith('81') ? faxNumberString.slice(2) : faxNumberString;
                var cleaned = ('' + faxNumber).replace(/\s/g, '').replace(/\(/g, '').replace(/\)/g, '').replace(/\-/g, '').replace(/\+/g, '').replace(/\./g, '');
                if (cleaned.length >= 11){
                    var input = cleaned.substring(cleaned.length-11);
                    var match = input.match(/^(\d{3})(\d{4})(\d{4})$/)
                    if (match) {
                        retVal = match[1] + '-' + match[2] + '-' + match[3];
                    }
                } else if (cleaned.length >= 10){
                    var input = cleaned.substring(cleaned.length-10);
                    var match = input.match(/^(\d{2})(\d{4})(\d{4})$/)
                    if (match) {
                        retVal = match[1] + '-' + match[2] + '-' + match[3];
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
    isFullOnboarding: function(component){
        return (component.get("v.selectedAction") === component.get("v.ACTION_FULL_ONBOARDING"));
    },
    finish : function(component, messageType, message) {
        self = this;
        switch (component.get("v.selectedAction")) {
            case component.get("v.ACTION_FULL_ONBOARDING"):
                var step = $A.util.getBooleanValue(component.get("v.isChangeOfOwnership"))
                            ? component.get("v.CHANGE_OF_OWNERSHIP_UPDATE")
                            : component.get("v.FULL_ONBOARDING_UPDATE");
                self.fireNimdaSyncEvent(component
                                , step
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
                        storeRequest.active = null;
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
    
    updateStore : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'updateStore'
                , { storeId : component.get("v.storeId")
                    , opportunityId : component.get("v.recordId")
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
    getNimdaSyncStatus : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getNimdaSyncStatus'
                , { opportunityId : component.get("v.recordId") }
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
                        console.log('@@',modelTemplate);
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