/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 09/27/2020
*
* @group SObject Field Copy
*
* @description A batch job that copies fields from the source Customer Detail/Store Detail record to the target account record.
*   Custom metadata is used to determine the source/target records as well as the specific fields to copy.
*   Member variable 'fieldCopyObj' is a representation of the custom metadata.
*
**************************************************************************************************************************************/
global class CDdCopyCustStoreDetailToAccountBatch implements Database.Batchable<sObject> {
    /**
    * @description Static constant field definitions
    **/	
    public static final String SOBJECT_TYPE_CUSTOMER_DETAIL = 'Customer_Detail__c';
    public static final String SOBJECT_TYPE_STORE_DETAIL = 'Store_Details__c';
	public static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    public static final String SOBJECT_FIELD_CUSTOMER_DETAIL = 'Customer_Detail__c';
    public static final String SOBJECT_FIELD_STORE_DETAIL = 'Store_Details__c';	
    public static final String ERROR_MSG_INVALID_SOURCE_SOBJECT_TYPE = 'Please select a valid SObject Type.'
                                                + ' Valid values are \'Customer_Detail__c\' or \'Store_Details__c\'. ';                	
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
    private Set<Id> recordIds;
    /**
    * @description A variable to store errors at the batch instance level
    */      
    private List<String> errors;         
    /**
    *   A query clause to further filter the records based on record identifiers
    */
    public static String QUERY_FILTER_RECORD_IDS = ' AND (Account__c IN :recordIds) ';
    public static String QUERY_ORDER_BY = ' ORDER BY LastModifiedDate ASC ';         
    /**
    * @description Constructor method
    *   - Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
    *   - Prepare the dynamic SOQL query to execute by this batch job
    * @param sObjectType Source SObject - SOBJECT_TYPE_CUSTOMER_DETAIL or SOBJECT_TYPE_STORE_DETAIL    
    **/     
    global CDdCopyCustStoreDetailToAccountBatch(String sObjectType) {
        if (!new Set<String>{SOBJECT_TYPE_CUSTOMER_DETAIL, SOBJECT_TYPE_STORE_DETAIL}.contains(sObjectType)){
            throw new CDdCopyCustStoreDetailToAccountBatchException(ERROR_MSG_INVALID_SOURCE_SOBJECT_TYPE);
        }    	
        errors = new List<String>();
        setFieldCopyObj(sObjectType, SOBJECT_TYPE_ACCOUNT);
        setQuery(sObjectType);
    }
    /**
    * @description Constructor method
    *   - Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
    *   - Prepare the dynamic SOQL query to execute by this batch job
    * @param sObjectType Source SObject - SOBJECT_TYPE_CUSTOMER_DETAIL or SOBJECT_TYPE_STORE_DETAIL
    * @param recordIds Input account identifers
    **/     
    global CDdCopyCustStoreDetailToAccountBatch(String sObjectType, Set<Id> recordIds) {
        this(sObjectType);
        this.recordIds = recordIds;
        this.query = this.query 
                    + (this.recordIds != null && !this.recordIds.isEmpty() ? QUERY_FILTER_RECORD_IDS : '')
                    + QUERY_ORDER_BY;
    }   
    /** 
    * @description Start the batch operation and prepare the Query to locate the Account records for field copy
    */      
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    /** 
    * @description Execute the batch operation for field copy on the scoped sourceSObjectType records
    */  
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> sourceRecordIds = new Set<Id>();
        List<String> errorMessages = new List<String>();
        for (SObject obj : scope){
            sourceRecordIds.add((Id)obj.get('Account__c'));
        }
        List<sObject> targetRecords = new CDdSObjectFieldCopyProcessor(this.fieldCopyObj, sourceRecordIds).targetRecords;
        Savepoint savePointBeforeUpdate = Database.setSavepoint();
        try{
            Database.SaveResult[] updateResults = Database.update(targetRecords, false);
            errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
        } catch(Exception ex) {
            Database.rollback(savePointBeforeUpdate);
        }
        if(!errorMessages.isEmpty()){
            this.errors.addAll(errorMessages);
            throw new CDdCopyCustStoreDetailToAccountBatchException(errorMessages.get(0));  //throw an exception with the first error message
        }       
    }
    /** 
    * @description Finish the batch operation
    */  
    global void finish(Database.BatchableContext BC) {
        if(!this.errors.isEmpty()){
            CDdErrorUtilities.createApexLogs(this.errors, 'CDdCopyCustStoreDetailToAccountBatch');
        }        
    }
    /**
    * @description Retrieve the field copy object that represents the custom metadata for 
    *   - source object type - input object type from the constructor
    *   - target sobject type 'Account'
    * and set it in the member variable fieldCopyObj
    **/     
    private void setFieldCopyObj(String sourceSObjectType, String targetSObjectType) {
        this.fieldCopyObj = new CDdSObjectFieldCopyInitializer(sourceSObjectType).getFieldCopyObj(targetSObjectType);
    }
    /**
    * @description Prepare the dynamic SOQL query to execute. Set it in the member variable 'query'
    **/     
    private void setQuery(String sourceSObjectType) {
    	String sObjectType = sourceSObjectType;
    	String sObjectField = sourceSObjectType;
        this.query = 'SELECT Id, Account__c FROM ' 
                    + sObjectType 
                    + ' WHERE Account__r.' + sObjectField + ' = null ';
    }
    /**
    * @description A custom exception is thrown in the event something goes wrong during the processing in the above operations
    **/     
    public class CDdCopyCustStoreDetailToAccountBatchException extends Exception {}   
}