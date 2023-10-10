global without sharing class NetSuiteRequestHandler {
  public static final String accountCreationDescribeName = 'Payment Account';

  @future(callout=true)
  public static void sendPaymentAccountCreationRequest(Map<String, String> paIdToAccountId){
    for(String paId: paIdToAccountId.keySet()){
      sendPaymentAccountCreationRequest(paId, paIdToAccountId.get(paId));
    }
  }

  public static void sendPaymentAccountCreationRequest(String paymentAccountRecordId, String opportunityAccountId){
    HttpResponse resp;
    String failureMessage = '';
    HttpRequest req = OAuth1RequestGenerator.generateRequest(accountCreationDescribeName, paymentAccountRecordId,'Payment_Account__c');
    try{
      resp = (new Http()).send(req);
      if(resp.getStatusCode() != 200){
        throw new CalloutException('Code: '+ resp.getStatusCode() + ' Status: ' + resp.getStatus()+ 'Body: '+ resp.getBody());
      }
      Map<String, Object> content = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
      insert new Apex_Log__c(Class_Name__c = 'NetSuiteRequestHandler: '+system.now().format(), Method_Name__c = 'sendPaymentAccountCreationRequest', Log_Level__c = 'Debug', Log__c = '{"PA":'+paymentAccountRecordId+', "Account":'+opportunityAccountId+'} '+ resp.getBody());
      update new Payment_Account__c (Id = paymentAccountRecordId, Netsuite_Fail_Response__c = null, Netsuite_Success_Status__c = 'Success. '+String.valueOf(resp.getStatusCode()), NetSuite_ID__c = (String) content.get('id'));
      if(opportunityAccountId != null){
        update new Account(Id = opportunityAccountId, Primary_Payment_Account__c = paymentAccountRecordId);
      }
    }catch(Exception e){
      String respBody = (resp == null)? '': resp.getBody();
      Integer respCode = (resp == null)? -9999: resp.getStatusCode();
      failureMessage += 'Failed. '+ e.getMessage()+ ' resp body: '+respBody+' trace: '+e.getStackTraceString();
      insert new Apex_Log__c(Class_Name__c = 'NetSuiteRequestHandler: '+system.now().format(), Method_Name__c = 'sendPaymentAccountCreationRequest', Log_Level__c = 'Error', Log__c = '{"PA":'+paymentAccountRecordId+', "Account":'+opportunityAccountId+'} '+ failureMessage);
      update new Payment_Account__c (Id = paymentAccountRecordId, Netsuite_Fail_Response__c = failureMessage.substring(0, Math.Min(255, failureMessage.length())), Netsuite_Success_Status__c = 'Failed. '+String.valueOf(respCode));
    }
  }
}