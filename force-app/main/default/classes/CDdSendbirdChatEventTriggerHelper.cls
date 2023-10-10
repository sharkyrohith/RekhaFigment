/**
 * CDdSendbirdChatEventTriggerHelper
 *
 * @author     Jeegar
 * @date  2021-03
 * @decription  This class is the helper for Sendbird_Chat_Event__e Platform Events
 */
public with sharing class CDdSendbirdChatEventTriggerHelper {
    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
     *****************************************************************************************************************************/

    /*****************************************************************************************************************************
     *
     * Public/Global Variables
     *
     *****************************************************************************************************************************/

     /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/

    /**
     * @author     Jeegar
     * @date  2020-03
     * @decription This method is the entry point into the Helper. It processes the Sendbird events adn performs API Callouts to the ERS Sendbird endpoint
     * @param   Sendbird_Chat_Event__e newList
     * @return  void
     */
    public void processSendbirdChatEvents(List<Sendbird_Chat_Event__e> newList) {
        List<CDdRestJSONObj.SendbirdCaseUpdate> requests = new List<CDdRestJSONObj.SendbirdCaseUpdate>();
        Boolean shouldLog = ApiLoggerServiceImplHelper.shouldLog('Sendbird');
        List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();
        API_Log__c tempLog;

        CDdRestJSONObj.SendbirdCaseUpdate request;
        for(Sendbird_Chat_Event__e event : newList) {
            requests.add(createRequest(event));
            // adding logging, not relying on framework to insert because I want to check if there are any drops in platform events.
            // inserts on apiLogs should be trivial because there are no triggers on the object.
            if(shouldLog) {
                tempLog = new API_Log__c();
                tempLog.Calling_Code__c = 'SBCETH-processSendbirdChatEvents';
                tempLog.Related_To_Id__c = event.Case_Id__c;
                tempLog.Related_To_Owner_Id__c = event.Case_Owner_Id__c;
                tempLog.Request__c = String.valueOf(event);
                apiLogsToInsert.add(tempLog);
            }
        }

        if(shouldLog && !apiLogsToInsert.isEmpty()) {
            List<Database.SaveResult> apiLogsInsertResult  = Database.Insert(apiLogsToInsert);
            CDdErrorUtilities.publishException(CDdSupportConstants.CASE_OBJECT_LABEL , 'SBCETH-processSendbirdChatEvents-APILOG', apiLogsInsertResult);
        }
        try{
            sendChatEvents(requests);
        } catch (Exception ex) {
            CDdErrorUtilities.publishException('CDdSendbirdChatEventTriggerHelper', 'processSendbirdChatEvents', ex);
            throw ex;
        }

    }
    /**
     * @author     Jeegar
     * @date  2020-03
     * @decription This method is the entry point into the Helper. It processes the Sendbird events and performs API Callouts to the ERS Sendbird endpoint
     * @param   Sendbird_Chat_Event__e newList
     * @return  void
     */
    public void processSendbirdChatsByFutureMethod(List<CDdSupportHelper.SendBirdChatEventWrapper> sbceWrappers) {
        List<CDdRestJSONObj.SendbirdCaseUpdate> requests = new List<CDdRestJSONObj.SendbirdCaseUpdate>();
        Boolean shouldLog = ApiLoggerServiceImplHelper.shouldLog('Sendbird');
        List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();
        API_Log__c tempLog;

        CDdRestJSONObj.SendbirdCaseUpdate request;
        for(CDdSupportHelper.SendBirdChatEventWrapper currWrapper : sbceWrappers) {
            requests.add(createRequest(currWrapper));
            // adding logging, not relying on framework to insert because I want to check if there are any drops in platform events.
            // inserts on apiLogs should be trivial because there are no triggers on the object.
            if(shouldLog) {
                tempLog = new API_Log__c();
                tempLog.Calling_Code__c = 'processSendbirdChatsByFutureMethod';
                tempLog.Related_To_Id__c = currWrapper.caseId;
                tempLog.Related_To_Owner_Id__c = currWrapper.ownerId;
                tempLog.Request__c = String.valueOf(currWrapper);
                apiLogsToInsert.add(tempLog);
            }
        }

        if(shouldLog && !apiLogsToInsert.isEmpty()) {
            List<Database.SaveResult> apiLogsInsertResult  = Database.Insert(apiLogsToInsert);
            CDdErrorUtilities.publishException(CDdSupportConstants.CASE_OBJECT_LABEL , 'processSendbirdChatsByFutureMethod-APILOG', apiLogsInsertResult);
        }
        try{
            sendChatEvents(requests);
        } catch (Exception ex) {
            CDdErrorUtilities.publishException('CDdSendbirdChatEventTriggerHelper', 'processSendbirdChatEvents', ex);
            throw ex;
        }
    }

    /*****************************************************************************************************************************
     *
     * Private Methods
     *
     *****************************************************************************************************************************/

    /**
     * @author     Jeegar
     * @date  2020-03
     * @decription This method creates a Request object for senbird chats
     * @param   Sendbird_Chat_Event__e event
     * @return  CDdRestJSONObj.SendbirdCaseUpdate
     */
    private CDdRestJSONObj.SendbirdCaseUpdate createRequest(Sendbird_Chat_Event__e event) {
        CDdRestJSONObj.SendbirdCaseUpdate request = new CDdRestJSONObj.SendbirdCaseUpdate();
        request.caseId = event.Case_Id__c;
        request.chatSessionId = event.Chat_Key__c;
        request.ownerId = event.Case_Owner_Id__c;
        request.prevOwnerId = event.Case_Previous_Owner_Id__c;
        if(!String.isblank(event.Case_Status__c)) {
            request.caseStatus = event.Case_Status__c;
        }
        if(!String.isblank(event.Case_Previous_Status__c)) {
            request.prevCaseStatus = event.Case_Previous_Status__c;
        }
        request.agentFirstName = event.Agent_First_Name__c;
        request.chatEscalationId = event.Chat_Escalation_Id__c;
        request.isRealTimeQueue = event.New_Owner_Realtime__c;
        request.caseOrigin = event.Case_Origin__c;
        return request;
    }

    /**
     * @author     Jeegar
     * @date  2020-03
     * @decription This method converts a list of CDdRestJSONObj.SendbirdCaseUpdate to JSON and calls sendChatEvent()
     * @param   List<CDdRestJSONObj.SendbirdCaseUpdate> requests
     * @return  void
     */

    private void sendChatEvents (List<CDdRestJSONObj.SendbirdCaseUpdate> requests) {
        List<CDdRestJSONObj.RestAPIResponse> responses = new List<CDdRestJSONObj.RestAPIResponse>();
        CDdRestJSONObj.SendbirdRequest sendbirdRequest = new CDdRestJSONObj.SendbirdRequest();
        sendbirdRequest.caseUpdates = requests;
        String requestPayload = JSON.serialize(sendbirdRequest, false);
        sendChatEvent(requestPayload);
    }

    /**
     * @author     Jeegar
     * @date  2020-03
     * @decription This is a future method that makes an API callout to the ERS Sendbird endpoint. Retries are configured in Sendbird_Settings__c
     * @param   String body
     * @return  void
     */

    @future (callout=true)
    public static void sendChatEvent (String body) {
        CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
        String response;
        Boolean exceptionOccured = false;
        Boolean shouldLog = ApiLoggerServiceImplHelper.shouldLog('Sendbird');
        List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();
        API_Log__c tempLog;
        try{
            response = CDdSendBirdAPIHandler.makeRequest(CDdCoreConstants.HTTP_POST,CDdSupportConstants.SENDBIRD_ERS_ENDPOINT_PATH, body);
        } catch (Exception Ex) {
            CDdErrorUtilities.publishException('CDdSendbirdChatEventTriggerHelper', 'notifyTHQ', ex);
            exceptionOccured = true;
            throw ex;
        } finally {
            if(shouldLog) {
                tempLog = new API_Log__c();
                tempLog.Calling_Code__c = 'sendChatEvent-Future-'+exceptionOccured;
                tempLog.Related_To_Id__c = null;
                tempLog.Related_To_Owner_Id__c = null;
                if(body.length() >= CDdCoreConstants.TEXTAREA_SIZE_MAX) {
                    tempLog.Request__c = body.substring(0,CDdCoreConstants.TEXTAREA_SIZE_MAX - 10);
                } else {
                    tempLog.Request__c = body;
                }
                if(response != null && response.length() >= CDdCoreConstants.TEXTAREA_SIZE_MAX) {
                    tempLog.Response__c = response.substring(0,CDdCoreConstants.TEXTAREA_SIZE_MAX - 10);
                } else {
                    tempLog.Response__c = response;
                }
                apiLogsToInsert.add(tempLog);

               Database.insert(apiLogsToInsert, false);
            }

        }

    }

    /**
     * @author          Jeegar
     * @date            April 2023
     * @description     Create a request using Sendbird Chat Event Wrapper
     * @return          CDdRestJSONObj.SendbirdCaseUpdate
     */
    private CDdRestJSONObj.SendbirdCaseUpdate createRequest(CDdSupportHelper.SendBirdChatEventWrapper sbceWrapper) {
        CDdRestJSONObj.SendbirdCaseUpdate request = new CDdRestJSONObj.SendbirdCaseUpdate();
        request.caseId = sbceWrapper.caseId;
        request.chatSessionId = sbceWrapper.chatKey;
        request.ownerId = sbceWrapper.ownerId;
        request.prevOwnerId = sbceWrapper.prevOwnerId;
        if(!String.isblank(sbceWrapper.status)) {
            request.caseStatus = sbceWrapper.status;
        }
        if(!String.isblank(sbceWrapper.prevStatus)) {
            request.prevCaseStatus = sbceWrapper.prevStatus;
        }
        request.agentFirstName = sbceWrapper.AgentFirstName;
        request.chatEscalationId = sbceWrapper.chatEscalationId;
        request.isRealTimeQueue = sbceWrapper.isRealtime;
        request.caseOrigin = sbceWrapper.caseOrigin;

        return request;
    }
}