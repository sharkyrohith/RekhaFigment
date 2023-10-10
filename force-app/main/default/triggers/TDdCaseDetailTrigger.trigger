/**
 * @author: Nayana Kapse
 * @date: Feb 2022
 * @description Case Detail Trigger
 */
trigger TDdCaseDetailTrigger on Case_Detail__c (before insert, before update, after insert, after update) {
    new CDdCaseDetailTriggerHandler().run('Case_Detail__c');
}