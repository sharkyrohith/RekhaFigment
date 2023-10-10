/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 01-28-2022
 * @last modified by  : Nathalie Mendezona
**/
@isTest
public class Test_Acct_Action_Extension {

    public static testMethod void Test_Acct_Action_Extension(){
        Account acct = new Account();
        System.runAs(new User(Id=UserInfo.getUserId())) {
            Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
            cp.Name = 'Main';
            cp.Opportunity_Trigger_Enabled__c = true;
            cp.Account_Trigger_Enabled__c = true;
            upsert cp;

            acct.Name = 'Test Acct - DropIn methods';
            acct.BillingState = 'TX';
            insert acct;
        }
        
        PageReference pref = Page.Acct_Action_DropIn;
        Test.setCurrentPage(pref);
        
        User runAsUser = TDdUserFactory.createUsers(1)[0];

        ApexPages.StandardController stdController = new ApexPages.StandardController(acct);
        Acct_Action_Extension ext  = new Acct_Action_Extension(stdController);

        System.runAs(runAsUser){
            Test.startTest();

            PageReference ref = ext.dropInEvent();

            test.stopTest();
        }
    }

}