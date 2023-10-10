trigger PaymentAccountTrigger on Payment_Account__c (before insert, before update, after insert, after update) {
  //BZAP-13557 - False positive for Logic inside trigger
  if(Test.isRunningTest() || !CDdCustomMetaData.isDisabled('Payment_Account_AV')){
    new smartystreets.AutoVerificationServices().HandleAutoVerify('Payment_Account__c');
  }
}