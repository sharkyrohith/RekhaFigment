/**
 * Veltig, RA, 03/01/2017: Created
 */
public with sharing class VChatMonitor {
    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit        
    private static Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();

    public boolean fireOmniEvents {get; set;}

    public VChatMonitor(ApexPages.StandardController controller) {
        fireOmniEvents = apiSettings.Fire_On_Omni_Events__c;
    }

    @RemoteAction
    public static LiveChatTranscript getChat(ID workItemId) {
        LiveChatTranscript res = null;

        List<LiveChatTranscript> pRes = [select Id, 
                                                ChatKey, 
                                                Name, 
                                                Channel__c,
                                                LiveChatButtonId,
                                                First_Chat_Accept_Time__c,
                                                DeliveryUUID__c
                                        from LiveChatTranscript 
                                        where ID = :workItemId];
        if(pRes.size() == 1) {
            res = pRes[0];
            res.OmniAcceptedEventFired__c = true;
            if (CDdExperimentSvc.getSupportFeatureFlag('Enable_Chat_Monitor_Accepted_Time__c')){
                res.Chat_Event_Accept_Time__c = DateTime.Now();
            }

            // 04/2021 Tia Xuan BZAPSUP-1815 P1: Accurately capture chat accept time 
            //                               and chat button for transferred chats (impacts SLA)
            if (CDdExperimentSvc.getSupportFeatureFlag('Enable_Chat_Monitor_First_Accept__c')
                &&  res.First_Chat_Accept_Time__c == null){
                res.First_Chat_Accept_Time__c = DateTime.Now();
                res.First_Chat_Button_ID__c = res.LiveChatButtonId;
            }
            
            update res;

            // BZAPSUP-2038 Tia Xuan 06/2021 return on blank Delivery UUID
            if (CDdExperimentSvc.getSupportFeatureFlag('Use_Delivery_UUID_in_Chat_Monitor__c')){
                if (String.isBlank(res.DeliveryUUID__c)){
                    return null;
                }
            } else {
                if (res.Channel__c != null 
                    && (res.Channel__c.contains('Community')
                        || res.Channel__c == 'Dasher Onboarding')){
                    return null;
                }
            }
        }

        return res;
    }

    @RemoteAction
    public static Case createCase(String chatKey, Decimal deliveryNo,
        String deliveryUUID,
        Decimal customerNo,
        Decimal dasherNo,
        Decimal merchantNo, 
        String chatButtonId,
        String dispatchResponse) { 
        
        Case cObj = null;
        LiveChatTranscript chat = null;
        Decimal businessId = 0;
        /**
         * first check if there is a case already created with the chatkey
         * in the last one day to keep the query limited to less than 200000
         */
        Date yesterday = Date.today().addDays(-1);
        List<Case> lstCase = [Select Id, CaseNumber from Case where chatkey__c=:chatKey and createdDate>=:yesterday];
        if(lstCase.size() > 0) {
            return lstCase[0];
        }

        String caseRecordType;
        VDispatchDeliveryCallout cl = new VDispatchDeliveryCallout(deliveryNo, deliveryUUID);
        system.debug('<><><>cl'+cl);    
        try {
            
            if(apiSettings != null && apiSettings.Case_Record_Type_ID__c != null) {
                caseRecordType = apiSettings.Case_Record_Type_ID__c;
            }
            cObj = new Case();
            System.debug('>>>chatKey: ' + chatKey);
            VDeliveryInformation res;
            if(String.isNotBlank(dispatchResponse)) {
                res = apiSettings.Use_ERS_API__c ?
                    CDdDispatchDeliveryInformation.deserialize(dispatchResponse)[0] :
                    VDeliveryInformation.deserialize(dispatchResponse);
            }
            else {
                res = cl.makeDeliveryCallout();
            }
            system.debug('<><><>rex'+res);
            if(res != null){
                // Add the liveAgent information to the delivery information returned so that it can be used by
                // the record service
                if(customerNo > 0) {
                    res.liveAgentCustomerId = customerNo;
                }
                if(dasherNo > 0) {
                    res.liveAgentDasherId = dasherNo;
                }
                if(merchantNo > 0) {
                    res.liveAgentMerchantId = merchantNo;
                }
                if(String.isNotBlank(chatButtonId)) {
                    res.chatButtonId = chatButtonId;    
                    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                    chat = (LiveChatTranscript) [SELECT 
                                                    Id, CustomerNo__c, DasherNo__c, 
                                                    DeliveryNo__c, DeliveryUUID__c, MerchantNo__c, 
                                                    CustomerName__c, CustomerPhone__c, CustomerEmail__c,
                                                    DasherName__c, DasherPhoneNo__c, DasherEmail__c, 
                                                    Dispatch_Business_No__c, ChatKey,
                                                    Issue__c, Issue_Details__c,
                                                    LiveChatButtonId, LiveChatDeploymentId
                                                    FROM LiveChatTranscript 
                                                    WHERE ChatKey = :chatKey];
                    
                    chat.CustomerNo__c = customerNo != 0 ? customerNo : null;
                    chat.DasherNo__c = dasherNo != 0 ? dasherNo : null;
                    chat.DeliveryNo__c = deliveryNo != 0 ? deliveryNo : null;
                    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                    // 10/2021 Jeegar BIZS-539 Set the DeliveryUUID on chat only if the deliveryUUID field is not blank. 

                    if(String.isNotBlank(deliveryUUID)) {
                        chat.DeliveryUUID__c  = deliveryUUID;
                    }
                    chat.MerchantNo__c = merchantNo != 0 ? merchantNo : null;

                    // this code should only work for dashers
                    /*
                    if (chatButtonId.containsIgnoreCase('5731a00000005iJ')) {
                        // get the business id and let's get ready to rumble
                        if (res.merchantId != null) {
                            CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
                            CDdRestJSONObj.RestAPIResponse response = connector.getDoorstep('/v1/stores/' + (String.valueOf(res.merchantId).indexOf('.') != -1 ? String.valueOf(res.merchantId).substringBefore('.') : String.valueOf(res.merchantId)), '/?extra=business');
                            CDdRestJSONObj.DoorstepStoreGetResponse store = (CDdRestJSONObj.DoorstepStoreGetResponse) System.JSON.deserialize(response.body, CDdRestJSONObj.DoorstepStoreGetResponse.class);
                            if (store.business != null) {
                                chat.Dispatch_Business_No__c = store.business.id;
                                businessId = store.business.id;
                            } else if (!String.isBlank(store.detail)) {
                                System.debug(LoggingLevel.ERROR, '[VChatMonitor] store.detail = ' + store.detail);
                            }
                        }
                    }
                    */
                    
                    //upsert chat;
                }
                

                // NOTE: If you want to prefill any case information that is not specified in custom settings you can pass
                // that here. You are not required to pass any case information or initialize salesforceCase
                res.salesforceCase = new Case(ChatKey__c=chatKey,Origin = 'Chat', DispatchRQStatus__c = 'Success',
                    //description='Dasher: ' + dasherNo+', customerNo' + customerNo + ', DeliveryNo: ' + deliveryNo+
                    //'merchantNo: ' + merchantNo, 
                    DispatchRQAttempts__c = cl.retryAttempts,
                    DispatchRQResponse__c = dispatchResponse
                    );
                
                if (businessId != 0) {
                    res.salesforceCase.Business_Id__c = businessId;
                }

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

                // BZAP-7328 Populate chat issue on case
                Boolean copyChatIssue = CDdExperimentSvc.getFeatureFlag('Copy_Chat_Issue_From_Transcript__c')
                                            || Test.isRunningTest();
                if (copyChatIssue && chat != null){
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
                if (String.isBlank(res.salesforceCase.Country__c)){
                    res.salesforceCase.Country__c = cm.Country__c;
                }
                
                if (CDdExperimentSvc.getSupportFeatureFlag('Enable_Chat_Monitor_Case_Save__c')){
                    CDdDispatchRecordService svc = new CDdDispatchRecordService();
                    svc.upsertDeliveryInfo(new List<VDeliveryInformation> { res });
                    cObj = res.salesforceCase;
                    upsert cObj;
                } else {
                    VDispatchRecordService svc = new VDispatchRecordService();
                    svc.upsertDeliveryInfo(new List<VDeliveryInformation> { res });
                    cObj = res.salesforceCase;
                }
            }
            else {
                throw new CDdException(Label.DispatchBlankSalesforceAudienceInfo);
            }
        }
        catch(Exception ex) {
            system.debug('<><>ex'+ex);
            // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
            if (cObj.DeliveryUUID__c == null){
                cObj.DeliveryUUID__c = deliveryUUID;
            }
            if (cObj.DeliveryNo__c == null){
                cObj.DeliveryNo__c = deliveryNo;
            }
            if(String.isNotBlank(chatButtonId) || Test.isRunningTest()) {
                // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                chat = (LiveChatTranscript) [SELECT 
                                             Id, CustomerNo__c, DasherNo__c, 
                                             DeliveryNo__c, DeliveryUUID__c, MerchantNo__c,
                                             CustomerName__c, CustomerPhone__c, CustomerEmail__c,
                                             DasherName__c, DasherPhoneNo__c, DasherEmail__c, 
                                             Dispatch_Business_No__c, ChatKey ,
                                             Issue__c, Issue_Details__c,
                                             LiveChatButtonId, LiveChatDeploymentId 
                                             FROM LiveChatTranscript 
                                             WHERE ChatKey = :chatKey];
                chat.CustomerNo__c = customerNo != 0 ? customerNo : null;
                chat.DasherNo__c = dasherNo != 0 ? dasherNo : null;
                chat.DeliveryNo__c = deliveryNo != 0 ? deliveryNo : null;
                // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                // 10/2021 Jeegar BIZS-539 if NOT (Chat.DeliveryUUID != null && DeliveryUUID == null) 
                
                if(String.isNotBlank(deliveryUUID)) {
                    chat.DeliveryUUID__c  = deliveryUUID;
                }
                chat.MerchantNo__c = merchantNo != 0 ? merchantNo : null;
                chat.Dispatch_Business_No__c = businessId;
                //upsert chat;
            }

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
            if (copyChatIssue && chat != null){
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
            if(!ex.getMessage().contains(Label.DispatchBlankSalesforceAudienceInfo)){
                cObj.Subject = 'Error Creating case';
            }
            cObj.Origin = 'Chat';
            String delId = '';
            // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
            Boolean useUUID = (apiSettings.Use_UUID__c != null 
                            && apiSettings.Use_UUID__c == true) 
                            ? true : false; 
            if (String.isNotBlank(deliveryUUID) && useUUID){
                delId = deliveryUUID;
            } else {
                delId = String.valueOf(deliveryNo);
            }
            cObj.description = 'C: ' + customerNo + ', d:' + dasherNo + ', deli: ' + 
                delId + ', mNo: ' + merchantNo + '\n' + ex.getMessage();
            cObj.DispatchRQAttempts__c = cl.retryAttempts;
            if (String.isNotBlank(cl.responseData)) {
                cObj.DispatchRQResponse__c = cl.responseData;
            }
            cObj.DispatchCalloutException__c = ex.getMessage();
            cObj.DispatchRQStatus__c = 'Failure';
            cObj.chatkey__c = chatKey;
            if(caseRecordType != null && caseRecordType != '') {
                cObj.recordTypeId = caseRecordType;
            }
            if (businessId != 0) {
                cObj.Business_Id__c = businessId;
            }

            // 02/2021 Tia Xuan BZAPSUP-1591 - Update Chat Monitor Code in Salesforce for Cx and Dx Mobile and Web Chat
            LiveChatButton chatBtn = [select Id, WindowLanguage from LiveChatButton where Id =: chat.LiveChatButtonId];
            Country_Mapping__c cm = CDdSupportHelper.getCountryMapping(chatBtn.WindowLanguage);
            cObj.Language__c = cm.Language__c;
            if (String.isBlank(cObj.Country__c)){
                cObj.Country__c = cm.Country__c;
            }
            upsert cObj;   

            // BIZS-950 get rid of loggin no delivery number
            if (ex.getMessage() != Label.LDdDispatchDelivery0 && !ex.getMessage().contains(Label.DispatchBlankSalesforceAudienceInfo)){   
                CDdErrorUtilities.publishException('VChatMonitor','createCase',ex);
            }
        }
        /**
         * get casenumber of the new case created
         */
        if(cObj != null && cObj.id != null) {
            cObj = [select Id, AccountId, ContactId, CaseNumber from Case where Id = :cObj.Id];

            // assign case to chat transcript
            chat.CaseId = cObj.Id;
            chat.AccountId = cObj.AccountId; 
            chat.ContactId = cObj.ContactId;
            update chat;
        }

        return cObj;
    }

    /**
    * @description calling dispatch for sendbird cases
    */        
    @RemoteAction
    public static Case SendbirdCaseToDispatch(ID workItemId){
        if (!CDdExperimentSvc.getSupportFeatureFlag('Enable_Dispatch_for_Sendbird__c') ){
            return null;
        }

        Case cObj = [select Id,
                            RecordType.Name,
                            Origin,
                            Channel__c,
                            DeliveryNo__c,
                            DeliveryUUID__c, 
                            Customer_Type__c,
                            Consumer_ID__c,
                            Dasher_ID__c,
                            Store_ID__c
                    from Case
                    where Id =: workItemId];
        
        if (!(cObj.RecordType.Name == 'Support'
            && cObj.Origin == 'Chat'
            && cObj.Channel__c == 'DoorDash App - Sendbird')){
            return null;
        }

        VDispatchDeliveryCallout dispatch = new VDispatchDeliveryCallout(cObj.DeliveryNo__c, cObj.DeliveryUUID__c);    
        try {

            VDeliveryInformation res = dispatch.makeDeliveryCallout();

            if(res != null) {
                if(cObj.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_CONSUMER) {
                    res.liveAgentCustomerId = res.customerId;
                } else if(cObj.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_DASHER) {
                    res.liveAgentDasherId = res.dasherId;
                } else if(cObj.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_MERCHANT) {
                    res.liveAgentMerchantId = res.merchantId;
                }
    
                // NOTE: If you want to prefill any case information that is not specified in custom settings you can pass
                // that here. You are not required to pass any case information or initialize salesforceCase
                res.salesforceCase = cObj;
                res.salesforceCase.DispatchRQStatus__c = 'Success';
                res.salesforceCase = VDeliveryInformation.populateCustomerSegment(res, res.salesforceCase);
                res.salesforceCase.DispatchRQAttempts__c = dispatch.retryAttempts;
                res.salesforceCase.DispatchRQResponse__c = dispatch.responseData;
    
                VDispatchRecordService svc = new VDispatchRecordService();
                svc.upsertDeliveryInfo(new List<VDeliveryInformation> { res });
                
                cObj = res.salesforceCase;
            }
        }
        catch(Exception ex) {
            String delId = '';
            // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
            Boolean useUUID = (apiSettings.Use_UUID__c != null 
                            && apiSettings.Use_UUID__c == true) 
                            ? true : false; 
            if (String.isNotBlank(cObj.DeliveryUUID__c) 
                    && useUUID){
                delId = cObj.DeliveryUUID__c;
            } else {
                delId = String.valueOf(cObj.DeliveryNo__c);
            }
            cObj.Subject = 'Error Creating case';
            cObj.Origin = 'Chat';
            /* ??
            cObj.description = 'C: ' + chat.CustomerNo__c + ', d:' + chat.DasherNo__c + ', deli: ' + 
                delId + ', mNo: ' + chat.MerchantNo__c + '\n' + ex.getMessage();
            */ 

            cObj.DispatchRQAttempts__c = dispatch.retryAttempts;
            if (String.isNotBlank(dispatch.responseData)) {
                cObj.DispatchRQResponse__c = dispatch.responseData;
            }
            cObj.DispatchCalloutException__c = ex.getMessage();
            cObj.DispatchRQStatus__c = 'Failure';
            cObj.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            upsert cObj;    
        }

        return cObj;
    }

    @RemoteAction  
    public static void stampPreviousQueue(ID workItemId) {
        CDdChatMonitorController.treatPreviousQueue(workItemId);
    }

    /**
     * @description take ownership
     */
    @RemoteAction 
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

    /**
     * @author      Mahesh Chouhan
     * @date        April 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-961
     * @description Check if DispatchRQResponse__c is Success on Case
     */
    @RemoteAction
    public static Boolean isDispatchSuccessful(Id workItemId) {

        List<Case> chatCase = [SELECT ID, DispatchRQStatus__c 
                               FROM Case
                               WHERE Id = :workItemId];
        return chatCase.size() > 0 && chatCase[0].DispatchRQStatus__c == 'Success';
    }
}