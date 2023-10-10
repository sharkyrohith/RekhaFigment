/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 09/13/2019
*
* @group Apex Batch Test
*
* @description Purpose is to test the Lead Update Parent Account functionality
* 
**************************************************************************************************************************************/
@isTest
public class CDdLeadUpdateParentAccountBatchTest {
    private static final Decimal TEST_BUSINESS_ID_1 = 76789.0;
    private static final Decimal TEST_BUSINESS_ID_2 = 89078.0;
   /** 
    * @description Prepare test data
    */
    @testSetup 
    static void setup() {
        String sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        vCS__c s = VTestUtil.createVeltigSettings();
        s.parentAccMatchFlag__c = false;
        s.copyFieldsFromParent__c = true;
        s.SetupOwnerId = sysAdminProfileId;
        insert s;
        E2F__FindApi_Triggers_Settings__c findAPISettings = new E2F__FindApi_Triggers_Settings__c(
                                                            SetupOwnerId = sysAdminProfileId
                                                            , Name = 'System Administrator'
                                                            , E2F__Bypass_Trigger__c = true
                                                        );
        insert findAPISettings;                
        Test.startTest();       
        // insert parent account
        String parentAccountName = 'Test Parent Account';
        Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Business_Id__c = TEST_BUSINESS_ID_1;
        parentAccount.Deck_Rank__c = 'Jack';
        insert parentAccount;
        Contact parentContact = VTestUtil.createContact('Test Parent', 'Contact Parent', parentAccount);
        parentContact.Email = 'parent.contact@testdd.com';
        insert parentContact;
        Test.stopTest();
    }
    @isTest
    static void testLeadUpdateParentAccount() {
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_Id__c = TEST_BUSINESS_ID_1;
            insert testLead;            
            Database.executeBatch(new CDdLeadUpdateParentAccountBatch());
            Test.stopTest();
            Lead leadFromDB = [SELECT Id, Name, Parent_Account__c FROM Lead WHERE Id = :testLead.Id];
            System.assertEquals(true, leadFromDB.Parent_Account__c!=null, 'Expecting Lead to be associated with a Parent Account');
            Account parentAccountFromDB = [SELECT Id, Business_Id__c FROM Account WHERE Id = :leadFromDB.Parent_Account__c];
            System.assertEquals(true, parentAccountFromDB!=null, 'Expecting a valid Parent Account');
        }
    }
    @isTest
    static void testLeadInsertParentAccount() {
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_Id__c = TEST_BUSINESS_ID_2;
            insert testLead;            
            Database.executeBatch(new CDdLeadUpdateParentAccountBatch());
            Test.stopTest();
            Lead leadFromDB = [SELECT Id, Name, Company, Parent_Account__c FROM Lead WHERE Id = :testLead.Id];
            System.assertEquals(true, leadFromDB.Parent_Account__c!=null, 'Expecting Lead to be associated with a Parent Account');
            Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :leadFromDB.Parent_Account__c];
            System.assertEquals(true, parentAccountFromDB!=null, 'Expecting a valid Parent Account');
            System.assertEquals(leadFromDB.Company + ' ' + '[Parent-' + TEST_BUSINESS_ID_2.stripTrailingZeros().toPlainString() + ']', parentAccountFromDB.Name, 'Expecting a valid Parent Account Name');
        }
    }
    @isTest
    static void testLeadUpdateParentAccountBatchSched() {
        String CRON_EXP = '0 0 0 15 3 ? *';
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_Id__c = TEST_BUSINESS_ID_1;
            insert testLead;
            String jobId = System.schedule('CDdLeadUpdateParentAccountBatchSched',  CRON_EXP, new CDdLeadUpdateParentAccountBatchSched(10));            
            Test.stopTest();
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            Lead leadFromDB = [SELECT Id, Name, Parent_Account__c FROM Lead WHERE Id = :testLead.Id];
            System.assertEquals(true, leadFromDB.Parent_Account__c==null, 'Expecting Lead to be not associated with a Parent Account');
        }
    }            
}