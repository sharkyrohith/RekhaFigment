public interface IRealTimeAlertService {
    /**
     * @description Gets All Active Notification for the Case
     * @param String accountId - Id of the account for which alerts need to be fetched
     * @return List<RealTimeAlertService.RealTimeAlert>
     */
    List<RealTimeAlertService.RealTimeAlert> getRealTimeAlertsForCase(String accountId);

}