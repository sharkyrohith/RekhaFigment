/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 6/14/2020.
 *
 * Utility classes for retrieving Account and Case record types in a strongly-typed manner.
 */
@IsTest
public with sharing class CDdRecordTypeTest {

    @IsTest
    public static void testAll() {
        CDdRecordTypeAccount.businessDevelopment();
        CDdRecordTypeAccount.corpDevCompany();
        CDdRecordTypeAccount.corporateCustomers();
        CDdRecordTypeAccount.dasher();
        CDdRecordTypeAccount.doorDashDrive();
        CDdRecordTypeAccount.enterpriseDrive();
        CDdRecordTypeAccount.enterpriseMarketplace();
        CDdRecordTypeAccount.grandparentAccount();
        CDdRecordTypeAccount.parentAccount();
        CDdRecordTypeAccount.personAccount();
        CDdRecordTypeAccount.prospect();

        CDdRecordTypeCase.accountManagement();
        CDdRecordTypeCase.api();
        CDdRecordTypeCase.bulkUploadRequest();
        CDdRecordTypeCase.caviarOnboarding();
        CDdRecordTypeCase.caviarSupport();
        CDdRecordTypeCase.customer();
        CDdRecordTypeCase.dtb();
        CDdRecordTypeCase.menuUpdateRequestWeb();
        CDdRecordTypeCase.mxMarketingRequests();
        CDdRecordTypeCase.mxToolsRequests();
        CDdRecordTypeCase.onboardingManagerHandoff();
        CDdRecordTypeCase.photoshootProcessing();
        CDdRecordTypeCase.posIntegrations();
        CDdRecordTypeCase.posSupport();
        CDdRecordTypeCase.postSaleActivations();
        CDdRecordTypeCase.supportToolRequests();
        CDdRecordTypeCase.tabletRequests();
    }
}