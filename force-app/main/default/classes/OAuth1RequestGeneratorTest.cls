@isTest(SeeAllData=false)
public without sharing class OAuth1RequestGeneratorTest {
  static final Map<String, Object> validDeserializedRequestBodyContent = new Map<String, Object>{
      'company_name' => 'Test',
      'email' => 'test.three@doordash.com',
      'currencyId' => 'USD',
      'subsidiaryId' => 1, // calculated; 'USD' --> 1
      'term_id' => 'Net 15',
      'address' => new Map<String, Object> {
        'addr1' => '180 Flinders Ln',
        'addr2' => 'Line 2',
        'city' => 'Melbourne',
        'state' => 'VIC',
        'zip' => 'Australia',
        'country' => 'AU'
      }};
  @TestSetup
  static void createSetupData(){
    List<sObject> configs = Test.loadData(OAuth_Config__c.sObjectType, 'OAuth_Config_NS');
    List<sObject> pa = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
  }
  @isTest
  static void testWhenPaymentAccountIdThenGenerateValidContentBody(){
    Id paId = [SELECT Id FROM Payment_Account__c LIMIT 1].Id;
    HttpRequest req = OAuth1RequestGenerator.generateRequest('Payment Account', paId,'Payment_Account__c');
    Map<String, Object> content = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
    for(String key: validDeserializedRequestBodyContent.keySet()){
      System.assertEquals(true, content.containsKey(key));
    }
  }
}