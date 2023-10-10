/**
* @author Tia Xuan
* @date 2019-04
*
* @description Test class for CDdCoverageCheckSvc, CDdCoverageCheckCtrl, CDdAcctCoverageCheckBatch, CDdLeadCoverageCheckBatch
*/

@isTest
public class CDdCoverageCheckTest {

    /**
	* @description testing single account
	*/
    @isTest
    static void test_single_account_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        insert testAcc;

        Test.startTest();
        CDdCoverageCheckSvc.checkAcctCoverage(testAcc);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertEquals('Yes', updatedAcc.In_Coverage__c);
    }

    /**
	* @description testing single account not valid
	*/
    @isTest
    static void test_single_account_callout_nonvalid() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNonValidMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        insert testAcc;

        Test.startTest();
        CDdCoverageCheckSvc.checkAcctCoverage(testAcc);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertEquals('No', updatedAcc.In_Coverage__c);
    }


    /**
	* @description testing single account with null
	*/
    @isTest
    static void test_single_account_callout_null() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        insert testAcc;

        Test.startTest();
        CDdCoverageCheckSvc.checkAcctCoverage(testAcc);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertNotEquals('Yes',updatedAcc.In_Coverage__c);

    }
    /**
    * @description testing single account with invalid address
    */
    @isTest static void test_single_account_invalid_address() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        testAcc.BillingStreet = '';
        insert testAcc;

        Test.startTest();
        CDdCoverageCheckSvc.checkAcctCoverage(testAcc);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertNotEquals('Yes',updatedAcc.In_Coverage__c);

    }

    /**
	* @description testing multiple accounts
	*/
    @isTest
    static void test_multiple_account_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        insert testAccs;

        List<Id> testAccIds = new List<Id>();
        testAccIds.add(testAccs[0].Id);
        testAccIds.add(testAccs[1].Id);

        Test.startTest();
        CDdCoverageCheckSvc.checkAcctCoverage(testAccIds);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account LIMIT 1];
        System.assertEquals('Yes', updatedAcc.In_Coverage__c);
    }
    /**
	* @description testing multiple accounts invalid
	*/
    @isTest
    static void test_multiple_account_callout_nonvalid() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNonValidMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        insert testAccs;

        List<Id> testAccIds = new List<Id>();
        testAccIds.add(testAccs[0].Id);
        testAccIds.add(testAccs[1].Id);

        Test.startTest();
        CDdCoverageCheckSvc.checkAcctCoverage(testAccIds);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account LIMIT 1];
        System.assertEquals('No', updatedAcc.In_Coverage__c);
    }

    /**
	* @description testing multiple accounts with null
	*/
    @isTest
    static void test_multiple_account_callout_null() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        insert testAccs;

        List<Id> testAccIds = new List<Id>();
        testAccIds.add(testAccs[0].Id);
        testAccIds.add(testAccs[1].Id);

        Test.startTest();
        CDdCoverageCheckSvc.checkAcctCoverage(testAccIds);
        Test.stopTest();

        Account updatedAcc = [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAccs[0].Id];
        System.assertNotEquals('Yes',updatedAcc.In_Coverage__c);
    }

    /**
	* @description testing single lead
	*/
    @isTest
    static void test_single_lead_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock());

        Lead testLead = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true);
        insert testLead;

        Test.startTest();
        CDdCoverageCheckSvc.checkLeadCoverage(testLead);
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: testLead.Id];
        System.assertEquals('Yes', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing single lead not valid
	*/
    @isTest
    static void test_single_lead_callout_nonvalid() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNonValidMock());

        Lead testLead = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true);
        insert testLead;

        Test.startTest();
        CDdCoverageCheckSvc.checkLeadCoverage(testLead);
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: testLead.Id];
        System.assertEquals('No', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing single lead null
	*/
    @isTest
    static void test_single_lead_callout_null() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());

        Lead testLead = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true);
        insert testLead;

        Test.startTest();
        CDdCoverageCheckSvc.checkLeadCoverage(testLead);
        Test.stopTest();

        Lead updatedLead = [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: testLead.Id];
        System.assertNotEquals('Yes', updatedLead.In_Coverage__c);

    }
    /**
    * @description testing single lead with invalid address
    */
    @isTest
    static void test_single_lead_invalid_address() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());

        Lead testLead = new Lead(LastName = 'Test Lead 1',
                                 Street = '',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true);
        insert testLead;

        Test.startTest();
        CDdCoverageCheckSvc.checkLeadCoverage(testLead);
        Test.stopTest();

        Lead updatedLead = [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: testLead.Id];
        System.assertNotEquals('Yes', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing multiple leads
	*/
    @isTest
    static void test_multiple_lead_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock());

        Lead testLead1 = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true);
        Lead testLead2 = new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true);
        insert testLead1;
        insert testLead2;

        List<Id> testLeadIds = new List<Id>();
        testLeadIds.add(testLead1.Id);
        testLeadIds.add(testLead2.Id);

        Test.startTest();
        CDdCoverageCheckSvc.checkLeadCoverage(testLeadIds);
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead LIMIT 1];
        System.assertEquals('Yes', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing multiple leads non valid
	*/
    @isTest
    static void test_multiple_lead_callout_nonvalid() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNonValidMock());

        Lead testLead1 = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true);
        Lead testLead2 = new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true);
        insert testLead1;
        insert testLead2;

        List<Id> testLeadIds = new List<Id>();
        testLeadIds.add(testLead1.Id);
        testLeadIds.add(testLead2.Id);

        Test.startTest();
        CDdCoverageCheckSvc.checkLeadCoverage(testLeadIds);
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead LIMIT 1];
        System.assertEquals('No', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing multiple leads null
	*/
    @isTest
    static void test_multiple_lead_callout_null() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());

        Lead testLead1 = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true);
        Lead testLead2 = new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true);
        insert testLead1;
        insert testLead2;

        List<Id> testLeadIds = new List<Id>();
        testLeadIds.add(testLead1.Id);
        testLeadIds.add(testLead2.Id);

        Test.startTest();
        CDdCoverageCheckSvc.checkLeadCoverage(testLeadIds);
        Test.stopTest();

        Lead updatedLead = [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: testLead1.Id];
        System.assertNotEquals('Yes', updatedLead.In_Coverage__c);

    }

    /**
	* @description testing added Rest JSON for coverage
	*/
    @isTest
    static void test_RestJSONObj() {
     	CDdRestJSONObj.coverageCheckResponse res = new CDdRestJSONObj.coverageCheckResponse();
        res.starting_point = 'test';
        res.valid = true;
        res.submarket_is_valid = 'test';
        res.starting_point_name = 'test';
     }
    /**
     * @description Test Coverage Check Batch Scheduler for Option 0 i.e. In Coverage values Null, Unknown
     */
    @isTest
    public static void testCoverageCheckBatchSchedForInCoverageOption0(){
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());
        List<Lead> Leads = new List<Lead>{
                        new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = null,
                                 isConverted = false)
                        , new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'Unknown',
                                 isConverted = false)
                    };
        insert leads;
        Test.startTest();
        new CDdCoverageCheckBatchSched(0).execute(null);
        Test.stopTest();

        Lead updatedLead = [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: leads[0].Id];
        System.assertNotEquals('Yes', updatedLead.In_Coverage__c);
    }
    /**
     * @description Test Coverage Check Batch Scheduler for Option 1 i.e. In Coverage value 'No'
     */
    @isTest
    public static void testCoverageCheckBatchSchedForInCoverageOption1(){
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());
        List<Lead> Leads = new List<Lead>{
                        new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'No',
                                 isConverted = false)
                        , new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'No',
                                 isConverted = false)
                    };
        insert leads;
        Test.startTest();
        new CDdCoverageCheckBatchSched(1).execute(null);
        Test.stopTest();

        Lead updatedLead = [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: leads[0].Id];
        System.assertNotEquals('Yes', updatedLead.In_Coverage__c);
    }
    /**
     * @description Test Coverage Check Batch Scheduler for Invalid Option i.e. Not value 1 or 2
     */
    @isTest
    public static void testCoverageCheckBatchSchedForInCoverageInvalidOption(){
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock.CDdCoverageCalloutNullMock());
        List<Lead> Leads = new List<Lead>{
                        new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'No',
                                 isConverted = false)
                        , new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'No',
                                 isConverted = false)
                    };
        insert leads;
        Test.startTest();
        try {
            new CDdCoverageCheckBatchSched(null).execute(null);
        }catch(Exception e){
            System.assertEquals(CDdCoverageCheckBatchSched.ERROR_MSG_INVALID_IN_COVERAGE_OPTION, e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Test Coverage Check Batch Scheduler for Option 2 i.e. In Coverage value 'No'
     */
    @isTest
    static void testCoverageCheckBatchSchedForInCoverageOption2(){
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCalloutMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        testAcc.In_Coverage__c = 'No';
        insert testAcc;



        Test.startTest();
        new CDdCoverageCheckBatchSched(2).execute(null);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertNotEquals('Yes', updatedAccount.In_Coverage__c);
    }
}