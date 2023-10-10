@isTest
private class CDdSMEChatWidgetControllerTest {
    static testMethod void testGetRecord() {
        Task testTask = new Task();
        insert testTask;
        
        Task testTask1 = new Task();
        testTask1 = [SELECT Id FROM Task WHERE Id = :testTask.Id];
        
        Test.StartTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdSMEChatWidget'));
        System.currentPageReference().getParameters().put('id', testTask.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testTask);
        CDdSMEChatWidgetController ctrl = new CDdSMEChatWidgetController(controller);
        System.assertEquals(testTask1.Id, ctrl.currentRecordId);
        Test.StopTest();
    }
}