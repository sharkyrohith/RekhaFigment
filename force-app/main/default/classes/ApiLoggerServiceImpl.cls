/**
 * @author  Raju L
 * @date    December 2022
 * @description This is the service implementation class for the API Logger Tool which helps conditionally log data into the API_Log__c object
 */
public inherited sharing class ApiLoggerServiceImpl implements IApiLoggerService {
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
    public void log(String productOrToolName,String callingCode,String relatedToId,String relatedToOwnerId,String requestOrLog,String response) {
        if (!ApiLoggerServiceImplHelper.shouldLog(productOrToolName,relatedToId,relatedToOwnerId)) {
            return;
        }
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        SObject apiLog = new Api_Log__c(
            Calling_Code__c = callingCode,
            Related_To_Id__c = relatedToId,
            Related_To_Owner_Id__c = relatedToOwnerId,
            Request__c = String.isNotBlank(requestOrLog) ? requestOrLog.left(CDdCoreConstants.TEXTAREA_SIZE_DEFAULT) : null,
            Response__c = String.isNotBlank(response) ? response.left(CDdCoreConstants.TEXTAREA_SIZE_DEFAULT) : null
        );
        uow.registerNew(apiLog);
        try {
            uow.commitWork();
        } catch (Exception e) {
            //String errorMsg = CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e);
        }
    }

    /**
     * @description : Method to Log the API Log
     * @param logEvents - List of API_Logger__e platform Events to Log
     * @return None
    */
    public void log(List<API_Logger__e> logEvents) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        for (API_Logger__e logEvent : logEvents) {
            if (!ApiLoggerServiceImplHelper.shouldLog(logEvent.Product_Or_Tool_Name__c,logEvent.Related_To_Id__c,logEvent.Related_To_Owner_Id__c)) {
                continue;
            }
            SObject apiLog = new Api_Log__c(
                Calling_Code__c = logEvent.Calling_Code__c,
                Related_To_Id__c = logEvent.Related_To_Id__c,
                Related_To_Owner_Id__c = logEvent.Related_To_Owner_Id__c,
                Request__c = logEvent.Request__c,
                Response__c = logEvent.Response__c
            );
            uow.registerNew(apiLog);
        }
        try {
            uow.commitWork();
        } catch (Exception e) {
            //String errorMsg = CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e);
        }
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
    public API_Logger__e createApiLoggerEvent(String productOrToolName,String callingCode,String relatedToId,String relatedToOwnerId,String requestOrLog,String response) {
        if (!ApiLoggerServiceImplHelper.shouldLog(productOrToolName,relatedToId,relatedToOwnerId)) {
            return null;
        }
        return new API_Logger__e(
            Product_Or_Tool_Name__c = productOrToolName,
            Calling_Code__c = callingCode,
            Related_To_Id__c = relatedToId,
            Related_To_Owner_Id__c = relatedToOwnerId,
            Request__c = requestOrLog,
            Response__c = response
        );
    }
}