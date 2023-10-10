/**
 * @author     Aaron Schacht & Nathalie Mendezona
 * @date       2/2023
 * @decription Trigger to prevent user from creating an AAR record when the same user already has an active one
 *             https://doordash.atlassian.net/browse/BZAP-18836
 */

trigger TDdAdminAccessRequestTrigger on Admin_Access_Request__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    CDdAdminAccessRequestTriggerHandler handler = new CDdAdminAccessRequestTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
        }
    }
}