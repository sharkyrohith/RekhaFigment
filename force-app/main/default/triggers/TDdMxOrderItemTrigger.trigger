/********************************************************************************************************************
* @author Sriram
* @date 04/01/2022
*
* @group Merchant Services
*
* @description Trigger on object Mx_Order_Item__c
*
**************************************************************************************************************************************/
trigger TDdMxOrderItemTrigger on Mx_Order_Item__c (after update) {
    CDdMxOrderItemTriggerHandler handler = new CDdMxOrderItemTriggerHandler();
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}