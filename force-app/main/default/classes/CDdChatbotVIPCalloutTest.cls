@isTest
public class CDdChatbotVIPCalloutTest {

    static testMethod void testDRSCallout() {
        Service_Statistics__c stat = new Service_Statistics__c();
        stat.Live_Agent_Button_ID__c = 'test';
        stat.Live_Agent_Estimated_Wait_Time__c = 20;
        insert stat;

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new CDdChatbotVIPCalloutMock());

        List<CDdChatbotVIPCallout.DRSCalloutInput> inputs  = new List<CDdChatbotVIPCallout.DRSCalloutInput>();
        CDdChatbotVIPCallout.DRSCalloutInput input = new CDdChatbotVIPCallout.DRSCalloutInput();
        input.email = 'test@test.com';
        input.VIPButtonId = 'test';
        inputs.add(input);
        List<CDdChatbotVIPCallout.DRSCalloutOutput> outputs = CDdChatbotVIPCallout.DRSCallout(inputs);
        CDdChatbotVIPCallout.DRSCalloutOutput output = outputs[0];
        System.assert(output.chatWaitTime == 20);
        System.assert(output.isVIP == true);
        
        Test.stopTest();
    }

}