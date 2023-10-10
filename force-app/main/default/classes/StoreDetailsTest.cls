@isTest
class StoreDetailsTest {
  static final String ENDPOINT;
  static final Id TEST_ROLE_ID;
  static final Id SYSTEM_ADMIN_PROFILE_ID;
  static final String TEST_DD_RUN_USERNAME;
  static String assertErrorMessage;

  static {
    ENDPOINT =
      URL.getOrgDomainUrl().toExternalForm() +
      '/services/apexrest/getStoreDetails/';
    TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    SYSTEM_ADMIN_PROFILE_ID = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ]
    .Id;
    TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    assertErrorMessage = 'Expected: \n {0} Actual: \n {1}';
  }

  static User getTestRunUser() {
    User testRunUser = null;
    for (User u : [
      SELECT Id
      FROM User
      WHERE UserName = :TEST_DD_RUN_USERNAME
    ]) {
      testRunUser = u;
    }
    if (testRunUser == null) {
      testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
      testRunUser.Username = TEST_DD_RUN_USERNAME;
    }
    return testRunUser;
  }

  @TestSetup
  static void createTestData() {
    System.runAs(getTestRunUser()) {
      Test.startTest();
      insert new ApexRest__c(
        Store_Details_Bulk_Limit__c = 5,
        Store_Details_Versions__c = System.Label.Store_Details_API_Versions,
        SetupOwnerId = [SELECT Id FROM Organization LIMIT 1]
        .Id
      );
      Test.loadData(
        Response_Payload_Attribute__c.sObjectType,
        'StoreDetailsv100'
      );
      List<Account> accs = TDdAccountFactory.createAccounts(
        'GetDetailsAPI',
        3,
        'Marketplace'
      );
      accs[0].Restaurant_Id__c = '30000000000001';
      accs[1].Restaurant_Id__c = '30000000000002';
      accs[2].Restaurant_Id__c = '30000000000003';
      insert accs;
      Test.stopTest();
    }
  }

  @isTest
  static void testWhenOverflowOrUnderflowThenError() {
    RestRequest req1 = new RestRequest();
    req1.requestURI = ENDPOINT + 'fake_version/';
    req1.requestBody = Blob.valueOf('{"idsParam":"356400101"}');
    req1.httpMethod = 'POST';
    RestRequest req2 = new RestRequest();
    req2.requestURI = ENDPOINT + 'v1.0.0/*';
    req2.requestBody = Blob.valueOf(
      '{"idsParam":"3564001, 3533002, 3533003, 356400101, 353300201, 353300209"}'
    );
    req2.httpMethod = 'POST';
    RestRequest req3 = new RestRequest();
    req3.requestURI = ENDPOINT + 'v1.0.0/';
    req3.requestBody = Blob.valueOf('{"idsParam":null}');
    req3.httpMethod = 'POST';
    String responseBody1, responseBody2, responseBody3;
    Test.startTest();
    RestContext.request = req1;
    responseBody1 = StoreDetails.getStoreDetails();
    RestContext.request = req2;
    responseBody2 = StoreDetails.getStoreDetails();
    RestContext.request = req3;
    responseBody3 = StoreDetails.getStoreDetails();
    Test.stopTest();
    System.assertEquals(
      'Invalid api version.',
      responseBody1,
      String.format(
        assertErrorMessage,
        new List<String>{ 'Invalid api version.', responseBody1 }
      )
    );
    System.assertEquals(
      'Batch size limit exceeded.',
      responseBody2,
      String.format(
        assertErrorMessage,
        new List<String>{ 'Batch size limit exceeded.', responseBody2 }
      )
    );
    System.assertEquals(
      'Invalid request parameters.',
      responseBody3,
      String.format(
        assertErrorMessage,
        new List<String>{ 'Invalid request parameters.', responseBody3 }
      )
    );
  }

  @isTest
  static void testWhenStoreNotExistsThenEmptyDetails() {
    String emptyDetailsOutput = '{"store_list":[{"store_id":"999999999999999000","error":"Store not found","details":{}}]}';
    System.runAs(getTestRunUser()) {
      RestRequest req = new RestRequest();
      req.requestURI = ENDPOINT + 'v1.0.0/*';
      req.requestBody = Blob.valueOf('{"idsParam":"999999999999999000"}');
      req.httpMethod = 'POST';
      String responseBody;
      Test.startTest();
      RestContext.request = req;
      responseBody = StoreDetails.getStoreDetails();
      Test.stopTest();
      System.assertEquals(
        emptyDetailsOutput,
        JSON.serialize(JSON.deserializeUntyped(responseBody)),
        String.format(
          assertErrorMessage,
          new List<String>{
            emptyDetailsOutput,
            JSON.serialize(JSON.deserializeUntyped(responseBody))
          }
        )
      );
    }
  }

  static String output = '{"store_list":[{"store_id":"30000000000001","error":null,"details":{"record_id":null,"name":"GetDetailsAPI 0","legal_business_name":"TestAccount","merchant_supplied_id":null,"merchant_segment":null,"primary_vertical":null,"type":null,"address_id":null,"alcohol_activated":false,"alcohol_addendum_signed":false,"alcohol_eligibility":null,"alcohol_product_eligibility":"Not Eligible","menu_ui_type":null,"brand":{"record_id":null,"name":null,"default_corporate_business_id":null,"default_franchise_business_id":null},"franchise_parent":{"record_id":null,"name":null,"type":null},"parent":{"record_id":null,"name":null,"type":null},"ultimate_parent":{"record_id":null,"name":null,"type":null},"xrefs":null,"contacts":null,"opportunities":null,"contracts":null,"services":null}},{"store_id":"30000000000002","error":null,"details":{"record_id":null,"name":"GetDetailsAPI 1","legal_business_name":"TestAccount","merchant_supplied_id":null,"merchant_segment":null,"primary_vertical":null,"type":null,"address_id":null,"alcohol_activated":false,"alcohol_addendum_signed":false,"alcohol_eligibility":null,"alcohol_product_eligibility":"Not Eligible","menu_ui_type":null,"brand":{"record_id":null,"name":null,"default_corporate_business_id":null,"default_franchise_business_id":null},"franchise_parent":{"record_id":null,"name":null,"type":null},"parent":{"record_id":null,"name":null,"type":null},"ultimate_parent":{"record_id":null,"name":null,"type":null},"xrefs":null,"contacts":null,"opportunities":null,"contracts":null,"services":null}},{"store_id":"30000000000003","error":null,"details":{"record_id":null,"name":"GetDetailsAPI 2","legal_business_name":"TestAccount","merchant_supplied_id":null,"merchant_segment":null,"primary_vertical":null,"type":null,"address_id":null,"alcohol_activated":false,"alcohol_addendum_signed":false,"alcohol_eligibility":null,"alcohol_product_eligibility":"Not Eligible","menu_ui_type":null,"brand":{"record_id":null,"name":null,"default_corporate_business_id":null,"default_franchise_business_id":null},"franchise_parent":{"record_id":null,"name":null,"type":null},"parent":{"record_id":null,"name":null,"type":null},"ultimate_parent":{"record_id":null,"name":null,"type":null},"xrefs":null,"contacts":null,"opportunities":null,"contracts":null,"services":null}}]}';
  @isTest
  static void testing_v100() {
    System.runAs(getTestRunUser()) {
      RestRequest req = new RestRequest();
      req.requestURI = ENDPOINT + 'v1.0.0/*';
      req.requestBody = Blob.valueOf(
        '{"idsParam":"30000000000001, 30000000000002, 30000000000003"}'
      );
      req.httpMethod = 'POST';
      String responseBody;
      Test.startTest();
      RestContext.request = req;
      responseBody = StoreDetails.getStoreDetails();
      Test.stopTest();
      System.assertEquals(
        output,
        JSON.serialize(JSON.deserializeUntyped(responseBody)),
        String.format(
          assertErrorMessage,
          new List<String>{
            output,
            JSON.serialize(JSON.deserializeUntyped(responseBody))
          }
        )
      );
    }
  }
}