/**
* @author: Cory Bartholomew (ATG)
* @date: 2021-02    
* @description: Trigger Helper for Orders to support the CPQ Project             
*/ 

public with sharing class CDdOrderTriggerHelper {
    /**
     * @author:      Cory Bartholomew (ATG)
     * @date:        2021-02
     * @description: ATG-88 Generate a Contract from the Order when the Order is activated
     */
    public static void generateContractsFromOrders(List<Order> orders, Map<Id, Order> oldMap) {
        //As part of phase 1 Contracting should be disabled
        if (CDdRecursionUtils.isRunnable('CDdOrderTrigger_generateContracts')){
            List<Order> ordersToUpdate = new List<Order>();
            for(Order order : orders) {
                if(
                    order.status == 'Activated' && 
                    oldMap.get(order.Id).Status != 'Activated' &&
                    !order.SBQQ__Contracted__c
                ) {
                    ordersToUpdate.add(
                        new Order(
                            Id = order.Id,
                            SBQQ__Contracted__c = true
                        )
                    );
                }
            }

            if(!ordersToUpdate.isEmpty()){
                update ordersToUpdate;
            }
        }
    }

    /**
     * @author:      Cory Bartholomew (ATG)
     * @date:        2021-02
     * @description: ATG-88 Generate a Contract from the Order when the Order is activated
     */
    public static void activateOrders(List<Order> orders, Map<Id, Order> oldMap) {
        //As part of phase 1 Contracting should be disabled
        if (CDdRecursionUtils.isRunnable('CDdOrderTrigger_activateOrders')){
            Set<Id> orderIds = new Set<Id>();
            for(Order order : orders) {
                //Effective Date should only get updated once the Opportunity Activation has occurred
                //If activation occurs on the same day as order generation, evaluate the 'Ready for activation flag'
                if(
                    order.status != 'Activated' && 
                    order.Opportunity_Record_Type__c == CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId() &&
                    (
                        (order.EffectiveDate != oldMap.get(order.Id).EffectiveDate) ||
                        (order.EffectiveDate == oldMap.get(order.Id).EffectiveDate && order.Ready_for_Activation__c == true && oldMap.get(order.Id).Ready_for_Activation__c == false)
                    )
                ) {
                    orderIds.add(order.Id);
                }
            }

            if(!orderIds.isEmpty()){
                activateOrdersFuture(orderIds); 
            }       
        }
    }

    @future
    public static void activateOrdersFuture(Set<Id> orderIDs){
        if(!CDdRecursionUtils.isRunnable('CDdOrderTrigger_activateOrders')){
            return;
        }
        List<Order> ordersToUpdate = new List<Order>();
        for(Id orderId : orderIDs){
            ordersToUpdate.add(new Order(Id = orderId, Status = 'Activated')); 
        }        
        if(!ordersToUpdate.isEmpty()){
            update ordersToUpdate;
        }        
    }
}