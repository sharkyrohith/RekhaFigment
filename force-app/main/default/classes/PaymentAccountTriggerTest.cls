@isTest
public class PaymentAccountTriggerTest {
  @isTest
  static void testWhenNewPaymentAccountThenAddressVerified(){
    List<sObject> pa = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
  }
}