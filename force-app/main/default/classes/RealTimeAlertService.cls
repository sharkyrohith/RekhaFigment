// Service Facade for RealTimeAlert
public with sharing class RealTimeAlertService {
    /**
     * @description     get real time alerts for case
     * @param           String accountId    Id of the case's Account Id
     * @return          List<RealTimeAlertService.RealTimeAlert>
     */
    public static List<RealTimeAlertService.RealTimeAlert> getRealTimeAlertsForCase (String accountId) {
        return service().getRealTimeAlertsForCase(accountId);
    }

    /**
     * @description create an instance of RealTimeAlertServiceImp class
     * @return  -   return instance of IRealTimeAlertService
     */
    private static IRealTimeAlertService service() {
        return(IRealTimeAlertService) Application.Service.newInstance(
            IRealTimeAlertService.class
        );
    }
    // RealTime Alert
    public class RealTimeAlert {
        @AuraEnabled public String severity {get;set;}
        @AuraEnabled public String title {get;set;}
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public Boolean isDismissable {get;set;}
        public RealTimeAlert(String severity, String title, String message, Boolean isDismissable) {
            this.severity = severity;
            this.title = title;
            this.message = message;
            this.isDismissable = isDismissable;
        }
    }
}