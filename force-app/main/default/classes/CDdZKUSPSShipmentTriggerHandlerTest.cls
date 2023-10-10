/**
 * @description       : Test class for the CDdZKUSPSShipmentTriggerHandler
 * @author            : Jose Vega
 * @last modified on  : 06-16-2022
 * @last modified by  : Jose Vega
**/


/** 
 * @description Adding a line to add class to gearset
*/

@isTest public with sharing class CDdZKUSPSShipmentTriggerHandlerTest {

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
                Tablet_Received_Date_2__c = null
            );
            insert cs;     
        }
    }
   
    @isTest
    static void testUpdateCaseDeliveryStatusIsDelivered() {
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Case cs =[select Id, Status from Case limit 1];
            Test.startTest();
            zkusps__Shipment__c zk = new zkusps__Shipment__c();
            zk.Case__c = cs.Id;
            zk.zkusps__isDelivered__c = true;
            insert zk;

            Test.stopTest();
            cs =[select Id, Status from Case limit 1];
            System.assertEquals(CDdSupportConstants.RECEIVED_STATUS, cs.Status, 'Case Status should be Received');
        }
    }
    
    @isTest
    static void testUpdatepUdateCaseDeliveryStatusReturnToSender() {
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Case cs =[select Id, Status from Case limit 1];
            Test.startTest();

            zkusps__Shipment__c zk = new zkusps__Shipment__c();
            zk.Case__c = cs.Id;
            zk.zkusps__ReturnedToSender__c = true;
            zk.zkusps__lastTrackUpdateStatus__c = 'Delivered, To Original Sender';
            insert zk;

            Test.stopTest();
            
            cs =[select Id, Status from Case limit 1];
            
            System.assertEquals(CDdSupportConstants.RETURN_TO_SENDER_STATUS, cs.Status, 'Case Status should be Return to Sender');
        }
    }

    @isTest
    static void testUpdatepUdateCaseDeliveryStatusReturnToSenderOnUpdate() {
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Case cs =[select Id, Status from Case limit 1];
            Test.startTest();

            zkusps__Shipment__c zk = new zkusps__Shipment__c();
            zk.Case__c = cs.Id;
            insert zk;

            zk.zkusps__ReturnedToSender__c = true;
            zk.zkusps__lastTrackUpdateStatus__c = 'Delivered, To Original Sender';
            update zk;

            Test.stopTest();
            
            cs =[select Id, Status from Case limit 1];
            
            System.assertEquals(CDdSupportConstants.RETURN_TO_SENDER_STATUS, cs.Status, 'Case Status should be Return to Sender');
        }
    }
}