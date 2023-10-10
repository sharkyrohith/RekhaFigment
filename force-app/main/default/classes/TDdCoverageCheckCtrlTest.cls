@isTest
public class TDdCoverageCheckCtrlTest {

    /**
	 * Added feature flag update as per BZAP-13644 to always execute old API.
	 */
    @testSetup
    static void testSetup() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_coverageCheck_success');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
	}

    @isTest static void test_single_account_callout() {
        Test.setMock(HttpCalloutMock.class, new TDdCoverageCalloutMock());

        Account testAcc = TDdAccountFactory.createAccounts('Coverage Check Acc', 1)[0];
        insert testAcc;

        Test.startTest();
        CDdCoverageCheckSvc.checkAcctCoverage(testAcc);
        Test.stopTest();

        Account updatedAcc = (Account) [SELECT Id, In_Coverage__c FROM Account WHERE Id =: testAcc.Id];
        System.assertEquals('Yes', updatedAcc.In_Coverage__c);
    }

    @isTest static void test_multiple_account_callout() {
        Test.setMock(HttpCalloutMock.class, new TDdCoverageCalloutMock());

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

    @isTest static void test_single_lead_callout() {
        Test.setMock(HttpCalloutMock.class, new TDdCoverageCalloutMock());

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

    @isTest static void test_multiple_lead_callout() {
        Test.setMock(HttpCalloutMock.class, new TDdCoverageCalloutMock());

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
}