/********************************************************************************************************************
* @author ebby
* @date 12/08/2021
*
* @group Merchant Services
*
* @description Implements CDdMxSxSegmentConditionsHandler - will overirde a method to return the record ids which will satisfy the Segment Events
* 
**************************************************************************************************************************************/
public class CDdMxSxMilestoneHelper implements CDdMxSxSegmentConditionsHandler{
    //public Attributes - any custom attributes which are used across implementations can be defined here, in this case used in trigger
    public Set<Id> milestoneIds {get;set;}
    /**
     * @description prepares a collection of records based on the event Types for the trigger and batch processing
     * @param List<sObject> newList List of Milestone records 
     * @param Map<Id, sObject> oldMap Map of record Ids and Old values in case of trigger context
     * @param Set<Id> sObjectIds - List of record Ids passed in case of batch context 
     * @return Map<Id, sObject> collection of records which satisfies the condition of the events
    */
    public Map<Id, sObject> getSegmentEventIds(List<sObject> newList, Map<Id, sObject> oldMap, Set<Id> sObjectIds) {
        //Overiride the interface method and add the logic needed to get the records for which segment events should be published 
        milestoneIds = new Set<Id>();
        Map<Id, sObject> validSegmentEventIds = new Map<Id, sObject>();
        if(sObjectIds != null && !sObjectIds.isEmpty()){
            newList = [Select Id, RecordTypeId, RecordType.Name, Status__c, milestone_Type__c from Milestone__c where Id in: sObjectIds];
        }
        for (sObject newObj : newList){
            Milestone__c oldObj = (oldMap != null) ? (Milestone__c)oldMap.get(newObj.Id) : null;
            Milestone__c nObj = (Milestone__c)newObj;
            if (CDdMxSxTriggerHelper.hasFieldValueChanged(newObj, oldObj, CDdMxSxConstants.MILESTONE_STATUS_API_NAME) && CDdMxSxConstants.MILESTONE_STATUS_BLOCKED.equals(nObj.Status__c)){
                milestoneIds.add(nObj.Id);
                validSegmentEventIds.put(nObj.Id, newObj);
            }
        }
        return validSegmentEventIds ;
    } 
}