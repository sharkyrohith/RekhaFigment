/**
* @author Tia Xuan	
* @date 2019-06
*
* @description Test class for CDdDripTextMessageBatch, CDdDripTextMessageBatchSched
*/

@isTest
public class CDdDripTextMessageTest {
    
    @testSetup static void createObjects() {
        vCS__c s = VTestUtil.createVeltigSettings();
        insert s;
        
		Account acct = VTestUtil.createAccount('Test Account', true);
        acct.Deck_Rank__c = 'Queen';
        insert acct; 
        
        Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
        insert ctc;
        
        Opportunity opp = TDdOpportunityFactory.createOpportunity('Test Won Opp', acct.Id, ctc.Id, 'Closed Won');
        opp.OwnerId = [SELECT Id, UserRoleId FROM User WHERE UserRoleId != null LIMIT 1].Id;
        insert opp;
	}
    
    /**
	* @description testing condition 1 from batch class
	*/
    @isTest 
    static void testCond1() {
        
        Account acct = [select Id from Account limit 1];
        acct.Currently_Active__c = 'No';
        update acct; 
        
        Contact ctc = [select Id from Contact limit 1];
        
        Opportunity opp = [select Id from Opportunity limit 1];
        opp.AutoSMS_MenuComplete__c = DateTime.now().addDays(-2);
        update opp; 
        
        Test.startTest(); 

        CDdDripTextMessageBatchSched sh1 = new CDdDripTextMessageBatchSched();
		String sch = '0 0 23 * * ?'; 
        system.schedule('Test Drip Text Message', sch, sh1);

        Test.stopTest(); 
    }
    
    /**
	* @description testing condition 2 from batch class
	*/
    @isTest 
    static void testCond2() {
        
        Account acct = [select Id from Account limit 1];
        acct.Currently_Active__c = 'No';
        update acct; 
        
        Contact ctc = [select Id from Contact limit 1];
        
        Opportunity opp = [select Id from Opportunity limit 1];
        opp.AutoSMS_MenuComplete__c = DateTime.now().addDays(-4);
        update opp; 
        
        Test.startTest(); 

        CDdDripTextMessageBatchSched sh1 = new CDdDripTextMessageBatchSched();
		String sch = '0 0 23 * * ?'; 
        system.schedule('Test Drip Text Message', sch, sh1);

        Test.stopTest(); 
    }
    
    /**
	* @description testing condition 3 from batch class
	*/
    @isTest 
    static void testCond3() {
        
        Account acct = [select Id from Account limit 1];
        acct.Currently_Active__c = 'Yes';
        update acct; 
        
        Contact ctc = [select Id from Contact limit 1];
        
        Opportunity opp = [select Id from Opportunity limit 1];
        opp.AutoSMS_MenuComplete__c = DateTime.now().addDays(-2);
        update opp;
        
        Test.startTest(); 

        CDdDripTextMessageBatchSched sh1 = new CDdDripTextMessageBatchSched();
		String sch = '0 0 23 * * ?'; 
        system.schedule('Test Drip Text Message', sch, sh1);

        Test.stopTest(); 
    }
    
     /**
	* @description testing condition 4 from batch class
	*/
    @isTest 
    static void testCond4() {
        
        Account acct = [select Id from Account limit 1];
        acct.Deck_Rank__c = 'King';
        acct.Currently_Active__c = 'Yes';
        update acct; 
        
        Contact ctc = [select Id from Contact limit 1];
        
        Opportunity opp = [select Id from Opportunity limit 1];
        opp.AutoSMS_MenuComplete__c = DateTime.now().addDays(-2);
        update opp;
        
        Test.startTest(); 

        CDdDripTextMessageBatchSched sh1 = new CDdDripTextMessageBatchSched();
		String sch = '0 0 23 * * ?'; 
        system.schedule('Test Drip Text Message', sch, sh1);

        Test.stopTest(); 
    }

}