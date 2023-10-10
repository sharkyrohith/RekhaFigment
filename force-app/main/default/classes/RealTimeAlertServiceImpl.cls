/**
 * @author          Jeegar
 * @date            Aug 2023
 * @description     This is the service implementation class for Real Time Aelrts
 */
public inherited sharing class RealTimeAlertServiceImpl implements IRealTimeAlertService{
    public List<RealTimeAlertService.RealTimeAlert> getRealTimeAlertsForCase(String accountId) {
        /**
         * Change Count = 0
         * Increment change count if  last_n_hours changes.
         * Move to custom setting / metadata if it changes more than 2 times.
         */
        List<RealTimeAlertService.RealTimeAlert> realTimeAlerts = new List<RealTimeAlertService.RealTimeAlert>();
        if(String.isBlank(accountId)) {
            return realTimeAlerts;
        }
        List<Case> accountManagementCases = getRelatedAccountManagementCases( Id.valueOf(accountId));
        if(accountManagementCases.size() == 2) {
            realTimeAlerts.add(createRealTimeAlert(CDdCoreConstants.SEVERITY_LEVEL_WARNING,
                                                    RealTimeAlertsConstants.REAL_TIME_ALERT_REPEAT_CONTACT_TITLE,
                                                    RealTimeAlertsConstants.REAL_TIME_ALERT_REPEAT_CONTACT_MESSAGE));
        } else if(accountManagementCases.size() > 2) {
            realTimeAlerts.add(createRealTimeAlert(CDdCoreConstants.SEVERITY_LEVEL_ERROR,
                                                    RealTimeAlertsConstants.REAL_TIME_ALERT_REPEAT_CONTACT_TITLE,
                                                    RealTimeAlertsConstants.REAL_TIME_ALERT_REPEAT_CONTACT_MESSAGE));
        }
        return realTimeAlerts;
    }

    /**
     * @description     BIZS-3273 gets related Account Management Cases created in last N hours
     *                  for the given account Id
     * @param           Id AccountId
     * @param           Integer Last N hours
     * @return          List of cases fo type Account Management
     */
    private List<Case> getRelatedAccountManagementCases (Id accountId) {

        // initiate the case list so that you dont hit null pointer exception
        List<Case> relatedCases = new List<Case>();

        relatedCases = CasesSelector.newInstance().
            selectCasesByAccountIdAndIssueTypeLastnHours(accountId, RealTimeAlertsConstants.LAST_N_HOURS, getSupportRecordTypes(), getAccountManagementIssueTypes());

        return relatedCases;
    }
    /**
     * @description     Create an instance of real Real Time Alert
     * @param           String severity    Severity of the Alert
     * @param           String title       title to show on the alert
     * @param           String message     Message to be shown in the alert
     * @return          RealTimeAlertService.RealTimeAlert alert to be shown on the UI.
     */
    private RealTimeAlertService.RealTimeAlert createRealTimeAlert(String severity, String title, String message){
        return new RealTimeAlertService.RealTimeAlert(
                severity,
                title,
                message,
                FALSE);
    }

    /**
     * @description     returns all Account Management issue types
     * @return          Set<String>
     */
    @TestVisible
    private static Set<String> getAccountManagementIssueTypes() {
        Set<String> accountManagementIssueTypes = new Set<String>();
        accountManagementIssueTypes.add(CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT);
        accountManagementIssueTypes.add(CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_CX);
        accountManagementIssueTypes.add(CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_MX);
        accountManagementIssueTypes.add(CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_DX);

        return accountManagementIssueTypes;
    }

    /**
     * @description     get support recordtype Ids (Support, API)
     * @return          Set<Id>
     */
    @TestVisible
    private static Set<Id> getSupportRecordTypes() {
        Set<Id> recordTypeIds = new Set<Id>();
        recordTypeIds.add(CDdGenericTriggerOptimizationHelper.supportRecordTypeId);
        recordTypeIds.add(CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_API));
        return recordTypeIds;
    }
}