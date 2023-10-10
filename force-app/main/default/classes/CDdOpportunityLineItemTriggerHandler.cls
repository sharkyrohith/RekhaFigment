/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/18/2020
*
* @group Trigger Handler
*
* @description Trigger handler for Opportunity Line Item object
**************************************************************************************************************************************/
public class CDdOpportunityLineItemTriggerHandler {
    /**
    * @description Before insert trigger event
    */
    public void beforeInsert(List<OpportunityLineItem> newList) {
    	CDdOpportunityLineItemHelperMethods.applyDefaults(newList);
        CDdOpportunityLineItemHelperMethods.updateFieldsOnOppProducts(newList);
        CDdOpportunityLineItemValidationHelper.validateOpportunitiesDoorDashForBusiness(newList);
        CDdOpportunityLineItemHelperMethods.fopoAndOrOAS(newList, null);
    }
    /**
    * @description After insert trigger event
    */
    public void afterInsert(Map<Id, OpportunityLineItem> newMap) {
    	CDdOpportunityLineItemHelperMethods.updateOpportunity(newMap.values());
        CDdOpportunityLineItemHelperMethods.disablePactSafeCWRule(newMap);
        CDdOpportunityLineItemHelperMethods.finishOpportunityUOW();
    }
    /**
    * @description Before update trigger event
    */
    public void beforeUpdate(Map<Id, OpportunityLineItem> newMap, Map<Id, OpportunityLineItem> oldMap) {
        CDdOpportunityLineItemHelperMethods.updateFieldsOnOppProducts(newMap.values());
        CDdOpportunityLineItemValidationHelper.validateOpportunitiesDoorDashForBusiness(newMap.values());
        CDdOpportunityLineItemHelperMethods.fopoAndOrOAS(newMap.values(), oldMap);
    }    
    /**
    * @description After update trigger event
    */
    public void afterUpdate(Map<Id, OpportunityLineItem> newMap, Map<Id, OpportunityLineItem> oldMap) {
    }
    /**
    * @description before delete trigger event
    */
    public void beforeDelete (Map<Id, OpportunityLineItem> oldMap) {
        CDdOpportunityLineItemHelperMethods.preventOLIDeletionAfterContractSigned(oldMap);
    }
    /**
    * @description after delete trigger event
    */
    public void afterDelete (Map<Id, OpportunityLineItem> oldMap) {
        CDdOpportunityLineItemHelperMethods.updateOpportunity(oldMap.values());
        CDdOpportunityLineItemHelperMethods.disablePactSafeCWRule(oldMap);
        CDdOpportunityLineItemHelperMethods.finishOpportunityUOW();
    }
}