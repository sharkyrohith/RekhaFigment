/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/15/2021
*
* @group Fee Onboarding API
*
* @description This API Service Class will send the fee onboarding request to DSJ API Service 
**************************************************************************************************************************************/
public class CDdFeeOnboardingDSJApiService extends CDdFeeOnboardingImplApiService {
    public static final String DSJ_ENDPOINT_SUFFIX_MX_PROGRAM_FEE = '/v1/stores/onboard_mx_affiliate_programs';
    public static final String DSJ_ENDPOINT_SUFFIX_CX_STOREFRONT_FEE = '/v1/salesforce/cx_fee_products';
    public static final Map<CDdFeeOnboardingApiType, String> DSJ_FEE_ONBOARDING_ENDPOINT_SUFFIX = new Map<CDdFeeOnboardingApiType, String>{
        CDdFeeOnboardingApiType.MX_PROGRAM_FEE => DSJ_ENDPOINT_SUFFIX_MX_PROGRAM_FEE,
        CDdFeeOnboardingApiType.MX_STOREFRONT_MONTHLY_FEE => DSJ_ENDPOINT_SUFFIX_MX_PROGRAM_FEE,
        CDdFeeOnboardingApiType.CX_STOREFRONT_FEE => DSJ_ENDPOINT_SUFFIX_CX_STOREFRONT_FEE
    };
    private CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
    /**
     * @description An operation that interacts with the external service for posting the fee onboarding request
     * Fee Onboarding request and endpoint are evaluated based on the input Fee API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @param Object Fee Onboarding Request Object
     * @return CDdRestJSONObj.FeeOnboardingResponse Return the Fee Onboarding response information received from the external service
     */
    public override CDdRestJSONObj.FeeOnboardingResponse sendRequest(CDdFeeOnboardingApiType feeOnboardingApiType, Object feeOnboardingRequest) {
        String feeOnboardingEndpointSuffix = DSJ_FEE_ONBOARDING_ENDPOINT_SUFFIX.get(feeOnboardingApiType);
        String requestStr = JSON.serialize(feeOnboardingRequest, true);
        requestStr = requestStr.replaceAll('000Z', '000');        
        System.debug('CDdFeeOnboardingDSJApiService: sendRequest, request: ' + requestStr);
        CDdRestJSONObj.RestAPIResponse response = connector.postDoorstep(requestStr, feeOnboardingEndpointSuffix);
        System.debug('CDdFeeOnboardingDSJApiService: sendRequest, response: ' + JSON.serialize(response, true));
        CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = null;
        try {
            feeOnboardingResponse = (CDdRestJSONObj.FeeOnboardingResponse) JSON.deserialize(response.body, CDdRestJSONObj.FeeOnboardingResponse.class);
        }catch(Exception e){
            feeOnboardingResponse = new CDdRestJSONObj.FeeOnboardingResponse();
        }
        feeOnboardingResponse.statusCode = response.statusCode;
        feeOnboardingResponse.request = requestStr;
        feeOnboardingResponse.response = JSON.serialize(response);
        switch on feeOnboardingResponse.statusCode {
            when 200 {
                if (feeOnboardingResponse.non_field_errors != null) {
                    throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_RESPONSE, feeOnboardingResponse.non_field_errors, feeOnboardingResponse.request, JSON.serialize(feeOnboardingResponse));
                }
            }            
            when 500 {
                CDdFeeOnboardingException.handleResponseCode500(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_RESPONSE, feeOnboardingResponse.request, response.body);
            }
            when else {
                throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_RESPONSE, feeOnboardingResponse.non_field_errors != null ? feeOnboardingResponse.non_field_errors : CDdFeeOnboardingException.ERROR_UNKNOWN, feeOnboardingResponse.request, response.body);
            }
        }
        return feeOnboardingResponse;
    }    
}