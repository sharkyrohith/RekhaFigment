/**
* @author Tia Xuan
* @date 2019-04
*
* @description Test class for CDdBatchCaseToSolved
*/

@isTest
public class CDdBatchCaseToSolvedTest {
    /**
    * @description else condition
    */
    @isTest static void testBatch() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].Origin = 'Dasher Apply';
        caseList[0].Status = 'Pending';
        caseList[0].CreatedDate = dCreated;
        caseList[0].Pending_At__c = dCreated;
        insert caseList;

        User usr = [select Id from User where Profile.Name = 'Vendor Team' and isActive = true limit 1];

        caseList[0].Pending_At__c = dCreated;
        caseList[0].OwnerId = usr.Id;
        update caseList;

        Test.startTest();
        CDdBatchCaseToSolved batch = new CDdBatchCaseToSolved();
        Database.executeBatch(batch);
        Test.stopTest();

        Case retCase = [select Id, Status from Case where Id =: caseList[0].Id];
        System.assertEquals('Pending',retCase.Status);

     }

    /**
    * @description first if condition
    */
    @isTest static void testBatchCond1() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].Origin = 'Dasher Apply';
        caseList[0].Status = 'Pending';
        caseList[0].CreatedDate = dCreated;
        caseList[0].Pending_At__c = dCreated;
        caseList[0].Upsert_Error__c = true;
        insert caseList;

        User usr = [select Id from User where Profile.Name = 'Vendor Team' and isActive = true limit 1];

        caseList[0].Pending_At__c = dCreated;
        caseList[0].OwnerId = usr.Id;
        update caseList;

        Test.startTest();
        CDdBatchCaseToSolved batch = new CDdBatchCaseToSolved();
        Database.executeBatch(batch);
        Test.stopTest();

        Case retCase = [select Id, Status from Case where Id =: caseList[0].Id];
        System.assertEquals('Pending',retCase.Status);

     }

     /**
    * @description second if condition
    */
    @isTest static void testBatchCond2() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].Origin = 'Dasher Apply';
        caseList[0].Status = 'Pending';
        caseList[0].CreatedDate = dCreated;
        caseList[0].Pending_At__c = dCreated;
        caseList[0].Subject = 'test';
        caseList[0].Customer_Type__c = 'Merchant';
        caseList[0].Issue__c = 'Store Address';
        caseList[0].Issue_Type__c = 'Account Management - MX';
        caseList[0].Resolution__c = 'Printer issue resolved - MX';
        caseList[0].Resolution_Type__c = 'Merchant Equipment';
        caseList[0].Validation_Bypass__c = true;
        insert caseList;

        User usr = [select Id from User where Profile.Name = 'Vendor Team' and isActive = true limit 1];

        caseList[0].Pending_At__c = dCreated;
        caseList[0].OwnerId = usr.Id;
        caseList[0].Upsert_Error__c = true;
        update caseList;

        Test.startTest();
        CDdBatchCaseToSolved batch = new CDdBatchCaseToSolved();
        Database.executeBatch(batch);
        Test.stopTest();

        Case retCase = [select Id, Status,Error_Exception__c from Case where Id =: caseList[0].Id];
        System.assert(String.isBlank(retCase.Error_Exception__c),'Unexpected exception: ' + retCase.Error_Exception__c);
        System.assertEquals('Solved',retCase.Status);
    }

    @isTest static void testBatchCond2_Error() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].Origin = 'Dasher Apply';
        caseList[0].Status = 'Pending';
        caseList[0].CreatedDate = dCreated;
        caseList[0].Pending_At__c = dCreated;
        caseList[0].Subject = 'test';
        caseList[0].Customer_Type__c = 'Merchant';
        caseList[0].Issue__c = 'Store Address';
        caseList[0].Issue_Type__c = 'Account Management - MX';
        caseList[0].Resolution__c = 'Printer issue resolved - MX';
        caseList[0].Resolution_Type__c = 'Merchant Equipment';
        caseList[0].Validation_Bypass__c = true;
        insert caseList;

        User usr = [select Id from User where Profile.Name = 'Vendor Team' and isActive = true limit 1];

        caseList[0].Pending_At__c = dCreated;
        caseList[0].OwnerId = usr.Id;
        caseList[0].Upsert_Error__c = true;
        update caseList;

        Test.startTest();
        CDdBatchCaseToSolved batch = new CDdBatchCaseToSolved(true);
        Database.executeBatch(batch);
        Test.stopTest();

        Case retCase = [select Id, Status,Error_Exception__c from Case where Id =: caseList[0].Id];
        System.assert(String.isNotBlank(retCase.Error_Exception__c),'Exception expected but not found');
    }

}