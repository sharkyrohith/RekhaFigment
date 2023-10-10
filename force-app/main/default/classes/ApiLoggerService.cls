// Service Facade for ApiLoggerService
public inherited sharing class ApiLoggerService {
    /**
     * @description : Method to Log the API Log
     * @param productOrToolName - Api Logger is controller by the API Logger Gate custom setting... This field helps get fields from that custom setting.
     * @param callingCode - Which method or code is requesting this logger
     * @param relatedToId - Record this log is related To
     * @param relatedToOwnerID - Record OwnerId this log is related To
     * @param requestOrLog - Generic Log or API Request to log
     * @param response - API Response to log
     * @return None
    */
    public static void log(String productOrToolName,String callingCode,String relatedToId,String relatedToOwnerId,String requestOrLog,String response) {
        service().log(productOrToolName,callingCode,relatedToId,relatedToOwnerId,requestOrLog,response);
    }

    /**
     * @description : Method to Log the API Log
     * @param logEvents - List of API_Logger__e platform Events to Log
     * @return None
    */
    public static void log(List<API_Logger__e> logEvents) {
        service().log(logEvents);
    }

    /**
     * @description : Method to create an instance of the platform event sobject
     * @param productOrToolName - Api Logger is controller by the API Logger Gate custom setting... This field helps get fields from that custom setting.
     * @param callingCode - Which method or code is requesting this logger
     * @param relatedToId - Record this log is related To
     * @param relatedToOwnerID - Record OwnerId this log is related To
     * @param requestOrLog - Generic Log or API Request to log
     * @param response - API Response to log
     * @return API_Logger__e - Platform event sobject
    */
    public static API_Logger__e createApiLoggerEvent(String productOrToolName,String callingCode,String relatedToId,String relatedToOwnerId,String requestOrLog,String response) {
        return service().createApiLoggerEvent(productOrToolName,callingCode,relatedToId,relatedToOwnerId,requestOrLog,response);
    }

    /**
     * @description It creates instance of ApiLoggerServiceImpl class.
     * @return  - return instance of IMxpBobUpdateRequestService
     */
    private static IApiLoggerService service() {
        return (IApiLoggerService) Application.Service.newInstance(
            IApiLoggerService.class
        );
    }
}