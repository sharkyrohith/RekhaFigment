/**
 * @author Nayana
 * @date 12/2022
 * @description CDdToolsAdminCallout virtual class to make an API call
 *
**/
public virtual class CDdToolsAdminCallout {

    public static ToolsAdminDMLResultsHandler toolsAdminDMLHandler = new ToolsAdminDMLResultsHandler();
    public static Boolean chargebackQueued = false;
    public static Integer MAX_REQUESTS_TO_PROCESS;
    public class ToolsAdminDMLResultsHandler extends HandleDmlResults {
        public List<String> errorMessages = new List<String>();
        public Set<Id> successIds = new Set<Id>();
        public override void handle(Database.SaveResult[] results) {
            for(Database.SaveResult sr : results) {
                if(sr.isSuccess()){
                    successIds.add(sr.getId());
                }else{
                    for(Database.Error err : sr.getErrors()) {
                        errorMessages.add('Tools admin automation error: '+err.getMessage());
                    }
                }
            }
        }
    }

    public virtual void makeCall(Tools_Admin_API__mdt apiDetails,List<Object> lstWrapperToProcess) {
    }

    @TestVisible
    protected CDdRestJSONObj.RestAPIResponse invokeRESTAPI(Tools_Admin_API__mdt apiDetails,String requestPayload) {
        try{
            CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
            //change this to take from CMT
            String method = apiDetails.Method__c;
            String path = apiDetails.Path__c;
            CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI(method, requestPayload, null, null,path , null,
                                                CDdSupportConstants.DD_API_TOKEN,
                                                CDdSupportConstants.CREDENTIAL_PASSWORD,
                                                CDdSupportConstants.SUPPORT_GATEWAY_GENERIC_ENDPOINT);
            return response;
            //Add API logger if need to log : Check with Raju
        }catch (Exception e){
            throw e;
        }
    }

    protected Map<String,String> createMapFieldValue(String caseFldsToUpdate) {
        Map<String,String> mapFieldValue = new Map<String,String>();
        if(String.isNotBlank(caseFldsToUpdate)){
            for(String caseFldValue: caseFldsToUpdate.split(CDdCoreConstants.DELIMITER_SEMICOLON)){
                List<String> fldvalue = caseFldValue.split('=>');
                mapFieldValue.put(fldvalue[0].trim(),fldvalue[1].trim()); //check if any validation to add
            }
        }
        return mapFieldValue;
    }

    protected void commitAndLogErrors(fflib_ISObjectUnitOfWork uow){
       CDdTriggerConstantsUtil.skipCaseTriggerExecution = true;
       VFeedItemTriggerHandler.doNotUpdateCases = true;
       List<String> errorMessages = new List<String>();
       try{
            uow.commitwork();
        }catch(Exception e){
            errorMessages.add(CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e));
        }
        errorMessages.addAll(CDdToolsAdminCallout.toolsAdminDMLHandler.errorMessages);
        CDdErrorUtilities.createApexLogs(errorMessages, 'CDdToolsAdminCallout');
    }

    protected void sendEmailAlerts(Map<Id,String> RecordIdToEmailAlertName){
        /* we only send out emails if the records are updated successfully
            also - this is a flow callout within a for loop, this is the current implementation due to 2 reasons
            1.The flow is currently setup to only handle one record at a time
            2.This framework is only used by the chargeback submission project (CDdChargebackSubmissionCallout)
        and the number of records we process for the chargeback submission project is capped at 5 (MAX_REQUESTS_TO_PROCESS)
        and is only going to be 1 at a time in reality as these are cases submitted from the merchant portal */
        for(Id recordId : RecordIdToEmailAlertName.keyset()){
            if(CDdToolsAdminCallout.toolsAdminDMLHandler.successIds.contains(recordId)){
                EmailGeneratorService.sendWFEmailAlert(recordId, 'Case', RecordIdToEmailAlertName.get(recordId));
            }
        }
    }
}