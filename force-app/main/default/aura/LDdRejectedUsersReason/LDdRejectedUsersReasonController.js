({
    doInit : function(component, event, helper) {
        component.set('v.validate', function() {
            var urList = component.get("v.rejectedUserReviews");
            for(var ur of urList){
                if(ur.Approval_Status__c =='Rejected' && ur.Rejected_Reason__c==null){
                    return { isValid: false, errorMessage: 'Rejected Reason required' }
                }
            }
      
        });
        
		
    }
})