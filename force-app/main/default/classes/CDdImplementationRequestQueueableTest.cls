@isTest
public class CDdImplementationRequestQueueableTest {
	private Static Map<string, Schema.RecordTypeInfo> oppRecTypeMap = Opportunity.SobjectType.getDescribe().getRecordTypeInfosByName();
    private Static Map<string, Schema.RecordTypeInfo> accountRecTypeMap = Account.SobjectType.getDescribe().getRecordTypeInfosByName();
    private Static Map<String, Schema.RecordTypeInfo> IR_RT_INFO_BY_NAME = Schema.SObjectType.Implementation_Request__c.getRecordTypeInfosByName();
    
    public static final Id mlInsideSalesId = oppRecTypeMap.get('Marketplace').getRecordTypeId();
    public static final Id accRecordTypeId = accountRecTypeMap.get('Marketplace').getRecordTypeId();
    public static final Id nvOSARecordTypeId = IR_RT_INFO_BY_NAME.get('NV OSA').getRecordTypeId();
    
    @testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
        Id categoryRecordTypeId = Schema.SObjectType.Vertical_Category__c.getRecordTypeInfosByDeveloperName().get('Category').getRecordTypeId();
        
        // Insert parent categories
        List<Vertical_Category__c> parentCategoryList = new List<Vertical_Category__c>();
        Vertical_Category__c parentCategory1 = new Vertical_Category__c(Name = 'Alcohol', RecordTypeId = categoryRecordTypeId);
        Vertical_Category__c parentCategory2 = new Vertical_Category__c(Name = 'Flowers', RecordTypeId = categoryRecordTypeId);
        Vertical_Category__c parentCategory3 = new Vertical_Category__c(Name = 'Grocery', RecordTypeId = categoryRecordTypeId);
        Vertical_Category__c parentCategory4 = new Vertical_Category__c(Name = 'Pets', RecordTypeId = categoryRecordTypeId);
        parentCategoryList.add(parentCategory1);
        parentCategoryList.add(parentCategory2);
        parentCategoryList.add(parentCategory3);
        parentCategoryList.add(parentCategory4);
        insert parentCategoryList;

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
     
    static void initData(String primaryMerchantCategory,String StageName,Boolean isAsync){
		
        Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
        ftrFlag.Enable_Implementation_Request_Async__c = isAsync;
        upsert ftrFlag;
        
		List<Account> testAccounts = TDdAccountFactory.createAccounts('Test Account Impl Request', 1);
        testAccounts[0].BillingCountry  = 'United States';
        testAccounts[0].Merchant_Categories__c = 'Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery';
        testAccounts[0].Primary_Merchant_Categories__c = primaryMerchantCategory;
        testAccounts[0].RecordTypeId = accRecordTypeId;
        insert testAccounts;
        
        Contact testContact = new Contact(FirstName = 'Test First Name',
                                          LastName='Test Last Name',
                                          Phone = '123-123-1234',
                                          Email = 'testUser3@test.com',
                                          Language__c = 'English',
                                          AccountId = testAccounts[0].Id);
        insert testContact;
        
        Opportunity testOppty = new Opportunity(AccountId = testAccounts[0].Id,Decision_Maker__c=testContact.Id, of_Addressable_Locations__c=2,POS_System__c = 'Clover',
                                                Name='Test CPQOpp', StageName=StageName,Order_Protocol__c = 'Other',Exclusivity_End_Date__c=System.today()+10,
                                                CloseDate=Date.today().addDays(30),RecordTypeId=mlInsideSalesId);
        
		testOppty.of_Addressable_Locations__c = 1;
        testOppty.POS_System__c = null;
        testOppty.Order_Protocol__c = 'Email';            
        insert testOppty;
    }
    
    @isTest static void testImplementationRequest_CreateRecord(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData('Alcohol','Open',true);
            Test.startTest();
            Opportunity opptyRecord = [Select Id,Name,AccountId from Opportunity Where Account.Name Like 'Test Account Impl Request%' limit 1];
            opptyRecord.StageName = 'Contract Signed';
            update opptyRecord;
            Test.stopTest();
            
            opptyRecord = [Select Id,Name,AccountId,(Select Id FROM Implementation_Requests__r WHERE RecordTypeId = :nvOSARecordTypeId limit 2) from Opportunity Where Id = :opptyRecord.Id];
            System.assert(opptyRecord.Implementation_Requests__r.size() == 1,'There should be one Implementation_Request__c record created.');               
        }
    }
    
    @isTest static void testImplementationRequest_DoNotCreateRecord(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData('Flowers','Open',true);
            Test.startTest();
            Opportunity opptyRecord = [Select Id,Name,AccountId from Opportunity Where Account.Name Like 'Test Account Impl Request%' limit 1];
            opptyRecord.StageName = 'Contract Signed';
            update opptyRecord;
            
            Test.stopTest();
            opptyRecord = [Select Id,Name,AccountId,(Select Id FROM Implementation_Requests__r WHERE RecordTypeId = :nvOSARecordTypeId limit 2) FROM Opportunity Where Id = :opptyRecord.Id];
            System.assert(opptyRecord.Implementation_Requests__r.size() == 0,'There should be no Implementation_Request__c record created.'); 
        }
    }
    
    @isTest static void testImplementationRequest_CreateRecord_ByTrigger(){
        initUserData();
        User testUser = [Select Id,Name from User where userName = 'userEmail_SSMOQuote2@test.com' Limit 1];
    	System.runAs(testUser)
        {
            initData('Alcohol','Open',false);
            Test.startTest();
            Opportunity opptyRecord = [Select Id,Name,AccountId from Opportunity Where Account.Name Like 'Test Account Impl Request%' limit 1];
            opptyRecord.StageName = 'Contract Signed';
            update opptyRecord;
            
            opptyRecord = [Select Id,Name,AccountId,(Select Id FROM Implementation_Requests__r WHERE RecordTypeId = :nvOSARecordTypeId limit 2) FROM Opportunity Where Id = :opptyRecord.Id];
            System.assert(opptyRecord.Implementation_Requests__r.size() == 1,'There should be one Implementation_Request__c record created.');
            
            Test.stopTest();
        }
    }
    
}