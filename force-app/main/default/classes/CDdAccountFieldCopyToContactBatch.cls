/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/21/2019
*
* @group SObject Field Copy
*
* @description A batch job that copies fields from the source Account record to the target Contact record.
*	Custom metadata is used to determine the source/target records as well as the specific fields to copy.
*	Member variable 'fieldCopyObj' is a representation of the custom metadata.
*
**************************************************************************************************************************************/
global class CDdAccountFieldCopyToContactBatch implements Database.Batchable<sObject> {
  /**
  	* @description An instance of SObject Field Copy object that represents the configuration as found within custom metadata
  	**/						
	private CDdSObjectFieldCopyObj fieldCopyObj {get; set;}
   /**
    * @description A veriable to persist the dynamic query string
    */      
    private String query;	
  /**
  	* @description A static constant variable to hold the Account sObject type value
  	**/	
	private static final String SOBJECT_TYPE_ACCOUNT = 'Account';
  /**
  	* @description A static constant variable to hold the Contact sObject type value
  	**/	
	private static final String SOBJECT_TYPE_CONTACT = 'Contact';	
  /**
  	* @description Default constructor
  	*	- Prepare the field copy object using the custom metadata and set it in the member variable fieldCopyObj
  	*	- Prepare the dynamic SOQL query to execute by this batch job
  	**/		
	global CDdAccountFieldCopyToContactBatch() {
		setFieldCopyObj();
		setQuery();
	}
    /** 
    * @description Start the batch operation and prepare the Query to locate the Account records for field copy
    */    	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		Set<String> recordTypeDeveloperNames = this.fieldCopyObj.sourceRecordTypeDeveloperNames;
		return Database.getQueryLocator(query);
	}
    /** 
    * @description Execute the batch operation for field copy on the scoped Account records
    */  
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		Set<Id> sourceRecordIds = new Set<Id>();
		for (SObject obj : scope){
			sourceRecordIds.add((Id)obj.get('Id'));
		}
		List<sObject> targetRecords = new CDdSObjectFieldCopyProcessor(this.fieldCopyObj, sourceRecordIds).targetRecords;
		Savepoint savePointBeforeUpdate = Database.setSavepoint();
		try{
			Database.SaveResult[] updateResults = Database.update(targetRecords, false);
			for(Database.SaveResult sr : updateResults){
				if (!sr.isSuccess()) {
			        // Operation failed, so get all errors                
			        for(Database.Error err : sr.getErrors()) {
			            System.debug('The following error has occurred.');                    
			            System.debug(err.getStatusCode() + ': ' + err.getMessage());
			            System.debug('SObject copy fields that affected this error: ' + err.getFields());
			        }
				}				
			}
		} catch(Exception ex) {
			Database.rollback(savePointBeforeUpdate);
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
  	*	- target sobject type 'Contact'
  	* and set it in the member variable fieldCopyObj
  	**/		
	private void setFieldCopyObj() {
		this.fieldCopyObj = new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT).getFieldCopyObj(SOBJECT_TYPE_CONTACT);	
	}
  /**
  	* @description Prepare the dynamic SOQL query to execute. Set it in the member variable 'query'
  	**/		
	private void setQuery() {
		this.query = 'SELECT '
						+ this.fieldCopyObj.sourceRecordKeyField
						+ ' FROM ' + this.fieldCopyObj.sourceSObjectType
						+ ' WHERE ' + 'RecordType.DeveloperName' + ' IN ' + ':' + 'recordTypeDeveloperNames';		
	}
}