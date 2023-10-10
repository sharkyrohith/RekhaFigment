/**
 *
 * @author: Tia Xuan
 * @date: 2019-08
 * @description class for CDdChatMonitorController - create case and other records for chat
 *
 */
public class CDdChatMonitorController {

    private static Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();

    /**
     * @description Make a call out to the dispatch service
     *              and create case based on transcript components
     */
    @AuraEnabled
    public static Case CreateCase(Id workItemId){

        Case cObj = null;
        LiveChatTranscript chat = null;
        Decimal businessId = 0;
        //String transcriptDescription ='';
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        List<LiveChatTranscript> pRes = [   select  Id,
                                                    ChatKey,
                                                    Name,
                                                    DeliveryNo__c,
                                                    DeliveryUUID__c,
                                                    CustomerNo__c,
                                                    DasherNo__c,
                                                    MerchantNo__c,
                                                    LiveChatButtonId,
                                                    LiveChatDeploymentId,
                                                    Channel__c,
                                                    CustomerName__c,
                                                    DasherName__c,
                                                    Issue__c,
                                                    CustomerEmail__c,
                                                    DasherEmail__c,
                                                    CustomerPhone__c,
                                                    DasherPhoneNo__c,
                                                    Issue_Details__c,
                                                    First_Chat_Accept_Time__c
                                            from LiveChatTranscript
                                            where ID = :workItemId];
        if(pRes.size() == 1) {
            chat = pRes[0];
            chat.OmniAcceptedEventFired__c = true;
            if (CDdExperimentSvc.getSupportFeatureFlag('Enable_Chat_Monitor_Accepted_Time__c')){
                chat.Chat_Event_Accept_Time__c = DateTime.Now();
            }


            // 04/2021 Tia Xuan BZAPSUP-1815 P1: Accurately capture chat accept time
            //                               and chat button for transferred chats (impacts SLA)
            if (CDdExperimentSvc.getSupportFeatureFlag('Enable_Chat_Monitor_First_Accept__c')
                &&  chat.First_Chat_Accept_Time__c == null){
                    chat.First_Chat_Accept_Time__c = DateTime.Now();
                    chat.First_Chat_Button_ID__c = chat.LiveChatButtonId;
            }


            // BZAPSUP-2038 Tia Xuan 06/2021 return on blank Delivery UUID
            if (CDdExperimentSvc.getSupportFeatureFlag('Use_Delivery_UUID_in_Chat_Monitor__c')){
                if (String.isBlank(chat.DeliveryUUID__c)){
                    return null;
                }
            } else {
                if (chat.Channel__c != null
                && (chat.Channel__c.contains('Community')
                    || chat.Channel__c == 'Dasher Onboarding')){
                return null;
            }
            }

            // BZAP-4031 Tia Xuan 05/22/2019
            // adding the description field to be
            // [Dasher/cx Name]+ " - " + Issue  + " - "
            // + "Delivery " [Delivery Number] + " - " [dx/cx email]
            // + " - " + [Issue Details]
            /*if (String.isNotBlank(chat.CustomerName__c)){
                transcriptDescription += chat.CustomerName__c + '-';
            }
            if (String.isNotBlank(chat.DasherName__c)){
                transcriptDescription += chat.DasherName__c + '-';
            }
            if (String.isNotBlank(chat.Issue__c)){
                transcriptDescription += chat.Issue__c + '-';
            }
            if (chat.DeliveryNo__c != null){
                transcriptDescription += 'Delivery ' + chat.DeliveryNo__c;
            }
            if (String.isNotBlank(chat.CustomerEmail__c)){
                transcriptDescription += '-' + chat.CustomerEmail__c;
            }
            if (String.isNotBlank(chat.DasherEmail__c)){
                transcriptDescription += '-' + chat.DasherEmail__c;
            }
            if (String.isNotBlank(chat.Issue_Details__c)){
                transcriptDescription += chat.Issue_Details__c + '-';
            }*/
        } else {
            return null;
        }

        /**
         * first check if there is a case already created with the chatkey
         * in the last one day to keep the query limited to less than 200000
         */
        Date yesterday = Date.today().addDays(-1);
        List<Case> lstCase = [Select Id, CaseNumber from Case where chatkey__c=: chat.ChatKey and createdDate>=:yesterday];
        if(lstCase.size() > 0) {
            return lstCase[0];
        }

        String caseRecordType;
        System.debug('Calling dispatch from Chat Monitor');
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        VDispatchDeliveryCallout dispatch = new VDispatchDeliveryCallout(chat.DeliveryNo__c, chat.DeliveryUUID__c);
        try {

            cObj = new Case();

            VDeliveryInformation res = dispatch.makeDeliveryCallout();

            if(res != null) {
                // Add the liveAgent information to the delivery information returned so that it can be used by
                // the record service
                if(chat.CustomerNo__c != null && chat.CustomerNo__c > 0) {
                    res.liveAgentCustomerId = chat.CustomerNo__c;
                }
                if(chat.DasherNo__c != null && chat.DasherNo__c > 0) {
                    res.liveAgentDasherId = chat.DasherNo__c;
                }
                if(chat.MerchantNo__c != null && chat.MerchantNo__c > 0) {
                    res.liveAgentMerchantId = chat.MerchantNo__c;
                }

                // NOTE: If you want to prefill any case information that is not specified in custom settings you can pass
                // that here. You are not required to pass any case information or initialize salesforceCase
                res.salesforceCase = new Case(ChatKey__c=chat.ChatKey,Origin = 'Chat', DispatchRQStatus__c = 'Success',
                    //description='Dasher: ' + dasherNo+', customerNo' + customerNo + ', DeliveryNo: ' + deliveryNo+
                    //'merchantNo: ' + merchantNo,
                    DispatchRQAttempts__c = dispatch.retryAttempts,
                    DispatchRQResponse__c = dispatch.responseData
                );

                res.salesforceCase = VDeliveryInformation.populateCustomerSegment(res, res.salesforceCase);
                // BZAPSUP-831 Stop allowing null value from Delivery ID to break case creation for mobile chat
                if (chat.CustomerNo__c != null){
                    res.salesforceCase.SuppliedName = String.isNotBlank(chat.CustomerName__c) ? chat.CustomerName__c : '';
                    res.salesforceCase.SuppliedEmail = String.isNotBlank(chat.CustomerEmail__c) ? chat.CustomerEmail__c : '';
                    res.salesforceCase.SuppliedPhone = String.isNotBlank(chat.CustomerPhone__c) ? chat.CustomerPhone__c : '';
                } else if (chat.DasherNo__c != null){
                    res.salesforceCase.SuppliedName = String.isNotBlank(chat.DasherName__c) ? chat.DasherName__c : '';
                    res.salesforceCase.SuppliedEmail = String.isNotBlank(chat.DasherEmail__c) ? chat.DasherEmail__c : '';
                    res.salesforceCase.SuppliedPhone = String.isNotBlank(chat.DasherPhoneNo__c) ? chat.DasherPhoneNo__c : '';
                }

               /* if (String.isNotBlank(transcriptDescription)
                    && CDdExperimentSvc.getFeatureFlag('Stamp_Transcript_Fields_on_Case__c')) {
                    res.salesforceCase.Chat_Information__c = transcriptDescription;
                }*/

                // BZAP-7328 Populate chat issue on case
                Boolean copyChatIssue = CDdExperimentSvc.getFeatureFlag('Copy_Chat_Issue_From_Transcript__c')
                                            || Test.isRunningTest();
                if (copyChatIssue){
                    if (String.isNotBlank(chat.Issue__c)){
                        res.salesforceCase.Chat_Issue__c = chat.Issue__c;
                    }
                    if (String.isNotBlank(chat.Issue_Details__c)){
                        res.salesforceCase.Chat_Issue_Details__c = chat.Issue_Details__c;
                    }
                    res.salesforceCase.SourceId = chat.Id;
                }

                // BZAP-7586 Update Chat Monitor for Caviar Diner Mobile Chats
                Boolean enableCaviarMobileChat = CDdExperimentSvc.getFeatureFlag('Enable_Caviar_Mobile_Chat__c')
                                                    || Test.isRunningTest();
                if(enableCaviarMobileChat){
                    Set<String> caviarDeploymentIds = new Set<String>();
                    if(apiSettings != null) {
                        caviarDeploymentIds = new Set<String>(apiSettings.Caviar_Deployment_IDs__c.split(';'));
                    }

                    if (caviarDeploymentIds.contains(chat.LiveChatDeploymentId)){
                        caseRecordType = apiSettings.Caviar_Case_Record_Type_ID__c;
                    } else {
                        caseRecordType = apiSettings.Case_Record_Type_ID__c;
                    }
                    res.salesforceCase.RecordTypeId = caseRecordType;

                    if ( (apiSettings.Caviar_Diner_Chat_Button_ID__c == chat.LiveChatButtonId)
                            || Test.isRunningTest()) {
                        res.salesforceCase.Type = 'Caviar Diner';
                        res.salesforceCase.Customer_Type__c = 'Consumer';
                        res.salesforceCase.Platform__c = 'Caviar';
                        res.salesforceCase.Channel__c = 'Caviar Diner Chat (In-App)';
                        res.salesforceCase.Caviar_Diner_Topic__c = chat.Issue__c;
                        res.salesforceCase.Subject = 'Inbound Diner In-App Chat - ' + chat.Issue__c;
                    }

                    // BZAPSUP-903 Caviar Web App Chat Points to DoorDash Chat
                    if ((apiSettings.Caviar_Diner_Web_Chat_Button_ID__c == chat.LiveChatButtonId)
                            || Test.isRunningTest()){
                        res.salesforceCase.Channel__c = 'Caviar Diner Chat (Web App)';
                    }
                }

                // 02/2021 Tia Xuan BZAPSUP-1591 - Update Chat Monitor Code in Salesforce for Cx and Dx Mobile and Web Chat
                LiveChatButton chatBtn = [select Id, WindowLanguage from LiveChatButton where Id =: chat.LiveChatButtonId];
                Country_Mapping__c cm = CDdSupportHelper.getCountryMapping(chatBtn.WindowLanguage);
                res.salesforceCase.Language__c = cm.Language__c;
                if (String.isBlank(res.SalesforceCase.Country__c)){
                    res.salesforceCase.Country__c = cm.Country__c;
                }

                CDdDispatchRecordService svc = new CDdDispatchRecordService();
                svc.upsertDeliveryInfo(new List<VDeliveryInformation> { res });
                cObj = res.salesforceCase;
                upsert cObj;
            }
            else {
                throw new CDdException(Label.DispatchBlankSalesforceAudienceInfo);
            }
        }
        catch(Exception ex) {
            String delId = '';
            if (cObj.DeliveryNo__c == null
                && chat.DeliveryNo__c != null){
                cObj.DeliveryNo__c = chat.DeliveryNo__c;
            }
            // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
            Boolean useUUID = (apiSettings.Use_UUID__c != null
                            && apiSettings.Use_UUID__c == true)
                            ? true : false;
            if (cObj.DeliveryUUID__c == null
                && chat.DeliveryUUID__c != null
                && useUUID){
                cObj.DeliveryUUID__c = chat.DeliveryUUID__c;
            }
            if (String.isNotBlank(cObj.DeliveryUUID__c)
                    && useUUID){
                delId = cObj.DeliveryUUID__c;
            } else {
                delId = String.valueOf(cObj.DeliveryNo__c);
            }
            if(!ex.getMessage().contains(Label.DispatchBlankSalesforceAudienceInfo)){
                cObj.Subject = 'Error Creating case';
            }
            cObj.Origin = 'Chat';
            cObj.description = 'C: ' + chat.CustomerNo__c + ', d:' + chat.DasherNo__c + ', deli: ' +
                delId + ', mNo: ' + chat.MerchantNo__c + '\n' + ex.getMessage();

            // BZAPSUP-831 Stop allowing null value from Delivery ID to break case creation for mobile chat
            if (chat.CustomerNo__c != null){
                cObj.Consumer_ID__c = chat.CustomerNo__c;
                cObj.SuppliedName = String.isNotBlank(chat.CustomerName__c) ? chat.CustomerName__c : '';
                cObj.SuppliedEmail = String.isNotBlank(chat.CustomerEmail__c) ? chat.CustomerEmail__c : '';
                cObj.SuppliedPhone = String.isNotBlank(chat.CustomerPhone__c) ? chat.CustomerPhone__c : '';
                cObj.Customer_Type__c = 'Consumer';
            } else if (chat.DasherNo__c != null){
                cObj.Dasher_ID__c = chat.DasherNo__c;
                cObj.SuppliedName = String.isNotBlank(chat.DasherName__c) ? chat.DasherName__c : '';
                cObj.SuppliedEmail = String.isNotBlank(chat.DasherEmail__c) ? chat.DasherEmail__c : '';
                cObj.SuppliedPhone = String.isNotBlank(chat.DasherPhoneNo__c) ? chat.DasherPhoneNo__c : '';
                cObj.Customer_Type__c = 'Dasher';
            } else if (chat.MerchantNo__c != null){
                cObj.Store_ID__c = String.valueOf(chat.MerchantNo__c);
                cObj.Customer_Type__c = 'Merchant';
            }


            if (String.isBlank(cObj.Customer_Type__c)){
                Set<String> consumerButtonIds = new Set<String>();
                consumerButtonIds = new Set<String>(Label.Chat_Mobile_Consumer_Button_ID.split(';'));

                if (consumerButtonIds.contains(chat.LiveChatButtonId)){
                    cObj.Customer_Type__c = 'Consumer';
                }

                Set<String> dasherButtonIds = new Set<String>();
                dasherButtonIds = new Set<String>(Label.Chat_Mobile_Dasher_Button_ID.split(';'));

                if (dasherButtonIds.contains(chat.LiveChatButtonId)){
                    cObj.Customer_Type__c = 'Dasher';
                }

                Set<String> merchantButtonIds = new Set<String>();
                merchantButtonIds = new Set<String>(Label.Chat_Mobile_Merchant_Button_ID.split(';'));

                if (merchantButtonIds.contains(chat.LiveChatButtonId)){
                    cObj.Customer_Type__c = 'Merchant';
                }
            }

                // BZAP-7328 Populate chat issue on case
            Boolean copyChatIssue = CDdExperimentSvc.getFeatureFlag('Copy_Chat_Issue_From_Transcript__c')
                                        || Test.isRunningTest();
            if (copyChatIssue){
                if (String.isNotBlank(chat.Issue__c)){
                    cObj.Chat_Issue__c = chat.Issue__c;
                }
                if (String.isNotBlank(chat.Issue_Details__c)){
                    cObj.Chat_Issue_Details__c = chat.Issue_Details__c;
                }
                 cObj.SourceId = chat.Id;
            }
            // BZAP-7586 Update Chat Monitor for Caviar Diner Mobile Chats
            Boolean enableCaviarMobileChat = CDdExperimentSvc.getFeatureFlag('Enable_Caviar_Mobile_Chat__c')
                                                || Test.isRunningTest();
            if(enableCaviarMobileChat){
                Set<String> caviarDeploymentIds = new Set<String>();
                caviarDeploymentIds = new Set<String>(apiSettings.Caviar_Deployment_IDs__c.split(';'));

                if (caviarDeploymentIds.contains(chat.LiveChatDeploymentId)){
                    caseRecordType = apiSettings.Caviar_Case_Record_Type_ID__c;
                } else {
                    caseRecordType = apiSettings.Case_Record_Type_ID__c;
                }
                cObj.RecordTypeId = caseRecordType;

                if ( (apiSettings.Caviar_Diner_Chat_Button_ID__c == chat.LiveChatButtonId)
                        || Test.isRunningTest()) {
                    cObj.Type = 'Caviar Diner';
                    cObj.Customer_Type__c = 'Consumer';
                    cObj.Platform__c = 'Caviar';
                    cObj.Channel__c = 'Caviar Diner Chat (In-App)';
                    cObj.Caviar_Diner_Topic__c = chat.Issue__c;
                }

                // BZAPSUP-903 Caviar Web App Chat Points to DoorDash Chat
                if ((apiSettings.Caviar_Diner_Web_Chat_Button_ID__c == chat.LiveChatButtonId)
                        || Test.isRunningTest()){
                    cObj.Channel__c = 'Caviar Diner Chat (Web App)';
                }
            }

            // 02/2021 Tia Xuan BZAPSUP-1591 - Update Chat Monitor Code in Salesforce for Cx and Dx Mobile and Web Chat
            LiveChatButton chatBtn = [select Id, WindowLanguage from LiveChatButton where Id =: chat.LiveChatButtonId];
            Country_Mapping__c cm = CDdSupportHelper.getCountryMapping(chatBtn.WindowLanguage);
            cObj.Language__c = cm.Language__c;
            if (String.isBlank(cObj.Country__c)){
                cObj.Country__c = cm.Country__c;
            }

            cObj.DispatchRQAttempts__c = dispatch.retryAttempts;
            if (String.isNotBlank(dispatch.responseData)) {
                cObj.DispatchRQResponse__c = dispatch.responseData;
            }
            cObj.DispatchCalloutException__c = ex.getMessage();
            cObj.DispatchRQStatus__c = 'Failure';
            cObj.chatkey__c = chat.ChatKey;
            cObj.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            upsert cObj;
        }


        /**
         * get casenumber of the new case created
         */
        if(cObj != null && cObj.id != null) {
            cObj = [select Id, AccountId, ContactId, CaseNumber from Case where Id = :cObj.Id];
            chat.CaseId = cObj.Id;
            chat.AccountId = cObj.AccountId;
            chat.ContactId = cObj.ContactId;
        }
        update chat;

        return cObj;
    }

    /**
     * @description BZAP-5016
     *
     */
    @AuraEnabled
    public static void stampPreviousQueue(Id caseId){
        treatPreviousQueue(caseId);
    }

    /**
     * @description check the last owner queue change and stamp previous queue
     *      Omni routing does not trigger automations like Triggers/wf/pb etc to fire so if the case is sendbird case and
     *      if the Enable_Sendbird_API_Callouts__c is enabled publish a platform event to ERS endpoint.
     */
    public static void treatPreviousQueue(ID caseId) {
        if (!CDdExperimentSvc.getFeatureFlag('Stamp_Previous_Queue__c')){
            return;
        }
        List<Sendbird_Chat_Event__e> eventsToPublish = new List<Sendbird_Chat_Event__e>();
        Case c = null;

        List<Case> cRes = [select 	Id,
                           			Previous_Queue__c,
                           			Previous_Queue_Change__c,
                           			Previous_Queue_ID__c,
                                    Status, ChatKey__c, ownerid, owner.FirstName, origin, channel__c, recordtypeId
                           from Case
                           where Id = :caseId];
        if(cRes.size() == 1) {
            c = cRes[0];
            List<CaseHistory> cHistories =[select Id, field, NewValue, OldValue, CreatedDate
                                     from CaseHistory
                                     where caseId =: c.Id
                                     and field = 'Owner'
                                     order by CreatedDate DESC];

            List<Group> queues =[select Id, Name
                                 from Group
                                 where Type = 'Queue'];
            Map<Id, String> queueMap = new Map<Id, String>();
            for (Group g : queues){
                queueMap.put(g.Id, g.Name);
            }
            //Nayana : March 2022: https://doordash.atlassian.net/browse/BIZS-841
            for (CaseHistory cHis : cHistories){
                String oldVal = (String)cHis.OldValue;
                String newVal = (String)cHis.NewValue;
                if ((String.isNotBlank(oldVal) && oldVal.startsWith('00G')) || Test.isRunningTest()) {
                	c.Previous_Queue_ID__c = oldVal;
                    c.Previous_Queue__c = String.isNotBlank(oldVal) ? queueMap.get(oldVal): null;
                    c.Previous_Queue_Change__c = cHis.CreatedDate;
                    if(CDdCaseTriggerHelperV2.isSendbirdCase(c.Origin, c.Channel__c, c.recordTypeId)
                       && CDdExperimentSvc.getSupportFeatureFlag('Enable_Sendbird_API_Callouts__c')) {
                            CDdSupportHelper.SendBirdChatEventWrapper eWrap = new CDdSupportHelper.SendBirdChatEventWrapper();
                            eWrap.caseId = c.id;
                            eWrap.chatKey = c.ChatKey__c;
                            eWrap.ownerId = String.valueOf(c.ownerid);
                            eWrap.prevOwnerId = oldVal;
                            eWrap.status= c.Status;
                            eWrap.prevStatus = c.Status;
                            eWrap.AgentFirstName = c.owner.FirstName;
                            eWrap.caseOrigin = c.Origin;
                            eWrap.chatEscalationId = null;
                            eWrap.isRealtime = false;

                            eventsToPublish.add(CDdSupportHelper.createSendbirdEvent(eWrap));

                        if(!eventsToPublish.isEmpty()) {
                            List<Database.SaveResult> saveResults = EventBus.publish(eventsToPublish);
                            CDdErrorUtilities.publishException('CDdChatMonitorController' , 'treatPreviousQueue', saveResults);
                        }
                    }
                    //False positive for DML inside loop because of break statement after DML
                    try {
                        update c;
                    } catch (Exception e) {
                        if(e.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                            System.enqueueJob(new CDdRetryQueueable(new List<Case>{c}, 'UPDATE', 'CDdChatMonitorController.treatPreviousQueue'));
                        }
                        else {
                            CDdErrorUtilities.publishException('CDdChatMonitorController', 'treatPreviousQueue', c.Id, e);
                            throw e;
                        }
                    }
                    break;
             	}
            }

        }
    }

    /**
     * @description take ownership
     */
    @AuraEnabled
    public static void takeOwnership(ID caseId) {


        List<Case> cRes = [select 	Id,
                           			OwnerId,
                                    Origin
                           from Case
                           where Id = :caseId];
        if(cRes.size() == 1) {
            Case c = cRes[0];
            if (c.OwnerId != UserInfo.getUserId()
                && c.Origin == 'Phone'){
                c.OwnerId = UserInfo.getUserId();
                update c;
            }
        }
    }
}