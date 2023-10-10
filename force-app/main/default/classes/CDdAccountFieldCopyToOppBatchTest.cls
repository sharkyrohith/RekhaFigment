/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/05/2019
*
* @group SObject Field Copy
*
* @description Purpose is to test the Account to Opportunity Field Copy functionality
* 
**************************************************************************************************************************************/
@isTest
public class CDdAccountFieldCopyToOppBatchTest {
    private static final Decimal TEST_BUSINESS_ID = 76789.0;
    private static final String CHILD_ACCOUNT_NAME = 'Home Run Pizza (Artesia Blvd)';
    private static final String PARENT_ACCOUNT_NAME = 'Home Run Pizza [Parent-76789]';
    public static final String TEST_DD_ACCOUNT_MERCHANT_CATEGORIES = 'Alcohol / Alcohol-Lite ; Grocery';
    private static final RecordType OPP_RECORD_TYPE_MARKETPLACE =  [SELECT Id FROM RecordType WHERE Name = 'Marketplace' AND SObjectType = 'Opportunity' LIMIT 1];
    private static final String DECK_RANK_JACK = 'Jack';
    private static final Decimal SAMPLE_AMOUNT = 1023.00;    
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
        List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();     
        // insert parent account
        Account parentAccount = TDdAccountFactory.createAccounts('parentAccountName', 1, 'Parent Account')[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Name = PARENT_ACCOUNT_NAME;
        parentAccount.Business_Id__c = TEST_BUSINESS_ID;
        parentAccount.Deck_Rank__c = DECK_RANK_JACK;
        insert parentAccount;
        Contact parentContact = VTestUtil.createContact('Test Parent', 'Contact Parent', parentAccount);
        parentContact.Email = 'parent.contact@testdd.com';
        insert parentContact;
        Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
        childAccount.ParentId = parentAccount.Id;
        childAccount.BillingCountry = 'United States';
        childAccount.Name = CHILD_ACCOUNT_NAME;
        childAccount.Business_Id__c = TEST_BUSINESS_ID;
        childAccount.Deck_Rank__c = DECK_RANK_JACK;
        childAccount.Amount__c = SAMPLE_AMOUNT;
        childAccount.Merchant_Categories__c = TEST_DD_ACCOUNT_MERCHANT_CATEGORIES;		
       	childAccount.Primary_Merchant_Category__c = bvList[0].Primary_Category__c;
        insert childAccount;
        Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
        insert contact;
        Opportunity testOpportunity = TDdOpportunityFactory.createOpportunity(childAccount.Name, childAccount.Id, contact.Id, 'Meeting Set', OPP_RECORD_TYPE_MARKETPLACE);
		insert testOpportunity;        
        Test.stopTest();
    }
    @isTest
    static void testAccountFieldCopyToOpportunity1() {
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = [SELECT Id, Name, ParentId FROM Account WHERE Name = :CHILD_ACCOUNT_NAME];
            childAccount.OwnerId = runUser1.Id;
            update childAccount;
            Test.startTest();
            Database.executebatch(new CDdAccountFieldCopyToOpportunityBatch(), 10); 
            Test.stopTest();
            Opportunity opportunityFromDB = [SELECT Id, Account_Owner1__c, Amount, Deck_Rank__c FROM Opportunity WHERE Name = :CHILD_ACCOUNT_NAME];
            //System.assertEquals(DECK_RANK_JACK, opportunityFromDB.Deck_Rank__c, 'Expecting deck rank ' + DECK_RANK_JACK);
            //System.assertEquals(SAMPLE_AMOUNT, opportunityFromDB.Amount, 'Expecting amount ' + SAMPLE_AMOUNT);
            System.assertEquals(runUser1.Id, opportunityFromDB.Account_Owner1__c, 'Expecting owner id ' + runUser1.Id);
        }
    }
    @isTest
    static void testAccountFieldCopyToOpportunity2() {
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = [SELECT Id, Name, ParentId FROM Account WHERE Name = :CHILD_ACCOUNT_NAME];
            childAccount.OwnerId = runUser1.Id;
            update childAccount;
            Test.startTest();
            Database.executebatch(new CDdAccountFieldCopyToOpportunityBatch(new List<Id>{childAccount.Id}), 10); 
            Test.stopTest();
            Opportunity opportunityFromDB = [SELECT Id, Account_Owner1__c, Amount, Deck_Rank__c FROM Opportunity WHERE Name = :CHILD_ACCOUNT_NAME];
            //System.assertEquals(DECK_RANK_JACK, opportunityFromDB.Deck_Rank__c, 'Expecting deck rank ' + DECK_RANK_JACK);
            //System.assertEquals(SAMPLE_AMOUNT, opportunityFromDB.Amount, 'Expecting amount ' + SAMPLE_AMOUNT);
            System.assertEquals(runUser1.Id, opportunityFromDB.Account_Owner1__c, 'Expecting owner id ' + runUser1.Id);            
        }
    }        
}