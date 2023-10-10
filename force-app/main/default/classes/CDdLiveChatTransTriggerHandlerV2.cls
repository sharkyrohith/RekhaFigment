/**
 * @author      Sahil Chaudhry
 * @date        Dec 2021
 * @decription  BIZS-814 - LiveChatTranscript Trigger Handler V2
 *
 */
public class CDdLiveChatTransTriggerHandlerV2 {

    @TestVisible private static List<String> errorMessages = new List<String>();
    @TestVisible private static Boolean throwTestException = false;
    @TestVisible private static Time nowTime = null;
    CDdSupportOwnerAssignment cSupportAssignment = new CDdSupportOwnerAssignment();
    public static final String CONSUMER_VIP_BUTTON_PREFIX = 'Consumer Chat Button - VIP - ';
    public static final String CONSUMER_VIP_OVERFLOW_FLAG_NAME = 'Enable_Chat_VIP_Overflow__c';
    public static final String METADATA_SKIP_VENDOR_SPLIT = 'Enable_Metadata_Skip_Vendor_Split__c';
    public static final String ENABLE_SET_OWENR_ASSIGNMENT = 'LCT_Enable_Set_Owner_Assignment__c';
    public static boolean ranOnce = false;
    public static final Boolean ENABLE_TRANS_HISTORY_ID_CHECK = CDdExperimentSvc.getFeatureFlag('Enable_Trans_History_Id_Check__c');
    private static final String CMT_ROUTING_EXP_PERCENT = 'LCT_CMT_Routing_Exp_Percentage__c';
    public static Map<String, List<Issue_Based_Routing_Map__mdt>> issueCategoryRoutingMap =
        new Map<String, List<Issue_Based_Routing_Map__mdt>>();
    public static Integer cpuUsageLCTTriggerHandler = 0;
    public static final Boolean doDebug = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Debug_Logs__c');
    public static final Boolean doCPUTimeCheck = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_CPU_Time_Check__c');
    public static final String BEFORE_INSERT = '><><><><>CDdLiveChatTransTriggerHandlerV2.beforeInsert()';
    public static final String BEFORE_UPDATE = '><><><><>CDdLiveChatTransTriggerHandlerV2.beforeUpdate()';
    public static final String AFTER_INSERT = '><><><><>CDdLiveChatTransTriggerHandlerV2.afterInsert()';
    public static final String AFTER_UPDATE = '><><><><>CDdLiveChatTransTriggerHandlerV2.afterUpdate()';

    public CDdLiveChatTransTriggerHandlerV2(List<LiveChatTranscript> newList) {
        CDdUtilities.debug(LoggingLevel.DEBUG,'CDdLiveChatTransTriggerHandlerV2.CDdLiveChatTransTriggerHandlerV2()',doDebug);
        Set<Id> relatedCaseIds = new Set<Id>();
        for (LiveChatTranscript lctVar : newList) {
            if (lctVar.CaseId != null) {
                relatedCaseIds.add(lctVar.CaseId);
            }
        }
        CDdLiveChatTransOptimizationHelper.setCaseMap(relatedCaseIds);
    }

    private void logCpuUsage(String triggerContext,String method) {
        cpuUsageLCTTriggerHandler = CDdUtilities.calculateCPUUsage(triggerContext,(method.endsWith('= ') ? method : method + '= '),
                                                                    cpuUsageLCTTriggerHandler,doCPUTimeCheck);
        if (method == 'End' || method == 'Start') {
            String msg = 'CPU: ' + Limits.getCpuTime() + ' / ' + Limits.getLimitCpuTime() + '\n' +
                'Heap: ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize() + '\n' +
                'SOQL: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries() + '\n' +
                'DML Row: ' + Limits.getDmlRows() + ' / ' + Limits.getLimitDmlRows() + '\n' +
                'DML Statement: ' + Limits.getDmlStatements() + ' / ' + Limits.getDmlStatements();
            CDdUtilities.debug(LoggingLevel.WARN, triggerContext + 'LIMITS LOGGER = \n' + msg, true);
        }
    }

    public void beforeInsert(List<LiveChatTranscript> newList) {
        try {
            cpuUsageLCTTriggerHandler = 0;
            logCpuUsage(BEFORE_INSERT,'Start');
            CDdLiveChatTransTriggerHelper.associateChatIds(newList, null);
            handleDispatchResponse(newList);
            setPreferredVendor(newList);
            setChatOwner(newList);//Sets owner based on custom settings
            CDdLiveChatTransTriggerHelper.populateCaseWithChatKey(newList, null);
            logCpuUsage(BEFORE_INSERT,'End');
        } catch (Exception ex) { 
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','beforeInsert', ex);
        }
    }

    public void beforeUpdate(Map<Id,LiveChatTranscript> newMap, Map<Id,LiveChatTranscript> oldMap) {
        try {
            cpuUsageLCTTriggerHandler = 0;
            logCpuUsage(BEFORE_UPDATE,'Start');
            CDdLiveChatTransTriggerHelper.associateChatIds(newMap.values(), oldMap);
            CDdLiveChatTransTriggerHelper.populateCaseWithChatKey(newMap.values(), oldMap);
            logCpuUsage(BEFORE_UPDATE,'End');
        } catch (Exception ex) { 
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','beforeUpdate', ex);
        }
    }

    public void afterInsert(Map<Id,LiveChatTranscript> newMap) {
        try {
            cpuUsageLCTTriggerHandler = 0;
            logCpuUsage(AFTER_INSERT,'Start');
            CDdLiveChatTransTriggerHelper.populateTimesOnCases(newMap, null);
            CDdLiveChatTransTriggerHelper.populatePreviousQueue(newMap.values(), null);
            CDdLiveChatTransTriggerHelper.populateCaseSuppliedName(newMap.values(), null);
            CDdLiveChatTransOptimizationHelper.executeSObjectDML();
            logCpuUsage(AFTER_INSERT,'executeSObjectDML');
            logCpuUsage(AFTER_INSERT,'End');
        } catch (Exception ex) { 
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','afterInsert', ex);
        }
    }

    public void afterUpdate(Map<Id,LiveChatTranscript> newMap, Map<ID, LiveChatTranscript> oldMap) {
        try {
            cpuUsageLCTTriggerHandler = 0;
            logCpuUsage(AFTER_UPDATE,'Start');
            CDdLiveChatTransTriggerHelper.populateTimesOnCases(newMap, oldMap);
            CDdLiveChatTransTriggerHelper.populatePreviousQueue(newMap.values(), oldMap);
            CDdLiveChatTransTriggerHelper.populateCaseSuppliedName(newMap.values(), oldMap);
            CDdLiveChatTransOptimizationHelper.executeSObjectDML();
            logCpuUsage(AFTER_UPDATE,'executeSObjectDML');
            logCpuUsage(AFTER_UPDATE,'End');
        } catch (Exception ex) {
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','afterUpdate', ex); 
        }
    }

    /**
     * @author: salesforce.com
     * @date: 2020-09-16
     * @description Sets the preferred vendor for dynamic routing.
    */
    public static void setPreferredVendor(list<LiveChatTranscript> records) {
        // if(ranOnce) return;
        try {
            // if method is disabled then return
            if (CDdCustomMetadata.isDisabled('CDdLiveChatTranscriptTriggerHandler_sPV')) return;
            List<LiveChatTranscript> transcripts = new List<LiveChatTranscript>();
            // declaration(s)
            Set<Id> chatButtonIds = new Set<Id>();
            Map<String, LiveChatButton> chatButtonAPIMap = new Map<String, LiveChatButton>();
            Map<String, Map<String, Integer>> chatButtonFutureMap = new Map<String, Map<String, Integer>>();
            // 03/2021 Tia Xuan BZAPSUP-1527 VIP chat routing
            Map<String,VIP_Chat_Button_Mapping__c> vipBtnMap = VIP_Chat_Button_Mapping__c.getAll();
            Set<String> vipButtonNameList = new Set<String>();
            Set<String> vendorSplitButtonNameList = new Set<String>();
            Set<String> setVendorChatButtn = new Set<String>();
            Map<Id,CDdIssueBasedRoutingHelper.RoutingInfo> mapLiveChatRoutingInfo = new Map<Id,CDdIssueBasedRoutingHelper.RoutingInfo>();
    
            for (VIP_Chat_Button_Mapping__c btn : vipBtnMap.values()){
                if(btn.is_vip__c) {
                    vipButtonNameList.add(btn.VIP_Chat_Button_Name__c);
                } else {
                    vendorSplitButtonNameList.add(btn.VIP_Chat_Button_Name__c);
                }
    
            }
            // retrieve chat button ids
            List<String> emailList = new List<String>();
            for (LiveChatTranscript record : records) {
                if (String.isNotEmpty(record.LiveChatButtonId)) {
                    chatButtonIds.add(record.LiveChatButtonId);
                }
                if (String.isNotBlank(record.CustomerEmail__c)){
                    emailList.add(record.CustomerEmail__c);
                }
            }
            //Nayana 10/14/2021: BIZS-527 C&R experiment changes
            Map<String,Integer> mapCustomerSegmentNumber = new Map<String,Integer>();
            // 03/2021 Tia Xuan BZAPSUP-1527 VIP chat routing
            Set<String> vipCustomerList = new Set<String>();
            Integer audienceNumber = 0;
            if (emailList.size() > 0){
                List<Audience_Attribute__c> vipList = [select Id, email__c,VIP__c from Audience_Attribute__c where email__c =: emailList AND VIP__c>0];
                for (Audience_Attribute__c vip : vipList){
                    audienceNumber = vip.VIP__c!=null ? Integer.valueOf(vip.VIP__c): 0;
                    if(CDdSupportHelper.lstVipNumbers.contains(audienceNumber)){
                        vipCustomerList.add(vip.email__c);
                    }
                    mapCustomerSegmentNumber.put(vip.email__c,audienceNumber);
                }
            }
            // 03/2021 Tia Xuan BZAPSUP-1711 VIP overflow
            List<Service_Statistics__c> liveAgentStats = [  select  Id,
                                                                    Live_Agent_Estimated_Wait_Time__c,
                                                                    Live_Agent_Button_Name__c
                                                            from Service_Statistics__c
                                                            where RecordType.Name = 'Live Agent'];
            Map<String, Service_Statistics__c> laStatsMap = new Map<String, Service_Statistics__c>();
            for (Service_Statistics__c ss : liveAgentStats){
                laStatsMap.put(ss.Live_Agent_Button_Name__c, ss);
            }
    
            // loop through chat transcripts : Nayana 10/2021: Vendor chat button was not getting used in query.
            for (LiveChatTranscript record : records) {
                Integer customerSegmentNo = 0 ;
                if(mapCustomerSegmentNumber.containsKey(record.CustomerEmail__c)){
                    customerSegmentNo = mapCustomerSegmentNumber.get(record.CustomerEmail__c);
                    if(CDdSupportHelper.mapCustomerSegmentmapping.containsKey(customerSegmentNo)){
                        record.Customer_Segment__c = CDdSupportHelper.mapCustomerSegmentmapping.get(customerSegmentNo);
                    }
                }
                CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(record);
                if(String.isNotBlank(routingInfo.vendorChatButtonId)){
                    setVendorChatButtn.add(routingInfo.vendorChatButtonId);
                }
                mapLiveChatRoutingInfo.put(record.Id,routingInfo);
            }
            // if chat button ids exist (mainly for testing)
            if (chatButtonIds.size() > 0) {
    
                // get chat button details
                Map<Id, LiveChatButton> chatButtonMap = new Map<Id, LiveChatButton>([SELECT Id, DeveloperName
                                                                                     FROM LiveChatButton
                                                                                     WHERE (Id IN :chatButtonIds
                                                                                            OR DeveloperName IN : vipButtonNameList
                                                                                            OR DeveloperName IN : vendorSplitButtonNameList
                                                                                            OR DeveloperName IN : setVendorChatButtn)]);
    
                // create map of chat button API names
                for (LiveChatButton lcb : chatButtonMap.values()) {
                    chatButtonAPIMap.put(lcb.DeveloperName, lcb);
                }
    
                // get chat distributions for the chat buttons
                Map<String, List<Chat_Button_Distribution__c>> chatButtonDistMap = new Map<String, List<Chat_Button_Distribution__c>>();
                for (Chat_Button_Distribution__c chatButtonDist : [SELECT Id, Chat_Button_API_Name__c, Skip_Vendor_Distributions__c,
                                                                   Start_Time__c, End_Time__c,
                                                                   (SELECT Id, Vendor__c, Target_Distribution__c, Actual_Distribution__c
                                                                    FROM Vendor_Distributions__r
                                                                    ORDER BY Target_Distribution__c DESC)
                                                                   FROM Chat_Button_Distribution__c
                                                                   WHERE Chat_Button_API_Name__c IN :chatButtonAPIMap.keySet()
                                                                   ORDER BY Chat_Button_API_Name__c ASC, Start_Time__c ASC])
                {
    
                    // add chat button API name to map if not already present
                    if (!chatButtonDistMap.containsKey(chatButtonDist.Chat_Button_API_Name__c)) {
                        chatButtonDistMap.put(chatButtonDist.Chat_Button_API_Name__c, new List<Chat_Button_Distribution__c>());
                    }
    
                    // add chat button distribution to map
                    chatButtonDistMap.get(chatButtonDist.Chat_Button_API_Name__c).add(chatButtonDist);
                }
    
                // loop through chat transcripts
                for (LiveChatTranscript record : records) {
                    Integer customerSegmentNo = 0 ;
                    if(mapCustomerSegmentNumber.containsKey(record.CustomerEmail__c)){
                        customerSegmentNo = mapCustomerSegmentNumber.get(record.CustomerEmail__c);
                        if(CDdSupportHelper.mapCustomerSegmentmapping.containsKey(customerSegmentNo)){
                            record.Customer_Segment__c = CDdSupportHelper.mapCustomerSegmentmapping.get(customerSegmentNo);
                        }
                    }
                    Boolean runMetadataBasedRouting = CDdExperimentSvc.getSupportPercentageBasedExperimentFlag(CMT_ROUTING_EXP_PERCENT);
                    CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = mapLiveChatRoutingInfo.get(record.Id);
    
                    // add experiment service flag somewhere here.
                    if(routingInfo == null) {
                        routingInfo = getDefaultRoutingInfo();
                    }
                    // declaration(s)
                    Boolean skipVendorDistributions = false;
    
                    // get chat button API name from map
                    String chatButtonAPIName = chatButtonMap.containsKey(record.LiveChatButtonId) ?
                        chatButtonMap.get(record.LiveChatButtonId).DeveloperName : null;
                    String vipChatButtonName = vipBtnMap.containsKey(chatButtonAPIName) ?
                    vipBtnMap.get(chatButtonAPIName).VIP_Chat_Button_Name__c : null;
    
                    // 03/2021 Tia Xuan BZAPSUP-1527 VIP chat routing
                    // vendor distribution for MetadataBased Routing
                    // check for edge cases here as well.
    
                    if (String.isNotBlank(record.CustomerEmail__c)
                        && vipCustomerList.contains(record.CustomerEmail__c)
                        && chatButtonDistMap.containsKey(vipChatButtonName)){
                            record.is_VIP__c = true;
                            chatButtonAPIName = vipChatButtonName;
                    }else if(!routingInfo.standardRouting && routingInfo.doVendorSplit) {
                        chatButtonAPIName = routingInfo.vendorChatButtonId;
                    }
                    // if chat button API name found and there are chat button distributions
                    if (String.isNotEmpty(chatButtonAPIName) && chatButtonDistMap.containsKey(chatButtonAPIName)) {
    
                        // loop through chat button distributions to determine which to use
                        Chat_Button_Distribution__c chatButtonDist = null;
                        nowTime = nowTime == null ? DateTime.now().time() : nowTime;
                        for (Chat_Button_Distribution__c cbd : chatButtonDistMap.get(chatButtonAPIName)) {
    
                            // default to distribution with no start/end
                            chatButtonDist = cbd.Start_Time__c == null ? cbd : chatButtonDist;
    
                            // if current time between start/end (break on first match)
                            if (nowTime >= cbd.Start_Time__c && nowTime <= cbd.End_Time__c) {
                                chatButtonDist = cbd;
                                break;
                            }
                        }
    
                        // if chat distributions found
                        if (chatButtonDist != null) {
    
                            // loop through vendor distributions for chat button API name
                            for (Vendor_Distribution__c vd : chatButtonDist.Vendor_Distributions__r) {
                                Boolean skipVendorSplit = false;
                                if(runMetadataBasedRouting) {
                                    // if experiment is true
                                    // if standard Routing is FALSE meaning there is an IssueBased Routing to consider
                                    // skipVendorSplit = NOT(doVendorSplit)
                                    // i.e. (if doVendorSplit = FALSE then skipVendorSplit = TRUE)
                                    // If Standard routing = true then skipVendorSplit = FALSE
                                    // skipVendorSplit = (!routingInfo.standardRouting ? !routingInfo.doVendorSplit : false);
    
                                    if(!routingInfo.standardRouting) {
                                        // if doVendorSplit == TRUE then Set skipVendorSplit = FALSE
                                        // if doVendorSplit == FLASE then Set skipVendorSplit = true
                                        skipVendorSplit = !routingInfo.doVendorSplit;
                                    } else {
                                        // if standard routing, do do not skip vendor split
                                        skipVendorSplit = false;
                                    }
    
                                } else if (CDdExperimentSvc.getSupportFeatureFlag(METADATA_SKIP_VENDOR_SPLIT)){
                                    skipVendorSplit= skipVendorSplit(record.Issue__c, record.Issue_Subcategory__c,
                                        record.Is_VIP__c, record.LiveChatButtonId);
                                } else {
                                    skipVendorSplit = skipVendorSplit(record);
                                }
                                /**
                                 * IF the experiment is TRUE
                                 * AND Routing Info has Standard Routing FALSE
                                 * AND Routing Info has Prioritize VIP FALSE (
                                 *      If prioritize VIP = True do not set the queue and it will be routed to the VIP queue)
                                 * Set the Issue_Based_Queue__c to Routing Destination
                                 *
                                 * Issue_Based_Queue__c is used in the BOT for routing
                                 */
    
                                // Check this logic. how will it behave if the Is_VIP__c = TRUE AND PrioritizeVIP = false
                                // what shoudl the behavior be?
    
                                if(runMetadataBasedRouting
                                        && !routingInfo.standardRouting
                                        && (!routingInfo.prioritizeVIP || !record.Is_VIP__c)) {
    
                                    record.Issue_Based_queue__c = routingInfo.routingDestination;
                                }
    
                                // if vendor distributions are skipped, then break
                                skipVendorDistributions = chatButtonDist.Skip_Vendor_Distributions__c || skipVendorSplit ;
                                if (skipVendorDistributions) {
                                    break;
                                }
                                // default preferred vendor to highest threshold
                                record.Preferred_Vendor__c = String.isEmpty(record.Preferred_Vendor__c) ?
                                    vd.Vendor__c : record.Preferred_Vendor__c;
    
                                // if current distribution is less than target distribution then set preferred vendor
                                if (vd.Actual_Distribution__c < vd.Target_Distribution__c) {
                                    record.Preferred_Vendor__c = vd.Vendor__c;
                                    // Tia Xuan 03/2021 BZAPSUP-1711 Chat VIP time based Overflow
                                    // how to do Issue based vendor split?
                                    // essentially hwo do i move the below code block into routing framework?
                                    // may be add a new field in the routing config to send the Preferrred Vendor Prefix
                                    //
                                    if (record.Is_VIP__c && routingInfo.prioritizeVIP){
                                        record.Cx_VIP_Preferred_Vendor_Button__c = CONSUMER_VIP_BUTTON_PREFIX + record.Preferred_Vendor__c;
                                        if (CDdExperimentSvc.getSupportFeatureFlag(CONSUMER_VIP_OVERFLOW_FLAG_NAME)){
                                            if (laStatsMap.containsKey(record.Cx_VIP_Preferred_Vendor_Button__c)
                                                && vipBtnMap.containsKey(record.Cx_VIP_Preferred_Vendor_Button__c)){
                                                Service_Statistics__c ss = laStatsMap.get(record.Cx_VIP_Preferred_Vendor_Button__c);
                                                VIP_Chat_Button_Mapping__c cbMap = vipBtnMap.get(record.Cx_VIP_Preferred_Vendor_Button__c);
                                                record.Cx_VIP_Preferred_Vendor_Wait_Time__c = ss.Live_Agent_Estimated_Wait_Time__c;
                                                if (record.Cx_VIP_Preferred_Vendor_Wait_Time__c > cbMap.Max_Chat_Wait_Time__c){
                                                    record.Cx_VIP_Pref_Vendor_WT_Over_Threshold__c = true;
                                                }
                                            }
                                        }
                                    }
                                    break;
                                }
                                // vendor split for mtd based routing goes here.
                                if(routingInfo.doVendorSplit){}
                            }
    
                            // if vendor distributions are not skipped
                            if (!skipVendorDistributions) {
    
                                // add chat button to future map
                                if (!chatButtonFutureMap.containsKey(chatButtonDist.Id)) {
                                    chatButtonFutureMap.put(chatButtonDist.Id, new Map<String, Integer>());
                                }
    
                                // add vendor to chat button future map
                                if (!chatButtonFutureMap.get(chatButtonDist.Id).containsKey(record.Preferred_Vendor__c)) {
                                    chatButtonFutureMap.get(chatButtonDist.Id).put(record.Preferred_Vendor__c, 0);
                                }
    
                                // increment chat button future map vendor counter
                                Integer vendorCount = chatButtonFutureMap.get(chatButtonDist.Id).get(record.Preferred_Vendor__c) + 1;
                                chatButtonFutureMap.get(chatButtonDist.Id).put(record.Preferred_Vendor__c, vendorCount);
                            }
                        }
                    }
                    transcripts.add(record);
                    if(transcripts.size()> 0 )ranOnce = true;
                }
    
                // if there are vendor sites to update
                if (chatButtonFutureMap.size() > 0) {
                    // convert into list of entries
                    List<ChatButtonEntry> inputList = new List<ChatButtonEntry>();
                    for (String chatButtonId : chatButtonFutureMap.keySet()) {
                        ChatButtonEntry cbe = new ChatButtonEntry();
                        cbe.chatButtonId = chatButtonId;
                        cbe.vendorDistributionMap = chatButtonFutureMap.get(chatButtonId);
                        inputList.add(cbe);
                    }
    
                    String cbePayload;
                    if (!inputList.isEmpty()) {
                        cbePayload = JSON.serialize(inputList);
                    }
    
                    //increment vendor chat count with future or platform events
                    if (Test.isRunningTest()) {
                      if (CDdLiveChatTransTriggerHandlerV2Test.callFutureMethod && !CDdCustomMetadata.isDisabled('CDdLiveChatTranscriptTrHler_iVccF') && String.isNotBlank(cbePayload)) {
                        incrementVendorChatCountFuture(cbePayload);
                      } else if (!CDdLiveChatTransTriggerHandlerV2Test.callFutureMethod && !CDdCustomMetadata.isDisabled('CDdLiveChatTranscriptTrHler_iVccPE') && String.isNotBlank(cbePayload)) {
                          if(CDdExperimentSvc.getSupportFeatureFlag('Use_LCTPlatformEvent__c')) {
                              CDdLCTPlatformEventHelper.publishEvents(CDdLCTPlatformEventHelper.PlatformEventType.INCREMENT_VENDORCHATCOUNT,
                              null, cbePayload);
                          } else {
                              incrementVendorChatCountPE(cbePayload);
                          }
                      }
                    } else {
                        if (!CDdCustomMetadata.isDisabled('CDdLiveChatTranscriptTrHler_iVccF') && String.isNotBlank(cbePayload)) {
                            incrementVendorChatCountFuture(cbePayload);
                        } else if (!CDdCustomMetadata.isDisabled('CDdLiveChatTranscriptTrHler_iVccPE') && String.isNotBlank(cbePayload)) {
                            if(CDdExperimentSvc.getSupportFeatureFlag('Use_LCTPlatformEvent__c')) {
                                CDdLCTPlatformEventHelper.publishEvents(CDdLCTPlatformEventHelper.PlatformEventType.INCREMENT_VENDORCHATCOUNT,
                                null, cbePayload);
                            } else {
                                incrementVendorChatCountPE(cbePayload);
                            }
                        }
                    }
                }
            }
            // throw exception for test coverage
            if (Test.isRunningTest() && throwTestException) {
                throw new CDdLiveChatTransTriggerHandlerV2Exception('Test Exception');
            }
        } catch (Exception e) {
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','setPreferredVendorSite',e);
        }
    }

    /**
     * @author: Sahil
     * @date: 2020-02-14
     * @description calls increment vendor chat count method asynchronously with future callout
     *
    */
    @future
    public static void incrementVendorChatCountFuture(String inputPayload) {
        try {
            List<ChatButtonEntry> cbeList = (List<ChatButtonEntry>) System.JSON.deserialize(inputPayload, List<ChatButtonEntry>.class);
            incrementVendorChatCount(cbeList);
        } catch (Exception e) {
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','incrementVendorChatCountFuture',e);
        }

    }

    /**
     * @author: Mahesh Chouhan
     * @date: 07-16-2021
     * @description extracts payload from LCT platform event and calls increment vendor chat count method
     *
    */
    public static void handleIncrementVendorCCPE(List<Live_Chat_Transcript_Platform_Event__e> lctPEList) {
        try {
            List<ChatButtonEntry> cbeInnerList = new List<ChatButtonEntry>();
            List<ChatButtonEntry> cbeListOuter = new List<ChatButtonEntry>();
            for (Live_Chat_Transcript_Platform_Event__e lctVar : lctPEList) {
                if (String.isNotBlank(lctVar.Payload__c)) {
                    cbeInnerList = (List<ChatButtonEntry>) System.JSON.deserialize(lctVar.Payload__c, List<ChatButtonEntry>.class);
                    cbeListOuter.addAll(cbeInnerList);
                }
            }
        //call business method
        incrementVendorChatCount(cbeListOuter);
        } catch (Exception ex) {
            errorMessages.add(ex.getMessage());
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','handleIncrementVendorCCPE',ex);
        }
    }

    /**
     * @author: Sahil
     * @date: 2020-02-14
     * @description extracts payload from platform event and calls increment vendor chat count method
     *
    */
    public static void handleIncrementVendorCCPE(List<Generic_Platform_Event__e> genPEList) {
        try {
            List<ChatButtonEntry> cbeInnerList = new List<ChatButtonEntry>();
            List<ChatButtonEntry> cbeListOuter = new List<ChatButtonEntry>();
            for (Generic_Platform_Event__e gPEVar : genPEList) {
                if (String.isNotBlank(gPEVar.Payload__c)) {
                    cbeInnerList = (List<ChatButtonEntry>) System.JSON.deserialize(gPEVar.Payload__c, List<ChatButtonEntry>.class);
                    cbeListOuter.addAll(cbeInnerList);
                }
            }
        //call business method
        incrementVendorChatCount(cbeListOuter);
        } catch (Exception ex) {
            errorMessages.add(ex.getMessage());
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','handleIncrementVendorCCPE',ex);
        }
    }
    /**
     * @author: salesforce.com
     * @date: 2020-09-24
     * @description Increments the chat count for the preferred vendor that got the chat.
     * 				Done asynchronously due to record locking requirement.
    */
    public static void incrementVendorChatCount(List<ChatButtonEntry> inputList) {
        try {
            if (!inputList.isEmpty()) {
                // populate chat button map by looping through the input list
                Map<String, Map<String, Integer>> chatButtonFutureMap = new Map<String, Map<String, Integer>>();
                for (ChatButtonEntry cbeVar : inputList) {
                    chatButtonFutureMap.put(cbeVar.chatButtonId, cbeVar.vendorDistributionMap);
                }
                // loop through inputs and add all vendors to the overall set
                Set<String> vendors = new Set<String>();
                for (String chatButtonAPIName : chatButtonFutureMap.keySet()) {
                    vendors.addAll(chatButtonFutureMap.get(chatButtonAPIName).keySet());
                }

                // lock all vendors that might need to be updated
                List<Vendor_Distribution__c> vendorDistributions = [SELECT Id, Actual_Chat_Count__c, Vendor__c, Chat_Button_Distribution__c
                                                                    FROM Vendor_Distribution__c
                                                                    WHERE Chat_Button_Distribution__c IN :chatButtonFutureMap.keySet()
                                                                    AND Vendor__c IN :vendors FOR UPDATE];

                // loop through locked records
                for (Vendor_Distribution__c vendorDistribution : vendorDistributions) {

                    // if vendor needs to be updated
                    String chatButtonId = vendorDistribution.Chat_Button_Distribution__c;
                    if (chatButtonFutureMap.containsKey(chatButtonId) &&
                        chatButtonFutureMap.get(chatButtonId).containsKey(vendorDistribution.Vendor__c))
                    {
                        vendorDistribution.Actual_Chat_Count__c += chatButtonFutureMap.get(chatButtonId).get(vendorDistribution.Vendor__c);
                    }
                }
                // update records
                List<Database.SaveResult> results = Database.update(vendorDistributions,false);
                CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','incrementVendorChatCount',results);
            }
            // throw exception for test coverage
            if (Test.isRunningTest() && throwTestException) {
                throw new CDdLiveChatTransTriggerHandlerV2Exception('Test Exception');
            }
        } catch (Exception e) {
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.publishException('CDdLiveChatTransTriggerHandlerV2','incrementVendorChatCount',e);
        }
    }
    /**
     * @author: Sahil
     * @date: 2021-02-14
     * @description this method fires off a platform event with a json payload as input
     *
    */
    public static void incrementVendorChatCountPE(String chatButtonEntryList) {
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.INCREMENT_VENDORCHATCOUNT,null,chatButtonEntryList);
    }
    /**
     * @author Jeegar
     * @date: 2021-03
     * @description this method decides if the vendorsplit should be executed or not for a given chat. This is primarily used for ATO
     *
     */
    public static boolean skipVendorSplit(LiveChatTranscript chatTranscript){
        if(!String.isBlank(chatTranscript.Issue__c)
            && !String.isBlank(chatTranscript.Issue_Subcategory__c)){
            if ( !chatTranscript.is_vip__c
                && (chatTranscript.Issue__c.equalsIgnoreCase(CDdSupportConstants.CHAT_TRANS_ISSUE_PAYMENTS)
                        && chatTranscript.Issue_Subcategory__c.equalsIgnoreCase(CDdSupportConstants.CHAT_TRANS_ISSUE_SUBCAT_REPORT_UNAUTH_CHARGE) )
                    || (chatTranscript.Issue__c.equalsIgnoreCase(CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS)
                        && (chatTranscript.Issue_Subcategory__c.equalsIgnoreCase(CDdSupportConstants.CHAT_TRANS_ISSUE_SUBCAT_REACTIVATE_DD_ACCT)
                        || chatTranscript.Issue_Subcategory__c.equalsIgnoreCase(CDdSupportConstants.CHAT_TRANS_ISSUE_SUBCAT_FRAUD_ACCT_ACTIVITY))
                )){
                return true;
            } else {
                return false;
            }
        }
        else {
            return false;
        }
    }

    public static boolean skipVendorSplit(String issueCategory, String  issueSubCategory, Boolean isVIP, String chatButtonId) {
        Boolean skipVendorSplit = false;
        Set<String> issueCategories;
        if(issueCategoryRoutingMap == null || issueCategoryRoutingMap.keyset().size() == 0){
            issueCategoryRoutingMap = CDdChatTranscriptUtilities.getIssuebasedRoutingMap();
        }
        if(isVIP || !issueCategoryRoutingMap.containsKey(issueCategory)) {
            return skipVendorSplit;
        }
        for(Issue_Based_Routing_Map__mdt ibRouting : issueCategoryRoutingMap.get(issueCategory)) {
            issueCategories = new Set<String>();
            if( chatButtonId != null
                && chatButtonId.equalsIgnoreCase(ibRouting.Chat_Button_Id__c)) {

                if(String.isNotBlank(ibRouting.Issue_Subcategory__c)) {
                    issueCategories.addAll(ibRouting.Issue_Subcategory__c.split(';'));
                    for(String issueSubCat : issueCategories){
                        if(issueSubCat.equalsIgnoreCase(issueSubCategory)){
                            skipVendorSplit = true;
                            break;
                        }
                    }
                }
            }

        }

        return skipVendorSplit;
    }

    public static CDdIssueBasedRoutingHelper.RoutingInfo getDefaultRoutingInfo() {
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = new CDdIssueBasedRoutingHelper.RoutingInfo();

        routingInfo.prioritizeVIP = true;
        routingInfo.routingDestination = '';
        routingInfo.doVendorSplit = true;
        routingInfo.standardRouting = true;
        routingInfo.vendorChatButtonId = '';

        return routingInfo;

    }
    /**
     * @author Dinesh
     * @date: 2021-08
     * @description this method decides the owner assignment based on custom settings
     * @jira BIZS-307
     */

    public void setChatOwner(List<LiveChatTranscript> records) {
        if (CDdExperimentSvc.getSupportFeatureFlag(ENABLE_SET_OWENR_ASSIGNMENT) == false) return;

        Boolean ownerAssigned;
        //get all Support Assignment Mapping from custom settings
        List<Support_Assignment_Mapping__c> listOfSAM = CDdSupportHelper.getSupportAssignmentRecordsByObject('Chat');

        //Create a Collection based on unique Combinations to reduce iterations.
        Map<String, Support_Assignment_Mapping__c> sortedMapOfSAM = new Map<String, Support_Assignment_Mapping__c>();
        sortedMapOfSAM = getSupportAssignmentMappings(listOfSAM);
        if(sortedMapOfSAM != null && sortedMapOfSAM.size() > 0 ){
            // Assign ownerId based on the custom settings sortedMap
            for (LiveChatTranscript record : records){
                if (record.Issue_Based_Queue__c != null){
                    string issueBasedString = record.Issue_Based_Queue__c + '-';
                    if (record.Is_VIP__c && record.Cx_VIP_Pref_Vendor_WT_Over_Threshold__c){
                        if (sortedMapOfSAM.containsKey(issueBasedString+'VIP-Thresold' + '-' + record.Preferred_Vendor__c + '-' + record.LiveChatButtonId)){
                            record.ownerId = sortedMapOfSAM.get(issueBasedString+'VIP-Thresold' + '-' + record.Preferred_Vendor__c + '-' + record.LiveChatButtonId).Queue_Id__c;
                            assignFinalOwner(record);
                            continue;
                        }
                    }
                    if (record.Is_VIP__c && record.Preferred_Vendor__c != null){
                        if (sortedMapOfSAM.containsKey(issueBasedString+'VIP-' + record.Preferred_Vendor__c + '-' + record.LiveChatButtonId)){
                            record.ownerId = sortedMapOfSAM.get(issueBasedString+'VIP-' + record.Preferred_Vendor__c + '-' + record.LiveChatButtonId).Queue_Id__c;
                            assignFinalOwner(record);
                            continue;
                        }
                    }
                    if (record.Preferred_Vendor__c != null){
                        if (sortedMapOfSAM.containsKey(issueBasedString+record.Preferred_Vendor__c + '-' + record.LiveChatButtonId)){
                            record.ownerId = sortedMapOfSAM.get(issueBasedString+record.Preferred_Vendor__c + '-' + record.LiveChatButtonId).Queue_Id__c;
                            assignFinalOwner(record);
                            continue;
                        }

                    }

                    if (sortedMapOfSAM.containsKey(issueBasedString+record.LiveChatButtonId)){
                        record.ownerId = sortedMapOfSAM.get(issueBasedString+record.LiveChatButtonId).Queue_Id__c;
                        assignFinalOwner(record);
                        continue;
                    }
                }
                if (record.Preferred_Vendor__c != null){
                    if (record.Is_VIP__c && record.Cx_VIP_Pref_Vendor_WT_Over_Threshold__c){
                        if (sortedMapOfSAM.containsKey('VIP-Thresold' + '-' + record.Preferred_Vendor__c + '-' + record.LiveChatButtonId)){
                            record.ownerId = sortedMapOfSAM.get('VIP-Thresold' + '-' + record.Preferred_Vendor__c + '-' + record.LiveChatButtonId).Queue_Id__c;
                            assignFinalOwner(record);
                            continue;
                        }
                    }
                    if (record.Is_VIP__c && record.Preferred_Vendor__c != null){
                        if (sortedMapOfSAM.containsKey('VIP-' + record.Preferred_Vendor__c + '-' + record.LiveChatButtonId)){
                            record.ownerId = sortedMapOfSAM.get('VIP-' + record.Preferred_Vendor__c + '-' + record.LiveChatButtonId).Queue_Id__c;
                            assignFinalOwner(record);
                            continue;
                        }
                    }
                    if (record.Preferred_Vendor__c != null){
                        if (sortedMapOfSAM.containsKey(record.Preferred_Vendor__c + '-' + record.LiveChatButtonId)){
                            record.ownerId = sortedMapOfSAM.get(record.Preferred_Vendor__c + '-' + record.LiveChatButtonId).Queue_Id__c;
                            assignFinalOwner(record);
                            continue;
                        }
                    }

                }
            }
        }
    }

    /**
     * @author Nayana
     * @date: 2021-09
     * @description this method is used to assign routing reason and owner as overflowQueue queue
     * @jira BIZS-439
     */
    private void assignFinalOwner(LiveChatTranscript chatRec) {
        CDdSupportOwnerAssignment.OwnerRoutingInfo oInfo =cSupportAssignment.findFinalOwner(chatRec.ownerId);
        chatRec.Routing_Reason__c = oInfo.routingReason;
        chatRec.OwnerId = oInfo.ownerId;
    }


    /**
     * @author Dinesh
     * @date: 2021-09
     * @description this method is used to arange the SAM records in a Map based on priority
     * @jira BIZS-307
     */
    private Map<String, Support_Assignment_Mapping__c> getSupportAssignmentMappings(List<Support_Assignment_Mapping__c> listOFSAM){
        Map<String, Support_Assignment_Mapping__c> sortedMapOfSAM = new Map<String, Support_Assignment_Mapping__c>();
        for (Support_Assignment_Mapping__c sam : listOfSAM){
            if (sam.Issue_Based_Queue__c != null){
                string issueBasedString = sam.Issue_Based_Queue__c + '-';
                if (sam.Is_VIP__c && sam.Threshold__c){
                    sortedMapOfSAM.put(issueBasedString + 'VIP-Thresold' + '-' + sam.Chat_Button_Id__c, sam);
                } else if (sam.Is_VIP__c && sam.Preferred_Vendor__c != null){
                    sortedMapOfSAM.put(issueBasedString + 'VIP-' + sam.Preferred_Vendor__c + '-' + sam.Chat_Button_Id__c, sam);
                } else if (sam.Preferred_Vendor__c != null){
                    sortedMapOfSAM.put(issueBasedString + sam.Preferred_Vendor__c + '-' + sam.Chat_Button_Id__c, sam);
                } else{
                    sortedMapOfSAM.put(issueBasedString+sam.Chat_Button_Id__c, sam);
                }

            }
            else if (sam.Preferred_Vendor__c != null){
                if (sam.Is_VIP__c && sam.Threshold__c){
                    sortedMapOfSAM.put('VIP-Thresold' + '-'+sam.Preferred_Vendor__c+'-' + sam.Chat_Button_Id__c, sam);
                } else if (sam.Is_VIP__c && sam.Preferred_Vendor__c != null){
                    sortedMapOfSAM.put('VIP-' + sam.Preferred_Vendor__c + '-' + sam.Chat_Button_Id__c, sam);
                } else if (sam.Preferred_Vendor__c != null){
                    sortedMapOfSAM.put(sam.Preferred_Vendor__c + '-' + sam.Chat_Button_Id__c, sam);
                }
            }
            else if(sam.Preferred_Vendor__c == null && sam.Issue_Based_Queue__c==null) {
            	sortedMapOfSam.put(sam.Chat_Button_Id__c,sam);
            }
        }

        return sortedMapOfSAM;
    }

    /**
     * @author Mahesh
     * @date: 2022-04
     * @description Populate data from Dispatch Response
     * @jira BIZS-961
     */
    public void handleDispatchResponse(List<LiveChatTranscript> newList) {
        Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();
        for (LiveChatTranscript newChat : newList){
            if(!String.isBlank(newChat.DispatchRQResponse__c)) {
                VDeliveryInformation res = apiSettings.Use_ERS_API__c ?
                    CDdDispatchDeliveryInformation.deserialize(newChat.DispatchRQResponse__c)[0] :
                    VDeliveryInformation.deserialize(newChat.DispatchRQResponse__c);

                newChat.Business_Vertical_ID__c = res.merchantBusinessVerticalId;
                newChat.DispatchRQStatus__c = 'Success';
            }
        }
    } 

    // custom class for serialization to future method
    public class ChatButtonEntry {
        public String chatButtonId { get; set; }
        public Map<String, Integer> vendorDistributionMap { get; set; }
        public ChatButtonEntry() {
            vendorDistributionMap = new Map<String, Integer>();
        }
    }
    
    // exception test class
    public class CDdLiveChatTransTriggerHandlerV2Exception extends Exception { }
}