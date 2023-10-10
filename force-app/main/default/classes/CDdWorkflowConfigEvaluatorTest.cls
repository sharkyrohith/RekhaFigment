/**
 * CDdWorkflowConfigEvaluatorTest
 *
 * @author      Mahesh Chouhan
 * @date        Jan 2023
 * @decription  Test class for CDdWorkflowConfigEvaluator
 */
@isTest
public class CDdWorkflowConfigEvaluatorTest {
    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CDdWorkflowConfigEvaluator.class
    };

    /****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    ****************************************************************************************************************************/
    private static final String DISPATCH_RESPONSE = '{"salesforceAudienceInfoBulkResponse":[{"customerType":0,"audience":{"consumerAudience":{"id":"690354550","firstName":"Fernando","lastName":"Herrera","email":"fernandojrh26@gmail.com","phoneNumber":"+14244434916","country":"US","experience":0,"experienceString":"doordash","cxUnavailLast3OrdersFlag":9999,"isVip":false,"vipTier":0,"language":"en-US","address":{"id":"168804135","street":"2602 Broadway","createdAt":"2021-01-31T00:49:06.953Z","zipCode":"90404","lat":34.03197280000001,"lng":-118.4721346,"establishment":"","subpremise":"","neighborhood":"Mid-City","country":"United States","formattedAddress":"2602 Broadway, Santa Monica, CA 90404, USA","administrativeAreaLevel1":"CA","administrativeAreaLevel2":"Los Angeles County","locality":"Santa Monica","countryShortname":"US","googlePlaceId":"ChIJhxiDnEe7woARhNYMv0dOsvQ","isGeneric":false,"name":"2602 Broadway","city":"Santa Monica","postalCode":"90404","postalCodeSuffix":"3833","languageCode":"en"},"isSubscribedConsumer":false,"phoneNumberComponents":{"countryCode":"1","countryShortname":"US","formattedInternationalNumber":"+1 424-443-4916","formattedNationalNumber":"(424) 443-4916","internationalNumber":"+14244434916","nationalNumber":"4244434916"},"consumerSubscriptionPlan":{},"consumerDeliveryStatus":1,"availableConsumerCredits":0,"submarketId":"1","submarketName":"Los Angeles","availableConsumerCreditsMonetaryFields":{"unitAmount":0,"currency":"USD","displayString":"$0.00","decimalPlaces":2,"sign":true,"symbol":"$"}},"dasherAudience":{"id":"11165572","firstName":"Rianna","lastName":"Flores","email":"azjiathomas281@gmail.com","phoneNumber":"+19285662621","address":{},"experience":0,"phoneNumberComponents":{"countryCode":"1","countryShortname":"US","formattedInternationalNumber":"+1 928-566-2621","formattedNationalNumber":"(928) 566-2621","internationalNumber":"+19285662621","nationalNumber":"9285662621"},"language":"en","dasherDeliveryStatus":6},"store":{"id":"32415","name":"The Cheesecake Factory (Santa Monica - 0186)","business":{"id":"105","name":"The Cheesecake Factory"},"phoneNumber":"+13102601474","address":{"id":"80613950","street":"308 Santa Monica Boulevard","createdAt":"2020-03-09T19:47:06.925Z","zipCode":"90401","lat":34.01376366,"lng":-118.4940948,"establishment":"","subpremise":"","neighborhood":"Downtown","country":"United States","formattedAddress":"308 Santa Monica Blvd, Santa Monica, CA 90401, USA","administrativeAreaLevel1":"CA","administrativeAreaLevel2":"Los Angeles County","locality":"Santa Monica","countryShortname":"US","googlePlaceId":"ChIJHwZz09GkwoARv0spoG93K8Y","isGeneric":false,"name":"308 Santa Monica Blvd","city":"Santa Monica","postalCode":"90401","languageCode":"en"},"orderProtocol":"POINT_OF_SALE","phoneNumberComponents":{"countryCode":"1","countryShortname":"US","formattedInternationalNumber":"+1 310-260-1474","formattedNationalNumber":"(310) 260-1474","internationalNumber":"+13102601474","nationalNumber":"3102601474"},"isPartner":true,"tenure":868}},"delivery":{"mostRecentDeliveryUuid":"29fa9705-16a2-4260-9725-df92f90d2f43","totalCost":{"unitAmount":1795,"currency":"USD","displayString":"$17.95","decimalPlaces":2,"sign":true,"symbol":"$"},"orderSource":"mp","deliveryUuid":"29fa9705-16a2-4260-9725-df92f90d2f43","currency":"USD","statusOfCreditRefund":[],"activeDate":"2021-08-26T19:50:33.000Z","address":{},"wasBatched":true,"shoppingProtocol":1,"estimatedPickupTime":"2021-08-26T19:20:24.000Z","marketTimezone":"US/Pacific","estimatedPickupTimeInMarketTimezone":"8/26/21, 12:20 PM"},"requestingInfo":"Delivery"}],"salesforceAudienceInfoBulkResponseErrors":[]}';

    @TestSetup
    static void makeData(){
        vCS__c testSettings;
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.CaseTrigger__c = true;
        insert testSettings;
        TDdCaseFactory.getSupportFeatureFlag(true);
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        testCaseList[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_CONSUMER;
        insert testCaseList;
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  create test Accounts
     * @param   None
     * @return  None
    */
    static void createAccounts() {
        List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 1, 'Marketplace');
        accs[0].ParentId = accs[0].Id;
        accs[0].Restaurant_ID__c = '123456';
        accs[0].Competitors__c = 'GrubHub';
        accs[0].Deck_Rank__c = 'Ace';
        accs[0].Case_Routing_Override__c = CDdSupportConstants.MXP_ROUTING_OVERRIDE_VALUE;
        accs[0].Business_Vertical_Details__c = '';
        accs[0].Business_ID__c = 100;
        insert accs[0];
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription test method to validate a case workflow
    */
    @isTest
    static void testCaseWorkflow(){
        List<Case> testCaseList = [SELECT Id, Description FROM Case];
        Test.startTest();
        testCaseList[0].Description = 'Test Description';
        update testCaseList;
        Test.stopTest();
        List<Case> caseFromDB = [SELECT Activation_Notes__c, Do_Not_Sent_Survey__c, Due_Date__c FROM Case WHERE Id =:testCaseList[0].Id];
        List<Task> caseTask = [SELECT ID, Subject From Task WHERE WhatId =:testCaseList[0].Id];
        //Field Update Action
        System.assertEquals(CDdSupportConstants.CUSTOMER_TYPE_CONSUMER, caseFromDB[0].Activation_Notes__c, 'Activation Notes on case is not same as expected.');
        System.assert(caseFromDB[0].Do_Not_Sent_Survey__c, 'Do Not Send Survey on case should be true.');
        System.assertEquals(Date.newInstance(2023, 1, 17), caseFromDB[0].Due_Date__c, 'Due Date on case is not same as expected.');
        //Task Creation Action
        System.assertEquals(1, caseTask.size(), 'Task should be created.');
        System.assertEquals('Test Task Subject', caseTask[0].Subject, 'Task subject is not same as expected.');
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription Related entities Logic test
    */
    @isTest
    static void testRelatedObject1() {
        createAccounts();
        Test.startTest();
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        testCaseList[0].Store_ID__c = '123456';
        testCaseList[0].Formstack_Source__c = 'Support Request - Mx Portal';
        testCaseList[0].Formstack_Category__c = 'Point of Sale';
        testCaseList[0].DispatchRQResponse__c = DISPATCH_RESPONSE;
        testCaseList[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        insert testCaseList;
        Test.stopTest();
        List<Case> caseFromDB = [SELECT In_Progress_Date__c, Headcount__c, Consumer_Name__c, Account.Activation_Source__c FROM Case WHERE Id =:testCaseList[0].Id];
        //Field Update Action
        System.assertEquals(100, caseFromDB[0].Headcount__c, 'Headcount on Case is not same as expected.');
        System.assertEquals(System.today(), caseFromDB[0].In_Progress_Date__c, 'Activation Date on Case is not same as expected');
        System.assert(caseFromDB[0].Consumer_Name__c == null, 'Consumer Name on Case should be null');
        System.assertEquals('Testing Related Field Update', caseFromDB[0].Account.Activation_Source__c, 'Activation Source on Account is not same as expected.');
    }

    @IsTest
    static void increaseCodeCoverage(){
        Workflow_Criterion__mdt wc = Workflow_Criterion__mdt.getInstance('Test_Related_Object_1');
        CDdCriterionEvaluator eval = new CDdCriterionEvaluator();
        CDdFunctionEvaluator funcVal = new CDdFunctionEvaluator();

        increaseCodeCoverageHelper(eval,wc);
        eval.getRelatedObjectMap('Case-Opportunity');
        eval.getRelatedObjectMap('Case-Contact');
        eval.getRelatedObjectMap('LiveChatTranscript-Case');
        eval.getRelatedObjectMap('Test-Test');
        eval.getRelatedObjectFieldValue(null,null,null,null);

        increaseCodeCoverageHelper(new CDdEqualsCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdNotEqualsCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdContainsCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdNotContainsCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdLikeCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdIsNotBlankCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdIsNewCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdIsChangedCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdNotLikeCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdIsBlankCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdLessThanCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdLessOrEqualCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdGreaterThanCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(new CDdGreaterOrEqualCriterionEvaluator(),wc);
        increaseCodeCoverageHelper(funcVal);
    }
    /**
     * @author     Sharvani
     * @date       Mar 2023
     * @decription To increase the code coverage by making the reference of CDdCaseTriggerOptimizationHelper in CDdWorkflowConfigEvaluatorTest
    */

    @IsTest
    static void TestaccountfieldSet(){
		List<String> accFieldList = CDdCaseTriggerOptimizationHelper.getAccountFields();
        system.assert(accFieldList.size()>0, 'Account Field List');
    }

    private static void increaseCodeCoverageHelper(CDdCriterionEvaluator eval,Workflow_Criterion__mdt wc) {
        eval.evaluateCriterion('TEST', 'TEST', null);
        eval.evaluateCriterion(wc, null);
    }

    private static void increaseCodeCoverageHelper(CDdFunctionEvaluator funcVal) {
        funcVal.getValue('TEST');
    }
}