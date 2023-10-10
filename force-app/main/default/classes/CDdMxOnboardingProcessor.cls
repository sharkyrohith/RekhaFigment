/********************************************************************************************************************
* @author Lathika
* @date
*
* @group Merchant Services
*
* @description: class to handle MX_ONBOARDING_UPDATE_INBOUND events using 'Mx Support Event' service and Platform events
*
**************************************************************************************************************************************/
public class CDdMxOnboardingProcessor {
    /**
    * Define class variables here
    */
   public List<Mx_Onboarding__c> mxOnboardingList;
   public List<SObject> objectsToUpdate = new List<SObject>();
   public Set<ID> sObjectIds = new Set<ID>();
   public static String UPDATE_TYPE = CDdMxSxConstants.MX_ONBOARDING_MX_PORTAL_UPDATE_TYPE_INBOUND;
   public static String FILTERED_SOBJECT_IDS = 'sObjectIds';
   public CDdMxOnboardingProcessor(Set<Id> sObjectIds) {
        this.sObjectIds = sObjectIds;
   }

   /**
    *  execute method is called from MxSx Platformevent event (MX_ONBOARDING_UPDATE_INBOUND_EVENT) &&
    *  CDdMxOnboardingMxPortalUpdate (Support Job Batch Implementation)
    */
   public void execute(){
        // Query the mxOnboarding records
        String querywithIdsFilter = CDdMxOnboardingProcessorQueryBuilder.getDbQueryFilteredBySObjectIds();
        this.mxOnboardingList = Database.query(querywithIdsFilter);

        Map<id, SObject> milestoneMap = new Map<id, SObject>();
        milestoneMap = new CDdMxOnBoardingMilestoneHelper(mxOnboardingList).getsObjectsToUpdate(mxOnboardingList);
        Map<id, SObject> opportunityMap = new Map<id, SObject>();
        opportunityMap = new CDdMxOnBoardingOpportunityHelper(mxOnboardingList).getsObjectsToUpdate(mxOnboardingList);
        Map<id, SObject> caseMap = new Map<id, SObject>();
        caseMap = new CDdMxOnBoardingCaseHelper().getsObjectsToUpdate(milestoneMap.Values());

        objectsToUpdate.addAll(opportunityMap.values());
        objectsToUpdate.addAll(caseMap.Values());        
        objectsToUpdate.addAll(milestoneMap.values());
        
        List<Database.SaveResult> sResults;
        if (!objectsToUpdate.isEmpty()) {
           sResults = Database.update(objectsToUpdate, false);
           CDdErrorUtilities.publishException('Mx_Onboarding__c', 'handleMxOnboardingUpdate', sResults);
           // processing the results
           processResultsInt(sResults, milestoneMap, opportunityMap,objectsToUpdate);
        }
   }
   /**
     * @description processing the SObject Updates (UpdateType = null if the record is processed successfully)
     * @param List<Database.SaveResult> sResults
     * @param Map<id, SObject> milestoneMap
     * @param Map<id, SObject> opportunityMap
     * @param List<SObject> objectsToUpdate
     * @return void
     */
   public static void processResultsInt(List<Database.SaveResult> sResults, Map<id, SObject> milestoneMap, Map<id, SObject> opportunityMap, List<SObject> objectsToUpdate){
       //Set<Id> mxOnboardingIDFailed = new Set<Id>();
       Set<Id> mxOnboardingIDProcessed =  new Set<Id>();
       mxOnboardingIDProcessed.addAll(milestoneMap.keySet());
       mxOnboardingIDProcessed.addAll(opportunityMap.keySet());
       for (Integer i = 0; i < objectsToUpdate.size(); i++) {
           Database.SaveResult s = sResults[i];
           SObject origRecord = objectsToUpdate[i];
           if (!s.isSuccess()) {
                       for(ID mxOnId : milestoneMap.keySet()){
                               mxOnboardingIDProcessed.remove(mxOnId) ;
                               if(origRecord.Id == milestoneMap.get(mxOnId).id  && mxOnboardingIDProcessed.contains(mxOnId) ){
                               mxOnboardingIDProcessed.remove(mxOnId) ;
                           }
                       }
                       for(ID mxOnOppId : opportunityMap.keySet()){
                           if(origRecord.Id == opportunityMap.get(mxOnOppId).id && mxOnboardingIDProcessed.contains(mxOnOppId) ){
                            mxOnboardingIDProcessed.remove(mxOnOppId) ;
                           }
                       }
                   }
       }
      List<mx_onboarding__c> mxOnboardingListToUpdate = new List<mx_onboarding__c>();
      if (mxOnboardingIDProcessed.size()>0) {
        for (mx_onboarding__c mxOnb : [Select id, UpdateType__c from mx_onboarding__c where id IN:mxOnboardingIDProcessed]) {
            mxOnb.UpdateType__c = '';
            mxOnboardingListToUpdate.add(mxOnb);
        }
      }

       if (!mxOnboardingListToUpdate.isEmpty()) {
            List<Database.SaveResult> sResultsToProcess =  Database.update(mxOnboardingListToUpdate, false);
            CDdErrorUtilities.publishException('Mx_Onboarding__c', 'handleMxOnboardingUpdate processResultsInt', sResultsToProcess);
       }

   }
}