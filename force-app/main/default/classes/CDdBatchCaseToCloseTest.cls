/**
* @author Tia Xuan  
* @date 2019-04
*
* @description Test class for CDdBatchCaseToClose
*/

@isTest
public class CDdBatchCaseToCloseTest {
    /**
    * @description else statement for batch
    */
    @isTest static void testBatch() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Account Management');
        caseList[0].Origin = 'Dasher Apply';
        caseList[0].Status = 'Solved'; 
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        insert caseList;

        User usr = [select Id from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
        caseList[0].OwnerId = usr.Id;

        caseList[0].Solved_At__c = dCreated;
        update caseList;

        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
            batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                WHERE Record_Type__c = 'Account Management'
                AND Logic__c != 'MERCHANT ENTITLEMENT'
            ];
            Database.executeBatch(batch);
        Test.stopTest();
        
        Case retCase = [select Id, Error_Exception__c from Case where Id =: caseList[0].Id];
        System.assertNotEquals(retCase.Error_Exception__c, null,  'retCase --> ' + retCase);
        
    }
    
    /**
    * @description first if condition
    */
    @isTest static void testBatchCond2() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        
        caseList[0].Origin = 'Dasher Apply';
        caseList[0].Status = 'Solved'; 
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        caseList[0].Subject = 'test'; 
        caseList[0].Customer_Type__c = 'Merchant';
        caseList[0].Issue__c = 'Store Address';
        caseList[0].Issue_Type__c = 'Account Management - MX';
        caseList[0].Resolution__c = 'Printer issue resolved - MX';
        caseList[0].Resolution_Type__c = 'Merchant Equipment';
        caseList[0].Validation_Bypass__c = true;
        insert caseList;
        
        User usr = [select Id from User where Profile.Name = 'Vendor Team' and isActive = true limit 1];

        caseList[0].Solved_At__c = dCreated;
        caseList[0].OwnerId = usr.Id;
        caseList[0].Upsert_Error__c = true;
        update caseList;

        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
            batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                WHERE Record_Type__c = 'Support'
            ];
            Database.executeBatch(batch);
        Test.stopTest();
        
        Case retCase = [select Id, Status from Case where Id =: caseList[0].Id];
        System.assertEquals(retCase.Status, 'Closed');
        
    } 

    /**
    * @description second if condition
    */
    @isTest static void testBatchCond4() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Account Management');
        List<Account> acctList = TDdAccountFactory.createAccounts('test',1);
        insert acctList;
        
        caseList[0].Origin = 'Dasher Apply';
        caseList[0].Status = 'Solved'; 
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        caseList[0].Issue_Category__c = 'Account settings';
        caseList[0].Issue_PM__c = 'Address'; 
        caseList[0].AccountId = acctList[0].Id;
        caseList[0].Upsert_Error__c = true;
        insert caseList;

        caseList[0].Solved_At__c = dCreated;
        update caseList;
        
        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
            batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                WHERE Record_Type__c = 'Account Management'
                AND Logic__c != 'MERCHANT ENTITLEMENT'
            ];
            Database.executeBatch(batch);
        Test.stopTest();
        
        Case retCase = [select Id, Status from Case where Id =: caseList[0].Id];
        System.assertEquals(retCase.Status, 'Closed');
        
    }
    
    /**
    * @description third if condition
    */
    @isTest static void testBatchCond5() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Account Management');
        caseList[0].Origin = 'Dasher Apply';
        caseList[0].Status = 'Solved'; 
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        caseList[0].Upsert_Error__c = true;
        insert caseList;
        
        Test.startTest();
        CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
        batch.iEntry = 0;
        batch.batchCaseToCloseList = [
            SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
            FROM Batch_Case_To_Close__mdt
            WHERE Record_Type__c = 'Account Management'
            AND Logic__c != 'MERCHANT ENTITLEMENT'
        ];
        Database.executeBatch(batch);
        Test.stopTest();

    }

    /**
    * @description fourth if condition
    */
    @isTest static void testBatchCond6() {
        DateTime dCreated = DateTime.now().addHours(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Menu Update');
        caseList[0].Status = 'Solved'; 
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        insert caseList;
        
        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
            batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                WHERE Record_Type__c = 'Menu Update'
            ];
            Database.executeBatch(batch);
        Test.stopTest();

    }

    /**
    * @description testCaviarCases w/ Type = Caviar Corporate
    */
    @isTest static void testCaviarCases1() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Caviar Support');
        caseList[0].Status = 'Solved'; 
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        caseList[0].Type = 'Caviar Corporate';
        insert caseList;
        
        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
        	  batch.onlyEntry = 6;
        /*    batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                WHERE Record_Type__c = 'Caviar Support'
                AND Criteria__c LIKE '%Caviar Corporate%'
            ];
        */  Database.executeBatch(batch);
        Test.stopTest();

        Case retCase = [select Id, Status from Case where Id =: caseList[0].Id];
        // System.assertEquals('Closed', retCase.Status);
    }

    /**
    * @description testCaviarCases w/ Type = Caviar Diner
    */
    @isTest static void testCaviarCases2() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Caviar Support');
        caseList[0].Status = 'Solved'; 
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        caseList[0].Type = 'Caviar Diner';
        insert caseList;
        
        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
        	  batch.onlyEntry = 7;
        /*    batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                // WHERE Record_Type__c = 'Caviar Support'
                // AND Criteria__c LIKE '%Caviar Diner%'
            ];
        */	SchedulableContext sc = null;
            batch.execute(sc);
        Test.stopTest();

        Case retCase = [select Id, Status from Case where Id =: caseList[0].Id];
        // System.assertEquals('Closed', retCase.Status);
    }

    /**
    * @description Test for Case of record type - POS Integrations
    */
    @isTest static void testBatchCond15() {
        Account testAccount = TDdAccountFactory.createAccounts('POSIntegrationAcct', 1, 'Marketplace')[0];
        testAccount.Is_Partner__c = 'Yes';
        insert testAccount; 
        Contact testContact = TDdAccountFactory.createContacts(1, testAccount.Id)[0];
        insert testContact; 
        Case testCase  = TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0];
        testCase.Status = 'Solved';
        testCase.Last_Email_from_Customer__c = DateTime.now().addDays(-5);
        testCase.Solved_At__c = DateTime.now().addDays(-4);
        testCase.CreatedDate = DateTime.now().addDays(-5); 
        testCase.AccountId = testAccount.Id; 
        testCase.ContactId = testContact.Id; 
        insert testCase;        
        
        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
            batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                WHERE Record_Type__c = 'POS Integrations'
            ];
            Database.executeBatch(batch);
        Test.stopTest();
        
        Case retCase = [select Id, Status from Case where Id =: testCase.Id];
        System.assertEquals(retCase.Status, 'Closed');
        
    }    

    /**
    * @description Test for Case of record type - POS Integrations
    */
    @isTest static void testBatchCond15UsingWhereClause() {
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Case_Close_Job_use_Where_Clause__c = true;
        upsert featureFlag;
        Account testAccount = TDdAccountFactory.createAccounts('POSIntegrationAcct', 1, 'Marketplace')[0];
        testAccount.Is_Partner__c = 'Yes';
        insert testAccount; 
        Contact testContact = TDdAccountFactory.createContacts(1, testAccount.Id)[0];
        insert testContact; 
        Case testCase  = TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0];
        testCase.Status = 'Solved';
        testCase.Last_Email_from_Customer__c = DateTime.now().addDays(-5);
        testCase.Solved_At__c = DateTime.now().addDays(-4);
        testCase.CreatedDate = DateTime.now().addDays(-5); 
        testCase.AccountId = testAccount.Id; 
        testCase.ContactId = testContact.Id; 
        insert testCase;        
        
        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
            batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                WHERE Record_Type__c = 'POS Integrations'
            ];
            Database.executeBatch(batch);
        Test.stopTest();
        
        Case retCase = [select Id, Status from Case where Id =: testCase.Id];
        System.assertEquals(retCase.Status, 'Closed');
        
    }    
    
     /**
    * @description Test for japan cfa Case of record type - POS Integrations
    */
    @isTest static void testBatchCond15japanUsingWhereClause() {
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Case_Close_Job_use_Where_Clause__c = true;
        featureFlag.Enable_Case_Close_Japan_CFA_Exclusion__c = true;
        upsert featureFlag;
        Account testAccount = TDdAccountFactory.createAccounts('POSIntegrationAcct', 1, 'Marketplace')[0];
        testAccount.Is_Partner__c = 'Yes';
        insert testAccount; 
        Contact testContact = TDdAccountFactory.createContacts(1, testAccount.Id)[0];
        insert testContact; 
        Case testCase  = TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0];
        testCase.Status = 'Solved';
        testCase.Last_Email_from_Customer__c = DateTime.now().addDays(-5);
        testCase.Solved_At__c = DateTime.now().addDays(-4);
        testCase.CreatedDate = DateTime.now().addDays(-5); 
        testCase.AccountId = testAccount.Id; 
        testCase.ContactId = testContact.Id; 
        insert testCase;        
        
        Test.startTest();
            CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
            batch.iEntry = 0;
            batch.batchCaseToCloseList = [
                SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                    Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
                FROM Batch_Case_To_Close__mdt
                WHERE Record_Type__c = 'POS Integrations'
            ];
            Database.executeBatch(batch);
        Test.stopTest();
        
        Case retCase = [select Id, Status from Case where Id =: testCase.Id];
        System.assertEquals(retCase.Status, 'Closed');
        
    }    

}