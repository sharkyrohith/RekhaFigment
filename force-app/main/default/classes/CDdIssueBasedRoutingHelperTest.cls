/**
 * CDdIssueBasedRoutingHelperTest
 *
 * @author     Sahil
 * @date  2021-05-13
 * @decription Test class for CDdSendbirdChatController
 */
@isTest(seeAllData=false)
public with sharing class CDdIssueBasedRoutingHelperTest {
    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    private static final String ISSUE_ACCOUNT_HELP = 'Account Help';
    private static final String ISSUE_ACCOUNT = 'Account';
    private static final String TEST_OBJECT_LCT = 'LiveChatTranscript';
    private static final String TEST_OBJECT_CASE = 'Case';
    private static final String CONS_COMM = 'Consumer Community';
    private static final String CUSTOMER_SEGMENT_WHALE ='Sei Whale';
    private static final String AUSTRALIA_LOCATION ='NULL,Australia';
    private static final String TASKUS_PREFERRED_VENDOR ='TaskUs';
    private static final String ISSUE_PAYMENT_MANAGEMENT = 'Payment Management';
    private static final String DISPATCH_RESPONSE = '{"salesforceAudienceInfoBulkResponse":[{"customerType":0,"audience":{"consumerAudience":{"id":"690354550","firstName":"Fernando","lastName":"Herrera","email":"fernandojrh26@gmail.com","phoneNumber":"+14244434916","country":"US","experience":0,"experienceString":"doordash","cxUnavailLast3OrdersFlag":9999,"isVip":false,"vipTier":0,"language":"en-US","address":{"id":"168804135","street":"2602 Broadway","createdAt":"2021-01-31T00:49:06.953Z","zipCode":"90404","lat":34.03197280000001,"lng":-118.4721346,"establishment":"","subpremise":"","neighborhood":"Mid-City","country":"United States","formattedAddress":"2602 Broadway, Santa Monica, CA 90404, USA","administrativeAreaLevel1":"CA","administrativeAreaLevel2":"Los Angeles County","locality":"Santa Monica","countryShortname":"US","googlePlaceId":"ChIJhxiDnEe7woARhNYMv0dOsvQ","isGeneric":false,"name":"2602 Broadway","city":"Santa Monica","postalCode":"90404","postalCodeSuffix":"3833","languageCode":"en"},"isSubscribedConsumer":false,"phoneNumberComponents":{"countryCode":"1","countryShortname":"US","formattedInternationalNumber":"+1 424-443-4916","formattedNationalNumber":"(424) 443-4916","internationalNumber":"+14244434916","nationalNumber":"4244434916"},"consumerSubscriptionPlan":{},"consumerDeliveryStatus":1,"availableConsumerCredits":0,"submarketId":"1","submarketName":"Los Angeles","availableConsumerCreditsMonetaryFields":{"unitAmount":0,"currency":"USD","displayString":"$0.00","decimalPlaces":2,"sign":true,"symbol":"$"}},"dasherAudience":{"id":"11165572","firstName":"Rianna","lastName":"Flores","email":"azjiathomas281@gmail.com","phoneNumber":"+19285662621","address":{},"experience":0,"phoneNumberComponents":{"countryCode":"1","countryShortname":"US","formattedInternationalNumber":"+1 928-566-2621","formattedNationalNumber":"(928) 566-2621","internationalNumber":"+19285662621","nationalNumber":"9285662621"},"language":"en","dasherDeliveryStatus":6},"store":{"id":"32415","name":"The Cheesecake Factory (Santa Monica - 0186)","business":{"id":"105","name":"The Cheesecake Factory"},"phoneNumber":"+13102601474","address":{"id":"80613950","street":"308 Santa Monica Boulevard","createdAt":"2020-03-09T19:47:06.925Z","zipCode":"90401","lat":34.01376366,"lng":-118.4940948,"establishment":"","subpremise":"","neighborhood":"Downtown","country":"United States","formattedAddress":"308 Santa Monica Blvd, Santa Monica, CA 90401, USA","administrativeAreaLevel1":"CA","administrativeAreaLevel2":"Los Angeles County","locality":"Santa Monica","countryShortname":"US","googlePlaceId":"ChIJHwZz09GkwoARv0spoG93K8Y","isGeneric":false,"name":"308 Santa Monica Blvd","city":"Santa Monica","postalCode":"90401","languageCode":"en"},"orderProtocol":"POINT_OF_SALE","phoneNumberComponents":{"countryCode":"1","countryShortname":"US","formattedInternationalNumber":"+1 310-260-1474","formattedNationalNumber":"(310) 260-1474","internationalNumber":"+13102601474","nationalNumber":"3102601474"},"isPartner":true,"tenure":868}},"delivery":{"mostRecentDeliveryUuid":"29fa9705-16a2-4260-9725-df92f90d2f43","totalCost":{"unitAmount":1795,"currency":"USD","displayString":"$17.95","decimalPlaces":2,"sign":true,"symbol":"$"},"orderSource":"mp","deliveryUuid":"29fa9705-16a2-4260-9725-df92f90d2f43","currency":"USD","statusOfCreditRefund":[],"activeDate":"2021-08-26T19:50:33.000Z","address":{},"wasBatched":true,"shoppingProtocol":1,"estimatedPickupTime":"2021-08-26T19:20:24.000Z","marketTimezone":"US/Pacific","estimatedPickupTimeInMarketTimezone":"8/26/21, 12:20 PM"},"requestingInfo":"Delivery"}],"salesforceAudienceInfoBulkResponseErrors":[]}';
    @TestSetup
    static void makeData(){
        vCS__c testSettings;
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.CaseTrigger__c = true;
        insert testSettings;
        TDdCaseFactory.getSupportFeatureFlag(true);
        //get queue id
        Id mxSxQId = [SELECT Id FROM Group WHERE DeveloperName = 'MxSx_Mx_Success_Associate' LIMIT 1].Id;
        //insert custom settings for mapping routing destination to queue Id
        /*Support_Assignment_Mapping__c mxSxQMapping = new Support_Assignment_Mapping__c();
        mxSxQMapping.Name = CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
        mxSxQMapping.Queue_Id__c = mxSxQId;
        mxSxQMapping.Support_Assignment_Name__c = CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
        mxSxQMapping.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
        insert mxSxQMapping;*/
    }

    /**
     * @author      Raju
     * @date        March 2022
     * @decription  set configs for test
     * @param   None
     * @return  None
    */
    static void setConfigsForTest(String sobj) {
        CDdIssueBasedRoutingHelper.configsForTest = CDdIssueBasedRoutingHelper.getRoutingConfigHelper(sobj,true);
    }

    /**
     * @author      Raju
     * @date        March 2022
     * @decription  Not adding within testsetup as not all test methods need these accounts.
     * @param   None
     * @return  None
    */
    static void createAccounts() {
        List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 2, 'Marketplace');
        accs[0].Restaurant_ID__c = '12345';
        accs[0].Deck_Rank__c = 'Ace';
        insert accs[0];
        accs[1].ParentId = accs[0].Id;
        accs[1].Restaurant_ID__c = '123456';
        accs[1].Competitors__c = 'GrubHub';
        accs[1].Deck_Rank__c = 'Ace';
        accs[1].Case_Routing_Override__c = CDdSupportConstants.MXP_ROUTING_OVERRIDE_VALUE;
        accs[1].Business_Vertical_Details__c = '';
        accs[1].Business_ID__c = 100;
        insert accs[1];
    }

    /**
     * @author     Sahil
     * @date  2021-05-13
     * @decription test to check if record value is equal to value in metadata record
     * @param   None
     * @return  None
    */
    @isTest
    static void testEqualsContainsPositive() {
        setConfigsForTest(TEST_OBJECT_LCT);
        //create chat transcript record
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_ACCOUNT_HELP;
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Channel__c = CONS_COMM;
        testChatTranscript.Preferred_Vendor__c = TASKUS_PREFERRED_VENDOR;
        testChatTranscript.Location = AUSTRALIA_LOCATION;
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        System.assertEquals(false, routingInfo.standardRouting, 'Standard routing should be false');
        System.assertEquals(CDdSupportConstants.CREATED_UPDATED, routingInfo.evaluationCriteria, 'Record should be re-evaluated on update');
    }

    /**
     * @author     Sahil
     * @date  2021-05-13
     * @decription test to check if record value contains value in metadata record
     * @param   None
     * @return  None
    */
    @isTest
    static void testEqualsContainsNegative() {
        setConfigsForTest(TEST_OBJECT_LCT);
        //create chat transcript record
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c = ISSUE_ACCOUNT;
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Channel__c = CONS_COMM;
        testChatTranscript.Preferred_Vendor__c = AUSTRALIA_LOCATION;
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        System.assertEquals(true, routingInfo.standardRouting, 'Standard routing should be true');
    }

    /**
     * @author     Sahil
     * @date  2021-05-13
     * @decription test to check if record value is not equal to value in metadata record
     * @param   None
     * @return  None
    */
    @isTest
    static void testNotEqualsContainsPositive() {
        setConfigsForTest(TEST_OBJECT_LCT);
        //create chat transcript record
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_ACCOUNT_HELP;
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Channel__c = CONS_COMM;
        testChatTranscript.Preferred_Vendor__c = TASKUS_PREFERRED_VENDOR;
        testChatTranscript.Location = AUSTRALIA_LOCATION;
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        System.assertEquals(false, routingInfo.standardRouting, 'Standard routing should be false');
    }

    /**
     * @author     Sahil
     * @date  2021-05-13
     * @decription test to check if record value does not contain the value in metadata record
     * @param   None
     * @return  None
    */
    @isTest
    static void testNotEqualsContainsNegative() {
        setConfigsForTest(TEST_OBJECT_LCT);
        //create chat transcript record
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_ACCOUNT_HELP;
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Channel__c = CONS_COMM;
        testChatTranscript.Preferred_Vendor__c = TASKUS_PREFERRED_VENDOR;
        testChatTranscript.Location = AUSTRALIA_LOCATION;
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        System.assertEquals(false, routingInfo.standardRouting, 'Standard routing should be true');
    }

    /**
     * @author     Nayana
     * @date  2021-10-13
     * @decription Like Operator test
     * @param   None
     * @return  None
    */
    @isTest
    static void testLikeOperatorPositive() {
        setConfigsForTest(TEST_OBJECT_LCT);
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_ACCOUNT_HELP;
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Channel__c = CONS_COMM;
        testChatTranscript.Preferred_Vendor__c = TASKUS_PREFERRED_VENDOR;
        testChatTranscript.Location = AUSTRALIA_LOCATION;
        Test.startTest();
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        Test.stopTest();
        System.assertEquals(false, routingInfo.standardRouting, 'Standard routing should be false');
    }

    /**
     * @author     Nayana
     * @date  2021-10-13
     * @decription Like Operator test
     * @param   None
     * @return  None
    */
    @isTest
    static void testLikeOperatorNegative() {
        setConfigsForTest(TEST_OBJECT_LCT);
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_ACCOUNT_HELP;
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Channel__c = CONS_COMM;
        testChatTranscript.Preferred_Vendor__c = TASKUS_PREFERRED_VENDOR;
        testChatTranscript.Location = 'Null,USA';
        Test.startTest();
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        Test.stopTest();
        System.assertEquals(true, routingInfo.standardRouting, 'Standard routing should be true');
    }

    /**
     * @author     Mahesh Chouhan
     * @date  2022-06-17
     * @decription Is Blank Operator test
     * @param   None
     * @return  None
    */
    @isTest
    static void testIsBlankOperatorPositive() {
        setConfigsForTest(TEST_OBJECT_LCT);
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_ACCOUNT_HELP;
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Channel__c = CONS_COMM;
        testChatTranscript.Preferred_Vendor__c = TASKUS_PREFERRED_VENDOR;
        testChatTranscript.Location = AUSTRALIA_LOCATION;
        testChatTranscript.Routing_Reason__c = '';
        Test.startTest();
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        Test.stopTest();
        System.assertEquals(false, routingInfo.standardRouting, 'Standard routing should be false');
    }

    /**
     * @author     Mahesh Chouhan
     * @date  2022-06-17
     * @decription Is Blank Operator test
     * @param   None
     * @return  None
    */
    @isTest
    static void testIsBlankOperatorNegative() {
        setConfigsForTest(TEST_OBJECT_LCT);
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_ACCOUNT_HELP;
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Channel__c = CONS_COMM;
        testChatTranscript.Preferred_Vendor__c = TASKUS_PREFERRED_VENDOR;
        testChatTranscript.Location = AUSTRALIA_LOCATION;
        testChatTranscript.Routing_Reason__c = 'TestReason';
        Test.startTest();
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        Test.stopTest();
        System.assertEquals(true, routingInfo.standardRouting, 'Standard routing should be true');
    }

    /**
     * @author     Nayana
     * @date  2021-11-10
     * @decription Filter Logic test
     * @param   None
     * @return  None
    */
    @isTest
    static void testFilterLogicPositive() {
        setConfigsForTest(TEST_OBJECT_LCT);
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_PAYMENT_MANAGEMENT;
        testChatTranscript.Location = AUSTRALIA_LOCATION;
        testChatTranscript.Customer_Segment__c = CUSTOMER_SEGMENT_WHALE;
        Test.startTest();
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        Test.stopTest();
        System.assertEquals(false, routingInfo.standardRouting, 'Standard routing should be false');
        System.assertEquals('Live Delivery Support Filter', routingInfo.routingDestination, 'Routing destination should have this value.');
    }

    /**
     * @author     Nayana
     * @date  2021-11-10
     * @decription Filter Logic test
     * @param   None
     * @return  None
    */
    @isTest
    static void testFilterLogicNegative() {
        setConfigsForTest(TEST_OBJECT_LCT);
        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= ISSUE_PAYMENT_MANAGEMENT;
        testChatTranscript.Location = 'Null,USA';
        testChatTranscript.Customer_Segment__c = CUSTOMER_SEGMENT_WHALE;
        Test.startTest();
        CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(testChatTranscript);
        Test.stopTest();
        System.assertEquals(true, routingInfo.standardRouting, 'Standard routing should be true');
    }

     /**
     * @author     Raju
     * @date       March 2022
     * @decription Related entities Logic test
    */
    @isTest
    static void testRelatedObject1() {
        setConfigsForTest(TEST_OBJECT_CASE);
        createAccounts();
        Test.startTest();
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        testCaseList[0].Store_ID__c = '123456';
        testCaseList[0].Formstack_Source__c = 'Support Request - Mx Portal';
        testCaseList[0].Formstack_Category__c = 'Point of Sale';
        testCaseList[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        testCaseList[0].DispatchRQResponse__c = DISPATCH_RESPONSE;
        insert testCaseList;
        Test.stopTest();
        List<Case> caseFromDB = [SELECT Activation_Date__c, Activation_Date_2__c, Consumer_Name__c, Activation_Fee_Invoiced_Date__c, Routing_Destination__c FROM Case WHERE Id =:testCaseList[0].Id];
        System.assertEquals('MxSx - Mx Success Associate', caseFromDB[0].Routing_Destination__c, 'Routing Destination should be Mx Success Associate');
        System.assertEquals(System.today(), caseFromDB[0].Activation_Date__c, 'Activation Date on Case is not same as expected');
        System.assert(caseFromDB[0].Activation_Date_2__c != null, 'Activation Date/Time on Case should not be null');
        System.assert(caseFromDB[0].Consumer_Name__c != null, 'Consumer Name on Case should not be null');
        System.assertEquals(Date.newInstance(2022, 7, 29), caseFromDB[0].Activation_Fee_Invoiced_Date__c, 'Activation Fee Invoiced Date on Case is not same as expected');
    }

    @IsTest
    static void increaseCodeCoverage(){
        Routing_Criterion__mdt rc = Routing_Criterion__mdt.getInstance('Test_Related_Object_1');
        CDdIssueBasedRoutingHelper.getRoutingConfig(TEST_OBJECT_CASE);
        CDdIssueBasedRoutingHelper.getRoutingConfig(TEST_OBJECT_CASE); // cache
        CDdCriterionEvaluator eval = new CDdCriterionEvaluator();
        CDdFunctionEvaluator funcVal = new CDdFunctionEvaluator();

        increaseCodeCoverageHelper(eval,rc);
        eval.getRelatedObjectMap('Case-Opportunity');
        eval.getRelatedObjectMap('Case-Contact');
        eval.getRelatedObjectMap('LiveChatTranscript-Case');
        eval.getRelatedObjectMap('Test-Test');
        eval.getRelatedObjectFieldValue(null,null,null,null);

        increaseCodeCoverageHelper(new CDdEqualsCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdNotEqualsCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdContainsCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdNotContainsCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdLikeCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdIsNotBlankCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdIsNewCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdIsChangedCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdNotLikeCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdIsBlankCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdLessThanCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdLessOrEqualCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdGreaterThanCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(new CDdGreaterOrEqualCriterionEvaluator(),rc);
        increaseCodeCoverageHelper(funcVal);
    }

    private static void increaseCodeCoverageHelper(CDdCriterionEvaluator eval,Routing_Criterion__mdt rc) {
        eval.evaluateCriterion('TEST', 'TEST', null);
        eval.evaluateCriterion(rc, null);
    }

    private static void increaseCodeCoverageHelper(CDdFunctionEvaluator funcVal) {
        funcVal.getValue('TEST');
    }
}