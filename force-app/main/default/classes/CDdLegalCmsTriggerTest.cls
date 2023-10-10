/**
 * @author      Raju
 * @date        June 2022
 * @decription  Test Class for Legal CMS Content/Legal CMS Content Version Trigger
 */
@isTest
public with sharing class CDdLegalCmsTriggerTest {

    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CTrLegalCmsUpdateNameAndUniqueKey.class
    };

    @IsTest
    static void testDefaultFlagChange(){
        Legal_CMS_Content__c content1 = CDdLegalCmsTestFactory.createLegalCmsContent(
            CDdLegalCmsTestFactory.PRIVACY_POLICY,
            CDdLegalCmsTestFactory.UNITED_STATES,
            CDdLegalCmsTestFactory.LANG_SPANISH,
            true
        );
        Legal_CMS_Content__c verifyContent1 = [SELECT Id,Default_Language_For_Country__c
            FROM Legal_CMS_Content__c WHERE Id = :content1.Id];
        system.assertEquals(true, verifyContent1.Default_Language_For_Country__c, 'Default Language flag was not set');

        Legal_CMS_Content__c content2 = CDdLegalCmsTestFactory.createLegalCmsContent(
            CDdLegalCmsTestFactory.PRIVACY_POLICY,
            CDdLegalCmsTestFactory.UNITED_STATES,
            CDdLegalCmsTestFactory.LANG_ENGLISH,
            false
        );
        content2.Default_Language_For_Country__c = true;
        insert content2;

        verifyContent1 = [SELECT Id,Default_Language_For_Country__c
            FROM Legal_CMS_Content__c WHERE Id = :content1.Id];
        system.assertEquals(false, verifyContent1.Default_Language_For_Country__c, 'Default Language flag was not updated');
        Legal_CMS_Content__c verifyContent2 = [SELECT Id,Default_Language_For_Country__c
            FROM Legal_CMS_Content__c WHERE Id = :content2.Id];
        system.assertEquals(true, verifyContent2.Default_Language_For_Country__c, 'Default Language flag was not set');
    }

    @IsTest
    static void validateDelete(){
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
        Legal_CMS_Content_Version__c contentVersion2 = CDdLegalCmsTestFactory.createLegalCmsContentVersion(
            content1.Id,1,0,true
        );
        List<PermissionSetAssignment> superUser =
            [SELECT ID,AssigneeId from PermissionSetAssignment where PermissionSet.Name = 'Legal_CMS_Content_Standard_User' and Assignee.IsActive = true LIMIT 1];
        if (!superUser.isEmpty()) {
            system.runAs(new User(Id=superUser[0].AssigneeId)) {
                try {
                    delete contentVersion1;
                    system.assert(false,'Should not come here');
                } catch (Exception ex) {
                    system.assert(ex.getMessage().contains('Only records with status \'Draft\' can be deleted.'));
                }
                try {
                    delete contentVersion2;
                    system.assert(true,'Should come here');
                } catch (Exception ex) {
                    system.assert(false,'Should not come here');
                }
            }
        }
        List<User> someAdmin = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        system.runAs(someAdmin[0]) {
            try {
                delete contentVersion1;
                system.assert(true,'Should come here');
            } catch (Exception ex) {
                system.assert(false,'Should not come here:' + ex.getMessage());
            }
        }
    }
}