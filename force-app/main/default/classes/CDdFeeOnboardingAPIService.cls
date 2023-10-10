/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/15/2021
*
* @group Fee Onboarding API
*
* @description Following are the responsibilities of this apex service
*   1. Generate API Request 
*   2. Send (post) the request to appropriate MFS Endpoint
*   Note : Fee Onboarding Api Type is used to route the request to the correct MFS API Service Endpoint
**************************************************************************************************************************************/
public class CDdFeeOnboardingAPIService implements CDdFeeOnboardingAPIServiceInterface {
    public static final Map<String, CDdFeeOnboardingApiType> FEE_ONBOARDING_API_TYPES;
    public static final Integer FEE_ONBOARDING_TIME_OFFSET_IN_SECONDS = Integer.valueOf(System.Label.FEE_ONBOARDING_TIME_OFFSET_IN_SECONDS);
    public static final List<String> COUNTRY_CODES_TO_EXCLUDE_FROM_DOLLARS_TO_CENTS_CONVERSION = System.label.DDDollarsToCentsConversionExceptionCountries.split(';');
    private static Map<CDdFeeOnboardingApiType, CDdFeeOnboardingImplApiService> FEE_ONBOARDING_IMPL_API_SERVICE_BY_API_TYPE;    
    private Map<CDdFeeOnboardingApiType, Object> feeOnboardingRequests;
    static {
        FEE_ONBOARDING_API_TYPES = new Map<String, CDdFeeOnboardingApiType>();
        for (CDdFeeOnboardingApiType enumValue : CDdFeeOnboardingApiType.values()){
            FEE_ONBOARDING_API_TYPES.put(String.valueOf(enumValue).toUpperCase(), enumValue);
        }
        setFeeOnboardingImplApiServiceForApiType();
    }
    private static void setFeeOnboardingImplApiServiceForApiType(){
        FEE_ONBOARDING_IMPL_API_SERVICE_BY_API_TYPE = new Map<CDdFeeOnboardingApiType, CDdFeeOnboardingImplApiService>();
        for (CDdFeeOnboardingApiType apiType : CDdFeeOnboardingApiType.values()){
            switch on apiType {
                when MX_PROGRAM_FEE {
                    FEE_ONBOARDING_IMPL_API_SERVICE_BY_API_TYPE.put(apiType, !CDdNimdaSyncConstants.DISABLE_ONBOARD_PROGRAM_API ? (CDdFeeOnboardingImplApiService)new CDdFeeOnboardingMSApiService() : (CDdFeeOnboardingImplApiService)new CDdFeeOnboardingDSJApiService());
                }
                when MX_STOREFRONT_MONTHLY_FEE {
                    FEE_ONBOARDING_IMPL_API_SERVICE_BY_API_TYPE.put(apiType, !CDdNimdaSyncConstants.DISABLE_MX_RECURRING_PROGRAM_API ? (CDdFeeOnboardingImplApiService)new CDdFeeOnboardingMSApiService() : (CDdFeeOnboardingImplApiService)new CDdFeeOnboardingDSJApiService());
                }                
                when CX_STOREFRONT_FEE {
                    FEE_ONBOARDING_IMPL_API_SERVICE_BY_API_TYPE.put(apiType, !CDdNimdaSyncConstants.DISABLE_DELIVERY_FEE_API ? (CDdFeeOnboardingImplApiService)new CDdFeeOnboardingMSApiService() : (CDdFeeOnboardingImplApiService)new CDdFeeOnboardingDSJApiService());
                }
                when else { }
            }            
        }
    }
    /**
     * @description No argument constructor
     * @param -
     * @return 
     */    
    public CDdFeeOnboardingAPIService(){
    }    
    /**
     * @description Add the fee onboarding request for the specific Fee Onboarding API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @param Object Fee Onboarding request object
     * @return 
     */
    public void addRequest(CDdFeeOnboardingApiType feeOnboardingApiType, Object feeOnboardingRequest){
        if (this.feeOnboardingRequests == null){
            this.feeOnboardingRequests = new Map<CDdFeeOnboardingApiType, Object>();
        }
        this.feeOnboardingRequests.put(feeOnboardingApiType, feeOnboardingRequest);
    }
    /**
     * @description Generate and collect the fee onboarding requests
     * for each Fee Onboarding API Type, to post to MFS Service API
     * @param List<CDdFeeOnboardingProgramObject> Collection of program objects
     * @return 
     */ 
    public void addRequests(List<CDdFeeOnboardingProgramObject> programObjects){
        List<CDdRestJSONObj.MxAffiliateProgram> mxAffiliatePrograms = new List<CDdRestJSONObj.MxAffiliateProgram>();
        List<CDdRestJSONObj.Product> cxStorefrontProducts = new List<CDdRestJSONObj.Product>();
        List<CDdRestJSONObj.MxAffiliateProgram> mxStorefrontMonthlyFees = new List<CDdRestJSONObj.MxAffiliateProgram>();
        Integer storeId = null;
        for (CDdFeeOnboardingProgramObject programObject : programObjects){
            switch on FEE_ONBOARDING_API_TYPES.get(programObject.apiType.toUpperCase()) {
                when MX_PROGRAM_FEE {
                    mxAffiliatePrograms.add(getMxAffiliateProgram(programObject));
                }
                when MX_STOREFRONT_MONTHLY_FEE {
                    mxStorefrontMonthlyFees.add(getMxAffiliateProgram(programObject));
                }                
                when CX_STOREFRONT_FEE {
                    storeId = String.isNotBlank(programObject.storeId) ? Integer.valueOf(programObject.storeId) : null;
                    cxStorefrontProducts.addAll(getCxStorefrontProducts(programObject));
                }
                when else { }
            }
        }
        if (!mxAffiliatePrograms.isEmpty()){
            CDdRestJSONObj.MxFeeOnboardingRequest mxProgramFeeRequest = new CDdRestJSONObj.MxFeeOnboardingRequest();
            mxProgramFeeRequest.creator_email = UserInfo.getUserEmail();
            mxProgramFeeRequest.programs = mxAffiliatePrograms;            
            this.addRequest(CDdFeeOnboardingApiType.MX_PROGRAM_FEE, mxProgramFeeRequest);
        }
        if (!mxStorefrontMonthlyFees.isEmpty()){
            CDdRestJSONObj.MxFeeOnboardingRequest mxStorefrontMonthlyFeesRequest = new CDdRestJSONObj.MxFeeOnboardingRequest();
            mxStorefrontMonthlyFeesRequest.creator_email = UserInfo.getUserEmail();
            mxStorefrontMonthlyFeesRequest.programs = mxStorefrontMonthlyFees;            
            this.addRequest(CDdFeeOnboardingApiType.MX_STOREFRONT_MONTHLY_FEE, mxStorefrontMonthlyFeesRequest);
        }        
        if (!cxStorefrontProducts.isEmpty()){
            CDdRestJSONObj.CxFeeOnboardingRequest cxStorefrontFeeRequest = new CDdRestJSONObj.CxFeeOnboardingRequest();
            cxStorefrontFeeRequest.store_id = storeId;
            cxStorefrontFeeRequest.creator_email = UserInfo.getUserEmail();
            cxStorefrontFeeRequest.products = cxStorefrontProducts;            
            this.addRequest(CDdFeeOnboardingApiType.CX_STOREFRONT_FEE, cxStorefrontFeeRequest);
        }        
    }
    /**
     * @description Does the service contain a request of the input Fee Onboarding API Type?
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @return Boolean
     */
    public Boolean hasRequest(CDdFeeOnboardingApiType feeOnboardingApiType){
        return (this.feeOnboardingRequests != null && this.feeOnboardingRequests.containsKey(feeOnboardingApiType));
    }
    /**
     * @description Does the service contain at least one request to send to MFS?
     * @param -
     * @return Boolean
     */
    public Boolean hasRequests(){
        return (this.feeOnboardingRequests != null && !this.feeOnboardingRequests.isEmpty());
    }
    /**
     * @description Return the fee onboarding request object for the input Fee Onboarding API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @return Object Return the fee onboarding request object
     */
    public Object getRequest(CDdFeeOnboardingApiType feeOnboardingApiType){
        if (!this.hasRequest(feeOnboardingApiType)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, CDdFeeOnboardingException.ERROR_INVALID_REQUEST);           
        }
        return this.feeOnboardingRequests.get(feeOnboardingApiType);
    }        
    /**
     * @description An operation that interacts with the external service for posting the fee onboarding request
     * Fee Onboarding request and endpoint are evaluated based on the input Fee API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @return CDdRestJSONObj.FeeOnboardingResponse Return the Fee Onboarding response information received from the external service
     */
    public CDdRestJSONObj.FeeOnboardingResponse sendRequest(CDdFeeOnboardingApiType feeOnboardingApiType){
        return FEE_ONBOARDING_IMPL_API_SERVICE_BY_API_TYPE.get(feeOnboardingApiType).sendRequest(feeOnboardingApiType, this.getRequest(feeOnboardingApiType));        
    }        
    /**
     * @description Return the Mx Affiliate program object
     * @param CDdFeeOnboardingProgramObject program object
     * @return CDdRestJSONObj.MxAffiliateProgram
     */  
    private CDdRestJSONObj.MxAffiliateProgram getMxAffiliateProgram(CDdFeeOnboardingProgramObject programObject){
        CDdRestJSONObj.MxAffiliateProgram program = new CDdRestJSONObj.MxAffiliateProgram();
        program.audience = programObject.audience;
        program.channel = programObject.channel;
        program.experience = programObject.experience;
        program.fulfillment_type = programObject.fulfillmentType;
        program.salesforce_opportunity_id = programObject.opportunityId;
        program.start_time = dateTimeUTC(programObject.startDate, true, programObject.storeTimezoneGmtOffset);
        program.end_time = dateTimeUTC(programObject.endDate, false, programObject.storeTimezoneGmtOffset);
        program.store_id = String.isNotBlank(programObject.storeId) ? Integer.valueOf(programObject.storeId) : null;
        program.fee_attributes = new List<CDdRestJSONObj.MxAffiliateFeeAttribute>();
        for (CDdFeeOnboardingFeeObject feeObject : programObject.fees){
            program.fee_attributes.add(getMxAffiliateFeeAttribute(feeObject));
        }        
        return program;
    }
    /**
     * @description Return the Mx Affiliate fee attribute object
     * @param CDdFeeOnboardingFeeObject fee object
     * @return CDdRestJSONObj.MxAffiliateFeeAttribute
     */
    private CDdRestJSONObj.MxAffiliateFeeAttribute getMxAffiliateFeeAttribute(CDdFeeOnboardingFeeObject feeObject){
        CDdRestJSONObj.MxAffiliateFeeAttribute feeAttribute = new CDdRestJSONObj.MxAffiliateFeeAttribute();
        feeAttribute.name = feeObject.feeName;
        feeAttribute.friendly_display_name = feeObject.displayName;
        feeAttribute.fee_rate = feeObject.isFeeRate ? feeObject.feeValue.toPlainString() : null;
        feeAttribute.fee_rate_charging_target = feeObject.isFeeRate ? feeObject.feeRateChargingTarget : null;
        feeAttribute.flat_fee_in_cents = !feeObject.isFeeRate ? dollarsToCents(feeObject.feeValue, feeObject.billingCountryCode) : null;
        feeAttribute.fee_type = feeObject.feeType;
        feeAttribute.start_time =  dateTimeUTC(feeObject.startDate, true, feeObject.storeTimezoneGmtOffset);
        feeAttribute.end_time = dateTimeUTC(feeObject.endDate, false, feeObject.storeTimezoneGmtOffset);
        return feeAttribute;
    }    
    /**
     * @description Return the collection of Cx Storefront products for the Storefront Cx Fee program
     * @param CDdFeeOnboardingProgramObject program object
     * @return List<CDdRestJSONObj.Product> Collection of storefront products
     */
    private List<CDdRestJSONObj.Product> getCxStorefrontProducts(CDdFeeOnboardingProgramObject programObject){
        List<CDdRestJSONObj.Product> products = new List<CDdRestJSONObj.Product>();
        for (CDdFeeOnboardingFeeObject feeObject : programObject.fees){
            CDdRestJSONObj.Product product = new CDdRestJSONObj.Product();
            product.audience = programObject.audience;
            product.experience = programObject.experience;
            product.fulfillment_type = programObject.fulfillmentType;
            product.opportunity_id = programObject.opportunityId;
            product.service_rate = feeObject.isFeeRate ? feeObject.feeValue : null;
            product.delivery_fee = !feeObject.isFeeRate ? dollarsToCents(feeObject.feeValue, feeObject.billingCountryCode) : null;
            product.start_time =  dateTimeUTC(feeObject.startDate, true, feeObject.storeTimezoneGmtOffset);
            product.end_time = dateTimeUTC(feeObject.endDate, false, feeObject.storeTimezoneGmtOffset);
            product.opportunity_line_item_id = feeObject.orderItemId;
            product.created_at = feeObject.orderItemLastModifiedDate;            
            products.add(product);
        }
        return products;
    }
    /**
     * @description Return the converted Integer value of dollars to cents
     * @param Decimal input decimal value
     * @param String Billing Country Code
     * @return Integer
     */
    private static Integer dollarsToCents(Decimal input, String billingCountryCode) {
        return input!=null ? (isDollarsToCentsConversionRequired(billingCountryCode) ? (input * 100).intValue() : input.intValue()) : null;
    }
    /**
     * @description Convert Date to Datetime UTC
     * 1. Default time for start_date is 0,0,0,0
     * 2. Default time for end_date is 23,59,59,0
     * 3. If start_date is null or in the past, use today
     * 4. End datetime is nullable. This method will return null if isStartDate is false and the input dt is null
     * 5. Convert the above to UTC by inverting the time zone offset
     *     a) e.g. a negative offset adds time and shifts the end_date to the next day
     *     b) e.g. a positive offset subtracts time and shifts the start_date to yesterday
     * @param Date date to convert
     * @param Boolean Is this a start date?
     * @param Decimal gmt offset value
     * @return Integer
     */
    public static Datetime dateTimeUTC(Date dt, Boolean isStartDate, Decimal gmtOffset) {
        if (!isStartDate && dt == null) return null;
        Datetime dtm = null;
        if (isStartDate){
            if (dt == null || dt <=  System.Date.today()){
                dtm = Datetime.now().addSeconds(FEE_ONBOARDING_TIME_OFFSET_IN_SECONDS);
            } else {
                dtm = Datetime.newInstanceGmt(dt, Time.newInstance(0,0,0,0));
            }
        }
        if (!isStartDate){
            dtm = Datetime.newInstanceGmt(dt, Time.newInstance(23,59,59,0));
        }                
        /*if (gmtOffset != null) {
            Decimal fractional = gmtOffset - (Integer) gmtOffset;
            // Invert time zone offset to convert to UTC
            dtm = dtm.addHours((Integer) -gmtOffset);
            dtm = dtm.addMinutes((Integer) (-fractional * 60));
        }*/
        return dtm;
    }
    /**
     * @description Is dollars to cents conversion required? 
     * This is based on the Billing Country Code. Example: For Japan (JP), dollars to cents conversion is not required
     * @param String Billing Country Code
     */
    private static Boolean isDollarsToCentsConversionRequired(String billingCountryCode){
        return !COUNTRY_CODES_TO_EXCLUDE_FROM_DOLLARS_TO_CENTS_CONVERSION.contains(billingCountryCode);
    }             
}