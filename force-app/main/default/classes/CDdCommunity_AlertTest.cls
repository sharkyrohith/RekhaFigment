@isTest
public with sharing class CDdCommunity_AlertTest {
   public static testMethod void testAlerts(){
        

        List<CommunityAlert__c> caList = new List<CommunityAlert__c>();
        caList.add(new CommunityAlert__c(Community__c = 'Customer Community', All_Pages__c = true, Active__c = true, Language__c = 'en_US'));
        caList.add(new CommunityAlert__c(Language__c = 'en_US', Internal_Alert__c = true, Active__c = true, Alert_Type__c = 'Outage'));
        insert caList;
        
        Test.startTest();
        List<CommunityAlert__c> alts = CDdCommunity_AlertController.getCommunityAlert('en_US', 'test', false);
        System.assertEquals(1, alts.size(), 'Number of alerts is more than expected.');
        System.assert(alts != null);

        Integer refreshAlertInterval = CDdCommunity_AlertController.getInternalAlertRefreshInternal();
        System.assert(refreshAlertInterval != null, 'Internal Alert Refresh Interval should not be null');

        List<CommunityAlert__c> internalAlerls = CDdCommunity_AlertController.getCommunityAlert(null, null, true);
        System.assertEquals(1, internalAlerls.size(), 'Number of internal alerts is more than expected.');
        
        alts = CDdCommunity_AlertController.getCommunityAlert('test', 'test', false);
        System.assert(alts == null);

        Support_Feature_Flag__c flags = Support_Feature_Flag__c.getInstance();
        flags.Use_Community_Alert_Cache__c = true;
        insert flags;

        internalAlerls = CDdCommunity_AlertController.getCommunityAlert(null, null, true);
        System.assertEquals(1, internalAlerls.size(), 'Number of internal alerts is more than expected.');

        alts = CDdCommunity_AlertController.getCommunityAlert('test', 'test', false);
        System.assert(alts == null);

        Test.stopTest();
    }
}