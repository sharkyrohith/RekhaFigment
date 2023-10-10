/**
 * Created by Jeremy S. Johnson, Perficient Inc., 1/27/2020.
 *
 * Controller for the Mulesoft Bulk Uploader tool. Supports uploading and importing
 * a CSV file for bulk updating Salesforce and Send to Nimda.
 *
 * The uploaded file is constrained to fields defined in Uploader_Field_Map__mdt.
 * For each record, Account.MS_Sync_Stage__c and Opportunity.MS_Sync_To_DD__c (if applicable)
 * are set, updates are performed, and Store_Onboarding_Event__e / Store_Update_Event__e
 * events are generated, based on the actionType.
 *
 * Minimal validation is performed, including required Account.Id, Opportunity.Id, and
 * data type conversions. Any additional validations are delegated to the user's profile,
 * validation rules, Mulesoft, etc.
 */

public with sharing class CDdUploaderController {
    /**
     * Take the provided csvStr, parse it, create a CDdUploaderContext object,
     * validate the CSV, store the context object in Platform Cache, and return the context object.
     *
     * @param csv CSV file represented as a String
     * @param userId User Id
     * @param msSyncStage Mulesoft Sync type
     * @param filename Uploaded filename
     * @return CDdUploaderContext - a context object holding intermediate calculations
     */
    @AuraEnabled
    public static CDdUploaderContext uploadCsv(String csv, String userId, String msSyncStage, String filename) {
        CDdUploaderHelper helper = new CDdUploaderHelper();
        CDdUploaderContext ctx = new CDdUploaderContext(csv, userId, msSyncStage, filename);
        helper.uploadCsv(ctx);

        //Minimize what's cached. Maximum size of a single cached item (for put() methods) is 100KB
        CDdUploaderContext ctxMinimized = ctx.clone();
        ctxMinimized.csvRaw = null;
        ctxMinimized.csv = null;
        Cache.Org.put(ctxMinimized.partitionKey(), ctxMinimized);

        //Minimize what's returned to UI
        ctx.csvRaw = null;
        ctx.updateListByType = null;
        ctx.updateListByGroup = null;

        return ctx;
    }

    /**
     * Retrieve the CDdUploaderContext from cache and submit it for batch processing.
     *
     * @param userId The user Id
     * @param batchSize The batch size
     * @return batchId
     */
    @AuraEnabled
    public static String importCsv(String userId, Integer batchSize) {
        CDdUploaderContext ctx = (CDdUploaderContext) Cache.Org.get(CDdUploaderContext.partitionPrefix + userId);
        return importCsv(userId, batchSize, ctx);
    }

    /**
     * Testable version to enable injecting changes to CDdUploaderContext
     *
     * @param userId User Id
     * @param batchSize Batch size
     * @param ctx Execution context
     * @return batchId
     */
    @TestVisible
    private static String importCsv(String userId, Integer batchSize, CDdUploaderContext ctx) {
        if(ctx.isImportable) {
            //ctx.batchId = ctx.enableAtomicUpdates ?  System.enqueueJob(new CDdUploaderJob(ctx)) : Database.executeBatch(new CDdUploaderBatch(ctx), batchSize);
            ctx.batchId = Database.executeBatch(new CDdUploaderBatch(ctx), batchSize);
        } else {
            ctx.batchErrors.add('Invalid attempt to import an unimportable file');
            insert new Apex_Log__c(Class_Name__c = 'CDdUploaderController', Method_Name__c = 'importCsv', Log_Level__c = 'Error', Log__c = 'Invalid attempt to import an unimportable file');
        }
        return ctx.batchId;
    }

    @AuraEnabled
    public static String helpText() {
        String helpText = '';

        for(Uploader_Field_Map__mdt mdt : CDdS2NUtil.getFieldMap().values()) {
            helpText += String.format('<p>{0}.{1}: {2}</p>', new List<String> { mdt.Object__c, mdt.Field__c, mdt.Type__c });
        }

        return helpText;
    }

    @AuraEnabled
    public static AsyncApexJob getProgress(String batchId) {
        return [select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CompletedDate, ExtendedStatus
        from AsyncApexJob where Id = :batchId limit 1];
    }

    @AuraEnabled
    public static List<String> getImportMessages(String userId) {
        CDdUploaderContext uploaderCtx = (CDdUploaderContext) Cache.Org.get(CDdUploaderContext.partitionPrefix + userId);
        List<String> batchErrors = uploaderCtx.batchErrors.clone();
        uploaderCtx.batchErrors.clear();
        Cache.Org.put(CDdUploaderContext.partitionPrefix + userId, uploaderCtx);
        return batchErrors;
    }
}