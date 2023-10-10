/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/23/2019
*
* @group SObject Field Copy
*
* @description Purpose is to test the SObject Field Copy functionality
* 
**************************************************************************************************************************************/
@isTest
public class CDdSObjectFieldCopyObjTest {
    
    private static final Decimal TEST_BUSINESS_ID = 76789.0;
    public static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    public static final String SOBJECT_TYPE_CONTACT = 'Contact';
    public static final String TEST_DD_ACCOUNT_MERCHANT_CATEGORIES = 'Alcohol / Alcohol-Lite ; Grocery'; 	
    public static final String TEST_BUSINESS_VERTICAL_NAME = 'Test Retail';     
    private static Map<String, Schema.RecordTypeInfo> accountRecTypeMap = Account.SobjectType.getDescribe().getRecordTypeInfosByDeveloperName();
    public static final Id PARENT_ACC_RECORDTYPE_ID = accountRecTypeMap.get(CDdSupportConstants.RECORDTYPE_LABEL_PARENTACC).getRecordTypeId();
    
    
   /** 
    * @description Prepare test data
    */
    @testSetup 
    static void setup() {
        String sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        vCS__c s = VTestUtil.createVeltigSettings();
        s.parentAccMatchFlag__c = true;
        s.copyFieldsFromParent__c = true;
        s.SetupOwnerId = sysAdminProfileId;
        insert s;        
        Test.startTest();       
        // insert parent account
        String parentAccountName = 'Test Parent Account';
        Decimal businessId = TEST_BUSINESS_ID;

        List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();        
   
        Account acc = TDdAccountFactory.createAccount(PARENT_ACC_RECORDTYPE_ID);
        acc.Business_Id__c = TEST_BUSINESS_ID;
        insert acc;
        
        List<Contact> testConsList = TDdAccountFactory.createContacts(1, acc.Id);
        insert testConsList;
    
        Test.stopTest();
    }
    @isTest
    static void testCopyFieldsToChildAccount() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        Decimal newBusinessId = 1111111;
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {            
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.Deck_Rank__c = 'Jack';
            childAccount.OwnerId = runUser0.Id;
            childAccount.Virtual_Concept__c = false;
            insert childAccount;              
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;  
            Test.startTest();
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id =:childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];            
            parentAccountFromDB.OwnerId = runUser1.Id;
            parentAccountFromDB.Business_Id__c = newBusinessId;
            update parentAccountFromDB;
            Test.getEventBus().deliver();
            Test.stopTest();
            List<Account> accounts = (List<Account>)new CDdSObjectFieldCopyProcessor(
                                                        new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT)
                                                            .getFieldCopyObj(SOBJECT_TYPE_ACCOUNT) 
                                                        , new Set<Id>{parentAccountFromDB.Id})
                                                    .targetRecords;
            Account childAccountFromDB1 = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Name = 'Home Run Pizza (Artesia Blvd)'];
            Account parentAccountFromDB1 = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB1.ParentId];            
            System.assertEquals(parentAccountFromDB1.Business_Id__c
                                , childAccountFromDB1.Business_Id__c
                                , 'Expecting the Child Account Business Id to match with the Parent Account Business Id');                                                                 
        }
    }    	
    @isTest
    static void testCopyFieldsToContact() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        List<Business_Vertical__c> bvList = [SELECT Id, Menu_UI_Type__c, Primary_Category__c, Name, Business_Vertical_Id__c FROM Business_Vertical__c WHERE name =:TEST_BUSINESS_VERTICAL_NAME];
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) { 
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.Deck_Rank__c = 'Jack';
            childAccount.OwnerId = runUser0.Id;
            childAccount.ADR_Owner_Actual__c = null;
            childAccount.Merchant_Categories__c = TEST_DD_ACCOUNT_MERCHANT_CATEGORIES;		
        	childAccount.Primary_Merchant_Category__c = bvList[0].Primary_Category__c;
            insert childAccount;
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;
            Test.startTest();
            Account childAccountWithParentAccount = [SELECT Id, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, OwnerId FROM Account WHERE Id = :childAccountWithParentAccount.ParentId];
            parentAccountFromDB.OwnerId = runUser1.Id;
            childAccountWithParentAccount.OwnerId = runUser1.Id;
            update new List<Account>{parentAccountFromDB, childAccountWithParentAccount};
            Test.getEventBus().deliver();
            Test.stopTest();
            Account parentAccountFromDB1 = [SELECT Id, OwnerId FROM Account WHERE Id = :parentAccountFromDB.Id];
            Account childAccountFromDB = [SELECT Id, OwnerId FROM Account WHERE Id = :childAccount.Id];
            Contact childContactFromDB = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :childAccountFromDB.Id];
            System.assertEquals(true
                                , parentAccountFromDB1.OwnerId.equals(childAccountFromDB.OwnerId)
                                , 'Expecting the Child Account Owner to match with Parent Account Owner');
            System.assertEquals(true
                                , childAccountFromDB.OwnerId.equals(childContactFromDB.OwnerId)
                                , 'Expecting the Child Contact Owner to match with Child Account Owner');            
        }
    }
    @isTest
    static void testCopyFieldsToContactOverride() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        List<Business_Vertical__c> bvList = [SELECT Id, Menu_UI_Type__c, Primary_Category__c, Name, Business_Vertical_Id__c FROM Business_Vertical__c WHERE name =:TEST_BUSINESS_VERTICAL_NAME];
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.Deck_Rank__c = 'Jack';
            childAccount.OwnerId = runUser0.Id;
            childAccount.ADR_Owner_Actual__c = null;
            childAccount.Merchant_Categories__c = TEST_DD_ACCOUNT_MERCHANT_CATEGORIES;		
        	childAccount.Primary_Merchant_Category__c = bvList[0].Primary_Category__c;
            insert childAccount;
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;
            Test.startTest();
            childAccount.ADR_Owner_Actual__c = runUser1.Id;
            update childAccount;
            Test.stopTest();
            Account childAccountFromDB = [SELECT Id, OwnerId, ADR_Owner_Actual__c FROM Account WHERE Id = :childAccount.Id];
            Contact childContactFromDB = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :childAccountFromDB.Id];
            System.assertEquals(runUser1.Id
                                , childContactFromDB.OwnerId
                                , 'Expecting the Contact Owner to be ' + runUser1.Id);          
            System.assertEquals(true
                                , childContactFromDB.OwnerId.equals(childAccountFromDB.ADR_Owner_Actual__c)
                                , 'Expecting the Contact Owner to match with the Account ADR Owner');
        }
    }    
    @isTest
    static void testAccountFieldCopyToAccountBatch() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        Decimal newBusinessId = 1111111;
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.Deck_Rank__c = 'Jack';
            childAccount.OwnerId = runUser0.Id;
            childAccount.Virtual_Concept__c = false;
            insert childAccount;
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];            
            parentAccountFromDB.OwnerId = runUser1.Id;
            parentAccountFromDB.Business_Id__c = newBusinessId;
            update parentAccountFromDB;            
            Test.startTest();
            Id batchId = Database.executeBatch(new CDdAccountFieldCopyToAccountBatch());
            System.assertEquals(true, batchId!=null, 'Expecting a batch Id');
            Test.stopTest();
        }
    }    
    @isTest
    static void testAccountFieldCopyToContactBatch() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers[1];
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.Deck_Rank__c = 'Jack';
            insert childAccount; 
              
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;  
             
            Account childAccountWithParentAccount = [SELECT Id, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, OwnerId FROM Account WHERE Id = :childAccountWithParentAccount.ParentId];
            parentAccountFromDB.OwnerId = runUser1.Id;
            update parentAccountFromDB;
            Test.startTest();
            Id batchId = Database.executeBatch(new CDdAccountFieldCopyToContactBatch());
            System.assertEquals(true, batchId!=null, 'Expecting a batch Id');            
            Test.stopTest();
        }
    }
    @isTest
    static void testAccountFieldCopyAction() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        Decimal newBusinessId = 1111111;
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.Deck_Rank__c = 'Jack';
            childAccount.OwnerId = runUser0.Id;
            childAccount.Virtual_Concept__c = false;
            insert childAccount;
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];            
            parentAccountFromDB.OwnerId = runUser1.Id;
            parentAccountFromDB.Business_Id__c = newBusinessId;
            update parentAccountFromDB;
            Test.startTest();
            Test.setCurrentPageReference(new PageReference('Page.PDdAccountFieldCopy')); 
            System.currentPageReference().getParameters().put('retURL', '/Account');
            ApexPages.StandardSetController controller = new ApexPages.StandardSetController(new List<Account>{childAccount});
            controller.setSelected(new List<Account>{childAccount});
            CDdAccountFieldCopyCtrl ctrl = new CDdAccountFieldCopyCtrl(controller);
            CDdAccountFieldCopyCtrl.copyFields(new List<Id>{childAccount.Id});
            Test.stopTest();
            Account childAccountFromDB1 = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB1 = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];                        
            System.assertEquals(parentAccountFromDB1.Business_Id__c
                                , childAccountFromDB1.Business_Id__c
                                , 'Expecting the Child Account Business Id to match with the Parent Account Business Id');            

        }
    }         
}