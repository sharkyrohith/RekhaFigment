public with sharing class CDdCampaignMemberTriggerHandler {
    public Static Integer cpuUsageCMTriggerHandler = 0;
    public static final Feature_Flags__c featureFlag = Feature_Flags__c.getInstance();

    public static void beforeInsert(List<CampaignMember> newList) {
        cpuUsageCMTriggerHandler = Limits.getCpuTime();
        CDdCampaignMemberTriggerHelper.generateLeads(newList);
        System.debug('><><><><><><><><><><><><><> CDdCampaignMemberTriggerHelper.generateLeads = ' + (Limits.getCpuTime() - cpuUsageCMTriggerHandler));
    }

    public static void afterInsert(List<CampaignMember> newList) {
        cpuUsageCMTriggerHandler = Limits.getCpuTime();
        CDdCampaignMemberTriggerHelper.removeContacts(newList);
        System.debug('><><><><><><><><><><><><><> CDdCampaignMemberTriggerHelper.removeContacts = ' + (Limits.getCpuTime() - cpuUsageCMTriggerHandler));

        cpuUsageCMTriggerHandler = Limits.getCpuTime();
        CDdCampaignMemberTriggerHelper.updatePrimaryCampaignSourceOnContact(newList);
        System.debug('><><><><><><><><><><><><><> CDdCampaignMemberTriggerHelper.updatePrimaryCampaignSourceOnContact = ' + (Limits.getCpuTime() - cpuUsageCMTriggerHandler));

        cpuUsageCMTriggerHandler = Limits.getCpuTime();
        CDdCampaignMemberTriggerHelper.updateLeadInboundTimeAndOwner(newList, true);
        System.debug('><><><><><><><><><><><><><> CDdCampaignMemberTriggerHelper.updateLeadInboundTimeAndOwner = ' + (Limits.getCpuTime() - cpuUsageCMTriggerHandler));

        if(!featureFlag.Disable_CampaignMember_Queueable__c){
            CDdCampaignMemberTriggerHelper.updateLeadOnCampaignMember(newList);
        }

        cpuUsageCMTriggerHandler = Limits.getCpuTime();
        CDdCampaignMemberTriggerHelper.updateLeadContactPrimaryCampaignSource(newList);
        System.debug('><><><><><><><><><><><><><> CDdCampaignMemberTriggerHelper.updateLeadContactPrimaryCampaignSource = ' + (Limits.getCpuTime() - cpuUsageCMTriggerHandler));
    }

    public static void afterDeleteOrUndelete(List<CampaignMember> old) {
        cpuUsageCMTriggerHandler = Limits.getCpuTime();
        CDdCampaignMemberTriggerHelper.updateLeadInboundTimeAndOwner(old, false);
        System.debug('><><><><><><><><><><><><><> CDdCampaignMemberTriggerHelper.updateLeadInboundTimeAndOwner = ' + ((Limits.getCpuTime() - cpuUsageCMTriggerHandler)) );
    }
}