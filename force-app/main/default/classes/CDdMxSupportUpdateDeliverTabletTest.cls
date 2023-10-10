@isTest
public class CDdMxSupportUpdateDeliverTabletTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_INSTANCE_NAME = 'CDdMxSupportUpdateDeliverTablet';
    public static CDdMxSupportEventEnum testEvent1 = CDdMxSupportEventEnum.UPDATE_DELIVER_TABLET;
    public static final String QUERY_LAST_N_DAYS = '10';
    public static final Id deliverTabletRT  = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Deliver Tablet').getRecordTypeId();
    public static final Id onboardingCaseRT  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();


    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }
    /**
     * @description Prepare and return the test running user
     */
    private static User getTestRunUser() {
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

    /**
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {

        System.runAs(getTestRunUser()){

            Mx_Support_Event_Config__c eventConfig = new Mx_Support_Event_Config__c();
            eventConfig.Apex_Class__c = TEST_INSTANCE_NAME;
            eventConfig.Batch_Size__c = 50;
            eventConfig.Event_Name__c = testEvent1.name();
            eventConfig.Is_Active__c = true;
            eventConfig.Query_Last_N_Days__c = Decimal.valueOf(QUERY_LAST_N_DAYS);
            eventConfig.Query_SObject_Type__c = 'Case';
            eventConfig.Sequence__c = 1;
            insert eventConfig;
        }
    }

    /**
     * @description: Code coverage for CDdMxSupportUpdateDeliverTablet class
     */
    @isTest
    static void testUpdateDeliverTablet() {
        System.runAs(getTestRunUser()){

            List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 6, 'Marketplace');
            insert accs;
            List<Case> cases = new List<Case>();
            List<Case> onboardingCases = TDdCaseFactory.createCaseRecords(6, 'Marketplace Onboarding');
            List<Case> dtCases = TDdCaseFactory.createCaseRecords(6, 'Tablet Requests');
            cases.addAll(onboardingCases);
            for(Integer k=0; k<dtCases.size(); k++){
                dtCases[k].Return_Shipping_Address_State__c = 'Florida';
            }
            cases.addAll(dtCases);
            for(Integer k=0; k<accs.size(); k++){
                onboardingCases[k].AccountId = accs[k].Id;
                dtCases[k].AccountId = accs[k].Id;
                onboardingCases[k].Status = 'Opened';
                dtCases[k].Status = 'Received';
                dtCases[k].Request_Type__c = 'Ship to Merchant (New Tablet)';//BASD-35044
            }
            insert cases;
            Milestone_Template__c templ = new Milestone_Template__c(
                    Milestone_Type__c = 'Deliver Tablet',
                    Milestone_Record_Type_ID_18__c = deliverTabletRT,
                    Parent_Object_API_Name__c = 'Case',
                    Parent_Object_Record_Type_ID_18__c = onboardingCaseRT,
                    Milestone_Creation_Type__c = 'Default',
                    Default_Milestone_Status_on_Creation__c = 'Not Started',
                    Default_Owner_on_Creation_18__c = Userinfo.getUserId(),
                    Default_Sort_Order__c = 1,
                    Active__c = true,
                    Completed_by_Stage__c = 'Contacting Mx',
                    Reviewed_by_Stage__c = 'Onboarding Quality Check',
                    Stage_Completed_Sort_Order__c = 0,
                    Stage_Reviewed_Sort_Order__c = 0);
            insert templ;
            List<Milestone__c> tabletRequestMilestones = new List<Milestone__c>{
                new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[0].Id, Sort_Order__c = 1,
                        RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
                new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[1].Id, Sort_Order__c = 1,
                        RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
                new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[2].Id, Sort_Order__c = 1,
                        RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
                new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[3].Id, Sort_Order__c = 1,
                        RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
                new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[4].Id, Sort_Order__c = 1,
                        RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
                new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[5].Id, Sort_Order__c = 1,
                        RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id)
            };
            insert tabletRequestMilestones;


            update new List<Milestone__c>{
            new Milestone__c(Id = tabletRequestMilestones[0].Id, Status__c = 'In Progress'),
            new Milestone__c(Id = tabletRequestMilestones[1].Id, Status__c = 'In Progress'),
            new Milestone__c(Id = tabletRequestMilestones[2].Id, Status__c = 'In Progress'),
            new Milestone__c(Id = tabletRequestMilestones[3].Id, Status__c = 'Not Started'),
            new Milestone__c(Id = tabletRequestMilestones[4].Id, Status__c = 'Not Started'),
            new Milestone__c(Id = tabletRequestMilestones[5].Id, Status__c = 'Complete')
        	};
            Test.startTest();
            CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(testEvent1);
            Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(testEvent1));
            Test.stopTest();
        }
    }

     /**
     * @description: verifying the config values
     */
    @isTest
    static void testConfigValues() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            System.assertEquals(QUERY_LAST_N_DAYS, CDdMxSupportUpdateDeliverTablet.QUERY_LAST_N_DAYS);
            Test.stopTest();
        }
    }
}