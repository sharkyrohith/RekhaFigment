/********************************************************************************************************************
* @author ebby
* @date 12/08/2021
*
* @group Merchant Services
*
* @description SObject-agnostic class which has to be overwritten for validating the records fetched from segment logs to be reprocessed
* 
**************************************************************************************************************************************/
public Interface CDdMxSxSegmentConditionsHandler {
     /**
     * @description prepares a collection of records based on the event Types for the trigger and batch processing
     * @param List<sObject> newList List of Milestone records 
     * @param Map<Id, sObject> oldMap Map of record Ids and Old values in case of trigger context
     * @param Set<Id> sObjectIds - List of record Ids passed in case of batch context 
     * @return Map<Id, sObject> collection of records which satisfies the condition of the events
    */
     Map<Id, sObject> getSegmentEventIds(List<sObject> newList, Map<Id, sObject> oldMap, Set<Id> sObjectIds);
}