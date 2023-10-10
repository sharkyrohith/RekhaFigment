/**
 * CDdSendBirdAPIHandler
 *
 * @author     Sahil
 * @date  2021-03-22
 * @decription  This class is the handler for SendBird API Callouts
 */
public with sharing class CDdSendBirdAPIHandler {
  /*****************************************************************************************************************************
   *
   * Constants & Private Variables
   *
   *****************************************************************************************************************************/
  public static Sendbird_Settings__c sendbirdSettings = Sendbird_Settings__c.getInstance();
  /*****************************************************************************************************************************
   *
   * Public/Global Variables
   *
   *****************************************************************************************************************************/
  public Integer retryAttempts;
  /*****************************************************************************************************************************
   *
   * Public Methods
   *
   *****************************************************************************************************************************/
  /**
   * @author     Sahil
   * @date  2020-03-22
   * @decription This method makes an API call to sendbird endpoint
   * @param   http method type,endpoint,request body
   * @return  response from API
   */
  public static String makeRequest(String method, String path, String body) {
    //check if API calls are enabled
    if (sendbirdSettings.Disable_SG_API__c) {
      throw new CDdSendBirdAPIHandlerException(CDdCoreConstants.HTTP_CALL_DISABLED);
    }
    //initializing retry attempts and getting max retries from custom setting
    Integer retryCount = 0;
    Integer maxRetries = sendbirdSettings.Callout_Retries__c.intValue();
    if (maxRetries == null) {
      //set default max retries to 1 so that there is at least 1 api call made
      maxRetries = 1;
    }
    CDdRestJSONObj.RestAPIResponse response;

    Boolean shouldLog = ApiLoggerServiceImplHelper.shouldLog('Sendbird') && path == CDdSupportConstants.SENDBIRD_ERS_ENDPOINT_PATH;
    fflib_ISObjectUnitOfWork uow = Application.UNITOFWORK.newInstance();
    CDdRestJSONObj.SendbirdRequest sendbirdRequest;
    Boolean hasLogs = false;
    if (shouldLog) {
      sendbirdRequest = (CDdRestJSONObj.SendbirdRequest)JSON.deserialize(body, CDdRestJSONObj.SendbirdRequest.class);
    }
    for(retryCount = 0; retryCount < maxRetries; retryCount ++) {
      CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
      try {
        response = connector.invokeRESTAPI(method, body, null, null, path, null,
                                            CDdSupportConstants.DD_API_TOKEN,
                                            CDdSupportConstants.CREDENTIAL_PASSWORD,
                                            CDdSupportConstants.SUPPORT_GATEWAY);
        if (shouldLog) {
          for (CDdRestJSONObj.SendbirdCaseUpdate req : sendbirdRequest.caseUpdates) {
            API_Logger__e apiLogEvent = ApiLoggerService.createApiLoggerEvent(
                'Sendbird','makeRequest',req.caseId,req.ownerId,
                'Retry Count: ' + retryCount + CDdCoreConstants.NEW_LINE + body,
                response == null ? CDdCoreConstants.BLANK_STRING : JSON.serialize(response));
            if (apiLogEvent != null) {
              uow.registerPublishBeforeTransaction(apiLogEvent);
              hasLogs = true;
            }
          }
        }
        //if the request doesn't succeed ie: not 200-299 then throw exception
        if (response != null && (response.statusCode < CDdCoreConstants.CODE_REQUEST_SUCCESS
                                  || response.statusCode > CDdCoreConstants.CODE_SUCCESS_END)) {
            throw new CDdSendBirdAPIHandlerException(CDdCoreConstants.HTTP_REQ_FAILED
                                                      + CDdCoreConstants.DELIMITER_COLON
                                                      + CDdCoreConstants.DELIMITER_SPACE
                                                      + response.statusCode);
        }
        break;//if respnse is between 200-299, no more retries and break out
      } catch (Exception e) {
        if (retryCount == maxRetries -1) {
          //max attempts reached - throwing an exception and logging in database
          CDdErrorUtilities.publishException('CDdSendBirdAPIHandler', 'makeRequest', null,
                                              Label.vMaxRetriesAttempted
                                              + CDdCoreConstants.DELIMITER_SPACE
                                              + e.getMessage()
                                              + CDdCoreConstants.DELIMITER_SPACE
                                              + e.getStackTraceString()
                                              + CDdCoreConstants.NEW_LINE
                                              + body);
          if (hasLogs) {
            commitWork(uow);
          }
          throw new CDdSendBirdAPIHandlerException(Label.vMaxRetriesAttempted
                                                    + CDdCoreConstants.DELIMITER_SPACE
                                                    + e.getMessage()
                                                    + CDdCoreConstants.DELIMITER_SPACE
                                                    + e.getStackTraceString());
        }
      }
    }
    if (hasLogs) {
      commitWork(uow);
    }
    //response between 200-299, return body
    if (response != null) {
      return response.body;
    }
    //default response
    return CDdCoreConstants.HTTP_NO_RESP;
  }

  private static void commitWork(fflib_ISObjectUnitOfWork uow) {
    try {
        uow.commitWork();
    } catch (Exception ex) {
        CDdErrorUtilities.publishException('CDdSendBirdAPIHandler', 'commitWork', ex);
    }
  }

  public class CDdSendBirdAPIHandlerException extends Exception {}
}