/********************************************************************************************************************
* @author Praveen
* @date 14/07/2022
*
* @group Merchant Services
*
* @description test class for CDdMxEquipmentRequestController.
*
**************************************************************************************************************************************/

@isTest
public with sharing class CDdMxEquipmentRequestControllerTest {
    /*****************************************************************************************************************************
    *
    \
    * Public/Global Variables
    *
    *****************************************************************************************************************************/

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String OPP_NAME_CHILD = 'MxSx_Test_Opp_123';
    public static final String OPP_NAME_PARENT = 'MxSx';
    public static String TEST_MX_ORDER_REQUEST_COUNTRY_CODE = 'US';
    public static String ACCOUNT_RECORD_MARKETPLACE = 'Marketplace';
    public static String ACCOUNT_RECORD_PARENT_ACCOUNT = 'Parent Account';
    public static contact testContact;
    public static final String OPP_OBJECT = 'Opportunity';
    public static final String CONTACT_OBJECT = 'Contact';
    public static final String TABLET_IMEI = 'tablet';
    public static final String PRINTER_IMEI = 'printer';
    public static final String ORDER_PROTOCOL = CDdMxSxConstants.getEquipmentRequestOrderProtocol();
    public static final String DEFAULT_ORDER_PROTOCOL = 'POS and and Tablet (DoorDash Owns)';
    public static final String CASE_RECORD_TYPE = 'Tablet Requests';
    public static String TEST_MX_ORDER_REQUEST_TYPE = 'Ship to Merchant (New Tablet)';
    public static String PRINTER_MX_ORDER_REQUEST_TYPE = 'Ship to Merchant (New Tablet, Printer)';

    public static String SHIPPING_TYPE = 'Standard';
    public static String REASON_FOR_REPLACEMENT = 'Tablet Stolen';
    public static String TEST_TABLET_IMEI = '12345';
    public static String TEST_CASE_ORIGIN_FOLLOWUP = 'UI - Follow Up Tablet Request';
    public static String TEST_CASE_ORIGIN_NEWREQUEST = 'UI - New Tablet Request';
    public static String ACCOUNT_NAME = 'DoorDash';
    public static String PRINTER_PERMISSION_SET_NAME = 'Bypass_Printer_Block';

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }
    /**
    * @description Prepare and return the test running user
    */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]) {
            testRunUser = u;
        }
        if (testRunUser == null) {
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    /**
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()) {
            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            validation.Bypass_Case_Validations__c = true;
            insert validation;

            Test.startTest();
            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_CPU_Time_Check__c = true;
            ftrFlag.Enable_Debug_Logs__c = true;
            ftrFlag.Enable_Case_Trigger_Optimization__c = true;
            insert ftrFlag;

            Account account = TDdAccountFactory.createAccount(ACCOUNT_RECORD_MARKETPLACE);
            account.Business_ID__c = 1234567;
            account.Name = ACCOUNT_NAME;
            account.iPad_Username__c = '12345678';
            account.iPad_Password__c = '12345678';
            insert account;
            // actList.add(account);
            Account parentAccount = TDdAccountFactory.createAccount(ACCOUNT_RECORD_PARENT_ACCOUNT);
            parentAccount.Business_ID__c = 123456237;
            //actList.add(parentAccount);
            insert parentAccount;

            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;

            List<string> orderProtocols = String.isNotBlank(ORDER_PROTOCOL) ? ORDER_PROTOCOL.split(',') : new List<string>{ DEFAULT_ORDER_PROTOCOL };
                List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(OPP_NAME_CHILD, account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            opp.Commission__c = 15;
            opp.In_App_Pickup_Commission__c = 15;
            opp.Order_Protocol__c = orderProtocols[0];
            opp.DashPass_Only_Commission__c = 15;
            opp.Referred_Delivery_Commission__c = 15;
            opp.Referred_Pickup_Commission__c = 15;
            opp.Weekly_Printer_Subscription_Fee__c = '$0';
            opp.Activation_Fee__c = '$0';
            opp.Weekly_Tablet_Subscription_Fee__c = '$3';

            Opportunity parentOpp = TDdOpportunityFactory.createOpportunityByDevRT(OPP_NAME_PARENT, parentAccount.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            oppList.add(opp);
            oppList.add(parentOpp);
            insert oppList;

            List<Mx_Product__c> mxProducts = CDdMxTestDataFactory.createMxProducts();
            CDdMxTestDataFactory.createMxOrderRequest(TEST_MX_ORDER_REQUEST_TYPE, TEST_MX_ORDER_REQUEST_COUNTRY_CODE, mxProducts);
            CDdMxTestDataFactory.createReturnMxOrderRequest(CDdMxSxConstants.RETURN_REQUEST_TYPE, TEST_MX_ORDER_REQUEST_COUNTRY_CODE, mxProducts);
            CDdMxEquipmentRequestModel cs = new CDdMxEquipmentRequestModel();
            cs.AccountId = account.Id;
            cs.ContactId = contact.Id;
            cs.OppId = opp.Id;
            cs.requestType = TEST_MX_ORDER_REQUEST_TYPE;
            cs.shippingType = SHIPPING_TYPE;
            cs.tabletImei = TEST_TABLET_IMEI;
            cs.returnProducts = new List<String>{ mxProducts[0].Id };
            cs.newProducts = new List<String>{ mxProducts[0].Id };
            cs.returnReplaceComponent = 'Yes';
            cs.replacementReason = REASON_FOR_REPLACEMENT;
            cs.isLemonadeAccount = false;
            String payLoad = JSON.serialize(cs);
            CDdMxEquipmentRequestController.CreateCases(payLoad);
            Test.stopTest();
        }
    }

    /**
    * @description testCreateCase method will run tests for creating cases from UI.
    */
    @isTest
    static void testCreateReturnCase() {
        System.runAs(getTestRunUser()) {
            Account act = getaccountbyName(ACCOUNT_NAME);
            List<Mx_Product__c> mxProducts = [SELECT id FROM Mx_Product__c limit 10];
            Case returnCase = [
                SELECT id, origin
                FROM case
                WHERE Type_Of_Mx_Order__c = :CDdMxSxConstants.TYPE_OF_MX_ORDER_RETURN AND createddate >= today AND recordtypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS
                LIMIT 1
            ];
            System.assertEquals(TEST_CASE_ORIGIN_NEWREQUEST, returnCase.origin, 'case origin not matching');
            Mx_Order__c mx = [SELECT id, case__c, Vendor__c, Type_Of_Mx_Order__c FROM Mx_Order__c WHERE case__c = :returnCase.Id AND Type_Of_Mx_Order__c = :CDdMxSxConstants.TYPE_OF_MX_ORDER_RETURN];
            List<Mx_Order_Item__c> orderItems = [SELECT id, Identifier__c, Mx_Product__c FROM Mx_Order_Item__c WHERE Mx_Order__c = :mx.Id];
            String vendor = CDdMxSxConstants.MX_VENDOR_SOCIAL_MOBILE;
            System.assertEquals(vendor, mx.Vendor__c, 'Expecting the vendor value - ' + vendor);

            System.assertEquals(true, returnCase != null, 'Expecting Return Tablet case');
            System.assertEquals(true, mx != null, 'Expecting Mx return Order for the case');
            System.assertEquals(CDdMxSxConstants.TYPE_OF_MX_ORDER_RETURN, mx.Type_Of_Mx_Order__c, 'Expecting return Mx Order');
            System.assertEquals(1, orderItems.size(), 'Expecting single order item');
            System.assertEquals(mxProducts[0].Id, orderItems[0].Mx_Product__c, 'Mx return order item Product not matching');
            System.assertEquals(TEST_TABLET_IMEI, orderItems[0].Identifier__c, 'Incorrect defect tablet IMEI number for return order ');

            Case newRequestCase = [
                SELECT id
                FROM case
                WHERE Type_Of_Mx_Order__c = :CDdMxSxConstants.TYPE_OF_MX_ORDER_NEW AND AccountId = :act.Id AND recordtypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS
            ];
            Mx_Order__c newMxOrder = [SELECT id, case__c, Type_Of_Mx_Order__c FROM Mx_Order__c WHERE case__c = :newRequestCase.Id];
            List<Mx_Order_Item__c> newOrderItems = [SELECT id, Identifier__c, Mx_Product__c FROM Mx_Order_Item__c WHERE Mx_Order__c = :newMxOrder.Id];

            System.assertEquals(true, newRequestCase != null, 'Expecting Return Tablet case');
            System.assertEquals(true, newMxOrder != null, 'Expecting new equipment request mx order');
            System.assertEquals(true, newOrderItems != null, 'Expecting new equipment request order items');
            System.assertEquals(mxProducts[0].Id, newOrderItems[0].Mx_Product__c, 'new equipment request Mx order items are not matching');
        }
    }

    /**
    * @description testGetAccountDetails method will run tests for account ids.
    */
    @isTest
    static void testGetAccountDetails() {
        System.runAs(getTestRunUser()) {
            Account act = getaccountbyName(ACCOUNT_NAME);
            CDdMxAccountModel response = CDdMxEquipmentRequestController.getAccountDetails(act.Id);
            System.assertEquals(act.Id, response.AccountId, 'Account is not matching');
            Opportunity opp = [SELECT id, accountId FROM Opportunity WHERE AccountId = :act.Id LIMIT 1];
            CDdMxAccountModel OppResponse = CDdMxEquipmentRequestController.getAccountDetails(Opp.Id);
            System.assertEquals(Opp.accountId, OppResponse.AccountId, 'Account is not matching');
            Opportunity oppParent = [SELECT id, accountId FROM Opportunity WHERE Name = :OPP_NAME_PARENT LIMIT 1];
            try {
                CDdMxEquipmentRequestController.getAccountDetails(oppParent.Id);
            } catch (exception e) {
                System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Type of Exception is not same as expected.');
            }
        }
    }
    /**
    * @description testGetOrderRequests method will test the whether order request will return from the method.
    */
    @isTest
    static void testPrinterValidation() {
        System.runAs(getTestRunUser()) {
            Account act  = getaccountbyName(ACCOUNT_NAME);
            Contact con = [select id from contact where accountid = :act.Id];
            Opportunity opp=[select id,Order_Protocol__c from Opportunity where accountId = :act.Id ];
            opp.Order_Protocol__c ='POS';
            update opp;
            CDdMxEquipmentRequestModel cs = new CDdMxEquipmentRequestModel();
            cs.AccountId = act.Id;
            cs.ContactId = con.Id;
            cs.OppId = opp.Id;
            cs.requestType = PRINTER_MX_ORDER_REQUEST_TYPE;
            String payLoad= JSON.serialize(cs);
            Boolean allowPrinterRequest = CDdMxEquipmentRequestController.validatePrinterRequest(payLoad);
            System.assertEquals(false, allowPrinterRequest, 'Expecting notValidforPrinterRequest as true');
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :PRINTER_PERMISSION_SET_NAME];
            insert new PermissionSetAssignment(AssigneeId = Userinfo.getUserId(), PermissionSetId = ps.Id);
            allowPrinterRequest = CDdMxEquipmentRequestController.validatePrinterRequest(payLoad);
            System.assertEquals(true, allowPrinterRequest, 'Expecting notValidforPrinterRequest as true');
        }
    }
    /**
    * @description testGetOrderRequests method will test the whether order request will return from the method.
    */
    @isTest
    static void testGetOrderRequests() {
        System.runAs(getTestRunUser()) {
            Account act = getaccountbyName(ACCOUNT_NAME);
            List<CDdMxEquipmentOrderRequestModel> MxOrder = CDdMxEquipmentRequestController.getOrderRequests(act.Id);
            System.assertEquals(3, MxOrder.size(), 'Mx Order Count not matching');
            system.assertEquals(3 ,MxOrder[0].mxOrderRequestProduct.size(),'Mx order Item count not matching' );
            List<Mx_Order_Request__c> orderRequests = [select id, Request_Type_Family__c from Mx_Order_Request__c limit 10];
            for(Mx_Order_Request__c orderRequest : orderRequests){
                orderRequest.Request_Type_Family__c = 'Return Only';
            }
            update orderRequests;
            set<String> requstTypeFamily = new set<String>{'New'};
            set<String> oldRequestsTypes = CDdMxEquipmentRequestHelper.getReturnOrderRequests(act.Id,requstTypeFamily );
            System.assertEquals(0, oldRequestsTypes.size(), 'oldRequestsTypes type count not matching ');
        }
    }
    /**
    * @description method is for testing search functinality for different objects.
    */
    @isTest
    static void testSearch() {
        System.runAs(getTestRunUser()) {
            Account act = getaccountbyName(ACCOUNT_NAME);
            List<CDdMxEquipmentLookupSearchModel> MxOrderCOn = CDdMxEquipmentRequestController.search('Test', act.Id, CONTACT_OBJECT, '');
            System.assertEquals(1, MxOrderCOn.size(), 'Search contact count not matching');
            String oppId = '';
            for (Opportunity opportunity : getOpportunitiesByName(OPP_NAME_CHILD)){
                oppId = opportunity.Id;
            }
            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = oppId;
            Test.setFixedSearchResults(fixedSearchResults);
            List<CDdMxEquipmentLookupSearchModel> MxOrderOpp = CDdMxEquipmentRequestController.search(OPP_NAME_CHILD, act.Id, OPP_OBJECT, '');
            System.assertEquals(1, MxOrderOpp.size(), 'Opportunity Count not matching');

            List<case> cs = [select id,Tablet_Serial_Number__c from case limit 1];
            cs[0].Tablet_Serial_Number__c = '123';
            update cs;
            List<CDdMxEquipmentLookupSearchModel> MxOrderTablet = CDdMxEquipmentRequestController.search('123', act.Id, TABLET_IMEI, '');
            System.assertEquals(1, MxOrderTablet.size(), 'Tablet imei Count not matching');
        }
    }
     /**
    * @description method is for testing contact owner validation.
    */
    @isTest
    static void testContactownerValidation() {
        System.runAs(getTestRunUser()) {
            Account act = getaccountbyName(ACCOUNT_NAME);
            Contact cont = [select id from contact where accountId = :act.Id];
            CDdMxFieldSetController.ContactOwnerValidationResultModel contValidationResult= CDdMxFieldSetController.validateContactOwner(act.Id, cont.Id);
            System.assertEquals(false, contValidationResult.noActiveOwnerFound, 'contact owner should be active ');
        }
    }
    /**
    * @description Test Populate MxOrderVendor on Case when mxOrder Status changes to 'open'
    */
    @isTest
    static void testMxOrderVendorOnCaseFromEquipmentUIMxOrderOpen() {
        System.runAs(getTestRunUser()) {
            Account act = getaccountbyName(ACCOUNT_NAME);
            Case newRequestCase = [
                SELECT id
                FROM case
                WHERE Type_Of_Mx_Order__c = :CDdMxSxConstants.TYPE_OF_MX_ORDER_NEW AND AccountId = :act.Id AND recordtypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS
            ];
            newRequestCase.Return_Shipping_Address_State__c = 'Florida';
            update newRequestCase;
            Mx_Order__c newMxOrder = [SELECT id, case__c, Type_Of_Mx_Order__c, Order_Status__c,Vendor__c FROM Mx_Order__c WHERE case__c = :newRequestCase.Id];
            test.startTest();
            newMxOrder.Order_Status__c = 'open';
            update newMxOrder;
            Test.getEventBus().deliver();
            test.stopTest();
            Case newRequestCaseFromDB = [
                SELECT id, origin, Mx_Order_Vendor__c
                FROM case
                WHERE Type_Of_Mx_Order__c = :CDdMxSxConstants.TYPE_OF_MX_ORDER_NEW AND createddate >= today AND recordtypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS
                LIMIT 1
            ];
            System.assertEquals(newMxOrder.Vendor__c, newRequestCaseFromDB.Mx_Order_Vendor__c);
        }
    }
    /**
    * @description Test Populate MxOrderVendor on Case when mxOrder Status changes to 'new'
    */
    @isTest
    static void testMxOrderVendorOnCaseFromEquipmentUIMxOrderNew() {
        System.runAs(getTestRunUser()) {
            Account act = getaccountbyName(ACCOUNT_NAME);
            Case newRequestCase = [
                SELECT id
                FROM case
                WHERE Type_Of_Mx_Order__c = :CDdMxSxConstants.TYPE_OF_MX_ORDER_NEW AND AccountId = :act.Id AND recordtypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS
            ];
            newRequestCase.Return_Shipping_Address_State__c = 'Florida';
            update newRequestCase;
            Mx_Order__c newMxOrder = [SELECT id, case__c, Type_Of_Mx_Order__c, Order_Status__c,Vendor__c FROM Mx_Order__c WHERE case__c = :newRequestCase.Id];
            test.startTest();
            newMxOrder.Order_Status__c = 'new';
            update newMxOrder;
            Test.getEventBus().deliver();
            test.stopTest();
            Case newRequestCaseFromDB = [
                SELECT id, origin, Mx_Order_Vendor__c
                FROM case
                WHERE Type_Of_Mx_Order__c = :CDdMxSxConstants.TYPE_OF_MX_ORDER_NEW AND createddate >= today AND recordtypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS
                LIMIT 1
            ];
            System.assertEquals(newMxOrder.Vendor__c, newRequestCaseFromDB.Mx_Order_Vendor__c);
        }
    }

    static Account getaccount(string recordTypeName) {
        return [SELECT id, BillingCountryCode FROM Account WHERE recordtype.Name = :recordTypeName LIMIT 1];
    }
    static Account getaccountbyName(String Name) {
        return [SELECT id,ownerId, ADR_Owner_Actual__c, Owner.userName, BillingCountryCode FROM Account WHERE Name = :Name];
    }
     /**
     *  @description Method returns the opportunities by Name.
     */
    static List<Opportunity> getOpportunitiesByName(String oppName){
        return [SELECT Id,AccountId,Name FROM Opportunity where Name = :oppName];
    }
}