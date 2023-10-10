/**
 * @author      Raju
 * @date        June 2022
 * @decription  Test Class for Legal CMS Version PDF Generateor
 */

 @isTest
public class CDdLegalCmsVersionPdfGenControllerTest {
    @IsTest
    static void test1(){
        Legal_CMS_Content__c content1 = CDdLegalCmsTestFactory.createLegalCmsContent(
            CDdLegalCmsTestFactory.PRIVACY_POLICY,
            CDdLegalCmsTestFactory.UNITED_STATES,
            CDdLegalCmsTestFactory.LANG_ENGLISH,
            true
        );

        Legal_CMS_Content_Version__c contentVersion1 = CDdLegalCmsTestFactory.createLegalCmsContentVersion(
            content1.Id,1,0,true
        );

        PageReference pageRef = Page.PDdLegalCmsVersionPdfGenerator;
        pageRef.getParameters().put('recordId', String.valueOf(contentVersion1.Id));
        Test.setCurrentPage(pageRef);

        CDdLegalCmsVersionPdfGenController ctrl = new CDdLegalCmsVersionPdfGenController();

        String expectedContent = CDdLegalCmsTestFactory.PRIVACY_POLICY + CDdLegalCmsTestFactory.PRIVACY_POLICY;
        system.assertEquals(expectedContent, ctrl.displayText,'PDF Content not correct');
    }
}