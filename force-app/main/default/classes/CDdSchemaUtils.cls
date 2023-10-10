/**
 * @author Knick
 * @date 3/2020
 * @description Schema Utilities - Efficient calls for obtaining schema information
**/
global class CDdSchemaUtils {

    public class CDdSchemaUtilsException extends Exception {}

    /**
    * @author Knick
    * @date 3/2020
    * @description Initialize SOBJECT_TYPES to contain all Schema information.
    *              RECORD_TYPE_INFO_BY_SOBJECT will be built up as used by callers.
    */
    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();
    public static Map<String, Map<String, Schema.RecordTypeInfo>> RECORD_TYPE_INFO_BY_SOBJECT =
            new Map<String, Map<String, Schema.RecordTypeInfo>>();

    /**
    * @author Knick
    * @date 3/2020
    * @description Obtain the Schema informaton for a particular sObject.
    *              Throws an exception if the sObject does not exist.
    */
    public static Schema.SObjectType getDescribe(String SobjectName) {
        if (SOBJECT_TYPES.containsKey(SobjectName)) return SOBJECT_TYPES.get(SobjectName);
        throw new CDdSchemaUtilsException('Sobject Type: <' + SobjectName + '> does not exist.');
    }

    /**
    * @author Knick
    * @date 3/2020
    * @description Obtain the informaton for all record types for a particular sObject.
    *              Inserts it into RECORD_TYPE_INFO_BY_SOBJECT if it is not yet there.
    */
    public static Map<String, Schema.RecordTypeInfo> getRecordTypeInfosByDeveloperName(String SobjectName) {
        String key = SobjectName.toLowerCase();     // Prevent duplicates for case insensitive data
        if (! RECORD_TYPE_INFO_BY_SOBJECT.containsKey(key)) {
            Schema.SObjectType t = getDescribe(SobjectName);
            RECORD_TYPE_INFO_BY_SOBJECT.put(key, t.getDescribe().getRecordTypeInfosByDeveloperName());
        }
        return RECORD_TYPE_INFO_BY_SOBJECT.get(key);
    }

    /**
    * @author Knick
    * @date 3/2020
    * @description Obtain the informaton for a single record types for a particular sObject.
    *              Throws an exception if the record type does not exist.
    */
    public static Schema.RecordTypeInfo getRecordTypeInfoByDeveloperName(String SobjectName, String DeveloperName) {
        Schema.RecordTypeInfo info = getRecordTypeInfosByDeveloperName(SobjectName).get(DeveloperName);
        if (info != null) return info;
        throw new CDdSchemaUtilsException('Record Type: <' + DeveloperName + '> does not exist on the ' + SobjectName + ' sObject.');
    }

    /**
    * @author Knick
    * @date 3/2020
    * @description Obtain the RecordTypeId by sObject and developer name.
    *              Throws an exception if the record type does not exist.
    * Example: Id RecordTypeId = getRecordTypeIdByDeveloperName('Account', 'Parent_Account');
    */
    public static Id getRecordTypeIdByDeveloperName(String SobjectName, String DeveloperName) {
        return getRecordTypeInfoByDeveloperName(SobjectName, DeveloperName).getRecordTypeId();
    }

    public static String getSObjectTypeNameFromRecordId(Id sId) {
        return sId.getSobjectType().getDescribe().getName();
    }

    /**
     * Example usages:
     *     1) Id enterpriseDriveRecordTypeId = CDdSchemaUtils.ACCOUNT_RT.enterpriseDriveId();
     *     2) Account account = [select Id from account where RecordTypeId = :CDdSchemaUtils.ACCOUNT_RT.enterpriseDriveId()];
     *     3) Account account = [select Id from Account where RecordType.DeveloperName = :CDdSchemaUtils.AccountRTEnum.Dasher.name()];
     *     4) CDdSchemaUtils.AccountEnum recordType = CDdSchemaUtils.AccountRTEnum.Enterprise_Marketplace;
     *        switch on recordType {
     *           when Enterprise_Marketplace, Enterprise_Drive {
     *           }
     *           when Corporate_Customers {
     *           }
     *         }
     */
    public static AccountRT ACCOUNT_RT = new AccountRT();
    public static CampaignRT CAMPAIGN_RT = new CampaignRT();
    public static CaseRT CASE_RT = new CaseRT();
    public static LeadRT LEAD_RT = new LeadRT();
    public static OpportunityRT OPPORTUNITY_RT = new OpportunityRT();
    public static QuoteRT QUOTE_RT = new QuoteRT();
    public static MilestoneRT Milestone_RT = new MilestoneRT();

    public enum AccountRTEnum {
        Business_Development,
        Corp_Dev_Company,
        Corporate_Customers,
        Dasher,
        DoorDash_Drive,
        Enterprise_Drive,
        Enterprise_Marketplace,
        Grandparent_Account,
        Parent_Account,
        PersonAccount,
        Prospect
    }

    public enum CampaignRTEnum {
        Drive,
        Master_Launch,
        Promotion,
        Self_Delivery,
        Work
        // Commented out because Default is a reserved Identifier name
        // Default
    }

    public enum LeadRTEnum {
        DoorDash_Drive_Leads,
        DoorDash_for_Business,
        Master_Lead
    }

    public enum CaseRTEnum {
        Account_Management,
        API,
        Bulk_Upload_Request,
        Caviar_Onboarding,
        Caviar_Support,
        Customer,
        Drive_Activation_Case,
        DTB,
        Marketplace_Onboarding,
        Menu_Update_Request_Web,
        Mx_Marketing_Requests,
        Mx_Tools_Requests,
        Onboarding_Manager_Handoff,
        Photoshoot_Processing,
        POS_Integrations,
        POS_Support,
        Post_Sale_Activations,
        Support_Tool_Requests,
        Tablet_Requests,
        Support_Training,
        Storefront_Onboarding
    }

    public enum OpportunityRTEnum {
        Caviar_Marketplace,
        Corporate,
        Corporate_Approved,
        DoorDash_Drive,
        DoorDash_for_Business,
        Enterprise_Drive,
        Enterprise_Marketplace,
        Franchise_Opportunity,
        ML_Inside_Sales,
        Merchant_Catering,
        Merchant_Promotion,
        Post_Sale,
        Reactivation
    }

    public enum QuoteRTEnum {
        AQS_Draft_Quote,
        AQS_In_Progress_Quote,
        AQS_Approved_Quote
    }

    public enum MilestoneRTEnum {
        Setup_Banking,
        Setup_Menu,
        Activate_Store,
        Ads_Promos,
        Grant_Portal_Access,
        Deliver_Tablet,
        Activations_Checklist
    }

    public class AccountRT {

        public Id getId(AccountRTEnum developerName) {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(developerName.name()).getRecordTypeId();
        }

        public Id businessDevelopmentId() {
            return getId(AccountRTEnum.Business_Development);
        }

        public Id corpDevCompanyId() {
            return getId(AccountRTEnum.Corp_Dev_Company);
        }

        public Id corporateCustomersId() {
            return getId(AccountRTEnum.Corporate_Customers);
        }

        public Id dasherId() {
            return getId(AccountRTEnum.Dasher);
        }

        public Id doorDashDriveId() {
            return getId(AccountRTEnum.DoorDash_Drive);
        }

        public Id enterpriseDriveId() {
            return getId(AccountRTEnum.Enterprise_Drive);
        }

        public Id enterpriseMarketplaceId() {
            return getId(AccountRTEnum.Enterprise_Marketplace);
        }

        public Id grandparentAccountId() {
            return getId(AccountRTEnum.Grandparent_Account);
        }

        public Id parentAccountId() {
            return getId(AccountRTEnum.Parent_Account);
        }

        public Id personAccountId() {
            return getId(AccountRTEnum.PersonAccount);
        }

        public Id prospectId() {
            return getId(AccountRTEnum.Prospect);
        }
    }

    public class CampaignRT {

        public Id getId(CampaignRTEnum developerName) {
            return Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(developerName.name()).getRecordTypeId();
        }

        // Special case to handle 'Defualt' record type
        public Id getId(String developerName) {
            return Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
        }

        public Id driveId() {
            return getId(CampaignRTEnum.Drive);
        }

        public Id masterLaunchId() {
            return getId(CampaignRTEnum.Master_Launch);
        }

        public Id promotionId() {
            return getId(CampaignRTEnum.Promotion);
        }

        public Id selfDeliveryId() {
            return getId(CampaignRTEnum.Self_Delivery);
        }

        public Id workId() {
            return getId(CampaignRTEnum.Work);
        }

        public Id defaultId() {
            return getId('Default');
        }
    }

    public class CaseRT {

        public Id getId(CaseRTEnum developerName) {
            return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(developerName.name()).getRecordTypeId();
        }

        public Id accountManagementId() {
            return getId(CaseRTEnum.Account_Management);
        }

        public Id apiId() {
            return getId(CaseRTEnum.API);
        }
        public Id bulkUploadRequestId() {
            return getId(CaseRTEnum.Bulk_Upload_Request);
        }

        public Id caviarOnboardingId() {
            return getId(CaseRTEnum.Caviar_Onboarding);
        }

        public Id caviarSupportId() {
            return getId(CaseRTEnum.Caviar_Support);
        }

        public Id customerId() {
            return getId(CaseRTEnum.Customer);
        }

        public Id driveActivationCaseId() {
            return getId(CaseRTEnum.Drive_Activation_Case);
        }

        public Id dtbId() {
            return getId(CaseRTEnum.DTB);
        }

        public Id marketplaceOnboardingId() {
            return getId(CaseRTEnum.Marketplace_Onboarding);
        }

        public Id menuUpdateRequestWebId() {
            return getId(CaseRTEnum.Menu_Update_Request_Web);
        }

        public Id mxMarketingRequestsId() {
            return getId(CaseRTEnum.Mx_Marketing_Requests);
        }

        public Id mxToolsRequestsId() {
            return getId(CaseRTEnum.Mx_Tools_Requests);
        }

        public Id onboardingManagerHandoffId() {
            return getId(CaseRTEnum.Onboarding_Manager_Handoff);
        }

        public Id photoshootProcessingId() {
            return getId(CaseRTEnum.Photoshoot_Processing);
        }

        public Id posIntegrationsId() {
            return getId(CaseRTEnum.POS_Integrations);
        }

        public Id posSupportId() {
            return getId(CaseRTEnum.POS_Support);
        }

        public Id postSaleActivationsId() {
            return getId(CaseRTEnum.Post_Sale_Activations);
        }

        public Id supportToolRequestsId() {
            return getId(CaseRTEnum.Support_Tool_Requests);
        }

        public Id tabletRequestsId() {
            return getId(CaseRTEnum.Tablet_Requests);
        }

        public Id supportTrainingId() {
            return getId(CaseRTEnum.Support_Training);
        }

        public Id storefrontOnboardingId() {
            return getId(CaseRTEnum.Storefront_Onboarding);
        }
    }

    public class LeadRT {

        public Id getId(LeadRTEnum developerName) {
            return Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(developerName.name()).getRecordTypeId();
        }

        public Id doorDashDriveLeadsId() {
            return getId(LeadRTEnum.DoorDash_Drive_Leads);
        }

        public Id doorDashForBusinessId() {
            return getId(LeadRTEnum.DoorDash_for_Business);
        }

        public Id masterLead() {
            return getId(LeadRTEnum.Master_Lead);
        }

    }

    public class OpportunityRT {

        public Id getId(OpportunityRTEnum developerName) {
            return Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(developerName.name()).getRecordTypeId();
        }

        public Id caviarMarketplaceId() {
            return getId(OpportunityRTEnum.Caviar_Marketplace);
        }

        public Id corporateId() {
            return getId(OpportunityRTEnum.Corporate);
        }

        public Id corporateApprovedId(){
            return getId(OpportunityRTEnum.Corporate_Approved);
        }

        public Id doorDashDriveId() {
            return getId(OpportunityRTEnum.DoorDash_Drive);
        }

        public Id doorDashForBusinessId() {
            return getId(OpportunityRTEnum.DoorDash_for_Business);
        }

        public Id enterpriseDriveId() {
            return getId(OpportunityRTEnum.Enterprise_Drive);
        }

        public Id enterpriseMarketplaceId() {
            return getId(OpportunityRTEnum.Enterprise_Marketplace);
        }

        public Id franchiseOpportunityId() {
            return getId(OpportunityRTEnum.Franchise_Opportunity);
        }

        public Id mlInsideSalesId() {
            return getId(OpportunityRTEnum.ML_Inside_Sales);
        }

        public Id merchantCateringId() {
            return getId(OpportunityRTEnum.Merchant_Catering);
        }

        public Id merchantPromotionId() {
            return getId(OpportunityRTEnum.Merchant_Promotion);
        }

        public Id postSaleId() {
            return getId(OpportunityRTEnum.Post_Sale);
        }

        public Id reactivationId() {
            return getId(OpportunityRTEnum.Reactivation);
        }
    }

    public class QuoteRT {
        public Id getId(QuoteRTEnum developerName) {
            return Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get(developerName.name()).getRecordTypeId();
        }

        public Id draftId(){
            return getId(QuoteRTEnum.AQS_Draft_Quote);
        }

        public Id inProgressId(){
            return getId(QuoteRTEnum.AQS_In_Progress_Quote);
        }

        public Id approvedId(){
            return getId(QuoteRTEnum.AQS_Approved_Quote);
        }
    }
    public class MileStoneRT {
        public Id getId(MilestoneRTEnum developerName) {
            return Schema.SObjectType.Milestone__c.getRecordTypeInfosByDeveloperName().get(developerName.name()).getRecordTypeId();
        }

        public Id setupBankingId() {
            return getId(MilestoneRTEnum.Setup_Banking);
        }

        public Id setupMenuId(){
            return getId(MilestoneRTEnum.Setup_Menu);
        }

        public Id adsPromosId(){
            return getId(MilestoneRTEnum.Ads_Promos);
        }
        public Id grantPortalAccessId(){
            return getId(MilestoneRTEnum.Grant_Portal_Access);
        }

        public Id activateStoreId(){
            return getId(MilestoneRTEnum.Activate_Store);
        }
        public Id deliverTabletId(){
            return getId(MilestoneRTEnum.Deliver_Tablet);
        }
        public Id activationsChecklistId(){
            return getId(MilestoneRTEnum.Activations_Checklist);
        }
    }

}