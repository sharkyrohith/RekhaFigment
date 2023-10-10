/**
 * 
 * @author: Tia Xuan
 * @date: 2019-12
 * @description test class for CDdTaskTrackingController
 * 
 */

@isTest
public class CDdTaskTrackingControllerTest {
    /**
    * @description test the retrieveTaskTemplates
    **/
    @isTest static void retrieveTaskTemplates_testMethod() {
        String supportRTId = Schema.SObjectType.Case
                                .getRecordTypeInfosByName()
                                .get('Support').getRecordTypeId();

        Service_Task_Template__c temp = new Service_Task_Template__c();
        temp.Case_Record_Type_Id__c = supportRTId;
        temp.Estimated_Handle_Time_minutes__c = 10;
        temp.Is_Active__c = true;
        temp.Name = 'test';
        temp.Team__c = 'Local Onboarding';
        temp.Sort_Order__c = 1;
        insert temp;
               
        Test.startTest();
            Service_Task_Template__c[] temps = CDdTaskTrackingController.retrieveTaskTemplates(supportRTId,'All');
        	CDdTaskTrackingController.retrieveTeamDetails(supportRTId);
            System.assert(temps.size() ==  1);
        Test.stopTest();
    }

    /**
    * @description test checkForActiveTasks
    **/
    @isTest static void checkForActiveTasks_testMethod() {
        String supportRTId = Schema.SObjectType.Case
                                .getRecordTypeInfosByName()
                                .get('Support').getRecordTypeId();

        Service_Task_Template__c temp = new Service_Task_Template__c();
        temp.Case_Record_Type_Id__c = supportRTId;
        temp.Estimated_Handle_Time_minutes__c = 10;
        temp.Is_Active__c = true;
        temp.Name = 'test';
        temp.Sort_Order__c = 1;
        insert temp;

        List<Case> caseList = TDdCaseFactory.createCaseRecords(1,'Support');
        insert caseList;
        Test.startTest();
            Service_Task__c st =  new Service_Task__c();
            st.Case__c = caseList[0].Id;
            st.Status__c = Label.ServiceTaskStatusInProgress;
            st.Task_Type__c = temp.Id;
            insert st;
            String taskId = CDdTaskTrackingController.checkForActiveTasks(caseList[0].Id);
            System.assert(taskId == st.Id);
        Test.stopTest();
    }
    
}