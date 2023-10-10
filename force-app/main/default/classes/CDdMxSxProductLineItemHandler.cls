/********************************************************************************************************************
* @author Veera
* @date 07/22/2022
*
* @group Merchant Services
*
* @description class for Product Line items changes on Milestone updates
* 
**************************************************************************************************************************************/
public class CDdMxSxProductLineItemHandler {
   
    public static CDdSchemaUtils.MileStoneRT milestoneRT = new CDdSchemaUtils.MileStoneRT();

    /**
     * @description Handle events - Ads & Promo - Product Line Item Updates
     * @param Set<Id> milestoneIds
     * @return    
    */
    public static void handleMilestoneCompletedForProductLineItemUpdates(Set<Id> milestoneIds) {
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        for (Milestone__c m :getMilestonesByIds(milestoneIds)){ 
            caseIds.add(m.Case__c);  
            opportunityIds.add(m.Case__r.Opportunity_Name__c);
        }
        updateLineItemsOnStoreActivation(caseIds,opportunityIds);
    }    

    public static void updateLineItemsOnStoreActivation(Set<Id> caseIds, Set<Id> opportunityIds){
        CDdMxSxOpportunityHelper opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
        Map<Id,OrderItem> orderItemsToUpdate = new Map<Id,OrderItem>();
        
        Map<Id,Map<String,Milestone__c>> caseVsMileStonesByRecordtype =  getMilestonesByCaseIds(caseIds);

        for(Id caseId : caseVsMileStonesByRecordtype.keyset()){
            Map<String,Milestone__c> MileStonesByRecordType = caseVsMileStonesByRecordtype.get(caseId);
            Milestone__c milestone;
            if(MileStonesByRecordType.containsKey(milestoneRT.activateStoreId())){
                milestone = MileStonesByRecordType.get(milestoneRT.activateStoreId());
            }else {
                milestone =  MileStonesByRecordType.get(milestoneRT.activationsChecklistId());
            }

            if(milestone == null || milestone.Status__c != CDdMxSxConstants.MILESTONE_STATUS_COMPLETE || !MileStonesByRecordType.containsKey(milestoneRT.adsPromosId())){
                continue;
            }

            if(opportunityHelper.hasCPQProducts(milestone.Case__r.Opportunity_Name__c)){
                for(OrderItem orderItem : opportunityHelper.getCPQProducts(milestone.Case__r.Opportunity_Name__c)){
                    if (CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS.contains(orderItem.Product2.Family)
                        && orderItem.Delay_after_Activation_days__c != null
                        && orderItem.Length_of_Term__c != null){
                            orderItem.Promo_Start_Day__c = Date.today().addDays(Integer.valueOf(orderItem.Delay_after_Activation_days__c));
                            orderItem.Promo_Start_Day__c = Date.valueOf(BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id,orderItem.Promo_Start_Day__c));
                            if(orderItem.Length_of_Term__c.isNumeric()){
                                orderItem.Promo_End_Day__c = orderItem.Promo_Start_Day__c.addDays(Integer.valueOf(orderItem.Length_of_Term__c));
                            }
                            orderItemsToUpdate.put(orderItem.Id,orderItem);
                    }
                }
            }
        }

        if(!orderItemsToUpdate.isEmpty()){
            update orderItemsToUpdate.values();
        }
    }
    
    private static Map<Id,Map<String,Milestone__c>> getMilestonesByCaseIds(Set<Id> caseIds){
        Set<String> recordTypeIds = new Set<String>{milestoneRT.activateStoreId(), milestoneRT.activationsChecklistId(), milestoneRT.adsPromosId()};

        Map<Id,Map<String,Milestone__c>> caseVsMileStonesByRecordtype = new Map<Id,Map<String,Milestone__c>>();
        for(Milestone__c milestone : [  SELECT Id, Status__c, RecordTypeId, Case__c, Case__r.Opportunity_Name__c FROM Milestone__c
                                        WHERE RecordTypeId IN :recordTypeIds AND Case__c IN :caseIds]){
            if (!caseVsMileStonesByRecordtype.containsKey(milestone.Case__c)) {
                caseVsMileStonesByRecordtype.put(milestone.Case__c, new Map<String,Milestone__c>());
            }
            Map<String,Milestone__c> milestoneRecordtypeVsMilestone = caseVsMileStonesByRecordtype.get(milestone.Case__c);
            milestoneRecordtypeVsMilestone.put(milestone.RecordTypeId, milestone);
            caseVsMileStonesByRecordtype.put(milestone.Case__c, milestoneRecordtypeVsMilestone);                            
        }
        return caseVsMileStonesByRecordtype;
    }

    private static List<Milestone__c> getMilestonesByIds(Set<Id> milestoneIds){
        return [SELECT Id, RecordTypeId,Status__c, Case__c, Case__r.AccountId, Case__r.Opportunity_Name__c
        FROM Milestone__c
        WHERE Id IN :milestoneIds
        AND (RecordTypeId = :milestoneRT.activateStoreId() OR RecordTypeId = :milestoneRT.activationsChecklistId())
        AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING];
    }
}