@isTest

    /**
    * @author Knick
    * @description BZAP-6347---Batch-Rollup-Implementation - Test Roll up Account and Lead Data onto Parent Account
    */
    public class CDdBatchAccountRollupsTest {

    public static testMethod void doAccountRollupsTest() {
        List<Account> Accounts = TDdAccountFactory.createAccounts('Account ', 2, 'Parent Account');
        List<Account> Children = TDdAccountFactory.createAccounts('Child ', 2);
        List<Lead> Leads = TDdLeadFactory.createLeads('Test Lead ', 2, 'Master Lead', false);
        List<Account> checkAccounts;
        List<Account> checkChildren;
        List<Lead> checkLeads;
        insert Accounts;
        Set<Id> AccountIds = new Set<Id>();
        for (Integer i=1; i<=Accounts.size(); i++) {
            AccountIDs.add(Accounts[i-1].Id);
            Leads[i-1].Store_ID__c = '' +i;
        }
        System.assertEquals(2,AccountIds.size());
        checkAccounts = [
            SELECT Id, Highest_Child_Deck_Rank__c, Average_of_Account_nTam__c, of_child_accounts__c, of_Accounts_w_nTam__c, ParentId
            FROM Account
            WHERE Id IN :AccountIds
        ];
        System.assertEquals(2,checkAccounts.size());
        for (Account a : checkAccounts) {
            system.assertEquals(null, a.Highest_Child_Deck_Rank__c);
            system.assertEquals(null, a.Average_of_Account_nTam__c);
            system.assertEquals(null, a.of_child_accounts__c);
            system.assertEquals(null, a.of_Accounts_w_nTam__c);
        }
        for (Integer i = 0; i < Children.size(); i++) {
            Children[i].ParentId = Accounts[i].Id;
            Children[i].Deck_Rank__c = 'Queen';             // A rank of 5
            Children[i].Amount__c = 200.00;
        }
        system.debug('Inserting: ' + Children);
        insert Children;
        for (Integer i = 0; i < Leads.size(); i++) {
            Leads[i].Deck_Rank__c = 'Queen';                // A rank of 5
            Leads[i].Amount__c = 200.00;
            Leads[i].Parent_Account__c = Accounts[i].Id;
        }
        system.debug('Inserting: ' + Leads);
        insert Leads;
        Set<Id> ChildIds = new Set<Id>();
        for (Account a : Children) ChildIDs.add(a.Id);
        checkChildren = [SELECT Id, ParentId, Deck_Rank__c, Amount__c FROM Account WHERE Id IN :ChildIds];
        system.debug('checkChildren --> ' + checkChildren);
        System.assertEquals(2,checkChildren.size());
        test.startTest();
        CDdBatchAccountRollups batch = new CDdBatchAccountRollups();
        Database.executeBatch(batch, CDdCustomMetadata.getBatchSize('CDdBatchAccountRollups'));
        test.stopTest();
        checkAccounts = [
            SELECT Id, Highest_Child_Deck_Rank__c, Average_of_Account_nTam__c, of_child_accounts__c, of_Accounts_w_nTam__c, ParentId,
                Highest_Lead_Deck_Dank__c, Average_of_Lead_nTam__c, Leads__c, of_Leads_w_nTam__c
            FROM Account
            WHERE Id IN :AccountIds
        ];
        system.debug('checkAccounts --> ' + checkAccounts);
        for (Account a : checkAccounts) {
            system.assertEquals(5, a.Highest_Child_Deck_Rank__c, 'Account --> ' + a);
            system.assertEquals(200.00, a.Average_of_Account_nTam__c, 'Account --> ' + a);
            system.assertEquals(1, a.of_child_accounts__c, 'Account --> ' + a);
            system.assertEquals(1, a.of_Accounts_w_nTam__c, 'Account --> ' + a);
            system.assertEquals(5, a.Highest_Lead_Deck_Dank__c, 'Account --> ' + a);
            system.assertEquals(200.00, a.Average_of_Lead_nTam__c, 'Account --> ' + a);
            system.assertEquals(1, a.Leads__c, 'Account --> ' + a);
            system.assertEquals(1, a.of_Leads_w_nTam__c, 'Account --> ' + a);
        }
    }

}