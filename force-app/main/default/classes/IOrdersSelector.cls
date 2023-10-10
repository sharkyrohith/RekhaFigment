/********************************************************************************************************************
* @author Sriram
* @date 10/08/2022
*
* @group fflib
*
* @description Interface for Order Selector
* 
**************************************************************************************************************************************/
public interface IOrdersSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Order records when you know their ids
     * @param orderIds The ids of the records to be returned
     * @return A list of Order records
     */
    List<Order> selectById( Set<Id> orderIds );
    /**
     * @description Method for querying Order and Order Item child records when you know their associated OpportunityIds
     * @param opportunityIds The ids of the Opportunity Records
     * @return A list of Order records with the corresponding Order Items
     */
    List<Order> selectOrderAndOrderItemsByOpportunityId(Set<Id> opportunityIds);       
}