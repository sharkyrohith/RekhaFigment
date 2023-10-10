/*
 * @author Knick
 * @Date Mar 2020
 * @Description: Test Class for CDdOpportunityCaseHelper
*/
@isTest // (isParallel=false)
public class CDdOpportunityCaseHelperTest {

    // In order to test directly, comment out call to CDdOpportunityCaseHelper.createCases in the Opportunity Trigger
    public static final Boolean testDirectly = false;

    @isTest static void checkMetadataTest() {
        system.assertNotEquals(null, CDdOpportunityCaseHelper.businessHoursId);
        system.assertNotEquals(null, CDdOpportunityCaseHelper.menuOrderProtocols);
        system.assertNotEquals(null, CDdOpportunityCaseHelper.tabletOrderProtocols);
        system.assertNotEquals(null, CDdOpportunityCaseHelper.excludedBusinessIDs);
    }

    @isTest static void createOnboardingManagerCaseTest() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];  insert runningUser;
        system.runAs(runningUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
            validation.Bypass_Opportunity_Validations__c = true;  insert validation;
            Account parent = TDdAccountFactory.createAccounts('Parent', 1, 'Parent Account')[0];
            Account child = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
            insert parent;  child.ParentId = parent.Id;  child.Deck_Rank__c = 'King';  insert child;
            Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'ML_Inside_Sales');
            insert opp;
            test.startTest();
                opp.Requesting_Account_Management__c = 'Onboarding Manager';
                opp.StageName = 'Closed Won';
                opp.Activation_Date__c = Date.Today();  // Added per BZAP-7291
                update opp;
                if (testDirectly) { // not currently wired up to trigger
                    List<Id> oppIdList = new List<Id>{opp.Id};
                    CDdOpportunityCaseHelper.createCases(oppIdList);
                } // not currently wired up to trigger
            test.stopTest();
        }
        List<Case> checkCases = [SELECT Id, Subject FROM Case WHERE Subject = 'TEST: Onboarding Manager Handoff Case'];
        system.assertEquals(1, checkCases.size(), 'checkCases: ' + checkCases);
        List<Account> checkAccounts = [SELECT Id, Name, PM_transfer_case_created__c FROM Account];
        system.assertEquals(2, checkAccounts.size());
        for (Account a : checkAccounts)
            if (a.Name == 'Parent')
                system.assertEquals(true, a.PM_transfer_case_created__c);
        List<Opportunity> checkOpportunities = [SELECT Id, Activation_Case_Created__c FROM Opportunity];
        system.assertEquals(1, checkOpportunities.size());
        system.assertEquals(false, checkOpportunities[0].Activation_Case_Created__c);
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        system.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    @isTest static void createMxMarketingRequestTest() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];  insert runningUser;
        system.runAs(runningUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
            validation.Bypass_Opportunity_Validations__c = true;  insert validation;
            Account parent = TDdAccountFactory.createAccounts('Parent', 1, 'Parent Account')[0];
            Account child = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
            insert parent;  child.ParentId = parent.Id;  insert child;
            Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'ML_Inside_Sales');
            insert opp;
            test.startTest();
                opp.CloseDate = Date.newInstance(2018, 09, 10);
                opp.Send_Marketing_Kit__c = true;
                opp.Order_Protocol__c = 'Other';
                opp.StageName = 'Closed Won';
            	//BZAP-9690 Shiva pochamalla added menu to be completed for validation rule
                opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
                opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
                update opp;
                if (testDirectly) { // not currently wired up to trigger
                    List<Id> oppIdList = new List<Id>{opp.Id};
                    CDdOpportunityCaseHelper.createCases(oppIdList);
                } // not currently wired up to trigger
            test.stopTest();
        }
        List<Case> checkCases = [SELECT Id, Subject FROM Case WHERE Subject = 'TEST: MxMarketingRequestCase'];
        system.assertEquals(1, checkCases.size(), 'checkCases: ' + checkCases);
        List<Account> checkAccounts = [SELECT Id FROM Account];
        system.assertEquals(2, checkAccounts.size());
        List<Opportunity> checkOpportunities = [SELECT Id, Mx_Marketing_Request_created__c FROM Opportunity];
        system.assertEquals(1, checkOpportunities.size());
        system.assertEquals(true, checkOpportunities[0].Mx_Marketing_Request_created__c);
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        system.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    @isTest static void createTabletRequestTest() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];  insert runningUser;
        system.runAs(runningUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
            validation.Bypass_Opportunity_Validations__c = true;  insert validation;
            Account parent = TDdAccountFactory.createAccounts('Parent', 1, 'Parent Account')[0];
            Account child = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
            insert parent;  child.ParentId = parent.Id;  insert child;
            Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'ML_Inside_Sales');
            insert opp;
            test.startTest();
                CDdOpportunityCaseHelper.isMarketplaceOnboardingEnabled = false;
                opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
                opp.StageName = 'Closed Won';
            	//BZAP-9690 Shiva pochamalla added menu to be completed for validation rule
                opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
                opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
                update opp;
                if (testDirectly) { // not currently wired up to trigger
                    List<Id> oppIdList = new List<Id>{opp.Id};
                    CDdOpportunityCaseHelper.createCases(oppIdList);
                } // not currently wired up to trigger
            test.stopTest();
        }
        List<Case> checkCases = [SELECT Id, Subject FROM Case WHERE Subject = 'TEST: TabletCase'];
        system.assertEquals(1, checkCases.size(), 'checkCases: ' + checkCases);
        List<Account> checkAccounts = [SELECT Id FROM Account];
        system.assertEquals(2, checkAccounts.size());
        List<Opportunity> checkOpportunities = [SELECT Id, Tablet_Case_Created__c FROM Opportunity];
        system.assertEquals(1, checkOpportunities.size());
        system.assertEquals(true, checkOpportunities[0].Tablet_Case_Created__c);
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        system.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

        /*
         * @author Mani.
         * Test class case for, If related Accounts country on Opportunity is Japan, Map the Kanji address fields to case address fields
         * */
        @isTest static void createTabletRequestTestForAccountWithJapanAddress() {
            User runningUser = TDdAccountFactory.createUsers(1)[0];  insert runningUser;
            system.runAs(runningUser) {
                Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
                validation.Bypass_Opportunity_Validations__c = true;  insert validation;
                Account parent = TDdAccountFactory.createAccountsWithJapanAddress('Parent', 1, 'Parent Account')[0];
                Account child = TDdAccountFactory.createAccountsWithJapanAddress('Child', 1, 'Marketplace')[0];
                insert parent;  child.ParentId = parent.Id;  insert child;
                Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
                Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'ML_Inside_Sales');
                insert opp;
                test.startTest();
                    CDdOpportunityCaseHelper.isMarketplaceOnboardingEnabled = false;
                    opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
                    opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
                    opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
                    opp.StageName = 'Closed Won';
                    update opp;
                    if (testDirectly) { // not currently wired up to trigger
                        List<Id> oppIdList = new List<Id>{opp.Id};
                        CDdOpportunityCaseHelper.createCases(oppIdList);
                    } // not currently wired up to trigger
                test.stopTest();
            }
            List<Case> checkCases = [SELECT Id, Subject FROM Case WHERE Subject = 'TEST: TabletCase'];
            system.assertEquals(1, checkCases.size(), 'checkCases: ' + checkCases);
            List<Account> checkAccounts = [SELECT Id FROM Account];
            system.assertEquals(2, checkAccounts.size());
            List<Opportunity> checkOpportunities = [SELECT Id, Tablet_Case_Created__c FROM Opportunity];
            system.assertEquals(1, checkOpportunities.size());
            system.assertEquals(true, checkOpportunities[0].Tablet_Case_Created__c);
            List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
            system.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
        }

/*
    @isTest static void createTabletRequestFeatureFlagTest() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];  insert runningUser;
        system.runAs(runningUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
            validation.Bypass_Opportunity_Validations__c = true;  insert validation;
            Account parent = TDdAccountFactory.createAccounts('Parent', 1, 'Parent Account')[0];
            Account child = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
            insert parent;  child.ParentId = parent.Id;  insert child;
            Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'ML_Inside_Sales');
            insert opp;
            test.startTest();
            CDdOpportunityCaseHelper.isMarketplaceOnboardingEnabled = true;
            opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
            opp.Tablet_Delivery_Method__c = 'None - Use Existing Tablet';
            opp.StageName = 'Closed Won';
            update opp;
            if (testDirectly) { // not currently wired up to trigger
                List<Id> oppIdList = new List<Id>{opp.Id};
                CDdOpportunityCaseHelper.createCases(oppIdList);
            } // not currently wired up to trigger
            test.stopTest();
        }
        List<Case> checkCases = [SELECT Id, Subject FROM Case WHERE Subject = 'TEST: TabletCase'];
        system.assertEquals(0, checkCases.size(), 'checkCases: ' + checkCases);
    }
*/

    /*
     * @Description: BZAP-9025 Create a Drive Activation Case
     */
    @isTest static void createDriveActivationCaseTest() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];
        insert runningUser;
        system.runAs(runningUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
            validation.Bypass_Opportunity_Validations__c = true;
            insert validation;
            Account parent = TDdAccountFactory.createAccounts('Parent', 1, 'Parent Account')[0];
            Account child = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
            insert parent;
            child.ParentId = parent.Id;
            insert child;
            Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'DoorDash_Drive');
            opp.Nimda_Setup_Required__c = 'No';
            insert opp;
            Test.startTest();
            opp.StageName = 'Closed Won';
            opp.Automation_Status__c = 'Manual Activation Case';
            update opp;
            Test.stopTest();
        }
        List<Case> checkCases = [SELECT Id, Subject FROM Case WHERE Subject = 'TEST: Drive Activation Case'];
        system.assertEquals(1, checkCases.size(), 'checkCases: ' + checkCases);
        List<Account> checkAccounts = [SELECT Id FROM Account];
        system.assertEquals(2, checkAccounts.size());
        List<Opportunity> checkOpportunities = [SELECT Id, Activation_Case_Created__c FROM Opportunity];
        system.assertEquals(1, checkOpportunities.size());
        system.assertEquals(true, checkOpportunities[0].Activation_Case_Created__c);
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        system.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    /*
     * @Description: BZAP-9025 Create Corporate Drive Product Activation Case
     */
    @isTest static void createCorporateDriveProductsActivationCaseTest() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];
        insert runningUser;
        system.runAs(runningUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
            validation.Bypass_Opportunity_Validations__c = true;
            insert validation;
            Map<String, String> PRODUCT_NAME_AND_FAMILY = new Map<String, String> {
                    'LOF' => 'Products'
            };
            List<Product2> products = new List<Product2>();
            for (String productName : PRODUCT_NAME_AND_FAMILY.keySet()) {
                Product2 product = new Product2(Name = productName, Family = PRODUCT_NAME_AND_FAMILY.get(productName));
                for (String fieldName : TDdOpportunityLineItemFactory.DEFAULT_PRODUCT_VALUES.keySet()) {
                    product.put(fieldName, TDdOpportunityLineItemFactory.DEFAULT_PRODUCT_VALUES.get(fieldName));
                }
                products.add(product);
            }
            insert products;
            List<PricebookEntry> priceBookEntries = TDdOpportunityLineItemFactory.createPricebookEntries(products);
            List<PriceBookEntry> pbes = [
                SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id,
                        Product2Id, ProductCode, UnitPrice, UseStandardPrice,
                        Product2.Name, Product2.Family
                FROM PricebookEntry
                WHERE Name IN :PRODUCT_NAME_AND_FAMILY.keySet()];
            Account parent = TDdAccountFactory.createAccounts('Parent', 1, 'Parent Account')[0];
            Account child = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
            insert parent;
            child.ParentId = parent.Id;
            insert child;
            Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'Corporate');
            opp.Nimda_Setup_Required__c = 'No';
            //BZAP-9691 - commented by shiva pochamalla to fix validation error
            //opp.Menu_to_be_completed_by__c = null;
            //opp.Menu_Setup_Method__c =  null;

            opp.Tablet_Kit_Type__c = null;
            insert opp;
            List<OpportunityLineItem> oppProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(opp.Id, priceBookEntries);
            for (OpportunityLineItem oli : oppProducts){
                oli.Renegotiation__c = 'No';
                oli.Upsell__c = 'No';
                oli.Store_Commitments__c = 'No';
                oli.Merchant_Signed_with_Exclusivity__c = 'No';
            }
            insert oppProducts;
            Test.startTest();
            opp.StageName = 'Closed Won';
            //BZAP-9690 Shiva pochamalla added menu to be completed for validation rule
            opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';

            update opp;
            Test.stopTest();
        }
        List<Case> checkCases = [SELECT Id, Subject FROM Case WHERE Subject = 'TEST: Drive Activation Case'];
        system.assertEquals(1, checkCases.size(), 'checkCases: ' + checkCases);
        List<Account> checkAccounts = [SELECT Id FROM Account];
        system.assertEquals(2, checkAccounts.size());
        List<Opportunity> checkOpportunities = [SELECT Id, Activation_Case_Created__c FROM Opportunity];
        system.assertEquals(1, checkOpportunities.size());
        system.assertEquals(true, checkOpportunities[0].Activation_Case_Created__c);
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        system.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    @IsTest
    static void createMarketplaceOnboarding() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];  insert runningUser;

        System.runAs(runningUser) {
            Opportunity opp = setupEnterpriseMarketplaceOnboardingOpp(runningUser, false);
            System.assertEquals(true, CDdOpportunityCaseHelper.matches(opp, CDdOpportunityCaseHelper.Criteria.Marketplace_Onboarding));

            Test.startTest();
            insert opp;
            Test.stopTest();

            System.debug([select Id from Case].size());

            Case c = [select
                    AccountId,
                    Account.RecordTypeId,
                    ContactId,
                    Decision_Maker__c,
                    Id,
                    Origin,
                    OwnerId,
                    Platform__c,
                    POS_Fallback_Protocol__c,
                    POS_Integration_ID__c,
                    POS_Integration_Type__c,
                    RecordTypeId,
                    Segment__c,
                    Stage__c,
                    Status
            from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];

            System.assertEquals('Closed Won Opportunity', c.Origin);
            System.assertEquals('Open', c.Status);
            System.assertEquals(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(), c.RecordTypeId);
            System.assertEquals(opp.AccountId, c.AccountId);
            System.assertEquals(opp.Decision_Maker__c, c.Decision_Maker__c);
            System.assertEquals([select Id from Group where Name = 'Ent Onboarding - Under Review'].Id, c.OwnerId);
            System.assertEquals(null, c.POS_Fallback_Protocol__c);
            System.assertEquals(null, c.POS_Integration_ID__c);
            System.assertEquals(null, c.POS_Integration_Type__c);
            System.assertEquals(opp.Platform__c, c.Platform__c);
            System.assertEquals(opp.Store_Manager__c, c.ContactId);
            System.assertEquals('Enterprise', c.Segment__c);
            System.assertEquals('Not Started', c.Stage__c);

        }
    }

    @IsTest
    static void createMarketplaceOnboardingAlternate() {
        User selfServIntegrationUser = [SELECT Id FROM User WHERE alias = 'selfserv'];

        System.runAs(selfServIntegrationUser) {
            Opportunity opp = setupEnterpriseMarketplaceOnboardingOpp(selfServIntegrationUser, true);

            Test.startTest();
            insert opp;
            Test.stopTest();

            System.debug([select Id from Case].size());

            Case c = [select
                    Origin,
                    OwnerId,
                    POS_Fallback_Protocol__c,
                    POS_Integration_ID__c,
                    POS_Integration_Type__c,
                    Segment__c
            from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];

            System.assertEquals('Closed Won Opportunity - SSMO', c.Origin);
            System.assertEquals(null, c.POS_Fallback_Protocol__c);
            System.assertEquals(null, c.POS_Integration_ID__c);
            System.assertEquals(null, c.POS_Integration_Type__c);
            System.assertEquals('Enterprise', c.Segment__c);

        }
    }


    public static Opportunity setupEnterpriseMarketplaceOnboardingOpp(User runningUser, Boolean isEnterprise) {
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
        validation.Bypass_Opportunity_Validations__c = true;  insert validation;

        Account parentAccount = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId());
        if (isEnterprise) {
            parentAccount.Deck_Rank__c = 'King of Spades';
        }
        insert parentAccount;

        Account childAccount = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId());
        childAccount.In_Coverage__c = 'Yes';
        childAccount.ParentId = parentAccount.Id;
        childAccount.Restaurant_ID__c = '123';
        childAccount.iPad_Password__c = '123';
        childAccount.Deck_Rank__c = 'King of Spades'; // BASD -12171 Added this value to address validation rule fix
        childAccount.iPad_Username__c = '123@doordash.com.test';
        insert childAccount;

        Contact contact = TDdAccountFactory.createContacts(1, childAccount.Id)[0];
        insert contact;

        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test', childAccount.Id, contact.Id, 'Closed Won', 'Enterprise_Marketplace');
        opp.OwnerId = runningUser.Id;
        return opp;
    }

    /**
     * @description: Test for BZAP-13015 - Migrate PB "Create Cases for Protocol Change for Post-Sale" to Trigger
     *               CDdOpportunityCaseHelper.postSaleProtocolChangeTabletCase() and postSaleProtocolChangePOSCase()
     */
    @IsTest
    public static void testPostSaleProtocolChangeCase() {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;  insert validation;

            Account acct = TDdAccountFactory.createAccounts('Test Account', 1, 'Marketplace')[0];
            insert acct;
            
            Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', acct.Id, contact.Id, 'New', 'Post_Sale');
            opp.StageName = CDdOpportunityTriggerHelper.STAGE_NAME_CONTRACT_SIGNED;
            opp.Tablet_Delivery_Method__c = 'Drop-ship';
            opp.Tablet_Case_Created__c = false;
            opp.Activation_Case_Created__c = false;
            opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
            opp.Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)';
            opp.Proposed_Date_of_Activation__c = Date.today().addDays(15);
            opp.POS_Fallback_Protocol__c = 'Dasher Red Card';
            opp.POS_Integration_ID__c = '12345';
            opp.Previous_Order_Protocol__c = 'Tablet (DoorDash Owns)';
            // in order not to trigger the same Tablet Case as created by CDdOpportunityCaseHelper.createTabletCase() for Marketplace RT
            opp.Region_Type__c = 'Non-Live Region';
            insert opp;
            
            Case marketplaceCase = TDdCaseFactory.createCases(1, acct.Id, opp.Id, CDdSchemaUtils.CASE_RT.marketplaceOnboardingId())[0];
            insert marketplaceCase;

            Test.startTest();
                opp.StageName = CDdOpportunityTriggerHelper.STAGE_NAME_CLOSED_WON;
                update opp;
            Test.stopTest();

            Opportunity oppVerify = [SELECT Id, Activation_Case_Created__c, Name, Notes__c, OwnerId, POS_Fallback_Protocol__c, POS_Integration_ID__c,
                                            Proposed_Date_of_Activation__c, Shipping__c, Tablet_Case_Created__c,
                                            Account.BillingStreet, Account.BillingCountry, Account.OwnerId, RecordTypeId
                                    FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
            Case tabletCaseVerify = [SELECT Id, Description, Due_Date__c, Go_Live_Date__c, OwnerId,
                                            POS_Fallback_Protocol__c, POS_Integration_ID__c, POS_Integration_Type__c, Pre_Work_Deadline__c,
                                            RecordTypeId, Request_Type__c, Requested_Due_Date__c, Return_Shipping_Address_Street__c,
                                            Shipping_Address_Country__c, Shipping_Type__c, Status, Tablet_Device_Type__c
                                    FROM Case
                                    WHERE Opportunity_Name__c =: oppVerify.Id
                                      AND RecordTypeId =: CDdOpportunityCaseHelper.caseTabletRequestRTId];
            Case posCaseVerify = [SELECT Id, Account_Owner__c,Description, Due_Date__c, Go_Live_Date__c, OwnerId, ParentId,
                                        POS_Fallback_Protocol__c, POS_Integration_ID__c, POS_Integration_Type__c, Pre_Work_Deadline__c,
                                        RecordTypeId, Request_Type__c, Requested_Due_Date__c, Return_Shipping_Address_Street__c,
                                        Shipping_Address_Country__c, Shipping_Type__c, Status, Tablet_Device_Type__c
                                    FROM Case
                                    WHERE RecordTypeId =: CDdOpportunityCaseHelper.casePosIntegrationsRTId];
            System.assertEquals(true, oppVerify.Tablet_Case_Created__c);
            System.assertEquals(true, oppVerify.Activation_Case_Created__c);

            System.assertEquals('Ship to Merchant (New Tablet)', tabletCaseVerify.Request_Type__c,
                                'The Case Request_Type__c should be set based on the orderProtocolToRequestType or previousOrderProtocolToRequestType maps');
            System.assertEquals(oppVerify.Notes__c, tabletCaseVerify.Description, 'The Case description should come from the Opportunity Notes__c');
            System.assertEquals(oppVerify.OwnerId, tabletCaseVerify.OwnerId, 'The Case Owner should come from the Opportunity Owner');
            System.assertEquals(oppVerify.Shipping__c, tabletCaseVerify.Shipping_Type__c, 'The Case Shipping_Type__c should come from the Opportunity Shipping__c');
            System.assertEquals('Open', tabletCaseVerify.Status, 'The Case Status should be set to Open');
            System.assertEquals(null, tabletCaseVerify.Tablet_Device_Type__c, 'The Case Tablet_Device_Type__c should be blank for Tablet Case');
            System.assertEquals(oppVerify.Account.BillingStreet, tabletCaseVerify.Return_Shipping_Address_Street__c,
                                'The Case Return_Shipping_Address_Street__c should be set to the Account\'s BillingStreet');
            System.assertEquals(oppVerify.Account.BillingCountry, tabletCaseVerify.Shipping_Address_Country__c,
                                'The Case Shipping_Address_Country__c should be set to the Account\'s BillingCountry');
            System.assertEquals(oppVerify.Account.OwnerId, posCaseVerify.Account_Owner__c,
                                'The Case Account_Owner__c should be set to the Account\'s OwnerId');
            System.assertEquals(oppVerify.Proposed_Date_of_Activation__c, posCaseVerify.Due_Date__c,
                                'The Case Due_Date__c should be set to the Opportunity Proposed_Date_of_Activation__c');
            System.assertEquals(oppVerify.POS_Fallback_Protocol__c, posCaseVerify.POS_Fallback_Protocol__c,
                                'The Case POS_Fallback_Protocol__c should be set to the Opportunity POS_Fallback_Protocol__c');
            System.assertEquals(oppVerify.POS_Integration_ID__c, posCaseVerify.POS_Integration_ID__c,
                                'The Case POS_Integration_ID__c should be set to the Opportunity POS_Integration_ID__c');
            System.assertEquals(oppVerify.Proposed_Date_of_Activation__c.addDays(-2), posCaseVerify.Pre_Work_Deadline__c);
            System.assertEquals(CDdOpportunityCaseHelper.queueIdByDeveloperName.get('Queue_POS_Integration_Requests'), posCaseVerify.OwnerId,
                                'The Case Owner should be set to the Queue_POS_Integration_Requests Queue');
            System.assertEquals(CDdSupportConstants.OPEN_STATUS, posCaseVerify.Status, 'The Case Status should be Open');
            System.assertEquals(marketplaceCase.Id, posCaseVerify.ParentId, 'The Marketplace Onboarding Case should be linked to the POS Case via the ParentId field.');
            
            List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
            system.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    /**
     * @description: Test for BZAP-13015 - Migrate PB "Caviar Onboarding Flow" to Trigger
     *               CDdOpportunityCaseHelper.caviarOnboardingFlow()
     */
    @IsTest
    public static void testCaviarOnboardingFlowCaviarOnboarding() {
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;  insert validation;
        Account acct = TDdAccountFactory.createAccounts('Test Account', 1, 'Marketplace')[0];
        acct.Caviar_Service_Region__c = 'Los Angeles';
        insert acct;
        Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];  insert contact;
        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', acct.Id, contact.Id, 'New', 'ML_Inside_Sales');

        opp.Decision_Maker__c = opp.ContactId;
        opp.StageName = 'Closed Won';
        opp.Platform__c = 'Caviar';
        opp.Caviar_Onboarding_Type__c = 'Traditional Onboarding';
        opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';

        System.assertEquals(false, opp.Caviar_Onboarding_Case_Created__c);
        Test.startTest();
        insert opp;
        Test.stopTest();
        Opportunity oppVerify = [SELECT Id, Caviar_Onboarding_Case_Created__c, Account.Caviar_Service_Region__c, Account.OwnerId
                                FROM Opportunity
                                WHERE Name = 'Test Opp' LIMIT 1];
        List<Case> caseVerifyList = [SELECT Id, Account_Owner__c, Caviar_Service_Region__c, Description,
                                        Origin, OwnerId, RecordTypeId, Subject, Status
                                        FROM Case WHERE Opportunity_Name__c =: oppVerify.Id
                                                AND RecordTypeId =: CDdOpportunityCaseHelper.caseCaviarOnboardingRTID];
        System.assertEquals(1, caseVerifyList.size());
        Case caseVerify = caseVerifyList[0];
        System.assertEquals(true, caseVerify.Description.startsWith('Opportunity Details'));
        System.assertEquals(oppVerify.Account.Caviar_Service_Region__c, caseVerify.Caviar_Service_Region__c,
                            'The Case Caviar_Service_Region__c should come from the Opp Accounts Caviar_Service_Region__c');
        System.assertEquals(CDdSupportConstants.ORIGIN_CLOSED_WON_OPPORTUNITY, caseVerify.Origin,
                            'The Case Origin should be set to \'Closed Won Opportunity\'');
        System.assertEquals(oppVerify.Account.OwnerId, caseVerify.Account_Owner__c, 'The Case Account_Owner__c should come from the Opp Account OwnerId');
        System.assertEquals(CDdSupportConstants.NEW_STATUS, caseVerify.Status, 'The Case Status should be set to \'New\'');
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        System.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    /**
     * @description: Test for BZAP-23630 - Create Tablet request case for Caviar Merchnats
     */

    @isTest static void createTabletRequestCaviarTest() {
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;  insert validation;
        Account acct = TDdAccountFactory.createAccounts('Test Account', 1, 'Marketplace')[0];
        insert acct;
        Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];  insert contact;
        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', acct.Id, contact.Id, 'New', 'ML_Inside_Sales');
        opp.Activation_Date__c = null;
        opp.Tablet_Delivery_Method__c = 'Drop-ship';
        opp.Tablet_Case_Created__c = false;
        opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
        opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
        opp.Proposed_Date_of_Activation__c = Date.today().addDays(15);
        opp.Region_Type__c = 'Live Region';
        opp.Platform__c = 'Caviar';
        insert opp;
        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        Opportunity oppVerify = [SELECT Id, Activation_Case_Created__c, Name, Notes__c, OwnerId, POS_Fallback_Protocol__c, POS_Integration_ID__c,
                                        Proposed_Date_of_Activation__c, Shipping__c, Tablet_Case_Created__c,
                                        Account.BillingStreet, Account.BillingCountry, Account.OwnerId, RecordTypeId
                                FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Case tabletCaseVerify = [SELECT Id, Description, Due_Date__c, Go_Live_Date__c, OwnerId,
                                        POS_Fallback_Protocol__c, POS_Integration_ID__c, POS_Integration_Type__c, Pre_Work_Deadline__c,
                                        RecordTypeId, Request_Type__c, Requested_Due_Date__c, Return_Shipping_Address_Street__c,
                                        Shipping_Address_Country__c, Shipping_Type__c, Status, Tablet_Device_Type__c
                                FROM Case
                                WHERE Opportunity_Name__c =: oppVerify.Id
                                  AND RecordTypeId =: CDdOpportunityCaseHelper.caseTabletRequestRTId];
        System.assertEquals(true, oppVerify.Tablet_Case_Created__c);
        System.assertEquals('Ship to Merchant (New Tablet)', tabletCaseVerify.Request_Type__c,
                            'The Case Request_Type__c should be set based on the orderProtocolToRequestType or previousOrderProtocolToRequestType maps');
        System.assertEquals(oppVerify.Notes__c, tabletCaseVerify.Description, 'The Case description should come from the Opportunity Notes__c');
        System.assertEquals(oppVerify.OwnerId, tabletCaseVerify.OwnerId, 'The Case Owner should come from the Opportunity Owner');
        System.assertEquals('Expedited', tabletCaseVerify.Shipping_Type__c, 'The Case Shipping_Type__c should come from the Opportunity Shipping__c');
        System.assertEquals('Open', tabletCaseVerify.Status, 'The Case Status should be set to Open');
        System.assertEquals(null, tabletCaseVerify.Tablet_Device_Type__c, 'The Case Tablet_Device_Type__c should be blank for Tablet Case');
        System.assertEquals(oppVerify.Account.BillingStreet, tabletCaseVerify.Return_Shipping_Address_Street__c,
                            'The Case Return_Shipping_Address_Street__c should be set to the Account\'s BillingStreet');
        System.assertEquals(oppVerify.Account.BillingCountry, tabletCaseVerify.Shipping_Address_Country__c,
                            'The Case Shipping_Address_Country__c should be set to the Account\'s BillingCountry');
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        system.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    @IsTest
    static void createMarketplaceOnboardingPOSToast() {
        User muleIntegrationUser = [SELECT Id FROM User WHERE alias = 'mule'];

        System.runAs(muleIntegrationUser) {
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;  insert validation;
        Account acct = TDdAccountFactory.createAccounts('Test Account', 1, 'Marketplace')[0];
        insert acct;
        Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];  insert contact;
        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('POS test Queue', acct.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            opp.Lead_Source_Detail__c = CDdCoreConstants.LEADSOURCE_DETAIL_SSMO;
            opp.Order_Protocol__c = 'POS';
            opp.POS_Integration_Type__c = 'toast';
            opp.Tablet_Delivery_Method__c = null;
            opp.Tablet_Kit_Type__c = null;
            Test.startTest();
            insert opp;
            Test.stopTest();

            Case marketPlaceOnboardingCase  = [select  Origin, OwnerId, POS_Fallback_Protocol__c,
                                           POS_Integration_ID__c, POS_Integration_Type__c
                                           from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];
            System.assertEquals('Closed Won Opportunity - SSMO', marketPlaceOnboardingCase.Origin);
            System.assertEquals([select Id from Group where Name = 'Onboarding - SSMO Square POS'].Id, marketPlaceOnboardingCase.OwnerId);

        }
    }

    @IsTest
    static void bbotProductOnlyDoesNotCreateMarketplaceOnboardingCase() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs(runningUser) {
            Opportunity opp = setupEnterpriseMarketplaceOnboardingOpp(runningUser, false);
			opp.StageName = 'Contract Signed';

            Map<String, String> PRODUCT_NAME_AND_FAMILY = new Map<String, String> {
                'Bbot Product 1' => 'Bbot'
            };
            List<Product2> products = new List<Product2>();
            for (String productName : PRODUCT_NAME_AND_FAMILY.keySet()) {
                Product2 product = new Product2(Name = productName, Family = PRODUCT_NAME_AND_FAMILY.get(productName));
                for (String fieldName : TDdOpportunityLineItemFactory.DEFAULT_PRODUCT_VALUES.keySet()) {
                    product.put(fieldName, TDdOpportunityLineItemFactory.DEFAULT_PRODUCT_VALUES.get(fieldName));
                }
                products.add(product);
            }
            insert products;
            List<PricebookEntry> priceBookEntries = TDdOpportunityLineItemFactory.createPricebookEntries(products);

            insert opp;

            List<OpportunityLineItem> oppProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(opp.Id, priceBookEntries);
            for (OpportunityLineItem oli : oppProducts){
                oli.Renegotiation__c = 'No';
                oli.Upsell__c = 'No';
                oli.Store_Commitments__c = 'No';
                oli.Merchant_Signed_with_Exclusivity__c = 'No';
            }
            insert oppProducts;

            Test.startTest();
            opp.StageName = 'Closed Won';
            update opp;
            Test.stopTest();

            List<Case> cases = [select
                    AccountId,
                    Account.RecordTypeId,
                    ContactId,
                    Decision_Maker__c,
                    Id,
                    Origin,
                    OwnerId,
                    Platform__c,
                    POS_Fallback_Protocol__c,
                    POS_Integration_ID__c,
                    POS_Integration_Type__c,
                    RecordTypeId,
                    Segment__c,
                    Stage__c,
                    Status
            from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];

            System.assertEquals(0, cases.size());
        }
    }

    @isTest
    static void test_GTMI_Opportunity_Case_Owners() {
        User runningUser = TDdAccountFactory.createUsers(1)[0];  insert runningUser;
        system.runAs(runningUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
            validation.Bypass_Opportunity_Validations__c = true;  insert validation;
            Account parent = TDdAccountFactory.createAccounts('Parent', 1, 'Parent Account')[0];
            insert parent;
            Contact contact = TDdAccountFactory.createContacts(1, parent.Id)[0];
            insert contact;
            GTM_Initiative__c gtmi = new GTM_Initiative__c(Name = 'Test');
            insert gtmi;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', parent.Id, contact.Id, 'New', 'ML_Inside_Sales');
            opp.GTMI_Initiative_Name__c = gtmi.Id;
            insert opp;

            test.startTest();
            opp.StageName = 'Closed Won';
            opp.Region_Type__c = 'Live Region';
            opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
            opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
            update opp;
            test.stopTest();
        }
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        List<Case> checkCases = [SELECT Id, Subject, ownerId FROM Case WHERE Opportunity_Name__c = :opportunity.Id];
        system.assertEquals(2, checkCases.size(), 'checkCases: ' + checkCases);
        Id queueId = [SELECT Id, DeveloperName FROM Group where DeveloperName =: CDdOpportunityCaseHelper.QUEUE_ACTIVATIONS_LAB].Id;
        for(Case c: checkCases){
            system.assertEquals(queueId, c.ownerId, 'Owner Id was not set to Activations Lab Queue');
        }
    }
}