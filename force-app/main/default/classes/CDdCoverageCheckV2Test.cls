/**
* @author Venkat D
* @date 2022-04
*
* @description Test class for CDdCoverageCheckSvcV2, CDdCoverageCheckCtrl, CDdAcctCoverageCheckBatch, CDdLeadCoverageCheckBatch
*/

@isTest
public class CDdCoverageCheckV2Test {

    /**
	* @description testing single account
	*/
    @isTest
    static void test_single_account_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        insert testAcc;

        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdAcctCoverageChecker'));
		System.currentPageReference().getParameters().put('id', testAcc.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testAcc);
        CDdCoverageCheckCtrl ctrl = new CDdCoverageCheckCtrl(controller);
        PageReference pg = ctrl.coverageCheckCallout();
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertEquals('Yes', updatedAcc.In_Coverage__c);
    }

    /**
	* @description testing single account not valid
	*/
    @isTest
    static void test_single_account_callout_nonvalid() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNonValidMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        insert testAcc;

        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdAcctCoverageChecker'));
		System.currentPageReference().getParameters().put('id', testAcc.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testAcc);
        CDdCoverageCheckCtrl ctrl = new CDdCoverageCheckCtrl(controller);
        PageReference pg = ctrl.coverageCheckCallout();
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertEquals('No', updatedAcc.In_Coverage__c);
    }

    /**
	* @description testing single account with null
	*/
    @isTest
    static void test_single_account_callout_null() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        insert testAcc;

        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdAcctCoverageChecker'));
		System.currentPageReference().getParameters().put('id', testAcc.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testAcc);
        CDdCoverageCheckCtrl ctrl = new CDdCoverageCheckCtrl(controller);
        PageReference pg = ctrl.coverageCheckCallout();

        System.assertEquals(pg, null);
        Test.stopTest();


    }
    /**
    * @description testing single account with invalid address
    */
    @isTest static void test_single_account_invalid_address() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        testAcc.BillingStreet = '';
        insert testAcc;

        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdAcctCoverageChecker'));
        System.currentPageReference().getParameters().put('id', testAcc.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testAcc);
        CDdCoverageCheckCtrl ctrl = new CDdCoverageCheckCtrl(controller);
        PageReference pg = ctrl.coverageCheckCallout();

        System.assertEquals(pg, null);
        Test.stopTest();
    }
    /**
	* @description testing multiple accounts
	*/
    @isTest
    static void test_multiple_account_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        insert testAccs;

        List<Id> testAccIds = new List<Id>();
        testAccIds.add(testAccs[0].Id);
        testAccIds.add(testAccs[1].Id);

        Test.startTest();
        CDdCoverageCheckSvcV2.checkAcctCoverage(testAccIds);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account LIMIT 1];
        System.assertEquals('Yes', updatedAcc.In_Coverage__c);
    }
    /**
	* @description testing multiple accounts invalid
	*/
    @isTest
    static void test_multiple_account_callout_nonvalid() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNonValidMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        insert testAccs;

        List<Id> testAccIds = new List<Id>();
        testAccIds.add(testAccs[0].Id);
        testAccIds.add(testAccs[1].Id);

        Test.startTest();
        CDdCoverageCheckSvcV2.checkAcctCoverage(testAccIds);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account LIMIT 1];
        System.assertEquals('No', updatedAcc.In_Coverage__c);
    }

    /**
	* @description testing multiple accounts with null
	*/
    @isTest
    static void test_multiple_account_callout_null() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        insert testAccs;

        List<Id> testAccIds = new List<Id>();
        testAccIds.add(testAccs[0].Id);
        testAccIds.add(testAccs[1].Id);

        Test.startTest();
        CDdCoverageCheckSvcV2.checkAcctCoverage(testAccIds);
        Test.stopTest();
    }

    /**
	* @description testing single lead
	*/
    @isTest
    static void test_single_lead_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

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
        Test.setCurrentPageReference(new PageReference('Page.PDdLeadCoverageChecker'));
		System.currentPageReference().getParameters().put('id', testLead.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testLead);
        CDdCoverageCheckCtrl ctrl = new CDdCoverageCheckCtrl(controller);
        PageReference pg = ctrl.coverageCheckCallout();
        ctrl.cancel();
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: testLead.Id];
        System.assertEquals('Yes', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing single lead not valid
	*/
    @isTest
    static void test_single_lead_callout_nonvalid() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNonValidMock());

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
        Test.setCurrentPageReference(new PageReference('Page.PDdLeadCoverageChecker'));
		System.currentPageReference().getParameters().put('id', testLead.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testLead);
        CDdCoverageCheckCtrl ctrl = new CDdCoverageCheckCtrl(controller);
        PageReference pg = ctrl.coverageCheckCallout();
        ctrl.cancel();
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: testLead.Id];
        System.assertEquals('No', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing single lead null
	*/
    @isTest
    static void test_single_lead_callout_null() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

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
        Test.setCurrentPageReference(new PageReference('Page.PDdLeadCoverageChecker'));
		System.currentPageReference().getParameters().put('id', testLead.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testLead);
        CDdCoverageCheckCtrl ctrl = new CDdCoverageCheckCtrl(controller);
        PageReference pg = ctrl.coverageCheckCallout();
        System.assertEquals(pg, null);
        Test.stopTest();


    }
    /**
    * @description testing single lead with invalid address
    */
    @isTest
    static void test_single_lead_invalid_address() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

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
        Test.setCurrentPageReference(new PageReference('Page.PDdLeadCoverageChecker'));
        System.currentPageReference().getParameters().put('id', testLead.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testLead);
        CDdCoverageCheckCtrl ctrl = new CDdCoverageCheckCtrl(controller);
        PageReference pg = ctrl.coverageCheckCallout();
        System.assertEquals(pg, null);
        Test.stopTest();
    }

    /**
	* @description testing multiple leads
	*/
    @isTest
    static void test_multiple_lead_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

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
        CDdCoverageCheckSvcV2.checkLeadCoverage(testLeadIds);
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead LIMIT 1];
        System.assertEquals('Yes', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing multiple leads non valid
	*/
    @isTest
    static void test_multiple_lead_callout_nonvalid() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNonValidMock());

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
        CDdCoverageCheckSvcV2.checkLeadCoverage(testLeadIds);
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead LIMIT 1];
        System.assertEquals('No', updatedLead.In_Coverage__c);
    }

    /**
	* @description testing multiple leads null
	*/
    @isTest
    static void test_multiple_lead_callout_null() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

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
        CDdCoverageCheckSvcV2.checkLeadCoverage(testLeadIds);
        Test.stopTest();


    }

    /**
	* @description testing multiple accounts with coverage batch
	*/
   	@isTest
    static void test_multiple_account_batch() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        insert testAccs;

        Test.startTest();
        CDdAcctCoverageCheckBatch batch = new CDdAcctCoverageCheckBatch(CDdAcctCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_NULL_OR_UNKNOWN, 2);
        Database.executeBatch(batch);
        Test.stopTest();

    }
    /**
    * @description testing multiple accounts with In Coverage No
    */
    @isTest
    static void test_multiple_account_batch_coverage_no() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        testAccs[0].In_Coverage__c = 'No';
        testAccs[1].In_Coverage__c = 'No';
        insert testAccs;

        Test.startTest();
        CDdAcctCoverageCheckBatch batch = new CDdAcctCoverageCheckBatch(CDdAcctCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_YES_OR_NO, 2);
        Database.executeBatch(batch);
        Test.stopTest();

    }

    /**
	* @description testing multiple leads with coverage batch
	*/
    @isTest
    static void test_multiple_lead_batch() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

        Lead testLead1 = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'Unknown',
                                 isConverted = false);
        Lead testLead2 = new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'Unknown',
                                 isConverted = false);
        insert testLead1;
        insert testLead2;

        Test.startTest();
        CDdLeadCoverageCheckBatch batch = new CDdLeadCoverageCheckBatch(CDdLeadCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_NULL_OR_UNKNOWN, 2, False);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    /**
    * @description testing multiple leads with coverage No
    */
    @isTest
    static void test_multiple_lead_batch_coverage_no() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

        Lead testLead1 = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'No',
                                 isConverted = false);
        Lead testLead2 = new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'No',
                                 isConverted = false);
        insert testLead1;
        insert testLead2;

        Test.startTest();
        CDdLeadCoverageCheckBatch batch = new CDdLeadCoverageCheckBatch(CDdLeadCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_YES_OR_NO, 2, False);
        Database.executeBatch(batch);
        Test.stopTest();
    }

    /**
    * @description testing multiple leads with coverage No and satisfies query filters
    */
    @isTest
    static void test_multiple_eligible_lead_batch_coverage_no() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());

        Id promoRecTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
        Campaign testCampaign = new Campaign(RecordTypeId = promoRecTypeId,isActive=true);
        testCampaign.Name = 'DDfBAcqMktg_'+System.today();
        testCampaign.Title__c = 'DDfBAcqMktg_'+System.today();
        insert testCampaign;

        Lead testLead1 = new Lead(LastName = 'Test Lead 1',
                                 Street = '123 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551234',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'No',
                                 LeadSource = 'Merchant Inbound',
                                 Primary_Campaign_Source__c = testCampaign.Id,
                                 isConverted = false);
        Lead testLead2 = new Lead(LastName = 'Test Lead 2',
                                 Street = '124 Mulberry Ln',
                                 City = 'South San Francisco',
                                 State = 'CA',
                                 PostalCode = '94108',
                                 CountryCode = 'US',
                                 Phone = '2135551235',
                                 Validation_Bypass__c = true,
                                 In_Coverage__c = 'No',
                                 LeadSource = 'Merchant Inbound',
                                 Primary_Campaign_Source__c = testCampaign.Id,
                                 isConverted = false);
        insert testLead1;
        insert testLead2;

        Test.startTest();
        CDdLeadCoverageCheckBatch batch = new CDdLeadCoverageCheckBatch(CDdLeadCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_NO, 10, True);
        Database.executeBatch(batch);
        Test.stopTest();
    }

    /**
	* @description testing added Rest JSON for coverage

    @isTest
    static void test_RestJSONObj() {
     	CDdRestJSONObj.coverageCheckResponse res = new CDdRestJSONObj.coverageCheckResponse();
        res.starting_point = 'test';
        res.valid = true;
        res.submarket_is_valid = 'test';
        res.starting_point_name = 'test';
     }*/
    /**
     * @description Test Coverage Check Batch Scheduler for Option 0 i.e. In Coverage values Null, Unknown
     */
    @isTest
    public static void testCoverageCheckBatchSchedForInCoverageOption0(){
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());
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
    }
    /**
     * @description Test Coverage Check Batch Scheduler for Option 1 i.e. In Coverage value 'No'
     */
    @isTest
    public static void testCoverageCheckBatchSchedForInCoverageOption1(){
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());
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
    }
    /**
     * @description Test Coverage Check Batch Scheduler for Invalid Option i.e. Not value 1 or 2
     */
    @isTest
    public static void testCoverageCheckBatchSchedForInCoverageInvalidOption(){
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock.CDdCoverageCheckV2CalloutNullMock());
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
    * @description testing multiple accounts  for the Check Coverage list button
    */
    @isTest
    static void test_multiple_account_list_button() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

        List<Account> testAccs = TDdAccountFactory.createAccounts('Coverage Check Acc', 2);
        insert testAccs;

        List<Id> testAccIds = new List<Id>();
        testAccIds.add(testAccs[0].Id);
        testAccIds.add(testAccs[1].Id);

        Test.startTest();
        Id batchId = CDdCoverageCheckCtrl.coverageCheck(testAccIds);
        Test.stopTest();

        System.assertEquals(true, batchId!=null);
    }

    /**
    * @description testing multiple leads for the Check Coverage list button
    */
    @isTest
    static void test_multiple_lead_list_button() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

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
        Id batchId = CDdCoverageCheckCtrl.coverageCheck(testLeadIds);
        Test.stopTest();

        System.assertEquals(true, batchId!=null);
    }
    /**
    * @description testing Coverage Check Mass Action for Account records
    */
    @isTest
    static void test_mass_action_account_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        insert testAcc;

        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdAccountCoverageCheckMassAction'));
        System.currentPageReference().getParameters().put('retURL', '/Account');
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(new List<Account>{testAcc});
        controller.setSelected(new List<Account>{testAcc});
        CDdCoverageCheckMassActionCtrl ctrl = new CDdCoverageCheckMassActionCtrl(controller);
        CDdCoverageCheckMassActionCtrl.coverageCheck(new List<Id>{testAcc.Id});
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertEquals('Yes', updatedAcc.In_Coverage__c);
    }
    /**
    * @description testing Coverage Check Mass Action for Lead records
    */
    @isTest
    static void test_mass_action_lead_callout() {
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

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
        Test.setCurrentPageReference(new PageReference('Page.PDdLeadCoverageCheckMassAction'));
        System.currentPageReference().getParameters().put('retURL', '/Lead');
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(new List<Lead>{testLead});
        controller.setSelected(new List<Lead>{testLead});
        CDdCoverageCheckMassActionCtrl ctrl = new CDdCoverageCheckMassActionCtrl(controller);
        CDdCoverageCheckMassActionCtrl.coverageCheck(new List<Id>{testLead.Id});
        Test.stopTest();

        Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c FROM Lead WHERE Id =: testLead.Id];
        System.assertEquals('Yes', updatedLead.In_Coverage__c);
    }

    /**
     * @description Test Coverage Check Batch Scheduler for Option 2 i.e. In Coverage value 'No'
     */
    @isTest
    static void testCoverageCheckBatchSchedForInCoverageOption2(){
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        testAcc.In_Coverage__c = 'No';
        insert testAcc;



        Test.startTest();
        new CDdCoverageCheckBatchSched(2).execute(null);
        Test.stopTest();
    }
}