/********************************************************************************************************************
* @author Sriram
* @date 04/08/2022
*
* @group Merchant Services
*
* @description Handler for MxSx Events related to Mx Order
* 
**************************************************************************************************************************************/
public class CDdMxOrderMxSxEventHandler {
    /**
     * @description
     * 1. Retrieve Marketplace Onboarding Milestone records for input Milestone record Ids filtered by Record Types 'Review & Triage' AND 'Setup Store'
     * 2. Collect the associated Account Record Identifiers
     * 3. Utilize the Mx Order Processor for further processing
     * @param Set<Id> milestoneIds - collection of milestone record identifiers
     * @return
     */
    public static void handleMilestoneEvent(Set<Id> milestoneIds){
        Set<Id> accountIds = new Set<Id>();
        for (Milestone__c m : [SELECT Id, RecordTypeId, Case__r.AccountId
                            FROM Milestone__c
                            WHERE Id IN :milestoneIds
                            AND RecordTypeId IN :CDdMxSxConstants.MX_ORDER_APPLICABLE_MILESTONE_RECORD_TYPE_IDS
                            AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING]){
            accountIds.add(m.Case__r.AccountId);          
        }
        handleSendMxOrderToVendorEvent(CDdMxSxConstants.SOBJECT_TYPE_ACCOUNT, accountIds);
    }
    /**
     * @description Utilize the Mx Order Processor for further processing
     * @param String sObjectType - valid values are Case, Mx_Order__c
     * @param Set<Id> sObjectIds - collection of record identifiers
     * @return
     */
    public static void handleSendMxOrderToVendorEvent(String sObjectType, Set<Id> sObjectIds){
        new CDdMxOrderProcessor(sObjectType, sObjectIds).execute();        
    }   
}