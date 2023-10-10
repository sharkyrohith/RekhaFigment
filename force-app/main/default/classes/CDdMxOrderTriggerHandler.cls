/********************************************************************************************************************
* @author Sriram
* @date 03/21/2022
*
* @group Merchant Services
*
* @description Trigger handler for object Mx_Order__c
*
**************************************************************************************************************************************/
public class CDdMxOrderTriggerHandler {
    /**
     * @description Trigger before insert operation on Object Mx_Order__c
     * @param List<Mx_Order__c> newList
     * @return 
     */
    public void beforeInsert(List<Mx_Order__c> newList) {
        Map<Id, Case> cases = CDdMxSxQueryCases.getCases(CDdMxSxQueryCases.getCaseIds(newList)); 
        CDdMxOrderTriggerHelper.validate(newList);
        CDdMxOrderTriggerHelper.overrideStatusIfNecessary(newList, null, cases);
        CDdMxOrderTriggerHelper.setShippingCarrier(newList, null);
    }
    /**
     * @description Trigger after insert operation on Object Mx_Order__c
     * @param List<Mx_Order__c> newList
     * @return 
     */
    public void afterInsert(List<Mx_Order__c> newList) {
        CDdMxOrderTriggerHelper.insertMxOrderItems(newList);
        CDdMxOrderTriggerHelper.publishEventsSendMxOrderToVendor(newList);
    }
    /**
     * @description Trigger before update operation on Object Mx_Order__c
     * @param List<Mx_Order__c> newList
     * @param Map<Id, Mx_Order__c> oldMap
     * @return
     */
    public void beforeUpdate(List<Mx_Order__c> newList, Map<Id, Mx_Order__c> oldMap){
        Map<Id, Case> cases = CDdMxSxQueryCases.getCases(CDdMxSxQueryCases.getCaseIds(newList));
        CDdMxOrderTriggerHelper.overrideStatusIfNecessary(newList, oldMap, cases);
        CDdMxOrderTriggerHelper.setShippingCarrier(newList, oldMap);
    }        
    /**
     * @description Trigger after update operation on Object Mx_Order__c
     * @param List<Mx_Order__c> newList
     * @param Map<Id, Mx_Order__c> oldMap
     * @return
     */
    public void afterUpdate(List<Mx_Order__c> newList, Map<Id, Mx_Order__c> oldMap){
        CDdMxOrderTriggerHelper.handleMxOrderItemsUpdate(newList, oldMap);
        CDdMxOrderTriggerHelper.handleMxOrderStatusUpdate(newList, oldMap);
        CDdMxOrderTriggerHelper.handleInsertShipmentRecords(newList, oldMap);      
    }
}