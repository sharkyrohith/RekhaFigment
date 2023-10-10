/************************************************************************************************************************************
* @author Ila Maheshwari
* @date 9/6/2022
*
* @group Delete SSMO Test Records
*
* @description The purpose of this Apex batch class is to query Opportunity, Lead, Case and Account test records created by Self-Serve Integration User
* 
**************************************************************************************************************************************/
public class CDdDeleteSSMOTestRecordsBatch implements Database.Batchable<sObject>, Database.stateful {
    
    private static Date datediff = System.Today().addDays(-7);
    private Date startDate, endDate;
    private Integer maxNumberOfRecords;
    private Set<String> objectNames;
    private String currentContextObject, query;
    private List<Self_Serve_Users__c> selfServeUsers = Self_Serve_Users__c.getAll().values(); 
    private List<Id> selfServeUserIds = new List<Id>();
    private List<Case> casesToDelete = new List<Case>();
    private String defaultRecordsLimit = System.Label.SSMO_Batch_Record_Deletion_Limit;
    private static String TEST_MATCH_STRING1 = CDdNameValuePairHelper.getTextValue('SSMO_Record_Delete_String_Match1');
    private static String TEST_MATCH_STRING2 = CDdNameValuePairHelper.getTextValue('SSMO_Record_Delete_String_Match2');
    private static String TEST_MATCH_LEAD_NAME = CDdNameValuePairHelper.getTextValue('SSMO_Record_Delete_String_Match_Lead1');
    private static String TEST_MATCH_LEAD_EMAIL = CDdNameValuePairHelper.getTextValue('SSMO_Record_Delete_String_Match_Lead2');
    private static String QUERY_BASE = 'SELECT Id, Name FROM ';
    private static String QUERY_ACC_OPP_FILTER = ' WHERE (Name Like \'%' + TEST_MATCH_STRING1 + '%\' OR Name Like \'%' + TEST_MATCH_STRING2 + '%\') AND Name Like \'%pulse%\'';
    private static String QUERY_LEAD_FILTER = ' WHERE (Email Like \'%' + TEST_MATCH_LEAD_EMAIL + '%\' OR Name Like \'%' + TEST_MATCH_LEAD_NAME + '%\')';
    private static String QUERY_BASE_FILTER, QUERY_LIMIT;
    
   /** 
    * @description 1 argument constructor
    * @param deleteObject to specify which object records to query
    */
    public CDdDeleteSSMOTestRecordsBatch(Set<String> objectNames, Date startDate, Date endDate, Integer maxNumberOfRecords) {	
        this.objectNames = objectNames;	
        this.startDate = startDate;	
        this.endDate = endDate;
        this.maxNumberOfRecords = maxNumberOfRecords;
        
        for(Self_Serve_Users__c ssUser : selfServeUsers) {
            selfServeUserIds.add(ssUser.User_Id__c); 
        }

        if(startDate == null || endDate == null) {
            QUERY_BASE_FILTER = ' AND CreatedById IN :selfServeUserIds AND CreatedDate < :datediff'; 
        } else {
        	QUERY_BASE_FILTER = ' AND CreatedById IN :selfServeUserIds AND CreatedDate <= :endDate AND CreatedDate >= :startDate'; 
        }

        QUERY_LIMIT = ((maxNumberOfRecords!=null && maxNumberOfRecords!=0) ? ' LIMIT ' + String.valueOf(maxNumberOfRecords) : ' LIMIT ' + defaultRecordsLimit);

        if(objectNames.contains('Opportunity')) {
            this.query = QUERY_BASE + 'Opportunity' + QUERY_ACC_OPP_FILTER + QUERY_BASE_FILTER + QUERY_LIMIT;
            this.currentContextObject = 'Opportunity';
        } else if(objectNames.contains('Lead')) {
            this.query = QUERY_BASE + 'Lead' + QUERY_LEAD_FILTER + QUERY_BASE_FILTER + QUERY_LIMIT;
            this.currentContextObject = 'Lead';
        } else if(objectNames.contains('Case')) {
            this.query = QUERY_BASE + 'Account' + QUERY_ACC_OPP_FILTER + QUERY_BASE_FILTER + QUERY_LIMIT;
            this.currentContextObject = 'Case';
        } else if(objectNames.contains('Account')) {
            this.query = QUERY_BASE + 'Account' + QUERY_ACC_OPP_FILTER + QUERY_BASE_FILTER + QUERY_LIMIT;
            this.currentContextObject = 'Account';
        }
    }
    /** 
    * @description Start the batch operation and prepare the Query to locate the Opportunity/Account/Lead/Case records to delete
    */    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    /** 
    * @description Execute the batch operation to delete scoped Opportunity/Account/Lead/Case records
    */      
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Apex_Log__c> errorsToLog = new List<Apex_Log__c>();
        String logMessage;
        Database.deleteResult[] results;
        
        if(currentContextObject == 'Case') {	
            casesToDelete = [SELECT Id FROM Case WHERE AccountId IN :scope OR Account_name__c IN :scope];	
        }	
        	
        try {	
            if(!casesToDelete.isEmpty()){	
                results = Database.delete(casesToDelete, false);	
            } else {	
              	results = Database.delete(scope, false);	
            }	
        }
        catch (Exception eX) {
            system.debug(LoggingLevel.ERROR, 'CDdDeleteSSMOTestRecordsBatch.execute: DMLtodo: Exception: ' + eX);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for(Database.Error err : results[i].getErrors())
                        logMessage += ' (status code: ' + err.getStatusCode() + ') ' + err.getMessage();
                    errorsToLog.add(new Apex_Log__c(Class_Name__c = 'CDdDeleteSSMOTestRecordsBatch', Method_Name__c = 'execute',
                                                    Log__c = 'Unable to delete test SSMO records from batch', Log_Level__c = 'Error'
                                                   ));
                }
            }
        }
        
        if (errorsToLog.size() > 0) Database.insert(errorsToLog, false);
    }
	/** 
    * @description Finish will execute same batch for Account, Lead, Case records
    */  
    public void finish(Database.BatchableContext BC) {
        if(this.objectNames.contains(this.currentContextObject)) {
            this.objectNames.remove(this.currentContextObject);
        }
        
        if(!objectNames.isEmpty()){
           Database.executeBatch(new CDdDeleteSSMOTestRecordsBatch(this.objectNames, this.startDate, this.endDate, this.maxNumberOfRecords)); 
        }
    }    

}