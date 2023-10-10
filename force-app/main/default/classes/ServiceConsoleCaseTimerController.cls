/**
 * @author Raju Lakshman
 * @date  Aug 2023
 * @decription BIZS-3216 - Controller for ServiceConsoleCaseTimer.
 *              Source: https://github.com/SalesforceLabs/CaseTimer/blob/master/force-app/main/default/classes/CaseTimeCount.cls
 *              Modified to comply with ffLib
 */

public with sharing class ServiceConsoleCaseTimerController {
    /**
     * @description Checks if user has access to Session Time Object, etc.
     * @return String - error message if access is not there
     */
    @AuraEnabled
    public static String checkAccess() {
        return SessionTimeService.checkAccess();
    }

    /**
     * @description Creates a new Session Time Record
     * @param caseId <Id> - Id of parent case
     * @param timeVal <Integer> - time in milliseconds that the session was active
     * @param status <String> - case status against which time has to be logged
     * @param omniStatus <String> - Omni status against which time has to be logged
     * @param newCaseStatus <String> - If the timer has to be created because the case status was changed, this field would have the new status set by the user. Helps for tracking user behavior.
     * @param newOmniStatus <String> - If the timer has to be created because the omni status was changed, this field would have the new omni status set by the user. Helps for tracking user behavior.
     * @return Session_Time__c - Created Session time record
     */
    @AuraEnabled
    public static Session_Time__c newSession(Id caseId, Integer timeVal, String status, String omniStatus, String newCaseStatus, String newOmniStatus) {
        return SessionTimeService.insertNewSession(caseId, timeVal, status, omniStatus, newCaseStatus, newOmniStatus);
    }

    /**
     * @description Called by the manual entry creation feature
     * @param caseId <Id> - Id of parent case
     * @param timeVal <Integer> - time in milliseconds that the session was active
     * @param theDate <String> - Date of entry
     * @param comments <String> - Comments
     * @param status <String> - case status against which time has to be logged
     * @param omniStatus <String> - Omni status against which time has to be logged
     * @return Session_Time__c - Created Session time record
     */
    @AuraEnabled
    public static Session_Time__c newSessionManual(Id caseId, String timeVal, String theDate, String comments, String status, String omniStatus) {
        return SessionTimeService.insertNewSessionManual(caseId, timeVal, theDate, comments, status, omniStatus);
    }

    /**
     * @description Get all the sessions related to this record
     * @param recordId <Id> - Id of parent case
     * @return List<Session_Time__c> - Session time records
     */
    @AuraEnabled(cacheable=true)
    public static Session_Time__c[] getSessions(Id recordId) {
        return SessionTimeSelector.newInstance().selectByCaseId(recordId);
    }

    /**
     * @description Get all total time for this case.
     * @param recordId <Id> - Id of parent case
     * @return Double - Total Time/Duration logged against this case
     */
    @AuraEnabled(cacheable=true)
    public static Double totalTime(Id recordId) {
        Aggregate[] aggResults = SessionTimeSelector.newInstance().getTotalTimeForCaseId(new Set<Id>{recordId});
        return aggResults.isEmpty() ? 0 : (aggResults[0].get('TotalDuration') != null ? (Double)aggResults[0].get('TotalDuration') : 0);
    }
}