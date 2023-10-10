/**
 * @author      Raju
 * @date        June 2022
 * @decription  Test Class for Legal CMS Content app's custom lwc features
 */
@isTest
public with sharing class CDdLegalCmsVersionControllerTest {
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
        CDdLegalCmsVersionController.publishContentVersion(contentVersion1.Id,content1.Id);

        Legal_CMS_Content_Version__c contentVersion = CDdLegalCmsVersionController.getPublishedVersion(content1.Id);
        system.assertNotEquals(null, contentVersion, 'Content Version is null');

        Legal_CMS_Content__c content = CDdLegalCmsVersionController.getLegalCmsContentWithPublishedVersion(content1.Id);
        system.assertNotEquals(null, content, 'Content is null');
        system.assertNotEquals(null, content.Legal_CMS_Content_Versions__r, 'Content\'s versions is null');
        system.assert(!content.Legal_CMS_Content_Versions__r.isEmpty(), 'Content\'s version is not published');

        Legal_CMS_Content_Version__c newContentVersion = CDdLegalCmsTestFactory.createLegalCmsContentVersion(
            content1.Id,2,0,true
        );

        CDdLegalCmsVersionController.publishContentVersion(newContentVersion.Id,content1.Id);

        Map<Id,Legal_CMS_Content_Version__c> toVerifyMap = new Map<Id,Legal_CMS_Content_Version__c>(
                                                [SELECT Id,Status__c,Previous_Published__c
                                                   FROM Legal_CMS_Content_Version__c
                                                  WHERE Id = :newContentVersion.Id OR Id = :contentVersion1.Id]);

        Legal_CMS_Content_Version__c toVerifyPublished = toVerifyMap.get(newContentVersion.Id);
        Legal_CMS_Content_Version__c toVerifyArchived = toVerifyMap.get(contentVersion1.Id);
        system.assertEquals(CDdSupportConstants.STATUS_PUBLISHED, toVerifyPublished.Status__c, 'Content version status is not published');
        system.assertEquals(toVerifyArchived.Id, toVerifyPublished.Previous_Published__c, 'Previous Published is wrong');
        system.assertEquals(CDdSupportConstants.STATUS_ARCHIVED, toVerifyArchived.Status__c, 'Content version status is not published');
    }

    @IsTest
    static void testVisibilityCode(){
        // Just doing code coverage now as object / object security does not exist in prod
        // Can uncomment actual test method with asserts when object gets deployed to prod

        CDdLegalCmsVersionController.canPublish();
        CDdLegalCmsVersionController.canEditContentVersion();

        /*List<PermissionSetAssignment> superUser =
            [SELECT ID,AssigneeId from PermissionSetAssignment where PermissionSet.Name = 'Legal_CMS_Content_Super_User' LIMIT 1];
        if (!superUser.isEmpty()) {
            System.runAs(new User(Id=superUser[0].AssigneeId)) {
                system.assertEquals(true, CDdLegalCmsVersionController.canPublish(), 'Super user should be able to publish versions');
                system.assertEquals(true, CDdLegalCmsVersionController.canEditContentVersion(), 'Super user should be able to update versions');
            }
        }

        List<PermissionSetAssignment> standardUser =
            [SELECT ID,AssigneeId from PermissionSetAssignment where PermissionSet.Name = 'Legal_CMS_Content_Standard_User' LIMIT 1];
        if (!standardUser.isEmpty()) {
            System.runAs(new User(Id=standardUser[0].AssigneeId)) {
                system.assertEquals(false, CDdLegalCmsVersionController.canPublish(), 'Standard user should not be able to publish versions');
                system.assertEquals(true, CDdLegalCmsVersionController.canEditContentVersion(), 'Standard user should be able to update versions');
            }
        }*/
    }
}