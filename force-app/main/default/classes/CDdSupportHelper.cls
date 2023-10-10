/**
 *
 * @author: Tia Xuan
 * @date: 2021-03
 * @description Helper methods for Support
 *
 */
public class CDdSupportHelper {
    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    private static List<Support_Assignment_Mapping__c> supAssignmentList = Support_Assignment_Mapping__c.getAll().values();
    private static List<Support_Assignment_Mapping__c> supMappingByObjList = new List<Support_Assignment_Mapping__c>();
    private static List<Customer_Segment_Mapping__c> lstCustomerSegSetting = Customer_Segment_Mapping__c.getall().values();
    public static List<Sendbird_Chat_Queue__mdt> sbChatQueues = Sendbird_Chat_Queue__mdt.getAll().values();
    public static final String CLASS_INFO = 'Class Name: CDdSupportHelper';
    public static final String QUEUE_BUSINESS_HOURS_VALIDATION_MTHD  = 'queueBusinessHoursValidation';
    public static Map<String, Queue_Mapping__c> queueMappingMap = new Map<String, Queue_Mapping__c>();
    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
    public static Country_Mapping__c getCountryMapping(String isoName){
        Map<String, Country_Mapping__c> countryMap = Country_Mapping__c.getAll();
        Country_Mapping__c cm = new Country_Mapping__c();
        cm.Country__c = 'United States';
        cm.Language__c = 'English';

        if (countryMap.containsKey(isoName)){
            return countryMap.get(isoName);
        } else {
            return cm;
        }
    }


    /**
     * @author      Jeegar
     * @date:       2021-03
     * @description Helper method for sendbird Chat events
     * @params Case newCase, Case oldCase
     * @return Sendbird_Chat_Event__e
     */
    public static Sendbird_Chat_Event__e createSendbirdEvent(Case newCase, Case oldCase) {
        return createSendbirdEvent(new SendBirdChatEventWrapper(newCase,oldCase,findIfRealTime(String.valueOf(newCase.OwnerId))));
    }

     /**
     * @author      Nayana
     * @date:       2022-03
     * @description Helper method to check if new owner is realtime queue
     * @params    new case ownerId
     * @return Boolean
     */
    public static Boolean findIfRealTime(String newCaseOwnerId){
        Boolean isRealtime = false;
        if(String.isNotBlank(newCaseOwnerId)){
            for (Sendbird_Chat_Queue__mdt sbCQVar : sbChatQueues) {
                if (sbCQVar.Queue_ID__c == newCaseOwnerId && sbCQVar.Real_Time__c) {
                    //case owner is a real time queue - set flag and break
                    isRealtime = true;
                    break;
                }
            }
        }
        return isRealtime;
    }
     /**
     * @author      Jeegar
     * @date:       2021-03
     * @description Helper method for sendbird Chat events
     * @params SendBirdChatEventWrapper
     * @return Sendbird_Chat_Event__e
     */
    public static Sendbird_Chat_Event__e createSendbirdEvent(SendBirdChatEventWrapper sEventWrap) {
        Sendbird_Chat_Event__e chatEvent = new Sendbird_Chat_Event__e();
        chatEvent.Case_Id__c = sEventWrap.caseId;
        chatEvent.Chat_Key__c = sEventWrap.chatKey;
        chatEvent.Case_Owner_Id__c = sEventWrap.ownerId;
        chatEvent.Case_Status__c = sEventWrap.status;
        chatEvent.Agent_First_Name__c = sEventWrap.AgentFirstName;
        chatEvent.Case_Previous_Owner_Id__c = sEventWrap.prevOwnerId;
        chatEvent.Case_Previous_Status__c = sEventWrap.prevStatus;
        chatEvent.Chat_Escalation_Id__c = sEventWrap.chatEscalationId;
        chatEvent.New_Owner_Realtime__c = sEventWrap.isRealtime;
        chatEvent.Case_Origin__c = sEventWrap.caseOrigin;
        return chatEvent;
    }

     /**
     * @author      Nayana
     * @date:       2022-03
     * @description Helper method for sendbird Mulesoft Chat events
     * @params SendBirdChatEventWrapper
     * @return Sendbird_Mulesoft_Chat_Event__e
     */
    public static Sendbird_Mulesoft_Chat_Event__e createSendbirdMulesoftChatEvent(SendBirdChatEventWrapper sEventWrap) {
        Sendbird_Mulesoft_Chat_Event__e chatEvent = new Sendbird_Mulesoft_Chat_Event__e();
        chatEvent.Case_Id__c = sEventWrap.caseId;
        chatEvent.Chat_Key__c = sEventWrap.chatKey;
        chatEvent.Case_Owner_Id__c = sEventWrap.ownerId;
        chatEvent.Case_Status__c = sEventWrap.status;
        chatEvent.Agent_First_Name__c = sEventWrap.AgentFirstName;
        chatEvent.Case_Previous_Owner_Id__c = sEventWrap.prevOwnerId;
        chatEvent.Case_Previous_Status__c = sEventWrap.prevStatus;
        chatEvent.Chat_Escalation_Id__c = sEventWrap.chatEscalationId;
        chatEvent.New_Owner_Realtime__c = sEventWrap.isRealtime;
        return chatEvent;
    }

    /**
     * @author Dinesh Annapareddy
     * @date   2021-08
     * @description get the Custom Metadata records based on Object
     */
    public static list<Support_Assignment_Mapping__c> getSupportAssignmentRecordsByObject(String objectName)
    {
        List<Support_Assignment_Mapping__c> returnSAList = new List<Support_Assignment_Mapping__c>();
        for(Support_Assignment_Mapping__c supportAssignment:Support_Assignment_Mapping__c.getAll().values())
        {
            if(supportAssignment.Object__c == objectName )
            {
                returnSAList.add(supportAssignment);
            }
        }

        return returnSAList;
    }

    /**
     * @author      Sahil
     * @date:       2021-08
     * @description get Id of the queue from custom settings based on destination and obj name
     * @params      routing destination, object name
     * @return      queue id
     */
    public static String getIdByRoutingDestination(String destination, List<Support_Assignment_Mapping__c> supportMappings) {
        if (!supportMappings.isEmpty() && String.isNotBlank(destination)) {
            for (Support_Assignment_Mapping__c saMapVar : supportMappings) {
                if (destination == saMapVar.Support_Assignment_Name__c) {
                    return saMapVar.Queue_Id__c;
                }
            }
        }
        return null;
    }

    /**
     * @author      Sahil
     * @date:       2021-09
     * @description get a list custom setting records(support assignment mapping) by object
     * @params      object name
     * @return      list custom setting records
    */
    public static List<Support_Assignment_Mapping__c> getObjToSupAssignList(String objectName) {
        //check if list is already populated in the transaction and return
        if (!supMappingByObjList.isEmpty()) {
            return supMappingByObjList;
        } else {
            //populate list from database and return
            if (!supAssignmentList.isEmpty() && String.isNotBlank(objectName)) {
                for (Support_Assignment_Mapping__c sAMVar : supAssignmentList) {
                    if (sAMVar.Object__c == objectName) {
                        supMappingByObjList.add(sAMVar);
                    }
                }
            }
            return supMappingByObjList;
        }
    }


     /**
     * @author: Nayana
     * @date: 2021-10-18
     * @description Get the customer Segment Mapping
    */
    public static Map<Integer,String> mapCustomerSegmentmapping{
        get{
            if(mapCustomerSegmentmapping == null){
                mapCustomerSegmentmapping = new Map<Integer,String>();
                for(Customer_Segment_Mapping__c cSeg: lstCustomerSegSetting){
                    if(cSeg.Audience_Attribute_Number__c!=null && String.isNotBlank(cSeg.Customer_Segment__c) && cSeg.Is_Active__c){
                        mapCustomerSegmentmapping.put(Integer.valueOf(cSeg.Audience_Attribute_Number__c), cSeg.Customer_Segment__c);
                    }
                }
            }
            return mapCustomerSegmentmapping;
        }
        set;
    }

    /**
     * @author: Nayana
     * @date: 2021-10-18
     * @description Get the List of Audience attribute number which are enabled for Experiment
    */
    public static List<Integer> lstVipNumbers{
        get{
            if(lstVipNumbers == null){
                lstVipNumbers = new List<Integer>();
                for(Customer_Segment_Mapping__c cSeg: lstCustomerSegSetting){
                    if(cSeg.Audience_Attribute_Number__c!=null && cSeg.Is_VIP__c && cSeg.Is_Active__c){
                        lstVipNumbers.add(Integer.valueOf(cSeg.Audience_Attribute_Number__c));
                    }
                }
            }
            return lstVipNumbers;
        }
        set;
    }

     /**
     * @author: Nayana
     * @date: 2022-03
     * @description Wrapper for SendBird/Sendbird Mulesoft chat PE
     *
    */

    public class SendBirdChatEventWrapper{
        public Id caseId;
        public String chatKey;
        public String ownerId;
        public String prevOwnerId;
        public String status;
        public String prevStatus;
        public String AgentFirstName;
        public String chatEscalationId;
        public String caseOrigin;
        public Boolean isRealtime;
        public SendBirdChatEventWrapper(){

        }
        public SendBirdChatEventWrapper(Case newCase,Case oldCase,Boolean realTime){
            caseId = newCase.id;
            chatKey = newCase.ChatKey__c;
            ownerId = String.valueOf(newCase.OwnerId);
            status= newCase.Status;
            AgentFirstName = newCase.Owner.FirstName;
            chatEscalationId = newCase.Chat_Escalation_Id__c;
            caseOrigin = newCase.Origin;
            isRealtime = realTime;
            if(oldCase != null) {
                prevStatus = oldCase.Status;
                prevOwnerId = String.valueOf(oldCase.OwnerId);
            }
        }
    }

    /**
     * @author: RajV
     * @date: 2022-05-18
     * @description Send the list of queues within the business hours
    */

    public static List<Sendbird_Chat_Queue__mdt> queueBusinessHoursValidation(list<Sendbird_Chat_Queue__mdt> queueList){

        List<Sendbird_Chat_Queue__mdt> finalist=new List<Sendbird_Chat_Queue__mdt>();
        try{
            for(Sendbird_Chat_Queue__mdt sc:queueList){
                If(String.isNotBlank(sc.Business_Hours_Id__c)){
                if(BusinessHours.isWithin(sc.Business_Hours_Id__c, Datetime.now())) finalist.add(sc);
                }else{
                    finalist.add(sc);
                }
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, CLASS_INFO, QUEUE_BUSINESS_HOURS_VALIDATION_MTHD, LoggingLevel.ERROR);
        }
        return finalist;
    }

    /**
     * @author: Mahesh Chouhan
     * @date: April 2023
     * @description Check if Queue is Live or Non-Live Queue
    */
    public static Boolean isLiveQueue(String queueId){
        if(queueMappingMap.isEmpty()){
            List<Queue_Mapping__c> queueMappings = [SELECT Id, Is_Live_Queue__c, Queue_Id__c
                                                    FROM Queue_Mapping__c
                                                    WHERE Queue_Usage__c = 'Active'];
            for(Queue_Mapping__c qMapping : queueMappings){
                queueMappingMap.put(qMapping.Queue_Id__c, qMapping);
            }
        }
        return queueMappingMap.containsKey(queueId) && queueMappingMap.get(queueId).Is_Live_Queue__c;
    }

     /**
     * @author: Sugan
     * @date: 2023-05
     * @description A helper method to check if a case has live order issue and issue category values,
     * the values are stored in an custom mdt and fetched using a query (as getInstance only provides 255 characters)
     * - we also store the retrieved values in the org cache for 6 hours to improve performance
     *
    */
    private static final String SITE_CONFIGS = 'local.DoorDash.siteEscConfigs';
    public static Boolean isLiveOrderIssue(Case caseRec){
        String cacheKey = SITE_CONFIGS+'liveOrderValues';
        Map<String,String> liveOrderMap = new Map<String,String>();
        try {
            liveOrderMap = (Map<String,String>)CDdCacheService.getFromOrgCache(cacheKey);
            if(liveOrderMap==null || liveOrderMap.isEmpty()){
                //query the live order details and store it in org cache if not already present in the cache
                List<Live_Order_Issue__mdt> liveOrderIssue =[Select Issue__c, Issue_Type__c,Time_in_seconds_to_store_in_Cache__c from Live_Order_Issue__mdt where developername = :CDdSupportConstants.LIVE_ORDER_ISSUES_MDT_NAME];
                if(!liveOrderIssue.isEmpty()){
                    liveOrderMap = new Map<String,String>{'Issue_Type__c' => liveOrderIssue[0].Issue_Type__c,'Issue__c' =>liveOrderIssue[0].Issue__c};
                    CDdCacheService.putInOrgCache(cacheKey, liveOrderMap,Integer.valueOf(liveOrderIssue[0].Time_in_seconds_to_store_in_Cache__c)); //store the live order values in the org cache for 1 hour - we are putting it as a shorter time window
                }
            }
        }catch (Exception e) {
            List<String> errorMessages = new List<String>();
            errorMessages.add(CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e));
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdSupportHelper', 'retrieveLiveOrderIssues', LoggingLevel.ERROR);
        }

        String liveOrderIssueType =  liveOrderMap.containsKey('Issue_Type__c') ? liveOrderMap.get('Issue_Type__c') : '';
        String liveOrderIssue = liveOrderMap.containsKey('Issue__c') ? liveOrderMap.get('Issue__c') : '';

        return liveOrderIssueType.contains(caseRec.Issue_Type__c) && liveOrderIssue.contains(caseRec.Issue__c);
    }


    /**
     * @author: Nayana
     * @date: July 2023
     * @description Get the List of queues which are used by Vendor Split
    */
    public static List<String> lstCaseVendorQueueDevName{
        get{
            if(lstCaseVendorQueueDevName == null){
                lstCaseVendorQueueDevName = new List<String>();
                for(Routing_Configuration__mdt rConfig: [SELECT Owner_Queue_Name__c FROM
                                                        Routing_Configuration__mdt WHERE Object_API_Name__c='Case'
                                                        AND Is_Active__c = TRUE AND Do_Vendor_Split__c = true]){
                    if(String.isNotBlank(rConfig.Owner_Queue_Name__c)){
                        Map<String,Object> mapFieldValue = (Map<String,Object>) JSON.deserializeUntyped(rConfig.Owner_Queue_Name__c);
                        for(String vendorName : mapFieldValue.keySet()){
                            String vendoQDevName = String.valueOf(mapFieldValue.get(vendorName));
                            lstCaseVendorQueueDevName.add(vendoQDevName);
                        }
                    }
                }
            }
            return lstCaseVendorQueueDevName;
        }
        set;
    }

}