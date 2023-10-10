/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/22/2019
*
* @group Copy Parent Account Event
*
* @description Purpose is to test the Copy Parent Account platform event hander
*
**************************************************************************************************************************************/
@isTest
public class CDdCopyParentAccountEventTest {
    public static final Decimal TEST_BUSINESS_ID = 7678900.0;
    public static final String TEST_TEAM_TYPE = 'Auto-Onboard';
    public static final String TEST_DECK_RANK = 'King';
    public static final Decimal TEST_NTAM_SALES = 123456.00;
    public static final String TEST_PARENT_ACCOUNT_NAME = 'Home Run Pizza [Parent-76789]';
    private static final String TEST_CHILD_ACCOUNT_NAME = 'Home Run Pizza (Artesia Blvd)';
    public static final String TEST_LEAD_NAME = 'Home Run Pizza (Artesia Blvd)';
    public static final String TEST_BUSINESS_VERTICAL_NAME = 'Test Retail';
    public static final String TEST_DD_ACCOUNT_MERCHANT_CATEGORIES = 'Alcohol / Alcohol-Lite ; Grocery';
    private static final RecordType OPP_RECORD_TYPE_MARKETPLACE =  [SELECT Id FROM RecordType WHERE Name = 'Marketplace' AND SObjectType = 'Opportunity' LIMIT 1];
    private static final Decimal TEST_AMOUNT = 1023.00;
   /**
    * @description Prepare test data
    */
    @testSetup
    static void setup() {
        String sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        vCS__c s = VTestUtil.createVeltigSettings();
        s.parentAccMatchFlag__c = true;
        s.copyFieldsFromParent__c = true;
        insert s;
        E2F__FindApi_Triggers_Settings__c findAPISettings = new E2F__FindApi_Triggers_Settings__c(
                                                            SetupOwnerId = sysAdminProfileId
                                                            , Name = 'System Administrator'
                                                            , E2F__Bypass_Trigger__c = true
                                                        );
        insert findAPISettings;
        CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
        List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();
        Account parentAccount = TDdAccountFactory.createAccounts(TEST_PARENT_ACCOUNT_NAME, 1, 'Parent Account')[0];
        parentAccount.Name = TEST_PARENT_ACCOUNT_NAME;
        parentAccount.Business_ID__c = TEST_BUSINESS_ID;
        insert parentAccount;
        List<Lead> testLeads = TDdLeadFactory.createLeads(TEST_LEAD_NAME, 1, 'Master Lead', false);
        Lead testLead = testLeads[0];
        testLead.LastName = TEST_LEAD_NAME;
        testLead.Business_Id__c = TEST_BUSINESS_ID;
        testLead.Type__c = 'Franchise';     //Based on custom metadata - this will be overwritten
        testLead.Deck_Rank__c = null;     //Based on custom metadata - this will not be overwritten
        testLead.Amount__c = null;        //Based on custom metadata - this will not be overwritten
        insert testLead;
        Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
        childAccount.ParentId = parentAccount.Id;
        childAccount.BillingCountry = 'United States';
        childAccount.Name = TEST_CHILD_ACCOUNT_NAME;
        childAccount.Business_Id__c = TEST_BUSINESS_ID;
        childAccount.Deck_Rank__c = TEST_DECK_RANK;
        childAccount.Amount__c = TEST_AMOUNT;
        insert childAccount;
        Contact contact = VTestUtil.createContact('Test', 'Contact', childAccount);
        insert contact;
        Opportunity testOpportunity = TDdOpportunityFactory.createOpportunity(childAccount.Name, childAccount.Id, contact.Id, 'Meeting Set', OPP_RECORD_TYPE_MARKETPLACE);
        insert testOpportunity;
        Test.stopTest();
    }
    /**
    * @description BZAP-4559 - Copy Parent Account information to master leads (unconverted leads)
    */
    @isTest
    public static void testAccountFieldCopyToLead(){
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            Account parentAccount = [SELECT Id, Account_Type__c, Deck_Rank__c, Amount__c
                                    FROM Account
                                    WHERE Name = :TEST_PARENT_ACCOUNT_NAME
                                    LIMIT 1];
            Lead testLead = [SELECT Id FROM Lead WHERE LastName = :TEST_LEAD_NAME LIMIT 1];
            parentAccount.Account_Type__c = TEST_TEAM_TYPE;
            parentAccount.Deck_Rank__c = TEST_DECK_RANK;
            parentAccount.Amount__c = TEST_NTAM_SALES;
            update parentAccount;
            Test.getEventBus().deliver();
            Test.stopTest();
            Account testParentAccountFromDB = [SELECT Id, Business_Id__c, Account_Type__c, Deck_Rank__c, Amount__c FROM Account WHERE Id = :parentAccount.Id];
            Lead testLeadFromDB = [SELECT Id, Business_Id__c, Type__c, Deck_Rank__c, Amount__c FROM Lead WHERE Id = :testLead.Id];
            System.assertEquals(TEST_BUSINESS_ID, testLeadFromDB.Business_Id__c, 'Expected Business Id ' + TEST_BUSINESS_ID);
            System.assertEquals(TEST_TEAM_TYPE, testLeadFromDB.Type__c, 'Expected Team Type ' + TEST_TEAM_TYPE);
            System.assertEquals(testParentAccountFromDB.Deck_Rank__c, testLeadFromDB.Deck_Rank__c, 'Expected Deck Rank ' + testParentAccountFromDB.Deck_Rank__c);
            System.assertEquals(TEST_NTAM_SALES, testLeadFromDB.Amount__c, 'Expected nTam Sales ' + TEST_NTAM_SALES);
        }
    }
    @isTest
    static void testAccountFieldCopyToOpportunity() {
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers[1];
        List<Business_Vertical__c> bvList = [SELECT Id, Menu_UI_Type__c, Primary_Category__c, Name, Business_Vertical_Id__c FROM Business_Vertical__c WHERE name =:TEST_BUSINESS_VERTICAL_NAME];
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Test.startTest();
            Account childAccount = [SELECT Id, Name, ParentId FROM Account WHERE Name = :TEST_CHILD_ACCOUNT_NAME];
            childAccount.OwnerId = runUser1.Id;
            childAccount.Merchant_Categories__c = TEST_DD_ACCOUNT_MERCHANT_CATEGORIES;
        	childAccount.Primary_Merchant_Category__c = bvList[0].Primary_Category__c;
            update childAccount;
            Test.getEventBus().deliver();
            Test.stopTest();
            Opportunity opportunityFromDB = [SELECT Id, Account_Owner1__c, Amount, Deck_Rank__c FROM Opportunity WHERE Name = :TEST_CHILD_ACCOUNT_NAME];
            //System.assertEquals(DECK_RANK_JACK, opportunityFromDB.Deck_Rank__c, 'Expecting deck rank ' + DECK_RANK_JACK);
            //System.assertEquals(TEST_AMOUNT, opportunityFromDB.Amount, 'Expecting amount ' + TEST_AMOUNT);
            System.assertEquals(runUser1.Id, opportunityFromDB.Account_Owner1__c, 'Expecting owner id ' + runUser1.Id);
        }
    }
}