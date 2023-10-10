/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Test Class for CDdErrorUtilities.
 */
@isTest(seeAllData = false)
public with sharing class CDdErrorUtilitiesTest {
    @isTest static void testFailureBatch() {
        Apex_Log_Settings__c loggerSettings = Apex_Log_Settings__c.getOrgDefaults();
        loggerSettings.Enable_Logging__c = true; 
        upsert loggerSettings; 
        
        List<String> errorMessages = new List<String>(); 
        List<Database.SaveResult> sResults = new List<Database.SaveResult>();
        Database.SaveResult srSuccess = (Database.SaveResult) 
            JSON.deserialize('{"success":true,"id":"0013000000abcde"}', Database.SaveResult.class);
        Database.SaveResult srFail = (Database.SaveResult) JSON.deserialize(
                '{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}'
                , Database.SaveResult.class);
        sResults.add(srSuccess);
        sResults.add(srFail);
        Test.startTest(); 
        errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
        CDdErrorUtilities.createApexLogs(errorMessages, 'CDdErrorUtilitiesTest');
        Test.stopTest(); 
        System.assertEquals(1, errorMessages.size());
        List<Apex_Log__c> logs = [Select Id from Apex_Log__c];
        System.assertEquals(1, logs.size());
    }
    @isTest static void testcreateHTTPApexLogs() {
        Apex_Log_Settings__c loggerSettings = Apex_Log_Settings__c.getOrgDefaults();
        loggerSettings.Enable_Logging__c = true; 
        upsert loggerSettings; 
        
        List<String> errorMessages = new List<String>(); 
        List<Database.SaveResult> sResults = new List<Database.SaveResult>();
        Database.SaveResult srSuccess = (Database.SaveResult) 
            JSON.deserialize('{"success":true,"id":"0013000000abcde"}', Database.SaveResult.class);
        Database.SaveResult srFail = (Database.SaveResult) JSON.deserialize(
                '{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}'
                , Database.SaveResult.class);
        sResults.add(srSuccess);
        sResults.add(srFail);
        String request = 'https://api.doordash.com/v2/deliveries/check_addresses/?pickup_address=MarkeSt+++21+GB';
        String response = '{"valid":null,"submarket_is_valid":null,"starting_point_name":null,"starting_point":null,"pickup_address":"Invalid address","errors":null}';
        Test.startTest(); 
        errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
        CDdErrorUtilities.createHTTPApexLogs(request, response, '0013000000abcde', errorMessages, 'CDdErrorUtilitiesTest', null, LoggingLevel.ERROR);
        Test.stopTest(); 
        System.assertEquals(1, errorMessages.size());
        List<Apex_Log__c> logs = [Select Id from Apex_Log__c];
        System.assertEquals(1, logs.size());
    }
    
    @isTest
    static void test_publishException()
    {
        Test.startTest();
        Lead lead = new Lead();
        List<Database.SaveResult> result = Database.insert(new List<Lead>{lead}, false); 
        CDdErrorUtilities.publishException('errorMessage', 'CDdErrorUtilities', 'RecordId', 'ErrorMessage');
        Test.stopTest();
        List<Apex_Log__c> lstErrorRecs = [SELECT Id  FROM Apex_Log__c];
        System.assertEquals(lstErrorRecs.size(), 1,'There should be atleast error record');
    }
    
    @isTest
    static void test_insertDatabaseErrorsForInsert()
    {
        Account acc = new Account();
        List<Database.SaveResult> res = Database.insert(new List<Account>{acc}, false);
        List<String> errorMessages = new List<String>();
        errorMessages = CDdErrorUtilities.processSaveResults(res, errorMessages);
        System.assert(errorMessages.size()>0,'There should be atleast error message');
        errorMessages = new List<String>();
        errorMessages = CDdErrorUtilities.processSaveResults(res);
        System.assert(errorMessages.size()>0,'There should be atleast error message');
        //Testing insert errors to be reported
        Test.startTest();
            CDdErrorUtilities.publishException('Account','TestClass',res);
        Test.stopTest();
        List<Apex_Log__c> lstErrorRecs = [SELECT Id  FROM Apex_Log__c];
        System.assertEquals(lstErrorRecs.size(), 1,'There should be atleast error record');
    }   
    @isTest
    static void test_insertDatabaseErrorsForUpsert()
    {
        Account acc = new Account();
        List<Database.UpsertResult> res = Database.Upsert(new List<Account>{acc}, false);
        //Testing upsert result errors to be reported
        Test.startTest();
            CDdErrorUtilities.publishException('Account','TestClass',res);
        Test.stopTest();
        List<Apex_Log__c> lstErrorRecs = [SELECT Id  FROM Apex_Log__c];
        System.assertEquals(lstErrorRecs.size(), 1,'There should be atleast error record');
    }

    @isTest
    static void test_deleteDatabaseErrorsForDelete()
    {
        List<Account> accounts = TDdAccountFactory.createAccounts('Test Account', 1);
        insert accounts;
        delete accounts;
        List<Database.DeleteResult> res = Database.Delete(accounts, false);
        //Testing upsert result errors to be reported
        Test.startTest();
            CDdErrorUtilities.publishException('Account','TestClass',res);
        Test.stopTest();
        List<Apex_Log__c> lstErrorRecs = [SELECT Id  FROM Apex_Log__c];
        System.assertEquals(lstErrorRecs.size(), 1,'There should be atleast error record');
    }

    @isTest
    static void test_testException()
    {
        Account acc = new Account();
        //Testing insert errors to be reported
        Test.startTest();
            try{
                 insert acc;
            } catch(Exception ex) {
                String eMsg = CDdErrorUtilities.getFormattedException(ex);
                System.assert(String.isNotBlank(eMsg),'Should have returned formatted exception message');
                CDdErrorUtilities.publishException('Account','TestClass',ex);
                CDdErrorUtilities.publishException('Account','TestClass','recordId',ex);                
            }
        //
        List<String> errorMessages = new List<String>();
        Boolean isError = false;
        errorMessages.add('TestMessage');
        try{
            CDdErrorUtilities.throwcustomException(errorMessages);
        } catch(Exception e) {
            isError=true;
       }
        System.assertEquals(isError,true,'There should be an exception thrown');
        Test.stopTest();

        List<Apex_Log__c> lstErrorRecs = [SELECT Id  FROM Apex_Log__c];
        System.assert(lstErrorRecs.size()>0, 'There should be atleast error record from exception message');
    }          
}