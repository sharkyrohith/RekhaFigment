/**
 * @author Nayana
 * @date 12/2022
 * @description CDdChargeBackSubmissionCallout class to make an API call
 *
**/
public class CDdChargeBackSubmissionCallout extends CDdToolsAdminCallout{
    public static final String EC_DISPUTE_REASON = 'mx_charge_dispute';
    public static final String CO_REFUND_REASON = 'cancelled_order_made';

    public static Map<String,String> MAP_OF_FORMSTACK_CATEGORY_TO_ADJUSTMENT_REASON = new Map<String, String>{
        'Error Charge Disputes' => EC_DISPUTE_REASON,
        'Cancelled Order Refund' => CO_REFUND_REASON
    };
    public override void makeCall(Tools_Admin_API__mdt apiDetails,List<Object> lstWrapperToProcess) {
        /*the current merchant payment adjustment end point can only process
        * one error charge request at a time and henc we make one callout per case record
        * - this is not a problem as the merchant portal will only submit one case at a time
        * and also even in the scenario of multiple locations - will only submit a maximum of 5
        * cases. We will also be not making more than 5 callouts in this section and will be transfering the remainder of the cases to the agent
        */
        CDdToolsAdminCallout.MAX_REQUESTS_TO_PROCESS = 5;
        Map<Id,CDdRestJSONObj.RestAPIResponse> caseToChargebackResponseMap = new Map<Id,CDdRestJSONObj.RestAPIResponse>();
        Map<Id,CDdRestJSONObj.ChargeBackSubmission> caseToRequestMap = new Map<Id,CDdRestJSONObj.ChargeBackSubmission>();
        fflib_ISObjectUnitOfWork uow = Application.UNITOFWORK.newInstance(new UnitOfWorkPartialSaveDml(CDdToolsAdminCallout.toolsAdminDMLHandler));
        String requestPayload = '';
        for(Integer i=0;i<lstWrapperToProcess.size();i++){
            CDdRestJSONObj.ChargeBackSubmission req = (CDdRestJSONObj.ChargeBackSubmission)lstWrapperToProcess[i];
            caseToRequestMap.put(req.caseId, req);
            CDdRestJSONObj.RestAPIResponse response;
            if(i<MAX_REQUESTS_TO_PROCESS){
                requestPayload = JSON.serialize(req, false);
                response = invokeRESTAPI(apiDetails,requestPayload);
            }else{
                response = new CDdRestJSONObj.RestAPIResponse();
                response.statusCode = 400;
                response.Body = 'Callout Limit exceeded';
            }
            caseToChargebackResponseMap.put(req.caseId, response);
        }
        /* we build a map of response key to actions to be taken , the
        * key to the map is response status code + response message key
        */
        Map<String,Tools_Admin_API_actions__mdt> responseToActionMap = new Map<String,Tools_Admin_API_actions__mdt>();
        Tools_Admin_API_actions__mdt defaultAction = new Tools_Admin_API_actions__mdt();
        for(Tools_Admin_API_actions__mdt action : apiDetails.Tools_Admin_API_actions__r){
            if(action.Response_Status_Code__c != null){
                String respKey = String.valueOf(Integer.valueOf(action.Response_Status_Code__c));
                respKey += action.Response_Message_key__c != null ? action.Response_Message_key__c : '';
                responseToActionMap.put(respKey,action);
                if(action.MasterLabel.contains('Default')){
                    defaultAction = action;
                }
            }
        }
        Map<Id,String> RecordIdToEmailAlertName = new Map<Id,String>();
        for(Id caseId : caseToChargebackResponseMap.keyset()){
            CDdRestJSONObj.RestAPIResponse chargeBackResponse = caseToChargebackResponseMap.get(caseId);
            Tools_Admin_API_actions__mdt actionToBeTaken;
            Map<String, Object> respBody = new Map<String, Object>();
            if(chargeBackResponse != null){
                respBody = (Map<String, Object>)JSON.deserializeUntyped(chargeBackResponse.body);
                String msg = respBody.containsKey('message') ? (String)respBody.get('message') : '';
                /* BIZS-2711 - we have configured the response to behavior mapping to be generic
                using placeholders like <DELIVERY_ID> in the message key, so we need to replace
                the actual delivery value with the placeholder to get a perfect match */
                String deliveryId = caseToRequestMap.get(caseId).deliveryUuidShort;
                msg = msg.replaceAll(deliveryId,'<DELIVERY_ID>');
                String responseKey = chargeBackResponse.statusCode + msg;
                if(responseToActionMap.containsKey(responseKey)){
                    actionToBeTaken = responseToActionMap.get(responseKey);
                }
            }
            if(actionToBeTaken == null){
                actionToBeTaken = defaultAction;
                //This is to capture missing response values on Salesforce side
                uow.registerNew(new FeedItem(parentId = caseId, Title = actionToBeTaken.MasterLabel,Body = 'Payment Adjustment Tool Response: \n'+respBody));

            }else{
                uow.registerNew(new FeedItem(parentId = caseId, Title = actionToBeTaken.MasterLabel,Body = 'Payment Adjustment Tool Response: \n'+actionToBeTaken.Response_Message_key__c));
            }
            //prep cases for update based on the values specified in the action record
            if(actionToBeTaken.Fields_To_Update__c != null){
                Map<String,String> mapCaseFlsValues = createMapFieldValue(actionToBeTaken.Fields_To_Update__c);
                Case c = new Case();
                c.Id = caseId;
                for(String fldName : mapCaseFlsValues.keySet()){
                    c.put(fldName,mapCaseFlsValues.get(fldName));
                }
                uow.registerDirty(c);
            }
            //prep emails to be sent out if any
            if(actionToBeTaken.Email_Template_Name__c != null){
                RecordIdToEmailAlertName.put(caseId, actionToBeTaken.Email_Template_Name__c);
            }
        }
        commitAndLogErrors(uow);
        sendEmailAlerts(RecordIdToEmailAlertName);
    }
}