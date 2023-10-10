({
    
    onReasonChange:function(component, event, helper){
        
        console.log('selected value is '+event.getSource().get("v.value"));
        if(event.getSource().get("v.value")==''){
            
            alert('Required Rejected Reason');
            return;
            
        }
        var action = component.get("c.saveUserReviewReason");
        
        action.setParams({ userReviewId : component.get("v.userReview.Id"),
                          rejectedReason : event.getSource().get("v.value")
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                console.log("From server: " + response.getReturnValue());  
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                        alert('Could not save. Please try again');
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
        
    },
    onStatusChange : function(component, event, helper){
        
        
        var action = component.get("c.saveUserReviewStatus");
        
        action.setParams({ userReviewId : component.get("v.userReview.Id"),
                          approvalStatus : event.getSource().get("v.value")
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                console.log("From server: " + response.getReturnValue());  
                if(event.getSource().get("v.value")=='Rejected'){
                    component.find("selectTag").set("v.required", true);
                }else{
                    component.find("selectTag").set("v.required", false);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                        alert('Could not save. Please try again');
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
        
    }
})