/**
 * @description       : Test class for ZKFedex Shipment Handler
 * @author            : Jose Vega
 * @last modified on  : 05-14-2022
 * @last modified by  : Jose Vega
**/
@isTest public with sharing class CDdZKFedexShipmentHandlerTest {
    /** 
    * @description Prepare test data
    */
    @testSetup 
    static void setup() {
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
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
                Return_Shipping_Address_State__c = 'Florida',
                Tablet_Received_Date_2__c = null,
                Tablet_Tracking_FedEx__c = null
            );
            insert cs;     
        }
    }
    
    @isTest
    static void testUpdateTabletReceivedDate() {
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Case cs =[select Id, Status from Case limit 1];
            Test.startTest();
            zkfedex__Shipment__c zk = new zkfedex__Shipment__c();
            zk.Case__c = cs.Id;
            zk.zkfedex__Delivered__c = true;
            insert zk;

            Test.stopTest();
            cs =[select Id, Status from Case limit 1];
            System.assertEquals(CDdSupportConstants.RECEIVED_STATUS, cs.Status, 'Case Status should be Received');
        }
    }
    
    /**
    * @description DISABLED IT THROWS CAS Load Error
    * @author Jose Vega | 05-14-2022 
    **/
    // @isTest
    // static void testFillInFedExTrackingNumberWhenShipmentCreated() {
    //     User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
    //     System.runAs(testUser){
    //         Case cs =[select Id, Status from Case limit 1];
    //         Test.startTest();

    //         zkfedex__Shipment__c zk = new zkfedex__Shipment__c();
    //         zk.Case__c = cs.Id;
    //         zk.zkfedex__MasterTrackingId__c = '575404811740';
    //         insert zk;

    //         Test.stopTest();
            
    //         cs =[select Id, Tablet_Tracking_FedEx__c from Case limit 1];
            
    //         System.assertEquals('575404811740', cs.Tablet_Tracking_FedEx__c, 'Case Status should be Return to Sender');
    //     }
    // }
}