/********************************************************************************************************************
* @author Sriram
* @date 08/10/2021
*
* @group Milestone
*
* @description Test class for Milestone Generator Framework
* 
**************************************************************************************************************************************/
@isTest
public class CDdMilestoneGeneratorTest {
    private static vCS__c testSettings;
    private static Opportunity_Trigger_Helper_Settings__c helperSettings;
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;  
    public static final Id CASE_MARKETPLACE_ONBOARDING_RECORD_TYPE_ID = CDdOpportunityTriggerHelper.onboardingCaseRTId; 
    public static final Id TEST_PERMISSION_SET_ID;
    public static final Id TEST_CUSTOM_PERMISSION_ID; 
    
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id; 
        TEST_PERMISSION_SET_ID = [SELECT Id, Name FROM PermissionSet WHERE Name = 'S2N_V4_Permission_Set'].Id;
        TEST_CUSTOM_PERMISSION_ID = [SELECT Id, DeveloperName FROM CustomPermission WHERE DeveloperName = 'S2N_V4_Permission'].Id;
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

    @testSetup
    static void testSetup() {
        System.runAs(getTestRunUser()) {
            Test.startTest();
            SBQQ.TriggerControl.disable();
            testSettings = VTestUtil.createVeltigSettings();
            Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
            cp.Name = 'Main';
            cp.Opportunity_Trigger_Enabled__c = false;
            cp.Account_Trigger_Enabled__c = false;
            upsert cp;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;
            
            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_CPU_Time_Check__c = true;
            ftrFlag.Enable_Debug_Logs__c = true;
            insert ftrFlag;            

            helperSettings = Opportunity_Trigger_Helper_Settings__c.getOrgDefaults(); 
            system.debug('testSetup: helperSettings: ' + helperSettings);
            helperSettings.Caviar_Promo_Notes__c = 'c';             // Caviar Promo
            helperSettings.New_Asset_Status__c = 'Purchased';       // Required field
            system.debug('testSetup: helperSettings: ' + helperSettings);
            upsert helperSettings;

            RealZip__RealZips__c realZipRec = new RealZip__RealZips__c(Submarket_ID__c = 10);
            insert realZipRec;

            TDdOpportunityLineItemFactory.createProducts();

            List<Account> accs = TDdAccountFactory.createAccounts('MilestoneGenParentAcc0', 1, 'Marketplace');
            accs[0].Restaurant_Id__c = '35990';

            insert new List<Account>{accs[0]};

            List<Account> childAccs = TDdAccountFactory.createAccounts('MilestoneGenChildAcc0', 1, 'Marketplace');
            childAccs[0].Restaurant_Id__c = '59900';  
            childAccs[0].ParentId = accs[0].Id;  
            insert childAccs;
            
            List<Contact> cons = new List<Contact>{
                TDdAccountFactory.createContacts(1, childAccs[0].Id)[0]
            };  
            cons[0].firstName = 'milestoneGen0';
            cons[0].LastName = 'Con0'; 
            cons[0].Email = 'milestoneGen0.Con0@dd.com';

            insert cons;            
            
            List<Opportunity> opps = new List<Opportunity>{
                TDdOpportunityFactory.createOpportunityByDevRT('MilestoneGenOpp0', childAccs[0].Id, cons[0].Id, 'New', 'ML_Inside_Sales')
            };

            opps[0].Menu_to_be_completed_by__c = 'Account Owner';
            opps[0].Order_Protocol__c = 'Email';
            opps[0].Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
            opps[0].Activate_Centrally_2__c = 'No';
            opps[0].StageName = 'Closed Won';
            insert opps;

            Test.stopTest();
        }
    }

    @isTest 
    static void testMilestoneGenerator(){
        System.runAs (getTestRunUser()) {
            String testOppName = 'MilestoneGenOpp0';
            Opportunity testOpp = [SELECT Id, RecordTypeId, Activate_Centrally_2__c, Mx_Requested_Custom_Radius_Demand_Gen__c, 
                Order_Protocol__c, Menu_to_be_completed_by__c FROM Opportunity WHERE Name = :testOppName];
            Case testCase = [SELECT Id FROM Case WHERE Opportunity_Name__c = :testOpp.Id AND RecordTypeId = :CASE_MARKETPLACE_ONBOARDING_RECORD_TYPE_ID];
            System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Opportunity_Name__c = :testOpp.Id AND RecordTypeId = :CASE_MARKETPLACE_ONBOARDING_RECORD_TYPE_ID]);
            System.assertEquals(0, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id 
                    AND Milestone_Template__r.Milestone_Creation_Type__c = 'Conditional']);
            //System.assertEquals(6, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id]);

            update new Case(
                    Segment__c = 'Local', 
                    Id = testCase.Id
            );
            update new Opportunity(
                Id = testOpp.Id,
                Menu_to_be_completed_by__c = 'DoorDash Onboarding Team',
                Order_Protocol__c = 'Email',
                Mx_Requested_Custom_Radius_Demand_Gen__c = 'Yes',
                Activate_Centrally_2__c = 'Yes'
            );        
            CDdMilestoneTemplate.insertMilestoneTemplates();
            
            Test.startTest();

                List<Milestone_Event__e> milestoneEvents = new List<Milestone_Event__e>{
                    new Milestone_Event__e(
                        Operation__c = 'Insert', 
                        User_Id__c = UserInfo.getUserId(), 
                        Parent_SObject_Type__c = 'Case', 
                        Parent_SObject_Id__c = testCase.Id)
                    };
                EventBus.publish(milestoneEvents);
                Test.getEventBus().deliver();        

            Test.stopTest();
            System.assertEquals(4, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id 
                    AND Milestone_Template__r.Milestone_Creation_Type__c = 'Conditional'] );
        }
    }
    @isTest 
    static void testUserPermittedSettings(){
        System.runAs (getTestRunUser()) {
            PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
                PermissionSetId = TEST_PERMISSION_SET_ID,
                AssigneeId = UserInfo.getUserId()
            );
            insert permissionSetAssignment;
            SetupEntityAccess setupEntityAccess = null;
            for (SetupEntityAccess access : [SELECT Id 
                                            FROM SetupEntityAccess 
                                            WHERE SetupEntityId = :TEST_CUSTOM_PERMISSION_ID
                                            AND ParentId = :TEST_PERMISSION_SET_ID ]){
                setupEntityAccess = access;
            }
            if (setupEntityAccess == null){
                setupEntityAccess = new SetupEntityAccess(
                    SetupEntityId = TEST_CUSTOM_PERMISSION_ID,
                    ParentId = TEST_PERMISSION_SET_ID
                );
                insert setupEntityAccess;
            }            
            Milestone_Generator_Setting__mdt setting = [SELECT Id FROM Milestone_Generator_Setting__mdt lIMIT 1];
            Set<Id> userPermittedSettings 
                = CDdMilestoneGeneratorSetting.getUserPermittedSettings(UserInfo.getUserId(), new Map<Id, Set<Id>>{TEST_CUSTOM_PERMISSION_ID => new Set<Id>{setting.Id}});
            System.assertEquals(true, !userPermittedSettings.isEmpty());
        }
    }        
}