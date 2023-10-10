/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/22/2019
*
* @group SObject Field Copy
*
* @description A batch job that copies fields from the source Account record to the target master lead record.
*	Custom metadata is used to determine the source/target records as well as the specific fields to copy.
*	Member variable 'fieldCopyObj' is a representation of the custom metadata.
*
**************************************************************************************************************************************/
global class CDdAccountFieldCopyToLeadBatch implements Database.Batchable<sObject> {
    /**
    * @description An instance of SObject Field Copy object that represents the configuration as found within custom metadata
    **/						
    private CDdSObjectFieldCopyObj fieldCopyObj {get; set;}
    /**
    * @description A veriable to persist the dynamic query string
    */      
    private String query;
    /**
    * @description A veriable to store in memory (stateful) Account record identifiers
    */      
    private List<Id> recordIds;    	
    /**
    * @description A static constant variable to hold the Account sObject type value
    **/	
    private static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    /**
    * @description A static constant variable to hold the Lead sObject type value
    **/	
    private static final String SOBJECT_TYPE_LEAD = 'Lead';	
    /**
    *	A query clause to further filter the lead records based on Parent Account record identifiers
    */
    public static String QUERY_FILTER_RECORD_IDS = ' AND (Parent_Account__c IN :recordIds)';      	
    /**
    * @description Default constructor
    *	- Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
    *	- Prepare the dynamic SOQL query to execute by this batch job
    **/		
    global CDdAccountFieldCopyToLeadBatch() {
        setFieldCopyObj();
        setQuery();
    }
    /**
    * @description Single argument constructor - input Parent Account record identifiers
    *	- Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
    *	- Prepare the dynamic SOQL query to execute by this batch job  	
    * @param recordIds Input Parent Account record identifers
    **/		
    global CDdAccountFieldCopyToLeadBatch(List<Id> recordIds) {
        this();
        this.recordIds = recordIds;
        this.query = this.query + (this.recordIds != null && !this.recordIds.isEmpty() ? QUERY_FILTER_RECORD_IDS : '');
    }	
    /** 
    * @description Start the batch operation and prepare the Query to locate the Account records for field copy
    */    	
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> sourceRecordTypeDeveloperNames = this.fieldCopyObj.sourceRecordTypeDeveloperNames;
        Set<String> targetRecordTypeDeveloperNames = this.fieldCopyObj.targetRecordTypeDeveloperNames;
        return Database.getQueryLocator(query);
    }
    /** 
    * @description Execute the batch operation for field copy on the scoped Account records
    */  
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> sourceRecordIds = new Set<Id>();
        Set<Id> targetRecordIds = new Set<Id>();
        List<String> errorMessages = new List<String>();
        for (SObject obj : scope){
            sourceRecordIds.add((Id)obj.get('Parent_Account__c'));
            targetRecordIds.add((Id)obj.get('Id'));
        }
        List<sObject> targetRecords = new CDdSObjectFieldCopyProcessor(this.fieldCopyObj, sourceRecordIds, targetRecordIds).targetRecords;
        Savepoint savePointBeforeUpdate = Database.setSavepoint();
        try{
            Database.SaveResult[] updateResults = Database.update(targetRecords, false);
            errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
        } catch(Exception ex) {
            Database.rollback(savePointBeforeUpdate);
        }
        if(!errorMessages.isEmpty()){
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdAccountFieldCopyToLeadBatch');
        }        
    }
    /** 
    * @description Finish the batch operation
    */ 	
    global void finish(Database.BatchableContext BC) {

    }
    /**
    * @description Retrieve the field copy object that represents the custom metadata for 
    *	- source object type 'Account'
    *	- target sobject type 'Account'
    * and set it in the member variable fieldCopyObj
    **/		
    private void setFieldCopyObj() {
        this.fieldCopyObj = new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT).getFieldCopyObj(SOBJECT_TYPE_LEAD);		
    }
    /**
    * @description Prepare the dynamic SOQL query to execute. Set it in the member variable 'query'
    **/		
    private void setQuery() {
        this.query = 'SELECT Id, Parent_Account__c '
                + ' FROM Lead '
                + ' WHERE ' + 'RecordType.DeveloperName' + ' IN ' + ':' + 'targetRecordTypeDeveloperNames'
                + ' AND IsConverted = false ';
    }
}