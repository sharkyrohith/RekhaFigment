({
    init : function(component) {
        var storeFieldDefinitionForCompactLayout = {};
        this.getNimdaStoreFieldDefinitions(component
            , function(result) {
                try {
                    // Parse data and retrieve relevant attributes
                    let data = JSON.parse(result);
                    for (var i=0; i<data.length; i++){
                        if (data[i].Include_In_Compact_Layout__c){
                            storeFieldDefinitionForCompactLayout[data[i].DeveloperName] = data[i];
                        }

                    }
                    component.set("v.storeFieldDefinitionForCompactLayout", storeFieldDefinitionForCompactLayout);
                } catch(e) {
                    component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                    component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                }                       
            }
            , function(error) {
            }
        ); 
    },
    handleGetAllStores : function(component){
        var self = this;
        var defaultStoreOption = { value: '-1', label: 'Create New Store'};
        var storeOptions = [];
        this.clearErrors(component);        
        this.getAllStores(component
            , function(result) {
                try {
                    storeOptions.push(defaultStoreOption);
                    // Parse data and retrieve relevant attributes
                    let data = JSON.parse(result);
                    for (var i=0; i<data.length; i++){
                        storeOptions.push(
                                {   value: data[i].id
                                    , label: data[i].id + ' - ' + data[i].name + ' - ' + data[i].address.printable_address
                                }
                            );
                    }
                    component.set("v.storeId", storeOptions[0].value);
                    component.set("v.stores", data);
                    component.set("v.storeOptions", storeOptions);
                    component.set("v.selectedStore", storeOptions[0].value);
                    // fire nimda sync event
                    self.fireNimdaSyncEvent(component, component.get("v.STEP_SEARCH_STORE"), storeOptions[0].value);
                } catch(e) {
                    component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                    component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                }                       
            }
            , function(error) {
                storeOptions.push(defaultStoreOption);
                component.set("v.storeOptions", storeOptions);
                component.set("v.selectedStore", storeOptions[0].value);
                // fire nimda sync event
                self.fireNimdaSyncEvent(component, component.get("v.STEP_SEARCH_STORE"), storeOptions[0].value);                
                //self.handleException(component, error, true);
            }
        ); 
    },
    handleGetStoreDetail : function(component){
        var self = this;
        var storeFieldsForCompactLayout = [];
        component.set("v.storeFieldsForCompactLayout", storeFieldsForCompactLayout);
        var storeId = component.get("v.selectedStore");
        if (storeId != '-1'){
            this.getStore(component
                , function(result) {
                    try {
                        // Parse data and retrieve relevant attributes
                        let data = JSON.parse(result);
                        var storeFieldDefinitionForCompactLayout = component.get("v.storeFieldDefinitionForCompactLayout");
                        if (!$A.util.isEmpty(storeFieldDefinitionForCompactLayout)){
                            for (var field in storeFieldDefinitionForCompactLayout){
                                storeFieldsForCompactLayout.push({
                                            label: storeFieldDefinitionForCompactLayout[field].MasterLabel
                                            , value: data[field] 
                                        });
                            };
                        }
                        component.set("v.storeFieldsForCompactLayout", storeFieldsForCompactLayout);
                    } catch(e) {
                        component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                        component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                    }                       
                }
                , function(error) {
                }
            );
        }        
    },        
    handleException : function(component, error, applyUpdates){
        var self = this;
        if (error.message){
            try {
                let errorData = JSON.parse(error.message);
                component.set("v.errorType", errorData.errorType);
                component.set("v.errorMessage", errorData.errorMessage);
                component.set("v.calloutRequest", errorData.calloutRequest);
                component.set("v.calloutResponse", errorData.calloutResponse);
            } catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", error.message);
            }
        }
        if (applyUpdates){
            self.applyUpdates(component
                , function(result) {
                    console.log('Applied updates successfully');                     
                }
                , function(error) {
                    console.log('Failure in applying updates ' + error.message); 
                }                
            );
        }
    },
    clearErrors : function(component) {
        component.set("v.errorType", "");
        component.set("v.errorMessage", "");
        component.set("v.calloutRequest", "");
        component.set("v.calloutResponse", "");
    },
    getAddresses : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmpSearch");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'getAddresses'
                    , { account : component.get("v.account") }
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
    getStores : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmpSearch");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'getStores'
                    , { businessId : component.get("v.businessId")
                        , addressId : component.get("v.addressId")
                        , account : component.get("v.account")
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
    getAllStores : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmpSearch");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'getAllStores'
                    , { businessId : component.get("v.businessId")
                        , account : component.get("v.account")
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
    getNimdaStoreFieldDefinitions : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmpSearch");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'getNimdaStoreFieldDefinitions'
                    , {}
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
    getStore : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmpSearch");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'getStore'
                    , { storeId : component.get("v.selectedStore") }
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
    applyUpdates : function(component, success, failure) {
        var self = this;
        var exceptionData = {};
        exceptionData.step = component.get("v.currentStep");
        if (!$A.util.isEmpty(component.get("v.errorType"))){
            exceptionData.errorType = component.get("v.errorType");
        }
        if (!$A.util.isEmpty(component.get("v.errorMessage"))){
            exceptionData.errorMessage = component.get("v.errorMessage");
        }
        if (!$A.util.isEmpty(component.get("v.calloutRequest"))){
            exceptionData.calloutRequest = component.get("v.calloutRequest");
        }
        if (!$A.util.isEmpty(component.get("v.calloutResponse"))){
            exceptionData.calloutResponse = component.get("v.calloutResponse");
        }
        var calloutCmp = component.find("calloutCmpSearch");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'applyUpdates'
                    , { businessId : component.get("v.businessId")
                        , storeId : component.get("v.storeId")
                        , userId : null
                        , paymentAcctId : null
                        , stripeAcctId : null
                        , stripeBankAcctId : null
                        , account : component.get("v.account")
                        , opportunity : component.get("v.opportunity")
                        , exceptionDataStr : JSON.stringify(exceptionData)
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
    fireNimdaSyncEvent: function(component, step, value) {
        var nimdaSyncEvent = component.getEvent("LDdNimdaSyncEvent");
        nimdaSyncEvent.setParams({
            step: step
            , value: value
        });
        nimdaSyncEvent.fire();
    },                  
})