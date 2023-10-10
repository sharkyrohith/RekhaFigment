({
    getOpportunityLineItems: function (cmp) {
        var action = cmp.get('c.getOpportunityLineItems');
        action.setParams({
            recordId : cmp.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                var result = response.getReturnValue();
                if(result.isSuccess){
                    cmp.set("v.cardtitle","Opportunity Line Items ("+result.data.length+")");
                    cmp.set('v.oppLineItems', result.data );
                }else {
                    cmp.set("v.cardtitle","Opportunity Line Items (0)");
                    cmp.set("v.noResults", "No records to display");
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                cmp.set("v.cardtitle","Opportunity Line Items (0)");
                cmp.set("v.noResults", "An error occurred: No records to display");
            }
        }));
        $A.enqueueAction(action);
    }
})