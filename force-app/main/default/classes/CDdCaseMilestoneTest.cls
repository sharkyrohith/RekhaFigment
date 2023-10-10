/**
    @author: Dan Thoreson
    @date: 07-Jun-2022
    @group: Milestone
    @description: Contains helper methods and test methods for the CDdCaseMilestone* classes.
                  Redundant code can be consolidated here and shared across the sibling classes and 
                  with the parent classes.
**/
@IsTest
public class CDdCaseMilestoneTest {

    private static vCS__c testSettings;
    
    public static final Id CASE_MARKETPLACE_ONBOARDING_RECORD_TYPE_ID = CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    
    public static void initializeTestSettings() {
        SBQQ.TriggerControl.disable();
        testSettings = VTestUtil.createVeltigSettings();
        insert testSettings;

        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = false;
        cp.Account_Trigger_Enabled__c = false;
        upsert cp;

        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true; 
        insert validation;

        RealZip__RealZips__c realZipRec = new RealZip__RealZips__c(Submarket_ID__c = 10);
        insert realZipRec; 
    }

    /** 
    * @description Prepare and return the test running user
    */
    public static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0]; 
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
}