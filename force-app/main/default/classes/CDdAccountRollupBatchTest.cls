/**
 * Created by Jeremy Johnson, Perficient, Inc.
 *
 * BZAP-8356: Backfill #Active Child Accounts to Parent Account
 *
 */
@IsTest
public with sharing class CDdAccountRollupBatchTest {

    @IsTest
    public static void testBatch() {
        Account parent = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId());
        insert parent;

        Account child = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId());
        child.ParentId = parent.Id;
        child.Currently_Active__c = 'Yes';
        insert child;

        parent = [select Id, of_Active_Child_Accounts__c from Account where Id = :parent.Id];
        parent.of_Active_Child_Accounts__c = null;
        update parent;

        Test.startTest();
        Database.executeBatch(new CDdAccountRollupBatch(2));
        Test.stopTest();

        Account parentActual = [select Id, of_Active_Child_Accounts__c from Account where Id = :parent.Id];
        System.assertEquals(1, parentActual.of_Active_Child_Accounts__c);
    }
}