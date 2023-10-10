/**
* @author Tia Xuan  
* @date 08-2021
*
* @description Test class for PII 
*/
@isTest
public class CDdPIITest {

    /**
    * @description Test Batch
    */
    @isTest 
    static void testBatch() {
        List<Account> testAccounts = TDdAccountFactory.createAccounts('Test Consumer', 1, 'Consumer or Dasher');
        testAccounts[0].CustomerNo__pc = 123;
        insert testAccounts;

        testAccounts[0].LastName = 'test';
        update testAccounts;

        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].AccountId = testAccounts[0].Id;
        insert caseList;
        
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.RelatedToId = testAccounts[0].Id; 
        insert email;

        Test.startTest();

        Privacy_Service__c ps = new Privacy_Service__c();
        ps.Action_ID__c = 'BIZAPPS_FORGET';
        ps.Profile_Type__c = 'Consumer';
        ps.User_Id__c = 123;
        ps.Status__c = 'New';
        ps.Request_ID__c = 'test';
        insert ps;

        List<Privacy_Service_Task__c> pstList = [select Id 
                                                from Privacy_Service_Task__c 
                                                where Privacy_Service__c =: ps.Id
                                                    and Object_Name__c !=  'EmailMessage'];
        for (Privacy_Service_Task__c pst : pstList){
            pst.Status__c = CDdPIIHelper.COMPLETED_STATUS;
        }
        update pstList;

        CDdPIITaskBatch batch = new CDdPIITaskBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        pstList = [ select Id 
                    from Privacy_Service_Task__c 
                    where Privacy_Service__c =: ps.Id
                        and Status__c =: CDdPIIHelper.COMPLETED_STATUS];
        
        System.assert(pstList.size()> 0, 'A privacy Service task must be complete');
    }

    /**
    * @description Test Sched
    */
    @isTest 
    static void testSched() {
        Support_Settings__c sSetting = Support_Settings__c.getInstance();
        sSetting.PII_Batch_Interval__c = 0;
        insert sSetting;

        List<Account> testAccounts = TDdAccountFactory.createAccounts('Test Consumer', 1, 'Consumer or Dasher');
        testAccounts[0].CustomerNo__pc = 123;
        insert testAccounts;

        testAccounts[0].LastName = 'test';
        update testAccounts;

        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].AccountId = testAccounts[0].Id;
        insert caseList;

        Test.startTest();

        Privacy_Service__c ps = new Privacy_Service__c();
        ps.Action_ID__c = 'BIZAPPS_FORGET';
        ps.Profile_Type__c = 'Consumer';
        ps.User_Id__c = 123;
        ps.Status__c = 'New';
        ps.Request_ID__c = 'test';
        insert ps;

        SchedulableContext sc;
        CDdPIITaskSched tstCls = new CDdPIITaskSched();
        tstCls.execute(sc);

        Test.stopTest();
        
        List<Privacy_Service_Task__c> pstList = [select Id 
                                                from Privacy_Service_Task__c 
                                                where Privacy_Service__c =: ps.Id
                                                    and Status__c =: CDdPIIHelper.COMPLETED_STATUS];
        
        System.assert(pstList.size()> 0, 'A privacy Service task must be complete');
    }


    /**
    * @description Test Batch complete
    */
    @isTest 
    static void testBatchComplete() {
        List<Account> testAccounts = TDdAccountFactory.createAccounts('Test Consumer', 1, 'Consumer or Dasher');
        testAccounts[0].CustomerNo__pc = 123;
        testAccounts[0].PersonHomePhone =  '123';
        insert testAccounts;

        testAccounts[0].PersonHomePhone =  '1233467';
        update testAccounts;

        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].AccountId = testAccounts[0].Id;
        insert caseList;

        Privacy_Service__c ps = new Privacy_Service__c();
        ps.Action_ID__c = 'BIZAPPS_FORGET';
        ps.Profile_Type__c = 'Consumer';
        ps.User_Id__c = 123;
        ps.Status__c = CDdPIIHelper.NEW_STATUS;
        ps.Request_ID__c = 'test';
        insert ps;

        Test.startTest();

        List<Privacy_Service_Task__c> pstList = [select Id,  Object_Name__c, Status__c
                                                from Privacy_Service_Task__c 
                                                where Privacy_Service__c =: ps.Id];
        for (Privacy_Service_Task__c tsk : pstList){
            tsk.Status__c = CDdPIIHelper.COMPLETED_STATUS;
        }
        update pstList;

        ps = [  select Id, Status__c 
                from Privacy_Service__c
                where Id = : ps.Id];
    
        System.assert(ps.Status__c == CDdPIIHelper.COMPLETED_STATUS, 'Privacy Service not complete');

        ps.Status__c = CDdPIIHelper.NEW_STATUS;
        update ps;

        for (Privacy_Service_Task__c tsk : pstList){
            if (tsk.Object_Name__c == 'Contact'){
                tsk.Status__c = CDdPIIHelper.NEW_STATUS;
            }
        }
        update pstList;

        CDdPIITaskBatch batch = new CDdPIITaskBatch();
        Database.executeBatch(batch);

        Test.stopTest();
        
        pstList = [ select Id 
                    from Privacy_Service_Task__c 
                    where Privacy_Service__c =: ps.Id
                        and Status__c =: CDdPIIHelper.NEW_STATUS];
        
        System.assert(pstList.size() == 0, 'A new privacy Service task exists');
    }

     /**
    * @description Test Batch
    */
    @isTest 
    static void testBatchRetries() {
        Support_Settings__c sSetting = Support_Settings__c.getInstance();
        sSetting.Max_RTF_Retries__c = 1;
        insert sSetting;

        Test.startTest();

        Privacy_Service__c ps = new Privacy_Service__c();
        ps.Action_ID__c = 'BIZAPPS_FORGET';
        ps.Profile_Type__c = 'Consumer';
        ps.User_Id__c = 123;
        ps.Status__c = 'New';
        ps.Request_ID__c = 'test';
        insert ps;

        List<Privacy_Service_Task__c> pstList = [select Id 
                                                from Privacy_Service_Task__c 
                                                where Privacy_Service__c =: ps.Id];
        for (Privacy_Service_Task__c pst : pstList){
            pst.Retries__c = null;
        }
        update pstList;

        CDdPIITaskBatch batch = new CDdPIITaskBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        pstList = [ select Id, Retries__c
                    from Privacy_Service_Task__c 
                    where Privacy_Service__c =: ps.Id
                        and Status__c =: CDdPIIHelper.NEW_STATUS];
        
        System.assert(pstList.size()> 0, 'An error privacy Service task must exist');

    }

    /**
    * @description Test Batch empty
    */
    @isTest 
    static void testBatchEmpty() {
        Test.startTest();
        CDdPIITaskBatch batch = new CDdPIITaskBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assertEquals(null, batch.qry, 'No query expected');
    }
}