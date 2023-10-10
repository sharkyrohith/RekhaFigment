/**
 * @description       : 
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 04-25-2022
 * @last modified by  : Jose Vega
**/

/** 
 * @description Adding a line to add class to gearset
*/

@isTest public with sharing class CDdZkmultiMCShipmentTriggerHandlerTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    }    
   /** 
    * @description Prepare and return the test running user
    */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0]; 
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }       
   /** 
    * @description Prepare test data
    */
    @testSetup 
    static void setup() {
        System.runAs(getTestRunUser()){
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
    static void testAfterInsert() {
        System.runAs(getTestRunUser()){
            Case cs =[select Id, Status from Case limit 1];
            Test.startTest();
            zkmulti__MCShipment__c zk = new zkmulti__MCShipment__c();
            zk.Case__c = cs.Id;
            zk.zkmulti__Status_Description__c = 'test';
            zk.zkmulti__Last_Track_Update_Time__c = DateTime.now();
            zk.zkmulti__Delivered__c = true;
            zk.Date_returned_to_sender__c = null;
            insert zk;
            Test.stopTest();
            cs =[select Id, Status from Case limit 1];
            System.assertEquals('Received', cs.Status, 'Case Status should be Received');
        }
    }
    
    @isTest
    static void testAfterUpdate() {
        System.runAs(getTestRunUser()){
            Case cs =[select Id, Status from Case limit 1];
            Test.startTest();

            zkmulti__MCShipment__c zk = new zkmulti__MCShipment__c();
            zk.Case__c = cs.Id;
            zk.zkmulti__Status_Description__c = 'test';
            zk.zkmulti__Last_Track_Update_Time__c = DateTime.now();
            insert zk;
            
            cs.Status = 'Closed';
            update cs;
            
            zk.zkmulti__Delivered__c = true;
            zk.Date_returned_to_sender__c = null;
            update zk;
            
            Test.stopTest();
            
			cs =[select Id, Status from Case limit 1];
            
            System.assertEquals('Received', cs.Status, 'Case Status should be Received');
        }
    }
}