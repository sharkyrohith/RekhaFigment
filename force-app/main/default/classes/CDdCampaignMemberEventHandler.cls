public class CDdCampaignMemberEventHandler {
    
    public static final String PRIMARY_CAMPAIGN_SOURCE = 'Primary Campaign Source';
    /**
    * @description fire this method after the 'SSMO Opportunity Attribution Event' event is published
    */
    public void afterInsert(List<Campaign_Member_Platform_Event__e> newList) {
        Map<String,List<Campaign_Member_Platform_Event__e>> campaignMemberEventMap = new Map<String,List<Campaign_Member_Platform_Event__e>>();
        for (Campaign_Member_Platform_Event__e eventRecord : newList){
            if(!campaignMemberEventMap.containsKey(eventRecord.Event_Type__c)){
                campaignMemberEventMap.put(eventRecord.Event_Type__c,new List<Campaign_Member_Platform_Event__e>());
            }
            campaignMemberEventMap.get(eventRecord.Event_Type__c).add(eventRecord);
        }

        for(String eventType:campaignMemberEventMap.keySet()){
            if(eventType == PRIMARY_CAMPAIGN_SOURCE){
                updateLeadContactPrimaryCampaignSource(campaignMemberEventMap.get(eventType));
            }
        }
        
    }

    /**
    * @description BZAP-16115 - Convert "Campaign Member Insert - Update Lead/Contact" to Trigger (Async - Platform Events)
    *
    */
	public void updateLeadContactPrimaryCampaignSource(List<Campaign_Member_Platform_Event__e> newList) {
        List<Id> campainMemberIdList = new List<Id>();
        for(Campaign_Member_Platform_Event__e cmpe:newList){
            campainMemberIdList.add(cmpe.Campaign_Member_Id__c);
        }

        List<CampaignMember> campainMemberList = [SELECT Id,LeadId,ContactId,CampaignId FROM CampaignMember WHERE Id IN :campainMemberIdList];
        
        if(campainMemberList != null && !campainMemberList.isEmpty()){
            Map<Id, Contact> idToContact = new Map<Id, Contact>([SELECT Id FROM Contact
                                                                    WHERE Id IN ( SELECT ContactId FROM CampaignMember WHERE Id IN :campainMemberIdList AND CampaignId != null)]);
            Map<Id, Lead> idToLead = new Map<Id, Lead>([SELECT Id, Primary_Campaign_Source__c FROM Lead
                                                                    WHERE Id IN ( SELECT LeadId FROM CampaignMember WHERE Id IN :campainMemberIdList AND CampaignId != null )]);

            for (CampaignMember cm : campainMemberList) {
                if (idToContact.containsKey(cm.ContactId)) {
                    idToContact.get(cm.ContactId).Primary_Campaign_Source__c = cm.CampaignId;
                }
                if (idToLead.containsKey(cm.LeadId)) {
                    idToLead.get(cm.LeadId).Primary_Campaign_Source__c = cm.CampaignId;
                }
            }

            try {
                List<String> errorMessages = new List<String>();
                List<Database.SaveResult> contactSaveResults = Database.update(idToContact.values(), false);
                List<Database.SaveResult> leadSaveResults = Database.update(idToLead.values(), false);
                errorMessages.addAll(CDdErrorUtilities.processSaveResults(contactSaveResults));
                errorMessages.addAll(CDdErrorUtilities.processSaveResults(leadSaveResults));
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdCampaignMemberEventHandler','updateLeadContactPrimaryCampaignSource', LoggingLevel.ERROR);
            } catch (Exception ex) {
                CDdErrorUtilities.createApexLogs(new List<String>{'Contact/Lead update exception: ' + ex.getMessage()}, 'CDdCampaignMemberEventHandler','updateLeadContactPrimaryCampaignSource', LoggingLevel.ERROR);
            }
        }
    }

}