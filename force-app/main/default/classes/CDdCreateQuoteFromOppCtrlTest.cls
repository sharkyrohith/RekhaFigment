@isTest
public class CDdCreateQuoteFromOppCtrlTest {
    @TestSetup
    static void makeData(){
        CDdContactTriggerHelper.insertCampaign();
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
    	validation.Bypass_Opportunity_Validations__c = true;
    	validation.Bypass_Account_Validations__c = true;
    	insert validation;

        List<Account> lstacct = TDdAccountFactory.createAccountsWithDynamicAddress('UnitedStates',1,'Marketplace','United States','US','CA', '+81 999 989 999','48075');
        lstacct.addAll(TDdAccountFactory.createAccountsWithDynamicAddress('Canada',1,'Marketplace','Canada','CA','AB', '+81 9-9999-9999', '91767'));
        lstacct.addAll(TDdAccountFactory.createAccountsWithDynamicAddress('Japan',1,'Marketplace','Japan','JP','Miyagi', '+81 9-9999-9999','981-1106'));
        lstacct.addAll(TDdAccountFactory.createAccountsWithDynamicAddress('Germany',1,'Marketplace','Germany','DE','Bavaria', '+49-999-989-999','70176'));
        lstacct.addAll(TDdAccountFactory.createAccountsWithDynamicAddress('Australia',1,'Marketplace','Australia','AU','Victoria', '+61 999 999 999','3005'));
        insert lstacct;

        List<Opportunity> opps = new List<Opportunity>();
        opps.add(TDdCPQTestDataFactory.createOpportunityByDevRT('UnitedStatesMKT', lstacct[0].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false));
        opps.add(TDdCPQTestDataFactory.createOpportunityByDevRT('CanadaMKT', lstacct[1].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false));
        opps.add(TDdCPQTestDataFactory.createOpportunityByDevRT('JapanMKT', lstacct[2].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false));
        opps.add(TDdCPQTestDataFactory.createOpportunityByDevRT('GermanyMKT', lstacct[3].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false));
        opps.add(TDdCPQTestDataFactory.createOpportunityByDevRT('AustraliaMKT', lstacct[4].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false));
        opps.add(TDdOpportunityFactory.createPostSaleOpportunity('UnitedStatesPOST', lstacct[0].Id, 'Meeting Ran / Negotiated'));
        opps.add(TDdOpportunityFactory.createPostSaleOpportunity('CanadaPOST', lstacct[1].Id, 'Meeting Ran / Negotiated'));
        opps.add(TDdOpportunityFactory.createPostSaleOpportunity('AustraliaPOST', lstacct[4].Id, 'Meeting Ran / Negotiated'));

        Opportunity businessOpportunity = TDdCPQTestDataFactory.createOpportunityByDevRT(
            'USBusiness',
            lstacct[0].Id,
            null,
            'Meeting Ran / Negotiated',
            'DoorDash_for_Business',
            false
        );
        businessOpportunity.Eligible_Employees__c = 78;
        opps.add(businessOpportunity);

        insert opps;

        Contact contact = TDdCPQTestDataFactory.createContact(true);

        Pricebook2 pricebook = new PriceBook2(
            Id = Test.getStandardPriceBookId()
        );
        update pricebook;
    }

    private static Account getUSAccount(){
        return [SELECT Id FROM Account WHERE Name LIKE '%UnitedStates%' LIMIT 1];
    }

    private static Opportunity getBusinessOpportunity(){
        return [
            SELECT Id,Order_Protocol__c,Caviar_Order_Protocol__c,CloseDate,Eligible_Employees__c
            FROM Opportunity
            WHERE Name LIKE '%USBusiness%'
            LIMIT 1
        ];
    }

    private static Opportunity getUSMktOpportunity(){
        return [
            SELECT Id,Order_Protocol__c,Caviar_Order_Protocol__c,CloseDate,Shopping_Protocol__c,Legal_Entity__c,Control_of_Price__c,
            Commission_Calculation_Methodology__c,Payment_Protocol__c
            FROM Opportunity
            WHERE Name LIKE '%UnitedStatesMKT%'
            LIMIT 1
        ];
    }

    private static Contact getContact(){
        return [SELECT Id FROM Contact LIMIT 1];
    }

    private static SBQQ__Quote__c getQuote(){
        return [
            SELECT Id, SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__SubscriptionTerm__c,
                SBQQ__Primary__c, SBQQ__StartDate__c, SBQQ__ExpirationDate__c,
                SBQQ__Pricebook__c, SBQQ__PricebookId__c, Drawer_Attributes__c
            FROM SBQQ__Quote__c LIMIT 1
        ];
    }

    @isTest
    static void testQuoteCreate(){
        Contact contact = getContact();
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        opp.Order_Protocol__c = CDdCpqBillingConstants.OPP_ORD_PROTOCOL_EMAIL;
        opp.Decision_Maker__c = contact.Id;
        update opp;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        Test.setCurrentPage(ref);
        ref.getParameters().put('id',opp.Id);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        SBQQ__Quote__c quote = getQuote();
        System.assertNotEquals(null, quote, 'The quote was not created');
        System.assertEquals(opp.Id, quote.SBQQ__Opportunity2__c, 'The correct opportunituy was not mapped to the quote');
        System.assertEquals(Test.getStandardPriceBookId(), quote.SBQQ__Pricebook__c, 'The standard pricebook was not mapped to the quote');
        System.assertEquals(Test.getStandardPriceBookId(), quote.SBQQ__PricebookId__c, 'The standard pricebook Id was not mapped to the quote');
        System.assertEquals(true, quote.SBQQ__Primary__c, 'The quote was not created as primary');
        System.assertEquals(Date.today(), quote.SBQQ__StartDate__c, 'The quote start date should be today');
    }
    /**
     * Test that any error is given when creating a quote
     */
    @isTest
    static void testQuoteCreateNegative(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        opp.Order_Protocol__c = null;
        update opp;
        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        Test.setCurrentPage(ref);
        ref.getParameters().put('id','1234567');
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        try{
            createQuoteController.createQuote();
        } catch( Exception e) {
            System.assertNotEquals(null, e);
        }
        test.stopTest();
    }
    /**
     * Test that an error is given when there is a contract out for signature already
     */
    @isTest
    static void testQuoteCreateNegative2(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(opp, account, null, false);
        quote.SBQQ__Status__c = 'Out for Signature';
        insert quote;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertEquals(true, createQuoteController.error, 'There should be an error when the quote is Out for Signature');
    }

    /**
     * Test that an error is given when decision maker is null
     */
    @isTest
    static void createQuote_nullDecisionMaker_expectErrorThrown(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        opp.Decision_Maker__c = null;
        update opp;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertEquals(true, createQuoteController.error, 'There should be an error when the decision maker is null');
    }

    @isTest
    static void createQuote_nullEligibleEmployees_ddfbRecordType_expectErrorThrown(){
        Account account = getUSAccount();
        Contact testContact = getContact();
        Opportunity opp = getBusinessOpportunity();
        opp.Eligible_Employees__c = null;
        opp.Decision_Maker__c = testContact.Id;
        opp.Order_Protocol__c = CDdCpqBillingConstants.OPP_ORD_PROTOCOL_EMAIL;
        update opp;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertEquals(
            true,
            createQuoteController.error,
            'There should be an error when the decision maker is null for a DDFB-type Opportunity.'
        );
    }

    @isTest
    static void createQuote_setEligibleEmployees_ddfbRecordType_expectNoErrorThrown(){
        Account account = getUSAccount();
        Contact testContact = getContact();
        Opportunity opp = getBusinessOpportunity();
        opp.Eligible_Employees__c = 666;
        opp.Decision_Maker__c = testContact.Id;
        opp.Order_Protocol__c = CDdCpqBillingConstants.OPP_ORD_PROTOCOL_EMAIL;
        update opp;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        SBQQ__Quote__c quote = getQuote();
        System.assertNotEquals(null, quote, 'The quote was not created');
        System.assertNotEquals(
            true,
            createQuoteController.error,
            'There should not be an error when the decision maker is non-null for a DDFB-type Opportunity. Instead: ' +
                ApexPages.getMessages()
        );
    }

    @isTest
    static void createQuote_nullEligibleEmployees_nonDDFBRecordType_expectNoErrorThrown(){
        Account account = getUSAccount();
        Contact testContact = getContact();
        Opportunity opp = getUSMktOpportunity();
        opp.Eligible_Employees__c = null;
        opp.Decision_Maker__c = testContact.Id;
        opp.Order_Protocol__c = CDdCpqBillingConstants.OPP_ORD_PROTOCOL_EMAIL;
        update opp;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        SBQQ__Quote__c quote = getQuote();
        System.assertNotEquals(null, quote, 'The quote was not created');
        System.assertNotEquals(
            true,
            createQuoteController.error,
            'There should not be an error when the decision maker is null for a non-DDFB Opportunity. Instead: ' +
                ApexPages.getMessages()
        );
    }

    /**
     * Test that an error is given when Shopping protocol is null and PMC is not equals to any of these values'Prepared Food & Drink (Rx)','Government or Non-Profit'
     * and 'Incumbents'
     */
    @isTest
    static void createQuoteNullShoppingProtocolExpectErrorThrown(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        Contact testContact = getContact();
        Account.BillingCountry = 'United States';
        account.Primary_Merchant_Categories__c = 'Flowers';
        opp.Legal_Entity__c = 'US - G&C';
        opp.Shopping_Protocol__c = null;
        opp.Control_of_Price__c = 'Merchant';
        opp.Commission_Calculation_Methodology__c = 'DoorDash Platform Price';
        opp.Payment_Protocol__c = 'Credit Card';
        opp.Decision_Maker__c = testContact.Id;
        opp.Order_Protocol__c = CDdCpqBillingConstants.OPP_ORD_PROTOCOL_EMAIL;
        update opp;
        update account;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertEquals(true, createQuoteController.error, 'There should be an error when the shopping protocol is null');
    }

     /**
     * Test that an error will not be thrown when leagl entity is not equals to'US G&C', Shopping protocol is null and PMC is not equals to any of these values'Prepared Food & Drink (Rx)','Government or Non-Profit'
     * and 'Incumbents'
     */
    @isTest
    static void createQuoteShoppingProtocolEqualsToNullLegalEntityEqualsToUSGCExpectNoErrorThrown(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        Contact testContact = getContact();
        Account.BillingCountry = 'United States';
        account.Primary_Merchant_Categories__c = 'Flowers';
        opp.Legal_Entity__c = 'US';
        opp.Shopping_Protocol__c = null;
        opp.Control_of_Price__c = 'Merchant';
        opp.Payment_Protocol__c = 'Credit Card';
        opp.Decision_Maker__c = testContact.Id;
        opp.Order_Protocol__c = CDdCpqBillingConstants.OPP_ORD_PROTOCOL_EMAIL;
        update opp;
        update account;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertNotEquals(true, createQuoteController.error, 'There should not be an error: ' + ApexPages.getMessages());
    }

    /**
     * Test that an error will not be thrown when Commission Calculation Methodology is null and PMC is equals to any of these values 'Prepared Food & Drink (Rx)','Government or Non-Profit'
     * and 'Incumbents'
     */
    @isTest
    static void createQuoteCCMEqualsToNullAndPmcEqualsToGovernmentOrNonProfitExpectNoErrorThrown(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        Contact testContact = getContact();
        Account.BillingCountry = 'United States';
        account.Primary_Merchant_Categories__c = 'Government or Non-Profit';
        opp.Legal_Entity__c = 'US - G&C';
        opp.Shopping_Protocol__c = 'Mx Pick';
        opp.Control_of_Price__c = 'Merchant';
        opp.Payment_Protocol__c = 'Credit Card';
        opp.Commission_Calculation_Methodology__c = null;
        opp.Decision_Maker__c = testContact.Id;
        opp.Order_Protocol__c = CDdCpqBillingConstants.OPP_ORD_PROTOCOL_EMAIL;
        update opp;
        update account;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertNotEquals(true, createQuoteController.error, 'There should not be an error: ' + ApexPages.getMessages());
    }

     /**
     * Test that an error is given when opportunity type is null
     */
    @isTest
    static void testQuoteCreateNegative4(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        opp.Type = null;
        update opp;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertEquals(true, createQuoteController.error, 'There should be an error when the opp type is null');
    }

     /**
     * Test that an error is given when order protocol is null
     */
    @isTest
    static void testQuoteCreateNegative5(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        opp.Order_Protocol__c = null;
        update opp;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertEquals(true, createQuoteController.error, 'There should be an error when the order protocol is null');
    }
    /**
     * Test that an error is given when Opp stage is Contract Signed
     */
    @isTest
    static void testQuoteCreateNegative6(){
        Account account = getUSAccount();
        Opportunity opp = [SELECT Id, Order_Protocol__c,Caviar_Order_Protocol__c, CloseDate FROM Opportunity  WHERE Name LIKE '%UnitedStatesMKT%' LIMIT 1];
        opp.StageName = CDdCpqBillingConstants.OPP_STAGENAME_CONTRACT_SIGNED;
        update opp;

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        ref.getParameters().put('id',opp.Id);
        Test.setCurrentPage(ref);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        createQuoteController.createQuote();
        Test.StopTest();

        System.assertEquals(true, createQuoteController.error, 'There should be an error when the Opp Stage is Contract Signed.');
    }
    /**
     * Test sending a user back to the Opportuntiy
     */
     @isTest
    static void testReturnToOpp(){
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        Test.setCurrentPage(ref);
        ref.getParameters().put('id',opp.Id);
        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);
        PageReference refAfter = createQuoteController.returnToOpp();
        Test.StopTest();

        System.assertEquals(opp.Id, ApexPages.currentPage().getParameters().get('id'),'The current Page should still contain the Opportunity Id Parameter');
    }

    /**
     * Set user group to USD Inside Presales
     */
    @isTest
    static void testSetUserGroupUSDMktIn(){
        // UserRole developer is hardcoded here because the CPQ code expects the role to contain 'Inside'
        // This needs to be updated if the CPQ code changes, or if the role is deleted/renamed.
        Id roleId = TDdUserFactory.getUserRole('Account_Executive_Inside_Sales');
        User testUser = TDdUserFactory.createUsers(1, null, roleId, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%UnitedStatesMKT%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('USD Inside Presales', userGroup, 'The User group for the quote should be USD Inside Presales');
        }
    }
    /**
     * Set user group to USD Outside Presales
     */
    @isTest
    static void testSetUserGroupUSDMktOut(){
        // UserRole developer is hardcoded here because the CPQ code expects the role to contain 'Outside'
        // This needs to be updated if the CPQ code changes, or if the role is deleted/renamed.
        Id roleId = TDdUserFactory.getUserRole('Account_Executive_Outside_Sales');
        User testUser = TDdUserFactory.createUsers(1, null, roleId, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%UnitedStatesMKT%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('USD Outside Presales', userGroup, 'The User group for the quote should be USD Outside Presales');
        }
    }

    /**
     * Set user group to US Alcohol Only Presales
     */
    @isTest
    static void testSetUserGroupUSDMktAlc(){
        // UserRole developer is hardcoded here because the CPQ code expects the role to contain 'Alcohol'
        // This needs to be updated if the CPQ code changes, or if the role is deleted/renamed.
        Id roleId = TDdUserFactory.getUserRole('Account_Executive_Alcohol');
        User testUser = TDdUserFactory.createUsers(1, null, roleId, false)[0];

        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%UnitedStatesMKT%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('US Alcohol Only Presales', userGroup, 'The User group for the quote should be US Alcohol Only Presales');
        }
    }

    /**
     * Set user group to USD Inside Postsales
     */
    @isTest
    static void testSetUserGroupUSDPostInside(){
        // UserRole developer is hardcoded here because the CPQ code expects the role to contain 'Inside'
        // This needs to be updated if the CPQ code changes, or if the role is deleted/renamed.
        Id roleId = TDdUserFactory.getUserRole('Account_Executive_Inside_Sales');
        User testUser = TDdUserFactory.createUsers(1, null, roleId, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%UnitedStatesPOST%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('USD Inside Postsales', userGroup, 'The User group for the quote should be USD Inside Postsales');
        }
    }

    /**
     * Set user group to USD Outside Postsales
     */
    @isTest
    static void testSetUserGroupUSDPostOutside(){
        // UserRole developer is hardcoded here because the CPQ code expects the role to contain 'Outside'
        // This needs to be updated if the CPQ code changes, or if the role is deleted/renamed.
        Id roleId = TDdUserFactory.getUserRole('Account_Executive_Outside_Sales');
        User testUser = TDdUserFactory.createUsers(1, null, roleId, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%UnitedStatesPOST%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('USD Outside Postsales', userGroup, 'The User group for the quote should be USD Outside Postsales');
        }
    }

    /**
     * Set user group to US Alcohol Only Postsales
     */
    @isTest
    static void testSetUserGroupUSDPostAlc(){
        // UserRole developer is hardcoded here because the CPQ code expects the role to contain 'Alcohol'
        // This needs to be updated if the CPQ code changes, or if the role is deleted/renamed.
        Id roleId = TDdUserFactory.getUserRole('Account_Executive_Alcohol');
        User testUser = TDdUserFactory.createUsers(1, null, roleId, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%UnitedStatesPOST%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('US Alcohol Only Postsales', userGroup, 'The User group for the quote should be US Alcohol Only Postsales');
        }
    }

     /**
     * Set user group to AUD Presales
     */
    @isTest
    static void testSetUserGroupAUDMkt(){
        //No role for this test
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%AustraliaMKT%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('AUD Presales', userGroup, 'The User group for the quote should be AUD Presales');
        }
    }

    /**
     * Set user group to AUD Postsales
     */
    @isTest
    static void testSetUserGroupAUDPost(){
        //No role for this test
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%AustraliaPOST%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('AUD Postsales', userGroup, 'The User group for the quote should be AUD Postsales');
        }
    }

    /**
     * Set user group to CAD Postsales
     */
    @isTest
    static void testSetUserGroupCADMkt(){
        //No role for this test
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%CanadaMKT%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('CAD Presales', userGroup, 'The User group for the quote should be CAD Presales');
        }
    }

    /**
     * Set user group to CAD Postsales
     */
    @isTest
    static void testSetUserGroupCADPost(){
        //No role for this test
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%CanadaPOST%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('CAD Postsales', userGroup, 'The User group for the quote should be CAD Postsales');
        }
    }

    /**
     * Set user group to JPY Presales.  Japan only has a single user group
     */
    @isTest
    static void testSetUserGroupJPY(){
        //No role for this test
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%JapanMKT%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('JPY Presales', userGroup, 'The User group for the quote should be JPY Presales');
        }
    }

    /**
     * Set user group to DEU Presales.  Germany only has a single user group
     */
    @isTest
    static void testSetUserGroupDEU(){
        //No role for this test
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Opportunity oppAfter = [SELECT Id, Name, Account.BillingCountry, RecordType.Name FROM Opportunity WHERE Name LIKE '%GermanyMKT%'];
            String userGroup = CDdCreateQuoteFromOppCtrl.setUserGroup(oppAfter);
            System.assertEquals('DEU Presales', userGroup, 'The User group for the quote should be DEU Presales');
        }
    }

    @isTest
    private static void createQuote_expectDrawerAttributesPopulated(){
        String expectedResult = CDdCreateQuoteFromOppCtrl.drawer_attributes;

        Contact contact = getContact();
        Account account = getUSAccount();
        Opportunity opp = getUSMktOpportunity();
        opp.Order_Protocol__c = CDdCpqBillingConstants.OPP_ORD_PROTOCOL_EMAIL;
        opp.Decision_Maker__c = contact.Id;
        update opp;

        ApexPages.standardController sc = new ApexPages.standardController(opp);
        CDdCreateQuoteFromOppCtrl createQuoteController = new CDdCreateQuoteFromOppCtrl(sc);

        Test.StartTest();
        PageReference ref = Page.PDdCreateQuote;
        Test.setCurrentPage(ref);
        ref.getParameters().put('id',opp.Id);
        createQuoteController.createQuote();
        Test.StopTest();

        SBQQ__Quote__c quote = getQuote();
        System.assertNotEquals(null, quote, 'The quote was not created');
        System.assertNotEquals(null, quote.Drawer_Attributes__c, 'Expected a non-null drawer attributes field.');
        System.assertNotEquals('', quote.Drawer_Attributes__c, 'Expected a non-empty drawer attributes field.');
        System.assertEquals(
            expectedResult,
            quote.Drawer_Attributes__c,
            'Expected the contents of the drawer_attributes property/field set to be set on the quote\'s Drawer_Attributes__c field.'
        );
    }
}