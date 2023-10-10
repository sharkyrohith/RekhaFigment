/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 12/21/2020
*
* @group Nimda Bulk Bypass Tool
*
* @description Bypass Bulk Store Update Batch Job
* 
**************************************************************************************************************************************/
public class CDdBypassBulkStoreUpdateBatch implements Database.Batchable<Map<String, Object>>, Database.Stateful, Database.AllowsCallouts {
    // Instance level variables are defined here
    private static String CLASS_NAME = 'CDdBypassBulkStoreUpdateBatch';
    private static final String BATCH_SIZE = Label.Bypass_Bulk_Store_Update_Batch_Size;
    private String batchJobId;
    private static List<String> errorMessages = new List<String>();
    private Map<String, String> storeIdToAccountIdMap;
    private List<Map<String, Object>> storesToUpdate {get; set;}
    private String reason;
    private String exceptionMessage = null;
    /**
    * @description Batch job constructor method
    * @param Database.BatchableContext bctx
    * @param String reason    
    **/
    public CDdBypassBulkStoreUpdateBatch(List<Map<String, Object>> storesToUpdate, String reason){
        this.storesToUpdate = storesToUpdate;
        this.reason = reason;
    }
    /**
    * @description Batch job execute method implementation
    * @param Database.BatchableContext bctx
    * @return Iterable<Map<String, Object>> List collection of object of type Map<String, Object>
    **/
    public Iterable<Map<String, Object>> start(Database.BatchableContext bctx) {
        setBatchJobId(bctx.getJobId());
        this.handleUpdateToBulkStoreUpdateRequestObj(this.storesToUpdate);
        this.setStoreIdToAccountIdMap(this.storesToUpdate);
        return this.storesToUpdate;
    }
    /**
    * @description Batch job execute method implementation
    * @param Database.BatchableContext bctx
    * @param List<Map<String, Object>> scope records    
    * @return 
    **/
    public void execute(Database.BatchableContext bctx, List<Map<String, Object>> scope) {
        if (!Test.isRunningTest()){
            this.handleCalloutToBulkStoreUpdateApi(scope);
        }
    }
    /**
    * @description Batch job finish method implementation
    * @param Database.BatchableContext bctx
    * @return 
    **/
    public void finish(Database.BatchableContext bctx) {
        this.handleFinish();
    }
    /**
    * @description Persist the batch job id at the instance level
    * @param String batchJobId
    * @return 
    **/
    @TestVisible
    private void setBatchJobId(String batchJobId){
        this.batchJobId = batchJobId;
    }
    /**
    * @description Persist the batch job id at the instance level
    * @param List<Map<String, Object>> scope records   
    * @return 
    **/
    @TestVisible
    private void setStoreIdToAccountIdMap(List<Map<String, Object>> scope){
        this.storeIdToAccountIdMap = new Map<String, String>();
        for (Map<String, Object> storeToUpdate : scope){
            this.storeIdToAccountIdMap.put(
                (String)storeToUpdate.get(CDdBypassBulkStoreUpdateConstants.PROPERTY_STORE_ID),
                (String)storeToUpdate.get(CDdBypassBulkStoreUpdateConstants.PROPERTY_ACCOUNT_ID)
            );
        }
    }        
    /**
    * @description Handle updates to Bulk Store Update Request Object
    * @param List<Map<String, Object>> scope records
    * @return 
    **/ 
    @TestVisible
    private void handleUpdateToBulkStoreUpdateRequestObj(List<Map<String, Object>> scope){
        try {
            for (Map<String, Object> storeToUpdate : scope){
                if (String.isBlank(this.reason)){
                    exceptionMessage = String.format(CDdBypassBulkStoreUpdateConstants.ERROR_MSG_MISSING_PROPERTY, new List<String>{CDdBypassBulkStoreUpdateConstants.PROPERTY_REASON});
                }                 
                if (!storeToUpdate.containsKey(CDdBypassBulkStoreUpdateConstants.PROPERTY_STORE_ID)){
                    exceptionMessage = String.format(CDdBypassBulkStoreUpdateConstants.ERROR_MSG_MISSING_PROPERTY, new List<String>{CDdBypassBulkStoreUpdateConstants.PROPERTY_STORE_ID});
                }
                if (!storeToUpdate.containsKey(CDdBypassBulkStoreUpdateConstants.PROPERTY_ACCOUNT_ID)){
                    exceptionMessage = String.format(CDdBypassBulkStoreUpdateConstants.ERROR_MSG_MISSING_PROPERTY, new List<String>{CDdBypassBulkStoreUpdateConstants.PROPERTY_ACCOUNT_ID});
                }
                if (String.isNotBlank(exceptionMessage)){
                    throw new CDdBypassBulkStoreUpdateBatchException(exceptionMessage);
                }                
                storeToUpdate.put(CDdBypassBulkStoreUpdateConstants.PROPERTY_OWNER_ID, UserInfo.getuserId());
                storeToUpdate.put(CDdBypassBulkStoreUpdateConstants.PROPERTY_ORIGIN, CDdBypassBulkStoreUpdateConstants.BYPASS_BULK_STORE_UPDATE_ORIGIN);
                storeToUpdate.put(CDdBypassBulkStoreUpdateConstants.PROPERTY_REASON, this.reason);
            }
        } catch(CDdBypassBulkStoreUpdateBatchException bpEx){
            this.exceptionMessage = bpEx.getMessage();
            throw bpEx;
        } finally {
            if (String.isNotBlank(this.exceptionMessage)){
                this.handleFinish();
            }
        }        
    }
    /**
    * @description Handle callout to Bulk Store Update API (MuleSoft)
    * @param List<Map<String, Object>> scope records
    * @return 
    **/ 
    @TestVisible
    private void handleCalloutToBulkStoreUpdateApi(List<Map<String, Object>> scope) {
        try {
            DateTime lastModifiedDateTime = Datetime.now();
            List<Account> accountsToUpdate = new List<Account>();
            List<Map<String,String>> responseObj = (List<Map<String,String>>)JSON.deserialize(new CDdNimdaSyncMSService().bulkUpdateStore(scope), List<Map<String,String>>.class);
            for (Map<String,String> storeUpdateResponse : responseObj){
                String storeId = (String)storeUpdateResponse.get(CDdBypassBulkStoreUpdateConstants.PROPERTY_STORE_ID);
                String accountId = this.storeIdToAccountIdMap.get(storeId);
                String responseMessage = (String)storeUpdateResponse.get(CDdBypassBulkStoreUpdateConstants.RESPONSE_PROPERTY_STATUS);
                String stage = CDdBypassBulkStoreUpdateConstants.MS_SYNC_STAGE_BYPASS_BULK_STORE_UPDATE;
                String status = responseMessage.contains(CDdBypassBulkStoreUpdateConstants.RESPONSE_STRING_SUCCESSFUL) ? CDdBypassBulkStoreUpdateConstants.MS_SYNC_STATUS_SUCCESS : CDdBypassBulkStoreUpdateConstants.MS_SYNC_STATUS_ERROR;
                String errorMessage = responseMessage.contains(CDdBypassBulkStoreUpdateConstants.RESPONSE_STRING_SUCCESSFUL) ? null : responseMessage;
                accountsToUpdate.add(
                    new Account(
                        Id = accountId,
                        MS_Sync_Stage__c = stage,
                        MS_Sync_Status__c = status,
                        MS_Error_Message__c = errorMessage,
                        Bulk_Tool_Batch_Id__c = this.batchJobId,
                        Bulk_Tool_User__c = UserInfo.getUserId(),
                        Bulk_Tool_Last_Modified__c = lastModifiedDateTime
                    )
                );
            }
            update accountsToUpdate;
        } catch(CDdNimdaSyncMSService.CDdNimdaSyncMSServiceException msEx){
            this.exceptionMessage = msEx.getMessage();
            CDdNimdaSyncMSService.CDdNimdaSyncMSExceptionData data = (CDdNimdaSyncMSService.CDdNimdaSyncMSExceptionData)JSON.deserialize(msEx.getMessage(), CDdNimdaSyncMSService.CDdNimdaSyncMSExceptionData.class);
            throw new CDdBypassBulkStoreUpdateBatchException(data.calloutResponse);
        } catch(System.DmlException dmlEx){
            this.exceptionMessage = dmlEx.getMessage();
            throw dmlEx;            
        } finally {
            if (String.isNotBlank(this.exceptionMessage)){
                this.handleFinish();
            }
        }
    }    
    /**
    * @description Batch job - handle finish method implementation 
    *   Write to log record in the event of failure
    *   Insert chatter post
    *   Notify user via e-mail regarding the status of the job 
    * @param
    * @return 
    **/ 
    @TestVisible
    private void handlefinish() {
        if (String.isNotBlank(this.exceptionMessage)){
            Apex_Log__c log = new Apex_Log__c(Class_Name__c = CLASS_NAME, Reference_Id__c = this.batchJobId, Log__c = exceptionMessage);
            insert log;
        }
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CompletedDate, ExtendedStatus, CreatedBy.Email
                            FROM AsyncApexJob WHERE Id = :this.batchJobId];        
        String body = ''
                + (String.isNotBlank(this.exceptionMessage) ?
                    'Your bulk import request encountered errors. Please correct the errors and try again.' :
                    'Your bulk import request has been sent to MuleSoft for processing.')
                + '\n   Action Type : ' + CDdBypassBulkStoreUpdateConstants.MS_SYNC_STAGE_BYPASS_BULK_STORE_UPDATE
                + '\n   Job Id : ' + job.Id
                + '\n   Completed Date : ' + job.CompletedDate
                + '\n   Items Processed : ' + job.JobItemsProcessed
                + '\n   Number of Errors : ' + job.NumberOfErrors
                + '\n   Total Items : ' + getTotalItems(job.TotalJobItems)
                + (job.ExtendedStatus == null ? '' : '\n   Extended Status : ' + job.ExtendedStatus);
        // Insert chatter post
        FeedItem post = new FeedItem();
        post.ParentId = UserInfo.getUserId();
        post.Body = '\n' + exceptionMessage;
        insert post;
        // Notify user via e-mail regarding the status of the job 
        try {
            User user = [select Email from User where Id = :UserInfo.getUserId()];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.toAddresses = new String[] { user.Email };
            email.subject = CDdBypassBulkStoreUpdateConstants.MS_SYNC_STAGE_BYPASS_BULK_STORE_UPDATE + ' Results';
            email.optOutPolicy = 'FILTER';
            email.plainTextBody = body;
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
        }                
    }
    /**
     * @description Gets total numbers of records processed by multiplying
     * number of batches by batch size:
     * 10 batches, each batch processed 5 records - 10 x 5 = 50
     */
    @TestVisible
    private Integer getTotalItems(Integer batchesProcessed) {
        Integer batchSize = 0;
        try {
            if (Test.isRunningTest()) {
                batchSize = 2;
            } else {
                batchSize = Integer.valueOf(BATCH_SIZE);
            }
        } catch (Exception e) {
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBypassBulkStoreUpdateBatch',
                                             'getTotalItems', LoggingLevel.ERROR);
        }
        return batchesProcessed * batchSize;
    }
    /**
    * @description Custom Exception for the batch job
    **/ 
    public class CDdBypassBulkStoreUpdateBatchException extends Exception {}
}