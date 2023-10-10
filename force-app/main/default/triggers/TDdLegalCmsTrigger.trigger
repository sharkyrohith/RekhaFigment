/**
 * @author: Raju
 * @date: June 2022
 * @description Trigger for Legal_CMS_Content__c object using the CDdMetadataTriggerHandler framework
 */
trigger TDdLegalCmsTrigger on Legal_CMS_Content__c (before insert,before update,after insert,after update,before delete,after delete) {
    new CDdMetadataTriggerHandler().run('Legal_CMS_Content__c');
}