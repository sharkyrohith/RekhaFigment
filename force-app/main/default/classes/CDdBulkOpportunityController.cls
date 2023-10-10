/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
*
 * Implements BZAP-7037: "Bulk Creation Opportunities" button and batch job
 * Implements BZAP-7046: Batch Job "Retry" Process and GridBuddy button
  */

public with sharing class CDdBulkOpportunityController {
    private static final String partitionPrefix = 'local.DoorDash.bo';

    @AuraEnabled
    public static String execute(String oppId, String accountIds) {
        List<String> accountList = new List<String>();
        accountList.addAll(accountIds.split(','));

        Context ctx = new Context(getSourceOpp(oppId), accountList);
        ctx.opps = clone(ctx);
        ctx.batchId = Database.executeBatch(new CDdBatchOpportunity(ctx), Integer.valueOf(Label.DDBulkOpportunityBatchSize));
        Cache.Org.put(partitionPrefix + UserInfo.getUserId(), ctx);
        return ctx.batchId;
    }

    private static Opportunity getSourceOpp(String oppId) {
        Map<String, Schema.SObjectField> fields = Opportunity.SObjectType.getDescribe().fields.getMap();

        //Retrieve all updateable fields
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            DescribeFieldResult describe = field.getDescribe();
            if (describe.isUpdateable()) {
                fieldNames.add(describe.name);
            }
        }

        String soql = 'select ' + String.join(fieldNames, ', ') + ' from Opportunity where Id = \'' + oppId + '\'';
        Opportunity sourceOpp = Database.query(soql);

        return sourceOpp;
    }

    private static List<Opportunity> clone(Context ctx) {
        List<Account> accounts = [select Id, Name, Decision_Maker__c from Account where Id =: ctx.accountIds];
        List<Opportunity> opps = new List<Opportunity>();

        Datetime dt = System.today();
        for(Account account : accounts) {
            Opportunity opp = ctx.sourceOpp.clone();
            opp.AccountId = account.Id;
            opp.Contract_Signed_Date__c = null;
            opp.Decision_Maker__c = account.Decision_Maker__c;
            opp.Docusign_Sent__c = null;
            opp.Enterprise_Type__c = 'Franchise';
            opp.Marketplace_Contract_Link__c = null;
            opp.Merchant_Supplied_ID__c = null;
            opp.Name = account.Name + ' - Franchise ' + ctx.sourceOpp.Type + ' - ' + dt.format('YYYY-MM-dd');
            // Tia Xuan 09/2020 BZAPSUP-484 Switch references of "Number_of_Stores__c" in apex classes
            opp.of_Addressable_Locations__c = null;
            opp.PactSafe_Contract_Type__c = ctx.contractType;
            opp.Parent_Opportunity__c = ctx.sourceOpp.Id;
            opp.RecordTypeId = ctx.recordTypeId;
            opp.StageName = 'New';
            opps.add(opp);
        }

        return opps;
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
        @AuraEnabled public List<String> batchMessages = new List<String>();
        public List<Opportunity> opps = new List<Opportunity>();
        public List<String> oppIds = new List<String>();
        public String batchId;
        public final Id recordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId();
        public final List<String> accountIds;
        public final Opportunity sourceOpp;
        public final String contractType = 'Franchisee Opt-Out Addendum';
        public final String userId;

        public Context(Opportunity sourceOpp, List<String> accountIds) {
            this.sourceOpp = sourceOpp;
            this.accountIds = accountIds;
            this.userId = UserInfo.getUserId();
        }
    }
}