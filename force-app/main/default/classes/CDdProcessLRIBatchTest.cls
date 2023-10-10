/**
 * CDdProcessLRIBatchTest
 *
 * @author     Sahil
 * @date  2022-05-31
 * @decription Test class for CDdProcessLRIBatch
 */
@isTest(seeAllData=false)
public with sharing class CDdProcessLRIBatchTest {
    private static List<Case> casesToTest = new List<Case>();
   
    /**
    * @author     Sahil
    * @date  2022-05-31
    * @decription create test data
    * @param   None
    * @return  None
    */
    static {
        casesToTest = TDdCaseFactory.createCaseRecords(2,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        for (Case c : casesToTest) {
            c.Customer_Type__c = 'Dasher';
        }
        insert casesToTest;
        System.assertEquals(2, casesToTest.size(), '2 test cases should be inserted');
    }

     /**
    * @author     Sahil
    * @date  2022-05-31
    * @decription test batch execution
    * @param   None
    * @return  None
    */
    @isTest
    static void testBatchPositive() {
        Load_Request_Item__c lriObj = new Load_Request_Item__c();
        lriObj.UUID__c = casesToTest[0].Id;
        lriObj.Issue_Type__c = 'Other - DX';
        lriObj.Issue__c = 'Other';
        lriObj.Resolution__c = 'Other';
        lriObj.Resolution_Category__c = 'Other - DX';
        lriObj.Send_Email__c = true;
        lriObj.Case_Status__c = 'Closed';
        lriObj.Email_Body__c = 'Hello {!Case_Contact.Name}';
        lriObj.Operation__c = CDdSupportConstants.OPERATION_CASE_UPDATES;
        lriObj.Status__c = 'New';
        insert lriObj;

        Test.startTest();
        Database.executeBatch(new CDdProcessLRIBatch(CDdSupportConstants.OPERATION_CASE_UPDATES));
        Test.stopTest();
        List<Load_Request_Item__c> lriFromDB = [SELECT Status__c FROM Load_Request_Item__c];
        System.debug(lriFromDB);
        System.assertEquals('Completed', lriFromDB[0].Status__c, 'Staging record status should be Completed');
    }

     /**
    * @author     Sahil
    * @date  2022-05-31
    * @decription test batch execution
    * @param   None
    * @return  None
    */
    @isTest
    static void testBatchNegative() {
        Load_Request_Item__c lriObjError = new Load_Request_Item__c();
        lriObjError.UUID__c = casesToTest[1].Id;
        lriObjError.Issue_Type__c = 'Other - DX';
        lriObjError.Issue__c = 'Other - DX';
        lriObjError.Resolution__c = 'Other - DX';
        lriObjError.Resolution_Category__c = 'Other - DX';
        lriObjError.Send_Email__c = true;
        lriObjError.Case_Status__c = 'Closed';
        lriObjError.Email_Body__c = 'Hello {!Case_Contact.Name}';
        lriObjError.Operation__c = CDdSupportConstants.OPERATION_CASE_UPDATES;
        lriObjError.Status__c = 'New';
        insert lriObjError;

        Test.startTest();
        Database.executeBatch(new CDdProcessLRIBatch(CDdSupportConstants.OPERATION_CASE_UPDATES));
        Test.stopTest();
        List<Load_Request_Item__c> lriFromDB = [SELECT Status__c FROM Load_Request_Item__c];
        System.assertEquals('Error', lriFromDB[0].Status__c, 'Staging record status should be Error');
    }

      /**
    * @author     Sahil
    * @date  2022-05-31
    * @decription test batch scheduler
    * @param   None
    * @return  None
    */
    @isTest
    static void testScheduler() {
        String cronExp = '0 0 0 15 3 ? 2099';
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', cronExp, new CDdProcessLRIScheduler());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression, 'batch has not been scheduled correctly. Check cron expression');
    }
}