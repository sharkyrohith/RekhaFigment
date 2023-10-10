/**
 * @description       : 
 * @author            :
 * @group             : 
 * @last modified on  : 01-28-2022
 * @last modified by  : Nathalie Mendezona
**/
@isTest
public class Test_Contact_Action_Extension {
    
    @testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
    }
    
    public static testMethod void Test_Contact_Action_Extension(){
        Contact c = new Contact();
        System.runAs(new User(Id=UserInfo.getUserId())) {
            Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
            cp.Name = 'Main';
            cp.Opportunity_Trigger_Enabled__c = true;
            cp.Account_Trigger_Enabled__c = true;
            upsert cp;

            Account acct = new Account();
            acct.Name = 'Test Contact - DropIn methods';
            acct.BillingState = 'TX';
            insert acct;

            c.FirstName = 'Paul';
            c.LastName = 'wall';
            c.Email = 'acad2r@adf.com';
            c.AccountId = acct.id;
            insert c;
        }

        PageReference pref = Page.Contact_Action_DropIn;
        Test.setCurrentPage(pref);

        User runAsUser = TDdUserFactory.createUsers(1)[0];

        ApexPages.StandardController stdController = new ApexPages.StandardController(c);
        Contact_Action_Extension ext  = new Contact_Action_Extension(stdController);
        
        system.runAs(runAsUser){
        Test.startTest();
        
        PageReference ref = ext.dropInEvent();
        
        test.stopTest();
        }
    }

}