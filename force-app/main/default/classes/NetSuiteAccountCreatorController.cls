public without sharing class NetSuiteAccountCreatorController {
  public static final String calloutErrorMessage = 'NetSuite account creation error';
  public static final String queryExceptionMessage = 'Opportunity Criteria not met';
  public static final String successMessage = 'NetSuite Account created Successfully';
  public static Id oppMarketplaceRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('ML_Inside_Sales');
    public static Set<String> netsuiteOppRecordTypeIds = new Set<String>();    
    static {
        for (Opp_NetSuite_Account_Record_Type__mdt config : [SELECT Id, Label, 
                                                            Record_Type_Developer_Name__c, Record_Type_Id__c
                                                            FROM Opp_NetSuite_Account_Record_Type__mdt
                                                            Where Is_Active__c = true]){
            netsuiteOppRecordTypeIds.add(config.Record_Type_Id__c);
        }
    }  
  @AuraEnabled
  public static String createNetSuiteAccount(Id recordId) {
    String returnMessage = '';
    try{
      Opportunity opp = [SELECT Id, AccountId, Account.Primary_Payment_Account__c, Payment_Account__c 
          FROM Opportunity WHERE Payment_Account__r.NetSuite_Id__c = null 
              AND RecordTypeId IN :netsuiteOppRecordTypeIds
              AND (PactSafe_Record__c = null OR (RecordTypeId = :oppMarketplaceRTID AND Legal_Entity__c = 'US - G&C')) AND Payment_Account__c = :recordId LIMIT 1];
      if(opp.Account.Primary_Payment_Account__c == null){
        NetSuiteRequestHandler.sendPaymentAccountCreationRequest(opp.Payment_Account__c, opp.AccountId);
      }else{
        NetSuiteRequestHandler.sendPaymentAccountCreationRequest(opp.Payment_Account__c, null);
      }
      returnMessage = successMessage;
    }catch(QueryException qe){
      returnMessage = queryExceptionMessage;
      if (!Test.isRunningTest()) throw new AuraHandledException(returnMessage);
    }
    catch(CalloutException ce){
      returnMessage = calloutErrorMessage;
      if (!Test.isRunningTest()) throw new AuraHandledException(returnMessage);
    }
    return returnMessage;
  }
}