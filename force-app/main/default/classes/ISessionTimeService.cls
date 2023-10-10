public interface ISessionTimeService {
    /**
     * @description Checks if user has access to Session Time Object, etc.
     * @return String - error message if access is not there
     */
    String checkAccess();

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
    Session_Time__c insertNewSession(Id caseId, Integer timeVal, String status, String omniStatus, String newCaseStatus, String newOmniStatus);

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
    Session_Time__c insertNewSessionManual(Id caseId, String timeVal, String theDate, String comments, String status, String omniStatus);

}