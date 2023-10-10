@isTest
public class CDdSSMOLinkControllerTest {
	
    @testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
    }
    
    @isTest static void initUserData(){
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testManager = new User(
                Alias = 'test',
                Email='testUser1@test.com', 
                EmailEncodingKey='UTF-8',
                LastName='Carlos',
                FirstName = 'Perez',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = testProfile.Id,
                TimeZoneSidKey='America/Los_Angeles',
                UserName='userEmail_SSMOQuote1@test.com',
                Approver_Group_API__c = '20xd6' 
            );
            insert testManager;
        
        User testUser = new User(
                Alias = 'test',
                Email='testUser2@test.com', 
                EmailEncodingKey='UTF-8',
                LastName='TestLastName',
                FirstName = 'TestFirstName',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = testProfile.Id,
                TimeZoneSidKey='America/Los_Angeles',
                UserName='userEmail_SSMOQuote2@test.com',
                ManagerId = testManager.Id
            );
         insert testUser;

        //add user to a group
        Group testGroup = new Group(Name = 'testGroup');
        insert testGroup;

        GroupMember testMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = testUser.Id);
        insert testMember;
    }
    
    @isTest static void initData(){

		Product2 testProduct = new Product2(Name='Test Product',SSMO_Eligible__c=true);    
        insert testProduct;
        
        Pricebook2 pricebook2 = new Pricebook2();
        pricebook2.Id = Test.getStandardPricebookId();
        pricebook2.IsActive = true;
        update pricebook2;
        
        List<Account> testAccounts = TDdAccountFactory.createAccounts('Test Account SSMO Quote', 1);
        testAccounts[0].BillingCountry  = 'United States';
        insert testAccounts;
        
        Contact testContact = new Contact(FirstName = 'Test First Name',
                                          LastName='Test Last Name',
                                          Phone = '123-123-1234',
                                          Email = null,
                                          Language__c = 'English',
                                          AccountId = testAccounts[0].Id);
        insert testContact;
        
        Opportunity testOppty = new Opportunity(AccountId = testAccounts[0].Id, Number_of_Stores__c=1,POS_System__c = null,
                                                Name='Test CPQOpp', StageName='Open',Order_Protocol__c = 'Email',Exclusivity_End_Date__c=System.today()+10,
                                                CloseDate=Date.today().addDays(30));
        insert testOppty;
        
        OpportunityContactRole opptyContRole = new OpportunityContactRole(OpportunityId=testOppty.Id,ContactId=testContact.Id,Role='Decision Maker', IsPrimary=true);
        insert opptyContRole;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Account__c = testAccounts[0].Id,User_Group__c ='USD Inside Presales',
                                                      SBQQ__Opportunity2__c = testOppty.Id,
                                                      SBQQ__StartDate__c = Date.today(),
                                                      SBQQ__EndDate__c = Date.today().addMonths(12));
        insert testQuote;
        
        SBQQ__Quote__c testQuote2 = new SBQQ__Quote__c(SBQQ__Account__c = testAccounts[0].Id,User_Group__c ='USD Inside Presales',
                                                       SBQQ__Opportunity2__c = testOppty.Id,
                                                       SBQQ__StartDate__c = Date.today(),
                                                       SBQQ__EndDate__c = Date.today().addMonths(20));
        insert testQuote2;
        
        
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__StartDate__c = Date.today(),
                                                                  SBQQ__EndDate__c = Date.today().addMonths(12),
                                                                  SBQQ__Product__c = testProduct.Id,                                                      
                                                                  SBQQ__Quote__c = testQuote.Id);
        insert testQuoteLine;
        
	}
    
    @isTest
    static void testSSMOLinkEmail(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData();
            
            Opportunity opptyRecord = [Select Id,Name,AccountId from Opportunity Where Account.Name Like 'Test Account SSMO Quote%' limit 1];
            Contact contRecord = [Select Id from Contact Where AccountId = :opptyRecord.AccountId limit 1];
            List<SBQQ__Quote__c> quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Custom_SSMO_Link__c,SBQQ__Opportunity2__r.Number_of_Stores__c, SBQQ__Opportunity2__r.Account.BillingCountry,SBQQ__Opportunity2__r.POS_System__c,
                                        (SELECT Id from PactSafe_Requests__r LIMIT 1),
                                        (SELECT Id,SBQQ__Product__r.SSMO_Eligible__c FROM SBQQ__LineItems__r) 
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            quotes[0].SBQQ__Status__c = 'Approved';
            quotes[0].PactSafe_Contract_Type__c = CDdSSMOQuoteConstants.REP_ENABLED_SSMO_LIST[0];
            update quotes[0];
            
            Test.startTest();
            
            
            CDdSSMOLinkController.ResultMessageWrapper resultMessage = CDdSSMOLinkController.sendSSMOLink(opptyRecord.Id);
            System.assert(resultMessage.messages.size() > 0);
            
            opptyRecord.Decision_Maker__c=contRecord.Id;
            opptyRecord.Custom_SSMO_Link__c = 'https://www.test.com';
            opptyRecord.PactSafe_Contract_Type__c = CDdSSMOQuoteConstants.REP_ENABLED_SSMO_LIST[0];
            update opptyRecord;
            
            contRecord.Email = 'testUser3@test.com';
            update contRecord;
            
            resultMessage = CDdSSMOLinkController.sendSSMOLink(opptyRecord.Id);
            System.assert(resultMessage.messages.size() == 0);
            
            Test.stopTest();
            
        }
    }
    
}