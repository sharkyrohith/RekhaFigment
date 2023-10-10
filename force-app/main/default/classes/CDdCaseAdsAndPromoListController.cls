/**
 * @author: Krishna Sanisetty
 * @date: 09/07/2022
 * @decription: Created this class as part of the ticket BZAP-16364 to
 * 1. Validate visibility of the component
 * 2. Retrieve the OrderItems associated to a Opportunity
 *
 * @date:10/07/2022
 * Updated the SoQLs to the Selector class methods.
 */
public with sharing class CDdCaseAdsAndPromoListController {

    @testvisible
    private static final string MILESTONE_STATUS = 'Complete';
    @testvisible
    private static final string VALIDITY_MAP_KEY_NAME = 'ShowProducts';
    @testvisible
    private static final String ADS_PROMO_TYPE = 'Ads & Promos';
    @testvisible
    private static final String ACTIVATE_STORE_TYPE = 'Activate Store';
    @testvisible
    private static final String ACTIVATIONS_CHECKLIST_TYPE = 'Activations Checklist';
    @testvisible
    private static final Set<String> PRODUCT_FAMILY = new Set<String>{'Marketplace Promotion', 'Advertisement'};
    @testvisible
    private static final Set<String> RECORDTYPE_SET= new Set<String>{ADS_PROMO_TYPE, ACTIVATE_STORE_TYPE, ACTIVATIONS_CHECKLIST_TYPE};

    /**
     * @author: Krishna Sanisetty
     * @date: 09/07/2022
     * @decription: This method validate all the visiblity criteria for a Ads & Promos
     * list Lwc to be visible in UI for a given case
     * @param: Id case record Id
     * @return: Map<String, boolean> this boolean value will determine the visibility of the LWC component in UI.
     */
    @AuraEnabled(cacheable = true)
    public static Map<String, Boolean> validateComponentVisibility(Id caseId){
        Boolean isComponentVisible = false;
        Map<String, String> milestoneStatusMap = new Map<String, String>();
        try{
            List<Milestone__c> milestoneList = MilestonesSelector.newInstance().selectByCaseIdAndRecordTypeName(new Set<Id>{caseId}, RECORDTYPE_SET);
            for(Milestone__c milestone: milestoneList){
                milestoneStatusMap.put(milestone.recordtype.Name, milestone.status__c);
            }
            if(milestoneStatusMap.containsKey(ADS_PROMO_TYPE) &&
                ((milestoneStatusMap.containsKey(ACTIVATE_STORE_TYPE) &&
                milestoneStatusMap.get(ACTIVATE_STORE_TYPE) == MILESTONE_STATUS)
                || (!milestoneStatusMap.containsKey(ACTIVATE_STORE_TYPE) &&
                milestoneStatusMap.containsKey(ACTIVATIONS_CHECKLIST_TYPE) &&
                milestoneStatusMap.get(ACTIVATIONS_CHECKLIST_TYPE) == MILESTONE_STATUS))){
                    isComponentVisible = true;
            }
        } catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }

        return new Map<String, Boolean>{VALIDITY_MAP_KEY_NAME => isComponentVisible};
    }
    /**
     * @author: Krishna Sanisetty
     * @date: 09/07/2022
     * @decription: This method will retrieve all the OrderItems with its Product Name,
     * Promo Start Date and Promo End date fields, this list will be displayed thru LWC
     * in Marketplace onboarding record type case detail page in UI
     * @param: Id opportunity record Id
     * @return: List<OrderItem> Order Product records associated to an Opportunity and
     * whose product family is either Marketplace Promotion or Advertisement
     */
    @AuraEnabled
    public static List<OrderItem> getOrderItems(Id opportunityId){
        List<OrderItem> orderItems = new List<OrderItem>();
        try{
            orderItems = OrderItemsSelector.newInstance().selectByOrderIdAndProductFamily(new Set<Id>{opportunityId}, PRODUCT_FAMILY);
        } catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }
        return orderItems.isEmpty() ? orderItems : (List<OrderItem>) Security.stripInAccessible(AccessType.READABLE, orderItems).getRecords();
    }
}