/**
 * CDdVendorSplitHelper
 *
 * @author      Sahil (sahil.chaudhry@doordash.com)
 * @date        08/02/2021
 * @decription  Splits incoming work item to vendors
 */
public with sharing class CDdVendorSplitHelper {
    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    @TestVisible private static Boolean iVCCFuture = false;
    @TestVisible private static Boolean iVCCPlatEvent = false;
    @TestVisible private static Boolean tUVDFuture = false;
    @TestVisible private static Boolean tUVDPlatEvent = false;
    @TestVisible private static Time nowTime = null;
    @TestVisible private static Time caseCreatedTime = null;
    //Key is Formstack Category and Value is List of Formstack Subcategory
    private static Map<String, Set<String>> blockedFormstackCategoryMap = new Map<String, Set<String>>();
    CDdSupportOwnerAssignment cSupportAssignment = new CDdSupportOwnerAssignment();

    static {
        for(Offender_Setting__mdt offenderSetting : Offender_Setting__mdt.getAll().values()) {
            if(offenderSetting.Is_Active__c){
                if(!blockedFormstackCategoryMap.containsKey(offenderSetting.Formstack_Category__c)){
                    blockedFormstackCategoryMap.put(offenderSetting.Formstack_Category__c, new Set<String>());
                }
                blockedFormstackCategoryMap.get(offenderSetting.Formstack_Category__c).add(offenderSetting.Formstack_Subcategory__c);
            }
        }
    }
    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    sets case owner of incoming cases
    * @param         list of cases
    * @return        None
    */
    public static void setCaseOwner(List<Case> newCaseList, System.TriggerOperation operationType) {
        try {
            Set<String> chatButtonSet = new Set<String>();
            Map<Case, CDdIssueBasedRoutingHelper.RoutingInfo> caseToRoutingInfoMap =
                                                                        new Map<Case, CDdIssueBasedRoutingHelper.RoutingInfo>();
            List<FeedItem> lstCaseFeedItems = new List<FeedItem>();
            //Nayana: check in the database if the customer is a VIP
            //https://doordash.atlassian.net/browse/BASD-24065
            Set<Decimal> consumerIdSet = new Set<Decimal>();
            Set<String> emails = new Set<String>();
            if (String.valueOf(operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_INSERT))) {
                List<Case> filteredCases = filterOffenderCases(newCaseList);
                emails = handleFormstackCasesWithSuppliedEmail(filteredCases);
                consumerIdSet.addAll(handleFormstackCasesWithStoreId(filteredCases));
            }
            Map<Decimal, Audience_Attribute__c> consumerIdMap = new Map<Decimal, Audience_Attribute__c>();
            Map<String, Audience_Attribute__c> consumeEmailMap = new Map<String, Audience_Attribute__c>();

            Map<Case,Map<String,String>> mapCaseVendorQueues = new Map<Case,Map<String,String>>();
            List<String> lstVendorQueueDevName = new List<String>();

            for (Case caseVar : newCaseList) {
                if (caseVar.Consumer_ID__c != null) {
                    consumerIdSet.add(caseVar.Consumer_ID__c);
                }
            }
            if (!emails.isEmpty() || !consumerIdSet.isEmpty()) {
                for (Audience_Attribute__c aAttVar : [SELECT Id, Email__c,VIP__c, Audience_ID__c FROM Audience_Attribute__c WHERE Email__c IN :emails OR Audience_ID__c IN :consumerIdSet]) {
                    if(String.isNotBlank(aAttVar.Email__c)){
                        consumeEmailMap.put(aAttVar.Email__c, aAttVar);
                    }
                    if(aAttVar.Audience_ID__c != null){
                        consumerIdMap.put(aAttVar.Audience_ID__c, aAttVar);
                    }
                }
            }
            //check criteria on each case and get routing Destination
            CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = new CDdIssueBasedRoutingHelper.RoutingInfo();
            for (Case caseVar : newCaseList) {
                Integer customerSegmentNo = 0 ;
                if((caseVar.Consumer_ID__c != null && consumerIdMap.containsKey(caseVar.Consumer_ID__c))
                    || (String.isNotBlank(caseVar.Store_ID__c) && CDdUtilities.isDecimal(caseVar.Store_ID__c) && consumerIdMap.containsKey(Decimal.valueOf(caseVar.Store_ID__c)))
                    || (String.isNotBlank(caseVar.SuppliedEmail) && consumeEmailMap.containsKey(caseVar.SuppliedEmail))){
                    customerSegmentNo = consumerIdMap.containsKey(caseVar.Consumer_ID__c) ?
                                    Integer.valueOf(consumerIdMap.get(caseVar.Consumer_ID__c).VIP__c) : (String.isNotBlank(caseVar.Store_ID__c) && consumerIdMap.containsKey(Decimal.valueOf(caseVar.Store_ID__c)) ?
                                    Integer.valueOf(consumerIdMap.get(Decimal.valueOf(caseVar.Store_ID__c)).VIP__c) : Integer.valueOf(consumeEmailMap.get(caseVar.SuppliedEmail).VIP__c));
                    if(CDdSupportHelper.mapCustomerSegmentmapping.containsKey(customerSegmentNo)){
                        caseVar.Customer_Segment__c = CDdSupportHelper.mapCustomerSegmentmapping.get(customerSegmentNo);
                    }
                }
                //call metadata framework to check routing criteria based on case data
                routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(caseVar);
                if (String.valueOf(operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_UPDATE))) {
                    if(!CDdSupportConstants.updateEvaluationCriteria.contains(routingInfo.evaluationCriteria)) {
                        continue;
                    }
                    if(routingInfo.evaluationCriteria.contains(CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA)){
                        Case oldCaseRecord = (Case) Trigger.oldMap.get(caseVar.Id);
                        CDdIssueBasedRoutingHelper.RoutingInfo oldCaseRoutingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(oldCaseRecord);

                        if(oldCaseRoutingInfo.routingDestination == routingInfo.routingDestination ||
                            (oldCaseRoutingInfo.standardRouting != routingInfo.standardRouting && routingInfo.standardRouting)) {
                            continue;
                        }
                    }
                }
                if (String.valueOf(operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_INSERT))
                    && !CDdSupportConstants.insertEvaluationCriteria.contains(routingInfo.evaluationCriteria)) {
                        //in the insert context, do not process further if "run only on update" is true
                        continue;
                }
                //added as part BIZS-721
                //update: moved this before populating the caseToRoutingInfoMap to avoid failure when retrieving the key later
                if (String.isNotBlank(routingInfo.routingDestination)) {
                    caseVar.Routing_Destination__c = routingInfo.routingDestination;
                    caseVar.Feature_Logs__c = CDdErrorUtilities.constructFeatureLog('MISSION CONTROL', routingInfo.routingConfigLog, String.isBlank(caseVar.Feature_Logs__c));
                }

                if(routingInfo.fieldUpdates != null && !routingInfo.fieldUpdates.isEmpty()){
                    for(String fieldName : routingInfo.fieldUpdates.keySet()) {
                        caseVar.put(fieldName, routingInfo.fieldUpdates.get(fieldName));
                    }
                }

                if(!routingInfo.lstCaseNotes.isEmpty()){
                    for(String caseNote : routingInfo.lstCaseNotes) {
                        FeedItem cFeed = new FeedItem();
                        cFeed.ParentId = caseVar.Id;
                        cFeed.Body = caseNote;
                        lstCaseFeedItems.add(cFeed);
                    }
                }
                if(routingInfo.routingType == CDdSupportConstants.ATTRIBUTE_BASED_ROUTING){
                    //This will tell Attribute Based Routing
                    caseVar.Routing_Type__c = routingInfo.routingType;
                    //This will have Config Id Stamped
                    caseVar.Routing_Destination__c = routingInfo.routingConfigId;
                    if (String.isNotBlank(routingInfo.vendorChatButtonId) && routingInfo.doVendorSplit) {
                        chatButtonSet.add(routingInfo.vendorChatButtonId);
                        caseToRoutingInfoMap.put(caseVar, routingInfo);
                    }
                    //continue;
                }else{
                    //build a map of chat button names to case
                    if (String.isNotBlank(routingInfo.vendorChatButtonId) && routingInfo.doVendorSplit) {
                        chatButtonSet.add(routingInfo.vendorChatButtonId);
                        //If vendor split is true then deserialize the vendor and vendor queue name
                        if(String.isNotBlank(routingInfo.ownerQueueName)){
                            //Map of vendor name and vendor queue dev name
                            Map<String,String> mapVendorQueueDevName = new Map<String,String>();
                            Map<String,Object> mapFieldValue = (Map<String,Object>) JSON.deserializeUntyped(routingInfo.ownerQueueName);
                            for(String vendorName : mapFieldValue.keySet()){
                                String vendoQDevName = String.valueOf(mapFieldValue.get(vendorName));
                                lstVendorQueueDevName.add(vendoQDevName);
                                mapVendorQueueDevName.put(vendorName,vendoQDevName);
                            }
                            //Case specific vendor and vendor queue map
                            mapCaseVendorQueues.put(caseVar,mapVendorQueueDevName);
                        }
                    }else{
                        lstVendorQueueDevName.add(routingInfo.ownerQueueName);
                    }
                    caseToRoutingInfoMap.put(caseVar, routingInfo);
                }
            }
            //Query to get the queue Id based on Queue Dev name
            CDdGenericTriggerOptimizationHelper.setQueueMap(lstVendorQueueDevName);
            //Loop over query details and find out Queue Id and add to wrapper
            for (Case caseVar : caseToRoutingInfoMap.keySet()) {
                routingInfo = caseToRoutingInfoMap.get(caseVar);
                //We don't want to run this for Attribute based routing
                if(String.isBlank(routingInfo.routingType)){
                    if(routingInfo.doVendorSplit){
                        Map<String,String> mapVendorQueueDevName = mapCaseVendorQueues.get(caseVar);
                        for(String vName:mapVendorQueueDevName.keySet()){
                            Id vendorQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(mapVendorQueueDevName.get(vName));
                            routingInfo.mapVendorQueueMap.put(vName,vendorQueueId);
                        }
                    }
                    else if (String.isNotBlank(routingInfo.routingDestination)) {
                        Boolean isOwnerFieldUpdate = routingInfo.fieldUpdates.containsKey('OwnerId');
                        String caseOwnerId = isOwnerFieldUpdate ? (String) routingInfo.fieldUpdates.get('OwnerId') :
                                             CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(routingInfo.ownerQueueName);
                        if (String.isNotBlank(caseOwnerId)) {
                            caseVar.OwnerId = (Id)caseOwnerId;
                            new CDdVendorSplitHelper().assignFinalOwner(caseVar);
                        }
                    }
                }
            }
            if (!chatButtonSet.isEmpty() && !caseToRoutingInfoMap.isEmpty()) {
                Map<String, List<Chat_Button_Distribution__c>> chatButtonDistMap = getChatButtonToChatDist(chatButtonSet);
                if (!chatButtonDistMap.isEmpty()) {
                    setPreferredVendor(chatButtonDistMap,caseToRoutingInfoMap,consumerIdMap);
                }
            }
            if(!lstCaseFeedItems.isEmpty()){
                CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.CREATE_CASE_FEED,
                                                        null,JSON.serialize(lstCaseFeedItems)); //platform event
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdVendorSplitHelper','setCaseOwner', e);
        }
    }

    public static Set<Decimal> handleFormstackCasesWithStoreId(List<Case> newCaseList) {
        Set<Decimal> consumerIdSet = new Set<Decimal>();
        Set<String> formStackSubcategories = new Set<String>{CDdSupportConstants.FORMSTACK_SUBCATEGORY_ERROR_CHARGE_DISPUTES,
                                                             CDdSupportConstants.FORMSTACK_SUBCATEGORY_ERROR_CHARGE_DISPUTES_2};
        for(Case caseVar : newCaseList) {
            if(String.isNotBlank(caseVar.Store_ID__c)
                && caseVar.Single_Multi_Location_Menu_Update__c == CDdSupportConstants.FORMSTACK_STORE_LOCATION_SINGLE_LOCATION){
                    consumerIdSet.add(Decimal.valueOf(caseVar.Store_ID__c));
            }
        }
        return consumerIdSet;
    }

    public static Set<String> handleFormstackCasesWithSuppliedEmail(List<Case> newCaseList) {
        Set<String> emails = new Set<String>();
        Set<String> formStackSubcategories = new Set<String>{CDdSupportConstants.FORMSTACK_SUBCATEGORY_ERROR_CHARGE_DISPUTES,
                                                             CDdSupportConstants.FORMSTACK_SUBCATEGORY_ERROR_CHARGE_DISPUTES_2};
        for(Case caseVar : newCaseList) {
            if(String.isNotBlank(caseVar.SuppliedEmail)
                && caseVar.Single_Multi_Location_Menu_Update__c == CDdSupportConstants.FORMSTACK_STORE_LOCATION_SINGLE_LOCATION){
                    emails.add(caseVar.SuppliedEmail);
            }
        }
        return emails;
    }

    /**
    * @author        Mahesh Chouhan
    * @date          Nov 2022
    * @decription    Filter Cases having Formstack Category and Subcategory present in Offender Settings
    * @param         List<Case> case record list
    * @return        List of cases having Formstack Category and Subcategory present in Offender Settings
    */
    public static List<Case> filterOffenderCases(List<Case> caseList){
        List<Case> filteredCases = new List<Case>();

        for(Case caseRecord : caseList){
            if(blockedFormstackCategoryMap.containsKey(caseRecord.Formstack_Category__c)
                && blockedFormstackCategoryMap.get(caseRecord.Formstack_Category__c).contains(caseRecord.Formstack_Subcategory__c)){
                    filteredCases.add(caseRecord);
                }
        }
        return filteredCases;
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    gets a map of chat button name to chat button distributions
    * @param         set of chat button Ids from routing framework
    * @return        map of chat button name to chat button distributions
    */
    public static Map<String, List<Chat_Button_Distribution__c>> getChatButtonToChatDist(Set<String> chatButtonSet) {
        Map<String, List<Chat_Button_Distribution__c>> chatButtonDistMap = new Map<String, List<Chat_Button_Distribution__c>>();
        // get chat distributions for the chat buttons
        List<Chat_Button_Distribution__c> cBDistList = [SELECT Id, Chat_Button_API_Name__c, Skip_Vendor_Distributions__c,
                                                        Start_Time__c, End_Time__c, Last_Count_Reset__c,
                                                        (SELECT Id, Vendor__c, Target_Distribution__c, Actual_Distribution__c,
                                                        Actual_Chat_Count__c
                                                        FROM Vendor_Distributions__r
                                                        WHERE Target_Distribution__c > 0
                                                        ORDER BY Target_Distribution__c DESC)
                                                        FROM Chat_Button_Distribution__c
                                                        WHERE Chat_Button_API_Name__c IN :chatButtonSet
                                                        ORDER BY Chat_Button_API_Name__c ASC, Start_Time__c ASC];
        for (Chat_Button_Distribution__c chatButtonDist : cBDistList) {
            // add chat button API name to map if not already present
            if (!chatButtonDistMap.containsKey(chatButtonDist.Chat_Button_API_Name__c)) {
                chatButtonDistMap.put(chatButtonDist.Chat_Button_API_Name__c, new List<Chat_Button_Distribution__c>());
            }
            // add chat button distribution to map
            chatButtonDistMap.get(chatButtonDist.Chat_Button_API_Name__c).add(chatButtonDist);
        }
        return chatButtonDistMap;
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    sets preferred vendor on incoming cases
    * @param         map of chat button distributions, map of case to routing info
    * @return        None
    */
    public static void setPreferredVendor(Map<String, List<Chat_Button_Distribution__c>> chatButtonDistMap,
                                        Map<Case, CDdIssueBasedRoutingHelper.RoutingInfo> caseToRoutingInfoMap,
                                        Map<Decimal, Audience_Attribute__c> consumerIdMap) {
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = new CDdIssueBasedRoutingHelper.RoutingInfo();
        Boolean skipVendorDistributions = false;
        String caseOwnerId = null;
        String chatButtonAPIName;
        Map<String, Map<String, Integer>> incVenChatCountMap = new Map<String, Map<String, Integer>>();
        CDdVendorSplitHelper cVendorSplithlpr = new CDdVendorSplitHelper();
        //loop through cases
        for (Case caseVar : caseToRoutingInfoMap.keySet()) {
            routingInfo = caseToRoutingInfoMap.get(caseVar);
            if (routingInfo != null) {
                chatButtonAPIName = routingInfo.vendorChatButtonId;
            }
            if (String.isNotEmpty(chatButtonAPIName) && chatButtonDistMap.containsKey(chatButtonAPIName)) {
                List<Chat_Button_Distribution__c> chatButtonDistList = chatButtonDistMap.get(chatButtonAPIName);
                if (!chatButtonDistList.isEmpty()) {
                    Chat_Button_Distribution__c chatButtonDist = null;
                    //set current time to determine time based chat button dist
                    nowTime = nowTime == null ? DateTime.now().time() : nowTime;
                    for (Chat_Button_Distribution__c cbd : chatButtonDistList) {
                        // default to distribution with no start/end
                        chatButtonDist = cbd.Start_Time__c == null ? cbd : chatButtonDist;
                        // if current time between start/end (break on first match)
                        if (cbd.Start_Time__c != null && nowTime >= cbd.Start_Time__c
                            && cbd.End_Time__c != null & nowTime <= cbd.End_Time__c) {
                            chatButtonDist = cbd;
                            break;
                        }
                    }
                    if (chatButtonDist != null) {
                        //check for skip vendor distributions flag
                        if (chatButtonDist.Skip_Vendor_Distributions__c) {
                            break;
                        }
                        String preferredVendor = '';
                        // loop through vendor distributions for chat button API name
                        for (Vendor_Distribution__c vd : chatButtonDist.Vendor_Distributions__r) {
                            // if current distribution is less than target distribution then set preferred vendor
                            if ((vd.Actual_Distribution__c != null && vd.Target_Distribution__c != null)
                                && (vd.Actual_Distribution__c < vd.Target_Distribution__c)
                                && String.isNotBlank(vd.Vendor__c)) {
                                preferredVendor = vd.Vendor__c;
                                //check if VIP
                                //???Do we really need this. VIP ones has a different configs and higher sort order.
                                /* if (routingInfo.prioritizeVIP && caseVar.Consumer_ID__c != null
                                    && consumerIdMap.containsKey(caseVar.Consumer_ID__c)) {
                                    caseOwnerId = routingResObj.mapVendorQueueMap.get(caseVar.Preferred_Vendor__c);
                                    if (String.isNotBlank(caseOwnerId)) {
                                        caseVar.OwnerId = (Id)caseOwnerId;
                                        cVendorSplithlpr.assignFinalOwner(caseVar);
                                    }
                                    break;
                                } */
                                break;
                            } else {
                                //route to any vendor from vendor distributions list
                                if (String.isNotBlank(vd.Vendor__c)) {
                                    preferredVendor = vd.Vendor__c;
                                }
                            }
                        }
                        //Once found the preferred vendor get the vendor queue name,
                        if(String.isNotBlank(preferredVendor)){
                            caseVar.Preferred_Vendor__c = preferredVendor;
                            //bypass this for attribute based routing
                            if(String.isBlank(routingInfo.routingType)){
                                caseOwnerId = routingInfo.mapVendorQueueMap.get(preferredVendor);
                                if (String.isNotBlank(caseOwnerId)) {
                                    caseVar.OwnerId = (Id)caseOwnerId;
                                    cVendorSplithlpr.assignFinalOwner(caseVar);
                                }
                            }
                        }
                        //populate map for incrementing vendor chat counts
                        if (!incVenChatCountMap.containsKey(chatButtonDist.Id)) {
                            incVenChatCountMap.put(chatButtonDist.Id, new Map<String, Integer>());
                        }
                        // add vendor to vendor chat count map
                        if (!incVenChatCountMap.get(chatButtonDist.Id).containsKey(caseVar.Preferred_Vendor__c)
                            && String.isNotBlank(caseVar.Preferred_Vendor__c)) {
                            incVenChatCountMap.get(chatButtonDist.Id).put(caseVar.Preferred_Vendor__c, 0);
                        }
                        if (String.isNotBlank(caseVar.Preferred_Vendor__c)) {
                            // increment vendor chat counter
                            Integer vendorCount = incVenChatCountMap.get(chatButtonDist.Id).get(caseVar.Preferred_Vendor__c) + 1;
                            incVenChatCountMap.get(chatButtonDist.Id).put(caseVar.Preferred_Vendor__c, vendorCount);
                        }
                    }
                }
            }
        }
        //increment vendor chat count
        incrementVendorChatCount(incVenChatCountMap);
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    increments vendor chat counts on vendor and chat button distributions
    * @param         map of chat button distributions to vendor distributions count map
    * @return        None
    */
    public static void incrementVendorChatCount(Map<String, Map<String, Integer>> incVenChatCountMap) {
        if (!incVenChatCountMap.isEmpty()) {
            // convert into list of entries
            List<ChatButtonEntry> cbeList = new List<ChatButtonEntry>();
            for (String chatButtonId : incVenChatCountMap.keySet()) {
                ChatButtonEntry cbe = new ChatButtonEntry();
                cbe.chatButtonId = chatButtonId;
                cbe.vendorDistributionMap = incVenChatCountMap.get(chatButtonId);
                cbeList.add(cbe);
            }
            String cbePayload;
            if (!cbeList.isEmpty()) {
                cbePayload = JSON.serialize(cbeList);
            }
            //call increment vendor chat count with future or Platform events
            if (!iVCCFuture && !iVCCPlatEvent) {
                //this is NOT test context as both flags are false
                if (!CDdCustomMetadata.isDisabled('CDdVendorSplitHelper_iVccF')
                    && String.isNotBlank(cbePayload) && !System.isFuture() && !System.isBatch()) {
                    incrementVendorChatCountFuture(cbePayload);
                } else if (!CDdCustomMetadata.isDisabled('CDdVendorSplitHelper_iVccPE')
                        && String.isNotBlank(cbePayload)) {
                    incrementVendorChatCountPE(cbePayload);
                }
            } else if (iVCCFuture && String.isNotBlank(cbePayload)) {
                //call future method in test context
                incrementVendorChatCountFuture(cbePayload);
            } else if (iVCCPlatEvent && String.isNotBlank(cbePayload)) {
                //call Platform event in test context
                incrementVendorChatCountPE(cbePayload);
            }
        }
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    increments vendor chat count in future context
    * @param         serialized payload
    * @return        None
    */
    @future
    public static void incrementVendorChatCountFuture(String inputPayload) {
        List<ChatButtonEntry> cbeList = (List<ChatButtonEntry>) System.JSON.deserialize(inputPayload, List<ChatButtonEntry>.class);
        updateVendorDistChatCount(cbeList);
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    increments vendor chat count using platform events
    * @param         serialized payload
    * @return        None
    */
    public static void incrementVendorChatCountPE(String chatButtonEntryList) {
        //process with platform events
        CDdCaseVendorSplitEventHelper.publishEvents(CDdCaseVendorSplitEventHelper.OperationType.INCREMENT_VENDOR_CC,null,chatButtonEntryList);
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    processes incoming case vendor split platform event to increment chat count
    * @param         list of case vendor split platform events
    * @return        None
    */
    public static void handleIncrementVendorCCPE(List<Case_Vendor_Split__e> cvsPEList) {
        List<ChatButtonEntry> cbeInnerList = new List<ChatButtonEntry>();
        List<ChatButtonEntry> cbeListOuter = new List<ChatButtonEntry>();
        for (Case_Vendor_Split__e cvsPEVar : cvsPEList) {
            if (String.isNotBlank(cvsPEVar.Payload__c)) {
                cbeInnerList = (List<ChatButtonEntry>) System.JSON.deserialize(cvsPEVar.Payload__c, List<ChatButtonEntry>.class);
                cbeListOuter.addAll(cbeInnerList);
            }
        }
        //call business method
        updateVendorDistChatCount(cbeListOuter);
    }

    /**
    * @author: Sahil
    * @date: 2021-08-03
    * @description Increments the chat count for the preferred vendor that got the chat.
    * @param         list of chat button entry wrapper class instance
    * @return        None
    */
    public static void updateVendorDistChatCount(List<ChatButtonEntry> cbeList) {
        try {
            if (!cbeList.isEmpty()) {
                // populate chat button map by looping through the input list
                Map<String, Map<String, Integer>> incVenChatCountMap = new Map<String, Map<String, Integer>>();
                for (ChatButtonEntry cbeVar : cbeList) {
                    incVenChatCountMap.put(cbeVar.chatButtonId, cbeVar.vendorDistributionMap);
                }
                // loop through inputs and add all vendors to the overall set
                Set<String> vendors = new Set<String>();
                for (String chatButtonAPIName : incVenChatCountMap.keySet()) {
                    vendors.addAll(incVenChatCountMap.get(chatButtonAPIName).keySet());
                }
                // lock all vendors that might need to be updated
                List<Vendor_Distribution__c> vendorDistributions =
                                                    [SELECT Id, Actual_Chat_Count__c, Vendor__c, Chat_Button_Distribution__c
                                                        FROM Vendor_Distribution__c
                                                        WHERE Chat_Button_Distribution__c IN :incVenChatCountMap.keySet()
                                                        AND Target_Distribution__c > 0
                                                        AND Vendor__c IN :vendors FOR UPDATE];
                // loop through locked records
                for (Vendor_Distribution__c vendorDistribution : vendorDistributions) {
                    // if vendor needs to be updated
                    String chatButtonId = vendorDistribution.Chat_Button_Distribution__c;
                    if (incVenChatCountMap.containsKey(chatButtonId) &&
                        incVenChatCountMap.get(chatButtonId).containsKey(vendorDistribution.Vendor__c)) {
                            vendorDistribution.Actual_Chat_Count__c +=
                                                incVenChatCountMap.get(chatButtonId).get(vendorDistribution.Vendor__c);
                    }
                }
                // update records
                List<Database.SaveResult> results = Database.update(vendorDistributions,false);
                CDdErrorUtilities.publishException('CDdVendorSplitHelper','updateVendorDistChatCount',results);
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdVendorSplitHelper','updateVendorDistChatCount',e);
        }
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    sets actual vendor on incoming cases
    * @param         list of cases
    * @return        None
    */
    public static void setActualVendor(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        try {
            Map<Case, CDdIssueBasedRoutingHelper.RoutingInfo> caseToRoutingInfoMap = new Map<Case, CDdIssueBasedRoutingHelper.RoutingInfo>();
            Set<String> chatButtonSet = new Set<String>();
            //build a map of agent users which will have the agent's email and company name
            Set<Id> ownerIdSet = new Set<Id>();
            Map<Id,User> agentDetailMap = new Map<Id,User>();
            List<Vendor_User_Mapping__mdt> vumList = Vendor_User_Mapping__mdt.getAll().values();
            String vendor;
            List<Case> casesTrueUpVendorList = new List<Case>();
            for (Case caseVar : newCaseList) {
                if (oldCaseMap.get(caseVar.Id).OwnerId.getSobjectType() == User.sObjectType) {
                    ownerIdSet.add(oldCaseMap.get(caseVar.Id).OwnerId);
                }
            }
            //query user database to get agent details
            if (!ownerIdSet.isEmpty()) {
                List<User> agentList = [SELECT Id,Email,CompanyName FROM User WHERE Id =:ownerIdSet];
                //now populate the user map
                for (User usrVar : agentList) {
                    agentDetailMap.put(usrVar.Id, usrVar);
                }
            }
            //compare the agent's email and company name against the database to find a matching vendor
            for (Case caseVar : newCaseList) {
                if (String.isBlank(caseVar.Actual_Vendor__c) && String.isNotBlank(caseVar.Preferred_Vendor__c)
                    && agentDetailMap.containsKey(oldCaseMap.get(caseVar.Id).OwnerId)
                    && !vumList.isEmpty()) {
                    for (Vendor_User_Mapping__mdt vendorUserMapping : vumList) {
                        String vumEmailDomainPrefixes = vendorUserMapping.Email_Domain_Prefixes__c == null ?
                                                        '' : vendorUserMapping.Email_Domain_Prefixes__c;
                        String vumCompanyName = vendorUserMapping.Company_Name__c == null ?
                                                '' : vendorUserMapping.Company_Name__c;
                        // split email domains and check against agent email
                        Boolean emailMatch = false;
                        for (String emailDomain : vumEmailDomainPrefixes.split(CDdCoreConstants.NEW_LINE)) {
                            if (String.isNotBlank(agentDetailMap.get(oldCaseMap.get(caseVar.Id).OwnerId).Email)) {
                                emailMatch =
                                    agentDetailMap.get(oldCaseMap.get(caseVar.Id).OwnerId).Email.containsIgnoreCase(CDdCoreConstants.DELIMITER_AT
                                                        + emailDomain.trim());
                            }
                            if (emailMatch) {
                                break;
                            }
                        }
                        // if user email or company name matches vendor user mapping values then select vendor
                        if (emailMatch ||
                            (String.isNotBlank(agentDetailMap.get(oldCaseMap.get(caseVar.Id).OwnerId).CompanyName)
                                && agentDetailMap.get(oldCaseMap.get(caseVar.Id).OwnerId).CompanyName.equalsIgnoreCase(vumCompanyName))) {
                            vendor = vendorUserMapping.MasterLabel;
                            break;
                        }
                    }
                    if (String.isNotBlank(vendor)) {
                        caseVar.Actual_vendor__c = vendor;
                        if (String.isNotBlank(caseVar.Routing_Destination__c)) {
                            chatButtonSet.add(caseVar.Routing_Destination__c);
                        }
                    }
                }
            }
            if (!chatButtonSet.isEmpty()) {
                Map<String, List<Chat_Button_Distribution__c>> chatButtonDistMap = getChatButtonToChatDist(chatButtonSet);
                if (!chatButtonDistMap.isEmpty()) {
                    trueUpVendorDistribution(newCaseList, chatButtonDistMap);
                }
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdVendorSplitHelper','setActualVendor',e);
        }
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    sets preferred vendor on incoming cases
    * @param         list of cases
    * @return        None
    */
    public static void trueUpVendorDistribution(List<Case > newCaseList,
                                                  Map<String, List<Chat_Button_Distribution__c>> chatButtonDistMap) {
        try {
            Map<String, Case> chatButtonToCaseMap = new Map<String, Case>();
            Chat_Button_Distribution__c chatButtonDist = null;
            List<VendorDistribution> vdList = new List<VendorDistribution>();
            for (Case caseVar : newCaseList) {
                if (String.isNotBlank(caseVar.Preferred_Vendor__c) && String.isNotBlank(caseVar.Actual_Vendor__c)) {
                    String chatButtonAPIName = caseVar.Routing_Destination__c;
                    if (chatButtonDistMap.containsKey(chatButtonAPIName)) {
                        List<Chat_Button_Distribution__c> chatButtonDistList = chatButtonDistMap.get(chatButtonAPIName);
                        if (!chatButtonDistList.isEmpty()) {
                            caseCreatedTime = caseCreatedTime == null ? caseVar.CreatedDate.time() : caseCreatedTime;
                            for (Chat_Button_Distribution__c cbd : chatButtonDistList) {
                                // default to distribution with no start/end
                                chatButtonDist = cbd.Start_Time__c == null ? cbd : chatButtonDist;
                                // if current time between start/end (break on first match)
                                if (cbd.Start_Time__c != null && caseCreatedTime >= cbd.Start_Time__c
                                    && cbd.End_Time__c != null && caseCreatedTime <= cbd.End_Time__c) {
                                    chatButtonDist = cbd;
                                    break;
                                }
                            }
                            //last reset should be before case creation date
                            if (chatButtonDist != null && (chatButtonDist.Last_Count_Reset__c == null
                                || chatButtonDist.Last_Count_Reset__c < caseVar.CreatedDate)) {
                                for (Vendor_Distribution__c vd : chatButtonDist.Vendor_Distributions__r) {
                                    if (!caseVar.Actual_Vendor__c.equalsIgnoreCase(caseVar.Preferred_Vendor__c)) {
                                        if (vd.Vendor__c == caseVar.Actual_Vendor__c || vd.Vendor__c == caseVar.Preferred_Vendor__c) {
                                            // default chat count to zero
                                            vd.Actual_Chat_Count__c = vd.Actual_Chat_Count__c == null ? 0 : vd.Actual_Chat_Count__c;
                                            // if actual vendor then increment chat count, otherwise decrement it
                                            // preferred vendor got count incremented when chat was created, now
                                            // that another vendor took the chat we are truing up the count
                                            vd.Actual_Chat_Count__c += vd.Vendor__c.equalsIgnoreCase(caseVar.Actual_Vendor__c) ? 1 : -1;
                                            VendorDistribution vdObj = new VendorDistribution(vd.Id,(Integer)vd.Actual_Chat_Count__c);
                                            vdList.add(vdObj);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            String vdPayload;
            if (!vdList.isEmpty()) {
                vdPayload = JSON.serialize(vdList);
            }
            //true up vendor distribution with future or platform events
            if (!tUVDFuture && !tUVDPlatEvent) {
                //this is NOT test context as both flags are false
                if (!CDdCustomMetadata.isDisabled('CDdVendorSplitHelper_tUVDF')
                    && String.isNotBlank(vdPayload) && !System.isFuture() && !System.isBatch()) {
                    updateVendorDistributionFuture(vdPayload);
                } else if (!CDdCustomMetadata.isDisabled('CDdVendorSplitHelper_tUVDPE')
                        && String.isNotBlank(vdPayload)) {
                    updateVendorDistributionPE(vdPayload);
                }
            } else if (tUVDFuture && String.isNotBlank(vdPayload)) {
                //call future method in test context
                updateVendorDistributionFuture(vdPayload);
            }  else if (tUVDPlatEvent && String.isNotBlank(vdPayload)) {
                //call platform event in test context
                updateVendorDistributionPE(vdPayload);
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdVendorSplitHelper','trueUpVendorDistribution',e);
        }
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    updates vendor distributions in future context
    * @param         serialized payload
    * @return        None
    */
    @future
    public static void updateVendorDistributionFuture(String vdPayload) {
        List<VendorDistribution> vdList = (List<VendorDistribution>) System.JSON.deserialize(vdPayload, List<VendorDistribution>.class);
        updateVendorDistribution(vdList);
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    updates vendor distributions with platform events
    * @param         serialized payload
    * @return        None
    */
    public static void updateVendorDistributionPE(String vdPayload) {
        CDdCaseVendorSplitEventHelper.publishEvents(CDdCaseVendorSplitEventHelper.OperationType.TRUE_UP_VD, null, vdPayload);
    }

      /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    updates vendor distribution records in the database
    * @param         list of vendor distribution wrapper class instance
    * @return        None
    */
    public static void updateVendorDistribution(List<VendorDistribution> vdList) {
        if (!vdList.isEmpty()) {
            try {
                Map<String,VendorDistribution> vdUpdateMap = new Map<String,VendorDistribution>();
                for (VendorDistribution vdVar : vdList) {
                    vdUpdateMap.put(vdVar.vendorDistId,vdVar);
                }
                if (!vdUpdateMap.isEmpty()) {
                    //to avoid race condition, lock the vendor distribution records which need to be updated
                    List<Vendor_Distribution__c> vDistListDB = [SELECT Id,Actual_Chat_Count__c
                                                                FROM Vendor_Distribution__c
                                                                WHERE Id IN :vdUpdateMap.keySet()
                                                                FOR UPDATE];
                    for (Vendor_Distribution__c vdObj : vDistListDB) {
                        if (vdUpdateMap.containsKey(vdObj.Id)) {
                            vdObj.Actual_Chat_Count__c = vdUpdateMap.get(vdObj.Id).actualChatCount;
                        }
                    }
                    if (!vDistListDB.isEmpty()) {
                        List<Database.SaveResult> results = Database.update(vDistListDB,false);
                        CDdErrorUtilities.publishException('CDdVendorSplitHelper','updateVendorDistribution',results);
                    }
                }
            } catch (Exception e) {
                CDdErrorUtilities.publishException('CDdVendorSplitHelper','updateVendorDistribution',e);
            }
        }
    }

    /**
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    processes incoming case vendor split platform event to update vendor distributions
    * @param         list of case vendor split platform events
    * @return        None
    */
    public static void handleUpdateVendorDistribution(List<Case_Vendor_Split__e> cvsPEList) {
        List<VendorDistribution> vdListInner = new List<VendorDistribution>();
        List<VendorDistribution> vdListOuter = new List<VendorDistribution>();
        Map<String,Integer> vdIdToActChatCountMap = new Map<String,Integer>();
        for (Case_Vendor_Split__e cvsPEVar : cvsPEList) {
            if (String.isNotBlank(cvsPEVar.Payload__c)) {
                vdListInner = (List<VendorDistribution>) System.JSON.deserialize(cvsPEVar.Payload__c, List<VendorDistribution>.class);
                vdListOuter.addAll(vdListInner);
            }
        }
        updateVendorDistribution(vdListOuter);
    }

     /**
     * @author Nayana
     * @date: 2021-09
     * @description this method is used to assign routing reason and owner as overflowQueue queue
     * @jira BIZS-439
     */
    private void assignFinalOwner(Case caseRec) {
        CDdSupportOwnerAssignment.OwnerRoutingInfo oInfo =cSupportAssignment.findFinalOwner(caseRec.ownerId);
        Id originalQId = caseRec.ownerId;
        caseRec.Routing_Reason__c = oInfo.routingReason;
        caseRec.OwnerId = oInfo.ownerId;
    }

    // custom class for serialization
    public class ChatButtonEntry {
        public String chatButtonId { get; set; }
        public Map<String, Integer> vendorDistributionMap { get; set; }
        public ChatButtonEntry() {
            vendorDistributionMap = new Map<String, Integer>();
        }
    }

    public class VendorDistribution {
        String vendorDistId;
        Integer actualChatCount;

        public VendorDistribution(String vdId, Integer cc) {
            vendorDistId = vdId;
            actualChatCount = cc;
        }
    }

    public class CDdVendorSplitHelperException extends Exception {}
}