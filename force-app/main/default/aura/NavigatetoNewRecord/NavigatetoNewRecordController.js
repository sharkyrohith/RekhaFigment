({
invoke : function(component, event, helper) {
var redirectToNewRecord = $A.get( "e.force:navigateToSObject" );

redirectToNewRecord.setParams({
"opportunityId": component.get( "v.opportunityId" ),
"slideDevName": "detail"
});
redirectToNewRecord.fire();
}
})