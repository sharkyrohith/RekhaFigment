/**
 * @author     Aaron Schacht & Nathalie Mendezona
 * @date       2/2023
 * @decription Helper Class to prevent user from creating an AAR record when the same user already has an active one
 *             https://doordash.atlassian.net/browse/BZAP-18836
 */

public class CDdAdminAccessRequestTriggerHelper {
    public static final String STATUS_ACTIVE = 'Active';
    
    public static void preventDuplicateRequests() {
        List<Admin_Access_Request__c> existingRecords = [SELECT Id FROM Admin_Access_Request__c WHERE CreatedById = :UserInfo.getUserId() AND Status__c =: STATUS_ACTIVE];
        if (existingRecords.size() > 0) {
            for (Admin_Access_Request__c record : (List <Admin_Access_Request__c>) trigger.new) {
                record.addError(Label.AdminAccessRequest_Duplicate_Error);
            }
        }
    }
}