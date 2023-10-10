/**
 * CDdVendorSplitHelperTest
 *
 * @author     Sahil
 * @date  2021-08-13
 * @decription Test class for CDdVendorSplitHelper
 */
@isTest(seeAllData=false)
public with sharing class CDdVendorSplitHelperTest {
    /*****************************************************************************************************************************
    *
    * Constants & Private Variables
    *
    *****************************************************************************************************************************/
    private static Id vendor1QId;
    private static Id vendor2QId;
    private static Id vendor3QId;
    private static Id vendor4QId;
    private static Id vendor5QId;
    private static final String Q_VENDOR1 = 'Vendor1Queue';
    private static final String Q_VENDOR2 = 'Vendor2Queue';
    private static final String Q_VENDOR3 = 'Vendor3Queue';
    private static final String Q_VENDOR4 = 'Vendor4Queue';
    private static final String Q_VENDOR5 = 'Vendor5Queue';
    private static final String SB_TEST_CHANNEL = 'sendbird_group_channel_8642_5a9d6c930f464908d6aaacb9a606d69cac1f169b';
    private static final String Q_SB_CX_VENDOR1 = 'Sendbird_Cx_TaskUs';
    private static final String Q_SB_CX_VENDOR2 = 'Sendbird_Cx_Telus';
    private static final String Q_SB_CX_VIP_VENDOR1 = 'Sendbird_Cx_VIP_TaskUs';
    private static final String Q_SB_CX_VIP_VENDOR2 = 'Sendbird_Cx_VIP_Telus';
    private static final String Q_SB_MX = 'Sendbird_Mx';
    private static final String Q_SB_MX_TTec = 'Sendbird_Mx_TTec';
    private static final String SENDBIRD_CX = 'Sendbird_Cx';

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }


    /**
    * @author     Sahil
    * @date  2021-08-11
    * @decription insert test user
    * @param   None
    * @return  User
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

    static {
        List<Group> groups = new List<Group>();
        List<QueuesObject> queueVendors = new List<QueuesObject>();
        //insert 5 test vendor queues in database
        for (Integer i = 1; i < 6; i++) {
            Group grpVendor = new Group(Name='Vendor'+i+CDdSupportConstants.GROUP_QUEUE, Type = CDdSupportConstants.GROUP_QUEUE);
            groups.add(grpVendor);
        }

        insert groups;

        System.runAs(new User(Id=UserInfo.getUserId())) {
            for(Group grpVendor : groups) {
                //Associating queue with group AND to the Case object
                queueVendors.add(new QueueSObject(QueueID = grpVendor.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL));
            }
            insert queueVendors;
        }

        //get queue ids from database to use in support mapping
        List<Group> queueList = [SELECT Id, DeveloperName FROM Group
                                    WHERE Type =: CDdSupportConstants.GROUP_QUEUE
                                    AND (DeveloperName =: Q_VENDOR1
                                    OR DeveloperName =: Q_VENDOR2
                                    OR DeveloperName =: Q_VENDOR3
                                    OR DeveloperName =: Q_VENDOR4
                                    OR DeveloperName =: Q_VENDOR5)];
        //get queue Ids
        for (Group queueVar : queueList) {
            if (queueVar.DeveloperName == Q_VENDOR1) {
                vendor1QId = queueVar.Id;
            } else if (queueVar.DeveloperName == Q_VENDOR2) {
                vendor2QId = queueVar.Id;
            } else if (queueVar.DeveloperName == Q_VENDOR3) {
                vendor3QId = queueVar.Id;
            } else if (queueVar.DeveloperName == Q_VENDOR4) {
                vendor4QId = queueVar.Id;
            } else if (queueVar.DeveloperName == Q_VENDOR5) {
                vendor5QId = queueVar.Id;
            }
        }
    }

    /**
    * @author     Sahil
    * @date  2021-08-11
    * @decription insert custom settings for case routing
    * @param   None
    * @return  None
    */
    private static void insertSupMapping() {
        List<Support_Assignment_Mapping__c> lstToInsert = new List<Support_Assignment_Mapping__c>();
        //insert custom settings
        Support_Assignment_Mapping__c sbCxVd1Mapping = new Support_Assignment_Mapping__c();
        sbCxVd1Mapping.Name = 'Sendbird Cx Vendor1';
        sbCxVd1Mapping.Queue_Id__c = vendor1QId;
        sbCxVd1Mapping.Support_Assignment_Name__c = Q_SB_CX_VENDOR1;
        sbCxVd1Mapping.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
        lstToInsert.add(sbCxVd1Mapping);

        Support_Assignment_Mapping__c sbCxVd2Mapping = new Support_Assignment_Mapping__c();
        sbCxVd2Mapping.Name = 'Sendbird Cx Vendor2';
        sbCxVd2Mapping.Queue_Id__c = vendor2QId;
        sbCxVd2Mapping.Support_Assignment_Name__c = Q_SB_CX_VENDOR2;
        sbCxVd2Mapping.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
        lstToInsert.add(sbCxVd2Mapping);

        Support_Assignment_Mapping__c sbCxVd1MappingVIP = new Support_Assignment_Mapping__c();
        sbCxVd1MappingVIP.Name = 'Sendbird Cx VIP Vendor1';
        sbCxVd1MappingVIP.Queue_Id__c = vendor3QId;
        sbCxVd1MappingVIP.Support_Assignment_Name__c = Q_SB_CX_VIP_VENDOR1;
        sbCxVd1MappingVIP.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
        lstToInsert.add(sbCxVd1MappingVIP);

        Support_Assignment_Mapping__c sbCxVd2MappingVIP = new Support_Assignment_Mapping__c();
        sbCxVd2MappingVIP.Name = 'Sendbird Cx VIP Vendor2';
        sbCxVd2MappingVIP.Queue_Id__c = vendor4QId;
        sbCxVd2MappingVIP.Support_Assignment_Name__c = Q_SB_CX_VIP_VENDOR2;
        sbCxVd2MappingVIP.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
        lstToInsert.add(sbCxVd2MappingVIP);

        Support_Assignment_Mapping__c sbMxVd5Mapping = new Support_Assignment_Mapping__c();
        sbMxVd5Mapping.Name = 'Sendbird Chat Mx';
        sbMxVd5Mapping.Queue_Id__c = vendor5QId;
        sbMxVd5Mapping.Support_Assignment_Name__c = Q_SB_MX;
        sbMxVd5Mapping.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
        lstToInsert.add(sbMxVd5Mapping);

        insert lstToInsert;
    }

    /**
    * @author     Sahil
    * @date  2021-08-11
    * @decription test setup
    * @param   None
    * @return  None
    */
    @TestSetup
    static void makeData() {
        //setup data here
        System.runAs(getTestRunUser()){
            //insert queues and custom settings
            //insertSupMapping();
            //enable running case trigger
            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;
            TDdCaseFactory.getSupportFeatureFlag(true);
            //vendor and chat button distributions
            Chat_Button_Distribution__c testCBDist = new Chat_Button_Distribution__c(
                Chat_Button_API_Name__c = SENDBIRD_CX
            );
            insert testCBDist;
            Chat_Button_Distribution__c testMXCBDist = new Chat_Button_Distribution__c(
                Chat_Button_API_Name__c = Q_SB_MX
            );
            insert testMXCBDist;
            // create vendor distributions (one at 40%, one at 60%)
            List<Vendor_Distribution__c> lstVdInsert = new List<Vendor_Distribution__c>();
            Vendor_Distribution__c testVendDistTaskUs = new Vendor_Distribution__c(
                                                            Chat_Button_Distribution__c = testCBDist.Id,
                                                            Vendor__c = 'TaskUs',//restricted picklist
                                                            Target_Distribution__c = 40,
                                                            Actual_Chat_Count__c = 0);
            lstVdInsert.add(testVendDistTaskUs);
            Vendor_Distribution__c testMXVendDistTaskUs = new Vendor_Distribution__c(
                                                            Chat_Button_Distribution__c = testMXCBDist.Id,
                                                            Vendor__c = 'TaskUs',//restricted picklist
                                                            Target_Distribution__c = 40,
                                                            Actual_Chat_Count__c = 0);
            lstVdInsert.add(testMXVendDistTaskUs);

            Vendor_Distribution__c testVendDistTelus = new Vendor_Distribution__c(
                                                           Chat_Button_Distribution__c = testCBDist.Id,
                                                           Vendor__c = 'Telus',//restricted picklist
                                                           Target_Distribution__c = 60,
                                                           Actual_Chat_Count__c = 0);
            lstVdInsert.add(testVendDistTelus);
            Vendor_Distribution__c testMXVendDistTTec = new Vendor_Distribution__c(
                                                           Chat_Button_Distribution__c = testMXCBDist.Id,
                                                           Vendor__c = 'TTec',//restricted picklist
                                                           Target_Distribution__c = 60,
                                                           Actual_Chat_Count__c = 0);
            lstVdInsert.add(testMXVendDistTTec);
            insert lstVdInsert;

            //insert VIP
            List<Audience_Attribute__c> lstAudiceAttribute = new List<Audience_Attribute__c>();
            lstAudiceAttribute.add(new Audience_Attribute__c(Audience_ID__c = 1234));
            lstAudiceAttribute.add(new Audience_Attribute__c(Audience_ID__c = 123456, VIP__c = -1));
            lstAudiceAttribute.add(new Audience_Attribute__c(Audience_ID__c = 0001,VIP__c = 98));//Right Whale
            lstAudiceAttribute.add(new Audience_Attribute__c(Audience_ID__c = 0002,VIP__c = 94));//Sei Whale
            insert lstAudiceAttribute;

            //insert a cx support sendbird case
            List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
            casesToTest[0].ChatKey__c = SB_TEST_CHANNEL;
            casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
            casesToTest[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
            casesToTest[0].Customer_Type__c = 'Consumer';
            insert casesToTest;

            List<Customer_Segment_Mapping__c> lstCustomerSetting =new List<Customer_Segment_Mapping__c>();
            lstCustomerSetting.add(new Customer_Segment_Mapping__c(Name='Test1',Audience_Attribute_Number__c =98,Customer_Segment__c='Right Whale',Is_Active__c=true,Is_VIP__c=true));
            lstCustomerSetting.add(new Customer_Segment_Mapping__c(Name='Test2',Audience_Attribute_Number__c =94,Customer_Segment__c='Sei Whale',Is_Active__c=true,Is_VIP__c=true));
            lstCustomerSetting.add(new Customer_Segment_Mapping__c(Name='Test3',Audience_Attribute_Number__c =-1,Customer_Segment__c='Offender',Is_Active__c=true,Is_VIP__c=true));
            insert lstCustomerSetting;
        }
    }

    /**
     * @author     Sahil
     * @date  2021-08-11
     * @decription test set preferred vendor
     * @param   None
     * @return  None
     */
    @isTest
    static void testSetPreferredVendor() {
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = SB_TEST_CHANNEL;
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
        casesToTest[0].Customer_Type__c = 'Consumer';
        CDdVendorSplitHelper.iVCCFuture = true;
        CDdVendorSplitHelper.iVCCPlatEvent = false;
        Test.startTest();
        insert casesToTest;
        Test.stopTest();
        //assert
        Case caseFromDB = [SELECT Preferred_Vendor__c, OwnerId,Routing_Destination__c
                            FROM Case WHERE Id =:casesToTest[0].Id LIMIT 1];
        List<String> queueNames = new List<String>();
        Map<String,String> mapVendorQueueDevName = new Map<String,String>();
        for(Routing_Configuration__mdt rConfig: Routing_Configuration__mdt.getAll().values()){
            if(rConfig.Routing_Destination_Name__c == caseFromDB.Routing_Destination__c){
                if(rConfig.Do_Vendor_Split__c){
                    Map<String,Object> mapFieldValue = (Map<String,Object>) JSON.deserializeUntyped(rConfig.Owner_Queue_Name__c);
                    for(String vendorName : mapFieldValue.keySet()){
                        String vendoQDevName = String.valueOf(mapFieldValue.get(vendorName));
                        queueNames.add(vendoQDevName);
                        mapVendorQueueDevName.put(vendorName,vendoQDevName);
                    }
                }
                break;
            }
        }
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);
        System.assertNotEquals(null, caseFromDB.Preferred_Vendor__c, 'Preferred vendor cannot be blank');
        if(String.isNotBlank(caseFromDB.Preferred_Vendor__c)){
            Id ownerQId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(mapVendorQueueDevName.get(caseFromDB.Preferred_Vendor__c));
            System.assertEquals(ownerQId, caseFromDB.OwnerId, 'Owner should be the queue on config');
        }
        List<Chat_Button_Distribution__c> consumerChatButton = [SELECT ID FROM Chat_Button_Distribution__c
                                                                WHERE Chat_Button_API_Name__c =:SENDBIRD_CX];
        List<Vendor_Distribution__c> vdList = [SELECT Id, Vendor__c, Actual_Chat_Count__c
                                                        FROM Vendor_Distribution__c WHERE Chat_Button_Distribution__c =:consumerChatButton[0].Id];
        System.assertEquals(2, vdList.size(), 'There should be 2 Vendor Dist in the database');
        for (Vendor_Distribution__c vdVar : vdList) {
            if (vdVar.Vendor__c == 'Telus' && String.isNotBlank(caseFromDB.Preferred_Vendor__c)
                    && caseFromDB.Preferred_Vendor__c == 'Telus') {
                System.assertEquals(1, vdVar.Actual_Chat_Count__c, 'Actual chat count should be 1');
            } else if (vdVar.Vendor__c == 'TaskUs' && String.isNotBlank(caseFromDB.Preferred_Vendor__c)
                        && caseFromDB.Preferred_Vendor__c == 'TaskUs') {
                System.assertEquals(1, vdVar.Actual_Chat_Count__c, 'Actual chat count should be 1');
            }
        }

    }


     /**
     * @author     Sahil
     * @date  2021-08-11
     * @decription test set actual vendor
     * @param   None
     * @return  None
     */
    @isTest
    static void testSetActualVendor() {
        //create a test agent user
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
        testUser.Email = 'testuser@doordash.com';//actual vendor should match agent's email/company name
        insert testUser;

        Case caseToTest = [SELECT Id, OwnerId, Description, Actual_Vendor__c FROM Case WHERE Customer_Type__c = 'Consumer'
                            AND Channel__c =: CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD
                            LIMIT 1];

        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        CDdVendorSplitHelper.tUVDFuture = true;
        CDdVendorSplitHelper.tUVDPlatEvent = false;
        Test.startTest();
        //when case is inserted, the owner is a queue. To set actual vendor, previous owner of the case should be a user
        //so updating twice would ensure the previous owner is a user instead of a queue
        caseToTest.OwnerId = testUser.Id;
        update caseToTest;
        //user updates case
        caseToTest.Description = 'Test Description';
        update caseToTest;
        Test.stopTest();
        //assert
        Case caseFromDB = [SELECT Actual_Vendor__c FROM Case WHERE Id =:caseToTest.Id LIMIT 1];
        System.assertEquals('DoorDash', caseFromDB.Actual_Vendor__c, 'Actual vendor should be Doordash');
    }

     /**
     * @author     Sahil
     * @date  2021-08-11
     * @decription test set actual vendor with platform events
     * @param   None
     * @return  None
    */
    @isTest
    static void testSetActualVendorPE() {
        //create a test agent user
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
        testUser.Email = 'testuser@doordash.com';//actual vendor should match agent's email/company name
        insert testUser;

        Case caseToTest = [SELECT Id, OwnerId, Description, Actual_Vendor__c FROM Case WHERE Customer_Type__c = 'Consumer'
                            AND Channel__c =: CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD
                            LIMIT 1];

        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        CDdVendorSplitHelper.tUVDFuture = false;
        CDdVendorSplitHelper.tUVDPlatEvent = true;
        Test.startTest();
        //when case is inserted, the owner is a queue. To set actual vendor, previous owner of the case should be a user
        //so updating twice would ensure the previous owner is a user instead of a queue
        caseToTest.OwnerId = testUser.Id;
        update caseToTest;
        //user updates case
        caseToTest.Description = 'Test Description';
        update caseToTest;
        Test.stopTest();
        //assert
        Case caseFromDB = [SELECT Actual_Vendor__c FROM Case WHERE Id =:caseToTest.Id LIMIT 1];
        System.assertEquals('DoorDash', caseFromDB.Actual_Vendor__c, 'Actual vendor should be Doordash');
    }

    /**
     * @author     Sahil
     * @date  2021-08-11
     * @decription test set case owner without matching chat button distribution
     * @param   None
     * @return  None
     */
    @isTest
    static void testSetCaseOwner() {
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = SB_TEST_CHANNEL;
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
        casesToTest[0].Customer_Type__c = 'Merchant';

        Test.startTest();
        insert casesToTest;
        Test.stopTest();
        //assert
        Case caseFromDB = [SELECT OwnerId,Routing_Destination__c FROM Case WHERE Id =:casesToTest[0].Id LIMIT 1];
        System.assertEquals('Sendbird_Mx', caseFromDB.Routing_Destination__c, 'Routing Destination should be Sendbird_Mx');
        String ownerName = '';
        for(Routing_Configuration__mdt rConfig: Routing_Configuration__mdt.getAll().values()){
            if(rConfig.Routing_Destination_Name__c == caseFromDB.Routing_Destination__c){
                ownerName = rConfig.Owner_Queue_Name__c;
                break;
            }
        }
        CDdGenericTriggerOptimizationHelper.setQueueMap(new List<String>{ownerName});
        System.assertEquals(CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(ownerName), caseFromDB.OwnerId, 'Owner should be Vendor5 Queue');

    }

    /**
     * @author     Mahesh Chouhan
     * @date  May 2022
     * @decription test set case owner for Case Offenders
     * @param   None
     * @return  None
     */
    @isTest
    static void testSetCaseOwnerForOffendors() {
        Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
        ftrFlag.Enable_Case_Trigger_Optimization__c = true;
        insert ftrFlag;
        TDdCaseFactory.getSupportFeatureFlag(true);
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].Origin = 'Web';
        casesToTest[0].Customer_Type__c = 'Merchant';
        casesToTest[0].Formstack_Category__c = 'Payments';
        casesToTest[0].Formstack_Subcategory__c = 'Error Charge Disputes';
        casesToTest[0].Store_ID__c = '123456';
        casesToTest[0].Single_Multi_Location_Menu_Update__c = CDdSupportConstants.FORMSTACK_STORE_LOCATION_SINGLE_LOCATION;

        Test.startTest();
        insert casesToTest;
        Test.stopTest();

        Case caseFromDB = [SELECT Status, Customer_Segment__c FROM Case WHERE Id =:casesToTest[0].Id LIMIT 1];
        System.assertEquals(CDdSupportConstants.CLOSED_STATUS, caseFromDB.Status, 'Case Status is not updated to Closed');
        System.assertEquals(CDdSupportConstants.CUSTOMER_SEGMENT_OFFENDER, caseFromDB.Customer_Segment__c, 'Customer Segment on Case is not updated to Offender');
    }

     /**
     * @author  Nayana
     * @date   2022-03
     * @decription test set case for Right Whale
     * @param   None
     * @return  None
     */
    @isTest
    static void testSendbirdRightWhaleVIP() {
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = SB_TEST_CHANNEL;
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
        casesToTest[0].Customer_Type__c = 'Consumer';
        casesToTest[0].Consumer_ID__c = 0001;
        Test.startTest();
        insert casesToTest;
        Test.stopTest();
        //assert
        Case caseFromDB = [SELECT OwnerId,Customer_Segment__c FROM Case WHERE Id =:casesToTest[0].Id LIMIT 1];
        System.assertEquals('Right Whale', caseFromDB.Customer_Segment__c, 'Customer Segment should be Right Whale');
        //Need to add ownerId check once config is turned ON in Prod
    }

     /**
     * @author  Nayana
     * @date    Mar 22
     * @decription test set case for sei whale
     * @param   None
     * @return  None
     */
    @isTest
    static void testSendbirdSeiWhaleVIP() {
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = SB_TEST_CHANNEL;
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
        casesToTest[0].Customer_Type__c = 'Consumer';
        casesToTest[0].Consumer_ID__c = 0002;
        Test.startTest();
        insert casesToTest;
        Test.stopTest();
        //assert
        Case caseFromDB = [SELECT OwnerId,Customer_Segment__c FROM Case WHERE Id =:casesToTest[0].Id LIMIT 1];
        System.assertEquals('Sei Whale', caseFromDB.Customer_Segment__c, 'Customer Segment should be Sei Whale');
        //Need to add ownerId check once config is turned ON in Prod
    }


     /**
     * @author  Nayana
     * @date    Mar 22
     * @decription test set case for blank custmer Segment
     * @param   None
     * @return  None
     */
    @isTest
    static void testNullCustomerSegment() {
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = SB_TEST_CHANNEL;
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
        casesToTest[0].Customer_Type__c = 'Consumer';
        casesToTest[0].Consumer_ID__c = 50000;
        Test.startTest();
        insert casesToTest;
        Test.stopTest();
        //assert
        Case caseFromDB = [SELECT OwnerId,Customer_Segment__c FROM Case WHERE Id =:casesToTest[0].Id LIMIT 1];
        System.assertEquals(null, caseFromDB.Customer_Segment__c, 'Customer Segment should be null as customer not part of VIP list');
        //Need to add ownerId check once config is turned ON in Prod
    }
}