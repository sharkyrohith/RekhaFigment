/**
 * Created by Jeremy S. Johnson, Perficient, Inc. on 3/14/2020.
 * A window overlay for performing bulk lead conversions from GridBuddy
 */
public with sharing class CDdBulkLeadConvertController {
    public static final String partitionPrefix = 'local.DoorDash.bulkLeadConvert';

    @AuraEnabled
    public static String bulkConvertLeads(String ids, Integer batchSize) {
        Context ctx = new Context(ids);
        ctx.batchId = Database.executeBatch(new CDdBatchLeadConvert(ctx), batchSize);
        Cache.Org.put(partitionPrefix + UserInfo.getUserId(), ctx);
        return ctx.batchId;
    }

    @AuraEnabled
    public static AsyncApexJob getProgress(String batchId) {
        AsyncApexJob job = [
                select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CompletedDate, ExtendedStatus
                from AsyncApexJob where Id =:batchId limit 1];
        return job;
    }

    @AuraEnabled
    public static List<String> getImportMessages() {
        Context ctx = (Context) Cache.Org.get(partitionPrefix + UserInfo.getUserId());
        return ctx.batchMessages;
    }

    public class Context {
        @AuraEnabled public String batchId {get; private set;}
        @AuraEnabled public String userId {get; private set;}
        @AuraEnabled public List<String> ids = new List<String>();
        @AuraEnabled public List<String> batchMessages = new List<String>();
        public Map<Id, Lead> leadMap;
        public Map<Id, Id> accountMap = new Map<Id, Id>();
        public Map<Id, Id> contactMap = new Map<Id, Id>();
        public Map<Id, Id> opportunityMap = new Map<Id, Id>();

        public Context(String idsStr) {
            if(idsStr != null) {
                ids.addAll(idsStr.split(','));
            }
            this.userId = UserInfo.getUserId();
            this.batchMessages = new List<String>();

            leadMap = new Map<Id, Lead>([select Id, Account__c, Parent_Account_ID__c from Lead where Id =: ids]);
        }
    }
}