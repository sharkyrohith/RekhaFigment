/**
 * @description       : BZAP-19008/ As per this ticket we have to update the Opportunity Stage to Closed Won whenever it is Contract Signed if its a SSMO opportunity and 
 * 						that Opportunity has Integration_Auto_close__c = true and this SSMO opportunity has to be created by Mulesoft user.
 * 						Reasons for Creating a new Test class for Opportunity Trigger
 * 						1. When we try to create the Opportunity/Quote/Quote Line Item and And again update opportunity in same test method, 
 * 						   our Trigger recussrion variable is bypassing the trigger execution for the Opportunity stage updates - this is causing test failures
 * 						2. When we try to insert the pre-requisite data(New CPQ opportunity creation) in the setup method of the existing handler test class the whole class fails with APEX CPU Limits
 * 						3. We have the same issues with the "CDdOpportunityTriggerAdditionalTest" class - so not able to add over there
 * 						4. We have another class called "CDdOpportunityTriggerAdditionalTest" but this class has all test methods with SeeAllData = true, - so not able to add over there.
 * @author            : Krishna Sanisetty
 * @group             : 
 * @Created on        : 03-01-2023
 * @last modified by  : 
**/
@isTest
public class CDdOpportunityTriggerHandlerTest2 {
	private static final string OPPORTUNITY_NAME = 'TestSSMOCPQOpp';
    @testsetup
    static void testsetup(){
        User muleIntegrationUser = [SELECT Id FROM User WHERE alias = 'mule'];
        System.runAs(muleIntegrationUser){
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            validation.Bypass_Account_Validations__c = true;
            insert validation;      
            Test.startTest();
            List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
            insert accounts;
    
            Product2 product = TDdCPQTestDataFactory.createProduct(true);
            Pricebook2 pricebook2 = new Pricebook2();
            pricebook2.Id = Test.getStandardPricebookId();
            pricebook2.IsActive = true;
            update pricebook2;
            PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, pricebook2, 'USD', true);

            Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT(OPPORTUNITY_NAME, accounts[0].Id, null, 'New', 'ML_Inside_Sales', false);
            testOpp.Tablet_Delivery_Method__c = '';
            testOpp.Tablet_Kit_Type__c = '';
            testOpp.Notes__c = 'Test Notes';
            testOpp.Order_Protocol__c = '';
            testOpp.Pricing_Structure__c = 'Commission';
            testOpp.Planned_Integration_Path__c = 'Drive Form';
            testOpp.Payment_Protocol__c = 'Credit Card';
            testOpp.Accepts_Tips__c = 'Yes';
            testOpp.Catering_setup_exists__c = 'Yes';
            testOpp.Current_Delivery_Channels__c = 'None';
            testOpp.Type = 'Weblinks';
            testOpp.Contact_Manager_Owner_Name__c = 'Test User';
            testOpp.Contact_Manager_Owner_Email__c = 'test@test.com';
            testOpp.Integration_Auto_Close__c = true ;
            insert testOpp;
            
            Test.stopTest();
            
            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, false);
            quote.SBQQ__Status__c = 'Contract Signed';
            quote.ApprovalStatus__c = 'Approved';
            insert quote;
    
            SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
            
            quoteLine.Original_Commission__c = 0.54;
            insert quoteLine;
        }
    }
    @isTest
    static void test_contractSignedAutoMoveToCloseWon(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        insert validation;   
        
        Opportunity opp = [SELECT Id FROM Opportunity where Name =: OPPORTUNITY_NAME];
        
        Test.startTest();
        opp.StageName = CDdOpportunityTriggerHelper.STAGE_NAME_CONTRACT_SIGNED;
        update opp;
        Test.stopTest();
        
        Opportunity oppty = [SELECT Id, StageName FROM Opportunity WHERE Id =: opp.Id];
        System.assertEquals('Closed Won', oppty.StageName);
        
    }
}