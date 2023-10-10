/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/09/2020
*
* @group Service Test
*
* @description Test for Fee Onboarding Callout
**************************************************************************************************************************************/
@isTest
public class CDdFeeOnboardingCalloutTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }
    public static final String TEST_REFERENCE_ID = '01234567890123456789012345678900';
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
    /**
    * @description Test for send request of programs and fees to DSJ API for opportunity 
    */
    @isTest
    static void testMxSendRequestSuccess(){
        CDdFeeOnboardingService requestService =  new CDdFeeOnboardingService();
        CDdFeeOnboardingAPIServiceInterface apiService =  new CDdFeeOnboardingApiService();
        CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = null;

        System.runAs(getTestRunUser()){

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;

            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);
            // store accounts     
            List<Account> accounts = new List<Account>();
            accounts.add(parentAcct);
            accounts.add(childAcct);
            upsert accounts;
            // store contacts
            List<Contact> contacts = new List<Contact>();
            contacts.add(contact);
            upsert contacts;
            // update child account
            childAcct.ParentId = parentAcct.Id;
            upsert childAcct;           
            // store opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity closedWonOpportunity = CDdFeeOnboardingServiceTest.createPostSaleCaviarOpportunity('Test Closed Opp', childAcct.Id, contact.Id, 'Closed Won');
            //closedWonOpportunity.Menu_to_be_completed_by__c = null;
            //closedWonOpportunity.Menu_Setup_Method__c =  null;
            closedWonOpportunity.Tablet_Kit_Type__c = null;
            closedWonOpportunity.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
           
            opportunities.add(closedWonOpportunity);
            upsert opportunities;

            Map<String, Set<String>> programAndFeeDeveloperNames = new Map<String, Set<String>>();
            programAndFeeDeveloperNames.put('Marketplace_Delivery', new Set<String>{'Marketplace_Delivery_Fee'});

            Test.StartTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_fee_onboarding_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);
            CDdRestJSONObj.MxFeeOnboardingRequest mxProgramFeeRequest = requestService.getMxFeeOnboardingRequest(closedWonOpportunity.Id, programAndFeeDeveloperNames);
            apiService.addRequest(CDdFeeOnboardingApiType.MX_PROGRAM_FEE, mxProgramFeeRequest);
            feeOnboardingResponse = apiService.sendRequest(CDdFeeOnboardingApiType.MX_PROGRAM_FEE);
            System.assertEquals(true, feeOnboardingResponse!=null, 'Expecting a valid fee onboarding response object');
            Test.StopTest();
        }
    }
    /**
    * @description Test for send request of programs and fees to DSJ API for opportunity 
    */
    @isTest
    static void testMxSendRequestFailure(){
        CDdFeeOnboardingService requestService =  new CDdFeeOnboardingService();
        CDdFeeOnboardingAPIServiceInterface apiService =  new CDdFeeOnboardingApiService();
        CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = null;
        String errorMessage = null;

        System.runAs(getTestRunUser()){

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;

            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);
            // store accounts     
            List<Account> accounts = new List<Account>();
            accounts.add(parentAcct);
            accounts.add(childAcct);
            upsert accounts;
            // store contacts
            List<Contact> contacts = new List<Contact>();
            contacts.add(contact);
            upsert contacts;
            // update child account
            childAcct.ParentId = parentAcct.Id;
            upsert childAcct;           
            // store opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity closedWonOpportunity = CDdFeeOnboardingServiceTest.createPostSaleCaviarOpportunity('Test Closed Opp', childAcct.Id, contact.Id, 'Closed Won');
            //closedWonOpportunity.Menu_to_be_completed_by__c = null;
            //closedWonOpportunity.Menu_Setup_Method__c =  null;
            closedWonOpportunity.Tablet_Kit_Type__c = null;
            closedWonOpportunity.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
           
            opportunities.add(closedWonOpportunity);
            upsert opportunities;

            Map<String, Set<String>> programAndFeeDeveloperNames = new Map<String, Set<String>>();
            programAndFeeDeveloperNames.put('Marketplace_Delivery', new Set<String>{'Marketplace_Delivery_Fee'});

            Test.StartTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_fee_onboarding_failure');
            mock.setStatusCode(400);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);
            try {
                CDdRestJSONObj.MxFeeOnboardingRequest mxProgramFeeRequest = requestService.getMxFeeOnboardingRequest(closedWonOpportunity.Id, programAndFeeDeveloperNames);
                apiService.addRequest(CDdFeeOnboardingApiType.MX_PROGRAM_FEE, mxProgramFeeRequest);
                feeOnboardingResponse = apiService.sendRequest(CDdFeeOnboardingApiType.MX_PROGRAM_FEE);                
            }catch(CDdFeeOnboardingException e){
                errorMessage = CDdFeeOnboardingException.getErrorMessage(e);
            }                
            System.assertEquals(true, errorMessage!=null, 'Expecting an error message');
            Test.StopTest();
        }
    }

    /**
    * @description Test for send request of programs and fees to DSJ API for opportunity 
    */
    @isTest
    static void testMxSendRequestFailure500(){
        CDdFeeOnboardingService requestService =  new CDdFeeOnboardingService();
        CDdFeeOnboardingAPIServiceInterface apiService =  new CDdFeeOnboardingApiService();
        CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = null;
        String errorMessage = null;

        System.runAs(getTestRunUser()){

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;

            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);
            // store accounts     
            List<Account> accounts = new List<Account>();
            accounts.add(parentAcct);
            accounts.add(childAcct);
            upsert accounts;
            // store contacts
            List<Contact> contacts = new List<Contact>();
            contacts.add(contact);
            upsert contacts;
            // update child account
            childAcct.ParentId = parentAcct.Id;
            upsert childAcct;           
            // store opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity closedWonOpportunity = CDdFeeOnboardingServiceTest.createPostSaleCaviarOpportunity('Test Closed Opp', childAcct.Id, contact.Id, 'Closed Won');
            //closedWonOpportunity.Menu_to_be_completed_by__c = null;
            //closedWonOpportunity.Menu_Setup_Method__c =  null;
            closedWonOpportunity.Tablet_Kit_Type__c = null;
            closedWonOpportunity.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
           
            opportunities.add(closedWonOpportunity);
            upsert opportunities;

            Map<String, Set<String>> programAndFeeDeveloperNames = new Map<String, Set<String>>();
            programAndFeeDeveloperNames.put('Marketplace_Delivery', new Set<String>{'Marketplace_Delivery_Fee'});

            Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new FeeOnboardingHttpCallout500Mock());
            try {
                CDdRestJSONObj.MxFeeOnboardingRequest mxProgramFeeRequest = requestService.getMxFeeOnboardingRequest(closedWonOpportunity.Id, programAndFeeDeveloperNames);
                new CDdFeeOnboardingDSJApiService().sendRequest(CDdFeeOnboardingApiType.MX_PROGRAM_FEE, mxProgramFeeRequest);
            }catch(CDdFeeOnboardingException e){
                errorMessage = CDdFeeOnboardingException.getErrorMessage(e);
            }                
            System.assertEquals(true, errorMessage!=null, 'Expecting an error message');
            System.assertEquals(true, errorMessage.contains(TEST_REFERENCE_ID), 'Expecting the error message to contain the reference id ' + TEST_REFERENCE_ID);
            Test.StopTest();
        }
    }    

    /**
    * @description Test for send request of programs and fees to DSJ API for opportunity
    */
    @IsTest
    static void testCxSendRequestSuccess(){
        CDdFeeOnboardingService requestService =  new CDdFeeOnboardingService();
        CDdFeeOnboardingAPIServiceInterface apiService =  new CDdFeeOnboardingApiService();
        CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = null;

        System.runAs(getTestRunUser()){

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;

            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);
            // store accounts
            List<Account> accounts = new List<Account>();
            accounts.add(parentAcct);
            accounts.add(childAcct);
            upsert accounts;
            // store contacts
            List<Contact> contacts = new List<Contact>();
            contacts.add(contact);
            upsert contacts;
            // update child account
            childAcct.ParentId = parentAcct.Id;
            upsert childAcct;
            // store opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity closedWonOpportunity = CDdFeeOnboardingServiceTest.createPostSaleCaviarOpportunity('Test Closed Opp', childAcct.Id, contact.Id, 'Closed Won');
            //closedWonOpportunity.Menu_to_be_completed_by__c = null;
            //closedWonOpportunity.Menu_Setup_Method__c =  null;
            closedWonOpportunity.Tablet_Kit_Type__c = null;
            closedWonOpportunity.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;

            opportunities.add(closedWonOpportunity);
            upsert opportunities;

            TDdOpportunityLineItemFactory.createProducts();
            List<OpportunityLineItem> olis = TDdOpportunityLineItemFactory.createOpportunityProducts(closedWonOpportunity.Id);
            insert olis;

            Map<String, Set<String>> programAndFeeDeveloperNames = new Map<String, Set<String>>();
            programAndFeeDeveloperNames.put(CDdFeeOnboardingService.PROGRAM_NONE, new Set<String> { 'Customer_Delivery_Fee' });

            Test.StartTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_fee_onboarding_Cx_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);
            CDdRestJSONObj.CxFeeOnboardingRequest cxFeeRequest = requestService.getCxFeeOnboardingRequest(closedWonOpportunity.Id);
            apiService.addRequest(CDdFeeOnboardingApiType.CX_STOREFRONT_FEE, cxFeeRequest);
            feeOnboardingResponse = apiService.sendRequest(CDdFeeOnboardingApiType.CX_STOREFRONT_FEE);
            System.assertEquals(true, feeOnboardingResponse!=null, 'Expecting a valid fee onboarding info object');
            Test.StopTest();
        }
    }
    /**
    * @description Test for send request of programs and fees to DSJ API for opportunity
    */
    @IsTest
    static void testCxSendRequestFailure(){
        CDdFeeOnboardingService requestService =  new CDdFeeOnboardingService();
        CDdFeeOnboardingAPIServiceInterface apiService =  new CDdFeeOnboardingApiService();
        CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = null;
        String errorMessage = null;

        System.runAs(getTestRunUser()){

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;
                        
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);
            // store accounts
            List<Account> accounts = new List<Account>();
            accounts.add(parentAcct);
            accounts.add(childAcct);
            upsert accounts;
            // store contacts
            List<Contact> contacts = new List<Contact>();
            contacts.add(contact);
            upsert contacts;
            // update child account
            childAcct.ParentId = parentAcct.Id;
            upsert childAcct;
            // store opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity closedWonOpportunity = CDdFeeOnboardingServiceTest.createPostSaleCaviarOpportunity('Test Closed Opp', childAcct.Id, contact.Id, 'Closed Won');
            //closedWonOpportunity.Menu_to_be_completed_by__c = null;
            //closedWonOpportunity.Menu_Setup_Method__c =  null;
            closedWonOpportunity.Tablet_Kit_Type__c = null;
            closedWonOpportunity.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;

            opportunities.add(closedWonOpportunity);
            upsert opportunities;

            Map<String, Set<String>> programAndFeeDeveloperNames = new Map<String, Set<String>>();
            programAndFeeDeveloperNames.put(CDdFeeOnboardingService.PROGRAM_NONE, new Set<String>{ 'Customer_Delivery_Fee' });

            Test.StartTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_fee_onboarding_Cx_failure');
            mock.setStatusCode(400);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);
            try {
                CDdRestJSONObj.CxFeeOnboardingRequest cxFeeRequest = requestService.getCxFeeOnboardingRequest(closedWonOpportunity.Id);
                apiService.addRequest(CDdFeeOnboardingApiType.CX_STOREFRONT_FEE, cxFeeRequest);
                feeOnboardingResponse = apiService.sendRequest(CDdFeeOnboardingApiType.CX_STOREFRONT_FEE);
            }catch(CDdFeeOnboardingException e){
                errorMessage = CDdFeeOnboardingException.getErrorMessage(e);
            }                
            System.assertEquals(true, errorMessage!=null, 'Expecting an error message');
            Test.StopTest();
        }
    }

    public class FeeOnboardingHttpCallout500Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('<p>' + 'reference id: ' + TEST_REFERENCE_ID + '</p>');
            res.setStatusCode(500);
            return res;
        }        
    }
}