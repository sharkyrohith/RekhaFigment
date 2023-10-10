@isTest
public class CDdSSMOQuoteControllerTest {
	
    @testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
    }
    
    static void initUserData(){
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
     
    static void initData(Boolean isValidData){

		Product2 testProduct = new Product2(Name='Test Product',SSMO_Eligible__c=false);
        if(isValidData){
        	testProduct.SSMO_Eligible__c = true;    
        }
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
                                          Email = 'testUser3@test.com',
                                          Language__c = 'English',
                                          AccountId = testAccounts[0].Id);
        insert testContact;
        
        Opportunity testOppty = new Opportunity(AccountId = testAccounts[0].Id,Decision_Maker__c=testContact.Id, of_Addressable_Locations__c=2,POS_System__c = 'Clover',
                                                Name='Test CPQOpp', StageName='Open',Order_Protocol__c = 'Other',Exclusivity_End_Date__c=System.today()+10,
                                                CloseDate=Date.today().addDays(30));
        if(isValidData){
			testOppty.of_Addressable_Locations__c = 1;
            testOppty.POS_System__c = null;
            testOppty.Order_Protocol__c = 'Email';            
        }
        insert testOppty;
        
        OpportunityContactRole opptyContRole = new OpportunityContactRole(OpportunityId=testOppty.Id,ContactId=testContact.Id,Role='Decision Maker', IsPrimary=true);
        insert opptyContRole;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Account__c = testAccounts[0].Id,User_Group__c ='USD Inside Presales',
                                                      SBQQ__Opportunity2__c = testOppty.Id,
                                                      SBQQ__StartDate__c = Date.today(),
                                                      SBQQ__EndDate__c = Date.today().addMonths(12));
        if(isValidData){
            testQuote.SBQQ__Status__c = 'Approved';
            testQuote.PactSafe_Contract_Type__c = CDdSSMOQuoteConstants.REP_ENABLED_SSMO_LIST[0];
            testQuote.SBQQ__Primary__c = true;    
        }
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

    @isTest static void testQuoteValidations(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData(false);
            Test.startTest();
            
            Opportunity opptyRecord = [Select Id,Name,AccountId from Opportunity Where Account.Name Like 'Test Account SSMO Quote%' limit 1];
            List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            pactsafe1__PactSafeRequest__c pactsafeRequest = new pactsafe1__PactSafeRequest__c(Quote__c=quotes[0].Id,pactsafe1__Opportunity__c=opptyRecord.Id);
            insert pactsafeRequest;
            
            quotes[0].Experience__c = 'Caviar';
            update quotes[0];
            
            Account act = new Account(Id=opptyRecord.AccountId,Deck_Rank__c = 'Ace');
            update act;
            
            quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Custom_SSMO_Link__c,SBQQ__Opportunity2__r.of_Addressable_Locations__c, SBQQ__Opportunity2__r.Account.BillingCountry,SBQQ__Opportunity2__r.POS_System__c,SBQQ__Primary__c,SBQQ__Opportunity2__r.Order_Protocol__c,
                      					SBQQ__Opportunity2__r.DRN__c,SBQQ__Opportunity2__r.Proposed_Date_of_Activation__c,Experience__c,
                                        (SELECT Id from PactSafe_Requests__r WHERE pactsafe1__Expired__c = FALSE LIMIT 1),
                                        (SELECT Id,SBQQ__Product__c,SBQQ__Product__r.SSMO_Eligible__c FROM SBQQ__LineItems__r) 
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            List<String> validationErrors = CDdSSMOQuoteController.validateQuoteData(quotes[0]); 
            System.assert(validationErrors.size() > 0,'Quote validation should return errors');
            
            Product2 testProduct = [Select Id from Product2 where Name='Test Product' limit 1];
            testProduct.SSMO_Eligible__c = true;
			update testProduct;
            
            delete pactsafeRequest;
            
            act.Deck_Rank__c = null;
            update act;
            
            opptyRecord.of_Addressable_Locations__c = 1;
            opptyRecord.POS_System__c = null;
            opptyRecord.Order_Protocol__c = 'Email';
            update opptyRecord;
            
            quotes[0].Experience__c = null;
            quotes[0].SBQQ__Status__c = 'Approved';
            quotes[0].PactSafe_Contract_Type__c = CDdSSMOQuoteConstants.REP_ENABLED_SSMO_LIST[0];
            quotes[0].SBQQ__Primary__c = true;
            update quotes[0];
            
            quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Custom_SSMO_Link__c,SBQQ__Opportunity2__r.of_Addressable_Locations__c, SBQQ__Opportunity2__r.Account.BillingCountry,SBQQ__Opportunity2__r.POS_System__c,SBQQ__Primary__c,SBQQ__Opportunity2__r.Order_Protocol__c,
                                        SBQQ__Opportunity2__r.DRN__c,SBQQ__Opportunity2__r.Proposed_Date_of_Activation__c,Experience__c,
                      					(SELECT Id from PactSafe_Requests__r  WHERE pactsafe1__Expired__c = FALSE LIMIT 1),
                                        (SELECT Id,SBQQ__Product__c,SBQQ__Product__r.SSMO_Eligible__c FROM SBQQ__LineItems__r) 
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            validationErrors = CDdSSMOQuoteController.validateQuoteData(quotes[0]);
            System.assert(validationErrors.size() == 0, 'There should be no validation errors');
            
            Test.stopTest();
        }
    }
    
    @isTest static void testSendQuote1(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData(true);
            
            Opportunity opptyRecord = [Select Id,Name from Opportunity Where Account.Name Like 'Test Account SSMO Quote%' limit 1];
            List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            pactsafe1__PactSafeRequest__c pactsafeRequest = new pactsafe1__PactSafeRequest__c(Quote__c=quotes[0].Id,pactsafe1__Opportunity__c=opptyRecord.Id,pactsafe1__Expired__c=TRUE);
            insert pactsafeRequest;
            
            quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Custom_SSMO_Link__c,SBQQ__Opportunity2__r.of_Addressable_Locations__c, SBQQ__Opportunity2__r.Account.BillingCountry,SBQQ__Opportunity2__r.POS_System__c,SBQQ__Primary__c,SBQQ__Opportunity2__r.Order_Protocol__c,
                                        SBQQ__Opportunity2__r.DRN__c,SBQQ__Opportunity2__r.Proposed_Date_of_Activation__c,Experience__c,
                      					(SELECT Id from PactSafe_Requests__r  WHERE pactsafe1__Expired__c = FALSE LIMIT 1),
                                        (SELECT Id,SBQQ__Product__r.SSMO_Eligible__c FROM SBQQ__LineItems__r) 
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            Test.startTest();
            String body = '{}';
            SSMOQuoteMockHttpResponse mockInstance = new SSMOQuoteMockHttpResponse(body,200,'Ok');
            Test.setMock(HttpCalloutMock.class, mockInstance);
            
            CDdSSMOQuoteController.ResultMessageWrapper resultMessage = CDdSSMOQuoteController.validateQuoteAndSendToSSMO(quotes[0].Id);
            System.assert(resultMessage.status == 'success', 'Response status should be "success"');
            Test.stopTest();
        }
    }
    
    @isTest static void testSendQuote2(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData(true);
            
            
            Opportunity opptyRecord = [Select Id,Name from Opportunity Where Account.Name Like 'Test Account SSMO Quote%' limit 1];
            List<SBQQ__Quote__c> quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Custom_SSMO_Link__c,SBQQ__Opportunity2__r.of_Addressable_Locations__c, SBQQ__Opportunity2__r.Account.BillingCountry,SBQQ__Opportunity2__r.POS_System__c,SBQQ__Primary__c,SBQQ__Opportunity2__r.Order_Protocol__c,
                                        SBQQ__Opportunity2__r.DRN__c,SBQQ__Opportunity2__r.Proposed_Date_of_Activation__c,Experience__c,
                                        (SELECT Id from PactSafe_Requests__r  WHERE pactsafe1__Expired__c = FALSE LIMIT 1),
                                        (SELECT Id,SBQQ__Product__r.SSMO_Eligible__c FROM SBQQ__LineItems__r) 
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            Test.startTest();
            String body = '{}';
            SSMOQuoteMockHttpResponse mockInstance = new SSMOQuoteMockHttpResponse(body,400,'Bad request');
            Test.setMock(HttpCalloutMock.class, mockInstance);
            
            CDdSSMOQuoteController.ResultMessageWrapper resultMessage = CDdSSMOQuoteController.validateQuoteAndSendToSSMO(quotes[0].Id);
            System.assert(resultMessage.status == 'failed', 'Response status should be "failed"');
            Test.stopTest();
        }
    }
    
    @isTest static void testSendQuote3(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData(true);
            
            
            Opportunity opptyRecord = [Select Id,Name from Opportunity Where Account.Name Like 'Test Account SSMO Quote%' limit 1];
            List<SBQQ__Quote__c> quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Custom_SSMO_Link__c,SBQQ__Opportunity2__r.of_Addressable_Locations__c, SBQQ__Opportunity2__r.Account.BillingCountry,SBQQ__Opportunity2__r.POS_System__c,SBQQ__Primary__c,SBQQ__Opportunity2__r.Order_Protocol__c,
                                        SBQQ__Opportunity2__r.DRN__c,SBQQ__Opportunity2__r.Proposed_Date_of_Activation__c,Experience__c,
                                        (SELECT Id from PactSafe_Requests__r  WHERE pactsafe1__Expired__c = FALSE LIMIT 1),
                                        (SELECT Id,SBQQ__Product__r.SSMO_Eligible__c FROM SBQQ__LineItems__r) 
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            Test.startTest();
            String body = '{"error_message": "SSMO signup not found"}';
            SSMOQuoteMockHttpResponse mockInstance = new SSMOQuoteMockHttpResponse(body,400,'Bad request');
            Test.setMock(HttpCalloutMock.class, mockInstance);
            
            CDdSSMOQuoteController.ResultMessageWrapper resultMessage = CDdSSMOQuoteController.validateQuoteAndSendToSSMO(quotes[0].Id);
            System.assert(resultMessage.messages[0] == 'SSMO signup not found', 'Response message should have "SSMO signup not found"');
            Test.stopTest();
        }
    }
    
    @isTest static void testSendQuote4(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData(true);
            
            
            Opportunity opptyRecord = [Select Id,Name from Opportunity Where Account.Name Like 'Test Account SSMO Quote%' limit 1];
            List<SBQQ__Quote__c> quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Custom_SSMO_Link__c,SBQQ__Opportunity2__r.of_Addressable_Locations__c, SBQQ__Opportunity2__r.Account.BillingCountry,SBQQ__Opportunity2__r.POS_System__c,SBQQ__Primary__c,SBQQ__Opportunity2__r.Order_Protocol__c,
                                        SBQQ__Opportunity2__r.DRN__c,SBQQ__Opportunity2__r.Proposed_Date_of_Activation__c,Experience__c,
                                        (SELECT Id from PactSafe_Requests__r  WHERE pactsafe1__Expired__c = FALSE LIMIT 1),
                                        (SELECT Id,SBQQ__Product__r.SSMO_Eligible__c FROM SBQQ__LineItems__r) 
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            Test.startTest();
            String body = '{}';
            SSMOQuoteMockHttpResponse mockInstance = new SSMOQuoteMockHttpResponse(body,500,'Server Error');
            Test.setMock(HttpCalloutMock.class, mockInstance);
            
            CDdSSMOQuoteController.ResultMessageWrapper resultMessage = CDdSSMOQuoteController.validateQuoteAndSendToSSMO(quotes[0].Id);
            System.assert(resultMessage.status == 'failed', 'Response status should be "failed"');
            Test.stopTest();
        }
    }
    
    @isTest static void testRecallQuoteSuccess(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData(true);
            
            
            Opportunity opptyRecord = [Select Id,Name from Opportunity Where Account.Name Like 'Test Account SSMO Quote%' limit 1];
            List<SBQQ__Quote__c> quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.SSMO_UUID__c,SBQQ__Opportunity2__r.Decision_Maker__r.Email,SBQQ__Opportunity2__r.Owner.Email,SBQQ__Opportunity2__r.Decision_Maker__c  
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            Test.startTest();
            String body = '{}';
            SSMOQuoteMockHttpResponse mockInstance = new SSMOQuoteMockHttpResponse(body,200,'Ok');
            Test.setMock(HttpCalloutMock.class, mockInstance);
            
            CDdSSMOQuoteController.ResultMessageWrapper resultMessage = CDdSSMOQuoteController.recallQuote(quotes[0].Id);
            System.assert(resultMessage.status == 'success', 'Response status should be "success"');
            Test.stopTest();
        }
    }
	
    @isTest static void testRecallQuoteFail(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData(true);
            
            
            Opportunity opptyRecord = [Select Id,Name from Opportunity Where Account.Name Like 'Test Account SSMO Quote%' limit 1];
            List<SBQQ__Quote__c> quotes = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.SSMO_UUID__c,SBQQ__Opportunity2__r.Decision_Maker__r.Email,SBQQ__Opportunity2__r.Owner.Email,SBQQ__Opportunity2__r.Decision_Maker__c  
                                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opptyRecord.Id Order by SBQQ__EndDate__c];
            
            Test.startTest();
            String body = '{}';
            SSMOQuoteMockHttpResponse mockInstance = new SSMOQuoteMockHttpResponse(body,500,'Server Error');
            Test.setMock(HttpCalloutMock.class, mockInstance);
            
            CDdSSMOQuoteController.ResultMessageWrapper resultMessage = CDdSSMOQuoteController.recallQuote(quotes[0].Id);
            System.assert(resultMessage.status == 'failed', 'Response status should be "failed"');
            Test.stopTest();
        }
    }
    /** 
    * @description Create Http Mock Response for successful response from Bulk Store Update API
    */
    public class SSMOQuoteMockHttpResponse implements HttpCalloutMock {
        private String body;
        private Integer code;
        private String statusMsg;
        
        // constructor
        public SSMOQuoteMockHttpResponse(String body,Integer code, String statusMsg){
            this.body = body;
            this.code = code;
            this.statusMsg = statusMsg;
        }
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.body);
            res.setStatus(this.statusMsg);
            res.setStatusCode(this.code);
            return res;
        }        
    }
}