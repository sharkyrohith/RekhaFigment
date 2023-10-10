@isTest
public class VTaskTriggerHandlerTest {
	
    public static testMethod void doInsertUpdate (){
        insert VTestUtil.createVeltigSettings();
        
        Id supportRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case testCase = new Case(RecordTypeId=supportRecTypeId,
                                 Subject='Test Case',
                                 Status='New',
                                 Origin='Web',
                                 Customer_Type__c='Consumer');
        insert testCase;
        
        Task testTask1 = new Task(WhatId=testCase.Id,
                                  Status='Completed',
                                  Subject='Test Call');
        insert testTask1;
        
        Task testTask2 = new Task(WhatId=testCase.Id,
                                  Status='Open',
                                  Subject='Test Call');
        insert testTask2;
        testTask2.Status = 'Completed';
        update testTask2;
        
    }
}