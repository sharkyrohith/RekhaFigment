@IsTest
public with sharing class CDdS2NBypassToolUploaderContextTest {
    
    @TestSetup
    static void setup(){
        Account testAccount = new Account();
        //testAccount.Name = 'John Doe';
        testAccount.LastName = 'Doe';
        testAccount.FirstName = 'John';
        testAccount.Phone = '855-973-1040';
        testAccount.Restaurant_ID__c = '123456789';
        insert testAccount;
    }

    @IsTest
    static void testValidContext(){
        Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];
        String csv = 'accountId,store_id\n';
        csv += acct.Id + ',' + acct.Restaurant_ID__c;
        
        String msSyncStage = 'Bulk Store Update';
        String reason = 'Testing purpose';
        Boolean overwrite = false;
        String filename = 'filename.csv';

        Test.startTest();
        CDdS2NBypassToolUploaderContext ctx = new CDdS2NBypassToolUploaderContext(csv, UserInfo.getUserId(), msSyncStage, reason, overwrite, filename);
        Test.stopTest();

        System.assertEquals(reason, ctx.reason);
    }
}