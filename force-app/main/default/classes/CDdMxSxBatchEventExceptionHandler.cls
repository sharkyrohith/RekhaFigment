/********************************************************************************************************************
* @author Sriram
* @date 11/17/2021
*
* @group Merchant Services
*
* @description Apex Batch class that will retry the Merchant Services events that had an error/exception in the prior attempt
*
* MxSx events with errors are written to the logs. The batch job will read from the log object and reprocess
* 
**************************************************************************************************************************************/
global class CDdMxSxBatchEventExceptionHandler implements Database.Batchable<sObject> {
    /**
     * Define class variables here
     */
    public static final String MXSX_EVENT_FIELD_EVENT_NAME = 'Operation__c';
    public static final String query = ' SELECT Id, Class_Name__c, Method_Name__c, Object__c, Operation__c, '
                                        + ' Log_Level__c, System_Context__c, User_in_Context__c, Record_ID__c, Reference_Id__c, Log__c '
                                        + ' FROM Apex_Log__c '
                                        + ' WHERE CreatedDate = LAST_N_DAYS:{0} '
                                        + ' AND Reference_Id__c != NULL '                                        
                                        + ' AND Operation__c IN :events '
                                        + ' ORDER BY CreatedDate DESC ';
    private Integer lastModifiedDays;
    /**
     * @description Default Constructor 
     */
    public CDdMxSxBatchEventExceptionHandler(){
        this(CDdMxSxConstants.DEFAULT_BATCH_LAST_MODIFIED_DAYS);
    }
    /**
     * @description Default Constructor 
     */
    public CDdMxSxBatchEventExceptionHandler(Integer lastModifiedDays){
        this.lastModifiedDays = lastModifiedDays;
    }                                       
    /** 
    * @description Start the batch operation and prepare the Query to locate the error events to reprocess
    */      
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> events = CDdMxSxConstants.MXSX_EVENTS.keySet();
        String soqlQuery = String.format(query, new List<String>{String.valueOf(this.lastModifiedDays)});
        return Database.getQueryLocator(soqlQuery);
    }
    /** 
    * @description Execute the batch operation for Merchant Services events that had an error/exception in the prior attempt
    */  
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<String, List<Apex_Log__c>> mxSxEventsByEventName = groupMxSxEventsByMxSxEventProperty(MXSX_EVENT_FIELD_EVENT_NAME, scope);
        List<Apex_Log__c> mxSxEventsToUpdate = new List<Apex_Log__c>();
        for (String eventName : mxSxEventsByEventName.keySet()){
            CDdMxSxConstants.MXSX_EVENT event = CDdMxSxConstants.MXSX_EVENTS.get(eventName);
            List<Apex_Log__c> mxSxEvents = mxSxEventsByEventName.get(eventName);
            mxSxEventsToUpdate.addAll(mxSxEvents);
            Set<Id> sObjectIds = getSObjectIds(mxSxEvents);
            switch on (event) {
                when OPPORTUNITY_CLOSED_WON {
                    CDdMxSxEventHandler.handleEventsOpportunityClosedWon(sObjectIds);
                }
                when STORE_ACTIVE {
                    CDdMxSxEventHandler.handleEventsStoreActive(sObjectIds);
                }                
                when else {
                }
            }
        }
        updateMxSxEvents(mxSxEventsToUpdate);
    }    
    /** 
    * @description Finish the batch operation
    */  
    global void finish(Database.BatchableContext BC) {        
    }
    /**
     * @description Group the Merchant Services Events by the Merchant Service Event property 
     * @param String mxSxEventProperty
     * @param List<Apex_Log__c> mxSxEvents
     * @return Map<String, Set<Id>> Return a Collection of Merchant Services Events grouped by input mxSxEventProperty
     */    
    public Map<String, List<Apex_Log__c>> groupMxSxEventsByMxSxEventProperty(String mxSxEventProperty, List<Apex_Log__c> mxSxEvents){
        Map<String, List<Apex_Log__c>> mxSxEventsBymxSxEventProperty = new Map<String, List<Apex_Log__c>>();
        for (Apex_Log__c event : mxSxEvents){
            String value = (String)event.get(mxSxEventProperty);            
            if (mxSxEventsBymxSxEventProperty.containsKey(value)){
                mxSxEventsBymxSxEventProperty.get(value).add(event);
            } else {
                mxSxEventsBymxSxEventProperty.put(value, new List<Apex_Log__c>{event});
            }
        }
        return mxSxEventsBymxSxEventProperty;
    }
    /**
     * @description Return a Collection of sObject Ids from the Merchant Services Events
     * @param List<Apex_Log__c> mxSxEvents
     * @return Set<Id> - a Collection of sObject Ids   
    */    
    public Set<Id> getSObjectIds(List<Apex_Log__c> mxSxEvents){
        Set<Id> sObjectIds = new Set<Id>();
        for (Apex_Log__c event : mxSxEvents){
            sObjectIds.add((Id)event.Reference_Id__c);
        }
        return sObjectIds;
    }
    /**
     * @description Reset the events, clear the error messages
     * @param List<Apex_Log__c> mxSxEvents
     * @return 
    */     
    public void updateMxSxEvents(List<Apex_Log__c> mxSxEvents){
        for (Apex_Log__c mxSxEvent : mxSxEvents){
            mxSxEvent.Reference_Id__c = null;
        }
        update mxSxEvents;
    }             
}