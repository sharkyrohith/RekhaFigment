/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/23/2019
*
* @group SObject Field Copy
*
* @description Test class for copy of Parent Account data to child account(s) and master lead(s)
*
**************************************************************************************************************************************/
@isTest
public class CDdLtngAccountFieldCopyActionCtrlTest {
   /**
    * @description Prepare test data
    */
    @testSetup
    static void setup() {
        String sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        Test.startTest();
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
        Test.stopTest();
    }
    /**
    * @description BZAP-4559 - Copy Parent Account information
    */
    @isTest
    public static void testCopyFieldsPositive(){
        String parentAccountName = 'Test Parent Account';
        Decimal TEST_BUSINESS_ID = 7678900.0;
        String TEST_TEAM_TYPE = 'Enterprise';
        String TEST_DECK_RANK = 'King';
        Decimal TEST_NTAM_SALES = 123456.00;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = testUser.id);
            validation.Bypass_Account_Validations__c = true;  insert validation;
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
            parentAccount.Business_ID__c = TEST_BUSINESS_ID;
            insert parentAccount;
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_Id__c = TEST_BUSINESS_ID;
            testLead.Type__c = 'Franchise';     //Based on custom metadata - this will be overwritten
            testLead.Deck_Rank__c = null;     //Based on custom metadata - this will not be overwritten
            testLead.Amount__c = null;        //Based on custom metadata - this will not be overwritten
            insert testLead;
            parentAccount.Account_Type__c = TEST_TEAM_TYPE;
            parentAccount.Deck_Rank__c = TEST_DECK_RANK;
            parentAccount.Amount__c = TEST_NTAM_SALES;
            update parentAccount;
            String result = CDdLtngAccountFieldCopyActionCtrl.copyFields(parentAccount.Id);
            Test.stopTest();
            System.assertEquals(true, result!=null, 'Expective valid result');
        }
    }
    /**
    * @description BZAP-4559 - Copy Parent Account information
    */
    @isTest
    public static void testCopyFieldsNegative(){
        String parentAccountName = 'Test Parent Account';
        Decimal TEST_BUSINESS_ID = 7678900.0;
        String TEST_TEAM_TYPE = 'Enterprise';
        String TEST_DECK_RANK = 'King';
        Decimal TEST_NTAM_SALES = 123456.00;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = testUser.id);
            validation.Bypass_Account_Validations__c = true;  insert validation;
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
            parentAccount.Business_ID__c = TEST_BUSINESS_ID;
            insert parentAccount;
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_Id__c = TEST_BUSINESS_ID;
            testLead.Type__c = 'Franchise';     //Based on custom metadata - this will be overwritten
            testLead.Deck_Rank__c = null;     //Based on custom metadata - this will not be overwritten
            testLead.Amount__c = null;        //Based on custom metadata - this will not be overwritten
            insert testLead;
            parentAccount.Account_Type__c = TEST_TEAM_TYPE;
            parentAccount.Deck_Rank__c = TEST_DECK_RANK;
            parentAccount.Amount__c = TEST_NTAM_SALES;
            update parentAccount;
            String result = CDdLtngAccountFieldCopyActionCtrl.copyFields(testLead.Id);
            Test.stopTest();
            System.assertEquals(true, result==null, 'Expective null result');
        }
    }
}