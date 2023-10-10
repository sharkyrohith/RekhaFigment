@isTest
public class VDeliveryTriggerHandlerTest {
    
    public static testMethod void testInsertUpdate() {
        
        Trigger_Control_Panel__c tcpSettings = new Trigger_Control_Panel__c(Account_Trigger_Enabled__c=false,
                                                                           Name='TestCP');
        insert tcpSettings;
        
        Account testMerch = new Account(Restaurant_ID__c='0721',
                                       Name='Test Merchant');
        insert testMerch;
        
        Account testCust = new Account(FirstName='Test',
                                      LastName='Customer',
                                      CustomerNo__pc=0722);
        insert testCust;
        
        Account testCust2 = new Account(FirstName='Test',
                                      LastName='Customer2',
                                      CustomerNo__pc=0723);
        insert testCust2;
        
        Account testDash = new Account(Firstname='Test',
                                      LastName='Dasher',
                                      DasherNo__pc=0724);
        insert testDash;
        
       // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        Delivery__c testDelivery = new Delivery__c(MerchantNo__c=0721,
                                                  CustomerNo__c=0722,
                                                  DasherNo__c=0724,
                                                  DeliveryNo__c=0725,
                                                  DeliveryUUID__c='0725');
        insert testDelivery;
        
        testDelivery.CustomerNo__c = 0723;
        update testDelivery;
        
    }
}