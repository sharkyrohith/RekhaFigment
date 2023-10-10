/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/05/2019
*
* @group SObject Field Copy
*
* @description Purpose is to test the Account Field Copy functionality
* 
**************************************************************************************************************************************/
@isTest
public class CDdAccountFieldCopyBatchSchedTest {
    private static final Decimal TEST_BUSINESS_ID = 76789.0;
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
        Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Business_Id__c = businessId;
        parentAccount.Deck_Rank__c = 'Jack';
        insert parentAccount;
        Contact parentContact = VTestUtil.createContact('Test Parent', 'Contact Parent', parentAccount);
        parentContact.Email = 'parent.contact@testdd.com';
        insert parentContact;
        Test.stopTest();
    }
    @isTest
    static void testAccountFieldCopyInvalidOption() {
        List<User> testUsers = TDdAccountFactory.createUsers(1);
        insert testUsers;
        User runUser0 = testUsers[0];
        System.runAs (runUser0) {
            Test.startTest();
            try {
            	new CDdAccountFieldCopyBatchSched(-1, 10).execute(null);
            } catch(Exception e){
            	System.assertEquals(CDdAccountFieldCopyBatchSched.ERROR_MSG_INVALID_FIELD_COPY_OPTION, e.getMessage());
            }
            Test.stopTest();
        }
    }    
    @isTest
    static void testAccountFieldCopyToAccount() {
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
            insert childAccount;
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
			Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];            
            parentAccountFromDB.OwnerId = runUser1.Id;
            parentAccountFromDB.Business_Id__c = newBusinessId;
            update parentAccountFromDB;            
            Test.startTest();
            new CDdAccountFieldCopyBatchSched(CDdAccountFieldCopyBatchSched.fieldCopyOptionType.COPY_TO_CHILD_ACCOUNT.ordinal(), 10).execute(null);
            Test.stopTest();
        }
    }    
    @isTest
    static void testAccountFieldCopyToContact() {
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
            childAccount.Deck_Rank__c = 'Jack';
            insert childAccount;
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;
            Account childAccountWithParentAccount = [SELECT Id, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, OwnerId FROM Account WHERE Id = :childAccountWithParentAccount.ParentId];
            parentAccountFromDB.OwnerId = runUser1.Id;
            update parentAccountFromDB;
            Test.startTest();
            new CDdAccountFieldCopyBatchSched(CDdAccountFieldCopyBatchSched.fieldCopyOptionType.COPY_TO_CONTACT.ordinal(), 10).execute(null);
            Test.stopTest();
        }
    }
    @isTest
    static void testAccountFieldCopyToOpportunity() {
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
            childAccount.Deck_Rank__c = 'Jack';
            insert childAccount;
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
            insert contact;
            Opportunity closedWonOpportunity = TDdOpportunityFactory.createOpportunity(childAccount.Name, childAccount.Id, contact.Id, 'Closed Won');
            insert closedWonOpportunity;            
            Account childAccountWithParentAccount = [SELECT Id, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, OwnerId FROM Account WHERE Id = :childAccountWithParentAccount.ParentId];
            parentAccountFromDB.OwnerId = runUser1.Id;
            update parentAccountFromDB;
            Test.startTest();
            new CDdAccountFieldCopyBatchSched(CDdAccountFieldCopyBatchSched.fieldCopyOptionType.COPY_TO_OPPORTUNITY.ordinal(), 10).execute(null);
            Test.stopTest();
        }
    }    
}