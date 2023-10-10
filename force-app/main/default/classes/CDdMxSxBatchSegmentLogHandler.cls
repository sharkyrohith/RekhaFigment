/********************************************************************************************************************
* @author ebby
* @date 12/08/2021
*
* @group Merchant Services
*
* @description Apex Batch class that will retry from Segment Logs either to Mulesoft or to segment directly
* - Will push to Segment if Publish_Events_to_Segment__c is checked or retry Count >= 4
* - If not, will re-trigger a platform event 
* 
**************************************************************************************************************************************/

global class CDdMxSxBatchSegmentLogHandler implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.stateful{
    /**
     * Define class variables here
     */
    public static final String QUERY = ' SELECT Id, sObject_Id__c, status__c, Retry_Count__c, Event__c from Segment_Logs__c ' 
                                        + 'WHERE LASTMODIFIEDDATE = LAST_N_DAYS:{0} '
                                        + 'AND LASTMODIFIEDDATE <= {1} '
                                        + 'AND Status__c NOT IN :sucessStatus '
                                        + 'AND (Retry_Count__c < :maxRetryCount OR Retry_Count__c = null) '
                                        + 'AND Event__c IN :events  order by CreatedDate DESC';
    public Integer lastModifiedDays;
    public DateTime lastModifiedDate;
    public Integer platformEventfailedCount;
    public static final String SEGMENT_LOG_EVENT_NAME = 'Event__c';
    public List<segment__mdt> segmentConfigs{get;set;}
    private static final String CLASSNAME = 'CDdMxSxBatchSegmentLogHandler';
    /** 
     * @description Default constructor
     */
    public CDdMxSxBatchSegmentLogHandler(){
        this(CDdMxSxSegmentConstants.DEFAULT_BATCH_LAST_MODIFIED_DAYS, CDdMxSxSegmentConstants.DEFAULT_MINUTES_FOR_LOG_HANDLER);
    }
    /** 
     * @description two argument constructor
     * @param Integer lastModifiedDays - records to be fecthed from (from the last Modified days)
     * @param lastModifiedMinutes - fetch stale records not updated in lastModifiedMinutes
    */
    public CDdMxSxBatchSegmentLogHandler(Integer lastModifiedDays, Integer lastModifiedMinutes) {
        this.lastModifiedDays = lastModifiedDays!=null?lastModifiedDays:CDdMxSxSegmentConstants.DEFAULT_BATCH_LAST_MODIFIED_DAYS;
        this.lastModifiedDate = lastModifiedMinutes!=null?System.Now().addMinutes(- lastModifiedMinutes):System.Now().addMinutes(- CDdMxSxSegmentConstants.DEFAULT_MINUTES_FOR_LOG_HANDLER);
    }
    /** 
    * @description Start the batch operation and prepare the Query to fetch the Segment Logs to reprocess
    */ 
    global Database.QueryLocator start(Database.BatchableContext bC) {
        Set<String> events = CDdMxSxConstants.MXSX_EVENTS.keySet();
        Set<String> sucessStatus = CDdMxSxSegmentConstants.IGNORE_LOG_STATUS ;
        Integer maxRetryCount = CDdMxSxSegmentConstants.SEGMENT_MAXIMUM_RETRY_COUNT;
        platformEventfailedCount = 0;
        String soqlQuery = String.format(QUERY, new List<String>{String.valueOf(this.lastModifiedDays), this.lastModifiedDate.format(CDdMxSxSegmentConstants.TIMEFORMAT, CDdMxSxSegmentConstants.TIMESTAMPZONE)});
        return Database.getQueryLocator(soqlQuery);
    }
    /** 
    * @description Execute the batch operation for the Segment Logs. Categorize the logs and decide if a record has to be reprocessed
    */  
    global void execute(Database.BatchableContext bC, List<sObject> scope) {
        //Check the current status of the records
        Set<Id> parentsObjectIds = new Set<Id>();
        Set<String> parentsObjectTypes = new Set<String>();
        for(sObject sL :scope){
            Id sObjectId = String.valueOf(sL.get('sObject_Id__c'));
            parentsObjectIds.add(sObjectId);
            parentsObjectTypes.add(sObjectId.getSObjectType().getDescribe().getName());
        }
        Map<String, String> eventClass = getSegmentConditionsClass(parentsObjectTypes);//Get overwritten class from custom setting
        set<Id> reprocessIds = getReprocessIds(parentsObjectTypes, eventClass, parentsObjectIds);
        
        //for each Object Type get the Ids and update the new scope
        CDdMxSxSegmentHelper segmentHelper; //stores the list of log records where the status is moved out of block
        if(reprocessIds != null && !reprocessIds.isEmpty()){
            segmentHelper = processSegmentEvents(scope, reprocessIds);
        }else{
            for(sObject sL :scope){
                sL.put('status__c', CDdMxSxSegmentConstants.NOT_REQUIRED_STATUS);
                segmentHelper.logIds.put((String)sL.get('sObject_Id__c'), (segment_logs__c)sL);
            }
        }
        if(!segmentHelper.segmentRequestEvents.isEmpty()){
            segmentHelper.createSegmentEvents();
        }
        if(!segmentHelper.logIds.isEmpty()){
            database.update(segmentHelper.logIds.values());
        }
        
    }  
    /** 
    * @description Finish Operation overwritten after the batch execution is complete, it verifies if there are too many requests Failing through 
    * Mulesoft and notifies Mx POD team. Further actions can be taken based on the need if the Publish to Segment flag needs to be turned on
    */ 
    global void finish(Database.BatchableContext bC){
        //Send an email to notify of too many failures
        if(!CDdMxSxSegmentConstants.PUBLISH_EVENTS_TO_SEGMENT && platformEventfailedCount != null && platformEventfailedCount > CDdMxSxSegmentConstants.SEGMENTSETTINGS.Platform_Events_Error_Threshold__c){
            sendEmail(CDdMxSxSegmentConstants.NORESPONSEERRORSUBJECT, CDdMxSxSegmentConstants.NORESPONSEERRORBODY);
        }
    }
    /**
     * @description Sends an email with the subject and body passed
     * @param String subjec
     * @param String htmlBody
     * @return 
    */
    public void sendEmail(String subject, String htmlBody){
        if(String.isBlank(CDdMxSxSegmentConstants.SEGMENTSETTINGS.Error_Emails__c)){
            return;
        }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody( String.format(htmlBody, new List<String>{String.valueOf(this.platformEventfailedCount)}) );
        email.setToAddresses(CDdMxSxSegmentConstants.SEGMENTSETTINGS.Error_Emails__c.split(','));
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }catch(exception e){
            insert CDdMxSxException.createErrorLog(CDdMxSxBatchSegmentLogHandler.CLASSNAME, 'sendEmail', '', Logginglevel.ERROR, '',  null, e.getStackTraceString() + ' '+ e.getMessage());
        }
    }
    /**
     * @description Processes the segment logs and calls the helper methods to process the logs either to Mulesoft or to segment directly
     * @param List<sObject> scope
     * @param Set<Id> reprocessIds - sObjects Ids validated to be re-processed
     * @return CDdMxSxSegmentHelper - segmentHelper Class instance which will hold values - for which DML should be performed 
    */
    public CDdMxSxSegmentHelper processSegmentEvents(List<sObject> scope, Set<Id> reprocessIds){
        Map<String, sObject> reprocessLogs = new Map<String, sObject>();
        Map<String, Map<String, Segment_Logs__c>> logIdsbyEvent = new Map<String, Map<String, Segment_Logs__c>>();
        CDdMxSxSegmentHelper segmentHelper = new CDdMxSxSegmentHelper();
        for (sObject log : scope){
            String sObjectId = String.valueOf(log.get('SObject_Id__c')) ;
            if(reprocessIds.contains(sObjectId)){
                if(!reprocessLogs.containsKey(sObjectId)){
                        reprocessLogs.put(sObjectId, log);
                        logIdsbyEvent = groupLogIdsByMxSxEventProperty(log, logIdsbyEvent);
                }
                else{
                    segmentHelper.logIds.put(sObjectId+(String)log.get('Id'), updateProcessedLog(log));
                }        
            }else{
                segmentHelper.logIds.put(sObjectId+(String)log.get('Id'), updateProcessedLog(log));
            }
        }
        Map<String, List<Segment_Logs__c>> mxSxSegmentlogsByEventName = groupLogEventsByMxSxEventProperty(SEGMENT_LOG_EVENT_NAME, reprocessLogs.values());
        for (String eventName : mxSxSegmentlogsByEventName.keySet()){
            List<Segment_Logs__c> logEvents = mxSxSegmentlogsByEventName.get(eventName);
            Set<Id> sObjectIds = getSObjectIds(logEvents);
            CDdMxSxSegmentHelper helper = new CDdMxSxSegmentHelper(logIdsbyEvent.get(eventName));
            helper.handleSegmentEvents(sObjectIds, eventName);
            if(!helper.segmentRequestEvents.isEmpty()){
                segmentHelper.segmentRequestEvents.putAll(helper.segmentRequestEvents);
            }
            if(helper.logIds != null && !helper.logIds.isEmpty()){
                segmentHelper.logIds.putAll(helper.logIds);
            }
            platformEventfailedCount += (!helper.segmentRequests.isEmpty())?helper.segmentRequests.Size():0 ;
        }
        return segmentHelper;
    }
    /**
     * @description prepares a collection of event Type and a Map of sObjectId and the corresponding log
     * @param sObject log - Segment Log record
     * @param Map<String, Map<String, Segment_Logs__c>> collection of event Type and Map of sObjectIds/log records
     * @return SMap<String, Map<String, Segment_Logs__c>>  updated collection of event Type and Map of sObjectIds/log records  
    */
    public Map<String, Map<String, Segment_Logs__c>> groupLogIdsByMxSxEventProperty(sObject log,  Map<String, Map<String, Segment_Logs__c>> logIds){
        String eventName = (String)log.get(SEGMENT_LOG_EVENT_NAME);
        String sObjectId = (String)log.get('sObject_Id__c');
        Map<String, Segment_Logs__c> logs  = new Map<String, Segment_Logs__c>();
        if(logIds.containsKey(eventName)){
            logs = logIds.get(eventName) ;
        }
        logs.put(sObjectId, (Segment_Logs__c)log);
        logIds.put(eventName, logs);
        return logIds;
    }
    /**
     * @description Updates the status of the Segment Log if re-processing is not needed
     * @param sObject obj - Segment Log record
     * @return Segment_Logs__c - Status Updated Segment Log    
    */
    public Segment_Logs__c updateProcessedLog(sObject obj){
        obj.put('Status__c', CDdMxSxSegmentConstants.NOT_REQUIRED_STATUS);
        return (Segment_Logs__c)obj;
    }
    /**
     * @description returns the set of sObjectIds of the records that needs to be reprocessed
     * @param Set<String> parentsObjectTypes - sObject Types of the Log records in the collection(Scope)
     * @param Map<String, String> eventClass - event class collection where the condition for the valid records exists
     * @param Set<Id> parentsObjectIds - List of all sObjectIds from scope
     * @return Set<Id> sObjectIds - a Collection Object record Ids that needs to reproccesed to Segment
    */
    public Set<Id> getReprocessIds(Set<String> parentsObjectTypes, Map<String, String> eventClass, Set<Id> parentsObjectIds){
        Set<Id> reprocessIds = new Set<Id>();
        for(String objectName: parentsObjectTypes){
            if (eventClass.containsKey(objectName)){
                String className = eventClass.get(objectName);
                CDdMxSxSegmentConditionsHandler instanceHandler = CDdMxSxSegmentHelper.getClassInstance(className);
                reprocessIds.addAll(instanceHandler.getSegmentEventIds(null, null, parentsObjectIds).keySet());
            }
        }
        return reprocessIds ;
    } 
    /**
     * @description returns the sObjectIds of the records passed
     * @param List<Segment_Logs__c> logs - Log records
     * @return Set<Id> sObjectIds - a Collection Object record Ids   
    */
    public Set<Id> getSObjectIds(List<Segment_Logs__c> logs){
        Set<Id> sObjectIds = new Set<Id>();
        for (Segment_Logs__c log : logs){
            sObjectIds.add((Id)log.sObject_Id__c);
        }
        return sObjectIds;
    }
    /**
     * @description Group the Segment log records based on the event Type
     * @param String mxSxEventProperty field by which the records has to be grouped
     * @param List<Segment_Logs__c> segmentEventLogs List of all segment Logs
     * @return Map<String, List<Segment_Logs__c>> - a Collection of event Type and List of Log records   
    */
    public Map<String, List<Segment_Logs__c>> groupLogEventsByMxSxEventProperty(String mxSxEventProperty, List<Segment_Logs__c> segmentEventLogs){
        Map<String, List<Segment_Logs__c>> mxSxEventsBymxSxEventProperty = new Map<String, List<Segment_Logs__c>>();
        for (Segment_Logs__c log : segmentEventLogs){
            String value = (String)log.get(mxSxEventProperty);            
            if (mxSxEventsBymxSxEventProperty.containsKey(value)){
                mxSxEventsBymxSxEventProperty.get(value).add(log);
            } else {
                mxSxEventsBymxSxEventProperty.put(value, new List<Segment_Logs__c>{log});
            }
        }
        return mxSxEventsBymxSxEventProperty;
    }
    /**
     * @description returns a Map of Object Types and the corresponding Overwritten class for the conditions
     * @param Set<String> sObjectTypes Object Types
     * @return Map<String, String> - a Collection of Object Types and Class Names   
    */ 
    public Map<String, String> getSegmentConditionsClass(Set<String> sObjectTypes){
        Map<String, String> eventClasses = new Map<String, String>();
        for(segment__mdt sG : [Select Id, Apex_Class__c, Event_Name__c, SObject_Type__c from segment__mdt 
                               where SObject_Type__c in: sObjectTypes]){
            if (String.isNotBlank(sG.Apex_Class__c)){                                
                eventClasses.put(sG.SObject_Type__c, sG.Apex_Class__c);
            }
        }
        return eventClasses; 
    }
}