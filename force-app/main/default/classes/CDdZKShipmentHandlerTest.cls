/* 
 * @Author Tia Xuan
 * @Date April 2020
 * @description The test class for CDdZKShipmentHandler
 * 
 */
@isTest
public class CDdZKShipmentHandlerTest {
    @TestSetup
    static void setup(){
         vCS__c s = VTestUtil.createVeltigSettings();
        insert s;

        Account acct = VTestUtil.createAccount('Test Account', true);
        acct.Deck_Rank__c = 'Queen';
        insert acct; 
        
        Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
        insert ctc;

        Case cs = new Case(
            AccountId = acct.Id,
            ContactId = ctc.Id,
            RecordTypeId = Schema.SObjectType.Case
                            .getRecordTypeInfosByName()
                            .get('Tablet Requests').getRecordTypeId(),
            subject = 'Test Case',
            Return_Label_Shipping_Contact_Name__c = 'test',
            Status = 'New',
            Tablet_Device_Type__c = 'Samsung Galaxy Tab E LTE',
            Shipping_Type__c = 'Standard',
            Request_Type__c  = 'Ship to Merchant (New Tablet, Printer)',
            Include_Large_Marketing_Kit__c = true,
            Include_Marketing_Kit__c = true,
            Return_Shipping_Address_State__c = 'Florida'
        );
        insert cs;      
    }

    @isTest
    static void stampStatusDescriptionOnCaseTestMulti() {
        Case cs =[select Id from Case limit 1];

        Test.startTest();

        zkmulti__MCShipment__c zk = new zkmulti__MCShipment__c();
        zk.Case__c = cs.Id;
        zk.zkmulti__Status_Description__c = 'test';
        zk.zkmulti__Last_Track_Update_Time__c = DateTime.now();
        insert zk;

        try {
            zk.zkmulti__Status_Description__c ='test1';
            update zk;
        } catch(exception e){
            // should end in error as updates are not allowed.
        }

        Test.stopTest();

        zkmulti__MCShipment__c z =  [select Id,
                                            zkmulti__Status_Description__c,
                                            zkmulti__Last_Track_Update_Time__c
                                    from zkmulti__MCShipment__c
                                    where Id =: zk.Id];

        Case c =[select Id, 
                            Tablet_Shipment_Status__c,
                            Tablet_Last_Track_Update_Time__c
                from Case
                where Id =: cs.Id];
        System.assertEquals(c.Tablet_Shipment_Status__c, z.zkmulti__Status_Description__c);
        System.assertEquals(c.Tablet_Last_Track_Update_Time__c, z.zkmulti__Last_Track_Update_Time__c);
    }

    @isTest
    static void stampStatusDescriptionOnCaseTestFedex() {
        Case cs =[select Id from Case limit 1];

        Test.startTest();

        zkfedex__Shipment__c zk = new zkfedex__Shipment__c();
        zk.Case__c = cs.Id;
        zk.zkfedex__StatusDescription__c = 'test';
        zk.zkfedex__LastTrackUpdateTime__c = DateTime.now();
        insert zk;

        try {
            zk.zkfedex__StatusDescription__c ='test1';
            update zk;
        } catch(exception e){
            // should end in error as updates are not allowed.
        }

        Test.stopTest();

        zkfedex__Shipment__c z =[select Id,
                                        zkfedex__StatusDescription__c,
                                        zkfedex__LastTrackUpdateTime__c
                                from zkfedex__Shipment__c
                                where Id =: zk.Id];

        Case c =[select Id, 
                        Tablet_Shipment_Status__c,
                        Tablet_Last_Track_Update_Time__c
                from Case
                where Id =: cs.Id];
        System.assertEquals(c.Tablet_Shipment_Status__c, z.zkfedex__StatusDescription__c);
        System.assertEquals(c.Tablet_Last_Track_Update_Time__c, z.zkfedex__LastTrackUpdateTime__c);
    }
    @isTest
    static void StampDateReturnedToSenderOnShipmentTestMultiInsertion() {
        Case cs =[select Id from Case limit 1];

        Test.startTest();

        zkmulti__MCShipment__c zk = new zkmulti__MCShipment__c();
        zk.Case__c = cs.Id;
        zk.zkmulti__Status_Description__c = 'Unsuccessful Delivery';
        insert zk;
        Test.stopTest();

        zkmulti__MCShipment__c z =  [select Id,
                                            zkmulti__Status_Description__c,
                                            zkmulti__Last_Track_Update_Time__c,Date_returned_to_sender__c
                                    from zkmulti__MCShipment__c
                                    where Id =: zk.Id];

        Case c =[select Id, 
                            Tablet_Shipment_Status__c,
                            Tablet_Last_Track_Update_Time__c, status
                from Case
                where Id =: cs.Id];
        System.debug('z test'+z);
        System.debug('c test'+c);
        System.assertEquals(system.today(), z.Date_returned_to_sender__c);
        System.assertEquals('Returned to Sender', c.status);
    }
    
    @isTest
    static void StampDateReturnedToSenderOnShipmentTestMultiUpdation() {
        Case cs =[select Id from Case limit 1];

        Test.startTest();

        zkmulti__MCShipment__c zk = new zkmulti__MCShipment__c();
        zk.Case__c = cs.Id;
        zk.zkmulti__Status_Description__c = 'Yet to be delivered';
        insert zk;

        try {
            zk.zkmulti__Status_Description__c ='Unsuccessful Delivery';
            update zk;
        } catch(exception e){
            // should end in error as updates are not allowed.
        }

        Test.stopTest();

        zkmulti__MCShipment__c z =  [select Id,
                                            zkmulti__Status_Description__c,
                                            zkmulti__Last_Track_Update_Time__c,Date_returned_to_sender__c
                                    from zkmulti__MCShipment__c
                                    where Id =: zk.Id];

        Case c =[select Id, 
                            Tablet_Shipment_Status__c,
                            Tablet_Last_Track_Update_Time__c, status
                from Case
                where Id =: cs.Id];
        System.debug('z test'+z);
        System.debug('c test'+c);
        System.assertEquals(system.today(), z.Date_returned_to_sender__c);
        System.assertEquals('Returned to Sender', c.status);
    }
    
    @isTest
    static void trackingNumberUpdateTest(){
        Case cs =[select Id from Case limit 1];
        cs.Request_Type__c = 'Email to Merchant (Return Label Only)';
        update cs;

        Test.startTest();

        zkmulti__MCShipment__c zk = new zkmulti__MCShipment__c();
        zk.Case__c = cs.Id;
        zk.zkmulti__Tracking_Number__c = '1941007962';
        insert zk;
        
        Test.stopTest();
        
        Case c = [SELECT Id, 
                  		 Tablet_Tracking__c,
                   		 Status
                  from Case
                  where Id =: cs.Id];
        
        System.assertEquals(c.Status, 'Shipped');
        System.assertEquals(c.Tablet_Tracking__c, zk.zkmulti__Tracking_Number__c);
    }
}