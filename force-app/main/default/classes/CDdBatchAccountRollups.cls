/**
    * @author Knick
    * @description BZAP-6347---Batch-Rollup-Implementation - Rolls up Account and Lead Data onto Parent Account
    */
    public class CDdBatchAccountRollups Implements Database.Batchable<sObject>, Schedulable {

    public static void execute(SchedulableContext sc) {
        Set<String> runningStatus = new Set<String> {'Holding', 'Processing', 'Queued', 'Preparing'};
        ApexClass thisClass = [SELECT Id FROM ApexClass WHERE Name = 'CDdBatchAccountRollups' LIMIT 1];
        AsyncApexJob[] runningJobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClassId = :thisClass.Id
            AND Status IN :runningStatus
        ];
        if (runningJobs.size() == 0) {
            CDdBatchAccountRollups batch = new CDdBatchAccountRollups();
            Database.executeBatch(batch, CDdCustomMetadata.getBatchSize('CDdBatchAccountRollups'));
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator ql = Database.getQueryLocator([
            SELECT Id, of_child_accounts__c, Leads__c,
                Average_of_Account_nTam__c, Average_of_Lead_nTam__c,
                Highest_Child_Deck_Rank__c, Highest_Lead_Deck_Dank__c,
                Number_of_Stores_Partner__c, Sum_of_NTAM__c, Total_MK_Opps__c,
                of_Accounts_w_nTam__c, of_Leads_w_nTam__c
            FROM Account
            WHERE RecordTypeId = :CDdSchemaUtils.getRecordTypeIdByDeveloperName('Account', 'Parent_Account')
        ]);
        return ql;
    }
    
    public static void execute(Database.BatchableContext BC, List<Account> scope) {

        Set<Id> ParentAccountIDs = new Set<Id>();
        Map<Id, Account> accountToUpdateMap = new Map<Id, Account>();

        for (Account a : scope) { 
            ParentAccountIDs.add(a.Id);
            accountToUpdateMap.put(a.Id, a);
        }

        if (ParentAccountIDs.size() > 0) {

            AggregateResult[] AggregateAccountResults = [
                SELECT ParentId,
                    AVG(Amount__c) avgAmount,
                    SUM(Has_nTam__c) sumNtam,
                    COUNT(Id) countChildren,
                    MIN(Deck_Rank_Number__c) minDeckRankNumber,
                    SUM(Amount__c) sumAmount,
                    SUM(of_CW_MP_Opps__c) sumCwMpOpps,
                    SUM(of_Locations__c) sumLocations
                FROM Account
                WHERE IsDeleted = false AND isPersonAccount = false AND ParentId IN :ParentAccountIDs
                GROUP BY ParentId
            ];

            for (AggregateResult ar : AggregateAccountResults) {
                Account account = accountToUpdateMap.get((Id)ar.get('ParentId'));
                account.Average_of_Account_nTam__c = (Decimal)ar.get('avgAmount');
                account.of_Accounts_w_nTam__c = (Decimal)ar.get('sumNtam');
                account.of_child_accounts__c = (Decimal)ar.get('countChildren');
                account.Highest_Child_Deck_Rank__c = (Decimal)ar.get('minDeckRankNumber');
                account.Sum_of_NTAM__c = (Decimal)ar.get('sumAmount');
                account.Total_MK_Opps__c = (Decimal)ar.get('sumCwMpOpps');
                account.Number_of_Stores_Partner__c = (Decimal)ar.get('sumLocations');
                accountToUpdateMap.put(account.Id, account);
            }

            AggregateResult[] AggregateLeadResults = [
                SELECT Parent_Account__c,
                    MIN(Deck_Rank_Number__c) minDeckRankNumber,
                    AVG(Amount__c) avgAmount,
                    SUM(Has_nTam__c) sumNtam,
                    COUNT(Id) countLeads
                FROM Lead
                WHERE IsDeleted = false AND IsConverted = false AND Parent_Account__c IN :ParentAccountIDs
                AND RecordTypeId = :CDdSchemaUtils.getRecordTypeIdByDeveloperName('Lead', 'Master_Lead')
                GROUP BY Parent_Account__c
            ];

            for (AggregateResult ar : AggregateLeadResults) {
                Account account = accountToUpdateMap.get((Id)ar.get('Parent_Account__c'));
                account.Highest_Lead_Deck_Dank__c = (Decimal)ar.get('minDeckRankNumber');
                account.Average_of_Lead_nTam__c = (Decimal)ar.get('avgAmount');
                account.Leads__c = (Decimal)ar.get('countLeads');
                account.of_Leads_w_nTam__c = (Decimal)ar.get('sumNtam');
                accountToUpdateMap.put(account.Id, account);
            }

            Database.SaveResult[] dbResults = Database.update(accountToUpdateMap.values(),false);

        }
        
    }
    
    public void finish(Database.BatchableContext BC) {}     // Nothing to do in the finish method.

}