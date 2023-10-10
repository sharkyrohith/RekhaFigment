/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 09/23/2020
*
* @group SObject Field Copy
*
* @description A controller object that utilizes the CDdSObjectFieldCopy framework to 
*   copy the source fields from the source records over to the target fields on the target records
*
**************************************************************************************************************************************/
public class CDdSObjectFieldCopyController {

    public static final String SOBJECT_TYPE_CUSTOMER_DETAIL = 'Customer_Detail__c';
    public static final String SOBJECT_TYPE_STORE_DETAIL = 'Store_Details__c';
    public static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    /**
    * @description Perform copy of data from source to target SObject record
    * @param eventType the generic platform event type
    * @param events a collection of generic platform events
    */    
    public static void handleSObjectCopy(CDdGenericPlatformEventHelper.PlatformEventType eventType, List<Generic_Platform_Event__e> events){
        switch on eventType {
            when COPY_CUSTOMER_DETAIL_TO_ACCOUNT {
                handleSObjectCopy(SOBJECT_TYPE_CUSTOMER_DETAIL, SOBJECT_TYPE_ACCOUNT, getSObjectIds(events));
            }
            when COPY_STORE_DETAIL_TO_ACCOUNT {
                handleSObjectCopy(SOBJECT_TYPE_STORE_DETAIL, SOBJECT_TYPE_ACCOUNT, getSObjectIds(events));
            }            
        }
    }
    /**
    * @description Perform copy of data from source to target SObject record
    * If the collection size of the source record ids is greater than the threshold size, 
    *   the copy is performed via a batch job
    * @param sourceSObjectType the input source object type
    * @param targetSObjectType the input target object type
    * @param sourceRecordIds - a Collection of record identifiers that belong to the Source SObject Type
    */    
    public static void handleSObjectCopy(String sourceSObjectType, String targetSObjectType, Set<Id> sourceRecordIds){
        Integer THRESHOLD_SIZE = new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_ACCOUNT);
        Integer BATCH_SIZE = new CDdSObjectCopyConfigObj().getBatchSize(SOBJECT_TYPE_ACCOUNT);
        if (sourceRecordIds.size() > THRESHOLD_SIZE){             
            Database.executeBatch(new CDdCopyCustStoreDetailToAccountBatch(sourceSObjectType, sourceRecordIds), BATCH_SIZE);
        } else {
            performCopy(sourceSObjectType, targetSObjectType, sourceRecordIds);
        }            
    }       
    /**
    * @description Perform copy of data from source to target SObject record
    * @param sourceSObjectType the input source object type
    * @param targetSObjectType the input target object type
    * @param sourceRecordIds - a Collection of record identifiers that belong to the Source SObject Type
    */    
    public static void performCopy(String sourceSObjectType, String targetSObjectType, Set<Id> sourceRecordIds){
        CDdSObjectFieldCopyObj fieldCopyObj = new CDdSObjectFieldCopyInitializer(sourceSObjectType).getFieldCopyObj(targetSObjectType);         
        List<sObject> targetRecords = new CDdSObjectFieldCopyProcessor(fieldCopyObj, sourceRecordIds).targetRecords;
        List<String> errorMessages = new List<String>();
        Savepoint savePointBeforeUpdate = Database.setSavepoint();
        try{
            Database.SaveResult[] updateResults = Database.update(targetRecords, false);
            errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
        } catch(Exception ex) {
            Database.rollback(savePointBeforeUpdate);
        }
        if(!errorMessages.isEmpty()){
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdSObjectFieldCopyController');
            throw new CDdSObjectFieldCopyControllerException(errorMessages.get(0));  //throw an exception with the first error message            
        }         
    }   
    private static Set<Id> getSObjectIds(List<Generic_Platform_Event__e> events){
        Set<Id> sObjectIds = new Set<Id>();
        for (Generic_Platform_Event__e event : events) {
            sObjectIds.add(event.sObjectId__c);
        }        
        return sObjectIds;
    }
    /**
    * @description A custom exception is thrown in the event something goes wrong during the processing in the above operations
    **/     
    public class CDdSObjectFieldCopyControllerException extends Exception {}    
}