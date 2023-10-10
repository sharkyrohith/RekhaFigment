/**
 * @description Selector Class for OrderItem SObject
 *
 * @author Krishna Sanisetty
 * @date 10/07/2022
 */
public inherited sharing class OrderItemsSelector extends SObjectsSelector implements IOrderItemsSelector{
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the IOrderItemsSelector
     */
    public static IOrderItemsSelector newInstance() {
        return (IOrderItemsSelector) Application.Selector.newInstance(Schema.OrderItem.SObjectType);
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     *
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            OrderItem.Id,
            OrderItem.Promo_End_Day__c,
            OrderItem.Promo_Start_Day__c
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return OrderItem.SObjectType;
    }

     /**
     * @description Method for querying Order Item records by Opportunity id(s) and associated Products productFamily
     *
     * @param opportunityIds set of associated Opportunity id(s)
     * @param productFamily set of products product family
     * @return A list of OrderItem records
     */
    public List<OrderItem> selectByOrderIdAndProductFamily(Set<Id> opportunityIds, Set<String> productFamily) {
        return (List<OrderItem>) Database.query(
            newQueryFactory()
                .selectField('Product2.Name')
                .selectField('Product2.Family')
                .selectField('Delay_after_Activation_days__c')
                .selectField('Length_of_Term__c')
                .selectField('Promo_Start_Day__c')
                .selectField('Promo_End_Day__c')
                .selectField('Product2.Id')
                .selectField('Order.OpportunityID')
                .selectField('Product2.DD_Custom_ID__c')
                .setCondition('OrderId IN (SELECT Id FROM Order WHERE OpportunityId = :opportunityIds) AND Product2.Family IN :productFamily')
                .toSoql()
        );
    }

    /**
        @author: Dan Thoreson
        @date: 09-Jan-2023
        @description: From an inputted Set of Opportunity IDs, returns the Storefront Package OrderItems
    **/
    public List<OrderItem> selectItemsWithStorefrontProducts(Set<Id> opportunityIds) {
        String storefrontProductNames = '%' + CDdMxSxConstants.STOREFRONT_CONTAINS_KEY_BUNDLE_NAME_FOR_CPQ + '%';

        return (List<OrderItem>) Database.query(
            newQueryFactory()
                .selectField('OrderId')
                .selectField('Order.OpportunityId')
                .setCondition('Order.OpportunityId IN :opportunityIds AND Product2.Name LIKE :storefrontProductNames')
                .toSoql()
        );
    }
}