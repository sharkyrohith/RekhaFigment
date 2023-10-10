/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/21/2019
*
* @group SObject Field Copy
*
* @description A batch job that copies fields from the source Account record to the target account record.
*   Custom metadata is used to determine the source/target records as well as the specific fields to copy.
*   Member variable 'fieldCopyObj' is a representation of the custom metadata.
*
**************************************************************************************************************************************/
global class CDdAccountFieldCopyToAccountBatch implements Database.Batchable<sObject> {
    /**
    * @description An instance of SObject Field Copy object that represents the configuration as found within custom metadata
    **/                     
    private CDdSObjectFieldCopyObj fieldCopyObj {get; set;}
    /**
    * @description A veriable to persist the dynamic query string
    */      
    private String query;
    /**
    * @description A variable to store in memory (stateful) Account record identifiers
    */      
    private List<Id> recordIds;
    /**
    * @description A variable to store errors at the batch instance level
    */      
    private List<String> errors;         
    /**
    * @description A static constant variable to hold the Account sObject type value
    **/ 
    private static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    /**
    *   A query clause to further filter the records based on record identifiers
    */
    public static String QUERY_FILTER_RECORD_IDS = ' AND (Id IN :recordIds OR ParentId IN :recordIds)';         
    /**
    * @description Default constructor
    *   - Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
    *   - Prepare the dynamic SOQL query to execute by this batch job
    **/     
    global CDdAccountFieldCopyToAccountBatch() {
        errors = new List<String>();
        setFieldCopyObj();
        setQuery();
    }
    /**
    * @description Single argument constructor - input Account record identifiers
    *   - Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
    *   - Prepare the dynamic SOQL query to execute by this batch job   
    * @param recordIds Input account identifers
    **/     
    global CDdAccountFieldCopyToAccountBatch(List<Id> recordIds) {
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
            sourceRecordIds.add((Id)obj.get('ParentId'));
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
            this.errors.addAll(errorMessages);
            throw new CDdAccountFieldCopyToAccountBatchException(errorMessages.get(0));  //throw an exception with the first error message
        }       
    }
    /** 
    * @description Finish the batch operation
    */  
    global void finish(Database.BatchableContext BC) {
        if(!this.errors.isEmpty()){
            CDdErrorUtilities.createApexLogs(this.errors, 'CDdAccountFieldCopyToAccountBatch');
        }        
    }
    /**
    * @description Retrieve the field copy object that represents the custom metadata for 
    *   - source object type 'Account'
    *   - target sobject type 'Account'
    * and set it in the member variable fieldCopyObj
    **/     
    private void setFieldCopyObj() {
        this.fieldCopyObj = new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT).getFieldCopyObj(SOBJECT_TYPE_ACCOUNT);     
    }
    /**
    * @description Prepare the dynamic SOQL query to execute. Set it in the member variable 'query'
    **/     
    private void setQuery() {
        this.query = 'SELECT Id, ParentId FROM Account WHERE RecordType.DeveloperName IN :targetRecordTypeDeveloperNames';
    }
    /**
    * @description A custom exception is thrown in the event something goes wrong during the processing in the above operations
    **/     
    public class CDdAccountFieldCopyToAccountBatchException extends Exception {
    }   
}