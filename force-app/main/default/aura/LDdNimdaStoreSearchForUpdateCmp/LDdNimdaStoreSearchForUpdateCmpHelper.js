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
    handleGetStoreDetail : function(component, storeId, success, failure){
        var self = this;
        this.clearSearchResults(component);
        this.clearErrors(component);        
        var storeOptions = [];
        var storeFieldsForCompactLayout = [];

        this.getStore(component
            , storeId
            , function(result) {
                if (success) {
                    success.call(self, result);
                }                    
                try {
                    // Parse data and retrieve relevant attributes
                    let data = JSON.parse(result);
                    // Fill the search selection radio option
                    storeOptions.push(
                            {   value: data.id
                                , label: data.id + ' - ' + data.name + ' - ' + data.address.printable_address
                            }
                        );
                    component.set("v.storeId", storeOptions[0].value);
                    component.set("v.stores", data);
                    component.set("v.storeOptions", storeOptions);
                    component.set("v.selectedStore", storeOptions[0].value);                                            
                    // Fill the compact detail layout section
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
                if (failure) {
                    failure.call(self, error);
                }
                self.handleException(component, error);                    
            }
        );
    },        
    handleException : function(component, error){
        var self = this;
        if (error.message){
            try {
                let errorData = JSON.parse(error.message);
                if (errorData.calloutResponse){
                    let calloutResponse = JSON.parse(errorData.calloutResponse);
                    if (calloutResponse.statusCode && calloutResponse.statusCode == 404){
                        component.set("v.searchNoResultFound", true);
                    }                    
                } 
                if (!$A.util.getBooleanValue(component.get("v.searchNoResultFound"))){
                    component.set("v.errorType", errorData.errorType);
                    component.set("v.errorMessage", errorData.errorMessage);
                    component.set("v.calloutRequest", errorData.calloutRequest);
                    component.set("v.calloutResponse", errorData.calloutResponse);
                }
            } catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", error.message);
            }
        }
    },
    clearErrors : function(component) {
        component.set("v.searchNoResultFound", false);
        component.set("v.errorType", "");
        component.set("v.errorMessage", "");
        component.set("v.calloutRequest", "");
        component.set("v.calloutResponse", "");
    },
    clearSearchResults : function(component) {
        component.set("v.storeFieldsForCompactLayout", []);
        component.set("v.storeId", null);
        component.set("v.stores", null);
        component.set("v.storeOptions", []);
        component.set("v.selectedStore", null); 
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
    getStore : function(component, storeId, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmpSearch");
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
    fireNimdaSyncEvent: function(component, step, value) {
        var nimdaSyncEvent = component.getEvent("LDdNimdaSyncEvent");
        nimdaSyncEvent.setParams({
            step: step
            , value: value
            , version: component.get("v.version")
        });
        nimdaSyncEvent.fire();
    },                  
})