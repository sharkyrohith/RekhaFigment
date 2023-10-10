@RestResource(urlMapping='/getStoreDetails/*')
global with sharing class StoreDetails {
  @HttpPost
  global static String getStoreDetails() {
    RestRequest req = RestContext.request;
    String uri = req.requestURI;
    String idsParam = (String) (((Map<String, Object>) JSON.deserializeUntyped(
        req.requestBody.toString()
      ))
      .get('idsParam'));
    String version = uri.substring(
        uri.indexOf('getStoreDetails/') + 'getStoreDetails/'.length()
      )
      .substringBefore('/');
    Account accountIterator;
    List<String> storeIds;
    List<Object> payload;
    Map<String, Account> idToAccount;
    Map<String, Object> sourceData;
    JSONUtility.DynamicJSONBuilder jsonBuilder;
    Integer batchSizeLimit;
    Set<String> apiVersions = new Set<String>();
    ApexRest__c settings = ApexRest__c.getInstance();
    if (String.isBlank(idsParam)) {
      return 'Invalid request parameters.';
    }
    storeIds = idsParam.remove(' ').split(',');
    batchSizeLimit = (Integer) settings.Store_Details_Bulk_Limit__c;
    apiVersions.addAll(settings.Store_Details_Versions__c.split(','));

    if (storeIds.size() > batchSizeLimit) {
      return 'Batch size limit exceeded.';
    }
    if (!apiVersions.contains(version)) {
      return 'Invalid api version.';
    }

    try {
      payload = new List<Map<String, Object>>();
      idToAccount = new Map<String, Account>();
      for (Account acc : [
        SELECT
          Id,
          Name,
          Legal_Business_Name__c,
          Restaurant_Id__c,
          Alcohol_Addendum_Signed__c,
          Alcohol_Eligibility__c
        FROM Account
        WHERE Restaurant_Id__c IN :storeIds
      ]) {
        idToAccount.put(acc.Restaurant_ID__c, acc);
      }
      jsonBuilder = new JSONUtility.DynamicJSONBuilder(
        'StoreDetails/' + version
      );
      for (String storeId : storeIds) {
        accountIterator = idToAccount.get(storeId);
        if (idToAccount.containsKey(storeId)) {
          sourceData = ApexRestUtil.reformatSObjectRecord(accountIterator);
          sourceData.put(
            'alcohol_activated',
            (accountIterator.Alcohol_Addendum_Signed__c &&
            accountIterator.Alcohol_Eligibility__c != 'Not Eligible')
          );
          payload.add(jsonBuilder.buildJSONPayloadOnSuccess(sourceData));
        } else {
          payload.add(
            new Map<String, Object>{
              'store_id' => storeId,
              'error' => 'Store not found',
              'details' => new Map<String, Object>()
            }
          );
        }
      }
      return JSON.serializePretty(
        new Map<String, Object>{ 'store_list' => payload }
      );
    } catch (Exception e) {
      insert new Apex_Log__c(
        Class_Name__c = 'StoreDetails: ' + system.now().format(),
        Method_Name__c = 'getStoreDetails',
        Log_Level__c = 'Error',
        Log__c = e.getStackTraceString()
      );
      throw new StoreDetailsException(e);
    }
  }

  class StoreDetailsException extends Exception {
  }
}