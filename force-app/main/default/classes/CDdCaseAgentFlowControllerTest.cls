/**
 * 
 * @author: Tia Xuan
 * @date: 2020-07
 * @description Test class for CDdCaseAgentFlowController
 * 
 */
@isTest
public class CDdCaseAgentFlowControllerTest {
    @isTest
    static void testGetCaseAgentFlowAPI() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].SuppliedEmail = 'test@test.com';
        caseList[0].SuppliedPhone = '1234567890';
        caseList[0].Full_Name__c = 'test@test.com';
        caseList[0].Origin = 'API';
        caseList[0].Channel__c = 'Consumer Community';
        caseList[0].Platform__c = 'DoorDash';
        caseList[0].comm_dependent_cx_Category__c = 'Account Issues';
        caseList[0].communities_cx_Subcategory__c = 'Reactivate Account';
        caseList[0].Chat_Issue__c = 'test';
        caseList[0].Chat_Issue_Details__c = 'test';
        caseList[0].Alert_Type__c = 'Additional Cost from Instructions';
        caseList[0].Description = 'test';
        caseList[0].DeliveryNo__c = 123;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        caseList[0].DeliveryUUID__c = '123';
        caseList[0].Customer_Type__c = 'Consumer';
        insert caseList;

        Case_Agent_Flow__c agentFlow = new Case_Agent_Flow__c();
        agentFlow.Listen_Subtitle__c = 'test';
        agentFlow.Listen_Body__c = 'test';
        agentFlow.Empathize_Subtitle__c = 'test';
        agentFlow.Empathize_Body__c = 'test';
        agentFlow.Resolve_Subtitle__c = 'test';
        agentFlow.Resolve_Body__c = 'test';
        agentFlow.Close_Subtitle__c = 'test';
        agentFlow.Close_Body__c = 'test';
        agentFlow.Type__c = 'API';
        insert agentFlow;

        Test.startTest();

        Case_Agent_Flow__c caf = CDdCaseAgentFlowController.getCaseAgentFlow(caseList[0].Id);
        System.assert(caf != null);
        
        Test.stopTest();
    }

    @isTest
    static void testGetCaseAgentFlowChat() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].SuppliedEmail = 'test@test.com';
        caseList[0].SuppliedPhone = '1234567890';
        caseList[0].Full_Name__c = 'test@test.com';
        caseList[0].Origin = 'Chat';
        caseList[0].Channel__c = 'Consumer Community';
        caseList[0].Platform__c = 'DoorDash';
        caseList[0].comm_dependent_cx_Category__c = 'Account Issues';
        caseList[0].communities_cx_Subcategory__c = 'Reactivate Account';
        caseList[0].Chat_Issue__c = 'test';
        caseList[0].Chat_Issue_Details__c = 'test';
        caseList[0].Alert_Type__c = 'Additional Cost from Instructions';
        caseList[0].Description = 'test';
        caseList[0].DeliveryNo__c = 123;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        caseList[0].DeliveryUUID__c = '123';
        caseList[0].Customer_Type__c = 'Consumer';
        insert caseList;

        Case_Agent_Flow__c agentFlow = new Case_Agent_Flow__c();
        agentFlow.Listen_Subtitle__c = 'test';
        agentFlow.Listen_Body__c = 'test';
        agentFlow.Empathize_Subtitle__c = 'test';
        agentFlow.Empathize_Body__c = 'test';
        agentFlow.Resolve_Subtitle__c = 'test';
        agentFlow.Resolve_Body__c = 'test';
        agentFlow.Close_Subtitle__c = 'test';
        agentFlow.Close_Body__c = 'test';
        agentFlow.Type__c = 'Chat';
        insert agentFlow;

        Test.startTest();

        Case_Agent_Flow__c caf = CDdCaseAgentFlowController.getCaseAgentFlow(caseList[0].Id);
        System.assert(caf != null);
        
        Test.stopTest();
    }

    @isTest
    static void testGetCaseAgentFlowChat2() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].SuppliedEmail = 'test@test.com';
        caseList[0].SuppliedPhone = '1234567890';
        caseList[0].Full_Name__c = 'test@test.com';
        caseList[0].Origin = 'Chat';
        caseList[0].Channel__c = 'DoorDash App';
        caseList[0].Platform__c = 'DoorDash';
        caseList[0].Chat_Issue__c = 'test';
        caseList[0].Chat_Issue_Details__c = 'test';
        caseList[0].Alert_Type__c = 'Additional Cost from Instructions';
        caseList[0].Description = 'test';
        caseList[0].DeliveryNo__c = 123;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        caseList[0].DeliveryUUID__c = '123';
        caseList[0].Customer_Type__c = 'Dasher';
        insert caseList;

        Case_Agent_Flow__c agentFlow = new Case_Agent_Flow__c();
        agentFlow.Listen_Subtitle__c = 'test';
        agentFlow.Listen_Body__c = 'test';
        agentFlow.Empathize_Subtitle__c = 'test';
        agentFlow.Empathize_Body__c = 'test';
        agentFlow.Resolve_Subtitle__c = 'test';
        agentFlow.Resolve_Body__c = 'test';
        agentFlow.Close_Subtitle__c = 'test';
        agentFlow.Close_Body__c = 'test';
        agentFlow.Type__c = 'Chat';
        insert agentFlow;

        Test.startTest();

        Case_Agent_Flow__c caf = CDdCaseAgentFlowController.getCaseAgentFlow(caseList[0].Id);
        System.assert(caf != null);
        
        Test.stopTest();
    }

    @isTest
    static void testGetCaseAgentFlowPhone() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].SuppliedEmail = 'test@test.com';
        caseList[0].SuppliedPhone = '1234567890';
        caseList[0].Full_Name__c = 'test@test.com';
        caseList[0].Origin = 'Phone';
        caseList[0].Channel__c = 'Consumer Community';
        caseList[0].Platform__c = 'DoorDash';
        caseList[0].comm_dependent_cx_Category__c = 'Account Issues';
        caseList[0].communities_cx_Subcategory__c = 'Reactivate Account';
        caseList[0].Chat_Issue__c = 'test';
        caseList[0].Chat_Issue_Details__c = 'test';
        caseList[0].Alert_Type__c = 'Additional Cost from Instructions';
        caseList[0].Description = 'test';
        caseList[0].DeliveryNo__c = 123;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        caseList[0].DeliveryUUID__c = '123';
        caseList[0].Customer_Type__c = 'Merchant';
        insert caseList;

        Case_Agent_Flow__c agentFlow = new Case_Agent_Flow__c();
        agentFlow.Listen_Subtitle__c = 'test';
        agentFlow.Listen_Body__c = 'test';
        agentFlow.Empathize_Subtitle__c = 'test';
        agentFlow.Empathize_Body__c = 'test';
        agentFlow.Resolve_Subtitle__c = 'test';
        agentFlow.Resolve_Body__c = 'test';
        agentFlow.Close_Subtitle__c = 'test';
        agentFlow.Close_Body__c = 'test';
        agentFlow.Type__c = 'Phone';
        insert agentFlow;

        Test.startTest();

        Case_Agent_Flow__c caf = CDdCaseAgentFlowController.getCaseAgentFlow(caseList[0].Id);
        System.assert(caf != null);
        
        Test.stopTest();
    }

    @isTest
    static void testGetCaseAgentFlowWeb() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].SuppliedEmail = 'test@test.com';
        caseList[0].SuppliedPhone = '1234567890';
        caseList[0].Full_Name__c = 'test@test.com';
        caseList[0].Origin = 'Web';
        caseList[0].Channel__c = 'Consumer Community';
        caseList[0].Platform__c = 'DoorDash';
        caseList[0].comm_dependent_cx_Category__c = 'Account Issues';
        caseList[0].communities_cx_Subcategory__c = 'Reactivate Account';
        caseList[0].Chat_Issue__c = 'test';
        caseList[0].Chat_Issue_Details__c = 'test';
        caseList[0].Alert_Type__c = 'Additional Cost from Instructions';
        caseList[0].Description = 'test';
        caseList[0].DeliveryNo__c = 123;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        caseList[0].DeliveryUUID__c = '123';
        caseList[0].Customer_Type__c = 'Consumer';
        insert caseList;

        Case_Agent_Flow__c agentFlow = new Case_Agent_Flow__c();
        agentFlow.Listen_Subtitle__c = 'test';
        agentFlow.Listen_Body__c = 'test';
        agentFlow.Empathize_Subtitle__c = 'test';
        agentFlow.Empathize_Body__c = 'test';
        agentFlow.Resolve_Subtitle__c = 'test';
        agentFlow.Resolve_Body__c = 'test';
        agentFlow.Close_Subtitle__c = 'test';
        agentFlow.Close_Body__c = 'test';
        agentFlow.Type__c = 'Web';
        insert agentFlow;

        Test.startTest();

        Case_Agent_Flow__c caf = CDdCaseAgentFlowController.getCaseAgentFlow(caseList[0].Id);
        System.assert(caf != null);
        
        Test.stopTest();
    }
}