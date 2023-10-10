/**
* @author Mahesh Chouhan
* @description Trigger for Case Event PE
* @date June 2023
*/
trigger TDdCasePlatformEventTrigger on Case_Event__e (after insert) {
    CDdCaseEventTriggerHelper helper = new CDdCaseEventTriggerHelper(trigger.new);
    helper.handleEvents(trigger.new);
}