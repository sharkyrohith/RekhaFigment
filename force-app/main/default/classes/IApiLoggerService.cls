public interface IApiLoggerService {
    void log(String productOrToolName,String callingCode,String relatedToId,String relatedToOwnerId,String requestOrLog,String response);
    void log(List<API_Logger__e> logEvents);
    API_Logger__e createApiLoggerEvent(String productOrToolName,String callingCode,String relatedToId,String relatedToOwnerId,String requestOrLog,String response);
}