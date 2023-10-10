/**
 * @author: Raju
 * @date: June 2022
 * @description Trigger for Legal_CMS_Content_Version__c object using the CDdMetadataTriggerHandler framework
 */
trigger TDdLegalCmsVersionTrigger on Legal_CMS_Content_Version__c (before insert,before update,after insert,after update,before delete,after delete) {
    new CDdMetadataTriggerHandler().run('Legal_CMS_Content_Version__c');
}