@istest
private with sharing class MxSelfOnboardingEscalationBatchTest {
  static final String oppName = 'MxSelfOnboardingIterable';

  static final Id setupMenuRT = CDdGenericTriggerOptimizationHelper.getMilestoneRecordTypeId('Setup Menu');
  static final Id onboardingCaseRT =CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Marketplace Onboarding');

  @testSetup
  static void setupData() {
      User selfServIntegrationUser = [SELECT Id FROM User WHERE alias = 'selfserv'];

    System.runAs(selfServIntegrationUser) {

      insert VTestUtil.createVeltigSettings();
      Milestone_Template__c templ = new Milestone_Template__c(
      Milestone_Type__c = 'Setup Menu',
      Milestone_Record_Type_ID_18__c = setupMenuRT,
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
      Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
      validation.Bypass_Opportunity_Validations__c = true;  insert validation;
      Account parent = TDdAccountFactory.createAccounts('Parent', 1, 'Parent Account')[0];
      Account child = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
      insert parent;  child.ParentId = parent.Id;  insert child;
      Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;

        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(oppName, child.Id, contact.Id, 'New', 'ML_Inside_Sales');
        opp.Menu_To_Be_Completed_By__c = 'Merchant';
        opp.Menu_Setup_Method__c = null;
        opp.SSME_Menu_Completion_Date_Time__c = null ;
        opp.StageName = 'Closed Won';
        opp.SSME_Escalation_Date_Time__c = null;
        opp.SSME_Expiration_Date_Time__c = system.now();
        insert opp;
    }
    system.debug('MxSelfOnboardingEscalationBatchTest');
    system.debug([select id, Opportunity_Name__c, recordtype.name from Case where recordtype.name = 'Marketplace Onboarding']);
    system.debug([select id, name, case__c, recordtype.name from milestone__c]);
  }
  @isTest static void testBatch(){
    DateTime beforeEscalation = system.now().addMinutes(-1);
    Test.startTest();
    Database.executeBatch(new MxSelfOnboardingEscalationBatch(),1);
    Test.stopTest();
    Opportunity queriedOpp = [SELECT Id, Menu_to_be_completed_by__c, SSME_Escalation_Date_Time__c FROM Opportunity WHERE Name = :oppName];
    system.assertEquals('DoorDash Onboarding Team', queriedOpp.Menu_to_be_completed_by__c);
    system.assertNotEquals(null, queriedOpp.SSME_Escalation_Date_Time__c);
    system.assertEquals(true, system.now() > queriedOpp.SSME_Escalation_Date_Time__c);
    system.assertEquals(true, beforeEscalation <= queriedOpp.SSME_Escalation_Date_Time__c);
  }
}