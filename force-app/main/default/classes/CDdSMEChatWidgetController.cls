public class CDdSMEChatWidgetController{
    public String currentRecordId {get;set;}
    public String connectRegion {get;set;}
    public String instanceId {get;set;}
    public String acAPIURL {get;set;}
    public String contactFlowId {get;set;}
    public CDdSMEChatWidgetController(ApexPages.StandardController controller) {
        connectRegion = CDdSupportConstants.AC_REGION_US_WEST_2;
        instanceId = CDdSupportConstants.AC_INSTANCE_ID;
        acAPIURL = CDdSupportConstants.AC_API_URL;
        contactFlowId = CDdSupportConstants.AC_CONTACT_FLOW_ID;

        currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
    }
}