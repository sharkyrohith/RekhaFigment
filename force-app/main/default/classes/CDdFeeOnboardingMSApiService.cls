/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/02/2021
*
* @group Fee Onboarding API
*
* @description This API Service Class will send the fee onboarding request to MuleSoft gRPC API Service 
**************************************************************************************************************************************/
public class CDdFeeOnboardingMSApiService extends CDdFeeOnboardingImplApiService {
    private static final String DD_USER = CDdNimdaSyncMSService.getDDUser();
    private static final String ANY_AUDIENCE = 'any_audience';
    private static final String ANY_FULFILLMENT_TYPE  = 'any_fulfillment_type';
    private static final String FULFILLMENT_TYPE_CONSUMER_PICK_UP  = 'consumer_pick_up';
    private static final String FULFILLMENT_TYPE_PICKUP  = 'pickup';
    private static final String PROGRAM_TYPE_STOREFRONT_SUBSCRIPTION_PROGRAM = 'Storefront_Subscription_Program';
    private static final String FEE_NAME_STOREFRONT_SUBSCRIPTION_FEE = 'storefront_subscription_fee';
    private static final String SCHEDULE_NAME_MONTHLY = 'monthly';
    private static final String CREATE_METHOD_TYPE_NIMDA = 'NIMDA';
    private static final Map<CDdFeeOnboardingApiType, String> SUPPORTED_MS_OPERATION_FOR_API_TYPE 
        = new Map<CDdFeeOnboardingApiType, String>{
            CDdFeeOnboardingApiType.MX_PROGRAM_FEE => CDdNimdaSyncConstants.STEP_CREATE_MERCHANT_PROGRAM,
            CDdFeeOnboardingApiType.MX_STOREFRONT_MONTHLY_FEE => CDdNimdaSyncConstants.STEP_CREATE_MERCHANT_RECURRING_PROGRAM,
            CDdFeeOnboardingApiType.CX_STOREFRONT_FEE => CDdNimdaSyncConstants.STEP_CREATE_OPPORTUNITY_PRODUCTS
    };
    public static final Boolean ENABLE_CX_STOREFRONT_SERVICE_RATE_X_100 = CDdExperimentSvc.getFeatureFlag('Enable_Cx_Storefront_Service_Rate_x_100__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Enable_Cx_Storefront_Service_Rate_x_100__c');
    /**
     * @description An operation that interacts with the external service for posting the fee onboarding request
     * Fee Onboarding request and endpoint are evaluated based on the input Fee API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @param Object Fee Onboarding Request Object
     * @return CDdRestJSONObj.FeeOnboardingResponse Return the Fee Onboarding response information received from the external service
     */
    public override CDdRestJSONObj.FeeOnboardingResponse sendRequest(CDdFeeOnboardingApiType feeOnboardingApiType, Object feeOnboardingRequest) {
        CDdNimdaSyncMSService msService = new CDdNimdaSyncMSService();
        String operation = SUPPORTED_MS_OPERATION_FOR_API_TYPE.get(feeOnboardingApiType);
        String requestStr = JSON.serialize(getFeeOnboardingRequest(feeOnboardingApiType, feeOnboardingRequest), true);
        CDdRestJSONObj.RestAPIResponse response = msService.sendRequest(operation, requestStr);
        return getFeeOnboardingResponse(requestStr, response);          
    }
    /**
     * @description Return the fee onboarding request (MuleSoft version) for the input fee onboarding api type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @param Object Fee Onboarding Request Object
     * @return Object Return the Fee Onboarding request (MuleSoft version)
     */
    public Object getFeeOnboardingRequest(CDdFeeOnboardingApiType feeOnboardingApiType, Object feeOnboardingRequest){
        switch on feeOnboardingApiType {
            when MX_PROGRAM_FEE {
                return getMxFeeOnboardingRequestMS((CDdRestJSONObj.MxFeeOnboardingRequest)feeOnboardingRequest);
            }
            when MX_STOREFRONT_MONTHLY_FEE {
                return getMxMonthlyFeeOnboardingRequestMS((CDdRestJSONObj.MxFeeOnboardingRequest)feeOnboardingRequest);
            }
            when CX_STOREFRONT_FEE {
                return getCxFeeOnboardingRequestMS((CDdRestJSONObj.CxFeeOnboardingRequest)feeOnboardingRequest);
            }
            when else { return null; }
        }
    }
    /**
     * @description Return the fee onboarding response 
     * @param CDdRestJSONObj.RestAPIResponse Fee Onboarding response from callout request
     * @return CDdRestJSONObj.FeeOnboardingResponse Return the Fee Onboarding response
     */    
    public CDdRestJSONObj.FeeOnboardingResponse getFeeOnboardingResponse(String requestStr, CDdRestJSONObj.RestAPIResponse response){
        CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = null;
        try {
            feeOnboardingResponse = getFeeOnboardingResponse((CDdRestJSONObj.FeeOnboardingResponse_MS) JSON.deserialize(response.body, CDdRestJSONObj.FeeOnboardingResponse_MS.class));
        }catch(Exception e){
            feeOnboardingResponse = new CDdRestJSONObj.FeeOnboardingResponse();
        }
        feeOnboardingResponse.statusCode = response.statusCode;
        feeOnboardingResponse.request = requestStr;
        feeOnboardingResponse.response = JSON.serialize(response);
        switch on feeOnboardingResponse.statusCode {
            when 200 {
                if (feeOnboardingResponse.errorMessage != null) {
                    throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_RESPONSE, feeOnboardingResponse.errorMessage, feeOnboardingResponse.request, JSON.serialize(feeOnboardingResponse));
                }
            }            
            when else {
                throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_RESPONSE, feeOnboardingResponse.errorMessage != null ? feeOnboardingResponse.errorMessage : CDdFeeOnboardingException.ERROR_UNKNOWN, feeOnboardingResponse.request, response.body);
            }
        }
        return feeOnboardingResponse;
    }
    /**
     * @description Convert CDdRestJSONObj.MxFeeOnboardingRequest to CDdRestJSONObj.MxFeeOnboardingRequest_MS
     */
    public CDdRestJSONObj.MxFeeOnboardingRequest_MS getMxFeeOnboardingRequestMS(CDdRestJSONObj.MxFeeOnboardingRequest mxProgramFeeRequest){
        CDdRestJSONObj.MxFeeOnboardingRequest_MS mxProgramFeeRequest_MS = new CDdRestJSONObj.MxFeeOnboardingRequest_MS();
        List<CDdRestJSONObj.MxAffiliateProgram_MS> programs_ms = new List<CDdRestJSONObj.MxAffiliateProgram_MS>();
        for (CDdRestJSONObj.MxAffiliateProgram program : mxProgramFeeRequest.programs){
            CDdRestJSONObj.MxAffiliateProgram_MS program_ms = new CDdRestJSONObj.MxAffiliateProgram_MS();
            program_ms.store_id = String.valueOf(program.store_id);
            program_ms.audience = String.isNotBlank(program.audience) ? program.audience : ANY_AUDIENCE;
            program_ms.channel = program.channel;
            program_ms.experience = program.experience;
            program_ms.fulfillment_type = String.isNotBlank(program.fulfillment_type) 
                                            ? (FULFILLMENT_TYPE_CONSUMER_PICK_UP.equals(program.fulfillment_type) ? FULFILLMENT_TYPE_PICKUP : program.fulfillment_type)
                                            : ANY_FULFILLMENT_TYPE;
            program_ms.start_time = program.start_time;
            program_ms.end_time = program.end_time;
            program_ms.salesforce_opportunity_id = program.salesforce_opportunity_id;
            program_ms.fee_attributes = new List<CDdRestJSONObj.MxAffiliateFeeAttribute_MS>();
            for (CDdRestJSONObj.MxAffiliateFeeAttribute feeAttr : program.fee_attributes){
                CDdRestJSONObj.MxAffiliateFeeAttribute_MS feeAttr_ms = new CDdRestJSONObj.MxAffiliateFeeAttribute_MS();
                feeAttr_ms.name = feeAttr.name;
                feeAttr_ms.friendly_display_name = feeAttr.friendly_display_name;
                feeAttr_ms.fee_type = feeAttr.fee_type;
                feeAttr_ms.flat_fee_in_cents = feeAttr.flat_fee_in_cents!=null ? String.valueOf(feeAttr.flat_fee_in_cents) : null;
                feeAttr_ms.fee_rate = feeAttr.fee_rate;
                feeAttr_ms.fee_rate_charging_target = feeAttr.fee_rate_charging_target;
                feeAttr_ms.min_amount_in_cents = feeAttr.min_amount_in_cents;
                feeAttr_ms.max_amount_in_cents = feeAttr.max_amount_in_cents;
                feeAttr_ms.start_time = feeAttr.start_time;
                feeAttr_ms.end_time = feeAttr.end_time;
                program_ms.fee_attributes.add(feeAttr_ms);
            }
            programs_ms.add(program_ms);
        }
        mxProgramFeeRequest_MS.programs = programs_ms;
        mxProgramFeeRequest_MS.creator_user_id = DD_USER;
        return mxProgramFeeRequest_MS;
    }
    /**
     * @description Convert CDdRestJSONObj.MxFeeOnboardingRequest to CDdRestJSONObj.MxFeeOnboardingRequest_MS
     */
    public CDdRestJSONObj.MxFeeOnboardingRequest_MS getMxMonthlyFeeOnboardingRequestMS(CDdRestJSONObj.MxFeeOnboardingRequest mxProgramFeeRequest){
        CDdRestJSONObj.MxFeeOnboardingRequest_MS mxProgramFeeRequest_MS = new CDdRestJSONObj.MxFeeOnboardingRequest_MS();
        List<CDdRestJSONObj.MxAffiliateProgram_MS> programs_ms = new List<CDdRestJSONObj.MxAffiliateProgram_MS>();
        for (CDdRestJSONObj.MxAffiliateProgram program : mxProgramFeeRequest.programs){
            CDdRestJSONObj.MxAffiliateProgram_MS program_ms = new CDdRestJSONObj.MxAffiliateProgram_MS();
            program_ms.store_id = String.valueOf(program.store_id);
            program_ms.program_type = PROGRAM_TYPE_STOREFRONT_SUBSCRIPTION_PROGRAM;
            CDdRestJSONObj.MxAffiliateSchedule_MS schedule_ms = new CDdRestJSONObj.MxAffiliateSchedule_MS();
            schedule_ms.name = SCHEDULE_NAME_MONTHLY.toUpperCase();
            schedule_ms.frequency = SCHEDULE_NAME_MONTHLY;
            schedule_ms.effective_start_date = program.start_time;
            schedule_ms.effective_end_date = program.end_time;
            schedule_ms.create_method_type = CREATE_METHOD_TYPE_NIMDA;
            program_ms.schedule = schedule_ms;
            program_ms.salesforce_opportunity_id = program.salesforce_opportunity_id;
            program_ms.fee_attributes = new List<CDdRestJSONObj.MxAffiliateFeeAttribute_MS>();
            for (CDdRestJSONObj.MxAffiliateFeeAttribute feeAttr : program.fee_attributes){
                CDdRestJSONObj.MxAffiliateFeeAttribute_MS feeAttr_ms = new CDdRestJSONObj.MxAffiliateFeeAttribute_MS();
                feeAttr_ms.name = FEE_NAME_STOREFRONT_SUBSCRIPTION_FEE.toUpperCase();
                feeAttr_ms.friendly_display_name = FEE_NAME_STOREFRONT_SUBSCRIPTION_FEE;
                feeAttr_ms.fee_type = FEE_NAME_STOREFRONT_SUBSCRIPTION_FEE.toUpperCase();
                feeAttr_ms.flat_fee_in_minor_units = feeAttr.flat_fee_in_cents!=null ? String.valueOf(feeAttr.flat_fee_in_cents) : null;
                program_ms.fee_attributes.add(feeAttr_ms);
            }
            programs_ms.add(program_ms);
        }
        mxProgramFeeRequest_MS.programs = programs_ms;
        mxProgramFeeRequest_MS.creator_user_id = DD_USER;
        return mxProgramFeeRequest_MS;
    }    
    /**
     * @description Convert CDdRestJSONObj.CxFeeOnboardingRequest to CDdRestJSONObj.CxFeeOnboardingRequest_MS
     */         
    public CDdRestJSONObj.CxFeeOnboardingRequest_MS getCxFeeOnboardingRequestMS(CDdRestJSONObj.CxFeeOnboardingRequest cxStoreFrontFeeRequest){
        CDdRestJSONObj.CxFeeOnboardingRequest_MS cxStoreFrontFeeRequest_MS = new CDdRestJSONObj.CxFeeOnboardingRequest_MS();
        cxStoreFrontFeeRequest_MS.store_id = String.valueOf(cxStoreFrontFeeRequest.store_id);
        List<CDdRestJSONObj.Product_MS> products_ms = new List<CDdRestJSONObj.Product_MS>();
        for (CDdRestJSONObj.Product product : cxStoreFrontFeeRequest.products){
            CDdRestJSONObj.Product_MS product_ms = new CDdRestJSONObj.Product_MS();
            product_ms.created_at = product.created_at;
            product_ms.end_time = product.end_time;
            product_ms.start_time = product.start_time;
            product_ms.delivery_fee = product.delivery_fee!=null ? String.valueOf(product.delivery_fee) : null;
            product_ms.service_rate = product.service_rate!=null ? String.valueOf(ENABLE_CX_STOREFRONT_SERVICE_RATE_X_100 ? (product.service_rate * 100).intValue() : product.service_rate.intValue()) : null;
            product_ms.min_order_fee = product.min_order_fee;
            product_ms.min_order_subtotal = product.min_order_subtotal;
            product_ms.audience = product.audience;
            product_ms.channel = product.channel;
            product_ms.experience = product.experience;
            product_ms.fulfillment_type = product.fulfillment_type;
            product_ms.opportunity_id = product.opportunity_id;
            product_ms.opportunity_line_item_id = product.opportunity_line_item_id;
            products_ms.add(product_ms);
        }
        cxStoreFrontFeeRequest_MS.opportunity_products = products_ms;
        cxStoreFrontFeeRequest_MS.creator_user_id = DD_USER;
        return cxStoreFrontFeeRequest_MS;
    }
    /**
     * @description Convert CDdRestJSONObj.FeeOnboardingResponse_MS to CDdRestJSONObj.FeeOnboardingResponse
     */     
    public CDdRestJSONObj.FeeOnboardingResponse getFeeOnboardingResponse(CDdRestJSONObj.FeeOnboardingResponse_MS feeOnboardingResponse_ms){
        CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = new CDdRestJSONObj.FeeOnboardingResponse();
        feeOnboardingResponse.errorMessage = feeOnboardingResponse_ms.errorMessage;
        if (feeOnboardingResponse_ms.createdPrograms!=null && !feeOnboardingResponse_ms.createdPrograms.isEmpty()){
            feeOnboardingResponse.created_programs = new List<CDdRestJSONObj.MxAffiliateProgramResponse>();
            for (CDdRestJSONObj.MxAffiliateProgramResponse_MS programResponse_ms : feeOnboardingResponse_ms.createdPrograms){
                CDdRestJSONObj.MxAffiliateProgramResponse programResponse = new CDdRestJSONObj.MxAffiliateProgramResponse();
                programResponse.program_id = programResponse_ms.programId;
                programResponse.schedule_id = programResponse_ms.scheduleId;
                programResponse.fee_attribute_ids = programResponse_ms.feeAttributeIds;
                feeOnboardingResponse.created_programs.add(programResponse);
            }
        }
        return feeOnboardingResponse;
    }    
}