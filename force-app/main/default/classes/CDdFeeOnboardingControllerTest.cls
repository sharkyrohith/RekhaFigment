/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 7/9/2020.
 *
 * Implements:
 */
@IsTest
public with sharing class CDdFeeOnboardingControllerTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
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

    @IsTest
    public static void testController() {
        Object result;
        System.runAs(getTestRunUser()) {

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;
                        
            Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId());
            insert account;

            Contact contact = TDdAccountFactory.createContacts(1, account.id)[0];
            insert contact;

            Opportunity opportunity = CDdFeeOnboardingServiceTest.createPostSaleCaviarOpportunity('Test Closed Opp', account.Id, contact.Id, 'Ready for Signature');
            opportunity.Menu_to_be_completed_by__c = null;
            opportunity.Menu_Setup_Method__c =  null;
            opportunity.Tablet_Kit_Type__c = null;
            opportunity.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
            insert opportunity;

            TDdOpportunityLineItemFactory.createProducts();
            List<OpportunityLineItem> products = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunity.Id);
            insert products;

            opportunity.StageName = 'Closed Won';
            opportunity.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            opportunity.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
            update opportunity;

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_fee_onboarding_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);
            List<CDdFeeOnboardingController.MxAffiliateProgramAndFeeDTO> programsAndFees = CDdFeeOnboardingController.getProgramsAndFees(opportunity.Id);
            List<Id> feeIds = new List<Id>();
            for (CDdFeeOnboardingController.MxAffiliateProgramAndFeeDTO programAndFee : programsAndFees) {
                feeIds.add(programAndFee.feeId);
            }
            result = CDdFeeOnboardingController.createProgramsAndFees(opportunity.Id, feeIds);
            Test.stopTest();
        }

        System.assertEquals(true, result!=null, 'Expecting a valid result');
    }

    @IsTest
    public static void testServiceErrorGetProgramsAndFees() {
        System.runAs(getTestRunUser()) {

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;

            Test.startTest();
            try {
                CDdFeeOnboardingController.getProgramsAndFees(null);
            } catch (Exception e) {

            }
            Test.stopTest();
        }

        List<Apex_Log__c> logs = [select Id from Apex_Log__c where Class_Name__c = 'CDdFeeOnboardingController'];
        System.assertEquals(1, logs.size(), 'Unexpected number of log entries');
    }

    @IsTest
    public static void testServiceErrorCreateProgramsAndFees() {
        System.runAs(getTestRunUser()) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;

            vCS__c apiSettings = vCS__c.getInstance();

            Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId());
            insert account;

            Contact contact = TDdAccountFactory.createContacts(1, account.id)[0];
            insert contact;

            Opportunity opportunity = CDdFeeOnboardingServiceTest.createPostSaleCaviarOpportunity('Test Closed Opp', account.Id, contact.Id, 'Ready for Signature');
            opportunity.Menu_to_be_completed_by__c = null;
            opportunity.Menu_Setup_Method__c =  null;
            opportunity.Tablet_Kit_Type__c = null;
            opportunity.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
            insert opportunity;

            TDdOpportunityLineItemFactory.createProducts();
            List<OpportunityLineItem> products = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunity.Id);
            insert products;

            opportunity.StageName = 'Closed Won';
            opportunity.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            opportunity.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
            update opportunity;

            MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
            mock.setStaticResource(apiSettings.DoorstepEndpointPrefix__c + CDdFeeOnboardingDSJApiService.DSJ_ENDPOINT_SUFFIX_MX_PROGRAM_FEE + '/', 'mockResponse_DSJ_fee_onboarding_failure');
            mock.setStaticResource(apiSettings.DoorstepEndpointPrefix__c + CDdFeeOnboardingDSJApiService.DSJ_ENDPOINT_SUFFIX_CX_STOREFRONT_FEE + '/', 'mockResponse_DSJ_fee_onboarding_failure');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);

            List<Id> feeIds = new List<Id>();
            List<CDdFeeOnboardingController.MxAffiliateProgramAndFeeDTO> eligibleProgramsAndFees = CDdFeeOnboardingController.getProgramsAndFees(opportunity.Id);
            for (CDdFeeOnboardingController.MxAffiliateProgramAndFeeDTO eligibleProgramsAndFee : eligibleProgramsAndFees) {
                feeIds.add(eligibleProgramsAndFee.feeId);
            }

            Test.startTest();
            CDdFeeOnboardingController.createProgramsAndFees(opportunity.Id, feeIds);
            Test.stopTest();

            String errorLogLevel = String.valueOf(LoggingLevel.ERROR);
            Apex_Log__c apexLog = [SELECT Id, Log_Level__c, Log__c FROM Apex_Log__c WHERE Reference_Id__c = :opportunity.Id AND Log_Level__c = :errorLogLevel LIMIT 1];
            System.assertEquals(true, apexLog!=null, 'Expecting an apex log with log level ' + errorLogLevel);
            System.assertEquals(true, String.isNotBlank(apexLog.Log__c), 'Expecting an apex log with non-null log message'); 
        }
    }
}