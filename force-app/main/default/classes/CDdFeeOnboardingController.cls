/********************************************************************************************************************
* @author Jeremy S. Johnson (Perficient, Inc.)
* @date 07/01/2020
*
* @group Fee Onboarding
*
* @description BZAP-8198 Create Lightning Component for Caviar / Online Ordering STN
**************************************************************************************************************************************/
public with sharing class CDdFeeOnboardingController {
    private static final String CLASS_NAME = 'CDdFeeOnboardingController';
    private static final List<String> ELIGIBLE_OPPORTUNITY_RECORD_TYPE_DEVELOPER_NAMES = new List<String>{'Post_Sale','ML_Inside_Sales','Enterprise_Marketplace'};
    private static final String OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    private static final String OPPORTUNITY_RECORD_NOT_FOUND = 'Opportunity record not found. Either Id is invalid or record does not belong to record types '
                                                        + String.join(ELIGIBLE_OPPORTUNITY_RECORD_TYPE_DEVELOPER_NAMES, ', ');
    private static final String ERROR_MSG_OPPORTUNITY_NOT_CLOSED_WON = 'Fee onboarding can only be used for Opportunities where Stage = "Closed Won". Please move the Opportunity Stage to "Closed Won" to proceed.';                                                    
    private static String ERROR_EMPTY_FEE_ONBOARDING_REQUEST = 'No fee onboarding request to process';
    private static final Integer HTTP_STATUS_OK = 200;
    private static final Map<CDdFeeOnboardingApiType, String> FEE_TYPE_STRS = new Map<CDdFeeOnboardingApiType, String>{
        CDdFeeOnboardingApiType.MX_PROGRAM_FEE => 'Mx Program Fees',
        CDdFeeOnboardingApiType.MX_STOREFRONT_MONTHLY_FEE => 'Mx Storefront Monthly Fee',
        CDdFeeOnboardingApiType.CX_STOREFRONT_FEE => 'Cx Storefront Fees'  
    };
    /**
     * Return eligible Programs and Fees for a given Opportunity.
     *
     * @param opportunityId the Opportunity Id
     * @return a List of eligible Programs and Fees
     */
    @AuraEnabled
    public static List<MxAffiliateProgramAndFeeDTO> getProgramsAndFees(Id opportunityId) {
        String METHOD_NAME = 'getProgramsAndFees';
        List<MxAffiliateProgramAndFeeDTO> programsAndFeesDTO = new List<MxAffiliateProgramAndFeeDTO>();
        String locale = UserInfo.getLocale();
        try {
            Opportunity opportunity = getOpportunity(opportunityId);
            if (isCPQModel(opportunity)){
                CDdFeeOnboardingCPQService service = new CDdFeeOnboardingCPQService(opportunity.Id, opportunity.SBQQ__PrimaryQuote__c);
                for (CDdFeeOnboardingProgramObject programObject : service.getProgramObjects()){
                    for (CDdFeeOnboardingFeeObject feeObject : programObject.fees){
                        programsAndFeesDTO.add(new MxAffiliateProgramAndFeeDTO(
                            programObject.displayName,
                            feeObject.feeId,
                            feeObject.displayName
                        ));                        
                    }
                }
            } else {
                CDdFeeOnboardingService service = new CDdFeeOnboardingService();
                for (MxAffiliateFeeAttribute__mdt feeAttribute : service.getEligibleProgramsAndFees(opportunity.Id)) {
                    String programLabel = feeAttribute.Program__r.Label;
                    String feeLabel = feeAttribute.Display_Name__c;
                    if (locale == CDdCoreConstants.JAPAN_LOCALE) {
                        programLabel = feeAttribute.Program__r.Label_ja__c;
                        feeLabel = feeAttribute.Display_Name_ja__c;
                    }
                    programsAndFeesDTO.add(new MxAffiliateProgramAndFeeDTO(
                        programLabel,
                        feeAttribute.Id,
                        feeLabel
                    ));
                }                
            }
            logFuture(METHOD_NAME, String.valueOf(LoggingLevel.DEBUG), opportunityId, programsAndFeesDTO.toString(), '', '');
        } catch (CDdFeeOnboardingException e) {
            //No eligible programs; do nothing
            String errorMessage = CDdFeeOnboardingException.getErrorMessage(e);
            logFuture(METHOD_NAME, String.valueOf(LoggingLevel.ERROR), opportunityId, errorMessage, '', '');
            throw new AuraHandledException(errorMessage);
        }
        return programsAndFeesDTO;
    }
    /**
     * Create Programs and Fees based on user selection.
     *
     * @param opportunityId The Opportunity.Id for which to create Fees
     * @param feeIds A list of user-selected eligible Fees
     * @return CDdFeeOnboardingService.CDdFeeOnboardingInfo
     */
    @AuraEnabled
    public static ResponseDTO createProgramsAndFees(Id opportunityId, List<Id> feeIds) {
        String METHOD_NAME = 'createProgramsAndFees';
        ResponseDTO response = new ResponseDTO();
        Map<String, CDdRestJSONObj.FeeOnboardingResponse> feeOnboardingResponses = new Map<String, CDdRestJSONObj.FeeOnboardingResponse>();
        try {
            CDdFeeOnboardingAPIServiceInterface apiService = getFeeOnboardingAPIService(opportunityId, feeIds);
            for (CDdFeeOnboardingApiType apiType : CDdFeeOnboardingAPIService.FEE_ONBOARDING_API_TYPES.values()){
                if (apiService.hasRequest(apiType)){
                    String apiTypeStr = FEE_TYPE_STRS.get(apiType);
                    CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = apiService.sendRequest(apiType);
                    if (HTTP_STATUS_OK == feeOnboardingResponse.statusCode) {
                        response.messages.add(apiTypeStr + ' created successfully');
                    }                    
                    if (feeOnboardingResponse.created_programs!=null){
                        for (CDdRestJSONObj.MxAffiliateProgramResponse program :  feeOnboardingResponse.created_programs) {
                            response.messages.add(String.format(apiTypeStr + ' created: {0} for the following fee(s): {1}', new List<String> { program.program_id, String.join(program.fee_attribute_ids, ', ')}));
                        }                        
                    }
                    feeOnboardingResponses.put(apiTypeStr, feeOnboardingResponse);
                }
            }
            log(METHOD_NAME, opportunityId, feeOnboardingResponses);
        } catch (CDdFeeOnboardingException e) {
            response.errors.add(CDdFeeOnboardingException.getErrorMessage(e) + '<br> Request: ' + CDdFeeOnboardingException.getExceptionData(e).calloutRequest + '<br> Response: ' + CDdFeeOnboardingException.getExceptionData(e).calloutRequest);
            log(METHOD_NAME, opportunityId, e);
        } catch (Exception e) {
            response.errors.add('Error: ' + e.getMessage());
            log(METHOD_NAME, opportunityId, e);
        }
        return response;
    }
    /**
     * Log the Fee Onboarding error message, request and response in the event of an Exception
     * @param String method name
     * @param Id opportunity record Id
     * @param CDdFeeOnboardingException fee onboarding exception
     * @return
     */
    private static void log(String methodName, Id opportunityId, Exception e) {
        if (e instanceof CDdFeeOnboardingException) {
            CDdFeeOnboardingException fex = (CDdFeeOnboardingException)e; 
            logFuture(methodName, String.valueOf(LoggingLevel.ERROR), opportunityId, CDdFeeOnboardingException.getErrorMessage(fex), CDdFeeOnboardingException.getCalloutRequest(fex), CDdFeeOnboardingException.getCalloutResponse(fex));
        } else {
            logFuture(methodName, String.valueOf(LoggingLevel.ERROR), opportunityId, e.getMessage(), '', '');
        }
    }    
    /**
     * Log the Fee Onboarding successful request and response
     * @param String method name
     * @param Id opportunity record Id
     * @param Map<String, CDdRestJSONObj.FeeOnboardingResponse> feeOnboardingResponses
     * @return
     */
    private static void log(String methodName, Id opportunityId, Map<String, CDdRestJSONObj.FeeOnboardingResponse> feeOnboardingResponses) {
        Map<String, String> request = new Map<String, String>();
        Map<String, String> response = new Map<String, String>();
        for (String apiTypeStr : feeOnboardingResponses.keySet()){
            CDdRestJSONObj.FeeOnboardingResponse feeOnboardingResponse = feeOnboardingResponses.get(apiTypeStr);
            request.put(apiTypeStr, feeOnboardingResponse.request);
            response.put(apiTypeStr, feeOnboardingResponse.response);
        }
        logFuture(methodName, String.valueOf(LoggingLevel.DEBUG), opportunityId, '', JSON.serialize(request), JSON.serialize(response));
    }
    /**
     * Log the Fee Onboarding success and failure process in a future call (i.e. write to db asynchronously)
     * @param String method name
     * @param System.LoggingLevel log level
     * @param Id opportunity record Id (reference id)
     * @param String error message
     * @param String callout request
     * @param String callout response
     * @return
     */
    @future
    public static void logFuture(String methodName, String logLevel, Id opportunityId, String errorMessage, String request, String response) {
        if (String.isNotBlank(opportunityId)) {
            Database.update(new Opportunity( 
                Id = opportunityId,
                Nimda_Sync_Step__c = CDdFeeOnboardingException.STEP_FEE_ONBOARDING,
                Nimda_Sync_Error_Message__c = errorMessage.length() > 255 ? errorMessage.substring(0, 250) : errorMessage,
                Nimda_Sync_Callout_Request__c = request,
                Nimda_Sync_Callout_Response__c = response
            ), false);
        }
        writeApexLog(methodName, logLevel, opportunityId, errorMessage, request, response);
    }
    /**
     * Log the Fee Onboarding success and failure process to apex log
     * @param String method name
     * @param System.LoggingLevel log level
     * @param Id opportunity record Id (reference id)
     * @param String error message
     * @param String callout request
     * @param String callout response
     * @return
     */    
    private static void writeApexLog(String methodName, String logLevel, Id opportunityId, String errorMessage, String request, String response) {
        Database.insert(new Apex_Log__c(
            Class_Name__c = CLASS_NAME,
            Method_Name__c = methodName,
            Object__c = 'Opportunity',            
            Operation__c = CDdFeeOnboardingException.STEP_FEE_ONBOARDING,
            Log_Level__c = logLevel,
            System_Context__c = 'isFuture' + CddCoreConstants.DELIMITER_SEMICOLON,
            User_in_Context__c = UserInfo.getUserId(),
            Record_ID__c = opportunityId,
            Reference_Id__c = opportunityId,
            Log__c = errorMessage,
            Callout_Request__c = request, 
            Callout_Response__c = response
        ), false);
    }
    /**
     * A Data Transfer Object for displaying Programs and Fees to the UI
     */
    public class MxAffiliateProgramAndFeeDTO {
        @AuraEnabled public final Id feeId;
        @AuraEnabled public final String programLabel;
        @AuraEnabled public final String feeLabel;
        public MxAffiliateProgramAndFeeDTO(String programName, Id feeId, String feeName) {
            this.programLabel = programName;
            this.feeId = feeId;
            this.feeLabel = feeName;
        }        
    }

    public class ResponseDTO {
        @AuraEnabled public List<String> messages = new List<String>();
        @AuraEnabled public List<String> errors = new List<String>();
    }
    /**
     * @description Return the Fee Onboarding API Service after performing the following
     * 1. Instantiate the appropriate Fee Onboarding API Service
     * 2. Collect the applicable fee onboarding request(s) and add them as requests to the API Service
     * @param Id Opportunity Id
     * @param List<Id> Collection of Fee Ids (selected in the User Interface)
     * @return CDdFeeOnboardingAPIServiceInterface an instance of the Fee Onboarding API Service
     */
    private static CDdFeeOnboardingAPIServiceInterface getFeeOnboardingAPIService(Id opportunityId, List<Id> feeIds){
        CDdFeeOnboardingAPIServiceInterface apiService = new CDdFeeOnboardingAPIService();
        Opportunity opportunity = getOpportunity(opportunityId);
        if (isCPQModel(opportunity)){
            CDdFeeOnboardingCPQService requestService = new CDdFeeOnboardingCPQService(opportunity.Id, opportunity.SBQQ__PrimaryQuote__c);
            List<CDdFeeOnboardingProgramObject> programObjects = requestService.getProgramObjects(feeIds);
            apiService.addRequests(programObjects);
        } else {
            CDdFeeOnboardingService requestService = new CDdFeeOnboardingService();
            Map<CDdFeeOnboardingApiType, List<Id>> feeIdsByApiType = requestService.getFeeIdsByApiType(feeIds);
            for (CDdFeeOnboardingApiType apiType : feeIdsByApiType.keySet()){
                List<Id> feeIdsForApiType = feeIdsByApiType.get(apiType);
                switch on apiType {
                    when MX_PROGRAM_FEE, MX_STOREFRONT_MONTHLY_FEE {
                        Map<String, Set<String>> programsAndFeesMap = requestService.getProgramsAndFeesMap(feeIdsForApiType); 
                        CDdRestJSONObj.MxFeeOnboardingRequest mxProgramFeeRequest = requestService.getMxFeeOnboardingRequest(opportunityId, programsAndFeesMap);
                        if (mxProgramFeeRequest!=null && mxProgramFeeRequest.programs!=null && !mxProgramFeeRequest.programs.isEmpty()){
                            apiService.addRequest(apiType, mxProgramFeeRequest);
                        }
                    }
                    when CX_STOREFRONT_FEE {
                        CDdRestJSONObj.CxFeeOnboardingRequest cxStorefrontFeeRequest = requestService.getCxFeeOnboardingRequest(opportunityId);
                        if (cxStorefrontFeeRequest!=null && cxStorefrontFeeRequest.products!=null && !cxStorefrontFeeRequest.products.isEmpty()){
                            apiService.addRequest(CDdFeeOnboardingApiType.CX_STOREFRONT_FEE, cxStorefrontFeeRequest);
                        }
                    }
                    when else { }
                }
            }
        }
        if (!apiService.hasRequests()){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, ERROR_EMPTY_FEE_ONBOARDING_REQUEST);
        }
        return apiService;
    }
    /**
     * @description Get the opportunity record for input Opportunity Record Id
     * @param Id Opportunity Id
     * @return Opportunity 
     */
    private static Opportunity getOpportunity(Id opportunityId){
        Opportunity opportunity = null;
        for (Opportunity o : [  SELECT Id, SBQQ__PrimaryQuote__c, StageName 
                                FROM Opportunity 
                                WHERE Id = :opportunityId
                                AND RecordType.DeveloperName IN :ELIGIBLE_OPPORTUNITY_RECORD_TYPE_DEVELOPER_NAMES]){
            opportunity = o;
        }
        if (opportunity==null){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, OPPORTUNITY_RECORD_NOT_FOUND);
        }
        if (!OPPORTUNITY_STAGE_CLOSED_WON.equals(opportunity.StageName)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, ERROR_MSG_OPPORTUNITY_NOT_CLOSED_WON);
        }
        return opportunity;
    }
    /**
     * @description Return the S2N Pricing Model 
     * @param Opportunity Input opportunity record
     * @return CDdS2NSyncPricingModel - enum value
     */
    private static CDdS2NSyncPricingModel getPricingModel(Opportunity opportunity){
        return String.isNotBlank(opportunity.SBQQ__PrimaryQuote__c)
                ?   CDdS2NSyncPricingModel.CPQ
                :   CDdS2NSyncPricingModel.OPPORTUNITY;
    }
    /**
     * @description Is the S2N Pricing Model a CPQ Model?
     * @param Opportunity Input opportunity record
     * @return Boolean
     */    
    private static Boolean isCPQModel(Opportunity opportunity){
        return CDdS2NSyncPricingModel.CPQ.equals(getPricingModel(opportunity));
    }    
}