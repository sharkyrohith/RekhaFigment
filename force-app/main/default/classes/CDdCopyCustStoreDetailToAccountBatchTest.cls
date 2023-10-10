/**
 * @description       : DELETE ME
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 03-22-2022
 * @last modified by  : Jose Vega
**/
@isTest
public class CDdCopyCustStoreDetailToAccountBatchTest {
//     public static final String SOBJECT_TYPE_ACCOUNT = 'Account';	
//     public static final Id TEST_ROLE_ID;
//     public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';    
//     public static final Id SYSTEM_ADMIN_PROFILE_ID;
//     public static final Integer THRESHOLD_SIZE;

//     static {
//         TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
//         SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
// 		THRESHOLD_SIZE = new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_ACCOUNT);                
//     }
//    /** 
//     * @description Prepare and return the test running user
//     */
//     private static User getTestRunUser() {
//         User testRunUser = null;
//         for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
//             testRunUser = u;
//         }
//         if (testRunUser == null){
//             testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0]; 
//             testRunUser.Username = TEST_DD_RUN_USERNAME;
//         }
//         return testRunUser;
//     }
//    /** 
//     * @description Prepare test data
//     */
//     @TestSetup
//     static void setup() {
//         System.runAs(getTestRunUser()){
//             Test.startTest();

//             E2F__FindApi_Triggers_Settings__c findAPISettings = new E2F__FindApi_Triggers_Settings__c(
//                                                                 SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID
//                                                                 , Name = 'System Administrator'
//                                                                 , E2F__Bypass_Trigger__c = true
//                                                             );
//             insert findAPISettings;

//             Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
//             cp.Name = 'Main';
//             cp.Opportunity_Trigger_Enabled__c = true;
//             cp.Account_Trigger_Enabled__c = true;
//             upsert cp;

//             vCS__c s = VTestUtil.createVeltigSettings();
//             s.parentAccMatchFlag__c = true;
//             s.copyFieldsFromParent__c = true;
//             s.SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID;
//             insert s;

//             Test.stopTest();
//         }
//     }      	
//     /**
//     * @description BZAP-8812 - Store Details Re-Arch: Update Account Trigger
//     */
//     @isTest
//     static void testCreateCustomerDetails() {
//         System.runAs (getTestRunUser()) {
//             // Test.startTest();
//             // List<Account> accounts = TDdAccountFactory.createAccounts('Test_Cust_Details ', THRESHOLD_SIZE + 1);
//             // for (Account a : accounts){
// 	        //     a.RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.corporateCustomersId();
// 	        //     a.Industry = 'Finance';
// 	        //     a.NumberOfEmployees  = 100;            	
//             // }
//             // insert accounts;
//             // Test.getEventBus().deliver();
//             // Test.stopTest();
//             // List<Account> accountFromDB = [SELECT Id, RecordTypeId, Customer_Detail__c, Store_Details__c FROM Account WHERE Id IN :accounts];
//             // Account customDetailRecordAccount = accountFromDB[0];
//             // // System.assertEquals(true, customDetailRecordAccount!=null);
//             // Customer_Detail__c customDetailRecord = [SELECT Id FROM Customer_Detail__c WHERE Account__c = :customDetailRecordAccount.Id LIMIT 1];
//             // // System.assertEquals(true, customDetailRecord!=null);
//             // // System.assertEquals(customDetailRecordAccount.Customer_Detail__c, customDetailRecord.Id);
//         }
//     }
//     /**
//     * @description BZAP-8812 - Store Details Re-Arch: Update Account Trigger
//     */
//     @isTest
//     static void testCreateStoreDetails() {
//         List<Account> accounts = TDdAccountFactory.createAccounts('Test_Store_Details ', THRESHOLD_SIZE + 1);
//         for (Account a : accounts){
//             a.RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.prospectId();
//         }
//         insert accounts;        
//         System.runAs (getTestRunUser()) {
//             Test.startTest();
//             new CDdCopyCustStoreDetailToAccountBatchSch(CDdCopyCustStoreDetailToAccountBatchSch.fieldCopyOptionType.COPY_STORE_DETAIL_TO_ACCOUNT.ordinal(), THRESHOLD_SIZE + 1).execute(null);
//             Test.stopTest();
//             List<Account> accountFromDB = [SELECT Id, RecordTypeId, Customer_Detail__c, Store_Details__c FROM Account WHERE Id IN :accounts];
//             Account storeDetailRecordAccount = accountFromDB[0];
//             System.assertEquals(true, storeDetailRecordAccount!=null);
//             Store_Details__c storeDetailRecord = [SELECT Id FROM Store_Details__c WHERE Account__c = :storeDetailRecordAccount.Id LIMIT 1];
//             System.assertEquals(true, storeDetailRecord!=null);
//             System.assertEquals(storeDetailRecordAccount.Store_Details__c, storeDetailRecord.Id);
//         }
//     }    
}