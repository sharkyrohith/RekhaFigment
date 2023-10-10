/**
* @author Sriram
* @date 2019-05
*
* @description Additional test class for CDdAccountTriggerHandler
* This class uses the setup method to create the seed data required for all relevant test cases
*/
@isTest
public class CDdAccountTriggerHandlerAdditionalTest {
    public static final Id TEST_ROLE_ID;
    public static final Decimal TEST_BUSINESS_ID = 7678900.0;
    public static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_INFO_BY_DEV_NAME 
                                                = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    public static final String RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT = 'Parent_Account';
    public static final Id PARENT_ACCOUNT_RECORD_TYPE_ID = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_DD_TEST_PARENT_ACCOUNT = 'Test Parent Account';  
    public static final String TEST_DD_ACCOUNT_PARENT_IDENTIFIERS = 'TestDDAccountRollupParent%';
    public static final String TEST_DD_ACCOUNT_CHILD_IDENTIFIERS = 'TestDDAccountRollupChild%'; 
    public static final String TEST_DD_ACCOUNT_TYPE_PARTNER_MANAGED = 'Partner Managed';
    public static final String TEST_DD_ACCOUNT_MERCHANT_CATEGORIES = 'Alcohol / Alcohol-Lite ; Grocery';
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1 = 122222;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2 = 122223;
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
    * @description Prepare test data
    */
    @testSetup 
    static void setup() {
        System.runAs(getTestRunUser()){
            Test.startTest();

            vCS__c s = VTestUtil.createVeltigSettings();
            s.parentAccMatchFlag__c = true;
            s.copyFieldsFromParent__c = true;
            s.SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID;
            insert s;    
            CDdAccountHelperMethods.testingAccountFormStack = true;

            List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();
            String testPrimaryMerchantCategory = bvList[0].Primary_Category__c;                    
       
            List<Account> testAccounts = TDdAccountFactory.createAccounts('Test Account', 5);
            // Create Test Parent Accounts
            Account testAcct0 = testAccounts[0];
            testAcct0.Name = TEST_DD_TEST_PARENT_ACCOUNT;
            testAcct0.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct0.BillingCountry = 'United States';
            testAcct0.Business_Id__c = TEST_BUSINESS_ID;
            Account testAcct1 = testAccounts[1];
            testAcct1.Name = 'TestDDAccountRollupParent0';
            testAcct1.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct1.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1;
            testAcct1.Account_Type__c = TEST_DD_ACCOUNT_TYPE_PARTNER_MANAGED;
            Account testAcct2 = testAccounts[2];
            testAcct2.Name = 'TestDDAccountRollupParent1';
            testAcct2.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct2.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2;
            testAcct2.Account_Type__c = TEST_DD_ACCOUNT_TYPE_PARTNER_MANAGED;
            testAcct2.Merchant_Categories__c = TEST_DD_ACCOUNT_MERCHANT_CATEGORIES;	
            testAcct2.Primary_Merchant_Category__c = testPrimaryMerchantCategory;
            // Create Test Child Accounts
            Account testAcct3 = testAccounts[3];
            testAcct3.Name = 'TestDDAccountRollupChild0';
            Account testAcct4 = testAccounts[4];
            testAcct4.Name = 'TestDDAccountRollupChild1';                         
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
            Test.getEventBus().deliver(); 
            Test.stopTest();
        }
    }
   /** 
    * @description Test for valid business id on the child account
    * BZAP-3755 - if there is no Parent Account for that Bus ID, create a Parent Account
    */    
    @isTest
    static void testCreateParentAccount() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-1234567]';
        Decimal businessId = 1234567.0;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = businessId;
            insert childAccount;
            Test.stopTest();
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];
            System.assertEquals(parentAccountName, parentAccountFromDB.Name);
        }
    }
   /** 
    * @description Test for valid business id on the child account
    * BZAP-3755 - if there is no Parent Account for that Bus ID, create a Parent Account
    */    
    @isTest
    static void testExistingParentAccount() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            insert childAccount;
            Test.stopTest();
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];
            System.assertEquals(TEST_BUSINESS_ID, parentAccountFromDB.Business_Id__c);
        }
    }    
   /** 
    * @description Test for invalid business id on the child account
    * BZAP-3755 - if there is no Parent Account for that Bus ID, create a Parent Account
    */     
    @isTest
    static void testCreateParentAccountNegative() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        Decimal businessId = 45655.0;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = businessId;
            insert childAccount;
            Test.stopTest();
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
            System.assertEquals(true, childAccountFromDB.ParentId==null, 'Expecting no parent account for this child account of Business Id ' + businessId);
        }
    }
   /** 
    * @description Test for copy fields to Contact from Account record
    * BZAP-3801 - if the Owner on the Account has changed 
    */    
    @isTest
    static void testCopyFieldsToContact() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.OwnerId = runUser0.Id;
            insert childAccount;
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;
            Test.startTest();
            childAccount.OwnerId = runUser1.Id;
            update childAccount;
            Test.stopTest();
        }
    }
   /** 
    * @description Test for Previous Owner
    * BZAP-4088 - Test for Previous Owner
    */    
    @isTest
    static void testPreviousOwner() {
        Account account = [SELECT Id, OwnerId FROM Account WHERE NAME = :TEST_DD_TEST_PARENT_ACCOUNT LIMIT 1];
        List<User> testUsers = TDdAccountFactory.createUsers(4);
        insert testUsers;
        User runUser0 = testUsers[0];
        runUser0.ManagerId = testUsers[2].Id;
        User runUser1 = testUsers[1];
        runUser1.ManagerId = testUsers[3].Id;
        update testUsers;
        System.runAs (runUser0) {
            account.OwnerId = runUser0.Id;
            update account;
            Test.startTest();
            account.OwnerId = runUser1.Id;
            update account;
            Test.stopTest();
            Account accountFromDB = [   SELECT Id, Account_Owner_Manager__c, Previous_Account_Owner__c, Previous_Account_Owner_Manager__c 
                                        FROM Account 
                                        WHERE Id = :account.Id];
            System.assertEquals(runUser1.ManagerId, accountFromDB.Account_Owner_Manager__c, 'Expecting account manager to be updated');
            System.assertEquals(runUser0.Id, accountFromDB.Previous_Account_Owner__c, 'Expecting previous account owner to be updated');
            System.assertEquals(runUser0.ManagerId, accountFromDB.Previous_Account_Owner_Manager__c, 'Expecting previous account manager to be updated');
        }
    }
   /** 
    * @description Test for BZAP-4247 - Move Update Parent Account with Child Deck Rank to code
    * Testing for Deck Rank Ace of Spades    
    */
    @isTest
    static void testUpdateDeckRankOnParentAccount1() {
        Account parentAccount = [SELECT Id, OwnerId FROM Account WHERE NAME = :TEST_DD_TEST_PARENT_ACCOUNT LIMIT 1];
        System.runAs (getTestRunUser()) {
            Test.startTest();
            parentAccount.Highest_Child_Deck_Rank__c = 1;
            parentAccount.Highest_Lead_Deck_Dank__c = 7;
            update parentAccount;
            Test.getEventBus().deliver();
            Test.stopTest();
            Account parentAccountFromDB = [SELECT Id, Deck_Rank__c 
                                            FROM Account
                                            WHERE Id = :parentAccount.Id];
            System.assertEquals('Ace of Spades', parentAccountFromDB.Deck_Rank__c, 'Expecting deck rank - Ace of Spades');  
        }
    }
   /** 
    * @description Test for BZAP-4247 - Move Update Parent Account with Child Deck Rank to code
    * Testing for Deck Rank Queen    
    */
    @isTest
    static void testUpdateDeckRankOnParentAccount2() {
        Account parentAccount = [SELECT Id, OwnerId FROM Account WHERE NAME = :TEST_DD_TEST_PARENT_ACCOUNT LIMIT 1];
        System.runAs (getTestRunUser()) {
            Test.startTest();
            parentAccount.Highest_Lead_Deck_Dank__c = 5;
            update parentAccount;
            Test.getEventBus().deliver();
            Test.stopTest();
            Account parentAccountFromDB = [SELECT Id, Deck_Rank__c 
                                            FROM Account
                                            WHERE Id = :parentAccount.Id];
            System.assertEquals('Queen', parentAccountFromDB.Deck_Rank__c, 'Expecting deck rank - Queen');  
        }
    }
   /** 
    * @description Test for BZAP-4247 - Move Update Parent Account with Child Deck Rank to code
    * Testing for Deck Rank null
    */
    @isTest
    static void testUpdateDeckRankOnParentAccount3() {
        Account parentAccount = [SELECT Id, OwnerId FROM Account WHERE NAME = :TEST_DD_TEST_PARENT_ACCOUNT LIMIT 1];
        System.runAs (getTestRunUser()) {
            Test.startTest();
            parentAccount.Highest_Lead_Deck_Dank__c = 0;
            update parentAccount;
            Test.getEventBus().deliver();
            Test.stopTest();
            Account parentAccountFromDB = [SELECT Id, Deck_Rank__c 
                                            FROM Account
                                            WHERE Id = :parentAccount.Id];
            System.assertEquals(null, parentAccountFromDB.Deck_Rank__c, 'Expecting deck rank - null');   
        }
    }
    /**
    * @description For testing the positive test case of changing a Account Owner when Parent Account is changed
    */
    @isTest
    static void AccountOwnerMatching_Positive1_TestMethod(){
        Account parentAccount = [SELECT Id, OwnerId FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_PARENT_IDENTIFIERS LIMIT 1];
        List<Account> childAccounts = TDdAccountFactory.createAccounts('Test DD Child Account', 2);
        String ownerId = parentAccount.OwnerId;
        Set<Id> accountIds = new Set<Id>();
        
        for (Account childAccount : childAccounts){
            childAccount.ParentId = parentAccount.Id;
        }

        System.runAs (getTestRunUser()) {
            Test.startTest();
            insert childAccounts;
            accountIds.add(parentAccount.Id);
            for (Account childAccount : childAccounts){
                accountIds.add(childAccount.Id);
            }
            Test.getEventBus().deliver();
            Test.stopTest();
            List<Account> accountsFromDB = [SELECT Id, OwnerId
                                    FROM Account
                                    WHERE Id in :accountIds];

            for(Account acct : accountsFromDB){
                System.assert(acct.OwnerId == ownerId);
            }            
        }
    }
    /**
    * @description For testing the positive test case of verifying the change in the Child Accounts Owner on change of a Parent Account Owner
    */
    @isTest
    static void AccountOwnerMatching_Positive2_TestMethod(){
        Account parentAccount = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_PARENT_IDENTIFIERS LIMIT 1];
        Account childAccount = [SELECT Id FROM Account WHERE ParentId = :parentAccount.Id LIMIT 1];
        Set<Id> accountIds = new Set<Id>();

        User testUser = TDdAccountFactory.createUsers(1)[0];
        insert testUser;

        System.runAs (getTestRunUser()) {
            Test.StartTest();
            parentAccount.OwnerId = testUser.Id;
            update parentAccount;
            Test.getEventBus().deliver();
            Test.StopTest();

            accountIds.add(parentAccount.Id);
            accountIds.add(childAccount.Id);            

            List<Account> accountsFromDB = [SELECT Id, OwnerId, Business_ID__c, Account_Type__c
                                    FROM Account
                                    WHERE Id in :accountIds];

            for(Account acct : accountsFromDB){
                System.assert(acct.OwnerId == testUser.Id);
            }
        }
    }
    /**
    * @description For testing the positive test case of verifying the change in the Child Accounts Information on change of a Parent Account Information
    */
    @isTest
    static void AccountInformationMatching_Positive1_TestMethod(){
        Account parentAccount = [SELECT Id, Business_ID__c FROM Account WHERE NAME ='TestDDAccountRollupParent1'  LIMIT 1];
        Account childAccount = [SELECT Id FROM Account WHERE ParentId = :parentAccount.Id LIMIT 1];
        Decimal businessId = parentAccount.Business_ID__c;
        Set<Id> accountIds = new Set<Id>();

        System.runAs (getTestRunUser()) {
            Test.StartTest();
            parentAccount.Account_Type__c = TEST_DD_ACCOUNT_TYPE_PARTNER_MANAGED;
            update parentAccount;

            childAccount.Merchant_Categories__c = null;	
            childAccount.Primary_Merchant_Category__c = null;	
            update childAccount;
            Test.getEventBus().deliver();
            Test.StopTest();

            accountIds.add(parentAccount.Id);
            accountIds.add(childAccount.Id);            

            List<Account> accountsFromDB = [SELECT Id, Business_ID__c, OwnerId, Account_Type__c, Merchant_Categories__c
                                    FROM Account
                                    WHERE Id in :accountIds];

            for(Account acct : accountsFromDB){
                System.assertEquals(acct.Business_ID__c, businessId);
                System.assert(acct.Account_Type__c.equals(TEST_DD_ACCOUNT_TYPE_PARTNER_MANAGED));
                System.assertEquals(TEST_DD_ACCOUNT_MERCHANT_CATEGORIES, acct.Merchant_Categories__c);
            }
        }        
    }
    /**
    * @description For testing the positive test case of verifying the information on the Child Account created is in sync with the information on Parent Account
    */
    @isTest
    static void AccountInformationMatching_Positive2_TestMethod(){
        Account parentAccount = [SELECT Id, Business_ID__c, Account_Type__c FROM Account WHERE NAME ='TestDDAccountRollupParent1' LIMIT 1];
        List<Account> childAccounts = TDdAccountFactory.createAccounts('Test DD Child Account', 2);
        Decimal businessId = parentAccount.Business_ID__c;
        String accountType = parentAccount.Account_Type__c;
        Set<Id> accountIds = new Set<Id>();
        
        for (Account childAccount : childAccounts){
            childAccount.ParentId = parentAccount.Id;
        }

        System.runAs (getTestRunUser()) {
            Test.startTest();
            insert childAccounts;
            accountIds.add(parentAccount.Id);
            for (Account childAccount : childAccounts){
                accountIds.add(childAccount.Id);
            }
            Test.getEventBus().deliver();
            Test.stopTest();
            List<Account> accountsFromDB = [SELECT Id, OwnerId, Business_ID__c, Account_Type__c, Merchant_Categories__c
                                    FROM Account
                                    WHERE Id in :accountIds];

            for(Account acct : accountsFromDB){
                System.assert(acct.Business_ID__c == businessId);
                System.assert(acct.Account_Type__c == accountType);
                System.assertEquals(TEST_DD_ACCOUNT_MERCHANT_CATEGORIES, acct.Merchant_Categories__c);
            }            
        }        
    }

    /**
    * @description For testing the TopMx and High AOV field updates from Parent to child account
    */
    @isTest
    static void ParentChildAccount_TopMX_HighAOV_DataSyncTest(){
        Account parentAccount = [SELECT Id, Business_ID__c, Account_Type__c,Top_Mx__c,High_AOV__c FROM Account WHERE NAME LIKE :TEST_DD_TEST_PARENT_ACCOUNT LIMIT 1];
        List<Account> childAccounts = TDdAccountFactory.createAccounts('Test DD Child Account', 2);
         
        for (Account childAccount : childAccounts){
            childAccount.ParentId = parentAccount.Id;
        }

        
        Test.startTest();
        insert childAccounts;

        parentAccount.Top_Mx__c = true;
        parentAccount.High_AOV__c = true;
        update parentAccount;
        
        childAccounts = [Select Id,Top_Mx__c,High_AOV__c from Account Where Id IN :childAccounts];
        for (Account childAccount : childAccounts){
            System.assert(parentAccount.Top_Mx__c == childAccount.Top_Mx__c);
            System.assert(parentAccount.High_AOV__c == childAccount.High_AOV__c);   
        }
        Test.stopTest();  
    }

    @isTest
    static void testAccountPhoneBeforeUpdate() {
        Account acc = [SELECT Id, Phone FROM Account LIMIT 1];
        acc.Phone = '+64 55 44 3322';
        acc.BillingCountryCode = 'NZ';
        acc.BillingCountry = 'New Zealand';
        acc.BillingState = 'Auckland';
        acc.BillingPostalCode = '1234';
        Test.startTest();
        update acc;
        Test.stopTest();
        acc = [SELECT Id, Phone FROM Account WHERE Id =: acc.Id];
        //System.assertEquals('+6455443322', acc.Phone);
    }
    /** 
    * @description Test for if "Deck Rank" (Deck_Rank_c) is blank, default it to be the same value as "Launch Deck Rank" (Launch_Deck_Rank_c). 
    * BZAP-12607 - if "Deck Rank" (Deck_Rank_c) is blank, default it to be the same value as "Launch Deck Rank" (Launch_Deck_Rank_c)
    */    
    @isTest
    static void testPopulateDeckRankIfBlank() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-1234567]';
        Decimal businessId = 1234567.0;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'New Zealand';
            childAccount.BillingCountryCode = 'NZ';
            childAccount.BillingState = '';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Phone = '+64 12345678';
            childAccount.BillingPostalCode = '1234';
            childAccount.Launch_Deck_Rank__c = 'Ace';
            childAccount.Deck_Rank__c = null;
            childAccount.Business_Id__c = businessId;
            insert childAccount;
            Test.stopTest();
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId, Deck_Rank__c, Launch_Deck_Rank__c  FROM Account WHERE Id = :childAccount.Id];
            System.assertEquals(childAccountFromDB.Deck_Rank__c, childAccountFromDB.Launch_Deck_Rank__c);
        }
    }
}