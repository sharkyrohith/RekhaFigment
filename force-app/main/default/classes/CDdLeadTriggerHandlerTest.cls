/**
* @author Tia Xuan
* @date 2019-04
*
* @description Test class for CDdLeadTriggerHandler
*/

@isTest
public class CDdLeadTriggerHandlerTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
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
        System.runAs(getTestRunUser()){
            Test.startTest();
            vCS__c s = VTestUtil.createVeltigSettings();
            s.parentAccMatchFlag__c = true;
            insert s;
            E2F__FindApi_Triggers_Settings__c findAPISettings = new E2F__FindApi_Triggers_Settings__c(
                SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID
                , Name = 'System Administrator'
                , E2F__Bypass_Trigger__c = true
            );
            insert findAPISettings;
            /* Create Serve Users - Begin */
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
            /* Create Serve Users - End */

            List<Account> Accounts = TDdAccountFactory.createAccounts('Account Rollup Test', 2);
            List<Account> checkAccounts;
            for (Integer i = 1; i <= Accounts.size(); i++) {    // Associate a lead with each account
                Accounts[i-1].Restaurant_ID__c = '' +i;
            }
            insert Accounts;
            Test.stopTest();
        }
    }
    /**
    * @description testing lead trigger handler coverage
    */
    @isTest
    public static void testTrigger(){
        System.runAs(getTestRunUser()){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            List<Account> accts = TDdAccountFactory.createAccounts('test', 1,'Parent Account');
            accts[0].Business_ID__c = 1;
            insert accts;
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', true);
            Lead testLead = testLeads[0];
            Test.stopTest();
            Lead updatedLead = (Lead) [SELECT Id, In_Coverage__c, Parent_Account__c FROM Lead WHERE Id =: testLead.Id];
            System.assertEquals('Yes', updatedLead.In_Coverage__c);
            System.assertEquals(accts[0].Id, updatedLead.Parent_Account__c);
        }
    }
    /**
    * @description testing lead trigger handler coverage
    */
    @isTest
    public static void testUpdateAccountForConvertedLeads(){
        User runUser = getTestRunUser();
        System.runAs(runUser){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            List<Account> accts = TDdAccountFactory.createAccounts('test', 1,'Marketplace');
            accts[0].Account_Type__c = 'Franchise';
            accts[0].Business_ID__c = 1;
            insert accts;
            Contact contact = VTestUtil.createContact('Test', 'Contact', accts[0]);
            insert contact;
            Test.startTest();
            Id enterpriseMarktetplaceId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Master_Lead').getRecordTypeId();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            Lead testLead = new Lead(LastName = 'Test Lead 1',
                                     Company = 'Test Company',
                                     Phone = '+81 99-9999-999',
                                     Street = '1225 Hirai Honode-Machi',
                                     City = 'Nishitama-gun',
                                     State = 'Tokyo',
                                     PostalCode = '190-0181',
                                     CountryCode = 'JP',
                                     Validation_Bypass__c = true,
                                     Business_ID__c = 1,
                                     RecordTypeId = enterpriseMarktetplaceId,
                                     Lead_List__c = System.today(),
                                     Store_ID__c = '123456',
                                     ARR__c = 1000.00,
                                     Amount__c = 1000.00,
                                     Lead_Type__c = 'Net New',
                                     Deck_Rank__c = 'Ace of Spades',
                                     Starting_Point__c = '100',
                                     Starting_Point_ID__c = 100,
                                     Deactivation_Note__c = 'Test Deactivation Note',
                                     Deactivation_Code__c = 'Awaiting activation',
                                     Type__c = 'Franchise', //Team Type
                                     Launch_Deck_Rank__c = 'Ace'
                                    );
            insert testLead;
            List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
            List<Lead> leadUpdates = new List<Lead>();
            testLead.OwnerId = runUser.Id;
            testLead.Validation_Bypass__c = true;
            leadUpdates.add(testLead);
            upsert leadUpdates;
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setAccountId(accts[0].Id);
            lc.setContactId(contact.Id);
            lc.setConvertedStatus('Meeting Ran / Negotiated');
            lc.setOverwriteLeadSource(true);
            lc.setDoNotCreateOpportunity(true);
            leadsToConvert.add(lc);
            List<Database.LeadConvertResult> lcResults = Database.convertLead(leadsToConvert);
            Test.stopTest();
            Account accountToTest = [ SELECT Id, BypassValidationForProcessBuilder__c, OwnerId
                                     FROM Account
                                     WHERE ID = :accts[0].Id
                                    ];
            System.assertEquals(false, accountToTest.BypassValidationForProcessBuilder__c, 'Expected reset of the bypass validation flag');
            System.assertEquals(runUser.Id, accountToTest.OwnerId, 'Expected owner id on the Account - ' + runUser.Id);
        }
    }
    /**
    * @description Test for validation of unassigned lead conversion
    */
    @isTest
    public static void validateUnassignedLeadConversion(){
        String validationErrorMsg = '';
        User runUser = getTestRunUser();
        System.runAs(runUser){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            List<Account> accts = TDdAccountFactory.createAccounts('test', 1,'Marketplace');
            accts[0].Business_ID__c = 1;
            insert accts;
            Test.startTest();
            Id enterpriseMarktetplaceId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Master_Lead').getRecordTypeId();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.OwnerId = (new List<Id>(CDdLeadTriggerHelper.UNASSIGNED_QUEUE.keySet())).get(0);
            insert testLeads;
            List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
            List<Lead> leadUpdates = new List<Lead>();
            //testLead.OwnerId = runUser.Id;
            testLead.Validation_Bypass__c = true;
            leadUpdates.add(testLead);
            upsert leadUpdates;
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setAccountId(accts[0].Id);
            lc.setConvertedStatus('Meeting Ran / Negotiated');
            lc.setOverwriteLeadSource(true);
            lc.setDoNotCreateOpportunity(true);
            lc.setOwnerId(runUser.Id);
            leadsToConvert.add(lc);
            try {
                List<Database.LeadConvertResult> lcResults = Database.convertLead(leadsToConvert);
            } catch (Exception e){
                validationErrorMsg = e.getMessage();
            }
            Test.stopTest();
            if (CDdLeadTriggerHelper.VALIDATE_UNASSIGNED_LEAD_CONVERSION){
                System.assertEquals(true, String.isNotBlank(validationErrorMsg), 'Expecting a non-empty validation error message');
                System.assertEquals(true, validationErrorMsg.contains(CDdLeadTriggerHelper.ERROR_MSG_UNASSIGNED_LEAD_CONVERSION), 'Expecting the lead to fail on conversion');
            }
        }
    }
    /**
    * @description BZAP-4027 - Automatically populate "Decision Maker" field in an opportunity from a lead being converted
    */
    @isTest
    public static void testUpdateOpportunityForConvertedLeads(){
        User runUser = getTestRunUser();
        System.runAs(runUser){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            List<Account> accts = TDdAccountFactory.createAccounts('test', 1,'Marketplace');
            accts[0].Account_Type__c = 'Franchise';
            accts[0].Business_ID__c = 1;
            accts[0].Deck_Rank__c = 'Jack';
            insert accts;
            Contact contact = VTestUtil.createContact('Test', 'Contact', accts[0]);
            insert contact;
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', true);
            Lead testLead = testLeads[0];
            List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
            List<Lead> leadUpdates = new List<Lead>();
            testLead.OwnerId = runUser.Id;
            testLead.Validation_Bypass__c = true;
            leadUpdates.add(testLead);
            upsert leadUpdates;
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setAccountId(accts[0].Id);
            lc.setContactId(contact.Id);
            lc.setConvertedStatus('Meeting Ran / Negotiated');
            lc.setOverwriteLeadSource(true);
            lc.setDoNotCreateOpportunity(false);
            leadsToConvert.add(lc);
            List<Database.LeadConvertResult> lcResults = Database.convertLead(leadsToConvert);
            Test.stopTest();
            Lead leadFromDB = [SELECT Id, ConvertedOpportunityId FROM Lead WHERE Id = :testLead.Id];
            Opportunity opportunity = [ SELECT Id, Decision_Maker__c
                                       FROM Opportunity
                                       WHERE ID = :leadFromDB.ConvertedOpportunityId
                                      ];
            System.assertEquals(contact.Id, opportunity.Decision_Maker__c, 'Expected Opportunity with updated Decision Maker ' + opportunity.Decision_Maker__c);
        }
    }
    /**
    * @description BZAP-5470 - set the campaing lead source for lead convert
    */
    // @isTest
    // public static void testUpdateOpportunityPrimaryCampaignForConvertedLeads(){
    //     List<User> testUsers = TDdAccountFactory.createUsers(1);
    //     insert testUsers;
    //     User runUser = testUsers[0];
    //     System.runAs (runUser) {
    //         Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
    //         List<Account> accts = TDdAccountFactory.createAccounts('test', 1,'Marketplace');
    //         accts[0].Business_ID__c = 1;
    //         accts[0].Account_Type__c = 'Franchise';
    //         accts[0].Deck_Rank__c = 'Jack';
    //         insert accts;
    //         Contact contact = VTestUtil.createContact('Test', 'Contact', accts[0]);
    //         insert contact;
    //         Test.startTest();
    //         CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
    //         List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', true);
    //         Lead testLead = testLeads[0];
    //         List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
    //         List<Lead> leadUpdates = new List<Lead>();
    //         testLead.OwnerId = runUser.Id;
    //         testLead.Validation_Bypass__c = true;
    //         leadUpdates.add(testLead);
    //         upsert leadUpdates;

    //         RealZip__RealZips__c realZipRec = new RealZip__RealZips__c(Submarket_ID__c = 10);
    //         insert realZipRec;

    //         Id promoRecTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
    //         Campaign testCampaign = new Campaign(RecordTypeId = promoRecTypeId,
    //                                             Name = 'Test Campaign Name',
    //                                             Title__c = 'Test Campaign Title',
    //                                             Delivery_Fee__c = 3,
    //                                             Min_Order_Cart_Subtotal__c = 10,
    //                                             New_Customer_Only__c = false,
    //                                             Promotion_Type__c = 'tmf',
    //                                             Description = 'Test Campaign Description',
    //                                             Show_as_Carousel__c = false,
    //                                             RealZip__c = realZipRec.Id,
    //                                             Sort_Order__c = '1',
    //                                             BFF_Promotion_Id__c = '123',
    //                                             isActive = true);
    //         insert testCampaign;

    //         CampaignMember cm = new CampaignMember(CampaignId = testCampaign.Id, LeadId = testLead.Id);
    //         insert cm;


    //         Database.LeadConvert lc = new Database.LeadConvert();
    //         lc.setLeadId(testLead.Id);
    //         lc.setAccountId(accts[0].Id);
    //         lc.setContactId(contact.Id);
    //         lc.setConvertedStatus('Meeting Ran / Negotiated');
    //         lc.setOverwriteLeadSource(true);
    //         lc.setDoNotCreateOpportunity(false);
    //         leadsToConvert.add(lc);
    //         List<Database.LeadConvertResult> lcResults = Database.convertLead(leadsToConvert);
    //         Test.stopTest();
    //         Lead leadFromDB = [SELECT Id, ConvertedOpportunityId FROM Lead WHERE Id = :testLead.Id];
    //         Opportunity opportunity = [ SELECT Id, CampaignId
    //                                     FROM Opportunity
    //                                     WHERE ID = :leadFromDB.ConvertedOpportunityId
    //                                 ];
    //         System.assertEquals(opportunity.CampaignId, testCampaign.Id);
    //     }
    // }

    /**
    * @description BZAP-4559 - Copy Parent Account information to master leads (unconverted leads)
    */
    @isTest
    public static void copyFromParentAccountToMasterLeads1(){
        String parentAccountName = 'Test Parent Account';
        Decimal TEST_BUSINESS_ID = 7678900.0;
        String TEST_TEAM_TYPE = 'Enterprise';
        String TEST_DECK_RANK = 'King';
        Decimal TEST_NTAM_SALES = 123456.00;
        User runUser = getTestRunUser();
        System.runAs(runUser){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
            parentAccount.Business_ID__c = TEST_BUSINESS_ID;
            parentAccount.Account_Type__c = TEST_TEAM_TYPE;
            parentAccount.Deck_Rank__c = TEST_DECK_RANK;
            parentAccount.Amount__c = TEST_NTAM_SALES;
            insert parentAccount;
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_ID__c = TEST_BUSINESS_ID;
            testLead.Type__c = null;
            testLead.Deck_Rank__c = null;
            testLead.Amount__c = null;
            insert testLead;
            Test.stopTest();
            Account testParentAccountFromDB = [SELECT Id, Business_Id__c, Account_Type__c, Deck_Rank__c, Amount__c FROM Account WHERE Id = :parentAccount.Id];
            Lead testLeadFromDB = [SELECT Id, Business_Id__c, Type__c, Deck_Rank__c, Amount__c FROM Lead WHERE Id = :testLead.Id];
            System.assertEquals(TEST_BUSINESS_ID, testLeadFromDB.Business_Id__c, 'Expected Business Id ' + TEST_BUSINESS_ID);
            System.assertEquals(TEST_TEAM_TYPE, testLeadFromDB.Type__c, 'Expected Team Type ' + TEST_TEAM_TYPE);
            System.assertEquals(testParentAccountFromDB.Deck_Rank__c, testLeadFromDB.Deck_Rank__c, 'Expected Deck Rank ' + testParentAccountFromDB.Deck_Rank__c);
            System.assertEquals(TEST_NTAM_SALES, testLeadFromDB.Amount__c, 'Expected nTam Sales ' + TEST_NTAM_SALES);
        }
    }
    /**
    * @description BZAP-4559 - Copy Parent Account information to master leads (unconverted leads)
    */
    @isTest
    public static void copyFromParentAccountToMasterLeads2(){
        String parentAccountName = 'Test Parent Account';
        Decimal TEST_BUSINESS_ID = 7678900.0;
        String TEST_TEAM_TYPE = 'Enterprise';
        String TEST_DECK_RANK = 'King';
        Decimal TEST_NTAM_SALES = 123456.00;
        User runUser = getTestRunUser();
        System.runAs(runUser){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
            parentAccount.Business_ID__c = TEST_BUSINESS_ID;
            parentAccount.Account_Type__c = TEST_TEAM_TYPE;
            parentAccount.Deck_Rank__c = TEST_DECK_RANK;
            parentAccount.Amount__c = TEST_NTAM_SALES;
            insert parentAccount;
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Type__c = null;
            testLead.Deck_Rank__c = null;
            testLead.Amount__c = null;
            insert testLead;
            testLead.Business_Id__c = TEST_BUSINESS_ID;
            update testLead;
            Test.stopTest();
            Account testParentAccountFromDB = [SELECT Id, Business_Id__c, Account_Type__c, Deck_Rank__c, Amount__c FROM Account WHERE Id = :parentAccount.Id];
            Lead testLeadFromDB = [SELECT Id, Business_Id__c, Type__c, Deck_Rank__c, Amount__c FROM Lead WHERE Id = :testLead.Id];
            System.assertEquals(TEST_BUSINESS_ID, testLeadFromDB.Business_Id__c, 'Expected Business Id ' + TEST_BUSINESS_ID);
            System.assertEquals(TEST_TEAM_TYPE, testLeadFromDB.Type__c, 'Expected Team Type ' + TEST_TEAM_TYPE);
            System.assertEquals(testParentAccountFromDB.Deck_Rank__c, testLeadFromDB.Deck_Rank__c, 'Expected Deck Rank ' + testParentAccountFromDB.Deck_Rank__c);
            System.assertEquals(TEST_NTAM_SALES, testLeadFromDB.Amount__c, 'Expected nTam Sales ' + TEST_NTAM_SALES);
        }
    }
    /**
    * @description BZAP-4559 - Copy Parent Account information to master leads (unconverted leads)
    */
    @isTest
    public static void copyFromParentAccountToMasterLeads3(){
        String parentAccountName = 'Test Parent Account';
        Decimal TEST_BUSINESS_ID = 7678900.0;
        String TEST_TEAM_TYPE = 'Enterprise';
        String TEST_DECK_RANK = 'King';
        Decimal TEST_NTAM_SALES = 123456.00;
        User runUser = getTestRunUser();
        System.runAs(runUser){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
            parentAccount.Business_ID__c = TEST_BUSINESS_ID;
            parentAccount.Account_Type__c = TEST_TEAM_TYPE;
            parentAccount.Deck_Rank__c = TEST_DECK_RANK;
            parentAccount.Amount__c = TEST_NTAM_SALES;
            insert parentAccount;
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Type__c = 'Franchise';     //Based on custom metadata - this will be overwritten
            testLead.Deck_Rank__c = 'King';     //Based on custom metadata - this will not be overwritten
            testLead.Amount__c = 999999;        //Based on custom metadata - this will not be overwritten
            insert testLead;
            testLead.Business_Id__c = TEST_BUSINESS_ID;
            update testLead;
            Test.stopTest();
            Account testParentAccountFromDB = [SELECT Id, Business_Id__c, Account_Type__c, Deck_Rank__c, Amount__c FROM Account WHERE Id = :parentAccount.Id];
            Lead testLeadFromDB = [SELECT Id, Business_Id__c, Type__c, Deck_Rank__c, Amount__c FROM Lead WHERE Id = :testLead.Id];
            System.assertEquals(TEST_BUSINESS_ID, testLeadFromDB.Business_Id__c, 'Expected Business Id ' + TEST_BUSINESS_ID);
            System.assertEquals(TEST_TEAM_TYPE, testLeadFromDB.Type__c, 'Expected Team Type ' + TEST_TEAM_TYPE);
            System.assertEquals('King', testLeadFromDB.Deck_Rank__c, 'Expected Deck Rank ' + 'King');
            System.assertEquals(999999, testLeadFromDB.Amount__c, 'Expected nTam Sales ' + 999999);
        }
    }

    /**
    * @description BZAP-6347 Move Rollup and Lookup Helper to Trigger
    */
    public static testMethod void setAccountIdTest() {
        System.runAs(getTestRunUser()){
            List<Account> Accounts = TDdAccountFactory.createAccounts('Account ', 5);
            List<Lead> Leads = TDdLeadFactory.createLeads('Test Lead ', 5, 'Master Lead', false);
            List<Account> checkAccounts;
            List<Lead> checkLeads;
            Integer restaurantId = 5;
            for (Integer i = 1; i <= 5; i++) {
                Accounts[i-1].Restaurant_ID__c = '' +(restaurantId+i);
                Leads[i-1].Store_ID__c = '' +(restaurantId+i);
            }
            insert Accounts;
            checkAccounts = [SELECT Id, Name, Restaurant_ID__c FROM Account];
            Map<String, Id> AccountIDmap = new Map<String, Id>();
            for (Account a : checkAccounts) AccountIDmap.put(a.Restaurant_ID__c,a.Id);
            test.startTest();
            insert Leads;
            checkLeads = [SELECT Id, Account__c, Store_ID__c, Account__r.Restaurant_ID__c FROM Lead];
            for (Lead l: checkLeads) {
                system.assertEquals(l.Account__r.Restaurant_ID__c, l.Store_Id__c);
                system.assertEquals(AccountIdmap.get(l.Store_ID__c), l.Account__c);
                l.Store_ID__c = null;
            }
            update checkLeads;
            checkLeads = [SELECT Id, Account__c, Store_ID__c, Account__r.Restaurant_ID__c FROM Lead];
            Integer i = 6;
            for (Lead l: checkLeads) {
                system.assertEquals(null, l.Store_Id__c);
                system.assertNotEquals(null, l.Account__c);
                l.Store_ID__c = ''+i++;
            }
            update checkLeads;
            checkLeads = [SELECT Id, Account__c, Store_ID__c, Account__r.Restaurant_ID__c FROM Lead];
            for (Lead l: checkLeads) {
                system.assertEquals(l.Account__r.Restaurant_ID__c, l.Store_Id__c);
                system.assertEquals(AccountIdmap.get(l.Store_ID__c), l.Account__c);
            }
            test.stopTest();
        }
    }

    /**
    * @description BZAP-6347 Move Rollup and Lookup Helper to Trigger
    */
    public static testMethod void doAccountRollupsTest() {
        System.runAs(getTestRunUser()){
            List<Account> Accounts = [ SELECT Id, Highest_Lead_Deck_Dank__c, Average_of_Lead_nTam__c, Leads__c,
                                                    of_Leads_w_nTam__c, Restaurant_ID__c
                                        FROM Account
                                        WHERE Name like 'Account Rollup Test%'
                                    ];
            List<Lead> Leads = TDdLeadFactory.createLeads('Account Rollup Test Lead ', 2, 'Master Lead', false);
            List<Account> checkAccounts;
            List<Lead> checkLeads;
            for (Integer i = 1; i <= Accounts.size(); i++) {    // Associate a lead with each account
                Leads[i-1].Store_ID__c = '' +i;
            }

            Set<Id> AccountIds = new Set<Id>();
            for (Account a : Accounts) AccountIDs.add(a.Id);
            System.assertEquals(2,AccountIds.size());
            checkAccounts = [
                SELECT Id, Highest_Lead_Deck_Dank__c, Average_of_Lead_nTam__c, Leads__c, of_Leads_w_nTam__c, Restaurant_ID__c
                FROM Account
                WHERE Id IN :AccountIds
            ];
            System.assertEquals(2,checkAccounts.size());
            for (Account a : checkAccounts) {
                system.assertEquals(null, a.Highest_Lead_Deck_Dank__c);
                system.assertEquals(null, a.Average_of_Lead_nTam__c);
                system.assertEquals(null, a.Leads__c);
                system.assertEquals(null, a.of_Leads_w_nTam__c);
            }
            for (Integer i = 0; i < Leads.size(); i++) {
                Leads[i].Deck_Rank__c = 'Queen';                // A rank of 5
                Leads[i].Amount__c = 200.00;
                Leads[i].Parent_Account__c = Accounts[i].Id;
            }
            test.startTest();
            insert Leads;
            Test.getEventBus().deliver();
            Set<Id> LeadIds = new Set<Id>();
            for (Lead l : Leads) LeadIDs.add(l.Id);
            checkAccounts = [
                SELECT Id, Highest_Lead_Deck_Dank__c, Average_of_Lead_nTam__c, Leads__c, of_Leads_w_nTam__c, Restaurant_ID__c
                FROM Account
                WHERE Id IN :AccountIds
            ];
            system.debug('checkAccounts --> ' + checkAccounts);
            for (Account a : checkAccounts) {
                system.assertEquals(5, a.Highest_Lead_Deck_Dank__c, 'Account --> ' + a);
                system.assertEquals(200.00, a.Average_of_Lead_nTam__c, 'Account --> ' + a);
                system.assertEquals(1, a.Leads__c, 'Account --> ' + a);
                system.assertEquals(1, a.of_Leads_w_nTam__c, 'Account --> ' + a);
            }
            List<Lead> leadsToUpdate = new List<Lead>();
            for (Lead l : Leads) if (l.Store_ID__c == '2') {
                l.Amount__c = 500.00;
                l.Deck_Rank__c = 'Ace';     // A rank of 3
                leadsToUpdate.add(l);
            }
            system.debug('Updating: ' + leadsToUpdate);
            update leadsToUpdate;
            Test.getEventBus().deliver();
            test.stopTest();
            Test.getEventBus().deliver();
            checkAccounts = [
                SELECT Id, Highest_Lead_Deck_Dank__c, Average_of_Lead_nTam__c, Leads__c, of_Leads_w_nTam__c, Restaurant_ID__c
                FROM Account
                WHERE Id IN :AccountIds
            ];
            system.debug('checkAccounts --> ' + checkAccounts);
            for (Account a : checkAccounts) {
                if (a.Restaurant_ID__c == '1') {
                    system.assertEquals(5, a.Highest_Lead_Deck_Dank__c, 'Account --> ' + a);
                    system.assertEquals(200.00, a.Average_of_Lead_nTam__c, 'Account --> ' + a);
                    system.assertEquals(1, a.Leads__c, 'Account --> ' + a);
                    system.assertEquals(1, a.of_Leads_w_nTam__c, 'Account --> ' + a);
                }
                else {
                    system.assertEquals(3, a.Highest_Lead_Deck_Dank__c, 'Account --> ' + a);
                    system.assertEquals(500.00, a.Average_of_Lead_nTam__c, 'Account --> ' + a);
                    system.assertEquals(1, a.Leads__c, 'Account --> ' + a);
                    system.assertEquals(1, a.of_Leads_w_nTam__c, 'Account --> ' + a);
                }
            }
        }
    }

    /**
    * @description BZAP-6479 Concatenate SSMO UUID field on all lead merges
    */
    public static testMethod void concatenateLeadMergeTest() {
        System.runAs(getTestRunUser()){
            List<Lead> Leads = TDdLeadFactory.createLeads('Test Lead ', 2, 'Master Lead', false);
            Leads[0].SSMO_UUID__c = '1234';
            Leads[1].SSMO_UUID__c = '5678';
            insert leads;

            Test.startTest();

            Database.MergeResult results = Database.merge(Leads[0], Leads[1], false);

            Test.stopTest();

            Lead l = [select Id, SSMO_UUID__c from Lead where Id =: Leads[0].Id];
            System.assert(l.SSMO_UUID__c == '1234,5678');
        }
    }

    /**
    * @description BZAP-5647 Neverbounce API Integration
    */
    public static testMethod void markEmailChangeTest() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdNeverbounceTest.CDdNeverbounceValidMock());
            List<Lead> Leads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Leads[0].Email = 'test@test.com';
            insert leads;
            Lead l = [select Id, Email_Updated__c from Lead where Id =: Leads[0].Id];
            System.assert(l.Email_Updated__c == true);
            Test.stopTest();
        }
    }

    /**
    * @description BZAP-9861 Neverbounce Email Invalid
    */
    public static testMethod void neverbounceEmailInvalidTest() {
        System.runAs(getTestRunUser()){
            Test.startTest();

            List<Lead> Leads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Leads[0].Email = new List<String>(CDdLeadTriggerHelper.EMAILS_INVALID).get(0);
            insert leads;

            Lead l = [select Id, Email_Updated__c, Email_Verification_Status__c from Lead where Id =: Leads[0].Id];
            System.assert(l.Email_Updated__c == false);
            System.assert(l.Email_Verification_Status__c == CDdLeadTriggerHelper.EMAIL_VERIFICATION_STATUS_INVALID);

            Test.stopTest();
        }
    }

    @IsTest
    public static void testConcatenateMarketingUUID() {
        Lead newLead = new Lead(Id = '00Q1a000002p1qrEAA', Marketing_UUID__c = '1234567890');
        Lead oldLead = new Lead(Id = '00Q1a000002p1qrEAA', Marketing_UUID__c = '0987654321');
        Map<Id, Lead> oldMap = new Map<Id, Lead>();
        oldMap.put(oldLead.Id, oldLead);
        CDdLeadTriggerHelper.concatenateMarketingUUID(new List<Lead> { newLead }, oldMap);
        System.assertEquals('0987654321, 1234567890', newLead.Marketing_UUID__c);
    }

    /**
    * @description BZAP-11554
    */
    public static testMethod void testUpdateRecordTypeOnDriveLeadConversion(){

        System.runAs(getTestRunUser()){
            Test.startTest();
            CDdContactTriggerHelper.insertCampaign();
            List<Lead> Leads = TDdLeadFactory.createLeads('Test Lead ', 1, 'DoorDash Drive Leads', false);
            //Leads[0].Email = 'test@test.com';
            Leads[0].Deck_Rank__c = '';
            insert leads;
            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(Leads[0].id);
            LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);

            Database.LeadConvertResult lcr = Database.convertLead(lc);
            System.assert(lcr.isSuccess());
            Test.stopTest();
        }
    }

    @isTest
    static void testLeadPhoneBeforeInsert() {
        List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
        testLeads[0].Phone = '+64 55 44 3322';
        testLeads[0].Mobile_Phone__c = '+64 55 44 3322';
        testLeads[0].CountryCode = 'NZ';
        testLeads[0].Country = 'New Zealand';
        testLeads[0].State = 'Auckland';
        testLeads[0].PostalCode = '1234';
        Test.startTest();
        insert testLeads;
        Test.stopTest();
        Lead updatedLead = [SELECT Id, Phone, Mobile_Phone__c FROM Lead WHERE Id =: testLeads[0].Id];
        //System.assertEquals('+6455443322', updatedLead.Phone);
        System.assertEquals('+6455443322', updatedLead.Mobile_Phone__c);
    }
    /**
     * @description BZAP-12548
    */
    @isTest
    static void testHandleSpecialCharsOnLeadChange() {
        System.runAs (getTestRunUser()) {

            String address1 = 'Lautenschlagerstraße 25';
            String address2 = 'Gablenberger Hauptstraße 120';

            String updatedAddress1 = 'Lautenschlagerstr. 25';
            String updatedAddress2 = 'Gablenberger Hauptstr. 120';

            Test.startTest();

            Lead newLead = new Lead();
            newLead.LastName = 'newLead';
            newLead.Company = 'newLead';
            newLead.Status = 'Meeting Set';
            newLead.Street = address1;
            newLead.CountryCode ='DE';
            newLead.Language__c = 'German';

            Lead newLead2 = new Lead();
            newLead2.LastName = 'newLead2';
            newLead2.Company = 'newLead2';
            newLead2.Status = 'Meeting Set';
            newLead2.Street = address2;
            newLead2.CountryCode ='DE';
            newLead2.Language__c = 'German';

            List<Lead> leadList = new List<Lead>{newLead, newLead2};
            insert leadList;

            newLead.Street = updatedAddress1;
            newLead2.Street = updatedAddress2;
            update leadList;


            Test.stopTest();
            Map<Id,Lead> updatedLeads = new Map<Id,Lead>([SELECT Id, Street FROM Lead WHERE ID IN: leadList]);

            System.assertEquals(address1, updatedLeads.get(newLead.Id).Street);
            System.assertEquals(address2, updatedLeads.get(newLead2.Id).Street);
        }
    }

    /**
     * @description BZAP-13229
    */
    @isTest
    static void testPopulateLeadStage() {

        Id promoRecTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
        Campaign testCampaign = new Campaign(RecordTypeId = promoRecTypeId,isActive=true);
        testCampaign.Name = 'DDfBAcqMktg_'+System.today();
        testCampaign.Title__c = 'DDfBAcqMktg_'+System.today();
        insert testCampaign;

        List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 5, 'DoorDash for Business', false);
        testLeads[0].Status = 'Untouched';
        testLeads[1].Status = 'DM Found';
        testLeads[2].Status = 'Meeting Set';
        testLeads[3].Status = 'Unqualified';
        testLeads[4].Status = 'Converted Dupe';

        for(Lead leadRec:testLeads){
			leadRec.Primary_Campaign_Source__c = testCampaign.Id;
        	leadRec.Validation_Bypass__c = true;
        }

        Test.startTest();
        insert testLeads;
        Test.stopTest();
        Map<Id,Lead> updatedLeadsMap = new Map<Id,Lead>([SELECT Id,Status,Lead_Stage__c FROM Lead WHERE Id =: testLeads]);
        System.assertEquals('Marketing Qualified Lead', updatedLeadsMap.get(testLeads[0].Id).Lead_Stage__c);
        System.assertEquals('Sales Qualified Lead', updatedLeadsMap.get(testLeads[1].Id).Lead_Stage__c);
        System.assertEquals('Sales Accepted Lead', updatedLeadsMap.get(testLeads[2].Id).Lead_Stage__c);
        System.assertEquals('Disqualified', updatedLeadsMap.get(testLeads[3].Id).Lead_Stage__c);
        System.assertEquals(true, updatedLeadsMap.get(testLeads[4].Id).Lead_Stage__c == null);
    }

    /**
    * @description BZAP-14577 - Lead Sub status update to Reinbounding
    */
    @isTest
    public static void populateLeadSubStatusToReinboundingTest(){
        User runUser = getTestRunUser();
        System.runAs(runUser)
        {
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Last_Inbound_Date_Time__c = system.now();
            insert testLead;
            Test.startTest();

            testLead.Status = 'Not Interested - Cool Down';
            testLead.Last_Inbound_Date_Time__c = system.now().addDays(2);
            update testLead;
            System.assertEquals('Not Interested - Cool Down', testLead.Status);

            Test.stopTest();
        }
    }
    /**
     * @description BZAP-13021
    */
    @isTest
    static void testUpdateCampaignOnCFCLeads() {
        Test.startTest();
        List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'DoorDash for Business', false);
        testLeads[0].Lead_Platform__c = CDdSupportConstants.LEAD_PLATFORM_CAVIAR;
        insert testLeads;
        Campaign camp=new Campaign(Name='Test Campaign',IsActive=True,Title__c='Test Title');
        Insert camp;
        CampaignMember cmLead= New CampaignMember(CampaignId=camp.Id,LeadID=testLeads[0].id);
        Insert cmLead;
        Test.stopTest();

        List<CampaignMember> cm = [SELECT Id FROM CampaignMember WHERE LeadId =: testLeads[0].Id AND CampaignId =: camp.id];
        System.assertEquals(1, cm.size(), 'Campaign Member should have been inserted');
    }

    /**
     * @description BZAP-13021
    */
    @isTest
    static void testOutreachLeadCurrentSequence() {
        Test.startTest();
        List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'DoorDash for Business', false);
        testLeads[0].Lead_Platform__c = CDdSupportConstants.LEAD_PLATFORM_CAVIAR;
        testLeads[0].Name_of_Currently_Active_Sequence__c = '_INITIAL_ Smarketing: 0201-500 & No HC (On-Shore Sequence)';
        testLeads[0].ID_of_Currently_Active_Sequence__c = '2007';
        insert testLeads;
        Test.stopTest();

        List<Lead> l = [SELECT Initial_Sequence_Name__c FROM Lead WHERE Id =: testLeads[0].Id];
        System.assertEquals('_INITIAL_ Smarketing: 0201-500 & No HC (On-Shore Sequence)', l[0].Initial_Sequence_Name__c, 'Campaign Member should have been inserted');
    }
}