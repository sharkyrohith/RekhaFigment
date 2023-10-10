/********************************************************************************************************************
* @author Ila Maheshwari
* @date 9/6/2022
*
* @group Delete SSMO Test Records
*
* @description The purpose is to test deletion of test SSMO records for Account, Case, Lead and Opporutnity
**************************************************************************************************************************************/
@isTest
public class CDdDeleteSSMOTestRecordsBatchTest {
    
    public static final String TEST_SSMO_DD_RUN_USERNAME = 'testssmo.runninguser@doordash.com';
    public static final String TEST_SSMO_USER_NAME = 'Self-Serve Integration User';
    public static final Id TEST_ROLE_ID;
    public static final Date startDate = System.Today().addDays(-15);	
    public static final Date endDate = System.Today();
    public static final Integer maxNumberOfRecords = 100;
    
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;       
    }
	
    /**
     * @description Prepare and return the test running SSMO user  
     */
    private static User getSSMOTestRunUser() {
        User ssmoTestRunUser = null;
        ssmoTestRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
        ssmoTestRunUser.Username = TEST_SSMO_DD_RUN_USERNAME;
        ssmoTestRunUser.LastName = TEST_SSMO_USER_NAME;
        
        return ssmoTestRunUser;
    }
    /**
    * @description Create other users	
    */	
    private static void createOtherUsers() {	
        List<User> testUsers = TDdAccountFactory.createUsers(2, null, TEST_ROLE_ID); 	
        testUsers[0].Username = 'formstack@doordash.com';	
        testUsers[1].Username = 'mx-eng-api@doordash.com';	
        insert testUsers;	
    }
	/** 
    * @description Prepare test data
    */   
    @testSetup 
    static void setup() {
        createOtherUsers();	
        User selfServiceUser1 = [SELECT Id from User WHERE UserName = 'formstack@doordash.com'];	
        User selfServiceUser2 = [SELECT Id from User WHERE UserName = 'mx-eng-api@doordash.com'];	
        System.runAs(getSSMOTestRunUser()){	
            Test.startTest();	
            /* Create Serve Users - Begin */	
            List<Self_Serve_Users__c> selfServeUsersSettings = new List<Self_Serve_Users__c>();	
            Self_Serve_Users__c ssUser;	
            ssUser = new Self_Serve_Users__c(); 	
            ssUser.name = 'formstack@doordash.com';	
            ssUser.User_Id__c = selfServiceUser1.id; 	
            selfServeUsersSettings.add(ssUser);	
            ssUser = new Self_Serve_Users__c(); 	
            ssUser.name = 'mx-eng-api@doordash.com';	
            ssUser.User_Id__c = selfServiceUser2.id; 	
            selfServeUsersSettings.add(ssUser);	
            insert selfServeUsersSettings;	
            Test.stopTest();	
        }	
        	
        System.runAs(selfServiceUser2){
            Datetime weekOld = Datetime.now().addDays(-8);
            List<Account> testAccounts = TDdAccountFactory.createAccounts('TEST TEST TEST Acc pulse', 3);
            Account negativeAcc = TDdAccountFactory.createAccounts('Account for negative', 1)[0];
            testAccounts.add(negativeAcc);
            insert testAccounts;
            Test.setCreatedDate(testAccounts[0].Id, weekOld);
            Test.setCreatedDate(testAccounts[1].Id, weekOld);
            Test.setCreatedDate(testAccounts[2].Id, weekOld);
            List<Contact> testContacts = TDdAccountFactory.createContacts(3, testAccounts[0].Id);
            insert testContacts;
            
            Opportunity opp1 = TDdOpportunityFactory.createOpportunity('TEST TEST TEST Opp pulse 1', testAccounts[0].Id, testContacts[0].Id, 'Seeking Meeting');
            Opportunity opp2 = TDdOpportunityFactory.createOpportunity('TEST TEST TEST Opp pulse 2', testAccounts[1].Id, testContacts[1].Id, 'Seeking Meeting');
            Opportunity opp3 = TDdOpportunityFactory.createOpportunity('Non SSMO Opportunity Opportunity', testAccounts[3].Id, testContacts[2].Id, 'Seeking Meeting');
            insert new List<Opportunity>{opp1, opp2, opp3};
            Test.setCreatedDate(opp1.Id, weekOld);
            Test.setCreatedDate(opp2.Id, weekOld);
            Test.setCreatedDate(opp3.Id, weekOld);
            
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Test ', 3, 'Master Lead', true);
            Test.setCreatedDate(testLeads[0].Id, weekOld);
            Test.setCreatedDate(testLeads[1].Id, weekOld);
            Test.setCreatedDate(testLeads[2].Id, weekOld);

            List<Case> cases = TDdCaseFactory.createCases(2, testAccounts[0].Id, opp1.Id, CDdSchemaUtils.CASE_RT.caviarOnboardingId());	
            insert cases;
        }
    }
    
    @isTest	
    static void testDeleteSSMORecords() {	
        Set<String> testObjects = new Set<String>{'Opportunity', 'Lead', 'Case', 'Account'};	
        	
        Test.startTest();            	
        Database.executeBatch(new CDdDeleteSSMOTestRecordsBatch(testObjects,startDate,endDate,maxNumberOfRecords));	
        Test.stopTest();	
        	
        Integer deletedAccCount = [SELECT Count() FROM Account WHERE Name LIKE '%TEST TEST TEST Acc pulse%'];	
        Integer deletedOppCount = [SELECT Count() FROM Opportunity WHERE Name LIKE '%TEST TEST TEST Opp pulse%'];	
        Integer deletedLeadCount = [SELECT Count() FROM Lead WHERE Name LIKE '%Test Test%'];	
        Integer deletedCaseCount = [SELECT Count() FROM Case];	
        	
        System.assertEquals(0, deletedLeadCount, 'Expecting SSMO Lead records to get deleted');	
        System.assertEquals(0, deletedOppCount, 'Expecting SSMO Opportunity records to get deleted');	
        System.assertEquals(0, deletedCaseCount, 'Expecting Cases related to SSMO Accounts to get deleted');	
        System.assertEquals(0, deletedAccCount, 'Expecting SSMO Account records to get deleted');	
    }
    
    @isTest
    static void testDeleteSSMORecordsNegative() {
        Set<String> testObjects = new Set<String>{'Opportunity', 'Lead', 'Case', 'Account'};
            
        Test.startTest();            
        Database.executeBatch(new CDdDeleteSSMOTestRecordsBatch(testObjects,startDate,endDate,maxNumberOfRecords));
        Test.stopTest();
        
        Integer existingOppCount = [SELECT Count() FROM Opportunity WHERE Name LIKE '%Non SSMO Opportunity Opportunity%'];
        
        System.assertEquals(1, existingOppCount, 'Expecting Non SSMO Opportunity record to not get deleted');
    }
    
    @IsTest
    public static void testSchedulable() {
        Set<String> testObjects = new Set<String>{'Opportunity', 'Lead', 'Case', 'Account'};
            
        Test.startTest();
        System.schedule('CDdDeleteSSMOTestRecordsSchd', '0 0 22 ? * SAT *', new CDdDeleteSSMOTestRecordsSchd(testObjects,startDate,endDate,maxNumberOfRecords));
        Test.stopTest();
    }
}