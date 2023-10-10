/**
 * CDdCaseTriggerSendbirdTests
 * helps with CDdSendbirdChatEventTriggerHelper class as well.
 *
 * @author     Sahil
 * @date  2022-06-15
 * @decription Test class for triggering sendbird chat event
 */
@isTest
public with sharing class CDdCaseTriggerSendbirdTests {
    /*****************************************************************************************************************************
    *
    * Constants & Private Variables
    *
    *****************************************************************************************************************************/
    private static List<Case> sendbirdCases = new List<Case>();
    /**
     * @author     Sahil
     * @date  2022-06-15
     * @decription test setup
     * @param   None
     * @return  None
     */
    @TestSetup
    static void makeData(){
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Enable_Sendbird_API_Callouts__c = true;
        featureFlag.Disable_THQ_Callouts__c = false;
        upsert featureFlag;

        vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;
        insert new Sendbird_Settings__c(Callout_Retries__c = 3);
        //insert a sendbird case
        sendbirdCases = TDdCaseFactory.createSendbirdCase(1, null, null);
        insert sendbirdCases;
        // API Logger Gate service
        insert new API_Logger_Gate__c(
            SetupOwnerId = Userinfo.getOrganizationId(),
            Enable_Sendbird_Logging__c = true,
            Sendbird_Record_Id__c = null,
            Sendbird_Record_Owner_Id__c = null
        );
    }

    /**
     * @author     Sahil
     * @date  2022-06-15
     * @decription change case status which will trigger the processSendbirdChats on case trigger
     * @param   None
     * @return  None
     */
    @isTest
    static void testSendbirdAPIUpdates() {
        //sendbird case status changes makes a callout to ERS (fire and forget)
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_Empty');//empty response
        mock.setStatusCode(200);//success
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        //query for the case and change its status
        List<Case> testCaseList = [SELECT Id,Status FROM Case];
        String caseStatusUpdated;
        Test.startTest();
        if (!testCaseList.isEmpty()) {
            //change status of the test case
            testCaseList[0].Status = 'Pending';
            update testCaseList;
        }
        Test.stopTest();
        caseStatusUpdated = [SELECT Status FROM Case WHERE Id =:testCaseList[0].Id LIMIT 1].Status;
        System.assertEquals('Pending', caseStatusUpdated, 'Case Status should be Pending');
    }

    /**
     * @author     Jeegar
     * @date  April 2023
     * @decription change case status which will trigger the processSendbirdChats on case trigger
     * @param   None
     * @return  None
     */
    @isTest
    static void testSendbirdFutureMethod() {
        //sendbird case status changes makes a callout to ERS (fire and forget)\
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Sendbird_Use_Future_Method__c = true;
        featureFlag.Disable_THQ_Callouts__c = false;
        upsert featureFlag;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_Empty');//empty response
        mock.setStatusCode(200);//success
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        //query for the case and change its status
        List<Case> testCaseList = [SELECT Id,Status FROM Case];
        String caseStatusUpdated;
        Test.startTest();
        if (!testCaseList.isEmpty()) {
            //change status of the test case
            testCaseList[0].Status = 'Pending';
            update testCaseList;
        }
        Test.stopTest();
        caseStatusUpdated = [SELECT Status FROM Case WHERE Id =:testCaseList[0].Id LIMIT 1].Status;
        System.assertEquals('Pending', caseStatusUpdated, 'Case Status should be Pending');
    }


    /**
     * @author     Jeegar
     * @date  April 2023
     * @decription change case status which will trigger the processSendbirdChats on case trigger
     * @param   None
     * @return  None
     */
    @isTest
    static void testNotifyTHQForNonChatCases() {
        //sendbird case status changes makes a callout to ERS (fire and forget)\
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Sendbird_Use_Future_Method__c = true;
        featureFlag.Disable_THQ_Callouts__c = false;
        upsert featureFlag;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_Empty');//empty response
        mock.setStatusCode(200);//success
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        //query for the case and change its status
        List<Case> testCaseList = TDdCaseFactory.createSendbirdCase(1, null, null);
        String caseStatusUpdated;
        Test.startTest();
        if (!testCaseList.isEmpty()) {
            //change status of the test case
            testCaseList[0].Origin = 'Email';
            Insert testCaseList;
        }
        Test.stopTest();
        caseStatusUpdated = [SELECT Status FROM Case WHERE Id =:testCaseList[0].Id LIMIT 1].Status;
        System.assertEquals('Open', caseStatusUpdated, 'Case Status should be Open');
    }
}