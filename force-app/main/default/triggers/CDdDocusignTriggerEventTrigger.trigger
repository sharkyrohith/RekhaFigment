/**
 * @description       : 
 * @author            : Ganesh Dheekonda
 * @group             : 
 * @last modified on  : 08-04-2022
 * @last modified by  : Ganesh Dheekonda
**/
trigger CDdDocusignTriggerEventTrigger on Docusign_Trigger_Event__e (after insert) {
    
    CDdDocusignTriggerEventHandler.afterInsert(trigger.new);
}