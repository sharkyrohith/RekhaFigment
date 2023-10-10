({
	doInit : function(component, event, helper) {
		helper.openModel(component, event, helper);
        var action = component.get("c.displayAccountID"); 
        
        action.setParams({
            caseId :component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if(state === "SUCCESS"){
                var cse = response.getReturnValue();
                component.set("v.CaseRec", response.getReturnValue());
                if (cse.Account != null && !cse.Account.EIN_Encrypted__c && !cse.Account.Encrypted_Tax_Id__c){
                    component.set("v.displayMsg","No Tax ID on file, please verify the Mx in another way");
                    component.set("v.showMsg",true);
                    component.set("v.color","padding:0.5rem;background:#FF0000");
                }
            }
            
        });
        $A.enqueueAction(action);
	},
    
    verifyEIN : function(component, event, helper) {

        var last4EIN = component.find("EIN").get("v.value");
        
        var action = component.get("c.compareLast4EIN"); 
        action.setParams({
            accountID :component.get("v.accId"),
            last4EIN: component.find("EIN").get("v.value"),
            caseId :component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if(state === "SUCCESS"){
                if(response.getReturnValue()==true){
                    //alert('Mx EIN Verified successfully');
                    component.set("v.displayMsg","Mx EIN Verified successfully");
                    component.set("v.showMsg",true);
                    component.set("v.color","padding:0.5rem;background:#008000");
                    //helper.showToast(component, event, helper);
                }
                else{
                    //alert('Mx EIN does not match');
                    component.set("v.displayMsg","Mx EIN does not match");
                    component.set("v.showMsg",true);
                    component.set("v.color","padding:0.5rem;background:#FF0000");
                    
                    //helper.showError(component, event, helper);
                }
            }
            
        });
        $A.enqueueAction(action);
    },
    
    closeModal : function(component, event, helper){

        /*component.set("v.isModalOpen", true);
        var confirmmodal = component.find('myModal');
        var removemodal = component.find('myModal-back');
        $A.util.addClass(confirmmodal, 'slds-hide');
        $A.util.addClass(removemodal, 'slds-hide');*/
        //$A.get("e.force:refreshView").fire();
        sforce.console.getEnclosingTabId(
     	$A.getCallback(function(result) {
        sforce.console.closeTab(result.id);
      })
   );
        
    }
})