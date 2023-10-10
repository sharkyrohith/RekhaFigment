/**
 * @description Trigger on the pactsafe1__PactSafeRequest__c.
 *  Introduced by BZAP-13135 to support the PactSafe integration.
 *
 * @see CDdPactSafeRequestTriggerHandler
 * @see CDdPactSafeRequestTriggerHelper
 **/
trigger TDdPactSafeRequestTrigger on pactsafe1__PactSafeRequest__c (after insert) {
    CDdPactSafeRequestTriggerHandler handler = new CDdPactSafeRequestTriggerHandler();

    if (Trigger.isAfter && Trigger.isInsert){
        handler.afterInsert(Trigger.new);
    }
}