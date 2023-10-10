@isTest
private class AQS_ItemsToApproveControllerTest
{
    @testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
    }
    
    @isTest static void testDataInit()
    {
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        // BZAP-13768: user requires manager with an Approver_Group_API__c field set to insert approval records.
        User testManager = new User(
            Alias = 'test',
            Email='testUser1@test.com', 
            EmailEncodingKey='UTF-8',
            LastName='Carlos',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='userEmail4305@test.com',
            Approver_Group_API__c = '20xd6' // <<
        );
        insert testManager;

        User testUser = new User(
            Alias = 'test',
            Email='testUser2@test.com', 
            EmailEncodingKey='UTF-8',
            LastName='TestLastName',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='userEmail4306@test.com',
            ManagerId = testManager.Id
        );
        insert testUser;

        //add user to a group
        Group testGroup = new Group(Name = 'testGroup');
        insert testGroup;

        GroupMember testMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = testUser.Id);
        insert testMember;


		Set<Id> users = new Set<Id>();
        users.add(testUser.Id);
        
        System.runAs(testUser)
        {
            
            Product2 testProduct = new Product2(Name='Test Product');    
            insert testProduct;

            Pricebook2 pricebook2 = new Pricebook2();
            pricebook2.Id = Test.getStandardPricebookId();
            pricebook2.IsActive = true;
            update pricebook2;
             
            List<Account> testAccounts = TDdAccountFactory.createAccounts('Test Account', 1);
            insert testAccounts;
            
            Contact testContact = new Contact(FirstName = 'Test First Name',
                                                LastName='Test Last Name',
                                                AccountId = testAccounts[0].Id);
            insert testContact;
            
            Opportunity testOppty = new Opportunity(AccountId = testAccounts[0].Id, 
                                                    Name='Test CPQOpp', StageName='Open',
                                                    CloseDate=Date.today().addDays(30));
            insert testOppty;
            
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Account__c = testAccounts[0].Id,
                                                    SBQQ__Opportunity2__c = testOppty.Id,
                                                    SBQQ__StartDate__c = Date.today(),
                                                    SBQQ__EndDate__c = Date.today().addMonths(12));
            insert testQuote;

            SBQQ__Quote__c testQuote2 = new SBQQ__Quote__c(SBQQ__Account__c = testAccounts[0].Id,
                                                    SBQQ__Opportunity2__c = testOppty.Id,
                                                    SBQQ__StartDate__c = Date.today(),
                                                    SBQQ__EndDate__c = Date.today().addMonths(12));
            insert testQuote2;

            
            SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__StartDate__c = Date.today(),
                                                                    SBQQ__EndDate__c = Date.today().addMonths(12),
                                                                    SBQQ__Product__c = testProduct.Id,                                                      
                                                                    SBQQ__Quote__c = testQuote.Id);
            insert testQuoteLine;

            
            SBAA__ApprovalRule__c testApprovalRuleQuote = new SBAA__ApprovalRule__c(Name='Test Approval Rule',
                                                                                SBAA__TargetObject__c = 'SBQQ__Quote__c',
                                                                                SBAA__ApprovalStep__c = 10);
            insert testApprovalRuleQuote;

            
            SBAA__Approver__c testApprover = new SBAA__Approver__c(Name = UserInfo.getUserName(),
                                                                    SBAA__User__c = UserInfo.getUserId());
            insert testApprover;
            
            SBAA__Approval__c testQuoteApproval = new SBAA__Approval__c(SBAA__Status__c = 'Requested',
                                                                    SBAA__RecordField__c = 'AQS_Quote__c',
                                                                    SBAA__ApprovalStep__c = 10,
                                                                    SBAA__Rule__c = testApprovalRuleQuote.Id,
                                                                    SBAA__AssignedTo__c = UserInfo.getUserId(),
                                                                    AQS_Quote__c = testQuote.Id );

            insert testQuoteApproval;

            SBAA__Approval__c testQuoteApproval2 = new SBAA__Approval__c(SBAA__Status__c = 'Approved',
                                                                    SBAA__RecordField__c = 'AQS_Quote__c',
                                                                    SBAA__ApprovalStep__c = 10,
                                                                    SBAA__Rule__c = testApprovalRuleQuote.Id,
                                                                    SBAA__AssignedTo__c = UserInfo.getUserId(),
                                                                    AQS_Quote__c = testQuote2.Id );

            insert testQuoteApproval2;
          
             
            Test.startTest();
            AQS_ItemsToApproveController testController = new AQS_ItemsToApproveController(); 
            testController.getGroups(users);
            Test.stopTest();
        }
    }
}