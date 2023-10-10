/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/06/2020
*
* @group Service Test
*
* @description Test for Fee Onboarding Service
**************************************************************************************************************************************/
@isTest
public class CDdFeeOnboardingServiceTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_ACCOUNT_PARENT_IDENTIFIERS = 'TestDDAccountParent%';
    public static final String TEST_DD_ACCOUNT_CHILD_IDENTIFIERS = 'TestDDAccountChild%';
    public static final String TEST_DD_OPPORTUNITY_0 = 'TestOpportunity0';
    public static final String TEST_DD_OPPORTUNITY_1 = 'TestOpportunity1';
    public static final String TEST_DD_OPPORTUNITY_2 = 'TestOpportunity2';
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1 = 122222;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2 = 122223;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_3 = 122224;
    public static final Id PARENT_ACCOUNT_RECORD_TYPE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final RecordType OPPORTUNITY_RECORD_TYPE_POST_SALE;
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        PARENT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        OPPORTUNITY_RECORD_TYPE_POST_SALE = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Post_Sale'];       
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
   /** 
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){
            Test.startTest();

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;            

            E2F__FindApi_Triggers_Settings__c findAPISettings = new E2F__FindApi_Triggers_Settings__c(
                                                                SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID
                                                                , Name = 'System Administrator'
                                                                , E2F__Bypass_Trigger__c = true
                                                            );
            insert findAPISettings;

            Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
            cp.Name = 'Main';
            cp.Opportunity_Trigger_Enabled__c = true;
            cp.Account_Trigger_Enabled__c = true;
            upsert cp;

            vCS__c s = VTestUtil.createVeltigSettings();
            s.parentAccMatchFlag__c = true;
            s.copyFieldsFromParent__c = true;
            s.SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID;
            insert s;


            List<Account> testAccounts = TDdAccountFactory.createAccounts('TestDDAccount', 6);
            Account testAcct0 = testAccounts[0];
            testAcct0.Name = 'TestDDAccountChild0';
            Account testAcct1 = testAccounts[1];
            testAcct1.Name = 'TestDDAccountChild1';
            testAcct1.Lead_Type__c = 'Outside';
            testAcct1.Deck_Rank__c = 'Ace';         
            Account testAcct2 = testAccounts[2];
            testAcct2.Name = 'TestDDAccountChild2';
            testAcct2.Lead_Type__c = 'Inside';
            testAcct2.Deck_Rank__c = 'Ace'; 
            // Create Test Parent Accounts
            Account testAcct3 = testAccounts[3];
            testAcct3.Name = 'TestDDAccountParent0';
            testAcct3.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct3.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1;
            Account testAcct4 = testAccounts[4];
            testAcct4.Name = 'TestDDAccountParent1';
            testAcct4.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct4.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2;
            Account testAcct5 = testAccounts[5];
            testAcct5.Name = 'TestDDAccountParent2';
            testAcct5.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct5.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_3;                         
            // Insert Accounts
            insert testAccounts;
            // Perform update for child accounts
            List<Account> parentAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_PARENT_IDENTIFIERS];
            List<Account> childAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_CHILD_IDENTIFIERS];
            for (Integer i = 0; i < childAccounts.size(); i++) {
                childAccounts[i].ParentId = parentAccounts[i].Id;
                childAccounts[i].Deck_Rank__c = 'Queen';                // A rank of 5
                childAccounts[i].Amount__c = 200.00;
            }
            update childAccounts;            
            
            Contact testContact1 = TDdAccountFactory.createContacts(1, testAcct1.Id)[0];
            testContact1.FirstName = 'TestDDContactFirstName1';
            testContact1.LastName = 'TestDDContactLastName1';
            testContact1.Email = 'TestDDContactEmail1' + '@tes.com';
            Contact testContact2 = TDdAccountFactory.createContacts(1, testAcct2.Id)[0];
            testContact2.FirstName = 'TestDDContactFirstName2';
            testContact2.LastName = 'TestDDContactLastName2';
            testContact2.Email = 'TestDDContactEmail2' + '@tes.com';
            Contact testContact3 = TDdAccountFactory.createContacts(1, testAcct3.Id)[0];
            testContact3.FirstName = 'TestDDContactFirstName3';
            testContact3.LastName = 'TestDDContactLastName3';
            testContact3.Email = 'TestDDContactEmail3' + '@tes.com';
            List<Contact> testContacts = new List<Contact>{testContact1, testContact2, testContact3};                 
            insert testContacts;

            Opportunity testOpp1 = TDdOpportunityFactory.createOpportunity(TEST_DD_OPPORTUNITY_0, testAcct0.Id, testContact1.Id, 'Closed Won');
            testOpp1.Menu_Completion_Date__c = System.today();
            testOpp1.Commission__c = 5;
            testOpp1.In_App_Pickup_Commission__c = null;  
            testOpp1.DashPass_Only_Commission__c = null;  
            testOpp1.Referred_Delivery_Commission__c = null;  
            testOpp1.Referred_Pickup_Commission__c = null;
            
            //testOpp1.Menu_to_be_completed_by__c = null;
            //testOpp1.Menu_Setup_Method__c =  null;
            testOpp1.Tablet_Kit_Type__c = null;
            testOpp1.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;

            Opportunity testOpp2 = TDdOpportunityFactory.createOpportunity(TEST_DD_OPPORTUNITY_1, testAcct1.Id, testContact1.Id, 'New');
            testOpp2.Menu_Completion_Date__c = System.today();
            testOpp2.Commission__c = 5;
            testOpp2.In_App_Pickup_Commission__c = 5;  
            testOpp2.DashPass_Only_Commission__c = 5;  
            testOpp2.Referred_Delivery_Commission__c = 5;  
            testOpp2.Referred_Pickup_Commission__c = 5;
            
            //testOpp2.Menu_to_be_completed_by__c = null;
            //testOpp2.Menu_Setup_Method__c =  null;
            testOpp2.Tablet_Kit_Type__c = null;
            testOpp2.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;

            Opportunity testOpp3 = createPostSaleCaviarOpportunity(TEST_DD_OPPORTUNITY_2, testAcct2.Id, testContact2.Id, 'Closed Won');
            
            //testOpp3.Menu_to_be_completed_by__c = null;
            //testOpp3.Menu_Setup_Method__c =  null;
            testOpp3.Tablet_Kit_Type__c = null;
            testOpp3.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;

            List<Opportunity> testOpps = new List<Opportunity>{testOpp1, testOpp2, testOpp3};            
            insert testOpps;

            TDdOpportunityLineItemFactory.createProducts();

            Test.getEventBus().deliver();
            Test.stopTest();
        }
    }
    /**
    * @description Test for invalid opportunity
    */
    @isTest
    static void testInvalidOpportunityId(){
        String errorMessage = null;
        System.runAs(getTestRunUser()){    
            try {
                new CDdFeeOnboardingService().getEligiblePrograms(null);
            } catch (Exception e){
                errorMessage = e.getMessage();
            }
            System.assertEquals(true, errorMessage!=null, 'Expecting error for invalid opportunity');            
        }
    }
    /**
    * @description Test for opportunity not closed won
    */
    @isTest
    static void testForOpportunityNotClosed(){
        String errorMessage = null;
        System.runAs(getTestRunUser()){    
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_1 LIMIT 1]; 
            try {
                new CDdFeeOnboardingService().getEligiblePrograms(opportunity.Id);
            } catch (Exception e){
                errorMessage = e.getMessage();
            }
            System.assertEquals(true, errorMessage!=null, 'Expecting error for opportunity not \'Closed Won\'');            
        }
    }    
    /**
    * @description Test for opportunity with no eligible programs
    */
    @isTest
    static void testForOpportunityWithNoEligiblePrograms(){
        String errorMessage = null;
        System.runAs(getTestRunUser()){
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_0 LIMIT 1];     
            try {
                new CDdFeeOnboardingService().getEligiblePrograms(opportunity.Id);
            } catch (Exception e){
                errorMessage = e.getMessage();
            }
            System.assertEquals(true, errorMessage!=null, 'Expecting error for opportunity with no eligible programs');            
        }
    }
    /**
    * @description Test for opportunity with eligible programs
    */
    @isTest
    static void testForOpportunityWithEligiblePrograms(){
        String errorMessage = null;
        Map<String, MxAffiliateProgram__mdt> eligiblePrograms = null;
        System.runAs(getTestRunUser()){
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_2 LIMIT 1];     
            try {
                eligiblePrograms = new CDdFeeOnboardingService().getEligiblePrograms(opportunity.Id);
            } catch (Exception e){
                errorMessage = e.getMessage();
            }
            System.assertEquals(true, eligiblePrograms!=null, 'Expecting eligible programs for Opportunity');              
        }
    }
    /**
    * @description Test for opportunity with no products
    */
    @isTest
    static void testGetFeeOnboardingRequestForOpportunityWithNoProducts1(){
        String errorMessage = null;
        Map<String, MxAffiliateProgram__mdt> eligiblePrograms = null;
        CDdRestJSONObj.MxFeeOnboardingRequest request = null;
        CDdFeeOnboardingService service =  new CDdFeeOnboardingService();
        System.runAs(getTestRunUser()){
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_2 LIMIT 1];     
            try {
                eligiblePrograms = service.getEligiblePrograms(opportunity.Id);
                request = service.getFeeOnboardingRequest(opportunity.Id, eligiblePrograms.keySet());
            } catch (Exception e){
                errorMessage = e.getMessage();
            }
            System.assertEquals(true, eligiblePrograms!=null, 'Expecting eligible programs for Opportunity');
            System.assertEquals(true, request!=null, 'Expecting a valid fee onboarding request');                        
        }
    }
    /**
    * @description Test for opportunity with no products
    */
    @isTest
    static void testGetFeeOnboardingRequestForOpportunityWithNoProducts2(){
        String errorMessage = null;
        CDdRestJSONObj.MxFeeOnboardingRequest request = null;
        CDdFeeOnboardingService service =  new CDdFeeOnboardingService();
        System.runAs(getTestRunUser()){
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_2 LIMIT 1];     

            Map<String, Set<String>> programAndFeeDeveloperNames = new Map<String, Set<String>>();
            programAndFeeDeveloperNames.put('Marketplace_Delivery', new Set<String>{'Marketplace_Delivery_Fee_01'});
            programAndFeeDeveloperNames.put('Marketplace_Pickup', new Set<String>());
            request = service.getMxFeeOnboardingRequest(opportunity.Id, programAndFeeDeveloperNames);

            System.assertEquals(true, request!=null, 'Expecting a valid fee onboarding request');
            System.assertEquals(true, !request.programs.isEmpty(), 'Expecting 2 programs within the fee onboarding request');
            System.assertEquals(true, request.programs.size() == 2, 'Expecting 2 programs within the fee onboarding request');
            System.assertEquals(true, !request.programs[0].fee_attributes.isEmpty(), 'Expecting a fee atrribute within program \'Marketplace_Delivery\' of fee onboarding request'); 
            System.assertEquals(true, request.programs[1].fee_attributes.isEmpty(), 'Expecting no fee atrribute within program \'Marketplace_Pickup\' of fee onboarding request');                      
        }
    }    
    /**
    * @description Test for opportunity with no products
    */
    @isTest
    static void testGetFeeOnboardingRequestForOpportunityProducts1(){
        String errorMessage = null;
        Map<String, MxAffiliateProgram__mdt> eligiblePrograms = null;
        CDdRestJSONObj.MxFeeOnboardingRequest request = null;
        CDdFeeOnboardingService service =  new CDdFeeOnboardingService();
        System.runAs(getTestRunUser()){
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_2 LIMIT 1];
            List<PriceBookEntry> priceBookEntries = [SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id, 
                                                    Product2Id, ProductCode, UnitPrice, UseStandardPrice,
                                                    Product2.Name, Product2.Family
                                                    FROM PricebookEntry
                                                    WHERE Name IN :TDdOpportunityLineItemFactory.PRODUCT_NAME_AND_FAMILY.keySet()];
            PriceBookEntry promotionsPriceBookEntry = null;
            for (PriceBookEntry priceBookEntry : priceBookEntries){
                if ('Promotions'.equals(priceBookEntry.Product2.Family)){
                    promotionsPriceBookEntry = priceBookEntry;
                }
            }                                       
            Test.StartTest();
            List<OpportunityLineItem> opportunityProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunity.Id, priceBookEntries);
            for (OpportunityLineItem opportunityProduct : opportunityProducts){
                if (opportunityProduct.PricebookEntryId.equals(promotionsPriceBookEntry.Id)){
                    opportunityProduct.Billing_Frequency__c = 'Quarterly';
                    opportunityProduct.Commission_Rate__c = 1.00;
                    opportunityProduct.Service_Fee__c = 1.00;
                }
            }
            insert opportunityProducts;            
            Test.StopTest();
            eligiblePrograms = service.getEligiblePrograms(opportunity.Id);
            request = service.getFeeOnboardingRequest(opportunity.Id, eligiblePrograms.keySet());
            System.assertEquals(true, eligiblePrograms!=null, 'Expecting eligible programs for Opportunity');
            System.assertEquals(true, request!=null, 'Expecting a valid fee onboarding request');                        
        }
    }
    /**
    * @description Test for opportunity with no products
    */
    @isTest
    static void testGetFeeOnboardingRequestForOpportunityProducts2(){
        String errorMessage = null;
        CDdRestJSONObj.MxFeeOnboardingRequest request = null;
        CDdFeeOnboardingService service =  new CDdFeeOnboardingService();
        System.runAs(getTestRunUser()){
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_2 LIMIT 1];
            List<PriceBookEntry> priceBookEntries = [SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id, 
                                                    Product2Id, ProductCode, UnitPrice, UseStandardPrice,
                                                    Product2.Name, Product2.Family
                                                    FROM PricebookEntry
                                                    WHERE Name IN :TDdOpportunityLineItemFactory.PRODUCT_NAME_AND_FAMILY.keySet()];
            PriceBookEntry promotionsPriceBookEntry = null;
            for (PriceBookEntry priceBookEntry : priceBookEntries){
                if ('Promotions'.equals(priceBookEntry.Product2.Family)){
                    promotionsPriceBookEntry = priceBookEntry;
                }
            }                                       
            Test.StartTest();
            List<OpportunityLineItem> opportunityProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunity.Id, priceBookEntries);
            for (OpportunityLineItem opportunityProduct : opportunityProducts){
                if (opportunityProduct.PricebookEntryId.equals(promotionsPriceBookEntry.Id)){
                    opportunityProduct.Billing_Frequency__c = 'Quarterly';
                    opportunityProduct.Commission_Rate__c = 1.00;
                    opportunityProduct.Service_Fee__c = 1.00;
                }
            }
            insert opportunityProducts;            
            Test.StopTest();

            Map<String, Set<String>> programAndFeeDeveloperNames = new Map<String, Set<String>>();
            programAndFeeDeveloperNames.put('Online_Ordering_Delivery', new Set<String>{'Online_Ordering_Delivery_Fee_01','Online_Ordering_Processing_Fee_01'});
            programAndFeeDeveloperNames.put('Online_Ordering_Pickup', new Set<String>{'Online_Ordering_Pickup_Fee_01'});
            request = service.getMxFeeOnboardingRequest(opportunity.Id, programAndFeeDeveloperNames);

            System.assertEquals(true, request!=null, 'Expecting a valid fee onboarding request');
            System.assertEquals(true, !request.programs.isEmpty(), 'Expecting 2 programs within the fee onboarding request');
            System.assertEquals(true, request.programs.size() == 2, 'Expecting 2 programs within the fee onboarding request');
            System.assertEquals(true, !request.programs[0].fee_attributes.isEmpty(), 'Expecting 2 fee atrributes within program \'Online_Ordering_Delivery\' of fee onboarding request');
            System.assertEquals(true, request.programs[0].fee_attributes.size() == 2, 'Expecting 2 fee atrributes within program \'Online_Ordering_Delivery\' of fee onboarding request');
            System.assertEquals(true, !request.programs[1].fee_attributes.isEmpty(), 'Expecting 1 fee atrributes within program \'Online_Ordering_Pickup\' of fee onboarding request');
            System.assertEquals(true, request.programs[1].fee_attributes.size() == 1, 'Expecting 1 fee atrributes within program \'Online_Ordering_Pickup\' of fee onboarding request');                              
        }
    }

    @IsTest
    public static void testConvertDateToDatetime() {
        Date today = Date.today();
        Date tomorrow = Date.today().addDays(1);
        Date yesterday = Date.today().addDays(-1);

        // Start date should default to today if null
        Datetime dtm = CDdFeeOnboardingService.dateTimeUTC(today, true, null);
        System.assertEquals(today, Datetime.now().date());

        // Start date should default to today if in the past
        dtm = CDdFeeOnboardingService.dateTimeUTC(yesterday, true, null);
        System.assertEquals(today, Datetime.now().date());

        // Start date should be preserved if in the future
        dtm = CDdFeeOnboardingService.dateTimeUTC(tomorrow, true, null);
        System.assertEquals(tomorrow, dtm.dateGmt());
        System.assertEquals(Time.newInstance(0,0,0,0), dtm.timeGmt());

        // End date should be preserved if in the future
        dtm = CDdFeeOnboardingService.dateTimeUTC(tomorrow, false, null);
        System.assertEquals(tomorrow, dtm.dateGmt());
        System.assertEquals(Time.newInstance(23,59,59,0), dtm.timeGmt());

        // End date should be preserved if in the past
        dtm = CDdFeeOnboardingService.dateTimeUTC(yesterday, false, null);
        System.assertEquals(yesterday, dtm.dateGmt());
        System.assertEquals(Time.newInstance(23,59,59,0), dtm.timeGmt());

    }

    public static Opportunity createPostSaleCaviarOpportunity(String name, String accountId, String contactId, String stageName) {
        Opportunity opportunity = TDdOpportunityFactory.createOpportunity(name, accountId, contactId, stageName, OPPORTUNITY_RECORD_TYPE_POST_SALE);
        opportunity.Type = 'In-Store Marketing';
        opportunity.PactSafe_Contract_Type__c = 'Post Sale Paper Addendum';
        opportunity.Platform__c = CDdFeeOnboardingService.PLATFORM_CAVIAR;
        opportunity.Activate_Centrally_2__c = 'No';
        opportunity.Caviar_Order_Protocol__c = 'Email';
        opportunity.Order_Protocol_Email__c = 'caviar.test@doordash.com';
        opportunity.Caviar_Photo_Folder_URL__c = 'http://fakeurl.com/thisshouldntexist';
        opportunity.Caviar_Offer_Document_URL__c = 'http://fakeurl.com/thisshouldntexist';
        opportunity.Caviar_Onboarding_Type__c = 'Traditional Onboarding';                        
        opportunity.Commission__c = 5;
        opportunity.In_App_Pickup_Commission__c = 5;  
        opportunity.DashPass_Only_Commission__c = 5;  
        opportunity.Referred_Delivery_Commission__c = 5;  
        opportunity.Referred_Pickup_Commission__c = 5; 
        return opportunity;
    }                                                
}