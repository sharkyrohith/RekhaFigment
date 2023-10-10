/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/17/2021
*
* @group Fee Onboarding Exception
*
* @description Custom Apex Exception for Fee Onboarding
**************************************************************************************************************************************/
public class CDdFeeOnboardingException extends Exception {
    public static final String STEP_FEE_ONBOARDING = 'Fee Onboarding';
    public static final String ERROR_TYPE_VALIDATION = 'Validation Error';
    public static final String ERROR_TYPE_RESPONSE = 'Response Error';
    public static final String ERROR_TYPE_RUNTIME_EXCEPTION = 'Runtime Exception';
    public static final String ERROR_UNKNOWN = 'Unknown exception occurred';    
    public static final String ERROR_INVALID_REQUEST = 'Invalid request';
    /**
     * @description Constructor - instantiate the exception with the following parameters
     * @param String the Step in execution
     * @param String the Error Type
     * @param String the Error Message
     */
    public CDdFeeOnboardingException(String step, String errorType, String errorMessage){
        setMessage(JSON.serialize(new CDdFeeOnboardingExceptionData(step, errorType, errorMessage), true));
    }
    /**
     * @description Constructor - instantiate the exception with the following parameters
     * @param String the Step in execution
     * @param String the Error Type
     * @param String the Error Message
     * @param String the Callout Request
     * @param String the Callout Response
     */
    public CDdFeeOnboardingException(String step, String errorType, String errorMessage, String calloutRequest, String calloutResponse){
        setMessage(JSON.serialize(new CDdFeeOnboardingExceptionData(step, errorType, errorMessage, calloutRequest, calloutResponse), true));
    }        
    /**
     * @description Inner class used for capturing the exception data
     **/
    public class CDdFeeOnboardingExceptionData {
        /**
          * @description What step did the error take place in?
          **/
        public String step;
        /**
          * @description The serialized callout request
          **/
        public String calloutRequest;
        /**
          * @description The serialized callout response
          **/
        public String calloutResponse;
        /**
          * @description What is the error type? Error types are 'Validation Error', 'Response Error', 'Runtime Exception'
          **/
        public String errorType;
        /**
          * @description The actual error message
          **/
        public String errorMessage;
        
        /**
          * @description Constructor - instantiate the exception with the following parameters
          * @param String the Step in execution
          * @param String the Error Type
          * @param String the Error Message
          **/
        public CDdFeeOnboardingExceptionData(String step, String errorType, String errorMessage){
            this(step, errorType, errorMessage, null, null);
        }
        /**
          * @description Constructor - instantiate the exception with the following parameters
          * @param String the Step in execution
          * @param String the Error Type
          * @param String the Error Message
          * @param String the Callout Request
          * @param String the Callout Response
          **/
        public CDdFeeOnboardingExceptionData(String step, String errorType, String errorMessage, String calloutRequest, String calloutResponse){
            this.step = step;
            this.errorType = errorType;
            this.errorMessage = errorMessage;
            this.calloutRequest = calloutRequest;
            this.calloutResponse = calloutResponse;
        }
    }
    /**
     * @description Handle response code 500 
     * @param String the Step in execution
     * @param String the Error Type
     * @param String the Callout Request
     * @param String the Callout Response
     */    
    public static void handleResponseCode500(String step, String errorType, String request, String responseBody){
        String errorMessage = '500 Internal Server Error. ';
        Integer index = responseBody.indexOf('reference id: ');
        if (index > -1){
            errorMessage += 'Reference Id: ' + responseBody.substring(index+14, index+14+32);
        }
        throw new CDdFeeOnboardingException(step, errorType, errorMessage, request, errorMessage);
    }
    /**
     * @description De-serialize and return the CDdFeeOnboardingExceptionData object
     * @param CDdFeeOnboardingException Fee Onboarding Exception
     * @return CDdFeeOnboardingExceptionData 
     */      
    public static CDdFeeOnboardingExceptionData getExceptionData(CDdFeeOnboardingException e){
        return (CDdFeeOnboardingExceptionData) JSON.deserialize(e.getMessage(), CDdFeeOnboardingExceptionData.class);
    }
    /**
     * @description Extract and return error message from CDdFeeOnboardingExceptionData object
     * @param CDdFeeOnboardingException Fee Onboarding Exception
     * @return String error message
     */     
    public static String getErrorMessage(CDdFeeOnboardingException e) {
        return getExceptionData(e).errorMessage;
    }
    /**
     * @description Extract and return callout request  from CDdFeeOnboardingExceptionData object
     * @param CDdFeeOnboardingException Fee Onboarding Exception
     * @return String callout request
     */     
    public static String getCalloutRequest(CDdFeeOnboardingException e) {
        return getExceptionData(e).calloutRequest;
    }
    /**
     * @description Extract and return callout response from CDdFeeOnboardingExceptionData object
     * @param CDdFeeOnboardingException Fee Onboarding Exception
     * @return String callout response
     */     
    public static String getCalloutResponse(CDdFeeOnboardingException e) {
        return getExceptionData(e).calloutResponse;
    }                
}