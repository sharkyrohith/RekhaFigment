/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/05/2021
*
* @group Fee Onboarding API
*
* @description This is an abstract API Service Class that sends the fee onboarding request
**************************************************************************************************************************************/
public abstract class CDdFeeOnboardingImplApiService {
    /**
     * @description An operation that interacts with the external service for posting the fee onboarding request
     * Fee Onboarding request and endpoint are evaluated based on the input Fee API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @param Object Fee Onboarding Request Object
     * @return CDdRestJSONObj.FeeOnboardingResponse Return the Fee Onboarding response information received from the external service
     */
    public abstract CDdRestJSONObj.FeeOnboardingResponse sendRequest(CDdFeeOnboardingApiType feeOnboardingApiType, Object feeOnboardingRequest);
}