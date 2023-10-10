/**
 * @author: Ila Maheshwari
 * @date: 03-2022
 * @description:  Queueable to update leads and campaign member when a contact/person account with similar email gets associated
 */

public class CDdCampaignMemberQueueable implements Queueable,Database.AllowsCallouts{

    public static final Id campaignDriveId = CDdSchemaUtils.CAMPAIGN_RT.driveId();
    public static final Id campaignWorkId = CDdSchemaUtils.CAMPAIGN_RT.workId();
    public static final Id campaignMarketplaceId = CDdSchemaUtils.CAMPAIGN_RT.masterLaunchId();
    public static final Id campaignSelfDeliveryId = CDdSchemaUtils.CAMPAIGN_RT.selfDeliveryId();
    public static final Id leadWorkId = CDdSchemaUtils.LEAD_RT.doorDashForBusinessId();
    public static final Id leadDriveId = CDdSchemaUtils.LEAD_RT.doorDashDriveLeadsId();
    public static final Id leadMasterId = CDdSchemaUtils.LEAD_RT.masterLead();
    public static final Id oppWorkId = CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId();
    public static final Id oppDriveId = CDdSchemaUtils.OPPORTUNITY_RT.doorDashDriveId();
    public static final Id oppMarketplaceId = CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId();
    public static String inboundSalesOmniQueueName = CDdSupportConstants.QUEUE_INBOUND_SALES_OMNI_QUEUE;
    public static String badLeadDataQueueName = CDdSupportConstants.QUEUE_BAD_LEAD_DATA;
    public static String holdingUserAlias = Label.Holding_UserAlias; // Different by Environment

    Map<Lead, Boolean> memberToUpdate = new Map<Lead, Boolean>();
    Map<Id, CampaignMember> members = new Map<Id, CampaignMember>();
    Map<Id, Contact> contactMap = new Map<Id, Contact>();
    Set<String> leadEmails = new Set<String>();
    Map<Id, Campaign> campaignsByIdMap = new Map<Id, Campaign>();

    //Constructor of CDdCampaignMemberQueueable
    public CDdCampaignMemberQueueable(Map<Id, CampaignMember> members, Map<Id, Contact> contactMap, Set<String> leadEmails, Map<Id, Campaign> campaignsByIdMap){
        this.members = members;
        this.contactMap = contactMap;
        this.leadEmails = leadEmails;
        this.campaignsByIdMap = campaignsByIdMap;
    }

    public void execute(QueueableContext context) {
        try{
            List<Lead> leadsToUpdate = new List<Lead>();
            List<CampaignMember> membersToDelete = new List<CampaignMember>();
            Map<String,CampaignMember> membersToUpdate = new Map<String,CampaignMember>();
            leadsToUpdate = updateLeads();

            if(!leadsToUpdate.isEmpty()){
                update leadsToUpdate;
            }

            // Point the CampaignMember to updated Lead if lead is not associated to same campaign
            for (CampaignMember member : members.values()) {
                if (contactMap.containsKey(member.ContactId)) {
                    Contact contact = contactMap.get(member.ContactId);
                    for(Lead lead : leadsToUpdate){
                        if (lead.Email == contact.Email && memberToUpdate.get(lead)) {
                            membersToDelete.add(member);
                            CampaignMember campMember = member.clone(false,false,false,false);
                            campMember.LeadId = lead.Id;
                            campMember.ContactId = null;
                            membersToUpdate.put(campMember.CampaignId+'_'+campMember.LeadId,campMember);
                        }
                    }
                }
            }

            if(!membersToDelete.isEmpty()){
                delete membersToDelete;
                Database.emptyRecycleBin(membersToDelete);
            }

            if(!membersToUpdate.isEmpty()){
                insert membersToUpdate.values();
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{'CAMPAIGN MEMBER ID' + ex.getMessage()}, 'CDdCampaignMemberTriggerHelper',
                                             'generateLeads', LoggingLevel.ERROR);
            throw ex;
        }
    }

    /**
    * @author Ila Maheshwari
    * @description BASD-20148: This method updates existing Lead if exist with similar email id
    * return List<Enrichment_Junction__c> return final list of leads that needs to be updated
    */
    public List<Lead> updateLeads() {
        Set<Id> RTToBeProcessed = new Set<Id>{campaignMarketplaceId, campaignSelfDeliveryId, campaignWorkId, campaignDriveId};
        Map<Id,Lead> leadsToUpdate = new Map<Id,Lead>();
        Map<Id, Campaign> campaignsByIdMap = CDdCampaignMemberSelector.campaignsByIdMap(members.values());
        Map<String, Map<String,CampaignMember>> emailCampMap = new Map<String, Map<String,CampaignMember>>();
        Map<String,Map<Id,Lead>> emailLeadMap = new Map<String,Map<Id,Lead>>();
        Map<Id,Lead> leadMap;
        Map<String,CampaignMember> existingCamp;

        //will get the existing campaign member
        emailCampMap = getExistingCampaignMember(leadEmails,members,campaignsByIdMap);

        //will get the existing lead
        emailLeadMap = getExistingLead(leadEmails);

        //Loop for new campaign member
        for (CampaignMember member : members.values()) {
            if (contactMap.keySet().contains(member.ContactId)) {
                Contact contact = contactMap.get(member.ContactId);
                Boolean hasDriveOpp = false;
                Boolean hasWorkOpp = false;
                Boolean hasMarketplaceOpp = false;
                Boolean updateMember = false;
                Lead lead = new Lead();
                Id campaignRecordTypeId = campaignsByIdMap.get(member.CampaignId)?.RecordTypeId;

                // Skip logic if the current Campaign.RecordType is not part of the Set of Record Types that
                if (!RTToBeProcessed.contains(campaignRecordTypeId)) continue;

                if (member.ContactId != null && contact.Email!=null
                        && leadEmails.contains(contact.Email)
                        && !(campaignRecordTypeId == campaignWorkId && hasWorkOpp)
                        && !(campaignRecordTypeId == campaignDriveId && hasDriveOpp)
                        && !(campaignRecordTypeId == campaignMarketplaceId && hasMarketplaceOpp)
                        && !(campaignRecordTypeId == campaignSelfDeliveryId && hasMarketplaceOpp)) {

                            Integer daysbetween = 0;
                            Boolean newCampaign = false;
                            Lead existingLead;
                            Boolean existingLeadSameCampaign = false;
                            //Check if there is any campaign member exist with that emailID
                            if(emailCampMap.containsKey(member.Email)){
                                existingCamp = emailCampMap.get(member.Email);
                                //Check if that new member is part of same campaign or not
                                if(existingCamp.containsKey(member.CampaignId)){
                                    leadMap = emailLeadMap.get(member.Email);
                                    existingLead = leadMap.get(existingCamp.get(member.CampaignId).leadId);
                                    if(existingLead != null){
                                        existingLeadSameCampaign = true;
                                        //Finding the difference between today & existing "Campaign Member" created date
                                        daysbetween = Integer.valueOf((DateTime.now().getTime() - existingCamp.get(member.CampaignId).CreatedDate.getTime())/(1000*60*60*24));
                                    }
                                }
                            }
                            if(!existingLeadSameCampaign){
                                leadMap = emailLeadMap.get(member.Email);
                                existingLead = leadMap.values()[0];
                                for(Lead currLead : leadMap.values()){
                                    if(currLead.Primary_Campaign_Source__c != null){
                                        existingLead = currLead;
                                        break;
                                    }
                                }
                                newCampaign = true;
                            }


                        //If the lead is already enrolled in the same campaign and the different between member 1st association dates is > 15 days
                        if(daysbetween > 15){
                            lead.Id = existingLead.Id;
                            lead.Email = existingLead.Email;
                            if(existingLead.OwnerId == CDdCampaignMemberTriggerHelper.keyToQueueOrUserIds.get(holdingUserAlias)
                            || existingLead.OwnerId == CDdCampaignMemberTriggerHelper.keyToQueueOrUserIds.get(badLeadDataQueueName)){

                                lead.OwnerId = CDdCampaignMemberTriggerHelper.keyToQueueOrUserIds.get(inboundSalesOmniQueueName);
                            }
                            lead.LeadSource = 'Merchant Inbound';
                            lead.Status = 'Untouched';
                        }
                        //If the lead is not enrolled in the same campaign
                        else if(newCampaign){
                            string leadOwnerId = existingLead.OwnerId;

                            lead = CDdCampaignMemberTriggerHelper.createLead(contact, member);
                            lead.Id = existingLead.Id;
                            lead.Email = existingLead.Email;
                            lead.LeadSource = 'Merchant Inbound';
                            lead.Status = 'Untouched';
                            updateMember = true;
                            if(leadOwnerId != CDdCampaignMemberTriggerHelper.keyToQueueOrUserIds.get(holdingUserAlias)
                            && leadOwnerId != CDdCampaignMemberTriggerHelper.keyToQueueOrUserIds.get(badLeadDataQueueName)
                            && leadOwnerId != CDdCampaignMemberTriggerHelper.keyToQueueOrUserIds.get(inboundSalesOmniQueueName)){

                                lead.OwnerId = leadOwnerId;
                            }
                        }

                    if(lead.Id != Null){
                        if (campaignRecordTypeId == campaignWorkId) {
                            lead.RecordTypeId = leadWorkId;
                        } else if (campaignRecordTypeId == campaignDriveId) {
                            lead.RecordTypeId = leadDriveId;
                        } else {
                            lead.RecordTypeId = leadMasterId;
                        }

                    	leadsToUpdate.put(lead.Id,lead);
                        memberToUpdate.put(lead, updateMember);
                    }
                }
            }
        }
        return new List<Lead>(leadsToUpdate.values());
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-20148: This method get the map of existing Lead with help of emailid
    * return Map<String,Map<Id,Lead>> return final map of leads which already exist in system
    */
    public static Map<String,Map<Id,Lead>> getExistingLead(Set<String> leadEmails){
        Map<Id,Lead> currleadMap;
        Map<String,Map<Id,Lead>> emailLeadMap = new Map<String,Map<Id,Lead>>();
        for(Lead currLead : [SELECT Id, Email, OwnerId, Primary_Campaign_Source__c,CreatedDate FROM Lead WHERE Email IN :leadEmails AND IsConverted = false ORDER BY CreatedDate DESC]){
            if(emailLeadMap.containsKey(currLead.Email)){
                currleadMap = emailLeadMap.get(currLead.Email);
                currleadMap.put(currLead.id, currLead);
                emailLeadMap.put(currLead.Email, currleadMap);
            }
            else{
                currleadMap = new Map<Id,Lead>();
                currleadMap.put(currLead.id, currLead);
                emailLeadMap.put(currLead.Email, currleadMap);
            }
        }
        return emailLeadMap;
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-20148: This method get the map of existing campaign member with help of emailid
    * return Map<String, Map<String,CampaignMember>> return final map of campaign member which already exist in system
    */
    public static Map<String, Map<String,CampaignMember>> getExistingCampaignMember(Set<String> leadEmails, Map<Id, CampaignMember> members, Map<Id, Campaign> campaignsByIdMap){
        Map<String,CampaignMember> currMember;
        Map<String, Map<String,CampaignMember>> emailCampMap = new Map<String, Map<String,CampaignMember>>();
        for(CampaignMember existmember : [SELECT id, Email, CreatedDate,LeadId, CampaignId FROM CampaignMember
                                            WHERE Campaignid =: campaignsByIdMap.values() AND Email IN : leadEmails order by CreatedDate asc]){
            if(emailCampMap.containsKey(existmember.Email) && !members.containskey(existmember.Id)){
                currMember = emailCampMap.get(existmember.Email);
                if(!currMember.containsKey(existmember.CampaignId)){
                    currMember.put(existmember.CampaignId,existmember);
                    emailCampMap.put(existmember.Email, currMember);
                }
            }
            else if(!members.containskey(existmember.Id)){
                currMember = new Map<String,CampaignMember>();
                currMember.put(existmember.CampaignId,existmember);
                emailCampMap.put(existmember.Email, currMember);
            }
        }
        return emailCampMap;
    }

}