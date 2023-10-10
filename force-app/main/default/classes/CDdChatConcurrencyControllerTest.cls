/**
 * 
 * @author: Tia Xuan
 * @date: 2020-05
 * @description class for tests for CDdChatConcurrencyController
 * 
 */
@isTest
public class CDdChatConcurrencyControllerTest {

    public static final String queueName = 'Chat-Merchant';
    public class MockHttpResponseGenerator implements HttpCalloutMock{
        
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(204);
            return res;         
        }
    }  

    /** 
     * @description Prepare test data
     */
    @testSetup
    static void testSetup(){
        Chat_Concurrency_Setting__c chatConcurrencySetting = new Chat_Concurrency_Setting__c(Routing_Config_Label__c = queueName, Name = queueName);
        insert chatConcurrencySetting;
    }
    
    @isTest
    static void testChatConcurrency() { 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());     
        
        List<QueueRoutingConfig> configs = CDdChatConcurrencyController.initChatConcurrency();
        CDdChatConcurrencyController.updateChatConcurrency(configs);
        
        QueueRoutingConfig config = [ select    Id,
                                                MasterLabel,
                                                CapacityWeight
                                    from QueueRoutingConfig
                                    where MasterLabel = :queueName];   
        System.assertEquals(config.CapacityWeight, configs[0].CapacityWeight);
        Test.stopTest();
    }

}