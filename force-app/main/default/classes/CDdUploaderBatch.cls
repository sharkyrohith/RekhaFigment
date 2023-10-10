/**
 * Created by Jeremy S. Johnson, Perficient Inc., 1/27/2020.
 *
 *
 * Updates a hybrid List of related SObjects and sends Platform Events in a semi-atomic fashion:
 * a child will not be updated if the parent fails, and a Platform Event will not be sent if either
 * the parent or child fail. However, a parent object may succeed while the child object fails if
 * they are not in the same scope. For the same reason, a Platform Event may fail after the parent
 * and child succeeded.
 *
 * CDdUploaderContext.updateListByType: contains a hybrid List of SObjects to be updated, sorted by type.
 * SObjects must be sorted by type to optimize chunking:
 *
 *    "Records for multiple object types are broken into multiple chunks by Salesforce.
 *     A chunk is a subset of the input array, and each chunk contains records of one object type.
 *     Data is committed on a chunk-by-chunk basis...[and is limited to] 10 chunks in hybrid arrays."
 *
 *      @see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_dml_limitations.htm
 *
 * CDdUploaderContext.updateListByGroup: contains a Map of related SObjects and is used
 * to send Platform Events. Objects are removed from the Map if the DML update fails.
*/
public with sharing class CDdUploaderBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private CDdUploaderContext ctx;
    private CDdUploaderHelper helper = new CDdUploaderHelper();

    public CDdUploaderBatch(CDdUploaderContext ctx) {
        this.ctx = ctx;
    }

    /**
     * Retrieve the list of SObjects from CDdUploaderContext.updateListByType and
     * add job control values to each.
     *
     * @param bctx Database.BatchableContext
     * @return Iterable<sObject>
     */
    public Iterable<SObject> start(Database.BatchableContext bctx) {
        if (!Test.isRunningTest() && MSSyncStage.FullOnboardingCreate.equals(CDdS2NUtil.msSyncStageFromString(ctx.msSyncStageStr))) {
            helper.createBusiness(bctx.getJobId(), 
                                helper.getParentAccounts(ctx.updateListByGroup.keySet(),
                                                        CDdUploaderConstants.BULK_UPLOADER_CREATE_BIZ_MIN_CHILDCOUNT));
        }         
        Datetime now = Datetime.now();
        for (SObject obj : ctx.updateListByType) {
            obj.put('Bulk_Tool_Batch_Id__c', bctx.getJobId());
            obj.put('Bulk_Tool_User__c', ctx.userId);
            obj.put('Bulk_Tool_Last_Modified__c', now);
        }

        return ctx.updateListByType;
    }

    /**
     * Save parent/child objects separately. Remove child objects if parent fails.
     *
     * @param bctx Database.BatchableContext
     * @param objects A List of hybrid SObjects
    */
    public void execute(Database.BatchableContext bctx, List<SObject> objects) {
        Map<String, List<SObject>> objectMap = groupObjectsForUpdate(objects);
        for (String objectName : objectMap.keySet()) {
            List<SObject> objectSubset = objectMap.get(objectName);
            Boolean isChild = ctx.isCompositeUpdate && !'Account'.equals(objectName);
            if (isChild) {
                removeChildObjects(ctx, objectSubset);
            }
            Database.SaveResult[] resultList = Database.update(objectSubset, false);
            processResults(ctx, resultList, objectSubset, isChild);
        }
    }

    /**
     * Add errors to ctx.batchErrors and remove objects from the Platform Event map.
     *
     * @param ctx CDdUploaderContext
     * @param results List of Database.SaveResults
     * @param objects A subset of objects updated by execute()
     * @param isChild Whether this list contains child objects
    */
    private void processResults(CDdUploaderContext ctx, List<Database.SaveResult> results, List<SObject> objects, Boolean isChild) {
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];

            if (!result.isSuccess()) {
                removeObjectForEvents(objects[i], isChild);

                for (Database.Error error : result.getErrors()) {
                    String errorMsg = String.format('{0}.Id: {1}: {2}', new List<Object> { objects.get(i).getSObjectType(), objects.get(i).Id, error.getMessage() });
                    ctx.batchErrors.add(errorMsg);
                    System.debug('CDdUploaderBatch.processResults, error: ' + errorMsg);
                }
            }
        }
        ctx.recordsProcessed += objects.size();
    }

    /**
     * Group objects by type for updates
     *
     * @param objects A hybrid list of SObjects to update
     * @return Map<String, List<SObject>>
    */
    private Map<String, List<SObject>> groupObjectsForUpdate(List<SObject> objects) {
        Map<String, List<SObject>> allObjects = new Map<String, List<SObject>>();
        for (SObject obj : objects) {
            String objectName = obj.getSObjectType().getDescribe().getName();
            if (allObjects.keySet().contains(objectName)) {
                allObjects.get(objectName).add(obj);
            } else {
                allObjects.put(objectName, new List<SObject> { obj });
            }
        }
        return allObjects;
    }

    /**
     * Remove child objects if the parent object failed.
     *
     * @param ctx CDdUploaderContext
     * @param childObjects A list of child objects
    */
    public void removeChildObjects(CDdUploaderContext ctx, List<SObject> childObjects) {
        for (Integer i = 0; i < childObjects.size(); i++) {
            Id accountId = (Id) childObjects[i].get('AccountId');
            if (!ctx.updateListByGroup.containsKey(accountId)) {
                removeObjectForEvents(childObjects[i], true);
                childObjects.remove(i);
            }
        }
    }

   /**
    * Remove an object from the Context.updateListByGroup Map of Maps so Platform Events
    * are not generated for them.
    *
    * If this object is a parent, it's children are also removed. Otherwise just the given object
    * is removed.
    *
    * @param obj The object to remove
    * @param isChild Whether this is a child in a composite update
    */
    public void removeObjectForEvents(SObject obj, Boolean isChild) {
        Id id = (Id) obj.get('Id');

        if (isChild) { // Remove this object from the inner Map
            Id accountId = (Id) obj.get('AccountId');
            if (ctx.updateListByGroup.containsKey(accountId)) {
                ctx.updateListByGroup.get(accountId).remove(id);
            }
        } else { // Remove this object from the outer Map. Related objects are also removed.
            ctx.updateListByGroup.remove(id);
        }
    }

    /**
     * Send onboarding events after DML updates and notify user of the outcome. Platform
     * Event errors are added to CDdUploaderContext.batchErrors.
     *
     * @param bctx Database.BatchableContext
     */
    public void finish(Database.BatchableContext bctx) {

        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CompletedDate, ExtendedStatus, CreatedBy.Email
                            FROM AsyncApexJob WHERE Id =: bctx.getJobId()];

        CDdS2NUtil.sendEvents(ctx);

        String body = ''
                + (ctx.batchErrors.size() > 0 ?
                    'Your bulk import request encountered errors. Please correct the errors and try again.' :
                    'Your bulk import request has been sent to MuleSoft for processing.')
                + '\n   Filename : ' + ctx.filename
                + '\n   Action Type : ' + ctx.msSyncStageStr
                + '\n   Job Id : ' + job.Id
                + '\n   Completed Date : ' + job.CompletedDate
                + '\n   Records Processed : ' + ctx.recordsProcessed
                + '\n   Items Processed : ' + job.JobItemsProcessed
                + '\n   Number of Errors : ' + job.NumberOfErrors
                + '\n   Total Items : ' + job.TotalJobItems
                + (job.ExtendedStatus == null ? '' : '\n   Extended Status : ' + job.ExtendedStatus);

        FeedItem post = new FeedItem();
        post.ParentId = ctx.userId;
        post.Body = body;
        insert post;

        for (String error : ctx.batchErrors) {
            body += '\n' + error;
        }

        try {
            User user = [select Email from User where Id =: ctx.userId];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.toAddresses = new String[] { user.Email };
            email.subject = 'Bulk Uploader Results';
            email.optOutPolicy = 'FILTER';
            email.plainTextBody = body;
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
        }

        Cache.Org.put(ctx.partitionKey(), ctx);
    }

    /**
     * A testable method that enables caching of CDdUploaderContext without executing the batch.
    */
    @TestVisible
    private void finish() {
        Cache.Org.put(ctx.partitionKey(), ctx);
    }
}