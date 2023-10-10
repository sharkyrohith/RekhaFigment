({
	doInit : function(component,event,helper) {
		// if COO Business Option is null on the opportunity record, defaults the COO Business Option to "Old Store" 
		if(component.get("v.opportunity.Change_of_Ownership_Business_Option__c") == '' || component.get("v.opportunity.Change_of_Ownership_Business_Option__c") == null ){
			component.set("v.businessOptionSelected",'Old Store');
		}else{
			component.set("v.businessOptionSelected",component.get("v.opportunity.Change_of_Ownership_Business_Option__c") );
		}
		// if COO Business ID is null on the opportunity record, deafults the COO Business ID Option to "New BusinessID" 
		if(component.get("v.opportunity.Change_of_Ownership_Business_Id__c") == '' || component.get("v.opportunity.Change_of_Ownership_Business_Id__c") == null ){
			component.set("v.businessIDOptionSelected",'New BusinessID');
			component.set("v.businessIDInput",null);
		}else{
			component.set("v.businessIDOptionSelected",'Existing BusinessID');
			component.set("v.businessIDInput",component.get("v.opportunity.Change_of_Ownership_Business_Id__c"));
		}
		component.set("v.businessScreen",'Render Business Option Screen');
    },
	handleBusinessIdInput :function(component, event, helper) {
		var businessIdOption = event.getParam("value");
		component.set("v.businessIDInput",businessIdOption);
	},
	// navigates to the Business Confirmation Page 
	handleNext :function(component, event, helper) {
		// nullifies the attribute v.businessIDInput if (user enters some value in the input field and later chooses the option New BusinessID')
		if(component.get("v.businessIDOptionSelected") =='New BusinessID'){
			component.set("v.businessIDInput") == null;
		}
		helper.clearErrors(component);
		// if User entered BID in the input field matches with the Store Account BID, throws an error, Otherwise navigates to the Business Confirmation page
		if(component.get("v.businessIDInput") != null && component.get("v.opportunity.Account.Parent.Business_ID__c") == component.get("v.businessIDInput") ){
		   component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
		   var errorMessageBusinessIDInputMatchesAccBussID = $A.get("$Label.c.DDS2N_COO_Business_Config_BID_Entered_Same_as_ParentAcc_BID_Error_Text_Label");		   
		   component.set("v.errorMessage",  errorMessageBusinessIDInputMatchesAccBussID);
		}else if((component.get("v.businessIDInput") == '' || component.get("v.businessIDInput") == null) && component.get("v.businessIDOptionSelected") == 'Existing BusinessID'){
			component.set("v.errorMessage",  "Please input a valid Business ID");
		}else{
			component.set("v.businessScreen",'Render Business Confirmation Screen');
		}
	},
	// Saves the Business Config: on the Opportunity record.
	handleConfirm : function(component, event, helper) {
		component.set("v.isLoading", true); 
		var calloutCmp = component.find("calloutCmp");
		if(calloutCmp){
					helper.saveBusinessConfigurationOnOpportunity(component
						, function(result) {
							var value = component.get("v.CHANGE_OF_OWNERSHIP_CREATE");
							component.set("v.isLoading", true); 
							helper.fireNimdaSyncEvent(component, value, component.get("v.version"));
						}
						, function(error) {
							helper.handleException(component, error, false);
							component.set("v.isLoading", false);
						}
					);   		
	 	}
	},
	// ON Cancel takes the user back to the record detail page
	handleCancel : function(component, event, helper) {
		helper.navigateToPreviousPage(component); 
	},
	handlePrevious : function(component, event, helper) {
		if(component.get("v.businessScreen") == 'Render Business Option Screen'){
		var value = component.get("v.STEP_INITIALIZE");
		helper.fireNimdaSyncEvent(component, value, component.get("v.version"));
		}else{
			component.set("v.businessScreen",'Render Business Option Screen');
		}
		}, 	
 })