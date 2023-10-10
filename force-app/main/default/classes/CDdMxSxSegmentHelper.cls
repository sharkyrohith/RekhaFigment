/********************************************************************************************************************
* @author Ebenezer
* @date 11/23/2021
*
* @group Merchant Services
*
* @description --Classes uses three collections -  segmentRequests, segmentRequestEvents, logIds
*              segmentRequests - This collection is used to send Data to segment directly (point-to-point)
*              segmentRequestEvents - This is used to publish platform Events
*              logIds - Collection is used to create/update segment logs based on if the log is being created (from trigger) or updated (from batch)
*              --Based on the value of CDdMxSxSegmentConstants.ISEXECUTIONINBATCHCONTEXT, DML operation is either performed in the same class or just the 
*              collections are populated and the calling method will perform the updates  
**************************************************************************************************************************************/
public class CDdMxSxSegmentHelper {
    
    public class CDdMxSxSegmentRequest{
        public String anonymousId{get;set;}
        public String type{get;set;}
        public String event{get;set;}
        public Map<String, Object> properties{get;set;}
        public String timeStamp{get;set;}
        public CDdMxSxSegmentRequest(){}
        public CDdMxSxSegmentRequest(String anonymousId, String type, String event, Map<String, Object> properties, String timeStamp){
            this.anonymousId = anonymousId;
            this.type = type;
            this.event = event;
            this.properties = properties;
            this.timeStamp = timeStamp;
        }
    }

    private Map<Id, Segment_Event__e> segmentEvents{get;set;}
    private Map<String, List<Segment_Properties__mdt>> segmentEventProperties{get;set;}
    public Map<String, Segment_Logs__c> logIds{get;set;}
    public Map<String, CDdMxSxSegmentRequest> segmentRequests{get;set;}
    public Map<String, CDdMxSxSegmentRequest> segmentRequestEvents{get;set;}
    @testVisible Map<String,Segment__mdt> segmentMetadataMap{get;set;}

    private static final String CLASSNAME = 'CDdMxSxSegmentHelper';
    private static Boolean SEND_SEGMENT_EVENT_ONLY_ONCE;
    /** 
     * @description Default constructor
     * @param 
     */
    public CDdMxSxSegmentHelper(){
        this.setClassAttributes();
        logIds = new Map<String, Segment_Logs__c>();
    }
    /** 
     * @description Single argument constructor
     * @param Map<String, Segment_Logs__c> logIds - Collection of Segment log Ids
     */
    public CDdMxSxSegmentHelper(Map<String, Segment_Logs__c> logIds){
        this.setClassAttributes();
        this.logIds = logIds;
    }
     /** 
     * @description Initialize class variables, called from constructor
     * @param 
     */
    private void setClassAttributes(){
        segmentEvents = new Map<Id, Segment_Event__e>();
        segmentRequests = new Map<String, CDdMxSxSegmentRequest>();
        segmentRequestEvents = new Map<String, CDdMxSxSegmentRequest>();
        segmentEventProperties = new Map<String, List<Segment_Properties__mdt>>();
        segmentMetadataMap = new Map<String,Segment__mdt>();
    }

    /**
     * @description Categorizes the sObjectIds received, and groups them into different collections for processing as platform Events or through API
     *              - Populates the three collections (segmentRequests, segmentRequestEvents, logIds) and either will publish the platform Event or 
     *                makes the Post to Segment directly 
     * @param Set<Id> sObjectIds List of record Ids (of any Object) for which the Event is published
     * @param String eventName  Name of the event
     * @return 
     */
    public void handleSegmentEvents(Set<Id> sObjectIds, String eventName) {
        if(!CDdMxSxSegmentConstants.ENABLE_SEGMENT_FRAMEWORK){
            return;
        }
        Segment__mdt segmentMetadata = querySegmentRequestDetails(eventName).get(eventName);
        if(segmentMetadata == null || !segmentMetadata.Is_Active__c){
            return;
        }
        SEND_SEGMENT_EVENT_ONLY_ONCE = segmentMetadata.Send_Only_Once__c;
        sObjectIds = filterSobjectIdsToSendNotification(sObjectIds, eventName);


        Map<String, String> payLoad = new Map<String, String>();
        Map<String, String> segmentEventQuery = new Map<String, String>();
        try{
            payLoad = getPropertyAPINames(segmentMetadata.Segment_Properties__r, segmentMetadata.Event_Name__c);
            segmentEventQuery.put(segmentMetadata.Event_Name__c, getPayloadQuery(segmentMetadata.SObject_Type__c, payLoad.values(), sObjectIds)) ;
            segmentEventProperties.put(eventName, segmentMetadata.Segment_Properties__r);

            generatePayload(eventName, 
                            segmentEventQuery.get(eventName), 
                            segmentEventProperties.get(eventName), 
                            sObjectIds); //This method updates the collections segmentRequestEvents/segmentRequests based on the flags and status of the log records, either to publish an PE or send directly to segment
            //Exclude the DML's in batchContext, will be done in batch class (caller) after API call
            if(!CDdMxSxSegmentConstants.ISEXECUTIONINBATCHCONTEXT){ 
                generateSegmentLogs(CDdMxSxSegmentConstants.ISEXECUTIONINTRIGGERCONTEXT || !CDdMxSxSegmentConstants.PUBLISH_EVENTS_TO_SEGMENT);
                if(!segmentRequestEvents.isEmpty()){
                    createSegmentEvents();
                }
            }
            //Check if segmentRequests is not empty and 
            if(!segmentRequests.isEmpty() && (!CDdMxSxSegmentConstants.ISEXECUTIONINTRIGGERCONTEXT || Test.isRunningTest())){
                handleAPICall();
            }    
        }
        catch(Exception e){
            insert CDdMxSxException.createErrorLog(CDdMxSxSegmentHelper.CLASSNAME, 'handleSegmentEvents', eventName, Logginglevel.ERROR, 'Milestone__c,',  null, e.getStackTraceString() + ' '+ e.getMessage());
        }
    }
    /**
     * @description Query the Segment settings/payload for the Event
     * @param String eventName EventName for which the Settings have to be queried
     * @return List<Segment__mdt>
     */
    @TestVisible
    private Map<String,Segment__mdt> querySegmentRequestDetails(String eventName){
        if (segmentMetadataMap == null || !segmentMetadataMap.containsKey(eventName)) {
            List<Segment__mdt> segmentRecords = [Select id, Event_Name__c, SObject_Type__c, Send_Only_Once__c, Is_Active__c, 
               (Select Id, Key__c, Value__c, Type__c, Data_Type__c from Segment_Properties__r) 
               from Segment__mdt where Event_Name__c =:eventName];
               if(!segmentRecords.isEmpty()){
                    segmentMetadataMap.put(eventName, segmentRecords[0]);
               }
        }
        return segmentMetadataMap;
    }
    /**
     * @description Query the Segment settings/payload for the Event
     * @param String eventName EventName for which the Settings have to be queried
     * @return List<Segment__mdt>
     */
    public void createSegmentEvents(){
         for(String key : segmentRequestEvents.keySet()){
            segmentEvents.put(key, new Segment_Event__e(SObject_Id__c=key, Payload__c=JSON.Serialize(segmentRequestEvents.get(key)), Segment_Log_Id__c=logIds.get(key).Id));
         }
         insertSegmentEvents();
    }
    /**
     * @description Performs the DML to publish the segment events to Mulesoft and updates segment logs on the status of Platform Events published
     * @param 
     * @return 
     */
    private void insertSegmentEvents(){
        if(segmentEvents.isEmpty()){
            return;
        }
        List<Segment_Logs__c> eventLogs = new  List<Segment_Logs__c>();   
        List<Database.saveResult> results = EventBus.publish(segmentEvents.values());    
        for(Integer i=0;i<results.Size();i++){
            logIds.get(segmentEvents.values()[i].SObject_Id__c).status__c = CDdMxSxSegmentConstants.SEGMENT_EVENT_FAILED_STATUS ;
            
            if(!results[i].isSuccess() && results[i].getErrors() != null && !results[i].getErrors().isEmpty()){
                logIds.get(segmentEvents.values()[i].SObject_Id__c).status__c = CDdMxSxSegmentConstants.SEGMENT_EVENT_FAILED_STATUS ;
            }else {
                logIds.get(segmentEvents.values()[i].SObject_Id__c).status__c = CDdMxSxSegmentConstants.SEGMENT_EVENT_PUBLISHED_STATUS ;
            }
            logIds.get(segmentEvents.values()[i].SObject_Id__c).Retry_Count__c = (logIds.get(segmentEvents.values()[i].SObject_Id__c).Retry_Count__c != null)?(logIds.get(segmentEvents.values()[i].SObject_Id__c).Retry_Count__c + 1):1  ;
            eventLogs.add(logIds.get(segmentEvents.values()[i].SObject_Id__c));
        } 
        if(!eventLogs.isEmpty()){
            Database.update(eventLogs, false);
        }  
    }
    /**
     * @description inserts a segment log Object for every event to be created so that it can be sent to Mulesoft
     * @param 
     * @return 
     */
    private void generateSegmentLogs(Boolean insertLogs){
        Map<Id, Segment_Logs__c> segmentLogs = new Map<Id, Segment_Logs__c>();
        for(String i :segmentRequestEvents.keySet()){
            if(!logIds.containsKey(i)){
                segmentLogs.put(i, new Segment_Logs__c(sObject_Id__c = i, Event__c = segmentRequestEvents.get(i).event, status__c = CDdMxSxSegmentConstants.SEGMENT_EVENT_REQUEST_COMPLETE, Request_Payload__c = JSON.Serialize(segmentRequestEvents.get(i)))); 
            }
        }
        for(String i :segmentRequests.keySet()){
            if(!logIds.containsKey(i)){
                segmentLogs.put(i, new Segment_Logs__c(sObject_Id__c = i, Event__c = segmentRequests.get(i).event, status__c = CDdMxSxSegmentConstants.SEGMENT_EVENT_REQUEST_COMPLETE, Request_Payload__c = JSON.Serialize(segmentRequests.get(i)))); 
            }
        }
        if(segmentLogs.isEmpty()){
            return;
        }
        if(insertLogs){
            Database.insert(segmentLogs.values());
        }
        for(String i : segmentLogs.keySet()){
            logIds.put(i, segmentLogs.get(i));
        }
    }
    /**
     * @description Prepares the key, value pair of the metadata from Segment_Properties__mdt 
     * @param 
     * @return 
     */
    private Map<String, String> getPropertyAPINames(List<Segment_Properties__mdt> segmentData, String eventName){
        if(segmentData == null || segmentData.isEmpty()){
            return null ;
        }
        Map<String, String> payLoad = new Map<String, String>();
        for(Segment_Properties__mdt sP : segmentData){
            if(!CDdMxSxSegmentConstants.STATICPROPERTYTYPE.equalsIgnoreCase(sP.Type__c)){
                payLoad.put(sP.Key__c, sP.Value__c);
            }
        }
        return payLoad ;
    }
    /**
     * @description Prepares the key, value pair of the metadata from Segment_Properties__mdt 
     * @param String sObjectType
     * @param List<String> fieldAPIs
     * @param Set<Id> sObjectIds
     * @return String query
     */
    private String getPayloadQuery(String sObjectType, List<String> fieldAPIs, Set<Id> sObjectIds){
        String query = '';
        query = 'Select Id, '+ String.Join(fieldAPIs, ', ') + ' from ' + 
                 sObjectType+ ' where Id IN :sObjectIds' ;
        return query;
    }
    /**
     * @description Extracts the field value from the Api field name
     * @param String fieldAPI
     * @param sObject obj
     * @return String value
     */
    private Object getFieldValue(String fieldAPI, sObject obj){
        Object value = '';
        List<String> fieldAPIs = fieldAPI.split('\\.');    
        if(!fieldAPIs.isEmpty()){
            for(Integer i = 0; i<fieldAPIs.Size(); i++){
                if(obj != null){
                    if( i == (fieldAPIs.Size() - 1)){
                        value = obj.get(fieldAPIs[i]);
                    }else{
                        obj = (sObject)obj.getSobject(fieldAPIs[i]);
                    } 
                }
           } 
        }
        return value ;
    }
    /**
     * @description Generates the Key, value pair of the payload with the data/substitutes field API name with teh actual value 
     * @param String query
     * @param List<Segment_Properties__mdt> segmentEventProperties
     * @param Set<Id> sObjectIds
     * @return 
     */
    private void generatePayload(String eventName, String query, List<Segment_Properties__mdt> segmentEventProperties, Set<Id> sObjectIds){
        Map<String, Object> payLoad = new Map<String, String>();
        CDdMxSxSegmentRequest request = new CDdMxSxSegmentRequest();
        for(sObject obj : Database.Query(query)){
            payLoad = populateProperties(segmentEventProperties, obj);
            request = new CDdMxSxSegmentRequest(CDdMxSxSegmentConstants.USER_ID,
                                                CDdMxSxSegmentConstants.SEGMENT_TRACK_EVENT,
                                                eventName,
                                                payLoad,
                                                System.Now().format(CDdMxSxSegmentConstants.TIMEFORMAT, CDdMxSxSegmentConstants.TIMESTAMPZONE));
            if(CDdMxSxSegmentConstants.PUBLISH_EVENTS_TO_SEGMENT ||  
               (logIds.containsKey(obj.Id) && logIds.get(obj.Id).Retry_Count__c >= CDdMxSxSegmentConstants.SEGMENT_MAXIMUM_RETRY_EVENTS_COUNT)){
                segmentRequests.put(obj.Id, request);
            }else{
                segmentRequestEvents.put(obj.Id, request);
            }
        }
    }
    /**
     * @description Generates the Key, value pair of the payload with the data/substitutes field API name with teh actual value 
     * @param List<Segment_Properties__mdt> segmentEventProperties
     * @param sObject obj
     * @return Map<String, String> payLoadValues
     */
    private Map<String, Object> populateProperties(List<Segment_Properties__mdt> segmentEventProperties, sObject obj){
        Map<String, Object> properties = new Map<String, Object>();
        properties.put(CDdMxSxSegmentConstants.UUIDKEY, String.valueOf(getUUID()));
        for(Segment_Properties__mdt sP : segmentEventProperties){
            if(CDdMxSxSegmentConstants.STATICPROPERTYTYPE.EqualsIgnoreCase(sp.Type__c)){
                properties.put(sP.key__c, String.isBlank(sp.Value__c)?'':getStaticPropertyValue(sP.Value__c, sP.Data_Type__c));
            }else{
                Object value = getFieldValue(sp.Value__c, obj);
                properties.put(sP.key__c, value == null?'':value);
            }
        }
        return properties;
    }
    /**
     * @description Generates a randomn sequence of alpha-numeric ID. 
     * @param 
     * @return String uuid
     */
    public String getUUID(){
        Blob blbKey = Crypto.GenerateAESKey(128);
        String hexKey = EncodingUtil.ConvertTohex(blbKey);
        String uuid = hexKey.SubString(0,8)+ '-' + hexKey.SubString(8,12) + '-' + hexKey.SubString(12,16) + '-' + 
                      hexKey.SubString(16,20) + '-' + hexKey.substring(20);
        return uuid;
    }
    /**
     * @description returns the static data for property in respective datatype to insert into the map
     * @param String data (from value of metadata property)
     * @param String dataType
     * @return Object (in repective dataType)
     */
    public Object getStaticPropertyValue(String data, String dataType){
        switch on dataType {
            when 'Integer' {
                return Integer.valueOf(data);
            }
            when 'String' {
                return String.valueOf(data);
            }
            when 'Decimal' {
                return Decimal.valueOf(data);
            }
            when 'Boolean' {
                return Boolean.valueOf(data);
            }
            when 'Datetime' {
                return Datetime.valueOf(data);
            }
            when else {
                return data;
            }
        }
    }
    /**
     * @description returns the instance of the class overwritten to fetch the valid sObject Ids from batch 
     * @param String className
     * @return CDdMxSxSegmentConditionsHandler Type Instance
     */
    public static CDdMxSxSegmentConditionsHandler getClassInstance(String className){
        return (CDdMxSxSegmentConditionsHandler)Type.forName(className).newInstance();
    }

    /**
     * @description Process the API response and updates the corresponding segment log records (LogIds collection) for Non Batch Context
     * @param HttpResponse response httpresponse of the segment API call
     * @param Boolean insertLogs - used to determine if logs should be inserted at this point, if false is passed just the collection is updated and 
     *                             the caller has to perform DML
     * @return 
    */
    private void processAPIResponse(HttpResponse response, Boolean insertLogs){
       Segment_Logs__c sgLog = new Segment_Logs__c();
        for(String i : logIds.keySet()){
            if(segmentRequests != null && segmentRequests.containsKey(i)){
                sgLog = logIds.get(i);
                sgLog.Status__c= ((response != null && response.getStatusCode() == 200 )?CDdMxSxSegmentConstants.SUCESS_STATUS:response.getBody()) ;
                sgLog.Retry_Count__c = (logIds.get(i).Retry_Count__c!=null)?(logIds.get(i).Retry_Count__c + 1):1  ;
                logIds.put(i, sgLog) ;
            }
        }
        if(logIds.isEmpty()){
            return;
        }
        if(insertLogs)
        {
            Database.upsert(logIds.values(), false);
        }
    }
    /**
     * @description Wraps the List of event Requests with the batch key
     * @param 
     * @return Map<String, List<CDdMxSxSegmentHelper.CDdMxSxSegmentRequest>>
    */ 
    private Map<String, List<CDdMxSxSegmentRequest>> prepareRequestBodyforBatch(){
        Map<String, List<CDdMxSxSegmentRequest> > segmentBatchRequest = new Map<String, List<CDdMxSxSegmentRequest> >();
        segmentBatchRequest.put(CDdMxSxSegmentConstants.SEGMENT_BATCH_EVENT, segmentRequests.values());
        return segmentBatchRequest;
    }
    /**
     * @description Handles point-to-point Integration with Segment, calls the callouthelper and processes the response
     *              and calls the method to update logIds 
     * @param 
     * @return 
    */ 
    private void handleAPICall(){
        if(segmentRequests.isEmpty()){
            return;
        }
        String requestBody; //payload to be sent
        String urlPath; //extension of the API - Batch or Track
        if(CDdMxSxSegmentConstants.ISEXECUTIONINBATCHCONTEXT){
            requestBody = JSON.Serialize(prepareRequestBodyforBatch());
            urlPath = CDdMxSxSegmentConstants.SEGMENTSETTINGS.Batch_API_Url_Path__c ;
        }else{
            requestBody = JSON.Serialize(segmentRequests.values());
            urlPath = CDdMxSxSegmentConstants.SEGMENTSETTINGS.Track_API_Url_Path__c ;
        }
        HttpResponse response = CDdMxSxSegmentCalloutHelper.callSegmentAPI(requestBody, urlPath,
                                                                           CDdMxSxSegmentConstants.SEGMENT_CALLOUT_METHOD);
        processAPIResponse(response, !CDdMxSxSegmentConstants.ISEXECUTIONINBATCHCONTEXT);//pass the batch context to avoid DML statement for batch Execution
    }

    /**
     * @description filter SObject based on the custom metadata setting
     * @param Set<Id> sObjectIds
     * @param String eventName 
     * @return Set<Id>
    */
    public static Set<Id> filterSobjectIdsToSendNotification(Set<Id> sObjectIds, String eventName){
        Set<Id> filteredSobjectIds = new Set<Id>();
        Map<Id,Segment_Logs__c> segmentLogsBySObjectId = getSegmentLogRecords(eventName, sObjectIds,CDdMxSxSegmentConstants.SUCESS_STATUS);
        for (Id sobjectId : sObjectIds) {
            if (!segmentLogsBySObjectId.containsKey(sobjectId)){
                filteredSobjectIds.add(sobjectId);
            }
        }
        return filteredSobjectIds;
    }
    /**
     * @description get Segment Logs records
     * @param String eventName 
     * @param Set<Id> sObjectIds
     * @param String status 
     * @return Map<Id,Segment_Logs__c>
    */
    public static Map<Id,Segment_Logs__c> getSegmentLogRecords(String eventName, Set<Id> sObjectIds, String status){
        Map<Id,Segment_Logs__c> segmentLogsBySObjectId = new Map<Id,Segment_Logs__c>();
        List<Segment_Logs__c> segmentLogs = [SELECT Id, LastModifiedDate, CreatedDate, Event__c, Request_Payload__c, SObject_Id__c, Status__c, Error_Message__c 
                FROM Segment_Logs__c 
                WHERE SObject_Id__c IN :sObjectIds AND Event__c = :eventName];

        for (Segment_Logs__c segmentLog : segmentLogs) {
            if (segmentLog.CreatedDate > Datetime.now().addSeconds(-CDdMxSxSegmentConstants.PREVIOUS_EVENT_CREATED_IN_LAST_N_SECONDS)) {
                segmentLogsBySObjectId.put(segmentLog.SObject_Id__c,segmentLog);
            }else if(SEND_SEGMENT_EVENT_ONLY_ONCE && segmentLog.Status__c == status){
                segmentLogsBySObjectId.put(segmentLog.SObject_Id__c,segmentLog);
            }
        }
        return segmentLogsBySObjectId;
    }
}