/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 01-28-2022
 * @last modified by  : Nathalie Mendezona
**/
@isTest
public class Test_Opp_Action_Extension {
    
    public static testMethod void Test_Opp_Action_Extension(){
        Opportunity opp = new Opportunity();
        System.runAs(new User(Id=UserInfo.getUserId())) {
            Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
            cp.Name = 'Main';
            cp.Opportunity_Trigger_Enabled__c = true;
            cp.Account_Trigger_Enabled__c = true;
            upsert cp;

            Account acct = new Account();
            acct.Name = 'Test Opp - DropIn methods';
            acct.BillingState = 'TX';
            insert acct;

            opp.AccountId = acct.id;
            opp.Name = 'test opp12341';
            opp.StageName = 'Prospecting';
            opp.CloseDate = system.date.today();
            opp.Amount = 10000;
            opp.commission__c = 10;
            opp.Inflation__c = 10;
            opp.Lead_Source_Detail__c = 'Formstack';
            opp.Menu_to_be_completed_by__c = null;
            opp.Menu_Setup_Method__c =  null;
            opp.Tablet_Kit_Type__c = null;
            insert opp;
        }

        PageReference pref = Page.Opp_Action_DropIn;
        Test.setCurrentPage(pref);

        User runAsUser = TDdUserFactory.createUsers(1)[0];

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        Opp_Action_Extension ext  = new Opp_Action_Extension(stdController);
        
        system.runAs(runAsUser){
            Test.startTest();
            
            PageReference ref = ext.dropInEvent();
            
            test.stopTest();
        }
    }

}