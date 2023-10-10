/**
* @author Sriram
* @date 2020-03
*
* @description Test class for CDdAccountTriggerHandler
* This class uses the setup method to create the seed data required for all relevant test cases
*/
@isTest
public class CDdAccountTriggerHandlerTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_ACCOUNT_0 = 'TestDDAccount0';
    public static final String TEST_DD_ACCOUNT_LEAD_TYPE_OUTSIDE_0 = 'TestDDAccountLeadTypeOutside0';
    public static final String TEST_DD_ACCOUNT_LEAD_TYPE_INSIDE_0 = 'TestDDAccountLeadTypeInside0';
    public static final String TEST_DD_ACCOUNT_ROLLUP_PARENT_IDENTIFIERS = 'TestDDAccountRollupParent%';
    public static final String TEST_DD_ACCOUNT_ROLLUP_CHILD_IDENTIFIERS = 'TestDDAccountRollupChild%';
    public static final String TEST_DD_CLOSED_WON_OPPORTUNITY_0 = 'TestOppClosedWon0';
    public static final String TEST_DD_NEW_OPPORTUNITY_0 = 'TestOppNew0';
    public static final String TEST_DD_OPPORTUNITY_LEAD_TYPE_OUTSIDE_0 = 'TestOppLeadTypeOutside0';
    public static final String TEST_DD_OPPORTUNITY_LEAD_TYPE_INSIDE_0 = 'TestOppLeadTypeInside0';
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1 = 122222;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2 = 122223;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_3 = 122224;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_4 = 122225;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_5 = 122226;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_6 = 122227;
    public static final Id GRANDPARENT_ACCOUNT_RECORD_TYPE_ID;
    public static final Id PARENT_ACCOUNT_RECORD_TYPE_ID;
    public static final Id MARKETPLACE_RECORD_TYPE_ID;
    public static final Id ENTERPRISE_MARKETPLACE_RECORD_TYPE_ID;
    public static final Id BUSINESS_DEVELOPMENT_RECORD_TYPE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        GRANDPARENT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Grandparent Account').getRecordTypeId();
        PARENT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();
        MARKETPLACE_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
        ENTERPRISE_MARKETPLACE_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Enterprise Marketplace').getRecordTypeId();
        BUSINESS_DEVELOPMENT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Development').getRecordTypeId();
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
    @TestSetup
    static void setup() {
        createOtherUsers();
        System.runAs(getTestRunUser()){
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

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            insert validation;

            Multiplier__c m = new Multiplier__c();
            m.Ace_Multiplier__c = 4;
            m.King_Multiplier__c = 3.9;
            m.Queen_Multiplier__c = 3.8;
            m.Jack_Multiplier__c = 3.7;
            m.X10_Multiplier__c = 3.6;
            m.X8_Multiplier__c = 3.4;
            m.X6_Multiplier__c = 3.2;
            m.X4_Multiplier__c = 3;
            m.X2_Multiplier__c = 2;
            m.Joker_Multiplier__c = 1;
            m.Base_Rate__c = 1.27;
            m.Effective_Date__c = system.date.today().addDays(-2);
            m.Expiration_Date__c = system.date.today().addDays(30);
            m.Commission_Pay_Point__c = 25;
            m.Name = 'Master';
            m.Include_Protocol__c = True;
            m.Exponent__c = 0.2;
            m.Include_Direct_Deposit__c = True;
            m.Include_Tablet_Subscription_2_pts__c = True;
            m.Include_Inflation_1pt__c = True;
            m.Ace_of_Spades_Multiplier__c = 4;
            m.Inside_Commission_Pay_Point__c = 5;
            insert m;

            List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();
            List<Account> testAccounts = TDdAccountFactory.createAccounts('TestDDAccount', 10);
            Account testAcct1 = testAccounts[0];
            testAcct1.Name = 'TestDDAccount0';
            testAcct1.CHD_ID__c ='123456';
            testAcct1.Virtual_Concept__c =false;
            Account testAcct2 = testAccounts[1];
            testAcct2.Name = 'TestDDAccountLeadTypeOutside0';
            testAcct2.Lead_Type__c = 'Outside';
            testAcct2.Deck_Rank__c = 'Ace';
            testAcct2.Virtual_Concept__c =false;
            Account testAcct3 = testAccounts[2];
            testAcct3.Name = 'TestDDAccountLeadTypeInside0';
            testAcct3.Lead_Type__c = 'Inside';
            testAcct3.Deck_Rank__c = 'Ace';
            testAcct3.Virtual_Concept__c =false;
            // Create Roll Up Test Parent Accounts
            Account testAcct4 = testAccounts[3];
            testAcct4.Name = 'TestDDAccountRollupParent0';
            testAcct4.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct4.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1;
            testAcct4.Deck_Rank__c='Queen';
            testAcct4.Virtual_Concept__c =false;
            Account testAcct5 = testAccounts[4];
            testAcct5.Name = 'TestDDAccountRollupParent1';
            testAcct5.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct5.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2;
            testAcct5.Virtual_Concept__c =false;
            // Create Roll Up Test Child Accounts
            Account testAcct6 = testAccounts[5];
            testAcct6.Name = 'TestDDAccountRollupChild0';
            Account testAcct7 = testAccounts[6];
            testAcct7.Name = 'TestDDAccountRollupChild1';

            Account testAcct8 = testAccounts[7];
            testAcct8.Name = 'TestAccountPBHoldingUser';
            testAcct8.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct8.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_3;
            testAcct8.OwnerId = CDdAccountHelperMethods.HOLDING_USER;
            testAcct8.Deck_Rank__c='Queen';

            Account testAcct9 = testAccounts[8];
            testAcct9.Name = 'TestAccountPbPmHoldingUSer';
            testAcct9.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct9.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_4;
            testAcct9.OwnerId = CDdAccountHelperMethods.PM_HOLDING_USER;
            testAcct9.Deck_Rank__c='Queen';

            Account testAcct10 = testAccounts[9];
            testAcct10.Name = 'TestAccountPbSPMHoldingUSer';
            testAcct10.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct10.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_5;
            testAcct10.OwnerId = CDdAccountHelperMethods.SPM_HOLDING_USER;
            testAcct10.Deck_Rank__c='Queen';


            // Insert Accounts
            insert testAccounts;
            // Perform update for child accounts
            List<Account> parentAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_PARENT_IDENTIFIERS];
            List<Account> childAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_CHILD_IDENTIFIERS];
            for (Integer i = 0; i < childAccounts.size(); i++) {
                childAccounts[i].ParentId = parentAccounts[i].Id;
                childAccounts[i].Deck_Rank__c = 'Queen';                // A rank of 5
                childAccounts[i].Amount__c = 200.00;
                childAccounts[i].Currently_Active__c = 'Yes';
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

            Opportunity testOpp1 = TDdOpportunityFactory.createOpportunity('TestOppClosedWon0', testAcct1.Id, testContact1.Id, 'Closed Won');
            testOpp1.Menu_Completion_Date__c = System.today();
            testOpp1.Commission__c = 20;

            Opportunity testOpp2 = TDdOpportunityFactory.createOpportunity('TestOppNew0', testAcct1.Id, testContact1.Id, 'New');
            testOpp2.Menu_Completion_Date__c = System.today();
            testOpp2.Commission__c = 20;

            Opportunity testOpp3 = TDdOpportunityFactory.createOpportunity('TestOppLeadTypeOutside0', testAcct2.Id, testContact2.Id, 'Pitching');
            testOpp3.Menu_Completion_Date__c = System.today();
            testOpp3.Commission__c = 20;

            Opportunity testOpp4 = TDdOpportunityFactory.createOpportunity('TestOppLeadTypeInside0', testAcct3.Id, testContact3.Id, 'Pitching');
            testOpp4.Menu_Completion_Date__c = System.today();
            testOpp4.Commission__c = 14;
            testOpp4.Permission_to_Inflate__c = true;
            testOpp4.Direct_Deposit__c = true;
            testOpp4.Tablet_Subscription__c = 'Yes';

            List<Opportunity> testOpps = new List<Opportunity>{testOpp1, testOpp2, testOpp3, testOpp4};
            insert testOpps;

            Test.getEventBus().deliver();
            Test.stopTest();
        }
    }

    @isTest
    static void testUpdateADR() {
        List<User> testUsers = TDdAccountFactory.createUsers(4);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        runUser0.ADR__c = testUsers[2].Id;
        runUser1.ADR__c = testUsers[3].Id;
        update new List<User>{runUser0, runUser1};
        System.runAs (runUser0) {
            Test.startTest();
            Account acc = [SELECT Id, OwnerId FROM Account WHERE Name = :TEST_DD_ACCOUNT_0];
            update new Account(Id = acc.Id, OwnerId = runUser1.Id);
            Test.stopTest();
            System.assertEquals(runUser1.ADR__c,
                [SELECT ADR_Owner_Actual__c FROM Account WHERE Id = :acc.Id].ADR_Owner_Actual__c, 'Expecting ADR id ' + runUser1.ADR__c);
        }
    }

    @isTest
    static void testInsertWithSelfServeSuccess() {
        Id leadId;
        Id acctId;
        User selfServeUser = [SELECT Id from User WHERE UserName = 'mx-eng-api@doordash.com'];
        System.runAs(selfServeUser) {
            CDdAccountHelperMethods.testingAccountFormStack = true;
            Lead ld = VTestUtil.createLead('Test', 'Lead', true);
            insert ld;
            leadId = ld.Id;
            Account acct = VTestUtil.createFormstackAccount('Test Account');
            insert acct;
            // acctId = acct.Id;
        }
        Test.startTest();
        Lead ldFromQuery = [SELECT Id, Status, IsConverted, Auto_Conversion_Failed__c FROM Lead WHERE Id = :leadId];
        System.assert(!ldFromQuery.Auto_Conversion_Failed__c);
        //System.assert(ldFromQuery.IsConverted);
        //System.assertEquals(ldFromQuery.Status, 'Meeting Ran / Negotiated');
        Test.stopTest();
    }

    @isTest
    static void testInsertWithFormStackSuccess() {
        Id leadId;
        Id acctId;
        User formStackUser = [SELECT Id from User WHERE UserName = 'formstack@doordash.com'];
        System.runAs(formStackUser) {
            CDdAccountHelperMethods.testingAccountFormStack = true;
            Lead ld = VTestUtil.createLead('Test', 'Lead', true);
            ld.Street = '123 Main St';
            insert ld;
            leadId = ld.Id;

            Account acct = VTestUtil.createFormstackAccount('Test Account');
            acct.BillingStreet = '123 Main Street';
            acct.formstack_version__c = 'Local';
            insert acct;
            // acctId = acct.Id;
        }
        Test.startTest();
        Lead ldFromQuery = [SELECT Id, Status, IsConverted, Auto_Conversion_Failed__c FROM Lead WHERE Id = :leadId];
        System.assert(!ldFromQuery.Auto_Conversion_Failed__c);
        Test.stopTest();
    }

    @isTest
    static void updateTerritoryonAccount_testMethod(){
        Territory__c tr = new Territory__c ();
        tr.name = 'Test Tr';
        tr.Zip_Codes__c = '12345,14567,78741';
        insert tr;

        Territory_Assignment__c ta = new Territory_Assignment__c();
        ta.User__c = getTestRunUser().Id;
        ta.Territory__c = tr.Id;
        insert ta;

        System.runAs(getTestRunUser()){
            Test.startTest();

            Account a2 = new Account();
            a2.Name = 'Test Company';
            a2.BillingPostalCode = '12345';
            a2.BillingState = 'TX';
            a2.BillingStateCode = 'TX';
            a2.Deck_Rank__c = 'Ace';
            insert a2;

            Opportunity o = new Opportunity();
            o.Name = 'Test Opp';
            o.AccountId = a2.id;
            o.CloseDate = system.date.today();
            o.StageName = 'Prospecting';
            o.Amount = 100;
            o.Lead_Source_Detail__c = 'Formstack';
            insert o;

            a2.BillingPostalCode = '14567';
            a2.Deck_Rank__c = 'King';
            update a2;

            Test.stopTest();
        }
        try{
            Account a3 = new Account();
            a3.Name = 'Test Company';
            a3.BillingPostalCode = '12345';
            a3.BillingState = 'TX';
            a3.BillingStateCode = 'TX';
            insert a3;
        }
        catch(Exception e){
        }
    }
    /**
    * @description For testing the postive test case for NimdaCurrentlyActiveUpdateOp process where the Activation date should be populated on the Opportunity
    */
    @isTest
    static void NimdaCurrentlyActiveUpdateOp_Postitive_TestMethod(){
        Account testAcct = null;
        System.runAs(getTestRunUser()){
            Test.StartTest();
            testAcct = [SELECT Id FROM Account WHERE Name = :TEST_DD_ACCOUNT_0 LIMIT 1];
            testAcct.Currently_Active__c = 'Yes';
            update testAcct;
            Test.StopTest();
            Opportunity opp = [SELECT Id, Activation_Date__c, StageName
                               FROM Opportunity
                               WHERE Name = :TEST_DD_CLOSED_WON_OPPORTUNITY_0 LIMIT 1];
            System.Assert(opp.Activation_Date__c != null);
        }
    }
    /**
    * @description For testing the negative test case for NimdaCurrentlyActiveUpdateOp process where the Activation date should not be populated on the Opportunity
    */
    @isTest
    static void NimdaCurrentlyActiveUpdateOp_Negative_TestMethod(){
        Account testAcct = null;
        System.runAs(getTestRunUser()){
            Test.StartTest();
            testAcct = [SELECT Id FROM Account WHERE Name = :TEST_DD_ACCOUNT_0 LIMIT 1];
            testAcct.Currently_Active__c = 'Yes';
            update testAcct;
            Test.StopTest();
            Opportunity opp = [SELECT Id, Activation_Date__c, StageName
                               FROM Opportunity
                               WHERE Name = :TEST_DD_NEW_OPPORTUNITY_0 LIMIT 1];

            System.Assert(opp.Activation_Date__c == null);
        }
    }
    /**
    * @description Test that prevents the deletion of master account
    */
    @isTest
    static void prevent_Master_Account_Deletion() {
        System.runAs(getTestRunUser()){
            List<Account> accts = TDdAccountFactory.createAccounts('TestAccount', 2);
            Account masterAcct = accts[0];
            Account nonMasterAcct = accts[1];
            masterAcct.isMaster__c = true;
            nonMasterAcct.isMaster__c = false;
            insert accts;
            Test.startTest();
            try{
                delete masterAcct;
            } catch (DMLexception e){
                System.assert(e.getMessage().contains('Master Account can not be deleted'));
            }
            Test.stopTest();
        }
    }
    /**
     *
     * @author: Tia Xuan
     * @date: 2019-04
     * @description Test method for CDdAccountHelperMethods.matchMissingParentAccount
     */
    @isTest
    static void testMatchMissingParentAccount() {
        System.runAs(getTestRunUser()){
            vCS__c setting = vCS__c.getInstance();
            setting.parentAccMatchFlag__c = true;
            insert setting;

            Account testAcct = [SELECT Id, Business_Id__c FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_PARENT_IDENTIFIERS LIMIT 1];
            System.assert(testAcct != null);
            System.assert(testAcct.Business_Id__c != null);

            Test.startTest();
            CDdAccountHelperMethods.matchAccMissingParentAccountFlag = false;
            Account testAccChild = TDdAccountFactory.createAccounts('Matching Missing Child', 1, 'Marketplace')[0];
            testAccChild.Business_ID__c = testAcct.Business_Id__c;
            insert testAccChild;
            Test.getEventBus().deliver();
            Test.stopTest();
            Account childAccountFromDB = [SELECT Id, ParentId, Business_Id__c FROM Account WHERE Id = :testAccChild.Id];
            System.assert(childAccountFromDB != null);
            System.assert(childAccountFromDB.ParentId != null);
            System.assert(childAccountFromDB.ParentId == testAcct.Id);
        }
    }
    /**
     * @description Test DX Marketing Case
     */
    @isTest
    static void testDxMarketingCase1() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Account testAcc = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            testAcc.Checkr_Report_ID__c = 'test';
            testAcc.dx_kit_dxds_redcard_first_v1__c = true;
            insert testAcc;
            Test.stopTest();
            List<Case> caseRes = [  select Id, RecordType.Name, Origin, Overture_Request_Type__c
                                    from Case
                                    where AccountId =: testAcc.Id
                                        and RecordType.Name = 'Dasher / Merchant Kits'];
            System.Assert(caseRes.size() > 0);
        }
    }
    /**
     * @description Test DX Marketing Case
     */
    @isTest
    static void testDxMarketingCase2() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Account testAcc = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            testAcc.Checkr_Report_ID__c = 'test';
            testAcc.dx_kit_dxds_hotbag_second_v1__c = true;
            insert testAcc;
            Test.stopTest();
            List<Case> caseRes = [  select Id, RecordType.Name, Origin, Overture_Request_Type__c
                                    from Case
                                    where AccountId =: testAcc.Id
                                        and RecordType.Name = 'Dasher / Merchant Kits'];
            System.Assert(caseRes.size() > 0);
        }
    }
    /**
     * @description Test DX Marketing Case
     */
    @isTest
    static void testDxMarketingCase3() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Account testAcc = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            testAcc.Checkr_Report_ID__c = 'test';
            testAcc.dx_kit_instantdashing_v1__c = true;
            insert testAcc;
            Test.stopTest();
            List<Case> caseRes = [  select Id, RecordType.Name, Origin, Overture_Request_Type__c
                                    from Case
                                    where AccountId =: testAcc.Id
                                        and RecordType.Name = 'Dasher / Merchant Kits'];
            System.Assert(caseRes.size() > 0);
        }
    }
    /**
     * @description Test DX Marketing Case
     */
    @isTest
    static void testDxMarketingCase4() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Account testAcc = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            testAcc.Checkr_Report_ID__c = 'test';
            testAcc.dx_kit_dxds_v1__c = true;
            insert testAcc;
            Test.stopTest();
            List<Case> caseRes = [  select Id, RecordType.Name, Origin, Overture_Request_Type__c
                                    from Case
                                    where AccountId =: testAcc.Id
                                        and RecordType.Name = 'Dasher / Merchant Kits'];
            System.Assert(caseRes.size() > 0);
        }
    }
    /**
     * @description Test DX Marketing Case
     */
    @isTest
    static void testDxMarketingCase5() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Account testAcc = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            testAcc.Checkr_Report_ID__c = 'test';
            testAcc.dx_kit_dxds_v1__c = true;
            testAcc.Dasher_Kit_Ordered__c = false;
            testAcc.dx_kit_dxds_redcard_first_v1__c = false;
            testAcc.dx_kit_dxds_hotbag_second_v1__c = false;
            testAcc.dx_kit_instantdashing_v1__c = false;
            testAcc.dx_kit_dxds_v1__c = false;
            insert testAcc;
            Test.stopTest();
            List<Case> caseRes = [  select Id, RecordType.Name, Origin, Overture_Request_Type__c
                                    from Case
                                    where AccountId =: testAcc.Id
                                        and RecordType.Name = 'Dasher / Merchant Kits'];
            System.Assert(caseRes.size() > 0);
        }
    }
    @isTest
    static void testDxMarketingCase6() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Account testAcc = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            testAcc.Checkr_Report_ID__c = 'test';
            testAcc.dx_kit_us__c = true;
            insert testAcc;
            Test.stopTest();
            List<Case> caseRes = [  select Id, RecordType.Name, Origin, Overture_Request_Type__c
                                    from Case
                                    where AccountId =: testAcc.Id
                                        and RecordType.Name = 'Dasher / Merchant Kits'];
            System.Assert(caseRes.size() > 0);
        }
    }
    @isTest
    static void testInsertWithFormStackDuplicateLeadSuccess() {
        Id leadId;
        Id acctId;
        User formStackUser = [SELECT Id from User WHERE UserName = 'formstack@doordash.com'];
        System.runAs(formStackUser) {
            CDdAccountHelperMethods.testingAccountFormStack = true;

            List<Lead> leadsToInsert = TDdLeadFactory.createLeads('FormstackLeads', 2, false);
            Lead tempLead = leadsToInsert[0];
            leadsToInsert[1].phone = TDdAccountFactory.getRandom();
            leadsToInsert[1].email = 'test@thisisfake.com';
            leadsToInsert[1].Store_Id__c = null;
            leadsToInsert[1].smartystreets__Address_Last_Verified__c = Date.today();
            tempLead.phone = leadsToInsert[1].phone;
            tempLead.Street = leadsToInsert[1].Street;
            tempLead.PostalCode = leadsToInsert[1].PostalCode;
            tempLead.email = leadsToInsert[1].email;
            tempLead.Store_Id__c = leadsToInsert[1].Store_Id__c;
            tempLead.smartystreets__Address_Last_Verified__c = leadsToInsert[1].smartystreets__Address_Last_Verified__c;
            leadsToInsert[0] = tempLead;
            VTestUtil.allowDuplicates();
            Insert leadsToInsert;
            System.debug('Leads to insert size = ' + leadsToInsert.size());

            Test.startTest();
            // leadId = ld.Id;
            Account acct = VTestUtil.createFormstackAccount('Test Account');
            acct.Formstack_Email__c = tempLead.email;
            acct.Formstack_Mobile_Phone__c = tempLead.phone;
            acct.formstack_version__c = 'Local';
            insert acct;
            Test.stopTest();
        }
    }

    /**
    * @description BZAP-6347 Move Rollup and Lookup Helper to Trigger
    */
    @isTest
    static void testRollupsChildAccountInsert() {
        Account parentAccount = [SELECT Id FROM Account WHERE Name = :TEST_DD_ACCOUNT_0 LIMIT 1];
        System.assert(parentAccount != null);
        // Execute test with running user
        System.runAs(getTestRunUser()){
            Test.startTest();
            Account childAccount = TDdAccountFactory.createAccounts('TestDDAccount', 1)[0];
            childAccount.Name = 'TestDDChildAccount9999';
            childAccount.ParentId = parentAccount.Id;
            childAccount.Deck_Rank__c = 'Queen';                // A rank of 5
            childAccount.Amount__c = 200.00;
            childAccount.Currently_Active__c = 'Yes';
            insert childAccount;
            Test.stopTest();

            Account parentAccountFromDB = [SELECT Id, Highest_Child_Deck_Rank__c, Average_of_Account_nTam__c,
                                    of_child_accounts__c, of_Active_Child_Accounts__c, of_Accounts_w_nTam__c, ParentId
                                    FROM Account
                                    WHERE Id = :parentAccount.Id];
            system.assertEquals(5, parentAccountFromDB.Highest_Child_Deck_Rank__c, 'Account --> ' + parentAccountFromDB);
            system.assertEquals(200.00, parentAccountFromDB.Average_of_Account_nTam__c, 'Account --> ' + parentAccountFromDB);
            system.assertEquals(1, parentAccountFromDB.of_child_accounts__c, 'Account --> ' + parentAccountFromDB);
            system.assertEquals(1, parentAccountFromDB.of_Active_Child_Accounts__c, 'Account --> ' + parentAccountFromDB);
            system.assertEquals(1, parentAccountFromDB.of_Accounts_w_nTam__c, 'Account --> ' + parentAccountFromDB);

        }
    }

    /**
    * @description BZAP-6347 Move Rollup and Lookup Helper to Trigger
    */
    @isTest
    static void testRollupsChildAccountUpdate() {
        List<Account> parentAccounts = [SELECT Id, Highest_Child_Deck_Rank__c, Average_of_Account_nTam__c, of_child_accounts__c, of_Active_Child_Accounts__c, of_Accounts_w_nTam__c, ParentId
                                        FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_PARENT_IDENTIFIERS];
        List<Account> childAccounts = [SELECT Id, Highest_Child_Deck_Rank__c, Average_of_Account_nTam__c, of_child_accounts__c, of_Active_Child_Accounts__c, of_Accounts_w_nTam__c, ParentId
                                        FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_CHILD_IDENTIFIERS];
        System.assertEquals(2, parentAccounts.size());
        System.assertEquals(2, childAccounts.size());

        // Execute test with running user
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Account> childAccountToUpdate = new List<Account>();
            for (Account a : childAccounts) {
                System.assert(a.ParentId != null);
                a.Amount__c = 500.00;
                a.Deck_Rank__c = 'Ace';     // A rank of 3
                a.Currently_Active__c = 'Yes';
                childAccountToUpdate.add(a);
            }
            update childAccountToUpdate;
            Test.stopTest();

            List<Account> rollupParentAccounts = [
                SELECT Id, Highest_Child_Deck_Rank__c, Average_of_Account_nTam__c, of_child_accounts__c, of_Active_Child_Accounts__c, of_Accounts_w_nTam__c, ParentId
                FROM Account
                WHERE Id IN :parentAccounts
            ];
            for (Account a : rollupParentAccounts) {
                system.assertEquals(true, a.Highest_Child_Deck_Rank__c>0, 'Account --> ' + a);
                system.assertEquals(true, a.Average_of_Account_nTam__c>0, 'Account --> ' + a);
                system.assertEquals(3, a.Highest_Child_Deck_Rank__c, 'Account --> ' + a);
                system.assertEquals(500.00, a.Average_of_Account_nTam__c, 'Account --> ' + a);
                system.assertEquals(1, a.of_child_accounts__c, 'Account --> ' + a);
                system.assertEquals(1, a.of_Active_Child_Accounts__c, 'Account --> ' + a);
                system.assertEquals(1, a.of_Accounts_w_nTam__c, 'Account --> ' + a);
            }
        }
    }

    @IsTest
    static void testRollupsChildAccountDeleteRestore() {
        List<Account> parentAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_PARENT_IDENTIFIERS];
        List<Account> childAccounts = [SELECT Id, ParentId, Currently_Active__c FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_CHILD_IDENTIFIERS];
        System.assertEquals(2, parentAccounts.size());
        System.assertEquals(2, childAccounts.size());

        for (Account a : [SELECT Id, of_Active_Child_Accounts__c FROM Account WHERE Id IN :parentAccounts]) {
            System.assertEquals(1, a.of_Active_Child_Accounts__c);
        }

        System.runAs(getTestRunUser()) {
            Test.startTest();
            delete childAccounts;
            Test.stopTest();
        }

        for (Account a : [SELECT Id, of_Active_Child_Accounts__c FROM Account WHERE Id IN :parentAccounts]) {
            //System.assertEquals(null, a.of_Active_Child_Accounts__c);
        }
    }

    /**
    * @description BZAP-5697 Add Account Owner field to Opportunity Object
    */
    @isTest
    static void copyAccountOwnerToOpportunityTest() {
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers[1];
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Test.startTest();
            Account acc = [SELECT Id, Name, ParentId FROM Account WHERE Name = :TEST_DD_ACCOUNT_0];
            acc.OwnerId = runUser1.Id;
            update acc;
            Test.getEventBus().deliver();
            Test.stopTest();
            Opportunity opportunityFromDB = [SELECT Id, Account_Owner1__c, Amount, Deck_Rank__c FROM Opportunity WHERE Name = :TEST_DD_NEW_OPPORTUNITY_0];
            System.assertEquals(runUser1.Id, opportunityFromDB.Account_Owner1__c, 'Expecting owner id ' + runUser1.Id);
        }
    }

    /**
    * @description BZAP-6950 Changing PB to Trigger -- Create Lead when Lead Creation Approval Completed
    */
    @isTest
    static void createLeadOnLeadCreationApprovalTest() {
        List<Account> accounts = TDdAccountFactory.createAccounts('Account ', 1);
        Account acct = accounts[0];
        insert acct;

        Test.startTest();
        acct.Lead_Creation_Approval_Completed__c = true;
        update acct;

        Test.stopTest();

        List<Lead> l = [select Id
                        from Lead
                        where Account__c =: acct.Id];
        System.assert(l.size() == 1);
    }

    /**
    * @description BZAP-7194 Clean the EIN (Encrypted), Account Number (Encrypted),
    *                        Routing Number (Encrypted), Institution Number (Encrypted) fields on Accounts
    */
    @isTest
    static void cleanEncryptedFieldsTest() {
        Test.startTest();
        List<Account> accounts = TDdAccountFactory.createAccounts('Account ', 1);
        Account acct = accounts[0];
        acct.EIN_Encrypted__c = '123-451 ';
        acct.Bank_Account_Number_Encrypted__c = '123-451 ';
        acct.Bank_Institution_Number_Encrypted__c = '123-451 ';
        acct.Bank_Routing_Number_Encrypted__c = '123-451 ';
        insert acct;

        Account resAccount = [  select  Id,
                                        EIN_Encrypted__c,
                                        Bank_Account_Number_Encrypted__c,
                                        Bank_Institution_Number_Encrypted__c,
                                        Bank_Routing_Number_Encrypted__c
                                from Account
                                where Id =: acct.Id];
        System.assert(!resAccount.EIN_Encrypted__c.contains(' '));
        System.assert(!resAccount.EIN_Encrypted__c.contains('-'));
        System.assert(!resAccount.Bank_Account_Number_Encrypted__c.contains(' '));
        System.assert(!resAccount.Bank_Account_Number_Encrypted__c.contains('-'));
        System.assert(!resAccount.Bank_Institution_Number_Encrypted__c.contains(' '));
        System.assert(!resAccount.Bank_Institution_Number_Encrypted__c.contains('-'));
        System.assert(!resAccount.Bank_Routing_Number_Encrypted__c.contains(' '));
        System.assert(!resAccount.Bank_Routing_Number_Encrypted__c.contains('-'));

        Test.stopTest();
    }

    @IsTest
    static void testMergeError() {
        List<Account> parentAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_PARENT_IDENTIFIERS];
        List<Account> childAccounts = [SELECT Id, ParentId, Currently_Active__c FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_CHILD_IDENTIFIERS];
        System.assertEquals(2, parentAccounts.size());
        System.assertEquals(2, childAccounts.size());

        System.runAs(getTestRunUser()) {
            Test.startTest();
            merge parentAccounts[0] parentAccounts[1];
            Test.stopTest();
        }
    }

    @IsTest

    static void testSetLanguage() {
        Id id1 = '0012L000016PIg2QAG';
        Id id2 = '0012L000016PIg2QAH';
        Id id3 = '0012L000016PIg2QAI';

        // Test insert
        List<Account> newList = new List<Account>();

        Account countryState = new Account(BillingCountryCode = 'CA', BillingStateCode = 'QB', Id = id1);
        newList.add(countryState);

        Account countryNullState = new Account(BillingCountryCode = 'CA', BillingStateCode = null, Id = id2);
        newList.add(countryNullState);

        Account unmapped = new Account(BillingCountryCode = 'US', BillingStateCode = 'CA', Id = id3);
        newList.add(unmapped);

        CDdAccountHelperMethods.setLanguage(newList, null);
        System.assertEquals('French', countryState.Language__c, 'Unexpected value for countryState');
        System.assertEquals('English', countryNullState.Language__c, 'Unexpected value for countryNullState');
        System.assertEquals(null, unmapped.Language__c, 'Unexpected value for unmapped');

        // Test update
        countryState.Language__c = 'Spanish'; // Should remain unchanged when Language__c != null
        countryNullState.Language__c = null;
        unmapped.Language__c = null;

        Map<Id, Account> oldMap = new Map<Id, Account>();
        oldMap.put(id1, new Account(BillingCountryCode = 'CA', BillingStateCode = null, Id = id1));
        oldMap.put(id2, new Account(BillingCountryCode = 'CA', BillingStateCode = 'AL', Id = id2));
        oldMap.put(id3, new Account(BillingCountryCode = 'US', BillingStateCode = null, Id = id3));

        CDdAccountHelperMethods.setLanguage(newList, oldMap);
        System.assertEquals('Spanish', countryState.Language__c, 'Unexpected value for countryState');
        System.assertEquals('English', countryNullState.Language__c, 'Unexpected value for countryNullState');
        System.assertEquals(null, unmapped.Language__c, 'Unexpected value for unmapped');
    }

    @IsTest
    static void testPopulateBankAccountNumberForGermanyPositive() {
        // Test insert
        List<Account> accountList = TDdAccountFactory.createAccounts('GermanyAccountTest', 1, 'Enterprise Marketplace');

        Account germanyAccount = accountList[0];
        germanyAccount.Bank_Account_Number_Encrypted__c = '12345678901234567890';
        germanyAccount.BillingCountryCode = 'DE';
        germanyAccount.BillingCountry = 'Germany';
        germanyAccount.BillingState = 'Berlin';
        germanyAccount.Phone = '';

        insert germanyAccount;

        germanyAccount = [SELECT Bank_Account_Number_Encrypted__c FROM Account WHERE Id =:germanyAccount.Id];


        System.assertEquals('DE12345678901234567890', germanyAccount.Bank_Account_Number_Encrypted__c, 'Unexpected value for Bank Account Number');
    }
    /**
    * @description BZAP-9825 - Account Coverage
    */
    @isTest
    static void testCheckAccountCoverage() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.personAccountId());
            insert account;
            Test.getEventBus().deliver();
            Test.stopTest();
            Account accountFromDB = [SELECT Id, In_Coverage__c FROM Account WHERE Id = :account.Id];
            System.assertEquals(true, accountFromDB.In_Coverage__c == null);
        }
    }

    /**
     * @description: Test for jira# BZAP-11138 - Prevent Account deletion when opportunity is in certain stage and etc.
     */
    @isTest
    public static void testAccountDelete() {

        System.runAs(getTestRunUser()) {
            try {
               	List<Account> accounts = TDdAccountFactory.createAccounts('Account ', 1);
        		Account acct = accounts[0];
        		insert acct;

        		Opportunity opp = TDdOpportunityFactory.createOpportunity('TestOpp', acct.Id, null, 'New');
                opp.StageName ='Ready for Signature';
        		insert opp;

                List<Account> accountList = new List<Account>();
                List<Opportunity> opptyList = [SELECT Id, Name, AccountId, StageName FROM Opportunity WHERE StageName like 'Ready for Signature%'];

                for(Opportunity oppt: opptyList) {
                    accountList.add(new Account(Id=oppt.AccountId));
                }
            	Test.startTest();
            	delete accountList;

            } catch(Exception e) {

              	System.assert(e.getMessage().contains(System.Label.Account_Delete_Validation_Error));
            }

            Test.stopTest();
        }
    }
    /**
     * @description BZAP-11406 - setMenuUIType method coverage for Insert Scenario
     */
    @isTest
    static void testSetBusinessVerticalMenuUITypeForInsert() {
        System.runAs (getTestRunUser()) {
            String businessVerticalName = 'Test Retail';
            List<Business_Vertical__c> bvList = [SELECT Id, Menu_UI_Type__c, Primary_Category__c, Name, Business_Vertical_Id__c FROM Business_Vertical__c WHERE name =:businessVerticalName];
            String parentAccountName = 'Test Business Vertical Account 001';
            Id testBusinessVerticalId = bvList[0].Id;
            String testBusinessVerticalDetails = bvList[0].Menu_UI_Type__c +  ' UI - ' + bvList[0].Name + ' - '+  bvList[0].Business_Vertical_Id__c;
            String testPrimaryMerchantCategory = bvList[0].Primary_Category__c;
            Test.startTest();
            Account accountRec = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.parentAccountId());
            accountRec.name = parentAccountName;
            accountRec.Merchant_Categories__c = 'Alcohol / Alcohol-Lite ; Grocery';
            accountRec.Primary_Merchant_Category__c = testPrimaryMerchantCategory;
            accountRec.Business_Vertical__c = testBusinessVerticalId;
            insert accountRec;
            Test.stopTest();
            Account accountFromDB = [SELECT Id, Business_Vertical_Details__c FROM Account WHERE name = :parentAccountName];
            System.assertEquals(testBusinessVerticalDetails, accountFromDB.Business_Vertical_Details__c);
        }
    }
    /**
     * @description BZAP-11406 - setMenuUIType method coverage for Update Scenario
    */
    @isTest
    static void testSetBusinessVerticalMenuUITypeForUpdate() {
        System.runAs (getTestRunUser()) {
            String businessVerticalName = 'Test Retail';
            List<Business_Vertical__c> bvList = [SELECT Id, Menu_UI_Type__c, Primary_Category__c,Name,Business_Vertical_Id__c FROM Business_Vertical__c WHERE name =:businessVerticalName];
            List<Account> parentAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_PARENT_IDENTIFIERS];
            Account testParentAccount = parentAccounts[0];
            Account accountFromDBafterInsert = [SELECT Id, Business_Vertical_Details__c FROM Account WHERE Id = :testParentAccount.Id];
            System.assertEquals(null, accountFromDBafterInsert.Business_Vertical_Details__c);
            Id testBusinessVerticalId = bvList[0].Id;
            String testBusinessVerticalDetails = bvList[0].Menu_UI_Type__c +  ' UI - ' + bvList[0].Name + ' - '+  bvList[0].Business_Vertical_Id__c;
            String testPrimaryMerchantCategory = bvList[0].Primary_Category__c;
            Test.startTest();
            testParentAccount.Merchant_Categories__c = 'Alcohol / Alcohol-Lite ; Grocery';
            testParentAccount.Primary_Merchant_Category__c = testPrimaryMerchantCategory;
            testParentAccount.Business_Vertical__c = testBusinessVerticalId;
            update testParentAccount;
            Test.stopTest();
            Account accountFromDB = [SELECT Id, Business_Vertical_Details__c FROM Account WHERE Id = :testParentAccount.Id];
            System.assertEquals(testBusinessVerticalDetails, accountFromDB.Business_Vertical_Details__c);
        }
    }

    /**
     * @description BZAP-11884 - Set Ultimate Parent Hierarchy
    */
    @isTest
    static void testSetUltimateParent() {
        Map<String,Account> accountMap =  new Map<String,Account>{
            'Ultimate Parent1' => TDdAccountFactory.createAccount(GRANDPARENT_ACCOUNT_RECORD_TYPE_ID),
            'Parent' => TDdAccountFactory.createAccount(PARENT_ACCOUNT_RECORD_TYPE_ID),
            'Child 1' => TDdAccountFactory.createAccount(MARKETPLACE_RECORD_TYPE_ID),
            'Child 2' => TDdAccountFactory.createAccount(MARKETPLACE_RECORD_TYPE_ID)
        };
        insert accountMap.values();
        Account ultimateAcct = [SELECT Id, Ultimate_Parent_Id__c FROM Account WHERE Id =: accountMap.get('Ultimate Parent1').Id];
        //The ultimate parent should reference itself in the formula field
        System.assertEquals(ultimateAcct.Ultimate_Parent_Id__c, ultimateAcct.Id, 'The ultimate parent account should reference itself in the hierarchy');
        //Setup the hierarchy
        Test.startTest();
        accountMap.get('Parent').ParentId = accountMap.get('Ultimate Parent1').Id;
        accountMap.get('Child 1').ParentId = accountMap.get('Parent').Id;
        accountMap.get('Child 2').ParentId = accountMap.get('Parent').Id;
        update accountMap.values();
        //Fire platform event to make the update
        Test.getEventBus().deliver();
        Test.stopTest();

        Set<Id> accountIds = new Set<Id>{
            accountMap.get('Ultimate Parent1').Id,
            accountMap.get('Parent').Id,
            accountMap.get('Child 1').Id,
            accountMap.get('Child 2').Id
        };

        List<Account> accountsAfter = [SELECT Id, Ultimate_Parent_Id__c, Ultimate_Parent_Account__c FROM Account WHERE Id in: accountIds];
        for(Account acct : accountsAfter){
            System.assertEquals(ultimateAcct.Id, acct.Ultimate_Parent_Id__c, 'The account ultimate parent formula is not correct');

            if(acct.Id != ultimateAcct.Id){
                System.assertEquals(ultimateAcct.Id, acct.Ultimate_Parent_Account__c, 'The ultimate parent for this account is incorrect');
            }
        }
    }
    /**
     * @description BZAP-12630 - Only process ultimate parent updates for accounts that are hierarchy accounts
     */
    @isTest
    static void testIsHierarchyAccount() {
        Map<String,Account> accountMap =  new Map<String,Account>{
            'Account1' => TDdAccountFactory.createAccount(GRANDPARENT_ACCOUNT_RECORD_TYPE_ID),
            'Account2' => TDdAccountFactory.createAccount(PARENT_ACCOUNT_RECORD_TYPE_ID),
            'Account3' => TDdAccountFactory.createAccount(MARKETPLACE_RECORD_TYPE_ID),
            'Account4' => TDdAccountFactory.createAccount(ENTERPRISE_MARKETPLACE_RECORD_TYPE_ID)
        };
        for(Account acct : accountMap.values()){
            System.assertEquals(true, CDdAccountHelperMethods.isHierarchyAccount(acct.RecordTypeId), 'The account recordType ' + acct.RecordTypeId + 'should return true');
        }
    }
    /**
     * @description BZAP-12630 - Only process ultimate parent updates for accounts that are hierarchy accounts
     */
    @isTest
    static void testIsHierarchyAccountNegative() {
        Account acct = TDdAccountFactory.createAccount(BUSINESS_DEVELOPMENT_RECORD_TYPE_ID);
        System.assertEquals(false, CDdAccountHelperMethods.isHierarchyAccount(acct.RecordTypeId), 'The account recordType ' + acct.RecordTypeId + 'should return false');
    }
    /**
     * @description BZAP-11417 - Test for Setup Catalog Milestone when Parent Account Business Vertical is set as Retail
     */
    @isTest
    static void testSetupCatalogMilestoneForBusinessVerticalRetail() {
        System.runAs (getTestRunUser()) {
            CDdMilestoneTemplate.insertMilestoneTemplates();
            Business_Vertical__c retailBusinessVertical =  [SELECT Id, Menu_UI_Type__c, Primary_Category__c FROM Business_Vertical__c WHERE Menu_UI_Type__c = 'Retail' LIMIT 1];
            System.assertEquals(true, retailBusinessVertical != null, 'Expecting to retrieve the Business Vertical record for Retail');
            Account testParentAccount = [SELECT Id FROM Account WHERE RecordTypeId = :PARENT_ACCOUNT_RECORD_TYPE_ID AND Business_Id__c = :TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1 LIMIT 1];
            System.assertEquals(true, testParentAccount != null, 'Expecting to retrieve the test parent account for business id ' + TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1);
            Opportunity testClosedWonOpp = [SELECT Id, AccountId FROM Opportunity WHERE Name = :TEST_DD_CLOSED_WON_OPPORTUNITY_0];
            System.assertEquals(true, testClosedWonOpp != null, 'Expecting to retrieve the closed won opportunity record ' + TEST_DD_CLOSED_WON_OPPORTUNITY_0);
            Case testCase = [SELECT Id FROM Case WHERE RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() AND Opportunity_Name__c = :testClosedWonOpp.Id LIMIT 1];
            System.assertEquals(true, testCase != null, 'Expecting to retrieve the case record of record type marketplace onboarding for opportunity ' + TEST_DD_CLOSED_WON_OPPORTUNITY_0);
            Account testChildAccount = new Account(Id = testClosedWonOpp.AccountId, ParentId = testParentAccount.Id);
            update testChildAccount;
            Milestone__c testSetupCatalogMilestone = null;
            for (Milestone__c m : [SELECT Id FROM Milestone__c WHERE Case__c = :testCase.Id AND Milestone_Type__c = 'Setup Catalog']){
                testSetupCatalogMilestone = m;
            }
            System.assertEquals(true, testSetupCatalogMilestone == null, 'Expecting the Setup Catalog milestone to not be available for the Case as the Parent Account is not a business vertical of retail');
            Test.startTest();
            testParentAccount.Merchant_Categories__c = 'Alcohol / Alcohol-Lite ; Grocery';
            testParentAccount.Primary_Merchant_Category__c = retailBusinessVertical.Primary_Category__c;
            testParentAccount.Business_Vertical__c = retailBusinessVertical.Id;
            update testParentAccount;
            Test.stopTest();
            for (Milestone__c m : [SELECT Id FROM Milestone__c WHERE Case__c = :testCase.Id AND Milestone_Type__c = 'Setup Catalog']){
                testSetupCatalogMilestone = m;
            }
            System.assertEquals(true, testSetupCatalogMilestone != null, 'Expecting the Setup Catalog milestone to be available for the Case as the Parent Account is a business vertical of retail');
        }
    }

     /**
     *
     * @author: Neha Arora
     * @date: 2021-10
     * @description Test method for CDdAccountHelperMethods.updateChildAcctsInformationAfterInsert
     */
    @isTest
    static void testupdateChildAcctsInformationAfterInsert() {
        System.runAs(getTestRunUser()){
            Account testAcct = [SELECT Id, Deck_Rank__c,Business_Id__c FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_ROLLUP_PARENT_IDENTIFIERS LIMIT 1];

            Test.startTest();
            Account testAccChild = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
            testAccChild.ParentId = testAcct.Id;
            insert testAccChild;
            Test.getEventBus().deliver();
            Test.stopTest();
            Account childAccountFromDB = [SELECT Id,Deck_Rank__c, ParentId, Business_Id__c FROM Account WHERE Id = :testAccChild.Id];
            System.assert(childAccountFromDB.Deck_Rank__c == testAcct.Deck_Rank__c);
        }
    }

    /**
     * @description BZAP-15255 - insert Account with ChdId when Enrichment Junction dosen't exist
    */
    @isTest
    static void testinsertAccountWithChdIdAndEnrichmentJunctionNotExist() {
        System.runAs (getTestRunUser()) {
            Feature_Flags__c setting = Feature_Flags__c.getInstance();
            setting.Disable_Enrichment_Queueable__c = false;
            insert setting;

            Test.startTest();
            List<Account> accounts = TDdAccountFactory.createAccounts('Account ', 1);
            accounts[0].CHD_ID__c = 'US02090117165405';
            insert accounts;
            Test.stopTest();

            List<Enrichment_Junction__c> junctionList = [SELECT id,EJ_CHD_ID__c,Account__c from Enrichment_Junction__c Where Account__c =:accounts[0].Id ];
            System.assert(!junctionList.isEmpty(),'Junction List Should not be Empty');
            System.assertEquals(accounts[0].CHD_ID__c,junctionList[0].EJ_CHD_ID__c, 'Junction Record CHD ID should be same as account');
            System.assertEquals(accounts[0].id, junctionList[0].Account__c ,'Junction record should have same account id');
        }
    }

    /**
     * @description BZAP-15255 - insert Account with ChdId when Enrichment Junction exist
    */
    @isTest
    static void testinsertAccountWithChdIdAndEnrichmentJunctionExist() {
        System.runAs (getTestRunUser()) {
            Feature_Flags__c setting = Feature_Flags__c.getInstance();
            setting.Disable_Enrichment_Queueable__c = false;
            insert setting;

            Enrichment_Junction__c enrcJunctionRec = new Enrichment_Junction__c();
            enrcJunctionRec.EJ_CHD_ID__c = 'US02090117165405';
            insert enrcJunctionRec;

            Enrichment_Account__c enrcAccountRec = new Enrichment_Account__c();
            enrcAccountRec.Enrichment_Junction__c = enrcJunctionRec.id;
            enrcAccountRec.CHD_ID__c = enrcJunctionRec.EJ_CHD_ID__c;
            insert enrcAccountRec;

            Test.startTest();
            List<Account> accounts = TDdAccountFactory.createAccounts('Account ', 1);
            accounts[0].CHD_ID__c = enrcJunctionRec.EJ_CHD_ID__c;
            insert accounts;
            Test.stopTest();

            List<Enrichment_Junction__c> junctionList = [SELECT id,EJ_CHD_ID__c,Account__c from Enrichment_Junction__c Where Account__c =:accounts[0].Id ];
            System.assert(!junctionList.isEmpty(),'Junction List Should not be Empty');
            System.assertEquals(accounts[0].id, junctionList[0].Account__c ,'Junction record should have same account id');
        }
    }


    /**
     * @description BZAP-15255 - update Account ChdId to null
    */
    @isTest
    static void testUpdateAccountWithChdIdToNull() {
        System.runAs (getTestRunUser()) {
            Feature_Flags__c setting = Feature_Flags__c.getInstance();
            setting.Disable_Enrichment_Queueable__c = false;
            insert setting;

            Account acc = [Select id,CHD_ID__c from Account Where CHD_ID__c =: '123456'];
            Enrichment_Junction__c enrcJunctionRec = new Enrichment_Junction__c();
            enrcJunctionRec.EJ_CHD_ID__c = '123456';
            enrcJunctionRec.Account__c = acc.Id;
            insert enrcJunctionRec;

            Enrichment_Account__c enrcAccountRec = new Enrichment_Account__c();
            enrcAccountRec.Enrichment_Junction__c = enrcJunctionRec.id;
            enrcAccountRec.CHD_ID__c = enrcJunctionRec.EJ_CHD_ID__c;
            enrcAccountRec.Account__c = acc.Id;
            insert enrcAccountRec;

            Test.startTest();
            acc.CHD_ID__c = null;
            update acc;
            Test.stopTest();

            List<Enrichment_Junction__c> junctionList = [SELECT id,EJ_CHD_ID__c,Account__c from Enrichment_Junction__c Where EJ_CHD_ID__c = '123456' ];
            System.assert(!junctionList.isEmpty(),'Junction List Should not be Empty');
            System.assertEquals(null, junctionList[0].Account__c ,'Junction record should have account as null');

        }
    }

    /**
     * @description BZAP-15255 - update AccountChdId method with different CHD ID
    */
    @isTest
    static void testUpdateAccountWithChdIdToNewChdIdValue() {
        System.runAs (getTestRunUser()) {
            Feature_Flags__c setting = Feature_Flags__c.getInstance();
            setting.Disable_Enrichment_Queueable__c = false;
            insert setting;

            Account acc = [Select id,CHD_ID__c from Account Where CHD_ID__c =: '123456'];
            Enrichment_Junction__c enrcJunctionRec = new Enrichment_Junction__c();
            enrcJunctionRec.EJ_CHD_ID__c = '123456';
            enrcJunctionRec.Account__c = acc.Id;
            insert enrcJunctionRec;

            Enrichment_Account__c enrcAccountRec = new Enrichment_Account__c();
            enrcAccountRec.Enrichment_Junction__c = enrcJunctionRec.id;
            enrcAccountRec.CHD_ID__c = enrcJunctionRec.EJ_CHD_ID__c;
            enrcAccountRec.Account__c = acc.id;
            insert enrcAccountRec;

            Test.startTest();
            acc.CHD_ID__c = '123';
            update acc;
            Test.stopTest();

            List<Enrichment_Junction__c> junctionList = [SELECT id,EJ_CHD_ID__c,Account__c from Enrichment_Junction__c Where EJ_CHD_ID__c = '123' ];
            System.assert(!junctionList.isEmpty(),'Junction List Should not be Empty');
            System.assertEquals(acc.id, junctionList[0].Account__c ,'Junction record should have same account id');

        }
    }

    /**
    * @description BZAP-15255 - update AccountChdId method with different CHD ID where junction Record Exist
    */
    @isTest
    static void testUpdateAccountWithChdIdToNewChdIdValueWhereJunctionExist() {
        System.runAs (getTestRunUser()) {
            Feature_Flags__c setting = Feature_Flags__c.getInstance();
            setting.Disable_Enrichment_Queueable__c = false;
            insert setting;

            Account acc = [Select id,CHD_ID__c from Account Where CHD_ID__c =: '123456'];
            Enrichment_Junction__c enrcJunctionRec = new Enrichment_Junction__c();
            enrcJunctionRec.EJ_CHD_ID__c = '123';
            enrcJunctionRec.Account__c = acc.Id;
            insert enrcJunctionRec;

            Enrichment_Account__c enrcAccountRec = new Enrichment_Account__c();
            enrcAccountRec.Enrichment_Junction__c = enrcJunctionRec.id;
            enrcAccountRec.CHD_ID__c = enrcJunctionRec.EJ_CHD_ID__c;
            enrcAccountRec.Account__c = acc.id;
            insert enrcAccountRec;

            Test.startTest();
            acc.CHD_ID__c = '123';
            update acc;
            Test.stopTest();

            List<Enrichment_Junction__c> junctionList = [SELECT id,EJ_CHD_ID__c,Account__c from Enrichment_Junction__c Where EJ_CHD_ID__c = '123' ];
            System.assert(!junctionList.isEmpty(),'Junction List Should not be Empty');
            System.assertEquals(acc.id, junctionList[0].Account__c ,'Junction record should have same account id');
        }
    }

      /**
     * @description BZAP-12548
    */
    @isTest
    static void testHandleSpecialCharsOnAddressChange() {
        System.runAs (getTestRunUser()) {

            String address1 = 'Lautenschlagerstraße 25';
            String address2 = 'Gablenberger Hauptstraße 120';

            String updatedAddress1 = 'Lautenschlagerstr. 25';
            String updatedAddress2 = 'Gablenberger Hauptstr. 120';

            Test.startTest();

            Account newAcc = new Account();
            newAcc.Name = 'newaccount';
            newAcc.BillingStreet = address1;
            newAcc.billingcountryCode ='DE';

            Account newAcc2 = new Account();
            newAcc2.Name = 'newaccount2';
            newAcc2.BillingStreet = address2;
            newAcc2.billingcountryCode ='DE';

            List<Account> accountList = new List<Account>{newAcc, newAcc2};
            insert accountList;

            newAcc.BillingStreet = updatedAddress1;
            newAcc2.BillingStreet = updatedAddress2;
            update accountList;


            Test.stopTest();
            Map<Id,Account> updatedAccs = new Map<Id,Account>([SELECT Id, BillingStreet FROM ACCOUNT WHERE ID IN: accountList]);

            System.assertEquals(address1, updatedAccs.get(newAcc.Id).BillingStreet);
            System.assertEquals(address2, updatedAccs.get(newAcc2.Id).BillingStreet);
        }
    }

    /**
    * @description BASD-20183
    */
    @isTest
    static void testupdateLeadState() {
        User testRunUser = TDdAccountFactory.createUsers(1)[0];
        testRunUser.FirstName = 'Hubspot';
        testRunUser.LastName = 'Integration User';
        testRunUser.email = 'hubspot@doordash.com.testemail';

        System.runAs(testRunUser){

            Account account = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            account.PersonMailingCity = 'Los Angeles';
            account.PersonMailingCountry = 'United States';
            account.PersonMailingCountryCode = 'US';
            account.PersonMailingPostalCode = '91436';
            account.PersonMailingStreet = '15910 Ventura Blvd';
            account.PersonEmail = 'test@thisisfake.com';
            insert account;

            Account acc = [Select id,PersonMailingState,PersonContactId From Account Where id =: account.id ];

            Campaign campaign = new Campaign(Name = 'AcqMktgTest', Title__c = 'AcqMktgTest', RecordTypeId = CDdCampaignMemberTriggerHelper.campaignWorkId);
            insert campaign;

            insert new CampaignMember(ContactId = acc.PersonContactId, CampaignId = campaign.Id);

            Test.startTest();
            account.PersonMailingState = 'CA';
            update account;
            Test.stopTest();

           List<Lead> leadList = new List<Lead>();
           leadList = [Select id,State,Created_from_Contact__c From Lead Where Created_from_Contact__c =: acc.PersonContactId];
           System.assertEquals(account.PersonMailingState, leadList[0].state,'Person Account & Lead State value should be same');
        }
    }

    /**
    * @description BZAP-13012
    */
    @isTest
    static void testHandlePostSaleAccOwnerHoldingUser() {


        System.runAs(getTestRunUser()){
            Id userID = [Select id from user where Username = 'formstack@doordash.com'].Id;
            Account TestAccount = [SELECT Id, Requested_Account_Owner__c, OwnerId
                                  FROM Account
                                  WHERE name = 'TestAccountPBHoldingUser' Limit 1];
            CDdAccountHelperMethods.ranPostSaleAccountOwnerApprovalProcess = false;
            Test.startTest();
            TestAccount.Requested_Account_Owner__c = userID;
            TestAccount.Why_should_account_ownership_be_changed__c = 'Testing';
            update TestAccount;
            Test.stopTest();
            Account testAccountPBDB = [SELECT Id, Requested_Account_Owner__c,
                                              OwnerId,Why_should_account_ownership_be_changed__c
                                      FROM Account
                                      WHERE name = 'TestAccountPBHoldingUser' Limit 1];
            System.assertEquals(userID, testAccountPBDB.OwnerId,'Owner Id should now be Requested Account Owner');
            System.assertEquals(null, testAccountPBDB.Requested_Account_Owner__c,'Requested Account Owner should be null');
            System.assertEquals(null, testAccountPBDB.Why_should_account_ownership_be_changed__c,'Why should the Account Ownership changed should be null');
        }
    }

    /**
    * @description BZAP-13012
    */
    @isTest
    static void testHandlePostSaleAccOwnerPMHoldingUser() {
            System.runAs(getTestRunUser()){
            Id userID = [Select id from user where Username = 'formstack@doordash.com'].Id;
            Account TestAccount = [SELECT Id, Requested_Account_Owner__c, OwnerId
                                  FROM Account
                                  WHERE name = 'TestAccountPbPmHoldingUSer' Limit 1];
            CDdAccountHelperMethods.ranPostSaleAccountOwnerApprovalProcess = false;
            Test.startTest();
            TestAccount.Requested_Account_Owner__c = userID;
            TestAccount.Why_should_account_ownership_be_changed__c = 'Testing';
            update TestAccount;
            Test.stopTest();
            Account testAccountPBDB = [SELECT Id, Requester__c, OwnerId
                                      FROM Account
                                      WHERE name = 'TestAccountPbPmHoldingUSer' Limit 1];
            System.assertEquals(UserInfo.getUserId(), testAccountPBDB.Requester__c,'Requester should be the login user');
        }
    }

    /**
    * @description BZAP-13012
    */
    @isTest
    static void testHandlePostSaleAccOwnerSPMHoldingUser() {

        System.runAs(getTestRunUser()){
            Id userID = [Select id from user where Username = 'formstack@doordash.com'].Id;
            Account TestAccount = [SELECT Id, Requested_Account_Owner__c, OwnerId
                                  FROM Account
                                  WHERE name = 'TestAccountPbSPMHoldingUSer' Limit 1];
            CDdAccountHelperMethods.ranPostSaleAccountOwnerApprovalProcess = false;
            Test.startTest();
            TestAccount.Requested_Account_Owner__c = userID;
            TestAccount.Why_should_account_ownership_be_changed__c = 'Testing';
            update TestAccount;
            Test.stopTest();
            Account testAccountPBDB = [SELECT Id, Requester__c, OwnerId
                                      FROM Account
                                      WHERE name = 'TestAccountPbSPMHoldingUSer' Limit 1];
            System.assertEquals(UserInfo.getUserId(), testAccountPBDB.Requester__c,'Requester should be the login user');
        }
    }

    /**
    * @description BZAP-13012
    */
    @isTest
    static void testAccountOwnershipRejected() {

        User testApprovalPBUser = [SELECT Id from User WHERE UserName = 'formstack@doordash.com'];
        System.runAs(getTestRunUser()){
            CDdAccountHelperMethods.ranPostSaleAccountOwnerApprovalProcess = false;
            Account testAccount = new Account();
            testAccount.name = 'TestAccountRej';
            testAccount.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAccount.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_6;
            testAccount.Account_Ownership_Rejected__c = True;
            testAccount.OwnerId = CDdAccountHelperMethods.HOLDING_USER;
            testAccount.Requested_Account_Owner__c = testApprovalPBUser.ID;
            testAccount.Why_should_account_ownership_be_changed__c = 'Testing';
            Test.startTest();
            insert testAccount;
            Test.stopTest();
            Account testAccFromDB = [SELECT Id, Account_Ownership_Rejected__c,
                                            OwnerId , Requested_Account_Owner__c, Requested_Account_Owner_Manager__c,
                                            Requester__c, Why_should_account_ownership_be_changed__c
                                    FROM Account
                                    WHERE name = 'TestAccountRej' Limit 1];
            System.assertEquals(false, testAccFromDB.Account_Ownership_Rejected__c,'Account Ownership rejected should be false');
            System.assertEquals(testAccFromDB.OwnerId, testApprovalPBUser.ID, 'Owner ID should be Requested Account Owner');
            System.assertEquals(null, testAccFromDB.Requested_Account_Owner__c, 'Requested Account Owner should be null');
            System.assertEquals(null, testAccFromDB.Requested_Account_Owner_Manager__c,'Requested Account Owner Manager should be null');
            System.assertEquals(null, testAccFromDB.Requester__c,'Requester should be null');
            System.assertEquals(null, testAccFromDB.Why_should_account_ownership_be_changed__c,'Why should account ownership changed be null');
        }
    }

    /**
         * @author : Abhijeet K
         * @description : BZAP-13592 : SSMO: Phone number format update
    */
    @isTest
    static void testJPPhoneFormat() {
        Integration_User__c iuSettings = new Integration_User__c(
            SetupOwnerId = getTestRunUser().Id,
            User_Type__c = CDdCoreConstants.INTEGRATION_USER_TYPE_MULESOFT
        );
        insert iuSettings;
        System.runAs (getTestRunUser()) {
            Account testAcc = TDdAccountFactory.createAccounts('Default Values for NZ', 1, 'Marketplace')[0];
            Test.startTest();
            testAcc.BillingCountryCode = 'JP';
            testAcc.BillingCountry = 'Japan';
            testAcc.BillingState = 'Tokyo';
            testAcc.BillingPostalCode = '1234';
            testAcc.Phone = '120456789';
            testAcc.CurrencyISOCode = 'JPY';
            insert testAcc;
            Test.stopTest();
            testAcc = [SELECT Id, Direct_Deposit__c, Phone FROM Account WHERE Id =: testAcc.Id];
            System.assertEquals('+81 120-456-789', testAcc.Phone, 'Must have propper Phone format');
        }
    }

    /**
    * @description BASD-28825
    */
    @isTest
    static void testupdateLeadPrimaryMerchantCatergory() {
        User testRunUser = TDdAccountFactory.createUsers(1)[0];
        testRunUser.FirstName = 'Hubspot';
        testRunUser.LastName = 'Integration User';
        testRunUser.email = 'hubspot@doordash.com.testemail';

        System.runAs(testRunUser){

            Vertical_Category_Trigger_Setting__c vertCatSetting = new Vertical_Category_Trigger_Setting__c();
            vertCatSetting.Run_Update_Merchant_Categories_method__c = true;
            vertCatSetting.SetupOwnerId = testRunUser.Id;
            insert vertCatSetting;

            Account account = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            account.PersonMailingCity = 'Los Angeles';
            account.PersonMailingCountry = 'United States';
            account.PersonMailingCountryCode = 'US';
            account.PersonMailingPostalCode = '91436';
            account.PersonMailingStreet = '15910 Ventura Blvd';
            account.PersonEmail = 'test@thisisfake.com';
            insert account;

            Account acc = [Select id,PersonMailingState,Primary_Merchant_Category__pc,PersonContactId From Account Where id =: account.id ];

            Campaign campaign = new Campaign(Name = 'AcqMktgTest', Title__c = 'AcqMktgTest', RecordTypeId = CDdCampaignMemberTriggerHelper.campaignWorkId);
            insert campaign;

            insert new CampaignMember(ContactId = acc.PersonContactId, CampaignId = campaign.Id);

            Test.startTest();
            account.Primary_Merchant_Category__pc = 'Grocery';
            update account;
            Test.stopTest();

           List<Lead> leadList = new List<Lead>();
           leadList = [Select id,State,Primary_Merchant_Category__c,Created_from_Contact__c From Lead Where Created_from_Contact__c =: acc.PersonContactId];
           System.assertEquals(account.Primary_Merchant_Category__pc, leadList[0].Primary_Merchant_Category__c,'Person Account & Lead State value should be same');
        }
    }

    /**
    * @description BASD-28032
    */
    @isTest
    static void testupdateLeadAddress() {
        User testRunUser = TDdAccountFactory.createUsers(1)[0];
        testRunUser.FirstName = 'Hubspot';
        testRunUser.LastName = 'Integration User';
        testRunUser.email = 'hubspot@doordash.com.testemail';

        System.runAs(testRunUser){

            Account account = TDdAccountFactory.createAccounts('test Marketing Case', 1, 'Consumer or Dasher')[0];
            account.PersonMailingCity = 'Los Angeles';
            account.PersonMailingCountry = 'United States';
            account.PersonMailingCountryCode = 'US';
            account.PersonMailingPostalCode = '91436';
            account.PersonMailingStreet = '15910 Ventura Blvd';
            account.PersonEmail = 'test@thisisfake.com';
            insert account;

            Account acc = [Select id,PersonMailingState,PersonContactId From Account Where id =: account.id ];

            Campaign campaign = new Campaign(Name = 'AcqMktgTest', Title__c = 'AcqMktgTest', RecordTypeId = CDdCampaignMemberTriggerHelper.campaignWorkId);
            insert campaign;

            insert new CampaignMember(ContactId = acc.PersonContactId, CampaignId = campaign.Id);

            Test.startTest();
            account.PersonMailingState = 'CA';
            account.PersonMailingPostalCode = '12345';
            account.PersonMailingStreet = '15 Ventura Blvd';
            update account;
            Test.stopTest();

            List<Lead> leadList = new List<Lead>();
            leadList = [Select id,State,Street,PostalCode,Created_from_Contact__c From Lead Where Created_from_Contact__c =: acc.PersonContactId];
            System.assertEquals(account.PersonMailingState, leadList[0].state,'Person Account & Lead State value should be same');
            System.assertEquals(account.PersonMailingStreet, leadList[0].Street,'Person Account & Lead Street value should be same');
            System.assertEquals(account.PersonMailingPostalCode, leadList[0].PostalCode,'Person Account & Lead PostalCode value should be same');
        }
    }
}