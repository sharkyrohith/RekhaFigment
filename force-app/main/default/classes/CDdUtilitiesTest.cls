/**
 * @author Raju Lakshman
 * @date October 2020
 * @description Test class for the methods in CDdUtilities and CDdPicklistUtil
 */

 @isTest
public without sharing class CDdUtilitiesTest {

    @isTest
    public static void testIncreaseCodeCoverage() {
        CDdUtilities.getIsSandbox();
        system.assert(CDdUtilities.getObjectPrefix('Account') == '001','Invalid Account Object Prefix');
        CDdUtilities.createLink(UserInfo.getUserId(),'Click me');
        system.assert(CDdUtilities.getDecimalValue('1,000') == 1000,'Invalid conversion from String to Decimal');
        system.assert(CDdUtilities.getDecimalValueNull(CDdCoreConstants.BLANK_STRING) == null,'Invalid conversion from String to Decimal');
        System.assertEquals(null, CDdUtilities.returnValidId('123abc'), 'null should be returned for an invalid Id');
        Decimal d = 10000;
        Object o = (Object)d;
        system.assert(CDdUtilities.convertDecimalObjectToString(o) == '10,000.00','Invalid Decimal to Commafied String');
        d = 10000.1;
        o = (Object)d;
        system.assert(CDdUtilities.convertDecimalObjectToString(o) == '10,000.10','Invalid Decimal to Commafied String');
        d = 10000.12;
        o = (Object)d;
        system.assert(CDdUtilities.convertDecimalObjectToString(o) == '10,000.12','Invalid Decimal to Commafied String');
        system.assert(CDdUtilities.convertDecimalObjectToString(null) == CDdCoreConstants.BLANK_STRING,'Invalid Decimal to Commafied String');

        system.assert(CDdUtilities.maskString('test', 1, false) == 'xxxt', 'not masked');
        system.assert(CDdUtilities.maskString('test', 1, true) == 'txxx', 'not masked');
        system.assert(CDdUtilities.objectIsAccessible('Case') == true, 'Case not assessible');
    }

    @isTest
    public static void testGetFieldValAsString() {
        List<User> users =
            [SELECT Id,Name,Manager.Name,CreatedDate,isActive,Quota__c
               FROM User
              WHERE ManagerId != null
                AND Quota__c != null
              LIMIT 1];

        system.assert(!users.isEmpty(),'No Users found matching this criteria');

        User u = users[0];
        String userName = CDdUtilities.getFieldValAsString(u,'Name','String');
        system.assert(userName == u.Name,'User name does not match');
        String userManagerName = CDdUtilities.getFieldValAsString(u,'Manager.Name','String');
        system.assert(userManagerName == u.Manager.Name,'User manager does not match');
        String userIsActive = CDdUtilities.getFieldValAsString(u,'isActive','Boolean');
        system.assert(u.isActive ? (userIsActive == CDdCoreConstants.STRING_YES) : (userIsActive == CDdCoreConstants.STRING_NO),'User isActive does not match');
        String userCreatedDate = CDdUtilities.getFieldValAsString(u,'CreatedDate','Date');
        String userQuota = CDdUtilities.getFieldValAsString(u,'Quota__c','Decimal');
    }

    @isTest
    public static void testReplaceMergeFields() {
        String s = '{!User.Name} was created on {!User.CreatedDate}. The link to this users\'s record is {!User.Link}.';
        String merged = CDdUtilities.replaceMergeFields('User', UserInfo.getUserId(), s);
        system.assert(String.isNotBlank(merged),'Unable to create merged string');
    }

    @isTest
    public static void testReplaceMergeFields2() {
        User usr = [SELECT Id, Name, CreatedDate  FROM User WHERE Id =:UserInfo.getUserId()];
        String s = '{Name} was created on {CreatedDate}.';
        String merged = CDdUtilities.replaceMergeFields(usr, s);
        merged = CDdUtilities.replaceMergeFieldsString(usr, s);
        system.assert(String.isNotBlank(merged),'Unable to create merged string');
    }

    @isTest
    public static void testPicklist() {
        Map<String, List<CDdPicklistUtil.PicklistOption>> picklistOptions =
            CDdPicklistUtil.getPicklistOptions('Contact','CurrencyIsoCode');
        system.assert(picklistOptions.containsKey('CurrencyIsoCode'),'Contact.CurrencyIsoCode object picklist not found');
        system.assert(!picklistOptions.get('CurrencyIsoCode').isEmpty(),'Contact.CurrencyIsoCode object picklist is empty');
    }

    @isTest
    public static void testDependentPicklist() {
        Map<String, List<String>> picklistValues =
            CDdPicklistUtil.getDependentPicklistValues('Case','Issue_Category__c','Issue_PM__c');
        system.assert(!picklistValues.isEmpty(),'Case dependent picklist Issue Category/Issue PM is empty');
    }

    @isTest
    public static void logCpuUsage() {
        Feature_Flags__c setting = Feature_Flags__c.getInstance();
        setting.Enable_CPU_Time_Check__c = true;
        setting.Enable_Heap_Size_Check__c = true;
        insert setting;
        
        Integer lastCpuTime = 0;
        lastCpuTime = CDdUtilities.logCpuUsage('IN TEST', lastCpuTime, 'TESTING');
        
        List<Account> testAccounts = TDdAccountFactory.createAccounts('Test Account', 5);
        insert testAccounts;

        lastCpuTime = CDdUtilities.logCpuUsage('IN TEST', lastCpuTime, 'TESTING');
        System.assertNotEquals(0, lastCpuTime, 'lastCpuTime should not be 0');
    }

    @isTest static void testUtilMethods() {
        System.assertNotEquals(null, CDdUtilities.isQueueableAllowed(),'isQueueableAllowed should be boolean');
    }
    @isTest static void testsobjectDmlUtil() {
        // insert case
        List<Case> caseList = new List<Case>();
        Id custSuppRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case c = new Case();
        c.RecordTypeId = custSuppRecTypeId;
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Email';
        caseList.add(c);
        Test.startTest();
            CDdUtilities.insertSobjectQueueable('Insert Cases from Batch',caseList,CDdUtilities.BATCH_SIZE_1+9);
        Test.stopTest();
        // now query and see case was inserted
        List<Case> inCaseList = [Select id,Subject from Case limit 1];
        System.assertEquals(1, inCaseList.size(), 'There should be one case created');
    }
    @isTest static void testsobjectDmlUtil_update() {
        // insert case
        List<Case> caseList = new List<Case>();
        Id custSuppRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case c = new Case();
        c.RecordTypeId = custSuppRecTypeId;
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Email';
        caseList.add(c);
        Insert caseList;
        Test.startTest();
            caseList[0].Subject = 'Updated from Queueable';
            CDdUtilities.updateSobjectQueueable('Update Cases from Batch',caseList,CDdUtilities.BATCH_SIZE_1+9);
        Test.stopTest();
        // now query and see case was inserted
        List<Case> inCaseList = [Select id,Subject from Case limit 1];
        System.assertEquals(1, inCaseList.size(), 'There should be one case created');
        System.assertEquals(caseList[0].Subject, 'Updated from Queueable', 'Case Subject should have beem updated');
    }

    @isTest static void testsobjectDmlUtil_upsert() {
       // insert case
       List<Case> caseList = new List<Case>();
       Id custSuppRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
       Case c = new Case();
       c.RecordTypeId = custSuppRecTypeId;
       c.Subject = 'test 01';
       c.Description = 'this is a test';
       c.SuppliedName = 'tester 01';
       c.SuppliedEmail = 'tester01@test.com';
       c.Origin = 'Email';
       caseList.add(c);
       Test.startTest();
           CDdUtilities.upsertSobjectQueueable('Insert Cases from Batch',caseList,CDdUtilities.BATCH_SIZE_1+9,null);
       Test.stopTest();
       // now query and see case was inserted
       List<Case> inCaseList = [Select id,Subject from Case limit 1];
       System.assertEquals(1, inCaseList.size(), 'There should be one case created');
    }

    @isTest static void testsobjectDmlUtil_delete() {
        // insert case
        List<Case> caseList = new List<Case>();
        Id custSuppRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case c = new Case();
        c.RecordTypeId = custSuppRecTypeId;
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Email';
        caseList.add(c);
        insert caseList;
        Test.startTest();
            CDdUtilities.deleteSobjectQueueable('Delete Cases from Batch',caseList,CDdUtilities.BATCH_SIZE_1+9);
        Test.stopTest();
        // now query and see case was inserted
        List<Case> inCaseList = [Select id,Subject from Case];
        System.assert(inCaseList.isEmpty(), 'Case should be deleted.');
    }
}