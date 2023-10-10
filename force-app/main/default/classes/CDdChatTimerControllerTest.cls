/**
 * 
 * @author: Tia Xuan
 * @date: 2020-06
 * @description Test class for CDdChatTimerController
 * 
 */
@isTest
public class CDdChatTimerControllerTest {
    @isTest
    static void testPositive() {
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        
       // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        LiveChatTranscript tx = new LiveChatTranscript(
            chatKey = '123', liveChatVisitorId = visitor.id, Status='Completed',
            StartTime= datetime.newInstance(2017, 9, 15, 12, 30, 0), EndTime=datetime.newInstance(2017, 9, 15, 13, 30, 0),
            RequestTime=datetime.newInstance(2014, 9, 15, 13, 30, 0), DasherNo__c=2345, CustomerNo__c=35463,
            DeliveryNo__c=64754, DeliveryUUID__c='64754', MerchantNo__c =123, Issue__c='test', Issue_Details__c='test');     
        insert tx; 

        Test.startTest();   

        CDdChatTimerController.ChatInfo res = CDdChatTimerController.getChatInfo(tx.Id);
        System.assertNotEquals(res, null);

        res = CDdChatTimerController.getChatInfo(visitor.Id);
        System.assertEquals(res, null);
        
        Test.stopTest();

    }
}