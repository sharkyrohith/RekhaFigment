/**
 * @author  Raju L
 * @date    August 2023
 * @description This is the service implementation class for Case Session Timer Functionality
 */
public inherited sharing class SessionTimeServiceImpl implements ISessionTimeService {
    /**
    * @description Checks if user has access to Session Time Object, etc.
    * @return String - error message if access is not there
    */
    public String checkAccess() {
        String accessMessage = null;

        // Check we can access the custom object
        Map<String,Schema.SObjectField> objMap = Schema.SObjectType.Session_Time__c.fields.getMap();
        String[] fieldsToCheck = new String[] {'Name','Case__c','Date__c','Duration__c','Agent__c','Case_Status__c','Manual_Entry__c','Comments__c','Omni_Status__c' };
        for(String field : fieldsToCheck) {
            if(!objMap.get(field).getDescribe().isAccessible() && !objMap.get(field).getDescribe().isCreateable() ) {
                accessMessage = 'Unable to access Session Time object field ' + field;
                break;
            }
        }

        // Check we can access some related objects
        if (accessMessage == null && !Schema.sObjectType.Case.fields.Id.isAccessible()){
			accessMessage = 'Unable to access Case objects Id field.';
        }

        if (accessMessage == null && !Schema.sObjectType.User.fields.Name.isAccessible() && !Schema.sObjectType.User.fields.Id.isAccessible()){
			accessMessage = 'Unable to access the User objects Name field.';
        }

        return accessMessage;
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
    public Session_Time__c insertNewSession(Id caseId, Integer timeVal, String status, String omniStatus, String newCaseStatus, String newOmniStatus) {
        // Time Calculations - convert milliseconds to seconds.
        Integer timeInSecs = timeVal/1000;
        return insertNewSessionHelper(caseId, timeInSecs, System.Date.today(), null, status, omniStatus, newCaseStatus, newOmniStatus, false);
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
    public Session_Time__c insertNewSessionManual(Id caseId, String timeVal, String theDate, String comments, String status, String omniStatus) {
        // Split out the time string into hours, minutes and seconds
        String[] t = timeVal.split(':');
        Integer h = Integer.valueof(t[0]);
        Integer m = Integer.valueof(t[1]);
        Integer s = Integer.valueof(t[2]);
        Integer fullTime = s + (m * 60) + (h * 3600);

        return insertNewSessionHelper(caseId, fullTime, Date.valueOf(theDate), comments, status, omniStatus, CDdCoreConstants.BLANK_STRING, CDdCoreConstants.BLANK_STRING,true);
    }

    /**
     * @description Creates a new Session Time Record
     * @param caseId <Id> - Id of parent case
     * @param duration <Integer> - time in seconds that the session was active
     * @param theDate <String> - Date of entry
     * @param comments <String> - Comments
     * @param status <String> - case status against which time has to be logged
     * @param omniStatus <String> - Omni status against which time has to be logged
     * @param newCaseStatus <String> - If the timer has to be created because the case status was changed, this field would have the new status set by the user. Helps for tracking user behavior.
     * @param newOmniStatus <String> - If the timer has to be created because the omni status was changed, this field would have the new omni status set by the user. Helps for tracking user behavior.
     * @param isManual <Boolean> - time logged was from manual logging feature
     * @return Session_Time__c - Created Session time record
     */
    private Session_Time__c insertNewSessionHelper(Id caseId, Integer duration, Date theDate, String comments, String status, String omniStatus, String newCaseStatus, String newOmniStatus, Boolean isManual) {
        if (duration == 0) {
            return null;
        }
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        SObject session = new Session_Time__c(
            Case__c  = caseId,
            Date__c = theDate,
            Duration__c = duration,
            Agent__c = UserINFO.getUserId(),
            Manual_Entry__c  = isManual,
            Comments__c = comments,
            Name = UserINFO.getName() + ' time of ' + duration + 's on ' + String.valueOf(theDate),
            Case_Status__c = status,
            Omni_Status__c = omniStatus,
            New_Case_Status__c = newCaseStatus,
            New_Omni_Status__c = newOmniStatus
        );
        uow.registerNew(session);
        uow.commitWork();
        return (Session_Time__c)session;
    }
}