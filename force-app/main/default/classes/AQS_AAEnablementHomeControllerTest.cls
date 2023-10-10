@isTest
private class AQS_AAEnablementHomeControllerTest {
    
    @istest static void AQS_AAEnablementHomeControllerTest () {

        //tests the email templates and asserts that they have been inserted
        AQS_AAEnablementHomeController aaHomePage = new AQS_AAEnablementHomeController();

        aaHomePage.createTemplates();
        
        List<sbaa__EmailTemplate__c> queriedEmailTemplates = [  SELECT Id, Name, sbaa__TemplateId__c
                                                                FROM sbaa__EmailTemplate__c
                                                                WHERE NAME ='Approval - Quote Approved Notification - AQS'
                                                                LIMIT 1
                                                                ];

        System.assert(queriedEmailTemplates.get(0).Name == 'Approval - Quote Approved Notification - AQS');

        //-------------------------------------
        //tests the record types and compares against the custom setting
        aaHomePage.updateCustomSetting();

        AQS_AA_Enablement_IDs__c recordTypeCustomSetting = AQS_AA_Enablement_IDs__c.getOrgDefaults();

        System.assert(Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('AQS Approved Quote').getRecordTypeId() == recordTypeCustomSetting.AQS_Approved_Quote_RT__c);


        //-------------------------------------
        //tests the email document ID
        aaHomePage.updateEmailLogoId();

        recordTypeCustomSetting = AQS_AA_Enablement_IDs__c.getOrgDefaults();

        System.assert(String.isBlank(recordTypeCustomSetting.AQS_Approval_Email_Logo_ID__c) == true);
        
    }
    
    @istest static void testUpdateEmailLogoId (){
        //-------------------------------------
        //tests the email document ID
        AQS_AAEnablementHomeController aaHomePage = new AQS_AAEnablementHomeController();
        aaHomePage.updateEmailLogoId();

        AQS_AA_Enablement_IDs__c recordTypeCustomSetting = AQS_AA_Enablement_IDs__c.getOrgDefaults();

        System.assert(String.isBlank(recordTypeCustomSetting.AQS_Approval_Email_Logo_ID__c) == true);

		//-------------------------------------
        //tests the record types and compares against the custom setting        
        aaHomePage.updateCustomSetting();

        recordTypeCustomSetting = AQS_AA_Enablement_IDs__c.getOrgDefaults();

        System.assert(Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('AQS Approved Quote').getRecordTypeId() == recordTypeCustomSetting.AQS_Approved_Quote_RT__c);
    }
}