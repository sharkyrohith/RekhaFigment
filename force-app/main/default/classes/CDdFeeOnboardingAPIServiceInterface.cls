/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/18/2021
*
* @group Fee Onboarding API
*
* @description Fee Onboarding API Service Interface that exposes the following operation to post request to MFS
*   1. Add one or requests for the available Fee Onboarding API Types.
*   2. Send (post) the request to appropriate MFS Endpoint
*   Note : Fee Onboarding Api Type is used to route the request to the correct MFS API Service Endpoint
**************************************************************************************************************************************/
public interface  CDdFeeOnboardingAPIServiceInterface {
    /**
     * @description Add the fee onboarding request for the specific Fee Onboarding API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @param Object Fee Onboarding request object
     * @return 
     */
    void addRequest(CDdFeeOnboardingApiType feeOnboardingApiType, Object feeOnboardingRequest);
    /**
     * @description Generate and collect the fee onboarding requests
     * for each Fee Onboarding API Type, to post to MFS Service API
     * @param List<CDdFeeOnboardingProgramObject> Collection of program objects
     * @return 
     */ 
    void addRequests(List<CDdFeeOnboardingProgramObject> programObjects);
    /**
     * @description Does the service contain a request of the input Fee Onboarding API Type?
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @return Boolean
     */
    Boolean hasRequest(CDdFeeOnboardingApiType feeOnboardingApiType);
    /**
     * @description Does the service contain at least one request to send to MFS?
     * @param -
     * @return Boolean
     */
    Boolean hasRequests();
    /**
     * @description Return the fee onboarding request object for the input Fee Onboarding API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @return Object Return the fee onboarding request object
     */
    Object getRequest(CDdFeeOnboardingApiType feeOnboardingApiType);        
    /**
     * @description An operation that interacts with the external service for posting the fee onboarding request
     * Fee Onboarding request and endpoint are evaluated based on the input Fee API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @return CDdRestJSONObj.FeeOnboardingResponse Return the Fee Onboarding response information received from the external service
     */
    CDdRestJSONObj.FeeOnboardingResponse sendRequest(CDdFeeOnboardingApiType feeOnboardingApiType);             
}