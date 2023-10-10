/**
* @author: salesforce.com
* @date: 2020-09-15
* @description Trigger handler for LiveChatTranscriptEvent.
*/

public class CDdLiveChatTransEventTriggerHandler {
    
    // declaration(s)
    @TestVisible private static List<String> errorMessages = new List<String>();
    @TestVisible private static List<String> vendors = null;
    @TestVisible private static Boolean throwTestException = false;
    @TestVisible private static final String OTHER = 'Other';
    @TestVisible private static Boolean trueUpQueued = false;
    @TestVisible private static List<Vendor_User_Mapping__mdt> vendorUserMappings = null;
    @TestVisible private static Time createdTime = null;
    @TestVisible private static Boolean updateLiveChatTranscriptDisabled = false; 

    /**
     * @description before insert handler.
     * 
     * NOTE: Per documentation (https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_livechattranscriptevent.htm)
     * 
     * "LiveChatTranscriptEvent records are inserted after the chat is closed and the LiveTranscript record updated. 
     * However, the trigger on the LiveChatTranscriptEvent sObject fires separately on each LiveChatTranscriptEvent 
     * record within the same transaction. All the LiveChatTranscriptEvent records are inserted in a single
     * transaction but one by one."
    */
    public void beforeInsert(List<LiveChatTranscriptEvent> newList) {

        // get record, only one in each call per documentation (see description above)
        LiveChatTranscriptEvent record = newList[0];

        // if transfer/accept event and agent id present
        if (!CDdExperimentSvc.getSupportFeatureFlag('Disable_Transcript_Accept_Time__c')){
            if ((record.Type == 'Transfer' || record.Type == 'Accept') && record.AgentId != null) {
                handleAgentTransferAcceptEvent(record);
            }
        }
        
        /*ADDED BY SAHIL*/
        //true up vendor distributions asynchronously. 2 ways to do it : Future method or Platform events.
        //One of the 2 ways have to be enabled from custom metadata.
        if (!trueUpQueued ) {
            trueUpQueued = true;
            if (!CDdCustomMetadata.isDisabled('CDdLiveChatTransEventTHandler_tUVDF')) {
                trueUpVendorDistributionsFuture(record.LiveChatTranscriptId);
            } else if (!CDdCustomMetadata.isDisabled('CDdLiveChatTransEventTHandler_tUVDPE')) {
                if(CDdExperimentSvc.getSupportFeatureFlag('Use_LCTPlatformEvent__c')) {
                    CDdLCTPlatformEventHelper.publishEvents(CDdLCTPlatformEventHelper.PlatformEventType.LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD, 
                    new Set<Id>{record.liveChatTranscriptId});
                } else {
                    trueUpVendorDistributionsPE(record.liveChatTranscriptId);
                } 
            }
        }
    }
    
    // before update handler
    public void beforeUpdate(Map<Id,LiveChatTranscriptEvent> newMap, Map<Id,LiveChatTranscriptEvent> oldMap) { }
    
    // before delete pdate handler
    public void beforeDelete(Map<Id,LiveChatTranscriptEvent> oldMap) { 
        checkDeleteTranscriptEvent(oldMap.values());
    }
    
    // after insert handler
    public void afterInsert(Map<Id,LiveChatTranscriptEvent> newMap) { 
        if (!CDdExperimentSvc.getSupportFeatureFlag('Disable_Transcript_Accept_Time__c')){
            handleTimeStamping(newMap);
        }
    }
    
    // after update handler
    public void afterUpdate(Map<Id,LiveChatTranscriptEvent> newMap, Map<ID, LiveChatTranscriptEvent> oldMap) { }
    
    /**
     * @description Updates chat transcript with the actual vendor, based on
     *              initial interacting (transfer/accept event) agent (email/company)
     * 
    */
    public static void handleAgentTransferAcceptEvent(LiveChatTranscriptEvent record) {
        
        // if method is disabled then return  
        if (CDdCustomMetadata.isDisabled('CDdLiveChatTransEventTriggerHandler_hATA')) return;
        try {

            // get vendors, if not already retrieved in transaction
            if (vendors == null) {
                vendors = new List<String>();
                for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
                {
                    vendors.add(ple.getLabel());
                }
            }
            
            // get chat transcript record
            List<LiveChatTranscript> lcts = [SELECT Id, CreatedDate, LiveChatButton.DeveloperName, Preferred_Vendor__c, Actual_Vendor__c
                                             FROM LiveChatTranscript
                                             WHERE Id = :record.LiveChatTranscriptId];
            if (lcts.size() == 1) {

                // if actual vendor not already set
                if (lcts[0].Actual_Vendor__c == null) {
                    
                    // get agent info
                    User agent = [SELECT Id, Email, CompanyName
                                  FROM User
                                  WHERE Id = :record.AgentId];
                    String agentEmail = agent.Email == null ? '' : agent.Email;
                    String agentCompanyName = agent.CompanyName == null ? '' : agent.CompanyName;
                    
                    // get vendor user mappings if needed
                    if (vendorUserMappings == null) {
                        vendorUserMappings = [SELECT MasterLabel, Email_Domain_Prefixes__c,
                                              Company_Name__c
                                              FROM Vendor_User_Mapping__mdt];
                    }
                    
                    // loop through vendor user mappings
                    String vendor = '';
                    for (Vendor_User_Mapping__mdt vendorUserMapping : vendorUserMappings) {
                        
                        // get values
                        String vumEmailDomainPrefixes = vendorUserMapping.Email_Domain_Prefixes__c == null ?
                            '' : vendorUserMapping.Email_Domain_Prefixes__c;
                        String vumCompanyName = vendorUserMapping.Company_Name__c == null ?
                            '' : vendorUserMapping.Company_Name__c;
                        
                        // split email domains and check against agent email
                        Boolean emailMatch = false;
                        for (String emailDomain : vumEmailDomainPrefixes.split('\n')) {
                            emailMatch = agentEmail.containsIgnoreCase('@' + emailDomain.trim());
                            if (emailMatch) { break; }
                        }
                        
                        // if user email or company name matches vendor user mapping values
                        if (emailMatch || agentCompanyName.equalsIgnoreCase(vumCompanyName))
                        {
                            vendor = vendorUserMapping.MasterLabel;
                            break;
                        }
                    }
                    
                    // update chat transcript with actual vendor
                    if (String.isNotEmpty(vendor)) {
                        lcts[0].Actual_Vendor__c = vendor;
                        update(lcts[0]);
                    }
                }
            }
            
            // throw exception for test coverage
            if (Test.isRunningTest() && throwTestException) {
                throw new CDdLiveChatTransEventTriggerHandlerException('Test Exception');
            }
        } catch (Exception e) {
            
            // log exception
            system.debug(e.getMessage());
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdLiveChatTransEventTriggerHandler', 
                                             'handleAgentTransferAcceptEvent', LoggingLevel.ERROR);
        }
    }
    /**
     * @description Trues up vendor distribution records based on actual vs. preferred
     *              vendor Future Method. 
     * 
    */

    @future
    public static void trueUpVendorDistributionsFuture(Id trueUpVendorDistributions){
        trueUpVendorDistributions(trueUpVendorDistributions);
    }
    /**
     * @description Trues up vendor distribution records based on actual vs. preferred
     *              vendor
     * 
    */
    
    public static void trueUpVendorDistributions(Id liveChatTranscriptId) {
        // if method is disabled then return  
        if (CDdCustomMetadata.isDisabled('CDdLiveChatTransEventTriggerHandler_hATA')) return;
        try {
            
            // get chat transcript record
            // 03/2021 Tia Xuan BZAPSUP-1527 VIP chat routing
            List<LiveChatTranscript> lcts = [SELECT Id, CreatedDate, LiveChatButton.DeveloperName,
                                             Preferred_Vendor__c, Actual_Vendor__c, is_VIP__c
                                             FROM LiveChatTranscript
                                             WHERE Id = :liveChatTranscriptId];
            if (lcts.size() == 1) {
                
                String chatButtonName = lcts[0].LiveChatButton.DeveloperName;
                Map<String,VIP_Chat_Button_Mapping__c> vipBtnMap = VIP_Chat_Button_Mapping__c.getAll();
                if (lcts[0].is_VIP__c){
                    if (vipBtnMap.containsKey(chatButtonName)){
                        chatButtonName = VIP_Chat_Button_Mapping__c.getAll().get(chatButtonName).VIP_Chat_Button_Name__c;
                    }
                }
                // get chat button distributions
                List<Chat_Button_Distribution__c> cbds = [SELECT Id, Start_Time__c, End_Time__c, Last_Count_Reset__c, Skip_Vendor_Distributions__c
                                                          FROM Chat_Button_Distribution__c
                                                          WHERE Chat_Button_API_Name__c = :chatButtonName
                                                          ORDER BY Start_Time__c ASC];
                
                // loop through chat button distributions to determine which to use
                Chat_Button_Distribution__c chatButtonDist = null;
                createdTime = createdTime == null ? lcts[0].CreatedDate.time() : createdTime;
                for (Chat_Button_Distribution__c cbd : cbds) {
                    
                    // default to distribution with no start/end
                    chatButtonDist = cbd.Start_Time__c == null ? cbd : chatButtonDist;
                    
                    // if current time between start/end (break on first match)
                    if (createdTime >= cbd.Start_Time__c && createdTime <= cbd.End_Time__c) {
                        chatButtonDist = cbd;
                        break;
                    }
                }
                
                // if chat button distribution found and last reset is before chat was created
                if (chatButtonDist != null && (chatButtonDist.Last_Count_Reset__c == null || chatButtonDist.Last_Count_Reset__c < lcts[0].CreatedDate)) {
                    
                    // get values
                    String preferredVendor = lcts[0].Preferred_Vendor__c == null ? '' : lcts[0].Preferred_Vendor__c;
                    String actualVendor = lcts[0].Actual_Vendor__c == null ? '' : lcts[0].Actual_Vendor__c;
                    
                    // if actual vendor not the same as the preferred vendor
                    if (!actualVendor.equalsIgnoreCase(preferredVendor)) {
                        
                        // find vendor distributions for actual/preferred vendors
                        List<Vendor_Distribution__c> vds = [SELECT Id, Vendor__c, Actual_Chat_Count__c
                                                            FROM Vendor_Distribution__c
                                                            WHERE Chat_Button_Distribution__c = :chatButtonDist.Id
                                                            AND (Vendor__c = :actualVendor OR Vendor__c = :preferredVendor) FOR UPDATE];
                                         
                        if (vds.size() > 0) {
                            
                            // loop through vendor distributions
                            for (Vendor_Distribution__c vd : vds) {
                                
                                // default chat count to zero if needed
                                vd.Actual_Chat_Count__c = vd.Actual_Chat_Count__c == null ? 0 : vd.Actual_Chat_Count__c;
                                
                                // if actual vendor then increment chat count, otherwise decrement it;
                                // preferred vendor got count incremented when chat was created, now
                                // that another vendor took the chat we are truing up the count
                                vd.Actual_Chat_Count__c += vd.Vendor__c.equalsIgnoreCase(actualVendor) ? 1 : -1;
                            }
                            // update vendor distributions
                            update(vds);
                        }
                    }
                }
            }
            
            // throw exception for test coverage
            if (Test.isRunningTest() && throwTestException) {
                throw new CDdLiveChatTransEventTriggerHandlerException('Test Exception');
            }
        } catch (Exception e) {
            
            // log exception
            system.debug(e.getMessage());
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdLiveChatTransEventTriggerHandler', 
                                             'trueUpVendorSites', LoggingLevel.ERROR);
        }
    }
    

    /**
     *  @description  Update LiveChatTranscript record with Chat Accept, PushAssignment, Transfer Event Times if
     *                  Chat_Event_Accept_Time__c of the associated LiveChatTranscript is blank.
     *  @date        11/30/2020
     *  @JIRA        BZAPSUP-1292
     *  @author      Jeegar
     */

    public static void handleTimeStamping(Map<Id, LiveChatTranscriptEvent> newMap) {
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getInstance();
        updateLiveChatTranscriptDisabled = featureFlag.DisableCDdLCTETriggerHandler_hULCT__c; 
        
        if (updateLiveChatTranscriptDisabled) return; 
        
        Live_Chat_Transcript_Settings__c lctSetting = Live_Chat_Transcript_Settings__c.getInstance(); 
        String acceptEventsString;
        
        if(String.isblank(lctSetting.Accept_Events__c)) {
            // if custom setting value is blank, set Default. 
            acceptEventsString = 'Transfer;Accept;PushAssignment';
        } else {
            acceptEventsString = lctSetting.Accept_Events__c;
        }
        List<String> acceptEvents = acceptEventsString.split(';');
        // get record, only one in each call per documentation (see description above)
        LiveChatTranscriptEvent record = newMap.values()[0];

        if((acceptEvents.contains(record.Type)) && record.AgentId != null) {
            
            updateLiveChatTranscriptAcceptTime(record);
        }
    }
    /**
     *  @description Update LiveChatTranscript record with Chat Accept, PushAssignment, Transfer Event Times if
     *                  Chat_Event_Accept_Time__c of the associated LiveChatTranscript is blank.
     *  @date        11/30/2020
     *  @JIRA        BZAPSUP-1292
     *  @author      Jeegar
     */

    public static void updateLiveChatTranscriptAcceptTime(LiveChatTranscriptEvent lCTEventrecord) {
        
        try {
            List<liveChatTranscript> liveChatTranscripts = [SELECT Id, Chat_Event_Accept_Time__c
                                                            FROM LiveChatTranscript
                                                            WHERE id = :lCTEventrecord.LiveChatTranscriptId]; 
            LiveChatTranscript lcTranscript; 
            if (liveChatTranscripts.size() == 1) {
                lcTranscript = liveChatTranscripts[0];
                if (String.isBlank(String.valueOf(lcTranscript.Chat_Event_Accept_Time__c))) {
                    
                    lcTranscript.Chat_Event_Accept_Time__c = lCTEventrecord.Time;
                }
                update lcTranscript; 
            }
            
        } catch (Exception e) {
            system.debug(e.getMessage());
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdLiveChatTransEventTriggerHandler', 
                                             'updateLiveChatTranscriptAcceptTime', LoggingLevel.ERROR);
        }

    }



    /**
     * @description Trues up vendor distribution records based on actual vs. preferred
     *              vendor using platform Event. 
     *              Modified trueUpVendorDistributions() to be bulkified since Platform Events might bulkify the data. 
     * @author      jeegar
     * @jira        BZAPSUP-1334
     * @date        12/4/2020
     * 
    */
    
    public static void trueUpVendorDistributionsPE(Id liveChatTranscriptId) {
        Set<Id> lctIds = new Set<Id>(); 
        lctIds.add(liveChatTranscriptId);
        CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD, 
        lctIds);
    }

    /**
     *  @description Unable users to delete LiveChatTranscriptEvent
     *  @date        12/2021
     *  @JIRA        BASD-19921
     *  @author      Tia Xuan
     */
    public static void checkDeleteTranscriptEvent(List<LiveChatTranscriptEvent> eventList) {
        if (!CDdExperimentSvc.getSupportFeatureFlag('Disable_Delete_Transcript_Event__c')){
            return;
        }

        List<String> errorMessages = new List<String>();
        for (LiveChatTranscriptEvent evt : eventList){
            evt.addError(Label.Cannot_Delete_Transcript_Event);
            errorMessages.add('Id:' + evt.Id + 'UserId:' + UserInfo.getUserId());
        } 

        CDdErrorUtilities.createApexLogs(errorMessages, 'CDdLiveChatTransEventTriggerHandler', 'checkDeleteTranscriptEvent', LoggingLevel.DEBUG);
    }





    // exception test class
    public class CDdLiveChatTransEventTriggerHandlerException extends Exception { }
}