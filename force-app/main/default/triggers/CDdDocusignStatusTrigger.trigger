/**
 * CDdDocusignStatusTrigger
 *
 * @author     Ganesh Dheekonda
 * @date  3/8/2022
 * @decription Trigger on Docusign status object.
 */
trigger CDdDocusignStatusTrigger on dsfs__DocuSign_Status__c (after insert, after update) {
    if (! CDdRecursionUtils.isRunnable('CDdDocusignStatusTrigger')) return;
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            CDdDocusignStatusTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            CDdDocusignStatusTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}