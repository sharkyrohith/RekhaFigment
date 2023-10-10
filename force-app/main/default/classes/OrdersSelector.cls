/********************************************************************************************************************
* @author Sriram
* @date 10/08/2022
*
* @group fflib
*
* @description Selector class for Order sObject type
*
**************************************************************************************************************************************/
public virtual inherited sharing class OrdersSelector extends SObjectsSelector implements IOrdersSelector {
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     * @return A concrete or mock implementation of the IOrdersSelector
     */
    public static IOrdersSelector newInstance() {
        return (IOrdersSelector) Application.Selector.newInstance( Order.SObjectType );
    }
    /**
     * @description Method for defining the default fields that are included in the query results.
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Order.Id,
            Order.OpportunityId,
            Order.SBQQ__Quote__c
        };
    }
    /**
     * @description Defines the SObject to be queried by this selector
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Order.SObjectType;
    }
    /**
     * @description Method for querying Order records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Order records
     */
    public List<Order> selectById( Set<Id> ids ) {
        return (List<Order>) selectSObjectsById( ids );
    }
    /**
     * @description Method for querying Order and Order Item child records when you know their associated OpportunityIds
     * @param opportunityIds The ids of the Opportunity Records
     * @return A list of Order records with the corresponding Order Items
     */
    public List<Order> selectOrderAndOrderItemsByOpportunityId(Set<Id> opportunityIds) {
        fflib_QueryFactory ordersFactory = newQueryFactory();
        ordersFactory
        .selectFields(getSObjectFieldList())
        .setCondition('OpportunityId IN :opportunityIds');
        fflib_QueryFactory orderItemsFactory = ordersFactory.subselectQuery('OrderItems');
        orderItemsFactory.selectFields(new Set<String>{
            'Id', 'OrderId', 'Quantity', 'SBQQ__OrderedQuantity__c',
            'SBQQ__QuoteLine__r.SBQQ__StartDate__c', 'SBQQ__QuoteLine__r.Trial_Start_Date__c',
            'SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c',
            'Product2Id', 'Product2.Id', 'Product2.Family', 'Product2.Name', 'Product2.Priority_for_Activation__c',
            'Delay_after_Activation_days__c', 'Length_of_Term__c','Promo_End_Day__c','Promo_Start_Day__c', 'Product2.DD_Custom_ID__c'
        });
        return (List<Order>) Database.query(ordersFactory.toSOQL());
    }
}