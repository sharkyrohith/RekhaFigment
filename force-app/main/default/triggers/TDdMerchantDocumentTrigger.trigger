/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 03/08/2021
*
* @group Trigger
*
* @description Trigger for Merchant Document
**************************************************************************************************************************************/
trigger TDdMerchantDocumentTrigger on Merchant_Document__c (after insert, after update, after delete) {
    
    CDdMerchantDocumentTriggerHandler handler = new CDdMerchantDocumentTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete) {
            handler.afterDelete(Trigger.oldMap);
        } 
    }    
    
}