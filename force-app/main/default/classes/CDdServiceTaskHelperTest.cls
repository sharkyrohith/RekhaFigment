/**
 * 
 * @author: Jeegar Brahmakshatriya
 * @date: 2019-12
 * @description test class for CDdTaskTrackingController
 * 
 */

@isTest
public with sharing class CDdServiceTaskHelperTest {
    
    @isTest static void calculateTimeSpentPaused() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(1);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        
        serviceTask.Status__c = Label.ServiceTaskStatusPaused;
        update serviceTask; 
        
        Test.stopTest(); 

        serviceTask = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Estimated_Handle_Time_Minutes__c, Id, Name, 
                                Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE id =: serviceTask.Id][0]; 

        serviceTask = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Estimated_Handle_Time_Minutes__c, Id, Name, 
                                Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE id =: serviceTask.Id][0]; 

        System.assertNotEquals(null, serviceTask.Time_Entry_Stop__c, 'Time Entry Stop Should be populated');


    }
    
    @isTest static void calculateTimeSpentResume() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(1);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        
        serviceTask.Status__c = Label.ServiceTaskStatusPaused;
        update serviceTask; 

        serviceTask.Status__c = Label.ServiceTaskStatusInProgress;
        update serviceTask; 
        
        Test.stopTest(); 

        serviceTask = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Estimated_Handle_Time_Minutes__c, Id, Name, 
                                Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE id =: serviceTask.Id][0]; 

        System.assertEquals(null, serviceTask.Time_Entry_Stop__c, 'Time Entry Stop Should be null');


    }

    @isTest static void calculateTimeSpentPauseToCancel() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(1);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        
        serviceTask.Status__c = Label.ServiceTaskStatusPaused;
        update serviceTask; 

        serviceTask.Status__c = Label.ServiceTaskStatusCancelled;
        update serviceTask; 
        
        Test.stopTest(); 

        serviceTask = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Estimated_Handle_Time_Minutes__c, Id, Name, 
                                Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE id =: serviceTask.Id][0]; 

        System.assertNotEquals(null, serviceTask.Time_Entry_Stop__c, 'Time Entry Stop Should not be null');
        System.assertNotEquals(null, serviceTask.Actual_Handle_Time__c, 'Actual Handle Time Should not be null');

    }
    
    @isTest static void calculateTimeSpentPauseToCompleted() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(1);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        
        serviceTask.Status__c = Label.ServiceTaskStatusPaused;
        update serviceTask; 

        serviceTask.Status__c = Label.ServiceTaskStatusCompleted;
        update serviceTask; 
        
        Test.stopTest(); 

        serviceTask = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Estimated_Handle_Time_Minutes__c, Id, Name, 
                                Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE id =: serviceTask.Id][0]; 

        System.assertNotEquals(null, serviceTask.Time_Entry_Stop__c, 'Time Entry Stop Should not be null');
        System.assertNotEquals(null, serviceTask.Actual_Handle_Time__c, 'Actual Handle Time Should not be null');

    }

    @isTest static void calculateTimeSpentInprogressToCancelled() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(1);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        serviceTask.Status__c = Label.ServiceTaskStatusCancelled;
        update serviceTask; 
        
        Test.stopTest(); 

        serviceTask = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Estimated_Handle_Time_Minutes__c, Id, Name, 
                                Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE id =: serviceTask.Id][0]; 

        System.assertNotEquals(null, serviceTask.Time_Entry_Stop__c, 'Time Entry Stop Should not be null');
        System.assertNotEquals(null, serviceTask.Actual_Handle_Time__c, 'Actual Handle Time Should not be null');

    }

    @isTest static void calculateTimeSpentInprogressCompleted() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(1);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        
        serviceTask.Status__c = Label.ServiceTaskStatusCompleted;
        update serviceTask; 
        
        Test.stopTest(); 

        serviceTask = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Estimated_Handle_Time_Minutes__c, Id, Name, 
                                Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE id =: serviceTask.Id][0]; 

        System.assertNotEquals(null, serviceTask.Time_Entry_Stop__c, 'Time Entry Stop Should not be null');
        System.assertNotEquals(null, serviceTask.Actual_Handle_Time__c, 'Actual Handle Time Should not be null');

    }

    @isTest static void doNotCreateNextTask() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(2);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        serviceTask.Status__c = Label.ServiceTaskStatusCancelled;
        serviceTask.Next_Task__c = taskTemplates[1].Id;
        update serviceTask; 
        
        Test.stopTest(); 

        List<Service_Task__c> caseServiceTasks = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Id, Name, 
                                Estimated_Handle_Time_Minutes__c, Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, 
                                Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE Case__c =: serviceTask.Case__c]; 

        System.assertEquals(1, caseServiceTasks.size(), 'Should not create next task');

    }

    @isTest static void createNextTask() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(2);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        serviceTask.Status__c = Label.ServiceTaskStatusCompleted;
        serviceTask.Next_Task__c = taskTemplates[1].Id;
        update serviceTask; 
        
        Test.stopTest(); 

        List<Service_Task__c> caseServiceTasks = [SELECT Actual_Handle_Time__c, Case__c, Completed_Date_Time__c, Id, Name, 
                                Estimated_Handle_Time_Minutes__c, Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, 
                                Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE Case__c =: serviceTask.Case__c]; 

        System.assertEquals(2, caseServiceTasks.size(), 'There should be 2 Service Tasks for this case');

    }

    @isTest static void cannotHaveMultipleActiveTasksOnACase() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1,'Support');
        insert caseList;

        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(2);
        Service_Task__c serviceTask =  createServiceTask(caseList[0].Id, taskTemplates[0]);
        
        Test.startTest();
        try{
            Service_Task__c secondServiceTask = createServiceTask(caseList[0].Id, taskTemplates[1]);
        } catch (Exception e) {
            System.debug('><> ' + e);
            System.assert(e.getMessage().contains(Label.Service_Task_Error_Message_One_Active_Task));
        }
        
            

        Test.stopTest(); 


    }
    
    @isTest static void createNextTaskWithTeam() {
        List<Service_Task_Template__c> taskTemplates = createServiceTaskTemplate(2);
        Service_Task__c serviceTask =  createServiceTask(null, taskTemplates[0]);
        
        Test.startTest();
        serviceTask.Status__c = Label.ServiceTaskStatusCompleted;
        serviceTask.Next_Task__c = taskTemplates[1].Id;
        update serviceTask; 
        
        Test.stopTest(); 

        List<Service_Task__c> caseServiceTasks = [SELECT Actual_Handle_Time__c,Team_name__c, Case__c, Completed_Date_Time__c, Id, Name, 
                                Estimated_Handle_Time_Minutes__c, Next_Task__c, Notes__c, Start_Date_Time__c, Status__c,Task_Type__c, 
                                Time_Entry_Start__c, Time_Entry_Stop__c 
                       FROM Service_Task__c 
                       WHERE Case__c =: serviceTask.Case__c AND Status__c =: Label.ServiceTaskStatusInProgress]; 

        System.assertEquals(1, caseServiceTasks.size(), 'There should be 1 In Progress Service Tasks for this case');
        System.assertEquals(serviceTask.Team_Name__c, caseServiceTasks[0].Team_Name__c,'Next Task & Old Task Team should be same');
    }

    private static Service_Task__c createServiceTask(Id caseId, Service_Task_Template__c taskTemplate) {
        if(caseId == null ) {
            List<Case> caseList = TDdCaseFactory.createCaseRecords(1,'Support');
            insert caseList;
        }

        Service_Task__c serviceTask =  new Service_Task__c();
        serviceTask.Case__c = caseId;
        serviceTask.Status__c = Label.ServiceTaskStatusInProgress;
        serviceTask.Task_Type__c = taskTemplate.Id;
        serviceTask.Estimated_Handle_Time_Minutes__c = taskTemplate.Estimated_Handle_Time_minutes__c;
        serviceTask.Time_Entry_Start__c = System.now(); 
        serviceTask.Start_Date_Time__c = System.now(); 
        serviceTask.Name = taskTemplate.Name; 
        serviceTask.OwnerId = UserInfo.getUserId(); 
        serviceTask.Team_Name__c = taskTemplate.Team__c;

        insert serviceTask;
        return serviceTask; 
    }


    private static List<Service_Task_Template__c> createServiceTaskTemplate(Integer count)  {
        String supportRTId = Schema.SObjectType.Case
                                .getRecordTypeInfosByName()
                                .get('Support').getRecordTypeId();
        List<Service_Task_Template__c> templateList = new LIst<Service_Task_Template__c>(); 
        Service_Task_Template__c serviceTaskTemplate;
        for(Integer i = 0; i < count; i ++) {
            serviceTaskTemplate = new Service_Task_Template__c();
            serviceTaskTemplate.Case_Record_Type_Id__c = supportRTId;
            serviceTaskTemplate.Estimated_Handle_Time_minutes__c = 10;
            serviceTaskTemplate.Is_Active__c = true;
            serviceTaskTemplate.Name = 'test' + i;
            serviceTaskTemplate.Sort_Order__c = i+1;
            serviceTaskTemplate.Team__c = 'Local Onboarding';
            templateList.add(serviceTaskTemplate);
        }
        insert templateList;
        return templateList; 
    }
    
}