/**
 * @description       : 
 * @author            : Dinesh Annapareddy
 * @group             : 
 * @last modified on  : 12-10-2021
 * @last modified by  : Dinesh Annapareddy
**/
trigger CDdTaskTriggerEventTrigger on TaskTriggerEvent__e (after insert) {
    System.debug('I am heare at EventHandler');
    CDdTaskTriggerEventHandler.afterInsert(trigger.new);
}