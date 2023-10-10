/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/24/2020
*
* @group Fee Onboarding
*
* @description Service class for Fee Onboarding.
**************************************************************************************************************************************/
public class CDdFeeOnboardingService {

    public static final Map<String, MxAffiliateProgram__mdt> CONFIGURED_PROGRAMS;
    public static final Map<String, Opportunity_Translate_Length_Of_Trial__mdt> OPPORTUNITY_TRANSLATE_LENGTH_OF_TRIAL;
    public static final String PROGRAM_MARKETPLACE_DELIVERY = 'Marketplace_Delivery';
    public static final String PROGRAM_MARKETPLACE_PICKUP = 'Marketplace_Pickup';
    public static final String PROGRAM_MARKETPLACE_DASHPASS_NO_TRIAL = 'Marketplace_Dashpass_No_Trial';
    public static final String PROGRAM_MARKETPLACE_DASHPASS_TRIAL = 'Marketplace_Dashpass_Trial';
    public static final String PROGRAM_MARKETPLACE_WEBLINKS_DELIVERY = 'Marketplace_Weblinks_Delivery';
    public static final String PROGRAM_MARKETPLACE_WEBLINKS_PICKUP = 'Marketplace_Weblinks_Pickup';
    public static final String PROGRAM_ONLINE_ORDERING_DELIVERY = 'Online_Ordering_Delivery';
    public static final String PROGRAM_ONLINE_ORDERING_PICKUP = 'Online_Ordering_Pickup';
    public static final String PROGRAM_ONLINE_ORDERING_TRIAL_PICKUP_PROMO_PERIOD = 'Online_Ordering_Pickup_Trial_Promo';
    public static final String PROGRAM_ONLINE_ORDERING_TRIAL_DELIVERY_PROMO_PERIOD = 'Online_Ordering_Delivery_Trial_Promo';
    public static final String PROGRAM_CONTACTLESS_ORDERING_CAVIAR = 'Contactless_Ordering_Caviar';
    public static final String PROGRAM_CONTACTLESS_ORDERING_DOORDASH = 'Contactless_Ordering_DoorDash';
    public static final String PROGRAM_CONTACTLESS_ORDERING_TRIAL_CAVIAR = 'Contactless_Ordering_Trial_Caviar';
    public static final String PROGRAM_CONTACTLESS_ORDERING_TRIAL_DOORDASH = 'Contactless_Ordering_Trial_DoorDash';
    public static final String PROGRAM_NONE = 'None';
    public static final String PLATFORM_CAVIAR = 'Caviar';
    public static final String PLATFORM_DOORDASH = 'DoorDash';
    public static final String PLATFORM_CAVIAR_AND_DOORDASH = 'Caviar and DoorDash';
    public static final Set<String> CAVIAR_PLATFORMS = new Set<String>{PLATFORM_CAVIAR, PLATFORM_CAVIAR_AND_DOORDASH};
    public static final Set<String> DOORDASH_PLATFORMS = new Set<String>{PLATFORM_DOORDASH, PLATFORM_CAVIAR_AND_DOORDASH};
    public static final List<String> ELIGIBLE_OPPORTUNITY_RECORD_TYPE_DEVELOPER_NAMES = new List<String>{'Post_Sale','ML_Inside_Sales','Enterprise_Marketplace'};
    public static final String OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    public static final String TRIAL_TYPE_PROMOTIONAL_PERIOD = 'Promotional Period';
    public static final String OPP_REC_TYPE_DEV_NAME_POST_SALE = 'Post_Sale';
    public static final String FEE_TYPE_FEE = 'fee';
    public Enum FEE_NAME {delivery_fee, pickup_fee, processing_fee, monthly_fee}
    public Enum PROGRAM_DEVELOPER_NAME {Marketplace_Delivery, Marketplace_Pickup,
        Marketplace_Dashpass_No_Trial, Marketplace_Dashpass_Trial,
        Marketplace_Weblinks_Delivery, Marketplace_Weblinks_Pickup,
        Online_Ordering_Delivery, Online_Ordering_Pickup, Online_Ordering_Trial_Promo_Period,
        Contactless_Ordering_Caviar, Contactless_Ordering_DoorDash,
        Contactless_Ordering_Trial_Caviar, Contactless_Ordering_Trial_DoorDash
    }
    public static final List<String> COUNTRY_CODES_TO_EXCLUDE_FROM_DOLLARS_TO_CENTS_CONVERSION = System.label.DDDollarsToCentsConversionExceptionCountries.split(';');
    // Error Messages - Begin
    public static final String INVALID_OPPORTUNITY_ID = 'Opportunity Record Id cannot be null. Please provide a valid value.';
    public static final String OPPORTUNITY_RECORD_NOT_FOUND = 'Opportunity record not found. Either Id is invalid or record does not belong to record types '
                                                        + String.join(ELIGIBLE_OPPORTUNITY_RECORD_TYPE_DEVELOPER_NAMES, ', ');
    public static final String ERROR_MSG_OPPORTUNITY_NOT_CLOSED_WON = 'Fee onboarding can only be used for Opportunities where Stage = "Closed Won". Please move the Opportunity Stage to "Closed Won" to proceed.';                                                    
    public static final String INPUT_PROGRAMS_INVALID = 'Input programs cannot be null or an empty collection.';
    public static final String ELIGIBLE_PROGRAMS_NOT_FOUND = 'No eligible program found for the opportunity record Id {0}';
    public static final String INELIGIBLE_PROGRAM_DEVELOPER_NAMES_FOUND = 'Ineligible program developer names {0} found. Expecting the input to be within the list {1}.';
    public static final String INVALID_LENGTH_OF_TRIAL = 'Length of Trial is blank for {0} {1} with Trial Type {2}';
    // Error Messages - End
    static {
        CONFIGURED_PROGRAMS = new Map<String, MxAffiliateProgram__mdt>();
        for (MxAffiliateProgram__mdt program : [SELECT Id, Label, DeveloperName,
                Experience__c, Channel__c, Fulfillment_Type__c, Audience__c,
                IsOpportunityProductProgram__c, Product_Name__c, Is_Active__c,
        (SELECT Id, Label, DeveloperName, Display_Name__c, Is_Trial__c,
                Fee_Name__c, Fee_Type__c, Fee_Rate_Charging_Target__c
        FROM MxAffiliateFeeAttributes__r
        WHERE Is_Active__c = true)
        FROM MxAffiliateProgram__mdt
        WHERE Is_Active__c = true
        ORDER BY DeveloperName ASC]){
            CONFIGURED_PROGRAMS.put(program.DeveloperName, program);
        }
        OPPORTUNITY_TRANSLATE_LENGTH_OF_TRIAL = new Map<String, Opportunity_Translate_Length_Of_Trial__mdt>();
        for (Opportunity_Translate_Length_Of_Trial__mdt t : [SELECT Id, Label, DeveloperName,
                Default_Date_Time__c, Value__c
        FROM Opportunity_Translate_Length_Of_Trial__mdt]){
            OPPORTUNITY_TRANSLATE_LENGTH_OF_TRIAL.put(t.Label, t);
        }
    }
    // Define instance variables here - Begin
    public String billingCountryCode;
    // Define instance variables here - End
    /**
    * @description Query and return the Opportunity record for the input Id
    * For the opportunity record that is queried, in order to support the Opportunity Product Programs, include the following
    *   - Query the child Opportunity Line Items (if applicable) i.e. opportunity.OpportunityLineItems must be valid
    *   - Query for the following on the individual Opportunity Line Item
    *       a) Product Name (Product2.Name)    
    * @param <Id> Input Opportunity Id
    * @return Opportunity record 
    **/
    public Opportunity getOpportunity(Id opportunityId){
        Opportunity retVal = null;
        if (String.isBlank(opportunityId)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, INVALID_OPPORTUNITY_ID);
        }
        for (Opportunity opportunity : [SELECT Id, Name, Store_Id__c, RecordTypeId, RecordType.DeveloperName, Platform__c,
                                        Commission__c, In_App_Pickup_Commission__c, 
                                        DashPass_Only_Commission__c, DashPass_Flat_Fee__c,
                                        Referred_Delivery_Commission__c, Referred_Pickup_Commission__c, 
                                        StageName, Trial_Type__c, Length_of_Trial__c,
                                        Trial_Commission__c, Trial_DashPass_Commission__c,
                                        Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c, Account.BillingCountryCode,
                                            (SELECT Id, Name, Product2.Name, Start_Date__c, End_Date__c,
                                            Flat_Fee__c, Payment_Processing_Fee__c, Payment_Processing_Rate__c,
                                            Trial_Type__c, Length_of_Trial__c, CreatedDate, Service_Rate__c, Service_Fee__c,
                                            Subscription_Fee__c, LastModifiedDate
                                            FROM OpportunityLineItems)
                                        FROM Opportunity
                                        WHERE Id = :opportunityId
                                        AND RecordType.DeveloperName IN :ELIGIBLE_OPPORTUNITY_RECORD_TYPE_DEVELOPER_NAMES]){
            retVal = opportunity;
        }
        if (retVal==null){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, OPPORTUNITY_RECORD_NOT_FOUND);
        }
        if (!OPPORTUNITY_STAGE_CLOSED_WON.equals(retVal.StageName)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, ERROR_MSG_OPPORTUNITY_NOT_CLOSED_WON);
        }
        this.billingCountryCode = retVal.Account.BillingCountryCode;
        return retVal;
    }

    /**
     * Get a list of eligible programs and fees for the Opportunity
     *
     * @param opportunityId the Opportunity for which to check eligibility
     * @return a sorted list of MxAffiliateFeeAttribute__mdt
     */
    public List<MxAffiliateFeeAttribute__mdt> getEligibleProgramsAndFees(Id opportunityId) {
        Map<String, MxAffiliateProgram__mdt> eligiblePrograms = this.getEligiblePrograms(opportunityId);
        Opportunity opportunity = this.getOpportunity(opportunityId);
        Boolean isPromotionalTrial = this.isPromotionalTrial(opportunity);

        List<MxAffiliateFeeAttribute__mdt> programsAndFeesMDT  = new List<MxAffiliateFeeAttribute__mdt>();
        for (MxAffiliateFeeAttribute__mdt feeAttribute : [
                SELECT Id, Display_Name__c, Display_Name_ja__c, Is_Trial__c, Program__r.Label, Program__r.Label_ja__c, Program__r.IsOpportunityProductProgram__c
                FROM MxAffiliateFeeAttribute__mdt WHERE Program__r.DeveloperName = :eligiblePrograms.keySet()]) {

            if (!feeAttribute.Program__r.IsOpportunityProductProgram__c) {
                if (!feeAttribute.Is_Trial__c || (isPromotionalTrial && feeAttribute.Is_Trial__c)){
                    programsAndFeesMDT.add(feeAttribute);
                }
            } else {
                programsAndFeesMDT.add(feeAttribute);
            }
        }
        programsAndFeesMDT.sort();
        return programsAndFeesMDT;
    }

    /**
    * @description Return the eligible programs for the input Opportunity record Id
    * @return Map<String, MxAffiliateProgram__mdt> A Collection of eligible programs with Program Developer Name
    *   as the key which is found in Custom Metadata MxAffiliateProgram__mdt 
    **/
    public Map<String, MxAffiliateProgram__mdt> getEligiblePrograms(Id opportunityId){
        Map<String, MxAffiliateProgram__mdt> eligiblePrograms = new Map<String, MxAffiliateProgram__mdt>();
        Opportunity opportunity = this.getOpportunity(opportunityId);
        if (opportunity!=null){
            eligiblePrograms.putAll(this.getEligibleOpportunityPrograms(opportunity));
            eligiblePrograms.putAll(this.getEligibleOpportunityProductPrograms(opportunity));
            eligiblePrograms.putAll(this.getEligibleCustomerDeliveryFee(opportunity));
        }
        if (eligiblePrograms.isEmpty()){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, String.format(ELIGIBLE_PROGRAMS_NOT_FOUND, new List<String>{opportunityId}));
        }
        return eligiblePrograms;
    }

    /**
    * @description Prepare and return the fee onboarding request object
    * @param <Id> Input Opportunity Id
    * @param A collection Set<String> of eligible program developer names for the corresponding opportunity record
    *   - Follow the rules (as found in BZAP-8135) to determine what programs are eligible 
    *   - The corresponding developer names as found in custom metadata - MxAffiliateProgram__mdt must be set within the Collection 
    * @return CDdRestJSONObj.FeeOnboardingRequest the fee onboarding request object
    **/  
    public CDdRestJSONObj.MxFeeOnboardingRequest getFeeOnboardingRequest(Id opportunityId, Set<String> programDeveloperNames){
        if (String.isBlank(opportunityId)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, OPPORTUNITY_RECORD_NOT_FOUND);
        }
        Opportunity opportunity = this.getOpportunity(opportunityId);
        if (opportunity == null){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, OPPORTUNITY_RECORD_NOT_FOUND);
        }
        if (programDeveloperNames == null || programDeveloperNames.isEmpty()){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, INPUT_PROGRAMS_INVALID);
        }
        List<String> eligiblePrograms = new List<String>(this.getEligiblePrograms(opportunity.Id).keySet());
        List<String> ineligiblePrograms = new List<String>();
        for (String programDeveloperName : programDeveloperNames){
            if (eligiblePrograms.indexOf(programDeveloperName) < 0){
                ineligiblePrograms.add(programDeveloperName);
            }
        }
        if (!ineligiblePrograms.isEmpty()){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, String.format(INELIGIBLE_PROGRAM_DEVELOPER_NAMES_FOUND, new List<String>{String.join(ineligiblePrograms, ', '), String.join(eligiblePrograms, ', ')}));
        }
        CDdRestJSONObj.MxFeeOnboardingRequest request = new CDdRestJSONObj.MxFeeOnboardingRequest();
        request.creator_email = UserInfo.getUserEmail();
        List<CDdRestJSONObj.MxAffiliateProgram> programs = new List<CDdRestJSONObj.MxAffiliateProgram>();
        programs.addAll(this.getOpportunityPrograms(opportunity, programDeveloperNames));
        programs.addAll(this.getOpportunityProductPrograms(opportunity, programDeveloperNames));
        request.programs = programs;
        return request;
    }
    /**
    * @description Prepare and return the fee onboarding request object for specific programs and specific fees within a program
    * @param <Id> Input Opportunity Id
    * @param A nested collection Map<String, Set<String>> of selected program developer names and the selected fee developer names,
    *   for the corresponding opportunity record
    *   - Follow the rules (as found in BZAP-8135) to determine what programs are eligible 
    *   - The corresponding program developer names as found in custom metadata - MxAffiliateProgram__mdt must be set within the Collection 
    *   - The corresponding fee developer names as found in custom metadata - MxAffiliateFeeAttribute__mdt must be set within the Nested Collection
    *       for the corresponding program     
    * @return CDdRestJSONObj.FeeOnboardingRequest the fee onboarding request object
    **/  
    public CDdRestJSONObj.MxFeeOnboardingRequest getMxFeeOnboardingRequest(Id opportunityId, Map<String, Set<String>> programAndFeeDeveloperNames){
        if (String.isBlank(opportunityId)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, OPPORTUNITY_RECORD_NOT_FOUND);
        }
        Opportunity opportunity = this.getOpportunity(opportunityId);
        if (opportunity == null){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, OPPORTUNITY_RECORD_NOT_FOUND);
        }
        if (programAndFeeDeveloperNames == null || programAndFeeDeveloperNames.isEmpty()){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, INPUT_PROGRAMS_INVALID);
        }
        List<String> eligiblePrograms = new List<String>(this.getEligiblePrograms(opportunity.Id).keySet());
        List<String> ineligiblePrograms = new List<String>();
        for (String programDeveloperName : programAndFeeDeveloperNames.keySet()){
            if (eligiblePrograms.indexOf(programDeveloperName) < 0){
                ineligiblePrograms.add(programDeveloperName);
            }
        }
        if (!ineligiblePrograms.isEmpty()){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, String.format(INELIGIBLE_PROGRAM_DEVELOPER_NAMES_FOUND, new List<String>{String.join(ineligiblePrograms, ', '), String.join(eligiblePrograms, ', ')}));
        }
        CDdRestJSONObj.MxFeeOnboardingRequest request = new CDdRestJSONObj.MxFeeOnboardingRequest();
        request.creator_email = UserInfo.getUserEmail();
        List<CDdRestJSONObj.MxAffiliateProgram> programs = new List<CDdRestJSONObj.MxAffiliateProgram>();
        programs.addAll(this.getOpportunityPrograms(opportunity, programAndFeeDeveloperNames));
        programs.addAll(this.getOpportunityProductPrograms(opportunity, programAndFeeDeveloperNames));
        request.programs = programs;
        return request;
    }

    /**
     * BZAP-8800: Customer Delivery Fee
    **/
    public CDdRestJSONObj.CxFeeOnboardingRequest getCxFeeOnboardingRequest(Id opportunityId){
        if (String.isBlank(opportunityId)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, OPPORTUNITY_RECORD_NOT_FOUND);
        }

        Opportunity opportunity = this.getOpportunity(opportunityId);
        if (opportunity == null){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, OPPORTUNITY_RECORD_NOT_FOUND);
        }

        List<String> eligiblePrograms = new List<String>(this.getEligiblePrograms(opportunity.Id).keySet());
        if (!eligiblePrograms.contains(PROGRAM_NONE)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, 'This Opportunity is ineligible for ' + PROGRAM_NONE);
        }

        CDdRestJSONObj.CxFeeOnboardingRequest request = new CDdRestJSONObj.CxFeeOnboardingRequest();
        request.store_id = String.isNotBlank(opportunity.Store_Id__c) ? Integer.valueOf(opportunity.Store_Id__c) : null;
        request.creator_email = UserInfo.getUserEmail();
        request.products = this.getOpportunityProducts(opportunity);

        return request;
    }
    /**
    * @description Return a Collection of Opportunity based Mx Affiliate Programs for the input Opportunity and collection of program developer names
    *   - The collection of programs will be filtered to process only the Opportunity related program
    *       (i.e. configuredProgram.IsOpportunityProductProgram__c = false)
    * @param <Opportunity> Input opportunity record
    * @param A collection Set<String> of eligible Opportunity Program Developer Names
    * @return A Collection of Opportunity based Mx Affiliate Programs
    **/
    private List<CDdRestJSONObj.MxAffiliateProgram> getOpportunityPrograms(Opportunity opportunity, Set<String> programDeveloperNames){
        List<CDdRestJSONObj.MxAffiliateProgram> programs = new List<CDdRestJSONObj.MxAffiliateProgram>();
        for (String programDeveloperName : programDeveloperNames){
            if (CONFIGURED_PROGRAMS.containsKey(programDeveloperName)
                    && !CONFIGURED_PROGRAMS.get(programDeveloperName).IsOpportunityProductProgram__c){
                MxAffiliateProgram__mdt configuredProgram = CONFIGURED_PROGRAMS.get(programDeveloperName);
                CDdRestJSONObj.MxAffiliateProgram program = new CDdRestJSONObj.MxAffiliateProgram();
                program.audience = configuredProgram.Audience__c;
                program.channel = configuredProgram.Channel__c;
                program.experience = configuredProgram.Experience__c;
                program.fee_attributes = this.getOpportunityFeeAttributes(opportunity, configuredProgram).values();
                program.fulfillment_type = configuredProgram.Fulfillment_Type__c;
                program.salesforce_opportunity_id = opportunity.Id;
                program.start_time = null;
                program.store_id = String.isNotBlank(opportunity.Store_Id__c) ? Integer.valueOf(opportunity.Store_Id__c) : null;
                programs.add(program);
            }
        }
        return programs;
    }

    /**
    * @description Return a Collection of Opportunity based Mx Affiliate Programs for the input Opportunity and collection of program developer names
    *   - The collection of programs will be filtered to process only the Opportunity related program
    *       (i.e. configuredProgram.IsOpportunityProductProgram__c = false)
    * @param <Opportunity> Input opportunity record
    * @param A nested collection Map<String, Set<String>> of selected program developer names and the selected fee developer names,
    *   for the corresponding opportunity record
    * @return A Collection of Opportunity based Mx Affiliate Programs
    **/
    private List<CDdRestJSONObj.MxAffiliateProgram> getOpportunityPrograms(Opportunity opportunity, Map<String, Set<String>> programAndFeeDeveloperNames){
        List<CDdRestJSONObj.MxAffiliateProgram> programs = new List<CDdRestJSONObj.MxAffiliateProgram>();
        for (String programDeveloperName : programAndFeeDeveloperNames.keySet()){
            if (CONFIGURED_PROGRAMS.containsKey(programDeveloperName)
                    && !CONFIGURED_PROGRAMS.get(programDeveloperName).IsOpportunityProductProgram__c){
                MxAffiliateProgram__mdt configuredProgram = CONFIGURED_PROGRAMS.get(programDeveloperName);
                CDdRestJSONObj.MxAffiliateProgram program = new CDdRestJSONObj.MxAffiliateProgram();
                program.audience = configuredProgram.Audience__c;
                program.channel = configuredProgram.Channel__c;
                program.experience = configuredProgram.Experience__c;
                program.fee_attributes = new List<CDdRestJSONObj.MxAffiliateFeeAttribute>();
                program.fulfillment_type = configuredProgram.Fulfillment_Type__c;
                program.salesforce_opportunity_id = opportunity.Id;
                program.start_time = null;
                program.store_id = String.isNotBlank(opportunity.Store_Id__c) ? Integer.valueOf(opportunity.Store_Id__c) : null;
                Map<String, CDdRestJSONObj.MxAffiliateFeeAttribute> feeAttributesByDeveloperName = this.getOpportunityFeeAttributes(opportunity, configuredProgram);
                for (String feeDeveloperName : feeAttributesByDeveloperName.keySet()){
                    for (String filteredFeeDeveloperName : programAndFeeDeveloperNames.get(programDeveloperName)){
                        if (filteredFeeDeveloperName.equals(feeDeveloperName)){
                            program.fee_attributes.add(feeAttributesByDeveloperName.get(feeDeveloperName));
                        }
                    }
                }
                programs.add(program);
            }
        }
        return programs;
    }

    private List<CDdRestJSONObj.Product> getOpportunityProducts(Opportunity opportunity){
        List<CDdRestJSONObj.Product> products = new List<CDdRestJSONObj.Product>();
        MxAffiliateProgram__mdt configuredProgram = CONFIGURED_PROGRAMS.get(PROGRAM_NONE);
        List<String> productNames = this.getCustomerDeliveryFeeProductNames();

        Account account = [select Id, RealZip_TimeZone__c from Account where Id = :opportunity.AccountId];

        for (OpportunityLineItem oli : opportunity.OpportunityLineItems) {
            if (productNames.contains(oli.Product2.Name)) {
                CDdRestJSONObj.Product product = new CDdRestJSONObj.Product();
                product.audience = configuredProgram.Audience__c;
                product.created_at = oli.LastModifiedDate;
                product.delivery_fee = oli.Service_Fee__c == null ? null : (Integer) (oli.Service_Fee__c * 100);
                product.end_time = oli.End_Date__c == null ? null : dateTimeUTC(oli.End_Date__c, false, opportunity.Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c);
                product.experience = configuredProgram.Experience__c;
                product.fulfillment_type = configuredProgram.Fulfillment_Type__c;
                product.opportunity_id = opportunity.Id;
                product.opportunity_line_item_id = oli.Id;
                product.service_rate = oli.Service_Rate__c;
                product.start_time = dateTimeUTC(oli.Start_Date__c, true, opportunity.Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c);
                // TODO: Not currently supported by Salesforce
                //            product.min_order_fee = ?
                //            product.min_order_subtotal = ?
                products.add(product);
            }
        }

        return products;
    }

    /**
     * Convert Date to Datetime UTC
     * 1. Default time for start_date is 0,0,0,0
     * 2. Default time for end_date is 23,59,59,0
     * 3. If start_date is null or in the past, use today
     * 4. Convert the above to UTC by inverting the time zone offset
     *     a) e.g. a negative offset adds time and shifts the end_date to the next day
     *     b) e.g. a positive offset subtracts time and shifts the start_date to yesterday
     */
    public static Datetime dateTimeUTC(Date dt, Boolean isStartDate, Decimal gmtOffset) {
        return CDdFeeOnboardingAPIService.dateTimeUTC(dt, isStartDate, gmtOffset);
        /*Time tm = isStartDate ?
                Time.newInstance(0,0,0,0) :
                Time.newInstance(23,59,59,0);

        Datetime dtm = (dt == null) || (isStartDate && dt <= Date.today()) ?
                Datetime.newInstanceGmt(Date.today(), tm) :
                Datetime.newInstanceGmt(dt, tm);

        if (gmtOffset != null) {
            Decimal fractional = gmtOffset - (Integer) gmtOffset;
            // Invert time zone offset to convert to UTC
            dtm = dtm.addHours((Integer) -gmtOffset);
            dtm = dtm.addMinutes((Integer) (-fractional * 60));
        }

        return dtm;*/
    }

    private List<String> getCustomerDeliveryFeeProductNames() {
        List<Customer_Delivery_Fee_Product__mdt> products = [select Product_Name__c from Customer_Delivery_Fee_Product__mdt];

        List<String> productNames = new List<String>();
        for (Customer_Delivery_Fee_Product__mdt product : products) {
            productNames.add(product.Product_Name__c);
        }

        return productNames;
    }

    /**
    * @description Return a Collection of Opportunity Product based Mx Affiliate Programs for the input Opportunity and collection of program developer names
    *   - The collection of programs will be filtered to process only the Opportunity Product related programs
    *       (i.e. configuredProgram.IsOpportunityProductProgram__c = true)
    * @param <Opportunity> Input opportunity, in order to support the Opportunity Product Program, include the following
    *   - include the child Opportunity Line Items (if applicable) i.e. opportunity.OpportunityLineItems must be valid
    *   - include the following on the individual Opportunity Line Item
    *       a) Product Name (Product2.Name)
    * @param A collection Set<String> of eligible Opportunity Program Developer Names
    * @return A Collection of Opportunity Product based Mx Affiliate Programs
    **/
    private List<CDdRestJSONObj.MxAffiliateProgram> getOpportunityProductPrograms(Opportunity opportunity, Set<String> programDeveloperNames){
        List<CDdRestJSONObj.MxAffiliateProgram> programs = new List<CDdRestJSONObj.MxAffiliateProgram>();
        for (String programDeveloperName : programDeveloperNames){
            if (CONFIGURED_PROGRAMS.containsKey(programDeveloperName)
                    && CONFIGURED_PROGRAMS.get(programDeveloperName).IsOpportunityProductProgram__c){
                MxAffiliateProgram__mdt configuredProgram = CONFIGURED_PROGRAMS.get(programDeveloperName);
                PROGRAM_DEVELOPER_NAME programDeveloperNameEnumVal = this.getProgramDeveloperName(programDeveloperName);
                String productName = configuredProgram.Product_Name__c;
                List<OpportunityLineItem> opportunityLineItems = this.getOpportunityLineItems(opportunity, productName);
                for (OpportunityLineItem opportunityLineItem : opportunityLineItems) {
                    CDdRestJSONObj.MxAffiliateProgram program = new CDdRestJSONObj.MxAffiliateProgram();
                    program.store_id = String.isNotBlank(opportunity.Store_Id__c) ? Integer.valueOf(opportunity.Store_Id__c) : null;
                    program.experience = configuredProgram.Experience__c;
                    program.channel = configuredProgram.Channel__c;
                    program.fulfillment_type = configuredProgram.Fulfillment_Type__c;
                    program.audience = configuredProgram.Audience__c;
                    program.start_time = getProgramStartDateTime(opportunity, opportunityLineItem, programDeveloperNameEnumVal);
                    program.end_time = getProgramEndDateTime(opportunity, opportunityLineItem, programDeveloperNameEnumVal);
                    program.salesforce_opportunity_id = opportunity.Id;
                    program.fee_attributes = this.getOpportunityProductFeeAttributes(opportunity, opportunityLineItem, configuredProgram).values();
                    programs.add(program);
                }
            }
        }
        return programs;
    }
    /**
    * @description Return a Collection of Opportunity Product based Mx Affiliate Programs for the input Opportunity and collection of program developer names
    *   - The collection of programs will be filtered to process only the Opportunity Product related programs
    *       (i.e. configuredProgram.IsOpportunityProductProgram__c = true)
    * @param <Opportunity> Input opportunity, in order to support the Opportunity Product Program, include the following
    *   - include the child Opportunity Line Items (if applicable) i.e. opportunity.OpportunityLineItems must be valid
    *   - include the following on the individual Opportunity Line Item
    *       a) Product Name (Product2.Name)
    * @param A nested collection Map<String, Set<String>> of selected program developer names and the selected fee developer names,
    *   for the corresponding opportunity record
    * @return A Collection of Opportunity Product based Mx Affiliate Programs
    **/
    private List<CDdRestJSONObj.MxAffiliateProgram> getOpportunityProductPrograms(Opportunity opportunity, Map<String, Set<String>> programAndFeeDeveloperNames){
        List<CDdRestJSONObj.MxAffiliateProgram> programs = new List<CDdRestJSONObj.MxAffiliateProgram>();
        for (String programDeveloperName : programAndFeeDeveloperNames.keySet()){
            if (CONFIGURED_PROGRAMS.containsKey(programDeveloperName)
                    && CONFIGURED_PROGRAMS.get(programDeveloperName).IsOpportunityProductProgram__c){
                MxAffiliateProgram__mdt configuredProgram = CONFIGURED_PROGRAMS.get(programDeveloperName);
                PROGRAM_DEVELOPER_NAME programDeveloperNameEnumVal = this.getProgramDeveloperName(programDeveloperName);
                String productName = configuredProgram.Product_Name__c;
                List<OpportunityLineItem> opportunityLineItems = this.getOpportunityLineItems(opportunity, productName);
                for (OpportunityLineItem opportunityLineItem : opportunityLineItems) {
                    CDdRestJSONObj.MxAffiliateProgram program = new CDdRestJSONObj.MxAffiliateProgram();
                    program.store_id = String.isNotBlank(opportunity.Store_Id__c) ? Integer.valueOf(opportunity.Store_Id__c) : null;
                    program.experience = configuredProgram.Experience__c;
                    program.channel = configuredProgram.Channel__c;
                    program.fulfillment_type = configuredProgram.Fulfillment_Type__c;
                    program.audience = configuredProgram.Audience__c;
                    program.start_time = getProgramStartDateTime(opportunity, opportunityLineItem, programDeveloperNameEnumVal);
                    program.end_time = getProgramEndDateTime(opportunity, opportunityLineItem, programDeveloperNameEnumVal);
                    program.salesforce_opportunity_id = opportunity.Id;
                    program.fee_attributes = new List<CDdRestJSONObj.MxAffiliateFeeAttribute>();
                    Map<String, CDdRestJSONObj.MxAffiliateFeeAttribute> feeAttributesByDeveloperName = this.getOpportunityProductFeeAttributes(opportunity, opportunityLineItem, configuredProgram);
                    for (String feeDeveloperName : feeAttributesByDeveloperName.keySet()){
                        for (String filteredFeeDeveloperName : programAndFeeDeveloperNames.get(programDeveloperName)){
                            if (filteredFeeDeveloperName.equals(feeDeveloperName)){
                                program.fee_attributes.add(feeAttributesByDeveloperName.get(feeDeveloperName));
                            }
                        }
                    }
                    programs.add(program);
                }
            }
        }
        return programs;
    }
    /**
    * @description Return a Collection of fee attributes for the program at the Opportunity level
    *       (i.e. configuredProgram.IsOpportunityProductProgram__c = false)
    * @param <Opportunity> Input opportunity record
    * @param Input program record [MxAffiliateProgram__mdt]
    * @return A Collection of Fee Attributes
    **/
    private Map<String, CDdRestJSONObj.MxAffiliateFeeAttribute> getOpportunityFeeAttributes(Opportunity opportunity, MxAffiliateProgram__mdt program){
        PROGRAM_DEVELOPER_NAME programDeveloperName = this.getProgramDeveloperName(program.DeveloperName);
        Boolean isTrial = this.isTrial(opportunity);
        Boolean isPromotionalTrial = this.isPromotionalTrial(opportunity);
        DateTime trialEndDate = isTrial ? this.getTrialEndDate(opportunity) : null;
        Boolean hasTrialExpired = this.hasTrialExpired(opportunity);
        Map<String, CDdRestJSONObj.MxAffiliateFeeAttribute> feeAttributes = new Map<String, CDdRestJSONObj.MxAffiliateFeeAttribute>();
        if (!program.IsOpportunityProductProgram__c){
            for (MxAffiliateFeeAttribute__mdt configuredFeeAttribute : program.MxAffiliateFeeAttributes__r){
                // Process all non-trial records and additionally
                // Process trial records only if the record is in a Promotional Period
                if (!configuredFeeAttribute.Is_Trial__c || (isPromotionalTrial && configuredFeeAttribute.Is_Trial__c)){
                    Boolean processingTrialFee = configuredFeeAttribute.Is_Trial__c;
                    CDdRestJSONObj.MxAffiliateFeeAttribute feeAttribute = new CDdRestJSONObj.MxAffiliateFeeAttribute();
                    feeAttribute.name = configuredFeeAttribute.Fee_Name__c;
                    feeAttribute.friendly_display_name = configuredFeeAttribute.Display_Name__c;
                    feeAttribute.fee_rate = this.getFeeRate(opportunity, programDeveloperName, processingTrialFee);
                    feeAttribute.fee_rate_charging_target = feeAttribute.fee_rate!=null ? configuredFeeAttribute.Fee_Rate_Charging_Target__c : null;
                    feeAttribute.flat_fee_in_cents = this.getFlatFeeCents(opportunity, programDeveloperName);
                    // For fee type, default configured is applied mostly except for possible override in the case of 'Marketplace Dashpass - No Trial'
                    feeAttribute.fee_type = feeAttribute.fee_rate!=null ? configuredFeeAttribute.Fee_Type__c : FEE_TYPE_FEE;
                    feeAttribute.start_time =  (processingTrialFee ? null : (trialEndDate!=null && !hasTrialExpired ? trialEndDate.addDays(1) : null));
                    feeAttribute.end_time = (processingTrialFee ? (trialEndDate!=null ? trialEndDate : null) : null);
                    if (!this.isPastDate(feeAttribute.end_time)){    
                        feeAttributes.put(configuredFeeAttribute.DeveloperName, feeAttribute);
                    }
                }
            }
        }
        return feeAttributes;
    }
    /**
    * @description Return a Collection of fee attributes for the program at the Opportunity Product level
    *       (i.e. configuredProgram.IsOpportunityProductProgram__c = true)
    * @param <OpportunityLineItem> Input Opportunity Product
    *   - include the following on the individual Opportunity Line Item
    *       a) Product Name (Product2.Name)
    * @param Input program record [MxAffiliateProgram__mdt]
    * @return A Collection of Fee Attributes
    **/
    private Map<String, CDdRestJSONObj.MxAffiliateFeeAttribute> getOpportunityProductFeeAttributes(Opportunity opportunity, OpportunityLineItem opportunityLineItem, MxAffiliateProgram__mdt program){
        PROGRAM_DEVELOPER_NAME programDeveloperName = this.getProgramDeveloperName(program.DeveloperName);
        Map<String, CDdRestJSONObj.MxAffiliateFeeAttribute> feeAttributes = new Map<String, CDdRestJSONObj.MxAffiliateFeeAttribute>();
        if (program.IsOpportunityProductProgram__c){
            for (MxAffiliateFeeAttribute__mdt configuredFeeAttribute : program.MxAffiliateFeeAttributes__r){
                Boolean processingTrialFee = configuredFeeAttribute.Is_Trial__c;
                CDdRestJSONObj.MxAffiliateFeeAttribute feeAttribute = new CDdRestJSONObj.MxAffiliateFeeAttribute();
                feeAttribute.name = configuredFeeAttribute.Fee_Name__c;
                feeAttribute.friendly_display_name = configuredFeeAttribute.Display_Name__c;
                feeAttribute.fee_rate = this.getFeeRate(opportunity, opportunityLineItem, programDeveloperName, getFeeName(configuredFeeAttribute.Fee_Name__c), processingTrialFee);
                feeAttribute.fee_rate_charging_target = feeAttribute.fee_rate!=null ? configuredFeeAttribute.Fee_Rate_Charging_Target__c : null;
                feeAttribute.flat_fee_in_cents = this.getFlatFeeCents(opportunity, opportunityLineItem, programDeveloperName, getFeeName(configuredFeeAttribute.Fee_Name__c), processingTrialFee);
                // For fee type, default configured is applied mostly except for possible override in the case of 'Marketplace Dashpass Trial'
                feeAttribute.fee_type = feeAttribute.fee_rate!=null ? configuredFeeAttribute.Fee_Type__c : FEE_TYPE_FEE;
                feeAttribute.start_time = this.getFeeAttributeStartDateTime(opportunity, opportunityLineItem, programDeveloperName, processingTrialFee);
                feeAttribute.end_time = this.getFeeAttributeEndDateTime(opportunity, opportunityLineItem, programDeveloperName, processingTrialFee);
                if (!this.isPastDate(feeAttribute.end_time)){  
                    feeAttributes.put(configuredFeeAttribute.DeveloperName, feeAttribute);
                }
            }
        }
        return feeAttributes;
    }
    /**
    * @description Filter and return the relevant Opportunity Products that belong to the input program name
    * @param <Opportunity> input opportunity - an opportunity record includes the child Opportunity Line Items (if applicable)
    *   - includes the child Opportunity Line Items (if applicable) i.e. opportunity.OpportunityLineItems must be valid
    *   - include the following on the individual Opportunity Line Item
    *       a) Product Name (Product2.Name)
    * @param Input product name i.e. [MxAffiliateProgram__mdt].Product_Name__c
    * @return A Collection of Opportunity Products
    **/
    private List<OpportunityLineItem> getOpportunityLineItems(Opportunity opportunity, String productName){
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems){
            if (productName.equals(opportunityLineItem.Product2.Name)){
                opportunityLineItems.add(opportunityLineItem);
            }
        }
        return opportunityLineItems;
    }
    /**
    * @description Return the Fee Rate for the input Opportunity and program developer name
    **/
    private String getFeeRate(Opportunity opportunity, PROGRAM_DEVELOPER_NAME programDeveloperName, Boolean isTrial){
        Decimal feeRate = null;
        switch on programDeveloperName {
            when Marketplace_Delivery {
                feeRate = isTrial ? opportunity.Trial_Commission__c : opportunity.Commission__c;
            }
            when Marketplace_Pickup {
                feeRate = opportunity.In_App_Pickup_Commission__c;
            }
            when Marketplace_Dashpass_No_Trial {
                feeRate = opportunity.DashPass_Only_Commission__c;
            }
            when Marketplace_Weblinks_Delivery {
                feeRate = opportunity.Referred_Delivery_Commission__c;
            }
            when Marketplace_Weblinks_Pickup {
                feeRate = opportunity.Referred_Pickup_Commission__c;
            }
            when else {
                feeRate = null;
            }
        }
        return feeRate!=null ? feeRate.toPlainString() : null;
    }
    /**
    * @description Return the Flat Fee Cents for the input Opportunity and program developer name
    **/
    private Integer getFlatFeeCents(Opportunity opportunity, PROGRAM_DEVELOPER_NAME programDeveloperName){
        Integer flatFeeCents = null;
        switch on programDeveloperName {
            when Marketplace_Dashpass_No_Trial {
                flatFeeCents = dollarsToCents(opportunity.DashPass_Flat_Fee__c);
            }
            when else {
                flatFeeCents = null;
            }
        }
        return flatFeeCents;
    }
    /**
    * @description Return the program start date for the input Opportunity Product
    **/
    private DateTime getProgramStartDateTime(Opportunity opportunity, OpportunityLineItem opportunityLineItem, PROGRAM_DEVELOPER_NAME programDeveloperName){
        switch on programDeveloperName {
            when Marketplace_Dashpass_Trial {
                return null;
            }
            when else {
                return (opportunityLineItem.Start_Date__c != null &&  opportunityLineItem.Start_Date__c > System.today()) ? opportunityLineItem.Start_Date__c : null;
            }
        }
    }
    /**
    * @description Return the program end date for the input Opportunity Product
    **/
    private DateTime getProgramEndDateTime(Opportunity opportunity, OpportunityLineItem opportunityLineItem, PROGRAM_DEVELOPER_NAME programDeveloperName){
        switch on programDeveloperName {
            when Marketplace_Dashpass_Trial {
                return null;
            }
            when else {
                return opportunityLineItem.End_Date__c != null ? opportunityLineItem.End_Date__c : null;
            }
        }
    }
    /**
    * @description Return the fee attribute start date for the input Opportunity Product
    **/
    private DateTime getFeeAttributeStartDateTime(Opportunity opportunity, OpportunityLineItem opportunityLineItem, PROGRAM_DEVELOPER_NAME programDeveloperName, Boolean processingTrialFee){
        switch on programDeveloperName {
            when Marketplace_Dashpass_Trial {
                Boolean isTrial = this.isTrial(opportunityLineItem);
                DateTime trialEndDate = isTrial ? this.getTrialEndDate(opportunityLineItem) : null;
                Boolean hasTrialExpired = this.hasTrialExpired(opportunityLineItem);                
                return (processingTrialFee ? null : (trialEndDate!=null && !hasTrialExpired ? trialEndDate.addDays(1) : null));
            }
            when else {
                return (opportunityLineItem.Start_Date__c != null &&  opportunityLineItem.Start_Date__c > System.today()) ? opportunityLineItem.Start_Date__c : null;
            }
        }
    }
    /**
    * @description Return the fee attribute end date for the input Opportunity Product
    **/
    private DateTime getFeeAttributeEndDateTime(Opportunity opportunity, OpportunityLineItem opportunityLineItem, PROGRAM_DEVELOPER_NAME programDeveloperName, Boolean processingTrialFee){
        Boolean isTrial = this.isTrial(opportunityLineItem);
        DateTime trialEndDate = isTrial ? this.getTrialEndDate(opportunityLineItem) : null;
        switch on programDeveloperName {
            when Marketplace_Dashpass_Trial {
                return (processingTrialFee ? (trialEndDate!=null ? trialEndDate : null) : null);
            }
            when else {
                return opportunityLineItem.End_Date__c != null ? opportunityLineItem.End_Date__c : null;
            }
        }
    }
    /**
    * @description Return the Flat Fee Cents for the input Opportunity Product and fee name
    **/
    private Integer getFlatFeeCents(Opportunity opportunity, OpportunityLineItem opportunityLineItem, PROGRAM_DEVELOPER_NAME programDeveloperName, FEE_NAME feeName, Boolean isTrial){
        switch on programDeveloperName {
            when Marketplace_Dashpass_Trial {
                return (isTrial ? null : dollarsToCents(opportunity.DashPass_Flat_Fee__c));
            }
            when else {
                switch on feeName {
                    when delivery_fee, pickup_fee {
                        return dollarsToCents(opportunityLineItem.Flat_Fee__c);
                    }
                    when processing_fee {
                        return dollarsToCents(opportunityLineItem.Payment_Processing_Fee__c);
                    }
                    when monthly_fee {
                        return dollarsToCents(opportunityLineItem.Subscription_Fee__c);
                    }
                    when else {
                        return null;
                    }
                }
            }
        }
    }
    /**
    * @description Return the Fee Rate for the input Opportunity Product and fee name
    **/
    private String getFeeRate(Opportunity opportunity, OpportunityLineItem opportunityLineItem, PROGRAM_DEVELOPER_NAME programDeveloperName, FEE_NAME feeName, Boolean isTrial){
        Decimal feeRate = null;
        switch on programDeveloperName {
            when Marketplace_Dashpass_Trial {
                feeRate = (isTrial ? opportunity.Trial_DashPass_Commission__c : opportunity.DashPass_Only_Commission__c);
            }
            when else {
                switch on feeName {
                    when processing_fee {
                        feeRate = opportunityLineItem.Payment_Processing_Rate__c;
                    }
                    when else {
                        feeRate = null;
                    }
                }
            }
        }
        return feeRate!=null ? feeRate.toPlainString() : null;
    }
    /**
    * @description Return the converted Integer value of dollars to cents
    **/
    private Integer dollarsToCents(Decimal input) {
        return input!=null ? (isDollarsToCentsConversionRequired() ? (input * 100).intValue() : input.intValue()) : null;
    }
    /**
    * @description Return the Enum FEE_NAME for the input fee name String value
    **/
    private FEE_NAME getFeeName(String feeNameValue){
        for (FEE_NAME feeName : FEE_NAME.values()){
            if (feeNameValue.equals(feeName.name())){
                return feeName;
            }
        }
        return null;
    }
    /**
    * @description Return the Enum PROGRAM_DEVELOPER_NAME for the input program developer name
    **/
    private PROGRAM_DEVELOPER_NAME getProgramDeveloperName(String programDeveloperName){
        for (PROGRAM_DEVELOPER_NAME programDeveloperNameEnum : PROGRAM_DEVELOPER_NAME.values()){
            if (programDeveloperName.equals(programDeveloperNameEnum.name())){
                return programDeveloperNameEnum;
            }
        }
        return null;
    }
    /**
    * @description Return the eligible opportunity programs
    **/
    private Map<String, MxAffiliateProgram__mdt> getEligibleOpportunityPrograms(Opportunity opportunity){
        Map<String, MxAffiliateProgram__mdt> eligiblePrograms = new Map<String, MxAffiliateProgram__mdt>();
        Boolean isCaviarPlatform = (opportunity.Platform__c!=null && CAVIAR_PLATFORMS.contains(opportunity.Platform__c));
        if (isCaviarPlatform ){
            if (opportunity.Commission__c!=null){
                eligiblePrograms.put(PROGRAM_MARKETPLACE_DELIVERY, CONFIGURED_PROGRAMS.get(PROGRAM_MARKETPLACE_DELIVERY));
            }
            if (opportunity.In_App_Pickup_Commission__c!=null){
                eligiblePrograms.put(PROGRAM_MARKETPLACE_PICKUP, CONFIGURED_PROGRAMS.get(PROGRAM_MARKETPLACE_PICKUP));
            }
            if ((opportunity.DashPass_Only_Commission__c!=null || opportunity.DashPass_Flat_Fee__c!=null) && opportunity.Trial_DashPass_Commission__c==null){
                eligiblePrograms.put(PROGRAM_MARKETPLACE_DASHPASS_NO_TRIAL, CONFIGURED_PROGRAMS.get(PROGRAM_MARKETPLACE_DASHPASS_NO_TRIAL));
            }
            if (opportunity.Referred_Delivery_Commission__c!=null){
                eligiblePrograms.put(PROGRAM_MARKETPLACE_WEBLINKS_DELIVERY, CONFIGURED_PROGRAMS.get(PROGRAM_MARKETPLACE_WEBLINKS_DELIVERY));
            }
            if (opportunity.Referred_Pickup_Commission__c!=null){
                eligiblePrograms.put(PROGRAM_MARKETPLACE_WEBLINKS_PICKUP, CONFIGURED_PROGRAMS.get(PROGRAM_MARKETPLACE_WEBLINKS_PICKUP));
            }
        }
        return eligiblePrograms;
    }
    /**
    * @description Return the eligible opportunity product programs
    **/
    private Map<String, MxAffiliateProgram__mdt> getEligibleOpportunityProductPrograms(Opportunity opportunity){
        Map<String, MxAffiliateProgram__mdt> eligiblePrograms = new Map<String, MxAffiliateProgram__mdt>();
        Boolean isCaviarPlatform = (opportunity.Platform__c!=null && CAVIAR_PLATFORMS.contains(opportunity.Platform__c));
        Boolean isDoorDashPlatform = (opportunity.Platform__c!=null && DOORDASH_PLATFORMS.contains(opportunity.Platform__c));
        Boolean isDashPassTrial = ((opportunity.DashPass_Only_Commission__c!=null || opportunity.DashPass_Flat_Fee__c!=null) && opportunity.Trial_DashPass_Commission__c!=null);
        if (OPP_REC_TYPE_DEV_NAME_POST_SALE.equals(opportunity.RecordType.DeveloperName)){
            for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems){
                if (CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_DELIVERY).Product_Name__c.equals(opportunityLineItem.Product2.Name)){
                    eligiblePrograms.put(PROGRAM_ONLINE_ORDERING_DELIVERY, CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_DELIVERY));
                }
                if (CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_PICKUP).Product_Name__c.equals(opportunityLineItem.Product2.Name)){
                    eligiblePrograms.put(PROGRAM_ONLINE_ORDERING_PICKUP, CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_PICKUP));
                }
                if (CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_TRIAL_PICKUP_PROMO_PERIOD).Product_Name__c.equals(opportunityLineItem.Product2.Name)){
                    eligiblePrograms.put(PROGRAM_ONLINE_ORDERING_TRIAL_PICKUP_PROMO_PERIOD, CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_TRIAL_PICKUP_PROMO_PERIOD));
                }
                if (CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_TRIAL_DELIVERY_PROMO_PERIOD).Product_Name__c.equals(opportunityLineItem.Product2.Name)){
                    eligiblePrograms.put(PROGRAM_ONLINE_ORDERING_TRIAL_DELIVERY_PROMO_PERIOD, CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_TRIAL_DELIVERY_PROMO_PERIOD));
                }
                if (CONFIGURED_PROGRAMS.get(PROGRAM_MARKETPLACE_DASHPASS_TRIAL).Product_Name__c.equals(opportunityLineItem.Product2.Name) && isCaviarPlatform && isDashPassTrial){
                    eligiblePrograms.put(PROGRAM_MARKETPLACE_DASHPASS_TRIAL, CONFIGURED_PROGRAMS.get(PROGRAM_MARKETPLACE_DASHPASS_TRIAL));
                }
                if (CONFIGURED_PROGRAMS.get(PROGRAM_CONTACTLESS_ORDERING_CAVIAR).Product_Name__c.equals(opportunityLineItem.Product2.Name) && isCaviarPlatform){
                    eligiblePrograms.put(PROGRAM_CONTACTLESS_ORDERING_CAVIAR, CONFIGURED_PROGRAMS.get(PROGRAM_CONTACTLESS_ORDERING_CAVIAR));
                }
                if (CONFIGURED_PROGRAMS.get(PROGRAM_CONTACTLESS_ORDERING_DOORDASH).Product_Name__c.equals(opportunityLineItem.Product2.Name) && isDoorDashPlatform){
                    eligiblePrograms.put(PROGRAM_CONTACTLESS_ORDERING_DOORDASH, CONFIGURED_PROGRAMS.get(PROGRAM_CONTACTLESS_ORDERING_DOORDASH));
                }
                if (CONFIGURED_PROGRAMS.get(PROGRAM_CONTACTLESS_ORDERING_TRIAL_CAVIAR).Product_Name__c.equals(opportunityLineItem.Product2.Name) && isCaviarPlatform){
                    eligiblePrograms.put(PROGRAM_CONTACTLESS_ORDERING_TRIAL_CAVIAR, CONFIGURED_PROGRAMS.get(PROGRAM_CONTACTLESS_ORDERING_TRIAL_CAVIAR));
                }
                if (CONFIGURED_PROGRAMS.get(PROGRAM_CONTACTLESS_ORDERING_TRIAL_DOORDASH).Product_Name__c.equals(opportunityLineItem.Product2.Name) && isDoorDashPlatform){
                    eligiblePrograms.put(PROGRAM_CONTACTLESS_ORDERING_TRIAL_DOORDASH, CONFIGURED_PROGRAMS.get(PROGRAM_CONTACTLESS_ORDERING_TRIAL_DOORDASH));
                }
            }
        }
        return eligiblePrograms;
    }

    /**
     * BZAP-8800: Add "Customer Delivery Fee" if Post Sale Opportunity and includes specific Products
     *
     * @param opportunity the Opportunity
     * @return Map<String, MxAffiliateProgram__mdt>
     */
    private Map<String, MxAffiliateProgram__mdt> getEligibleCustomerDeliveryFee(Opportunity opportunity){
        List<String> productNames = this.getCustomerDeliveryFeeProductNames();

        Map<String, MxAffiliateProgram__mdt> eligiblePrograms = new Map<String, MxAffiliateProgram__mdt>();
        if (opportunity.RecordTypeId.equals(CDdSchemaUtils.OPPORTUNITY_RT.postSaleId())) {
            for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems) {
                if (productNames.contains(opportunityLineItem.Product2.Name)) {
                    eligiblePrograms.put(PROGRAM_NONE, CONFIGURED_PROGRAMS.get(PROGRAM_NONE));
                    break; // only one customer delivery fee, if any product matches
                }
            }
        }

        return eligiblePrograms;
    }


    public Boolean isTrial(Opportunity opportunity){
        return String.isNotBlank(opportunity.Trial_Type__c);
    }
    public Boolean isTrial(OpportunityLineItem opportunityLineItem){
        return String.isNotBlank(opportunityLineItem.Trial_Type__c);
    }
    public Boolean isPromotionalTrial(Opportunity opportunity){
        return String.isNotBlank(opportunity.Trial_Type__c) && TRIAL_TYPE_PROMOTIONAL_PERIOD.equals(opportunity.Trial_Type__c);
    }
    public DateTime getTrialEndDate(Opportunity opportunity){
        if (String.isNotBlank(opportunity.Trial_Type__c) && String.isBlank(opportunity.Length_of_Trial__c)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, String.format(INVALID_LENGTH_OF_TRIAL, new List<String>{'Opportunity', opportunity.name, opportunity.Trial_Type__c}));
        }
        return getTrialEndDate(OPPORTUNITY_TRANSLATE_LENGTH_OF_TRIAL.get(opportunity.Length_of_Trial__c));
    }
    public DateTime getTrialEndDate(OpportunityLineItem opportunityLineItem){
        if (String.isNotBlank(opportunityLineItem.Trial_Type__c) && String.isBlank(opportunityLineItem.Length_of_Trial__c)){
            throw new CDdFeeOnboardingException(CDdFeeOnboardingException.STEP_FEE_ONBOARDING, CDdFeeOnboardingException.ERROR_TYPE_VALIDATION, String.format(INVALID_LENGTH_OF_TRIAL, new List<String>{'Opportunity Product', opportunityLineItem.Name, opportunityLineItem.Trial_Type__c}));
        }
        return getTrialEndDate(OPPORTUNITY_TRANSLATE_LENGTH_OF_TRIAL.get(opportunityLineItem.Length_of_Trial__c));
    }
    private DateTime getTrialEndDate(Opportunity_Translate_Length_Of_Trial__mdt config){
        if (config == null){
            return null;
        }
        if (config.Default_Date_Time__c == null){
            return System.today().addDays(config.Value__c.intValue());
        } else {
            return config.Default_Date_Time__c;
        }
    }
    /**
     * BASD-15548 - Determine if the current trial on the Opportunity record has expired or is it still in effect
     * NOTE: Use this method only if the input Opportunity record is in trial
     * @param Opportunity input opportunity record
     * @return Boolean - return true if the trial has ended
     */
    public Boolean hasTrialExpired(Opportunity opportunity){
        Boolean isTrial = this.isTrial(opportunity);
        DateTime trialEndDate = isTrial ? this.getTrialEndDate(opportunity) : null;
        return isPastDate(trialEndDate);
    }
    /**
     * BASD-15548 - Determine if the current trial on the Opportunity Line record has expired or is it still in effect
     * NOTE: Use this method only if the input Opportunity Line Item record is in trial
     * @param OpportunityLineItem input opportunity line item record
     * @return Boolean - return true if the trial has ended
     */    
    public Boolean hasTrialExpired(OpportunityLineItem opportunityLineItem){
        Boolean isTrial = this.isTrial(opportunityLineItem);
        DateTime trialEndDate = isTrial ? this.getTrialEndDate(opportunityLineItem) : null;
        return isPastDate(trialEndDate);
    }
    /**
     * BASD-15548 - Determine if the input date time is past date
     * @param Datetime input Datetime
     * @return Boolean - return true if the date has passed
     */    
    public Boolean isPastDate(Datetime dt){
        return dt!=null && dt.date() < System.today();        
    }         
    /**
     * Structures a list of Fees as a Map of Programs with related Fees
     *
     * @param feeIds a list of MxAffiliateFeeAttribute__mdt Ids
     * @return a Map of Programs with related Fees (as DeveloperName)
     */
    public Map<String, Set<String>> getProgramsAndFeesMap(List<Id> feeIds) {
        List<MxAffiliateFeeAttribute__mdt> programsAndFees = [select DeveloperName, Program__r.DeveloperName from MxAffiliateFeeAttribute__mdt where Id = :feeIds];
        Map<String, Set<String>> programsAndFeesMap = new Map<String, Set<String>>();
        for (MxAffiliateFeeAttribute__mdt fee : programsAndFees) {
            // Ignore customer delivery fee for this request
            if (!fee.Program__r.DeveloperName.equals(CDdFeeOnboardingService.PROGRAM_NONE)) {
                if (programsAndFeesMap.keySet().contains(fee.Program__r.DeveloperName)) {
                    programsAndFeesMap.get(fee.Program__r.DeveloperName).add(fee.DeveloperName);
                } else {
                    programsAndFeesMap.put(fee.Program__r.DeveloperName, new Set<String> { fee.DeveloperName });
                }
            }
        }
        return programsAndFeesMap;
    }
    /**
     * @description Re-organize the collection of fee ids based on Fee Onboarding API Type
     * @param feeIds a list of MxAffiliateFeeAttribute__mdt Ids
     * @return Map<CDdFeeOnboardingApiType, List<Id>> a Collection of fee Ids by Fee Onboarding API Type
     */
    public Map<CDdFeeOnboardingApiType, List<Id>> getFeeIdsByApiType(List<Id> feeIds) {
        Map<CDdFeeOnboardingApiType, List<Id>> feeIdsByApiType = new Map<CDdFeeOnboardingApiType, List<Id>>();
        for (MxAffiliateFeeAttribute__mdt feeAttr : [   SELECT Id, DeveloperName
                                                        FROM MxAffiliateFeeAttribute__mdt
                                                        WHERE Id IN :feeIds
                                                    ]){
            switch on (feeAttr.DeveloperName){
                when 'Customer_Delivery_Fee' {
                    addFeeIdToApiType(feeIdsByApiType, CDdFeeOnboardingApiType.CX_STOREFRONT_FEE, feeAttr.Id);
                }
                when 'Online_Ordering_Monthly_Fee_01' {
                    addFeeIdToApiType(feeIdsByApiType, CDdFeeOnboardingApiType.MX_STOREFRONT_MONTHLY_FEE, feeAttr.Id);
                }
                when else {
                    addFeeIdToApiType(feeIdsByApiType, CDdFeeOnboardingApiType.MX_PROGRAM_FEE, feeAttr.Id);
                }
            }                                                           
        }
        return feeIdsByApiType;
    }
    /**
     * @description Add the fee id to the appropriate collection of fee ids based on Fee Onboarding API Type
     * @param Map<CDdFeeOnboardingApiType, List<Id>> a Collection of fee Ids by Fee Onboarding API Type
     * @param CDdFeeOnboardingApiType Fee Onboarding API Type
     * @param Id fee id
     * @return 
     */    
    private void addFeeIdToApiType(Map<CDdFeeOnboardingApiType, List<Id>> feeIdsByApiType, CDdFeeOnboardingApiType apiType, Id feeId){
        if (feeIdsByApiType.containsKey(apiType)){
            feeIdsByApiType.get(apiType).add(feeId);
        } else {
            feeIdsByApiType.put(apiType, new List<Id>{feeId});
        }
    }
    /**
     * @description Is dollars to cents conversion required? 
     * This is based on the Billing Country Code. Example: For Japan (JP), dollars to cents conversion is not required
     */
    private Boolean isDollarsToCentsConversionRequired(){
        return !COUNTRY_CODES_TO_EXCLUDE_FROM_DOLLARS_TO_CENTS_CONVERSION.contains(this.billingCountryCode);
    }    
}