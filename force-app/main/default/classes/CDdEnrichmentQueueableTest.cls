@isTest
public class CDdEnrichmentQueueableTest {
	
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
    
}