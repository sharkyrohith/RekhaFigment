/**
 *
 * @author  Ayushi Agarwal
 * @date    May 10th, 2023
 * @decription BZAP-19868- Test Class for CDdBatchMissingOrdersOnClosedWonOpp and CDdScheduleMissingOrdersOnClosedWonOpp.
 */
@isTest
public class CDdBatchMissingOrdersOnClosedWonOppTest {

    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name =:CDdSupportConstants.PROFILE_SYS_ADM].Id;
    }

    /**
     * @description Prepare and return the test running user
     */

    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }

    @testSetup
    static void setup(){
        System.runAs(getTestRunUser()){
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        	validation.Bypass_Opportunity_Validations__c = true;
        	validation.Bypass_Account_Validations__c = true;
        	insert validation;

        	Test.startTest();
        	List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
        	insert accounts;

        	Product2 product = TDdCPQTestDataFactory.createProduct(true);

        	Pricebook2 pricebook2 = new Pricebook2();
        	pricebook2.Id = Test.getStandardPricebookId();
        	pricebook2.IsActive = true;
        	update pricebook2;

        	PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, pricebook2, 'USD', true);

        	Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', true);
			Test.stopTest();

        	SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, false);
        	quote.ApprovalStatus__c = 'Approved';
        	insert quote;

        	SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
        	quoteLine.Original_Commission__c = 0.54;
        	insert quoteLine;

        	testOpp.stagename = 'closed won';
        	update testOpp;
        }
    }

    @isTest
    static void testOrderCreated(){
        System.runAs(getTestRunUser()){
            Integer lastNDays = Integer.valueOf(System.Label.Filter_Records_by_Number_of_Days);
            List<Opportunity> testOpp = [SELECT Id, Name, SBQQ__PrimaryQuote__c, Lastmodifieddate, Stagename FROM Opportunity WHERE Name='TestCPQOpp' LIMIT 1 ];
            SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Status__c, ApprovalStatus__c, SBQQ__primary__c, SBQQ__ordered__c, SBQQ__Opportunity2__c
                                        FROM SBQQ__Quote__c
                                        WHERE SBQQ__Opportunity2__c = :testOpp[0].Id
                                        LIMIT 1 ];

            List<Order> orderList = [SELECT Id FROM Order WHERE opportunityid =: testOpp[0].Id ];

            Test.startTest();
            CDdBatchMissingOrdersOnClosedWonOpp batch = new CDdBatchMissingOrdersOnClosedWonOpp(lastNDays);
            Database.executeBatch(batch);
            Test.stopTest();

            orderList = [SELECT Id FROM Order WHERE opportunityid =: testOpp[0].Id ];
            system.assertEquals(1, orderList.size(), 'Order not Created');
        }
    }

    @isTest
    static void testNetUnitPriceNUllOrderNotCreated(){
        System.runAs(getTestRunUser()){
            Integer lastNDays = Integer.valueOf(System.Label.Filter_Records_by_Number_of_Days);
            List<Opportunity> testOpp = [SELECT Id, Name, SBQQ__PrimaryQuote__c, Lastmodifieddate, Stagename FROM Opportunity WHERE Name='TestCPQOpp' LIMIT 1 ];
            SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Status__c, ApprovalStatus__c, SBQQ__primary__c, SBQQ__ordered__c, SBQQ__Opportunity2__c
                                        FROM SBQQ__Quote__c
                                        WHERE SBQQ__Opportunity2__c = :testOpp[0].Id
                                        LIMIT 1 ];
            List<SBQQ__QuoteLine__c> quoteLine = [SELECT Id, SBQQ__NetPrice__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: testQuote.Id ];
            quoteLine[0].SBQQ__NetPrice__c = Null;
            SBQQ.triggercontrol.disable();
            update quoteLine[0];
            SBQQ.triggercontrol.enable();

            List<Order> orderList = [SELECT Id FROM Order WHERE opportunityid =: testOpp[0].Id ];

            Test.startTest();
            CDdBatchMissingOrdersOnClosedWonOpp batch = new CDdBatchMissingOrdersOnClosedWonOpp(lastNDays);
            Database.executeBatch(batch);
            Test.stopTest();

            orderList = [SELECT Id FROM Order WHERE opportunityid =: testOpp[0].Id ];
            system.assertEquals(0, orderList.size(), 'Order is Created');
        }
    }

    @isTest
    static void testOrderedIsTrueOrderCreated(){
        System.runAs(getTestRunUser()){
            Integer lastNDays = Integer.valueOf(System.Label.Filter_Records_by_Number_of_Days);
            List<Opportunity> testOpp = [SELECT Id, Name, SBQQ__PrimaryQuote__c, Lastmodifieddate, Stagename FROM Opportunity WHERE Name='TestCPQOpp' LIMIT 1 ];
            SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Status__c, ApprovalStatus__c, SBQQ__primary__c, SBQQ__ordered__c, SBQQ__Opportunity2__c
                                        FROM SBQQ__Quote__c
                                        WHERE SBQQ__Opportunity2__c = :testOpp[0].Id
                                        LIMIT 1 ];
 			testQuote.SBQQ__ordered__c =True;
            SBQQ.triggercontrol.disable();
            update testQuote;
            SBQQ.triggercontrol.enable();

            List<Order> orderList = [SELECT Id FROM Order WHERE opportunityid =: testOpp[0].Id ];

            Test.startTest();
            CDdBatchMissingOrdersOnClosedWonOpp batch = new CDdBatchMissingOrdersOnClosedWonOpp(lastNDays);
            Database.executeBatch(batch);
            Test.stopTest();

            orderList = [SELECT Id FROM Order WHERE opportunityid =: testOpp[0].Id ];
            system.assertEquals(1, orderList.size(), 'Order is not Created');
        }
    }

    @istest
	public static void testschedule(){
        System.runAs(getTestRunUser()){
            String CRON_EXP = '0 0 15 ? * * *';
        	Test.StartTest();
			CDdScheduleMissingOrdersOnClosedWonOpp testsche = new CDdScheduleMissingOrdersOnClosedWonOpp();
			String jobID = system.schedule('Test status Check', CRON_EXP, testsche );
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
			Test.stopTest();
        }
    }

}