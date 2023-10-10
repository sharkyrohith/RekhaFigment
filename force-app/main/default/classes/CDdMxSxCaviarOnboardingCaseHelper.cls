/********************************************************************************************************************
* @author Lathika
* @date 02/2023
*
* @group Merchant Services
*
* @description Helper class for Caviar Onboarding Case related operations
* scope:  operate on Caviar Onboarding cases, the class has helper methods for Identifying Case and orderline items eligible for Ads and promo
**************************************************************************************************************************************/
public class CDdMxSxCaviarOnboardingCaseHelper {
    private CDdMxSxOpportunityHelper opportunityHelper;
    /**
     * @description Single argument constructor
     * @param Set<Id> oppIds - Collection of Opportunity Ids
     * @return void
     */
    public CDdMxSxCaviarOnboardingCaseHelper(Set<Id> oppIds) {
        this.opportunityHelper = new CDdMxSxOpportunityHelper(oppIds);
    }

    /**
     * @description check if Case is meeting criteria for Caviar Turbo Charge related updates
     * opportunity Not Null, case.MxP_Handoff_Date__c != null, case.Activation_Date__c != null
     * Opportunity Platform = "Caviar and Doordash"
     * @param Case newCase
     * @return Boolean
    */
    public Boolean isCaseEligibleForTurboChargeUpdate(Case c){
        if(c.opportunity_name__c != null
              && this.opportunityHelper.hasCPQProducts(c.Opportunity_Name__c)
              && c.MxP_Handoff_Date__c != null
              && c.Activation_Date__c != null
              && this.opportunityHelper.isCaviarOpportunity(c.opportunity_name__c)
              && CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH.equals(this.opportunityHelper.getPlatform(c.opportunity_name__c))
              && c.RecordTypeId == CDdSchemaUtils.CASE_RT.caviarOnboardingId()
              ){
                    return true;
        }
            return false;
    }
     /**
     * @description Checking the OrderItem is eligible for Updating
     * exclude the product Ids defined in the Custom label Mx_Ads_Promos_Products
     * Delay_after_Activation_days__c Not equals null
     * Length_of_Term__c Not equals null
     * @param orderItem orderlineItem
     * @return Boolean
    */
    public static Boolean isOrderItemEligibleForUpdate(orderItem orderlineItem){
        if (CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS.contains(orderlineItem.Product2.Family)
            && orderlineItem.Delay_after_Activation_days__c != null
            && orderlineItem.Length_of_Term__c != null
            && orderlineItem.Length_of_Term__c.isNumeric()
            && !CDdMxSxConstants.ADS_PROMOS_PRODUCTS_DD_CUSTOM_IDS_TO_EXCLUDE.contains(orderlineItem.Product2.DD_Custom_ID__c)){
                return true;
        }
        return false;
    }
     /**
     * @description create a Map of Opportunity id to Ads and promo order line items
     * @param Set<id> oppidsToProcess
     * @return  Map<Id, List<OrderlineItems>>
    */
    public Map<Id, List<OrderItem>> getOrderLineItemsForOppMap(Set<id> oppidsToProcess){
        Map<Id, List<OrderItem>> orderlinetItemsByOppID = new Map<Id, List<OrderItem>>();
        for (ID oppId : oppidsToProcess){
            if (this.opportunityHelper.getOrderItemsForProductsOfAdsAndPromoFamilies(oppId)!= null) {
                orderlinetItemsByOppID.put(oppId , this.opportunityHelper.getOrderItemsForProductsOfAdsAndPromoFamilies(oppId));
            }
        }
        return orderlinetItemsByOppID;
    }

    /**
     * @description create a Map of Opportunity id to Ads and promo order line items
     * @param Set<id> oppidsToProcess
     * @return  Map<Id, List<OrderlineItems>>
    */
    public List<OrderItem> getOrderLineItemsForOpp(Id oppId){
       List<OrderItem> orderlinetItems = new  List<OrderItem>();
            if (this.opportunityHelper.getOrderItemsForProductsOfAdsAndPromoFamilies(oppId)!= null ) {
                orderlinetItems = this.opportunityHelper.getOrderItemsForProductsOfAdsAndPromoFamilies(oppId);
            }
        return orderlinetItems;
    }

     /**
    * @description create a Map of Opportunity id to Ads and promo order line items
    * Static method to get a Map of Opportunity id to Ads and promo order line items
    * @param Set<id> oppidsToProcess
    * @return  Map<Id, List<OrderlineItems>>
   */
    public static Map<Id, List<OrderItem>> getOrderLineItemsForOpportunityMap(Set<id> oppidsToProcess){
        Map<Id, List<OrderItem>> orderlinetItemsByoppID = new Map<Id, List<OrderItem>>();
        List<OrderItem> orderItems  = OrderItemsSelector.newInstance().selectByOrderIdAndProductFamily(oppidsToProcess, new Set<String>(CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS));
        if (!orderItems.isEmpty()){
            for (OrderItem orderLineItem : orderItems ){
                if(orderlinetItemsByoppID.containsKey(orderLineItem.order.OpportunityId)) {
                    List<OrderItem> olineitems = orderlinetItemsByoppID.get(orderLineItem.order.OpportunityId);
                    olineitems.add(orderLineItem);
                    orderlinetItemsByoppID.put(orderLineItem.order.OpportunityId , olineitems);
                } else {
                    orderlinetItemsByoppID.put(orderLineItem.order.OpportunityId, new List<OrderItem> { orderLineItem });
                }
            }
        }
        return orderlinetItemsByoppID;
    }

    /**
    * BZAP-19359
    * @description Process the Caviar Onbaording cases of Platform: caviar and Doordash.
    * DO not Set the case status for Caviar Onbaording case to Closed: (If there are products of Ads and Promo family)
    * @param Set<id> newCaseList
    * @return  null
    */
    public static void setCaviarOnboardingCaseStatusToClosedForPlatformCaviarAndDoordash (List<Case> newCaseList){
        Map<Id, List<OrderItem>> orderlineItemsByoppID = new Map<Id, List<OrderItem>>();
        Set<Id> oppidsToProcess = new Set<Id>();
        for (Case newCase : newCaseList) {
                oppidsToProcess.add(newCase.Opportunity_Name__c);
        }
        if (!oppidsToProcess.isEmpty()) {
            orderlineItemsByoppID = getOrderLineItemsForOpportunityMap(oppidsToProcess);
        }
        Boolean isCaseElibleToUpdate = true;
        for (Case caseToProcess : newCaseList) {
            isCaseElibleToUpdate = true;
            if (orderlineItemsByoppID.containsKey(caseToProcess.opportunity_name__c)) {
                for(OrderItem orderLineItem : orderlineItemsByoppID.get(caseToProcess.opportunity_name__c)){
                    if(isOrderItemEligibleForUpdate(orderLineItem)){
                        isCaseElibleToUpdate = false;
                     }
                }
            }
            if(isCaseElibleToUpdate){
                caseToProcess.Status = CDdMxSxConstants.CASE_STATUS_CLOSED;
            }
        }
    }
}