/**
 * @author Jeremy S. Johnson
 * @date November 2020
 *
 * @description BZAP-9259
 */
trigger TDdMilestoneTrigger on Milestone__c (before insert, after insert, before update, after update) {
    CDdMilestone milestone = new CDdMilestone();

    if (Trigger.isBefore && Trigger.isInsert) {
        milestone.updateMileStoneStatuses(Trigger.new);
    }else if(Trigger.isAfter && Trigger.isInsert){
        milestone.updateParentStageAndStatus(Trigger.newMap, Trigger.oldMap);
    }else if (Trigger.isBefore && Trigger.isUpdate) {
        milestone.populateKPIs(Trigger.newMap, Trigger.oldMap);
        milestone.validateAdPromo(Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        milestone.updateParentStageAndStatus(Trigger.newMap, Trigger.oldMap);
        milestone.completeMilestoneWithAdPromo(Trigger.newMap, Trigger.oldMap);
        CDdMxSxTriggerHelper.processMilestones(Trigger.new, Trigger.oldMap);
    }
}