/**
 * @description Versioned as part of BZAP-13135. Pre-existing code for calling the PactSafeAPI.
 **/
@isTest
private class PSRequestQuoteTriggerHandlerTest {

  @isTest
  static void testExpirationHandler() {
    PactSafe_Extension_Main_Setting__mdt apiSetting = new PactSafe_Extension_Main_Setting__mdt(
      MasterLabel = 'Test API',
      API_Endpoint__c = 'https://api.pactsafe.com/v1.1',
      API_Key__c = 'abcd1234',
      Setting_Type__c = 'API Configuration',
      Test__c = false
    );
    PactSafeAPI.retrieveApiSettings = apiSetting;
    Test.setMock(HttpCalloutMock.class, new TestPactSafeAPIMockCallout());
    Test.startTest();
    PSRequestQuoteTriggerHandler.expireRequest('abcd1234');
    Test.stopTest();
  }

  @isTest
  static void testExpirationTrigger() {
    Opportunity opty = TestPSHelpers.createTestOpportunity('TestOpty', 'Acceptance');
    insert opty;
    PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
    update pricebook;
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opty.Id,
      SBQQ__Status__c = 'Draft'
    );
    insert quote;
    PactSafe_Extension_Main_Setting__mdt apiSetting = new PactSafe_Extension_Main_Setting__mdt(
      MasterLabel = 'Test API',
      API_Endpoint__c = 'https://api.pactsafe.com/v1.1',
      API_Key__c = 'abcd1234',
      Setting_Type__c = 'API Configuration',
      Test__c = false
    );
    PactSafeAPI.retrieveApiSettings = apiSetting;
    Test.setMock(HttpCalloutMock.class, new TestPactSafeAPIMockCallout());
    Test.startTest();
    String quoteId = quote.Id;
    SBQQ__Quote__c quoteCheck = [
      SELECT Id, SBQQ__Opportunity2__c, SBQQ__Status__c
      FROM SBQQ__Quote__c
      WHERE Id = :quoteId
    ];
    quoteCheck.SBQQ__Status__c = 'Contract Voided';
    Database.SaveResult sr = Database.update(quoteCheck);
    Test.stopTest();
    System.assert(
      sr.isSuccess(),
      'Expected update to be successful.'
    );
  }

}