/********************************************************************************************************************
* @author Sriram
* @date 03/29/2022
*
* @group Merchant Services
*
* @description Trigger helper for object Mx_Order_Queue__c
*
**************************************************************************************************************************************/
public class CDdMxOrderQueueTriggerHelper {
    /**
     * @description Variables defined here
     */
    public static final String VALIDATION_MX_ORDER_ALREADY_QUEUED = 'Mx Order {0} has already been queued.';
    public static final String VALIDATION_MX_ORDER_CANNOT_BE_CHANGED = 'Mx Order {0} cannot be changed.';
    public static final String VALIDATION_MX_ORDER_ALREADY_PROCESSED = 'Mx Order {0} has already been processed.';
    /**
     * @description Validate the insertion of inbound Mx Order Queue record
     * Validation Rule - Prevent queue of Mx Order, if the Mx Order has already been queued
     * @param List<Mx_Order_Queue__c> newList
     * @return
     */  
    public static void validateInsert(List<Mx_Order_Queue__c> newList){
        Set<Id> newMxOrderIds = new Set<Id>();
        Set<Id> existingMxOrderIds = new Set<Id>();
        for (Mx_Order_Queue__c newQueue : newList){
            if (String.isNotBlank(newQueue.Mx_Order__c)){
                newMxOrderIds.add(newQueue.Mx_Order__c);                    
            }
        }
        for (Mx_Order_Queue__c existingQueue : [SELECT Id, Mx_Order__c FROM Mx_Order_Queue__c WHERE Mx_Order__c IN :newMxOrderIds]){
            if (String.isNotBlank(existingQueue.Mx_Order__c)){
                existingMxOrderIds.add(existingQueue.Mx_Order__c);
            }
        }
        for (Mx_Order_Queue__c newQueue : newList){
            if (String.isNotBlank(newQueue.Mx_Order__c)){
                if (existingMxOrderIds.contains(newQueue.Mx_Order__c)){
                    newQueue.addError(String.format(VALIDATION_MX_ORDER_ALREADY_QUEUED, new List<String>{ newQueue.Mx_Order__c }));
                    newQueue.Mx_Order__c.addError(String.format(VALIDATION_MX_ORDER_ALREADY_QUEUED, new List<String>{ newQueue.Mx_Order__c }));
                }
            }
        }
    }
        /**
     * @description Validate the update of inbound Mx Order Queue record
     * Validation Rules
     * - Cannot change the Mx Order on the Queue, once it has been set during insert operation 
     * - Prevent update of Mx Order Queue record, if the Mx Order has already been processed i.e. Mx_Order__r.Order_Id__c != null
     * @param List<Mx_Order_Queue__c> newList
     * @param Map<Id, Mx_Order_Queue__c> oldMap
     * @return
     */  
    public static void validateUpdate(List<Mx_Order_Queue__c> newList, Map<Id, Mx_Order_Queue__c> oldMap){
        Map<Id, Mx_Order_Queue__c> newMap = new Map<Id, Mx_Order_Queue__c>();
        for (Mx_Order_Queue__c q : newList){
            newMap.put(q.Id, q);
        }
        for (Mx_Order_Queue__c queue : [SELECT Id, Mx_Order__c, Mx_Order__r.Order_Id__c FROM Mx_Order_Queue__c WHERE Id IN :newMap.keySet()]){
            if (CDdMxSxTriggerHelper.hasFieldValueChanged(newMap.get(queue.Id), queue, new Set<String>{'Mx_Order__c'})){
                newMap.get(queue.Id).addError(String.format(VALIDATION_MX_ORDER_CANNOT_BE_CHANGED, new List<String>{ queue.Mx_Order__c }));
            } else if (queue.Mx_Order__c != null && String.isNotBlank(queue.Mx_Order__r.Order_Id__c)){
                newMap.get(queue.Id).addError(String.format(VALIDATION_MX_ORDER_ALREADY_PROCESSED, new List<String>{ queue.Mx_Order__c }));
                newMap.get(queue.Id).Mx_Order__c.addError(String.format(VALIDATION_MX_ORDER_ALREADY_PROCESSED, new List<String>{ queue.Mx_Order__c }));                
            }
        }
    }
    /**
     * @description Set the Queue reference on the Mx Order record. 
     * This will establish whether the Mx Order has been queued (or not)
     * @param List<Mx_Order_Queue__c> newList
     * @return
     */      
    public static void setQueueOnMxOrder(List<Mx_Order_Queue__c> newList){
        Map<Id, Id> queueIdForMxOrderId = new Map<Id, Id>();
        List<Mx_Order__c> mxOrdersToUpdate = new List<Mx_Order__c>();
        for (Mx_Order_Queue__c newQueue : newList){
            if (String.isNotBlank(newQueue.Mx_Order__c)){
                queueIdForMxOrderId.put(newQueue.Mx_Order__c, newQueue.Id);                    
            }
        }        
        for (Mx_Order__c mxOrder : [SELECT Id, Mx_Order_Queue__c FROM Mx_Order__c WHERE Id IN :queueIdForMxOrderId.keySet()]){
            mxOrdersToUpdate.add(new Mx_Order__c(Id = mxOrder.Id, Mx_Order_Queue__c = queueIdForMxOrderId.get(mxOrder.Id), Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_QUEUED, Order_Status_Description__c = null, Order_Status_Last_Modified_Date__c = System.now()));
        }
        if (!mxOrdersToUpdate.isEmpty()){
            update mxOrdersToUpdate;
        }
    }
}