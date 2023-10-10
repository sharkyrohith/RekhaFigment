/********************************************************************************************************************
* @author Sriram
* @date 03/29/2022
*
* @group Merchant Services
*
* @description Trigger handler for object Mx_Order_Queue__c
*
**************************************************************************************************************************************/
public class CDdMxOrderQueueTriggerHandler {
    /**
     * @description Trigger before insert operation on Object Mx_Order_Queue__c
     * @param List<Mx_Order_Queue__c> newList
     * @return 
     */
    public void beforeInsert(List<Mx_Order_Queue__c> newList) {
        CDdMxOrderQueueTriggerHelper.validateInsert(newList);
    }
    /**
     * @description Trigger before update operation on Object Mx_Order_Queue__c
     * @param List<Mx_Order_Queue__c> newList
     * @param Map<Id, Mx_Order_Queue__c> oldMap
     * @return 
     */
    public void beforeUpdate(List<Mx_Order_Queue__c> newList, Map<Id, Mx_Order_Queue__c> oldMap) {
        CDdMxOrderQueueTriggerHelper.validateUpdate(newList, oldMap);
    }         
    /**
     * @description Trigger after insert operation on Object Mx_Order_Queue__c
     * @param List<Mx_Order_Queue__c> newList
     * @return 
     */
    public void afterInsert(List<Mx_Order_Queue__c> newList) {
        CDdMxOrderQueueTriggerHelper.setQueueOnMxOrder(newList);
    }
    /**
     * @description Trigger after insert operation on Object Mx_Order_Queue__c
     * @param List<Mx_Order_Queue__c> newList
     * @param Map<Id, Mx_Order_Queue__c> oldMap
     * @return 
     */
    public void afterUpdate(List<Mx_Order_Queue__c> newList, Map<Id, Mx_Order_Queue__c> oldMap) {
        CDdMxOrderQueueTriggerHelper.setQueueOnMxOrder(newList);
    }    
}