/**
 * @description       :
 * @author            : Jose Vega
 * @group             :
 * @last modified on  : 05-31-2022
 * @last modified by  : Jose Vega
**/
@IsTest
private class VCaseAddPersonAccountTest
{
    @IsTest(SeeAllData=false)
    public static void testEmail()
    {
        // init();

        List<RecordType> supportRecordType = [Select Id, Name From RecordType Where SobjectType='Case' And DeveloperName='Customer' Limit 1];
        Case c = new Case();
        c.RecordTypeId = supportRecordType[0].Id;
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.SuppliedPhone = '888-123-4567';
        c.Origin = 'Email';
        insert c;

        test.startTest();

        System.assertEquals(1, ([Select Id From Contact Where Email = :c.SuppliedEmail]).size());

        test.stopTest();
    }

    @IsTest(SeeAllData=false)
    public static void testWeb()
    {
        // init();

        List<RecordType> supportRecordType = [Select Id, Name From RecordType Where SobjectType='Case' And DeveloperName='Customer' Limit 1];
        Case c = new Case();
        c.RecordTypeId = supportRecordType[0].Id;
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Web';
        c.Customer_Type__c = 'Consumer';
        insert c;

        test.startTest();

        System.assertEquals(1, ([Select Id From Contact Where Email = :c.SuppliedEmail]).size());

        test.stopTest();
    }

    @IsTest(SeeAllData=false)
    public static void testNoCreation()
    {
        // init();

        List<RecordType> supportRecordType = [Select Id, Name From RecordType Where SobjectType='Case' And DeveloperName='Customer' Limit 1];
        Case c = new Case();
        c.RecordTypeId = supportRecordType[0].Id;
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Web';
        insert c;

        test.startTest();

        System.assertEquals(0, ([Select Id From Contact Where Email = :c.SuppliedEmail]).size());

        test.stopTest();
    }

    @IsTest(SeeAllData=false)
    public static void testExist()
    {
        // init();

        List<RecordType> personAccountRecordType =  [Select Id, Name, SobjectType,IsPersonType From RecordType Where SobjectType='Account' And IsPersonType=True Limit 1];
        Account acc = new Account();
        acc.RecordTypeId = personAccountRecordType[0].Id;
        acc.PersonEmail = 'tester01@test.com';
        acc.FirstName = 'TESTER';
        acc.LastName = '9873420374';
        insert acc;

        List<RecordType> supportRecordType = [Select Id, Name From RecordType Where SobjectType='Case' And DeveloperName='Customer' Limit 1];
        Case c = new Case();
        c.RecordTypeId = supportRecordType[0].Id;
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Email';
        insert c;

        test.startTest();

        System.assertEquals(1, ([Select Id From Contact Where Email = :c.SuppliedEmail]).size());

        test.stopTest();
    }

    @TestSetup
    static void init()
    {
        Trigger_Control_Panel__c cs = new Trigger_Control_Panel__c();
        cs.Name = 'Control Panel';
        insert cs;
        TDdCaseFactory.getSupportFeatureFlag(true);
        vCS__c cs1 = new vCS__c();
        cs1.CasePopulateContact__c = true;
        cs1.CasePopulatePersonAccount__c = true;
        cs1.CaseTrigger__c = true;
        cs1.CustomerPAUpsert__c = true;
        insert cs1;

        Account acc = new Account();

        acc.RecordTypeId = '0121a000000Qg1VAAS'; //matches production recordtypeid
        acc.Name = 'DoorDash HQ';
        insert acc;

        List<BusinessHours> bhList = [Select Id, Name From businesshours Limit 1];
        if(!bhList.isEmpty())
        {
            Entitlement et = new Entitlement();
        	et.Name = 'Standard SLA';
        	et.StartDate = date.Today();
            et.AccountId = acc.Id;
            et.Type = 'Phone Support';
			et.BusinessHoursId = bhList[0].Id;
        	insert et;
        }
    }
}