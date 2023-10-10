/********************************************************************************************************************
* @author Sriram
* @date 04/01/2022
*
* @group Merchant Services
*
* @description Trigger handler for object Mx_Order_Item__c
*
**************************************************************************************************************************************/
public class CDdMxOrderItemTriggerHandler {      
    /**
     * @description Trigger after update operation on Object Mx_Order_Item__c
     * @param List<Mx_Order_Item__c> newList
     * @param Map<Id, Mx_Order_Item__c> oldMap
     * @return
     */
    public void afterUpdate(List<Mx_Order_Item__c> newList, Map<Id, Mx_Order_Item__c> oldMap){
        CDdMxOrderItemTriggerHelper.handleOrderItemUpdates(newList, oldMap);
    }
}