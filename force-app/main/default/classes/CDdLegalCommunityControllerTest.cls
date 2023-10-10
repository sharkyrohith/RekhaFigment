/**
 * @author      Raju
 * @date        June 2022
 * @decription  Test Class for Legal Community related lwc
 */
@isTest
public with sharing class CDdLegalCommunityControllerTest {
    public static Legal_CMS_Content__c content1;
    public static Legal_CMS_Content__c content2;
    public static Legal_CMS_Content_Version__c contentVersion1;
    public static Legal_CMS_Content_Version__c contentVersion2;

    @TestSetup
    static void testSetup(){
        content1 = CDdLegalCmsTestFactory.createLegalCmsContent(
            CDdLegalCmsTestFactory.PRIVACY_POLICY,
            CDdLegalCmsTestFactory.UNITED_STATES,
            CDdLegalCmsTestFactory.LANG_ENGLISH,
            false
        );
        content2 = CDdLegalCmsTestFactory.createLegalCmsContent(
            CDdLegalCmsTestFactory.PRIVACY_POLICY,
            CDdLegalCmsTestFactory.CANADA,
            CDdLegalCmsTestFactory.LANG_ENGLISH,
            false
        );
        insert new List<Legal_CMS_Content__c>{content1,content2};

        contentVersion1 = CDdLegalCmsTestFactory.createLegalCmsContentVersion(
            content1.Id,1,0,false
        );
        contentVersion2 = CDdLegalCmsTestFactory.createLegalCmsContentVersion(
            content2.Id,1,0,false
        );
        insert new List<Legal_CMS_Content_Version__c>{contentVersion1,contentVersion2};

        CDdLegalCmsVersionController.publishContentVersion(contentVersion1.Id,content1.Id);
        CDdLegalCmsVersionController.publishContentVersion(contentVersion2.Id,content2.Id);

        Legal_CMS_Content_Version__c newContentVersion = CDdLegalCmsTestFactory.createLegalCmsContentVersion(
            content1.Id,2,0,false
        );
        //set effective date in the future to allow for multipel versions to be viewable
        newContentVersion.Effective_Date__c = Date.today() + 10;
        insert newContentVersion;

        CDdLegalCmsVersionController.publishContentVersion(newContentVersion.Id,content1.Id);
    }

    @IsTest
    static void test1(){
        CDdLegalCommunityController.PicklistWrapper options = CDdLegalCommunityController.getPicklistOptions(
            CDdLegalCmsTestFactory.PRIVACY_POLICY,CDdLegalCmsTestFactory.US,CDdLegalCmsTestFactory.LANG_IETF_EN_US
        );

        system.assert(options.countryOptions.containsKey(CDdLegalCmsTestFactory.US),'US Picklist does not exist');
        system.assert(options.countryOptions.containsKey(CDdLegalCmsTestFactory.CA),'CA Picklist does not exist');
        system.assert(options.languageOptions.containsKey(CDdLegalCmsTestFactory.US),'US Language Picklist does not exist');
        system.assert(options.languageOptions.containsKey(CDdLegalCmsTestFactory.CA),'CA Language Picklist does not exist');

        CDdLegalCommunityController.ContentWrapper content = CDdLegalCommunityController.getLegalContent(
            CDdLegalCmsTestFactory.PRIVACY_POLICY,CDdLegalCmsTestFactory.US,CDdLegalCmsTestFactory.LANG_IETF_EN_US
        );
        String expectedContent = CDdLegalCmsTestFactory.PRIVACY_POLICY + CDdLegalCmsTestFactory.PRIVACY_POLICY;
        system.assertEquals(expectedContent, content.currentVersionContent,'Current Content not correct');
        system.assertEquals(expectedContent, content.previousVersionContent,'Previous Content not correct');
    }
}