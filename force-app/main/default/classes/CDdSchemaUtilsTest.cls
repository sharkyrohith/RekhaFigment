/**
 * @description       :
 * @author            : Jose Vega
 * @last modified on  : 01-17-2023
 * @last modified by  : Jose Vega
**/
@isTest

        /**
        * @author Knick
        * @description Test methods for Schema Utilities
        */
public class CDdSchemaUtilsTest {

    public static final String existingSobjectWithRecordTypes = 'Case';
    public static final String existingRecordTypeDeveloperName = 'Menu_Update_Request_Web';

    public static testMethod void sObjectTest() {
        system.assertNotEquals(null, CDdSchemaUtils.getDescribe('Account'), 'CDdSchemaUtils could not find the Account sObject.');
        system.assertNotEquals(null, CDdSchemaUtils.getRecordTypeInfosByDeveloperName(existingSobjectWithRecordTypes));
        system.assertNotEquals(null, CDdSchemaUtils.getRecordTypeInfoByDeveloperName(existingSobjectWithRecordTypes,existingRecordTypeDeveloperName));
        system.assertNotEquals(null, CDdSchemaUtils.getRecordTypeIdByDeveloperName(existingSobjectWithRecordTypes,existingRecordTypeDeveloperName));
    }

    public static testMethod void ExceptionTest() {
        try {
            Schema.SObjectType badType = CDdSchemaUtils.getDescribe('NoSuchSobject');
            system.assertEquals(null, badType, 'There should be no Schema information defined for NoSuchSobject.');
        }
        catch (Exception eX) {
            system.assertEquals('Sobject Type: <NoSuchSobject> does not exist.', eX.getMessage());
        }
        try {
            Map<String, Schema.RecordTypeInfo> badType = CDdSchemaUtils.getRecordTypeInfosByDeveloperName('NoSuchSobject');
            system.assertEquals(null, badType, 'There should be no Record Type information defined for NoSuchSobject.');
        }
        catch (Exception eX) {
            system.assertEquals('Sobject Type: <NoSuchSobject> does not exist.', eX.getMessage());
        }
        try {
            Schema.RecordTypeInfo badRecordType = CDdSchemaUtils.getRecordTypeInfoByDeveloperName(existingSobjectWithRecordTypes,'NoSuchRecordType');
            system.assertEquals(null, badRecordType, 'There should be no Record Type information defined for NoSuchRecordType.');
        }
        catch (Exception eX) {
            system.assertEquals('Record Type: <NoSuchRecordType> does not exist on the ' + existingSobjectWithRecordTypes + ' sObject.', eX.getMessage());
        }
        try {
            Id badRecordType = CDdSchemaUtils.getRecordTypeIdByDeveloperName(existingSobjectWithRecordTypes,'NoSuchRecordType');
            system.assertEquals(null, badRecordType, 'There should be no Record Type Id returned for NoSuchRecordType.');
        }
        catch (Exception eX) {
            system.assertEquals('Record Type: <NoSuchRecordType> does not exist on the ' + existingSobjectWithRecordTypes + ' sObject.', eX.getMessage());
        }
    }

    public static testMethod void testIdAccessors() {
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.businessDevelopmentId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.corpDevCompanyId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.corporateCustomersId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.dasherId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.enterpriseDriveId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.grandparentAccountId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.parentAccountId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.personAccountId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.ACCOUNT_RT.prospectId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CAMPAIGN_RT.driveId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CAMPAIGN_RT.masterLaunchId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CAMPAIGN_RT.promotionId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CAMPAIGN_RT.workId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.accountManagementId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.apiId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.bulkUploadRequestId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.caviarOnboardingId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.caviarSupportId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.customerId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.driveActivationCaseId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.dtbId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.menuUpdateRequestWebId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.mxMarketingRequestsId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.mxToolsRequestsId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.onboardingManagerHandoffId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.photoshootProcessingId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.posIntegrationsId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.posSupportId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.postSaleActivationsId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.supportToolRequestsId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.CASE_RT.tabletRequestsId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.caviarMarketplaceId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.corporateId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.doorDashDriveId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.enterpriseDriveId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.merchantCateringId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.merchantPromotionId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.postSaleId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.OPPORTUNITY_RT.reactivationId(), 'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.QUOTE_RT.draftId(),'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.QUOTE_RT.inProgressId(),'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.QUOTE_RT.approvedId(),'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.Milestone_RT.setupBankingId(),'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.Milestone_RT.setupMenuId(),'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.Milestone_RT.adsPromosId(),'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.Milestone_RT.grantPortalAccessId(),'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.Milestone_RT.activateStoreId(),'Unexpected Id');
        System.assertNotEquals(null, CDdSchemaUtils.Milestone_RT.deliverTabletId(),'Unexpected Id');
    }
}