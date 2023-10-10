/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/19/2020
*
* @group Trigger Handler Test
*
* @description Test for Opportunity Line Item Trigger Handler
**************************************************************************************************************************************/
@isTest
public class CDdOpportunityLineItemTriggerHandlerTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_ACCOUNT_PARENT_IDENTIFIERS = 'TestDDAccountParent%';
    public static final String TEST_DD_ACCOUNT_CHILD_IDENTIFIERS = 'TestDDAccountChild%';
    public static final String TEST_DD_OPPORTUNITY_0 = 'TestOpportunity0';
    public static final String TEST_DD_OPPORTUNITY_1 = 'TestOpportunity1';
    public static final String TEST_DD_OPPORTUNITY_2 = 'TestOpportunity2';
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1 = 122222;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2 = 122223;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_3 = 122224;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final Map<String, Object> PRODUCT_NAME_AND_FAMILY = TDdOpportunityLineItemFactory.PRODUCT_NAME_AND_FAMILY;
    public static final Map<String, Object> DEFAULT_PRODUCT_VALUES = TDdOpportunityLineItemFactory.DEFAULT_PRODUCT_VALUES;
    public static final Map<String, Object> DEFAULT_PRICEBOOK_ENTRY_VALUES = TDdOpportunityLineItemFactory.DEFAULT_PRICEBOOK_ENTRY_VALUES;
    public static final String PRODUCT_NAME_MARKETPLACE_CATERING = 'Marketplace Catering';
    public static final String PRODUCT_NAME_DDFB_GROUP_CART = 'DDfB Group Cart';
    public static final String PRODUCT_NAME_DOORDASH_GIFT_CARDS = 'DoorDash Gift Cards';

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    }

    /**
     * @description Prepare and return the test running user
     */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]) {
            testRunUser = u;
        }
        if (testRunUser == null) {
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }

    /**
    * @description Create other users
    */
    private static void createOtherUsers() {
        List<User> testUsers = TDdAccountFactory.createUsers(2, null, TEST_ROLE_ID);
        testUsers[0].Username = 'formstack@doordash.com';
        testUsers[1].Username = 'mx-eng-api@doordash.com';
        insert testUsers;
    }

    /**
    * @description Prepare test data
    */
    @testSetup
    static void setup() {
        createOtherUsers();
        System.runAs(getTestRunUser()) {
            Test.startTest();

            User selfServiceUser1 = [SELECT Id from User WHERE UserName = 'formstack@doordash.com'];
            User selfServiceUser2 = [SELECT Id from User WHERE UserName = 'mx-eng-api@doordash.com'];

            List<Self_Serve_Users__c> selfServeUsersSettings = new List<Self_Serve_Users__c>();
            Self_Serve_Users__c ssUser;
            ssUser = new Self_Serve_Users__c();
            ssUser.name = 'formstack@doordash.com';
            ssUser.User_Id__c = selfServiceUser1.id;
            selfServeUsersSettings.add(ssUser);
            ssUser = new Self_Serve_Users__c();
            ssUser.name = 'mx-eng-api@doordash.com';
            ssUser.User_Id__c = selfServiceUser2.id;
            selfServeUsersSettings.add(ssUser);
            insert selfServeUsersSettings;

            E2F__FindApi_Triggers_Settings__c findAPISettings =
                    new E2F__FindApi_Triggers_Settings__c(SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID, Name = 'System Administrator', E2F__Bypass_Trigger__c = true);
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

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            validation.Bypass_Opportunity_Product_Validations__c = true;
            insert validation;            

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
            testAcct3.RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.parentAccountId();
            testAcct3.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1;
            Account testAcct4 = testAccounts[4];
            testAcct4.Name = 'TestDDAccountParent1';
            testAcct4.RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.parentAccountId();
            testAcct4.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2;
            Account testAcct5 = testAccounts[5];
            testAcct5.Name = 'TestDDAccountParent2';
            testAcct5.RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.parentAccountId();
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
            testOpp1.Commission__c = 20;

            Opportunity testOpp2 = TDdOpportunityFactory.createOpportunity(TEST_DD_OPPORTUNITY_1, testAcct1.Id, testContact1.Id, 'New');
            testOpp2.Menu_Completion_Date__c = System.today();
            testOpp2.Commission__c = 20;

            Opportunity testOpp3 = TDdOpportunityFactory.createOpportunity(TEST_DD_OPPORTUNITY_2, testAcct2.Id, testContact2.Id, 'Pitching');
            testOpp3.Menu_Completion_Date__c = System.today();
            testOpp3.Commission__c = 20;

            List<Opportunity> testOpps = new List<Opportunity>{testOpp1, testOpp2, testOpp3};
            insert testOpps;

            TDdOpportunityLineItemFactory.createProducts();

            Test.getEventBus().deliver();
            Test.stopTest();
        }
    }



    /**
    * @description Create Opportunity Products and test for default values
    */
    @isTest
    static void testOpportunityProductDefaultValues() {
        Map<String, String> prdMap = CDdOpportunityLineItemHelperMethods.getDefaultFieldMap(CDdOpportunityLineItemHelperMethods.PRD_MAP_MDT);
        Map<String, String> pbeMap = CDdOpportunityLineItemHelperMethods.getDefaultFieldMap(CDdOpportunityLineItemHelperMethods.PBE_MAP_MDT);
        Id promotionsId = [select Id from PricebookEntry where Product2.Family = 'Promotions' limit 1].Id;

        System.runAs(getTestRunUser()) {
            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_0 LIMIT 1];

            Test.StartTest();

            List<OpportunityLineItem> olis = TDdOpportunityLineItemFactory.createOpportunityProducts(opp.Id);
            for (OpportunityLineItem oli : olis) {
                if (oli.PricebookEntryId.equals(promotionsId)) {
                    oli.Billing_Frequency__c = 'Quarterly';
                    oli.Commission_Rate__c = 1.00;
                    oli.Service_Fee__c = 1.00;
                }
            }
            insert olis;

            Test.StopTest();

            // Validate non-promotional OpportunityLineItems
            for (OpportunityLineItem oli : Database.query(getSoql(prdMap, pbeMap, opp.Id, promotionsId, false))) {

                // Validate Product2 defaults.
                for (String field : prdMap.keySet()) {
                    switch on field {
                        when 'Product_Family_Text__c' { // each Family is unique
                            System.assert(TDdOpportunityLineItemFactory.PRODUCT_NAME_AND_FAMILY.values().contains((String) oli.get(field)), 'Unexpected value for Product_Family_Text__c.');
                        }
                        when 'Product_Name_Text__c' { // each Name is unique
                            System.assert(TDdOpportunityLineItemFactory.PRODUCT_NAME_AND_FAMILY.keySet().contains((String) oli.get(field)), 'Unexpected value for Product_Name_Text__c.');
                        }
                        when 'Billing_Frequency__c' { // Billing_Frequency__c is static
                            System.assertEquals('Monthly', oli.Billing_Frequency__c, 'Unexpected value for Billing_Frequency__c.');
                        } when else {
                            System.assert(false, 'Untested mapping for Product2 default field: ' + field);
                        }
                    }
                }

                // Validate Pricebook Entry defaults
                for (String field : pbeMap.keySet()) {
                    System.assertEquals(DEFAULT_PRICEBOOK_ENTRY_VALUES.get(pbeMap.get(field)), oli.get(field), 'Unexpected value for ' + field);
                }
            }

            // Validate promotional OpportunityLineItem
            for (OpportunityLineItem oli : Database.query(getSoql(prdMap, pbeMap, opp.Id, promotionsId, true))) {
                System.assertEquals(true, oli != null, 'Expecting an opportunity product for Opportunity ' + opp.Name);
                System.assertEquals('Quarterly', oli.Billing_Frequency__c, 'Unexpected value for Billing_Frequency__c');
                System.assertEquals(1.00, oli.Commission_Rate__c, 'Unexpected value for Commission_Rate__c');
                System.assertEquals(1.00, oli.Service_Fee__c, 'Unexpected value for Service_Fee__c');
            }
        }
    }

    static String getSoql(Map<String, String> prdMap, Map<String, String> pbeMap, Id oppId, Id promotionsId, Boolean includePromotional) {
        String soqlFormat = 'select {0} from OpportunityLineItem where OpportunityId = {4}{1}{4} and PricebookEntryId {2} {4}{3}{4}';

        List<String> fieldList = new List<String>();
        fieldList.addAll(prdMap.keySet());
        fieldList.addAll(pbeMap.keySet());
        String fields = String.join(fieldList, ', ');

        String soql;
        if (includePromotional) {
            soql = String.format(soqlFormat, new List<String> { fields, oppId, '=', promotionsId, '\''});
        } else {
            soql = String.format(soqlFormat, new List<String> { fields, oppId, '!=', promotionsId, '\'' });
        }

        System.debug('getSoql, soql: ' + soql);
        return soql;
    }


    /**
    * @description Test update opportunity
    * Test the case, where the Product Ids field is updated to reflect the corresponding opp products associated with the opp record
    */
    @isTest
    static void testUpdateOpportunity1() {
        System.runAs(getTestRunUser()) {
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_1 LIMIT 1];
            List<PriceBookEntry> priceBookEntries = [SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id,
                    Product2Id, ProductCode, UnitPrice, UseStandardPrice,
                    Product2.Name, Product2.Family
            FROM PricebookEntry
            WHERE Name IN :PRODUCT_NAME_AND_FAMILY.keySet()];
            List<OpportunityLineItem> opportunityProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunity.Id, priceBookEntries);
            insert opportunityProducts;
            Test.StartTest();
            Opportunity opportunityFromDB = [SELECT Id, Product_IDs__c FROM Opportunity WHERE Id = :opportunity.Id LIMIT 1];
            List<Id> expectedProductIdsAssociatedWithOpp = new List<Id>();
            for (OpportunityLineItem opportunityLineItem : opportunityProducts) {
                expectedProductIdsAssociatedWithOpp.add(opportunityLineItem.Product2Id);
            }
            System.assertEquals(String.join(expectedProductIdsAssociatedWithOpp, CDdOpportunityLineItemHelperMethods.PRODUCT_ID_SEPARATOR),
                    opportunityFromDB.Product_IDs__c);

            List<OpportunityLineItem> opportunityProductsToDelete = new List<OpportunityLineItem>{opportunityProducts[0]};
            delete opportunityProductsToDelete;
            Test.StopTest();
            opportunityFromDB = [SELECT Id, Product_IDs__c FROM Opportunity WHERE Id = :opportunity.Id LIMIT 1];
            expectedProductIdsAssociatedWithOpp.remove(0);
            System.assertEquals(String.join(expectedProductIdsAssociatedWithOpp, CDdOpportunityLineItemHelperMethods.PRODUCT_ID_SEPARATOR),
                    opportunityFromDB.Product_IDs__c);

        }
    }
    /**
    * @description Test update opportunity
    * Test the edge case, where all opportunity products are removed from the associated opportunity record
    */
    @isTest
    static void testUpdateOpportunity2() {
        System.runAs(getTestRunUser()) {
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_1 LIMIT 1];
            List<PriceBookEntry> priceBookEntries = [SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id,
                    Product2Id, ProductCode, UnitPrice, UseStandardPrice,
                    Product2.Name, Product2.Family
            FROM PricebookEntry
            WHERE Name IN :PRODUCT_NAME_AND_FAMILY.keySet()];
            List<OpportunityLineItem> opportunityProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunity.Id, priceBookEntries);
            insert opportunityProducts;
            Test.StartTest();
            Opportunity opportunityFromDB = [SELECT Id, Product_IDs__c FROM Opportunity WHERE Id = :opportunity.Id LIMIT 1];
            List<Id> expectedProductIdsAssociatedWithOpp = new List<Id>();
            for (OpportunityLineItem opportunityLineItem : opportunityProducts) {
                expectedProductIdsAssociatedWithOpp.add(opportunityLineItem.Product2Id);
            }
            System.assertEquals(String.join(expectedProductIdsAssociatedWithOpp, CDdOpportunityLineItemHelperMethods.PRODUCT_ID_SEPARATOR),
                    opportunityFromDB.Product_IDs__c);

            delete opportunityProducts;
            Test.StopTest();
            opportunityFromDB = [SELECT Id, Product_IDs__c FROM Opportunity WHERE Id = :opportunity.Id LIMIT 1];
            expectedProductIdsAssociatedWithOpp.remove(0);
            System.assertEquals(true, String.isBlank(opportunityFromDB.Product_IDs__c));

        }
    }
    /**
    * @description BZAP-9090 - Update Corporate Product Validation field with 1 or 0
    */
    @isTest
    static void testUpdateCorporateProductValidation() {
        System.runAs(getTestRunUser()) {
            Test.StartTest();
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_1 LIMIT 1];
            List<PriceBookEntry> priceBookEntries = [SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id,
                    Product2Id, ProductCode, UnitPrice, UseStandardPrice,
                    Product2.Name, Product2.Family
            FROM PricebookEntry
            WHERE Name = :PRODUCT_NAME_MARKETPLACE_CATERING];
            List<OpportunityLineItem> opportunityProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunity.Id, priceBookEntries);
            OpportunityLineItem oli = opportunityProducts[0];
            oli.UnitPrice = 1.0;
            oli.Quantity = 1.0;
            oli.Weekly_Order_Frequency__c = 1;
            oli.Order_Type__c = 'Recurring';
            oli.Budget_Type__c = 'All-In';
            oli.Tip__c = 1.0;
            oli.Payment_Protocol__c = 'Credit Card';
            oli.Service_Type__c = 'Self Service';
            oli.Serve_Time__c = '15';
            oli.Dietary_Restrictions__c = 'Not Applicable';
            insert opportunityProducts;
            Test.StopTest();
            OpportunityLineItem oliFromDB = [SELECT Id, Name, Corporate_Product_Validation__c
                                             FROM OpportunityLineItem WHERE Id = :oli.Id LIMIT 1];
            System.assertEquals(true, oliFromDB!=null, 'Expecting an Opportunity Line Record in DB');
            System.assertEquals(1, oliFromDB.Corporate_Product_Validation__c, 'Expecting value 1 for Corporate Product Validation field');                                             
        }
    }
    /**
    * @description BZAP-9138 - Apply Weekly Revenue field calculation
    */
    @isTest
    static void testApplyWeeklyRevenueCalculation() {
        System.runAs(getTestRunUser()) {
            Test.StartTest();
            Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_1 LIMIT 1];
            List<PriceBookEntry> priceBookEntries = [SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id,
                    Product2Id, ProductCode, UnitPrice, UseStandardPrice,
                    Product2.Name, Product2.Family
            FROM PricebookEntry
            WHERE Name = :PRODUCT_NAME_DDFB_GROUP_CART];
            List<OpportunityLineItem> opportunityProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunity.Id, priceBookEntries);
            OpportunityLineItem oli = opportunityProducts[0];
            oli.UnitPrice = null;
            oli.Quantity = 1.0;
            oli.TotalPrice = 200.00;
            oli.Weekly_Order_Frequency__c = 4;
            oli.Order_Type__c = 'Recurring';
            oli.Budget_Type__c = 'All-In';
            oli.Tip__c = 1.0;
            oli.Payment_Protocol__c = 'Credit Card';
            oli.Service_Type__c = 'Self Service';
            oli.Serve_Time__c = '15';
            oli.Dietary_Restrictions__c = 'Not Applicable';
            insert opportunityProducts;
            Test.StopTest();
            OpportunityLineItem oliFromDB = [SELECT Id, Name, Weekly_Revenue__c
                                             FROM OpportunityLineItem WHERE Id = :oli.Id LIMIT 1];
            System.assertEquals(true, oliFromDB!=null, 'Expecting an Opportunity Line Record in DB');
            System.assertEquals(800.00, oliFromDB.Weekly_Revenue__c, 'Expecting value 800.00 for Weekly Revenue');                                             
        }
    }

    @IsTest
    public static void testRemovePactSafeCWRule() {
        System.runAs(getTestRunUser()) {
            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_1 LIMIT 1];
            opp.Bypass_Pactsafe_Validation__c = false;
            update opp;

            PriceBookEntry pbe = [SELECT Id, Product2Id, Product2.Family FROM PricebookEntry WHERE Name = :PRODUCT_NAME_DOORDASH_GIFT_CARDS limit 1];
            OpportunityLineItem oli = TDdOpportunityLineItemFactory.createOpportunityProducts(opp.Id, new List<PricebookEntry> { pbe })[0];
            insert new Bypass_Pactsafe_Validation__c(Name = 'DoorDash Gift Cards', Product2Id__c = pbe.Product2Id);

            System.debug('OLIHM.testRemovePactSafeCWRule 1');
            insert oli;
            System.assertEquals(true, [select Bypass_Pactsafe_Validation__c from Opportunity where Id = :opp.Id].Bypass_Pactsafe_Validation__c);

            System.debug('OLIHM.testRemovePactSafeCWRule 2');
            delete oli;
            System.assertEquals(false, [select Bypass_Pactsafe_Validation__c from Opportunity where Id = :opp.Id].Bypass_Pactsafe_Validation__c);
        }
    }

    @IsTest
    public static void testRemovePactSafeCWRuleFalse() {
        System.runAs(getTestRunUser()) {
            Test.startTest();
            Id filterId = [SELECT Product2Id FROM PricebookEntry WHERE Name = :PRODUCT_NAME_DOORDASH_GIFT_CARDS limit 1].Id;

            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_1 LIMIT 1];
            opp.Bypass_Pactsafe_Validation__c = true;

            PriceBookEntry pbe = [SELECT Id, Product2Id, Product2.Family FROM PricebookEntry WHERE Name = :PRODUCT_NAME_DDFB_GROUP_CART limit 1];
            OpportunityLineItem oli = TDdOpportunityLineItemFactory.createOpportunityProducts(opp.Id, new List<PricebookEntry> { pbe })[0];
            insert new Bypass_Pactsafe_Validation__c(Name = PRODUCT_NAME_DDFB_GROUP_CART, Product2Id__c = filterId);

            insert oli;
            Test.StopTest();

            Opportunity result = [select Bypass_Pactsafe_Validation__c from Opportunity where Id = :opp.Id];
            System.assertEquals(false, result.Bypass_Pactsafe_Validation__c);
        }
    }

    @IsTest
    public static void testRemovePactSafeCWRuleFalseComboProducts() {
        System.runAs(getTestRunUser()) {
            Test.startTest();
            Id filterId = [SELECT Product2Id FROM PricebookEntry WHERE Name = :PRODUCT_NAME_DOORDASH_GIFT_CARDS limit 1].Id;

            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_1 LIMIT 1];
            opp.Bypass_Pactsafe_Validation__c = true;
            update opp;

            List<PriceBookEntry> pbes = [SELECT Id, Product2Id, Product2.Family FROM PricebookEntry WHERE Name in (:PRODUCT_NAME_DDFB_GROUP_CART, :PRODUCT_NAME_DOORDASH_GIFT_CARDS)];
            OpportunityLineItem oli = TDdOpportunityLineItemFactory.createOpportunityProducts(opp.Id, pbes)[0];
            insert new Bypass_Pactsafe_Validation__c(Name = PRODUCT_NAME_DDFB_GROUP_CART, Product2Id__c = filterId);

            insert oli;
            Test.StopTest();

            Opportunity result = [select Bypass_Pactsafe_Validation__c from Opportunity where Id = :opp.Id];
            System.assertEquals(false, result.Bypass_Pactsafe_Validation__c);
        }
    }

    /**
     * * Test method for CDdOpportunityLineItemHelperMethods.updateOpportunity that sets
     * the Opportunity.Has_Bbot_Product__c field - BZAP-17040
     */
    @IsTest
    public static void testBbotUpdateOppFromOppLineItem() {
        System.runAs(getTestRunUser()) {
        	// insert Product
            Product2 bbotProduct = new Product2(Name = 'Test Bbot Product', Family = 'Bbot');
            insert bbotProduct;

            // insert PricebookEntry
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(
                    Pricebook2Id = pricebookId,
                    Product2Id = bbotProduct.Id,
                    UnitPrice = 0,
                    IsActive = true
            );
            insert pbe;
            Opportunity opp;
            Account acct = TDdAccountFactory.createAccounts('Test Account', 1, 'Marketplace')[0];
            insert acct;

            Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];  insert contact;
            opp = TDdOpportunityFactory.createOpportunityByDevRT('Bbot Opp', acct.Id, contact.Id, CDdOpportunityTriggerHelper.STAGE_NAME_MEETING_RAN_NEGOTIATED, 'ML_Inside_Sales');
            opp.Tablet_Delivery_Method__c = null;
            opp.Tablet_Kit_Type__c = null;
            opp.Has_Bbot_Product__c = true;   // Setting this to true manually because the point of the test is not to test OLI trigger         
            insert opp;

            Test.startTest();
            OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id, Quantity = 1, UnitPrice = 1);
            insert oli;
            Test.stopTest();

            Opportunity oppVerify = [SELECT Id, Has_Bbot_Product__c FROM Opportunity WHERE Id =: opp.Id LIMIT 1];
            System.assertEquals(true, oppVerify.Has_Bbot_Product__c, 'Opp.Has_Bbot_Product__d did not get set to TRUE after adding a Bbot Product to the Opportunity.');
        }
    }

    /**
     * Test method for CDdOpportunityLineItemHelperMethods.fopoAndOrOAS() that fills up discount fields
     * BZAP-17786
     */
    @IsTest
    public static void testFopoAndOrOAS() {
        System.runAs(getTestRunUser()) {
            // Create Products
            List<Product2> products = new List<Product2>();
            Product2 oasProduct = new Product2(Name = 'Order Again', Family = 'Promotions', Billing_Frequency__c = 'Monthly');
            Product2 fopoProduct = new Product2(Name = 'First Order, Percentage Off', Family = 'Promotions', Billing_Frequency__c = 'Monthly');
            products.add(oasProduct);
            products.add(fopoProduct);
            insert products;

            for (Product2 prod: products) {
                if (prod.Name == 'Order Again') {
                    oasProduct = prod;
                }
                if (prod.Name == 'First Order, Percentage Off') {
                    fopoProduct = prod;
                }
            }
            
            // Create PricebookEntries
            List<PricebookEntry> pbes = new List<PricebookEntry>();
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry oapbe = new PricebookEntry(
                    Pricebook2Id = pricebookId,
                    Product2Id = oasProduct.Id,
                    UnitPrice = 10000,
                    IsActive = true,
                    CurrencyIsoCode = 'AUD'
            );
            PricebookEntry fopopbe = new PricebookEntry(
                    Pricebook2Id = pricebookId,
                    Product2Id = fopoProduct.Id,
                    UnitPrice = 10000,
                    IsActive = true,
                    CurrencyIsoCode = 'AUD'
            );
            pbes.add(oapbe);
            pbes.add(fopopbe);
            insert pbes;

            // Create Account, Contact, Opp
            Account acct = TDdAccountFactory.createAccounts('Test FOPO', 1, 'Marketplace')[0];
            insert acct;
            Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];  insert contact;
            Opportunity oppty = TDdOpportunityFactory.createOpportunityByDevRT('FOPO Opp', acct.Id, contact.Id,
                                                                               CDdOpportunityTriggerHelper.STAGE_NAME_MEETING_RAN_NEGOTIATED, 'ML_Inside_Sales');
            insert oppty;
            oppty.CurrencyIsoCode = 'AUD'; // USD pricebookentry are excluded from the logic in the trigger. Also, currency would not set on insert. Had to do update
            update oppty;
            Test.startTest();

            // Create OpportunityLineItem
            List<OpportunityLineItem> olis = TDdOpportunityLineItemFactory.createOpportunityProducts(oppty.Id, pbes);
            OpportunityLineItem oliOriginal = null;

            for (OpportunityLineItem oli: olis) {             
                if (oli.Product2Id == fopoProduct.Id) {
                    oliOriginal = oli;
                    oli.Marketing_Only_Commission__c = 5.5;
                    oli.Discount_Percentage__c = null;
                    oli.Max_Discount__c = 3.0;
                }  
            }
            insert olis;

            // Verifications start - Test 1 - Insert
            List<OpportunityLineItem> olisCreated = [SELECT Id, Discount_Percentage__c, Max_Discount__c, OpportunityId, Product2Id FROM OpportunityLineItem WHERE Id in: olis];
            OpportunityLineItem oliVerify;
            for (OpportunityLineItem oli: olisCreated) {
                if (oli.Product2Id == fopoProduct.Id) {
                    oliVerify = oli;
                }
            }
            System.assertNotEquals(null, oliOriginal);
            System.assertNotEquals(null, oliVerify);
            // Scenario where the oli value is being set by another field value
            System.assertEquals(oliOriginal.Marketing_Only_Commission__c * 100, oliVerify.Discount_Percentage__c, 
                                'Fail, the Discount_Percentage__c = ' + oliVerify.Discount_Percentage__c + ' while expected value is ' + oliOriginal.Marketing_Only_Commission__c * 100);

            // Scenario where the oli value is remaining the same
            System.assertEquals(oliOriginal.Max_Discount__c, oliVerify.Max_Discount__c , 
                                'Fail, the Max_Discount__c = ' + oliVerify.Max_Discount__c + ' while expected value is ' + oliOriginal.Max_Discount__c);

                                // Test 2 - Update
            OpportunityLineItem oasLineItemUpdated;
            for (OpportunityLineItem oli: olisCreated) {
                if (oli.Product2Id == oasProduct.Id) {
                    oliOriginal = oli; // before updates
                    oli.Marketing_Only_Commission__c = null;
                    oli.Max_Amount_From_Marketing_Percent__c = null;
                    oli.Max_Discount__c = 3.0;
                    oasLineItemUpdated = oli; // after updates
                }
            }

            update oasLineItemUpdated;
            OpportunityLineItem oliVerifyUpdate = [SELECT Id, Max_Amount_From_Marketing_Percent__c , Max_Discount__c FROM OpportunityLineItem WHERE Id =: oasLineItemUpdated.Id];

            // Scenario where everything is set to null and will remain null
            System.assertEquals(null, oliVerifyUpdate.Max_Amount_From_Marketing_Percent__c, 
                                'Fail, the Max_Amount_From_Marketing_Percent__c = ' + oliVerifyUpdate.Max_Amount_From_Marketing_Percent__c + ' while expected value is ' + null);

            oasLineItemUpdated.Marketing_Only_Commission__c = 0.25;
            oasLineItemUpdated.Max_Discount__c = null;
            update oasLineItemUpdated;

            Test.stopTest();
            oliVerifyUpdate = [SELECT Id, Max_Amount_From_Marketing_Percent__c , Max_Discount__c FROM OpportunityLineItem WHERE Id =: oasLineItemUpdated.Id];
            // Scenario leveraging map in fopoAndOrOAS()
            System.assertEquals(6, oliVerifyUpdate.Max_Discount__c , 
                                'Fail, the Max_Discount__c = ' + oliVerifyUpdate.Max_Discount__c + ' while expected value is 6 (based on map in fopoAndOrOAS()');
        }
    }
}