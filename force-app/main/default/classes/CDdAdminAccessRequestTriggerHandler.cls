/**
 * @author     Aaron Schacht & Nathalie Mendezona
 * @date       2/2023
 * @decription Handler Class to prevent user from creating an AAR record when the same user already has an active one
 *             https://doordash.atlassian.net/browse/BZAP-18836
 */

public class CDdAdminAccessRequestTriggerHandler {

    public void beforeInsert(List<Admin_Access_Request__c> newList) {
        CDdAdminAccessRequestTriggerHelper.preventDuplicateRequests();
    }

}