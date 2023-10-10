/********************************************************************************************************************
* @author Tia
* @date 03/2020
*
* @group SObject Field Copy
*
* @description A batch job that copies fields from the source Account record to the target master lead record.
*	Custom metadata is used to determine the source/target records as well as the specific fields to copy.
*	Member variable 'fieldCopyObj' is a representation of the custom metadata.
*
**************************************************************************************************************************************/

global class CDdAccountFieldCopyToOpportunityBatch implements Database.Batchable<sObject> {
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
    private static final String SOBJECT_TYPE_OPPORTUNITY = 'Opportunity';
    /**
    * @description A static constant variable to maintain Opportunity stages closed
    **/ 
    private static final Set<String> OPPORTUNITY_STAGES_CLOSED = new Set<String>{'Closed Won','Closed Lost'};     	
    /**
    *	A query clause to further filter the lead records based on Parent Account record identifiers
    */
    public static String QUERY_FILTER_RECORD_IDS = ' AND (AccountId IN :recordIds)';      	
    /**
    * @description Default constructor
    *	- Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
    *	- Prepare the dynamic SOQL query to execute by this batch job
    **/		
    global CDdAccountFieldCopyToOpportunityBatch() {
        setFieldCopyObj();
        setQuery();
    }
    /**
    * @description Single argument constructor - input Parent Account record identifiers
    *	- Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
    *	- Prepare the dynamic SOQL query to execute by this batch job  	
    * @param recordIds Input Parent Account record identifers
    **/		
    global CDdAccountFieldCopyToOpportunityBatch(List<Id> recordIds) {
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
        System.debug('query:' + query);
        System.debug('targetRecordTypeDeveloperNames:'+ targetRecordTypeDeveloperNames);
        System.debug('sourceRecordTypeDeveloperNames:'+ sourceRecordTypeDeveloperNames);
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
            sourceRecordIds.add((Id)obj.get('AccountId'));
            targetRecordIds.add((Id)obj.get('Id'));
        }
        List<sObject> targetRecords = new CDdSObjectFieldCopyProcessor(this.fieldCopyObj, sourceRecordIds, targetRecordIds).targetRecords;
        Savepoint savePointBeforeUpdate = Database.setSavepoint();
        try{
            Database.SaveResult[] updateResults = Database.update(targetRecords, false);
            errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
            System.debug('errorMessages:' + errorMessages);
        } catch(Exception ex) {
            Database.rollback(savePointBeforeUpdate);
        }
        if(!errorMessages.isEmpty()){
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdAccountFieldCopyToOpportunityBatch');
            throw new CDdAccountFieldCopyToOpportunityBatchException(errorMessages.get(0));  //throw an exception with the first error message
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
        this.fieldCopyObj = new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT).getFieldCopyObj(SOBJECT_TYPE_OPPORTUNITY);		
    }
    /**
    * @description Prepare the dynamic SOQL query to execute. Set it in the member variable 'query'
    **/		
    private void setQuery() {
        
        this.query = 'SELECT Id, AccountId '
                + ' FROM Opportunity '
                + ' WHERE ' + 'RecordType.DeveloperName' + ' IN ' + ':targetRecordTypeDeveloperNames '
                + ' AND StageName NOT IN :OPPORTUNITY_STAGES_CLOSED ';
    }
    /**
    * @description A custom exception is thrown in the event something goes wrong during the processing in the above operations
    **/     
    public class CDdAccountFieldCopyToOpportunityBatchException extends Exception {
    }     
}