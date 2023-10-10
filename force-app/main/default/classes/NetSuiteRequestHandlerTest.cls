@isTest
public with sharing class NetSuiteRequestHandlerTest {
  @TestSetup
  static void createSetupData(){
    List<sObject> configs = Test.loadData(OAuth_Config__c.sObjectType, 'OAuth_Config_NS');
    List<sObject> pa = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
  }

  @isTest
  static void testSendPaymentAccountCreationRequestSuccess(){
    Id paId = [SELECT Id FROM Payment_Account__c LIMIT 1].Id;
    Test.setMock(HttpCalloutMock.class, new NSAccountCreationResponseGenerator.MockSuccess());
    Test.startTest();
    NetSuiteRequestHandler.sendPaymentAccountCreationRequest(new Map<String, String> {paId => null});
    Test.stopTest();
    system.assertEquals('5678656', [SELECT NetSuite_ID__c FROM Payment_Account__c WHERE Id = :paId LIMIT 1].NetSuite_ID__c);
  }

  @isTest
  static void testSendPaymentAccountCreationRequestFailure(){
    Id paId = [SELECT Id FROM Payment_Account__c LIMIT 1].Id;
    Test.setMock(HttpCalloutMock.class, new NSAccountCreationResponseGenerator.MockFailure());
    Test.startTest();
    NetSuiteRequestHandler.sendPaymentAccountCreationRequest(new Map<String, String> {paId => null});
    Test.stopTest();
    system.assertEquals(true, '5678656' != [SELECT NetSuite_ID__c FROM Payment_Account__c WHERE Id = :paId LIMIT 1].NetSuite_ID__c);
  }
}