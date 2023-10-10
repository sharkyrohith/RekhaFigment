/********************************************************************************************************************
* @author Lathika
* @date 08/25/2022
*
* @group Merchant Services
*
* @description Trigger helper for object Mx_Onboarding__c
*
**************************************************************************************************************************************/
public class CDdMxOnBoardingTriggerHelper {
    public static boolean ranMxOnboardingUpdate = false;
     /**
     * @description Handle Mx Onboarding Updates
     * @param List<Mx_Onboarding__c> newList
     * @param Map<Id, Mx_Onboarding__c> oldMap
     * @return
     */
    public static void handleMxOnboardingUpdate(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap){
        if (ranMxOnboardingUpdate) {
            return;
        }
        Map<id, SObject> milestoneMap = new Map<id, SObject>();
        milestoneMap = new CDdMxOnBoardingMilestoneHelper(newList, oldMap).getsObjectsToUpdate(newList, oldMap);
        Map<id, SObject> opportunityMap = new Map<id, SObject>();
        opportunityMap = new CDdMxOnBoardingOpportunityHelper(newList, oldMap).getsObjectsToUpdate(newList, oldMap);
        Map<id, SObject> caseMap = new Map<id, SObject>();
        caseMap = new CDdMxOnBoardingCaseHelper().getsObjectsToUpdate(milestoneMap.Values());
        List<SObject> objectsToUpdate = new List<SObject>();
        objectsToUpdate.addAll(opportunityMap.values());
        objectsToUpdate.addAll(caseMap.Values());
        objectsToUpdate.addAll(milestoneMap.values());

        if (!objectsToUpdate.isEmpty()) {
            List<Database.SaveResult> sResults = Database.update(objectsToUpdate, false);
            CDdErrorUtilities.publishException('Mx_Onboarding__c', 'handleMxOnboardingUpdate', sResults);
            ranMxOnboardingUpdate = true;
            CDdMxOnboardingProcessor.processResultsInt(sResults, milestoneMap, opportunityMap,objectsToUpdate);
        }
    }
    
    /**
     * @description Handle SSMO status reasons
     * @param List<Mx_Onboarding__c> newList
     * @param Map<Id, Mx_Onboarding__c> oldMap
     * @return
     */  
    public static void handleSSMONewStatusReasons(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap){
        
        List<Mx_Onboarding__c> processList = new List<Mx_Onboarding__c>();
        for(Mx_Onboarding__c onboarding:newList){
            if(onboarding.Business_Verification_Status_Reason__c != null
                && onboarding.Business_Verification_Status_Reason__c != oldMap.get(onboarding.Id).Business_Verification_Status_Reason__c){
                
                processList.add(onboarding);                
            }
        }
        
        if(processList.isEmpty()){
            return ;
        }
        
        Set<String> statusWithStatusReasons = new Set<String>();
        
        for(Mx_Business_Verification_Status_Reason__c verStatusReason:[SELECT Id, Status__c, Status_Reason__c
                                                                        FROM Mx_Business_Verification_Status_Reason__c]){
            
            statusWithStatusReasons.add(verStatusReason.Status__c +'::'+ verStatusReason.Status_Reason__c);                                                              
        }
        
        List<Mx_Business_Verification_Status_Reason__c> statusReasonInsertList = new List<Mx_Business_Verification_Status_Reason__c>();
        for(Mx_Onboarding__c onboarding:processList){
            List<String> statusReasons = onboarding.Business_Verification_Status_Reason__c.split('; ');
            for(String reason:statusReasons){
                if(!statusWithStatusReasons.contains(onboarding.Business_Verification_Status__c+'::'+reason)){
                    statusReasonInsertList.add(new Mx_Business_Verification_Status_Reason__c(
                                                    Status__c = onboarding.Business_Verification_Status__c,
                                                    Status_Reason__c = reason
                                                ));
                }
            }
        }
        
        if(!statusReasonInsertList.isEmpty()){
            Database.insert(statusReasonInsertList,false);
        }
        
    }
 }