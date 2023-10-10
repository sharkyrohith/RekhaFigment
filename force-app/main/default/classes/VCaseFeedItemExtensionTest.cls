/*******************************************************************************************
 * @Name         VCaseFeedItemExtensionTest
 * @Author       Sahil
 * @Date         2021-03-25
 * @Group        Bizapps Support
 * @Description  Test class for case notes/feed controller
 *******************************************************************************************/
/* MODIFICATION LOG
 * Version          Developer          Date               Description
 *-------------------------------------------------------------------------------------------
 *  1.0              Sahil              2021-03-25          Updated
 *******************************************************************************************/
@IsTest(SeeAllData=false)
public class VCaseFeedItemExtensionTest 
{   
    @testSetup
    static void setup() {
     //Creating Group
     Group testGroup = new Group(Name = CDdSupportConstants.TEST_QUEUE_LABEL, Type = CDdSupportConstants.GROUP_QUEUE);
     insert testGroup;
     QueuesObject testQueue; 
     System.runAs(new User(Id=UserInfo.getUserId())) {
       //Associating queue with group AND to the Case object
       testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
       insert testQueue;
     }
     //create configs for escalation and transfer
     Site_Escalation_Config__c escConfigObj = new Site_Escalation_Config__c( Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                             Queue_Id__c = testGroup.Id,
                                                                             Queue_Label__c = CDdSupportConstants.TEST_QUEUE_LABEL,
                                                                             Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                             IsEscalation__c = true,
                                                                             IsTransfer__c = false);
     insert escConfigObj;
    
     Site_Escalation_Config__c transferConfigObj = new Site_Escalation_Config__c( Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                                  Queue_Id__c = testGroup.Id,
                                                                                  Queue_Label__c = CDdSupportConstants.TEST_QUEUE_LABEL,
                                                                                  Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                                  IsEscalation__c = false,
                                                                                  IsTransfer__c = true);
      insert transferConfigObj;
  }

    @isTest
    public static void testPost() 
    {
        init();
        
        Chatter_Post_Notes_Template__c t = new Chatter_Post_Notes_Template__c();
        t.Name = 'Template 1';
        t.Body__c = 'This is the template body';
        t.Active__c = true;
        insert t;
        
        Case c = new Case();
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Email';
        insert c;
		
        VCaseFeedItemNewExtension ctrl = new VCaseFeedItemNewExtension(new ApexPages.StandardController(c));
    	List<SelectOption> options = ctrl.getTemplateOptions();
        ctrl.selectedTemplateId = t.Id;
        ctrl.loadTemplate();
        ctrl.postFeed();
        ctrl.getEscOrTransfer();
        ctrl.renderEscOrTfrPanel();
    }
    
    private static void init()
    {
        Trigger_Control_Panel__c cs = new Trigger_Control_Panel__c();
        cs.Name = 'Control Panel';
        insert cs;
        
        Account acc = new Account();
        acc.RecordTypeId = '0121a0000006PxA';
        acc.Name = 'DoorDash HQ';
        insert acc;
        
        List<BusinessHours> bhList = [Select Id, Name From businesshours Limit 1];
        if(!bhList.isEmpty())
        {
            Entitlement et = new Entitlement();
        	et.Name = 'Standard SLA';
        	et.StartDate = date.Today();
            et.AccountId = acc.Id;
            et.Type = 'Phone Support';
			et.BusinessHoursId = bhList[0].Id;
        	insert et;
        }
    }

  

    /**************************************************************************************
   * @Description  Method for testing get site escalations by logged in user's role id
   * @Return       NA
   **************************************************************************************/
  @isTest
  static void testGetEscQueueOptions() {
    User runningUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
    Id userRoleId = [
      SELECT Id, DeveloperName, Name
      FROM UserRole
      WHERE DeveloperName =: CDdSupportConstants.ROLE_HQ_SUPERVISOR_DEV_NAME
      LIMIT 1
    ]
    .Id;
    insert runningUser;

    List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case c = caseList[0];
        insert c;

    System.runAs(runningUser) {
      runningUser.UserRoleId = userRoleId;
      update runningUser; //to avoid MIXED_DML error. Can't insert User with UserRoleId in the prior DML on User
      Test.startTest();
      VCaseFeedItemNewExtension ctrl = new VCaseFeedItemNewExtension(new ApexPages.StandardController(c));
      Test.stopTest();
      System.assertEquals(2,ctrl.getEscQueueOptions().size(),'2 select options are expected');
    }
    
  }
   /**************************************************************************************
   * @Description  Method for testing get site escalations by logged in user's role id
   * @Return       NA
   **************************************************************************************/
  @isTest
  static void testGetTransferQueueOptions() {
    User runningUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
    Id userRoleId = [
      SELECT Id, DeveloperName, Name
      FROM UserRole
      WHERE DeveloperName =: CDdSupportConstants.ROLE_HQ_SUPERVISOR_DEV_NAME
      LIMIT 1
    ]
    .Id;
    insert runningUser;

    List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case c = caseList[0];
        insert c;

    System.runAs(runningUser) {
      runningUser.UserRoleId = userRoleId;
      update runningUser; //to avoid MIXED_DML error. Can't insert User with UserRoleId in the prior DML on User
      Test.startTest();
      VCaseFeedItemNewExtension ctrl = new VCaseFeedItemNewExtension(new ApexPages.StandardController(c));
      Test.stopTest();
      System.assertEquals(2,ctrl.getTransferQueueOptions().size(),'2 select options are expected');
    }
    
  }

    /**************************************************************************************
   * @Description  Method for testing render escalate or transer dropdown
   * @Return       NA
   **************************************************************************************/
  @isTest
  static void testEscalatePanel() {
    List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case c = caseList[0];
        insert c;
    Test.startTest();
    VCaseFeedItemNewExtension controller = new VCaseFeedItemNewExtension(new ApexPages.StandardController(c));
    controller.selectedAction = 'Escalate';
    controller.renderEscOrTfrPanel();
    Test.stopTest();
    System.assertEquals(null, controller.renderEscOrTfrPanel(),'Pagerefernce should be null');
  }
   /**************************************************************************************
   * @Description  Method for testing render escalate or transer dropdown
   * @Return       NA
   **************************************************************************************/
  @isTest
  static void testTransferPanel() {
    List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case c = caseList[0];
        insert c;
    Test.startTest();
    VCaseFeedItemNewExtension controller = new VCaseFeedItemNewExtension(new ApexPages.StandardController(c));
    controller.selectedAction = 'Transfer';
    controller.renderEscOrTfrPanel();
    Test.stopTest();
    System.assertEquals(null, controller.renderEscOrTfrPanel(),'Pagerefernce should be null');
  }

  /**************************************************************************************
   * @Description  Method for testing  escalate or transer dropdown options
   * @Return       NA
   **************************************************************************************/
  @isTest
  static void testGetEscTransferOptions() {
    List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case c = caseList[0];
        insert c;
    Test.startTest();
    VCaseFeedItemNewExtension controller = new VCaseFeedItemNewExtension(new ApexPages.StandardController(c));
    controller.getEscOrTransfer();
    Test.stopTest();
    System.assertEquals(2, controller.getEscOrTransfer().size(),'2 select options should be returned');
  }
  
}