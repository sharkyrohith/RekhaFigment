public with sharing class CDdCaseTriggerHelper_CPQ {
    public static Id POST_SALE_CASE_RT = CDdSchemaUtils.CASE_RT.postSaleActivationsId();
    
    public static void postSaleActivationsCaseClosed(List<Case> cases, Map<Id,Case> oldMap){
        List<OrderItem> orderProductsToUpdate = new List<OrderItem>();
        Map<Id,Case> orderProductCaseMap = new Map<Id,Case>();
        for(Case postSaleCase : cases){
            if(
                postSaleCase.RecordTypeId == POST_SALE_CASE_RT &&
                postSaleCase.Order_Product__c != null &&
                postSaleCase.Status == 'Closed' &&
                oldMap.get(postSaleCase.Id).Status != 'Closed'
            ){
                if(!orderProductCaseMap.containsKey(postSaleCase.Order_Product__c)){
                    orderProductCaseMap.put(postSaleCase.Order_Product__c, postSaleCase);
                }
            }
        }

        if(!orderProductCaseMap.keySet().isEmpty()){
            //Get the order products or and children order products from the set to activate them
            Map<Id, OrderItem> orderProductMap = new Map<Id,OrderItem>([
                SELECT Id, OrderId, ServiceDate, SBQQ__Status__c, 
                    (
                        SELECT Id, OrderId, ServiceDate, SBQQ__Status__c
                        FROM SBQQ__Components__r
                    ) 
                FROM OrderItem 
                WHERE Id IN :orderProductCaseMap.keySet()
            ]);

            for(Case postSaleCase : orderProductCaseMap.values()){
                OrderItem orderProduct;
                if(orderProductMap.containsKey(postSaleCase.Order_Product__c)){
                    orderProduct = orderProductMap.get(postSaleCase.Order_Product__c);
                    orderProduct.ServiceDate = postSaleCase.Activation_Date__c;
                    orderProduct.SBQQ__Status__c = 'Activated';
                    orderProductsToUpdate.add(orderProduct);
                    //Also update the relevant child order products
                    if(!orderProduct.SBQQ__Components__r.isEmpty()){
                        for(OrderItem childOrderProduct : orderProduct.SBQQ__Components__r){
                            childOrderProduct.ServiceDate = postSaleCase.Activation_Date__c;
                            childOrderProduct.SBQQ__Status__c = 'Activated';
                        }                
                        orderProductsToUpdate.addAll(orderProduct.SBQQ__Components__r);
                    }
                }
            }
        }
        
        if(!orderProductsToUpdate.isEmpty()){
            update orderProductsToUpdate;
        }
    }
}