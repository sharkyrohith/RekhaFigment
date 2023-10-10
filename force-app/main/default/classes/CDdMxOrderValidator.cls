/********************************************************************************************************************
* @author Sriram
* @date 04/06/2022
*
* @group Merchant Services
*
* @description Validator for Mx Order
*
**************************************************************************************************************************************/
public class CDdMxOrderValidator {
    /**
     * Define enum here
     */
    public enum VALIDATION_STEP {
        ACCOUNT_RECORD_TYPE_VALID,
        ADDRESS_CONFIRMATION,
        ADDRESS_IN_COVERAGE,
        CONTACT_EMAIL_EXISTS,
        CONTACT_FIRST_AND_LAST_NAME_EXISTS,
        CONTACT_EXISTS,
        CONTACT_PHONE_NUMBER_EXISTS,
        MILESTONE_BLOCKED_REVIEW_AND_TRIAGE,
        MILESTONE_BLOCKED_SETUP_STORE,
        OPPORTUNITY_EXISTS,
        REGION_EXISTS,
        PRINTER_ELIGIBILITY,
        SHIPPING_STATE_EXISTS,
        SHIPPING_TYPE_EXISTS,
        STARTING_POINT_AVAILABLE,
        STORE_EXISTS,
        SUB_MARKET_EXISTS,
        TABLET_PASSWORD_EXISTS,
        TABLET_USERNAME_EXISTS
    }
    /**
     * Define static variables here
     */
    public static Map<VALIDATION_STEP, Mx_Order_Validation_Config__mdt> VALIDATION_CONFIGURATION;
    /**
     * Define class variables here
     */
    private Map<Id, Mx_Order__c> mxOrders;
    private CDdMxOrderAccountHelper accountHelper;
    private Map<Id, List<String>> validationErrors;
    private Map<Id, Boolean> opportunityVsPrinterEligibleStatus;
    /**
     * Perform static block execution here
     */
    static {
        VALIDATION_CONFIGURATION = new Map<VALIDATION_STEP, Mx_Order_Validation_Config__mdt>();
        Map<String, Mx_Order_Validation_Config__mdt> configurations = new Map<String, Mx_Order_Validation_Config__mdt>();
        for (Mx_Order_Validation_Config__mdt v : [  SELECT Label, Validation_Step__c, Error_Message__c
                                                    FROM Mx_Order_Validation_Config__mdt
                                                    WHERE Is_Active__c = TRUE
                                                ]){
            configurations.put(v.Validation_Step__c, v);
        }
        for (VALIDATION_STEP validationStepEnum: VALIDATION_STEP.values()) {
            String validationStepStr = validationStepEnum.name();
            if (configurations.containsKey(validationStepStr)) {
                VALIDATION_CONFIGURATION.put(validationStepEnum, configurations.get(validationStepStr));
            }
        }
    }
    /**
     * Default Constructor
     * @param CDdMxOrderAccountHelper accountHelper
     * @param Map<Id, Mx_Order__c> mxOrders
     * @return
     */
    public CDdMxOrderValidator(CDdMxOrderAccountHelper accountHelper, Map<Id, Mx_Order__c> mxOrders) {
        this.mxOrders = mxOrders;
        this.accountHelper = accountHelper;
        this.validationErrors = new Map<Id, List<String>>();
    }
    /**
     * Validate the Mx Orders
     * @param
     * @return
     */
    public Map<Id, List<String>> validate(){
        this.opportunityVsPrinterEligibleStatus = CDdMxSxCaseHelper.isMxEligibleForPrinterForCases(this.accountHelper.caseIdSet);
        for (Mx_Order__c mxOrder : this.mxOrders.values()){
            this.validate(mxOrder);
        }
        return this.validationErrors;
    }
    /**
     * Validate the Mx Order
     * @param Mx_Order__c mxOrder
     * @return
     */
    private void validate(Mx_Order__c mxOrder){
        Id accountId = mxOrder.Account__c;
        for (VALIDATION_STEP step : VALIDATION_CONFIGURATION.keySet()){
            switch on step {
                when ACCOUNT_RECORD_TYPE_VALID {
                    if (!CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS.contains(mxOrder.Account__r.RecordTypeId)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String> { mxOrder.Account__r.RecordType.Name });
                    }
                }
                when ADDRESS_IN_COVERAGE {
                    if (!this.accountHelper.isAddressInCoverage(accountId)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when CONTACT_EMAIL_EXISTS {
                    if (String.isNotBlank(mxOrder.Contact__c) && String.isBlank(mxOrder.Contact_Email__c)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when CONTACT_FIRST_AND_LAST_NAME_EXISTS {
                    if (String.isNotBlank(mxOrder.Contact__c) && (String.isBlank(mxOrder.Contact_First_Name__c) || String.isBlank(mxOrder.Contact_Last_Name__c))){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when CONTACT_EXISTS {
                    if (String.isBlank(mxOrder.Contact__c)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when CONTACT_PHONE_NUMBER_EXISTS {
                    if (String.isNotBlank(mxOrder.Contact__c) && String.isBlank(mxOrder.Contact_Phone__c)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when MILESTONE_BLOCKED_REVIEW_AND_TRIAGE {
                    if (CDdMxSxConstants.MILESTONE_APPLICABLE_CASE_REQUEST_TYPES.contains(mxOrder.Case__r.Request_Type__c)
                        && this.accountHelper.hasMilestones(accountId)
                        && this.accountHelper.isMilestoneBlocked(accountId, CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when MILESTONE_BLOCKED_SETUP_STORE {
                    if (CDdMxSxConstants.MILESTONE_APPLICABLE_CASE_REQUEST_TYPES.contains(mxOrder.Case__r.Request_Type__c)
                        && this.accountHelper.hasMilestones(accountId)
                        && this.accountHelper.isMilestoneBlocked(accountId, CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when OPPORTUNITY_EXISTS {
                    if (String.isNotBlank(mxOrder.Case__c) && !CDdMxSxConstants.LEMONADE_CASE_ORIGINS.contains(mxOrder.Case__r.Origin) && String.isBlank(mxOrder.Case__r.Opportunity_Name__c) && !CDdMxSxConstants.STORE_ORDER_PROTOCOL.contains(mxOrder.Store_Order_Protocol__c)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when PRINTER_ELIGIBILITY {
                    if (String.isNotBlank(mxOrder.Case__r.Request_Type__c) && CDdMxSxConstants.CASE_REQUEST_TYPES_FOR_INCLUSION_OF_PRINTER.contains(mxOrder.Case__r.Request_Type__c)){
                        if (CDdMxSxConstants.LEMONADE_CASE_ORIGINS.contains(mxOrder.Case__r.Origin)){
                            if(!CDdMxSxCaseHelper.byPassSendPrinterValidationsForUser() && !this.accountHelper.isAccountEligibleForPrinter(accountId)){
                                this.addErrorMessage(mxOrder.Id, step, new List<String>());
                            }
                        } else if (!this.opportunityVsPrinterEligibleStatus.containsKey(mxOrder.Case__r.Opportunity_Name__c) ||  !this.opportunityVsPrinterEligibleStatus.get(mxOrder.Case__r.Opportunity_Name__c)){
                            this.addErrorMessage(mxOrder.Id, step, new List<String>());
                        }
                    }
                }
                when REGION_EXISTS {
                    if (!CDdMxSxConstants.LEMONADE_CASE_ORIGINS.contains(mxOrder.Case__r.Origin) && !this.accountHelper.hasRegion(accountId)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when SHIPPING_STATE_EXISTS {
                    if (!CDdMxSxConstants.MX_ORDER_SHIPPING_STATE_VALIDATION_COUNTRY_CODES_TO_EXCLUDE.contains(mxOrder.Country_Code__c)
                        && String.isNotBlank(mxOrder.Case__c)
                        && (String.isBlank(mxOrder.Case__r.Return_Shipping_Address_State__c)
                        || String.isBlank(mxOrder.State__c ))){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when SHIPPING_TYPE_EXISTS {
                    if (String.isNotBlank(mxOrder.Case__c) && String.isBlank(mxOrder.Case__r.Shipping_Type__c)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when STARTING_POINT_AVAILABLE {
                    if (!this.accountHelper.hasStartingPoint(accountId)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when STORE_EXISTS {
                    if (!this.accountHelper.hasStore(accountId)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when SUB_MARKET_EXISTS {
                    if (!CDdMxSxConstants.LEMONADE_CASE_ORIGINS.contains(mxOrder.Case__r.Origin) && !this.accountHelper.hasSubmarket(accountId)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when TABLET_PASSWORD_EXISTS {
                    if (!this.accountHelper.hasTabletPassword(accountId)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
                when TABLET_USERNAME_EXISTS {
                    if (!this.accountHelper.hasTabletUsername(accountId)){
                        this.addErrorMessage(mxOrder.Id, step, new List<String>());
                    }
                }
            }
        }
    }
    /**
     * @description Add the error message to the Validation Errors Collection (Map) with key as Mx Order Id
     * @param Id mxOrderId
     * @param VALIDATION_STEP step
     * @param List<Object> param
     * @return
     */
    private void addErrorMessage(Id mxOrderId, VALIDATION_STEP step, List<Object> params){
        String errorMessage = String.format(VALIDATION_CONFIGURATION.get(step).Error_Message__c, params);
        if (this.validationErrors.containsKey(mxOrderId)){
            this.validationErrors.get(mxOrderId).add(errorMessage);
        } else {
            this.validationErrors.put(mxOrderId, new List<String>{ errorMessage });
        }
    }
}