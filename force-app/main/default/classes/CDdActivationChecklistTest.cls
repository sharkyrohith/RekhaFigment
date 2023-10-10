/**
 * Created by Jeremy S. Johnson, Perficient, Inc.
 */

 @IsTest
 public with sharing class CDdActivationChecklistTest {
     final static String storeId = '766918';
     final static String urlStore = 'https://api.doordash.com/v1/stores/766918/?' +
             'extra=address' +
             '&extra=business.is_active' +
             '&extra=order_protocol' +
             '&extra=confirm_protocol' +
             '&extra=phone_number' +
             '&extra=is_partner' +
             '&extra=payment_account_id' +
             '&extra=starting_point_id';
     final static String urlMenuSandbox = 'callout:App_Cloud_Dev/grpc-services-client-dd-dev/api/storeMenu/' + storeId;
     final static String urlMenuPROD = 'callout:App_Cloud/grpc-services-client-dd-prod/api/storeMenu/' + storeId;
     final static String srStore = 'mockResponse_DSJ_ActivationChecklist_Store';
     final static String srMenu = 'mockResponse_DSJ_ActivationChecklist_Menu';
     final static String merchantDataService_addressById = 'callout:Merchant_Data_Service/api/v1/addresses/267439327/';
     final static String appCloudStoreSandbox = 'callout:App_Cloud_Dev/datasvc/data/stores/766918';
     final static String appCloudStoreProd = 'callout:App_Cloud/datasvc/data/stores/766918';
     final static String appCloudBusinessSandbox = 'callout:App_Cloud_Dev/datasvc/data/businesses/794472';
     final static String appCloudBusinessProd = 'callout:App_Cloud/datasvc/data/businesses/794472';
     final static String appCloudPaymentSandbox = 'callout:App_Cloud_Dev/datasvc/data/paymentDetails/953709';
     final static String appCloudPaymentProd = 'callout:App_Cloud/datasvc/data/paymentDetails/953709';
     public static final Id TEST_ROLE_ID;
     public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
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

     @testSetup
     static void setup() {
         Test.startTest();
         vCS__c s = VTestUtil.createVeltigSettings();
         s.S2N_Store_Feature_Flag__c = true;
         insert s;
         Test.stopTest();
     }

     public static void setUpPass() {
         Account account = TDdAccountFactory.createAccounts('Activation Checklist Test', 1, 'Marketplace')[0];
         account.Is_Active__c = true;
         account.Payment_Account_ID__c = storeId;
         account.Restaurant_ID__c = storeId;
         account.iPad_Password__c = 'test';
         account.iPad_Username__c = 'test';
         account.Phone = '(526) 667-5302';
         account.Starting_Point_ID__c = 1234.0;
         insert account;

         Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
         insert contact;

         List<Opportunity> opportunities = new List<Opportunity>();
         opportunities.add(TDdOpportunityFactory.createOpportunity('Slices Pizza', account.Id, contact.Id, 'Closed Won'));
         opportunities.add(TDdOpportunityFactory.createOpportunity('Slices Pizza', account.Id, contact.Id, 'New'));
         for (Opportunity o : opportunities){
             o.Proposed_Date_of_Activation__c = Date.today();
         }
         insert opportunities;

         List<Case> cases = new List<Case>();
         List<Case> relatedCases = [select Id, Status from Case];
         for(Case relatedCase : relatedCases) {
             relatedCase.Status = 'Closed';
             relatedCase.Menu_Completion_Date__c = Date.today();
             relatedCase.Store_ID__c = storeId;
             relatedCase.Menu_Preview_Links__c = 'https://doordash.com.test';
             cases.add(relatedCase);
         }

         Case tabletCase = TDdCaseFactory.createCaseRecords(1, 'Tablet Requests')[0];
         tabletCase.Origin = 'New Tablet Request';
         tabletCase.Return_Shipping_Address_State__c = 'Florida';
         tabletCase.AccountId = account.Id;
         tabletCase.Opportunity_Name__c = opportunities[0].Id;
         cases.add(tabletCase);

         upsert cases;

     }

     @IsTest
     public static void positiveTests() {
        setUpPass();
        Id caseId = [Select Id From Case limit 1].Id;

        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        mock.setStaticResource(merchantDataService_addressById,'mockResponse_getAddressById_success');
        mock.setStaticResource(urlStore, srStore);
        if(CddUtilities.getIsSandbox()){
            mock.setStaticResource(urlMenuSandbox, srMenu);
            mock.setStaticResource(appCloudStoreSandbox,'mockResponse_Appcloud_getStore_success');
            mock.setStaticResource(appCloudBusinessSandbox,'mockResponse_Appcloud_getBusiness_success');
            mock.setStaticResource(appCloudPaymentSandbox,'mockResponse_Appcloud_getPayment_success');
        }else{
            mock.setStaticResource(urlMenuPROD, srMenu);
            mock.setStaticResource(appCloudStoreProd,'mockResponse_Appcloud_getStore_success');
            mock.setStaticResource(appCloudBusinessProd,'mockResponse_Appcloud_getBusiness_success');
            mock.setStaticResource(appCloudPaymentProd,'mockResponse_Appcloud_getPayment_success');
        }
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CDdActivationChecklist.isMarketplaceOnboardingEnabled = false;
        CDdActivationChecklistController.validate(caseId);
        List<Activation_Checklist__c> steps = CDdActivationChecklistController.getChecklist(caseId);
        List<Activation_Checklist__c> resolved = new List<Activation_Checklist__c>();
        for(Activation_Checklist__c step : steps) {
            if(!'Pass'.equals(step.Original_Status__c)) {
                step.Resolved__c = true;
                resolved.add(step);
            }
        }
        CDdActivationChecklistController.resolveItems(caseId, resolved);
        Test.stopTest();

        System.assertEquals(18, steps.size(), 'Unexepected checkList.size().');

        for(Activation_Checklist__c step : steps) {
            String developerName = step.Developer_Name__c;
            System.assertNotEquals(null, step.Developer_Name__c, 'Unexpected value for Developer_Name__c (' + developerName + ').');
            System.assertEquals('Pass', step.Original_Status__c, 'Unexpected value for Original_Status__c (' + developerName + ').');
            System.assertEquals(false, step.Resolved__c, 'Unexpected value for Resolved__c (' + developerName + ').');
            System.assertEquals('Pass', step.Status__c, 'Unexpected value for Status__c (' + developerName + ').');
        }
    }

     @IsTest static void negativeTests() {
         Map<String, Activation_Checklist__c> checklist = new Map<String, Activation_Checklist__c>();

         Case aCase = createCase();

         String storeResponse = '{' +
                 '"name": "Name 2",' +
                 '"business":{"name":"Name 3", "is_active":false},' +
                 '"phone_number": "(098) 765-4321",' +
                 '"order_protocol":"IPAD",' +
                 '"is_partner":false,' +
                 '"starting_point_id":2345,' +
                 '"is_active":false' +
                 '}';
         CDdActivationChecklist.Store store = (CDdActivationChecklist.Store)JSON.deserialize(storeResponse, CDdActivationChecklist.Store.class);

         String menuResponse = '{"storeMenu": {"structure": {"menus": [{"id": "2080361","title": {"defaultOrResolvedValue": "GCK US UNI"},"isActive": true}]}}}';
         CDdActivationChecklist.MenuLinks menuLinks = (CDdActivationChecklist.MenuLinks) JSON.deserialize(menuResponse, CDdActivationChecklist.menuLinks.class);

         CDdActivationChecklist checker = new CDdActivationChecklist(storeId, aCase, checklist,null, null, store, null, menuLinks);

         checker.checkStorePhone();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkCurrentCaseStatus();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkOpportunityStage();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkProposedDateOfActivation();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkSFBankInfo();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkStoreOrderProtocol();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkOrderAndConfirmProtocol();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkIsActive();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkIsPartner();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkStoreName();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkStartingPoint();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();

         checker.checkPaymentAccount();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
         checker.checklist.clear();
     }

     /* Nathalie Mendezona - BASD-30363 */
     @IsTest static void nzPhoneTest() {
         Map<String, Activation_Checklist__c> checklist = new Map<String, Activation_Checklist__c>();
         Account account = new Account(Phone='+6449184723',BillingCountryCode='NZ',Entity_Type__c=null);
         Opportunity opp = new Opportunity(
                 Name = 'Name 1',
                 StageName = '',
                 Proposed_Date_of_Activation__c = Date.today().addDays(1),
                 Order_Protocol__c = 'Fax');
         Case aCase = new Case(Account=account, Opportunity_Name__r=opp, Status='Closed');

         String storeResponse = '{' +
                 '"name": "Name 2",' +
                 '"business":{"name":"Name 3", "is_active":false},' +
                 '"phone_number": "04-918 4723",' +
                 '"order_protocol":"IPAD",' +
                 '"is_partner":false,' +
                 '"starting_point_id":2345,' +
                 '"is_active":false' +
                 '}';
         CDdActivationChecklist.Store store = (CDdActivationChecklist.Store)JSON.deserialize(storeResponse, CDdActivationChecklist.Store.class);

         CDdActivationChecklist checker = new CDdActivationChecklist(storeId, aCase, checklist,null, null, store, null, null);

         checker.checkStorePhone();
         System.assertEquals('Pass', checker.checklist.values()[0].Status__c);
     }

     /* Jitendra Baghela - BZAP-15494 */
     @IsTest static void nzEINTest() {
         Map<String, Activation_Checklist__c> checklist = new Map<String, Activation_Checklist__c>();
         Account account = new Account(Phone='+6449184723',BillingCountryCode='NZ',Entity_Type__c='Sole proprietorship', EIN_Encrypted__c= null, Legal_Business_Name__c = 'test',Bank_Account_Number_Encrypted__c = '1234',Bank_Routing_Number_Encrypted__c='12345');
         Opportunity opp = new Opportunity(
                 Name = 'Name 1',
                 StageName = '',
                 Proposed_Date_of_Activation__c = Date.today().addDays(1),
                 Order_Protocol__c = 'Fax');
         Case aCase = new Case(Account=account, Opportunity_Name__r=opp, Status='Closed');

         String storeResponse = '{' +
                 '"name": "Name 2",' +
                 '"business":{"name":"Name 3", "is_active":false},' +
                 '"phone_number": "04-918 4723",' +
                 '"order_protocol":"IPAD",' +
                 '"is_partner":false,' +
                 '"starting_point_id":2345,' +
                 '"is_active":false' +
                 '}';
         CDdActivationChecklist.Store store = (CDdActivationChecklist.Store)JSON.deserialize(storeResponse, CDdActivationChecklist.Store.class);
         test.startTest();

         /* Positive Cases */
         CDdActivationChecklist checker = new CDdActivationChecklist(storeId, aCase, checklist,null, null, store, null, null);
         checker.checkSFBankInfo();
         System.assertEquals('Pass', checker.checklist.values()[0].Status__c);

         Account account1 = new Account(Phone='+6449184723',BillingCountryCode='AU',Entity_Type__c='Sole proprietorship', Mx_Tax_Id_VAT__c = null, Legal_Business_Name__c = 'test',Bank_Account_Number_Encrypted__c = '1234',Bank_Routing_Number_Encrypted__c='12345', EIN_Encrypted__c = '12345');
         Case aCase1 = new Case(Account=account1, Opportunity_Name__r=opp, Status='Closed');
         CDdActivationChecklist checker1 = new CDdActivationChecklist(storeId, aCase1, checklist,null, null, store, null, null);
         checker1.checkSFBankInfo();
         System.assertEquals('Pass', checker1.checklist.values()[0].Status__c);

         /* Negative Cases */
         Account account2 = new Account(Phone='+6449184723',BillingCountryCode='NZ',Entity_Type__c='Company', EIN_Encrypted__c= null);
         Case aCase2 = new Case(Account=account2, Opportunity_Name__r=opp, Status='Closed');
         CDdActivationChecklist checker2 = new CDdActivationChecklist(storeId, aCase2, checklist,null, null, store, null, null);
         checker2.checkSFBankInfo();
         System.assertEquals('Fail', checker2.checklist.values()[0].Status__c);

         Account account3 = new Account(Phone='+6449184723',BillingCountryCode='AU',Entity_Type__c='Company', Mx_Tax_Id_VAT__c = null);
         Case aCase3 = new Case(Account=account3, Opportunity_Name__r=opp, Status='Closed');
         CDdActivationChecklist checker3 = new CDdActivationChecklist(storeId, aCase3, checklist,null, null, store, null, null);
         checker3.checkSFBankInfo();
         System.assertEquals('Fail', checker3.checklist.values()[0].Status__c);
         test.stopTest();
     }

     @isTest
     static void testGermanStreetAddress() {
         String storeAddress = '25 Lautenschlagerstraße';
         String accountAddress = 'Lautenschlagerstr. 25';
         Decimal confidence = 1;
         Test.startTest();
         confidence = CDdActivationChecklist.verifyGermanStreetAddress(confidence,storeAddress, accountAddress);
         System.assertEquals(1, confidence);

         storeAddress = '25 Lautenschlaaße';
         accountAddress = 'Lautenschlagerstr. 25';
         confidence = 1;
         confidence = CDdActivationChecklist.verifyGermanStreetAddress(confidence,storeAddress, accountAddress);
         Test.stopTest();
         System.assertEquals(0.7, confidence);
     }

     @IsTest
     static void testCheckOrderAndConfirmProtocol() {
         System.runAs(getTestRunUser()) {
             StaticResource storeResource = [SELECT Body FROM StaticResource WHERE Name = :srStore LIMIT 1];
             String storeJson = storeResource.Body.toString();

             CDdActivationChecklist.Store store = (CDdActivationChecklist.Store) JSON.deserialize(storeJson, CDdActivationChecklist.Store.class);
             CDdActivationChecklist checker = new CDdActivationChecklist(storeId, createCase(), new Map<String, Activation_Checklist__c>(), null, null, store, null, null);

             Boolean confirmProtocol = CDdExperimentSvc.getFeatureFlag('Enable_Store_Confirm_Protocol_Checklist__c');
             if(confirmProtocol){
                 System.assert(getValidityOfProtocols(checker, 'IPAD', 'NO_CONFIRMATION'), '"NO_CONFIRMATION" Confirm Protocol should result in "Pass" for the "IPAD" Order Protocol if Feature Flag is True.');
                 System.assert(getValidityOfProtocols(checker, 'FAX', 'NO_CONFIRMATION'), '"NO_CONFIRMATION" Confirm Protocol should result in "Pass" for the "FAX" Order Protocol if Feature Flag is True.');
                 System.assert(!getValidityOfProtocols(checker, 'OTHER', 'ROBOCALL_SIMPLE'), '"ROBOCALL_SIMPLE" Confirm Protocol should result in "Fail" for the "OTHER" Order Protocol if Feature Flag is True.');
                 System.assert(getValidityOfProtocols(checker, 'PHONE', 'NO_CONFIRMATION'), '"NO_CONFIRMATION" Confirm Protocol should result in "Pass" for the "PHONE" Order Protocol if Feature Flag is True.');
             } else {
                 System.assert(getValidityOfProtocols(checker, 'IPAD', 'ROBOCALL_SIMPLE'), '"ROBOCALL_SIMPLE" Confirm Protocol should result in "Pass" for the "IPAD" Order Protocol.');
                 System.assert(getValidityOfProtocols(checker, 'FAX', 'ROBOCALL_SIMPLE'), '"ROBOCALL_SIMPLE" Confirm Protocol should result in "Pass" for the "FAX" Order Protocol.');
                 System.assert(getValidityOfProtocols(checker, 'OTHER', 'NO_CONFIRMATION'), '"NO_CONFIRMATION" Confirm Protocol should result in "Pass" for the "OTHER" Order Protocol.');
                 System.assert(getValidityOfProtocols(checker, 'PHONE', 'NO_CONFIRMATION'), '"NO_CONFIRMATION" Confirm Protocol should result in "Pass" for the "PHONE" Order Protocol.');
                 System.assert(!getValidityOfProtocols(checker, 'IPAD', 'NO_CONFIRMATION'), '"NO_CONFIRMATION" Confirm Protocol should result in "Fail" for the "IPAD" Order Protocol.');
                 System.assert(!getValidityOfProtocols(checker, 'IPAD', 'ROBOCALL_LONG_DELAY'), '"ROBOCALL_LONG_DELAY" Confirm Protocol should result in "Fail" for the "IPAD" Order Protocol.');
             }
         }
     }

     @IsTest
     static void testcheckIsMenuPass() {
         Map<String, Activation_Checklist__c> checklist = new Map<String, Activation_Checklist__c>();
         Case aCase = createCase();
         String storeResponse = '{' +
                 '"name": "Name 2",' +
                 '"store_partnership":{"name":"Name 3", "is_partner":null},' +
                 '"phone_number": "04-918 4723",' +
                 '"order_protocol":"IPAD",' +
                 '"is_partner":false,' +
                 '"starting_point_id":2345,' +
                 '"is_active":false' +
                 '}';
         CDdActivationChecklist.Store store = (CDdActivationChecklist.Store)JSON.deserialize(storeResponse, CDdActivationChecklist.Store.class);
         String menuResponse = '{"storeMenu": {"structure": {"menus": [{"id": "2080361","title": {"defaultOrResolvedValue": "GCK US UNI"},"isActive": true}]}}}';
         Test.startTest();
         CDdActivationChecklist.MenuLinks menuLinks = (CDdActivationChecklist.MenuLinks) JSON.deserialize(menuResponse, CDdActivationChecklist.menuLinks.class);
         CDdActivationChecklist checker = new CDdActivationChecklist(storeId, aCase, checklist,null, null, store, null, menuLinks);
         checker.checkStoreMenu();
         System.assertEquals('Pass', checker.checklist.values()[0].Status__c);
         Test.stopTest();
     }

     @IsTest
     static void checkStoreAddress() {
         Case aCase = createCase();
         Test.startTest();
         CDdActivationChecklist checker = new CDdActivationChecklist(null, aCase, new Map<String, Activation_Checklist__c>(),null, null, null, null, null);
         checker.checkStoreAddress();
         Test.stopTest();
         System.assertEquals('Fail', checker.checklist.values()[0].Status__c);
     }

     @IsTest
     static void testcheckIsPartnerNull() {
         Case aCase = createCase();
         String storeResponse = '{' +
                 '"name": "Name 2",' +
                 '"store_partnership":{"name":"Name 3", "is_partner":null},' +
                 '"phone_number": "04-918 4723",' +
                 '"order_protocol":"IPAD",' +
                 '"is_partner":false,' +
                 '"starting_point_id":2345,' +
                 '"is_active":false' +
                 '}';
         Test.startTest();
         CDdActivationChecklist.Store store = (CDdActivationChecklist.Store)JSON.deserialize(storeResponse, CDdActivationChecklist.Store.class);
         CDdActivationChecklist checker = new CDdActivationChecklist(storeId, aCase, new Map<String, Activation_Checklist__c>(),null, null, store, null, null);
         checker.checkIsPartner();
         System.assertEquals('Fail',  checker.checklist.get('N0006').Status__c);
         Test.stopTest();
     }

     @IsTest
     static void testcheckIsPartnerAndAddressBlank() {
         Case aCase = createCase();
         String storeResponse = '{' +
                 '"name": "Name 2",' +
                 '"store_partnership":"",' +
                 '"phone_number": "04-918 4723",' +
                 '"order_protocol":"IPAD",' +
                 '"is_partner":false,' +
                 '"starting_point_id":2345,' +
                 '"is_active":false' +
                 '}';
         Test.startTest();
         CDdActivationChecklist.Store store = new CDdActivationChecklist.Store((Map<String,Object>) JSON.deserializeUntyped(storeResponse));
         CDdActivationChecklist checker = new CDdActivationChecklist(storeId, aCase, new Map<String, Activation_Checklist__c>(),null, null, store, null, null);
         checker.checkIsPartner();
         checker.checkStoreAddress();
         Test.stopTest();
         System.assertEquals('Fail', checker.checklist.get('N0006').Status__c);
         System.assertEquals('Fail', checker.checklist.get('N0004').Status__c);

     }


     /**
         @author: Dan Thoreson
         @date: 23-Jun-2022
         @description:
         @param: CDdActivationChecklist checker - the instance of the ActivationChecklist for validation
         @param: String orderProtocol - the specific Order Protocol for the Store
         @param: String confirmProtocol - the specific Confirm Protocol for the Store
         @return: Boolean - indicating whether the Order/Confirm comparison was a 'Pass' (true) or 'Fail' (false)
     **/
     private static Boolean getValidityOfProtocols(CDdActivationChecklist checker, String orderProtocol, String confirmProtocol) {
         checker.store.order_protocol = orderProtocol;
         checker.store.confirm_protocol = confirmProtocol;
         checker.checkOrderAndConfirmProtocol();

         return 'Pass' == checker.checklist.values()[0].Status__c;
     }

     /**
         @author: Dan Thoreson
         @date: 23-Jun-2022
         @description: Helper method to initialize a Case for testing
         @param: N/A
         @return: Case - the initialized Case object
     **/
     private static Case createCase() {
         Account account = new Account(Phone='(123) 456-7890',BillingCountryCode='DE',Entity_Type__c=null);
         Opportunity opp = new Opportunity(
                 Name = 'Name 1',
                 StageName = '',
                 Proposed_Date_of_Activation__c = Date.today().addDays(1),
                 Order_Protocol__c = 'Fax');

         return new Case(Account=account, Opportunity_Name__r=opp, Status='Closed');
     }
 }