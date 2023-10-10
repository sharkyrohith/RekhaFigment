public with sharing class CDdCampaignMemberTriggerHelper {
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
    public static Map<String, Id> keyToQueueOrUserIds = new Map<String, Id>();
    public static Set<String> campaignTypeToUpdateOwnership = new Set<String>{
        'A', 'Referral', 'Event', 'Self-Serve'};
    static {
        List<Group> queues = [SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name IN (:inboundSalesOmniQueueName, :badLeadDataQueueName)];
        for(Group q: queues) {
            keyToQueueOrUserIds.put(q.Name, q.Id);
        }

        List<User> users = [SELECT Id, Alias FROM User WHERE Alias = :holdingUserAlias];
        for(User u: users) {
            keyToQueueOrUserIds.put(u.Alias, u.Id);
        }
    }

    public static String hubspotIntegrationUserEmail = 'hubspot@doordash.com';

    /**
     * BZAP-9018: Create Leads when Person Account / Contacts are added to a Campaign
     *
     * For each new CampaignMember, determine whether a new Lead should be generated. If a Lead should be
     * generated, create the Lead, insert it, and assign the Lead.Id to the CampaignMember.LeadId.
     *
     * A new Lead should be generated when:
     *
     *     1) The CampaignMember has a Contact
     *     2) The Contact is not associated with an Account having an open Opportunity of type Drive or Work
     *     3) The Contact email does not exist on an unconverted Lead
     *
     * This is the outer method, which collects data to be evaluated and stores results.
     * It delegates evaluation to the inner method by the same name.
     *
     * @param members A list of new CampaignMembers
     */
    public static void generateLeads(List<CampaignMember> members) {
        Map<Id, Contact> contactMap = getContactMap(members);
        Set<Id> accountsIds = CDdCampaignMemberSelector.accountIdsByContact(contactMap.values());
        Map<Id, List<Opportunity>> opportunitiesByAccountIds = CDdCampaignMemberSelector.workDriveOpportunitiesByAccountIdMap(accountsIds);
        Set<String> leadEmails = CDdCampaignMemberSelector.leadEmailsByContact(contactMap.values());

        // The lead record will only be created if the hubspot integration user creates a campaign member record- BASD-11603
        if (UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)) {
            // Insert new Leads
            Map<String, Lead> leadsByEmail = generateLeads(members, contactMap, opportunitiesByAccountIds, leadEmails);
            insert leadsByEmail.values();

            // Point the CampaignMember to the new Lead
            for (CampaignMember member : members) {
                if (contactMap.containsKey(member.ContactId)) {
                    Contact contact = contactMap.get(member.ContactId);
                    if (leadsByEmail.containsKey(contact.Email)) {
                        member.LeadId = leadsByEmail.get(contact.Email).Id;
                        member.ContactId = null;
                    }
                }
            }
        }
    }

    /**
     * BZAP-9018: Create Leads when Person Account / Contacts are added to a Campaign.
     *
     * This is the inner method, which evaluates the data collected and returns a map of Leads to create, keyed
     * by the Email.
     *
     * @param members A list of new CampaignMembers
     * @param contactMap Contacts associated with this member
     * @param oppsByAccountId Opportunities associated with this member's contacts
     * @param leadEmails Lead email addresses that already exist
     * @return A map of new leads keyed by Email
     */
    @TestVisible
    private static Map<String, Lead> generateLeads(List<CampaignMember> members, Map<Id, Contact> contactMap, Map<Id, List<Opportunity>> oppsByAccountId, Set<String> leadEmails) {
        Set<Id> RTToBeProcessed = new Set<Id>{campaignMarketplaceId, campaignSelfDeliveryId, campaignWorkId, campaignDriveId};
        Map<String, Lead> leadsByEmail = new Map<String, Lead>();
        Map<Id, Campaign> campaignsByIdMap = CDdCampaignMemberSelector.campaignsByIdMap(members);

        //BASD-20148 Skip logic for the campaign members where campaign name doesn't include AcqMktg in it's name
        List<CampaignMember> membersToProcess = checkCampaignName(members,campaignsByIdMap);
        for (CampaignMember member : membersToProcess) {
            if (contactMap.keySet().contains(member.ContactId)) {
                Contact contact = contactMap.get(member.ContactId);
                Boolean hasDriveOpp = false;
                Boolean hasWorkOpp = false;
                Boolean hasMarketplaceOpp = false;
                Id campaignRecordTypeId = campaignsByIdMap.get(member.CampaignId)?.RecordTypeId;

                // Skip logic if the current Campaign.RecordType is not part of the Set of Record Types that
                // support this lead generation process
                if (!RTToBeProcessed.contains(campaignRecordTypeId)) continue;

                if (member.ContactId != null && contact.Email!=null
                        && !leadEmails.contains(contact.Email)
                        && !(campaignRecordTypeId == campaignWorkId && hasWorkOpp)
                        && !(campaignRecordTypeId == campaignDriveId && hasDriveOpp)
                        && !(campaignRecordTypeId == campaignMarketplaceId && hasMarketplaceOpp)
                        && !(campaignRecordTypeId == campaignSelfDeliveryId && hasMarketplaceOpp)) {

                    Lead lead = createLead(contact, member);

                    if (campaignRecordTypeId == campaignWorkId) {
                        lead.RecordTypeId = leadWorkId;
                    } else if (campaignRecordTypeId == campaignDriveId) {
                        lead.RecordTypeId = leadDriveId;
                    } else {
                        lead.RecordTypeId = leadMasterId;
                    }

                    leadsByEmail.put(contact.Email, lead);
                }
            }
        }
        return leadsByEmail;
    }

    /**
     * BZAP-20148: Lead Creation from Contacts - Logic update // Ila Maheshwari
     *
     * For each new CampaignMember, determine whether an existing Lead should be updated. If a Lead should be
     * updated, call the queueable which will update the lead and assign the Lead.Id to the CampaignMember.LeadId.
     *
     * Lead should be updated when:
     *
     *     1) If the lead is already enrolled in the same campaign and the different between member 1st association dates is > 15 days
     *     2) If the lead is not enrolled in the same campaign
     *
     * @param members A list of new CampaignMembers
     *
     */

    @TestVisible
    public static void updateLeadOnCampaignMember(List<CampaignMember> members) {
        Map<Id,CampaignMember> membersToPro = new Map<Id, CampaignMember>();
        Map<Id, Contact> contactMap = getContactMap(members);
        Set<String> leadEmails = CDdCampaignMemberSelector.leadEmailsByContact(contactMap.values());
        Map<Id, Campaign> campaignsByIdMap = CDdCampaignMemberSelector.campaignsByIdMap(members);

        // The lead record will only be created if the hubspot integration user creates a campaign member record- BASD-11603
        if (UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)) {
            //Skip logic for the campaign members where campaign name doesn't include AcqMktg in it's name
            List<CampaignMember> membersToProcess = checkCampaignName(members,campaignsByIdMap);
            if(!membersToProcess.isEmpty()){
                for(CampaignMember currmember : members){
                    membersToPro.put(currmember.id,currmember);
                }
                System.enqueueJob(new CDdCampaignMemberQueueable(membersToPro, contactMap, leadEmails, campaignsByIdMap));
            }
        }
    }

    public static Lead createLead(Contact contact, CampaignMember member) {
        //Id leadOwner = determineLeadOwner(contact);
        Id leadOwner = keyToQueueOrUserIds.get(inboundSalesOmniQueueName);
        return new Lead(
            OwnerId = leadOwner,
            FirstName = contact.FirstName,
            LastName = contact.LastName,
            Phone = contact.Phone,
            Email = contact.Email,
            Street = contact.MailingStreet,
            City = contact.MailingCity,
            State = contact.MailingState,
            Country = contact.MailingCountry,
            PostalCode = contact.MailingPostalCode,
            Primary_Campaign_Source__c = member.CampaignId,
            Company = contact.Account.Name,
            Created_from_Contact__c = contact.Id,
            Website = contact.Account.Website,
            Title = contact.Title,
            MobilePhone = contact.MobilePhone,
            AnnualRevenue = contact.Account.AnnualRevenue,
            NumberOfEmployees = contact.Account.NumberOfEmployees,
            DOZISF__ZoomInfo_Company_ID__c = contact.DOZISF__ZoomInfo_Company_ID__c,
            DOZISF__ZoomInfo_Id__c = contact.DOZISF__ZoomInfo_Id__c,
            /*Notes__c = contact.Notes__c,*/
            Merchant_Categories__c = contact.Primary_Merchant_Category__c,
            Primary_Merchant_Category__c = contact.Primary_Merchant_Category__c,
            Notes__c = String.isNotBlank(contact.Notes__c) ? contact.Notes__c : contact.Description,
            LeadSource = (contact.Account <> null && contact.Account.PersonLeadSource <> null ? contact.Account.PersonLeadSource : contact.LeadSource),
            Industry = contact.Industry__c,
            Current_Delivery_Provider__c  = contact.Current_Delivery_Provider__c,
            Language__c = contact.language__c,
            //BASD-52061 Added 2 additional fields to populated during lead creation
            Referrer_Account_Manager_Email__c = contact.Referrer_Account_Manager_Email__c,
            Referrer_Store_ID__c = contact.Referrer_Store_ID__c
        );
    }

    //Check if campaign name includes eligible text - BASD-20148
    private static List<CampaignMember> checkCampaignName(List<CampaignMember> members, Map<Id, Campaign> campaignsByIdMap) {
        List<CampaignMember> membersToProcess = new List<CampaignMember>();
        For(CampaignMember campMember : members){
            if(campaignsByIdMap.containsKey(campMember.CampaignId)){
                String name = campaignsByIdMap.get(campMember.CampaignId).Name;
                if(name.containsIgnoreCase(Label.Hubspot_Eligible_Campaign_Name)){
                    membersToProcess.add(campMember);
                }
            }
        }
        return membersToProcess;
    }

    // Lead Owner is determine by the owner of the contact that was used
    // to create the Lead.
    private static Id determineLeadOwner(Contact contact) {
        Id leadOwner;
        Boolean contactOwnerActive = contact.Owner.isActive;
        Id contactOwnerId = contact.OwnerId;
        Set<String> contactOwnerIds = new Set<String>();
        contactOwnerIds = new Set<String>(Label.Lead_Ownership_Determining_Contact_Owners.split(';'));
        Id inboundSalesOmni = CDdCampaignMemberSelector.insideSalesOmniId();

        if (contact.Account.IsPersonAccount) {
            return inboundSalesOmni;
        }

        if (contactOwnerActive && !contactOwnerIds.contains(contactOwnerId)) {
            return contactownerId;
        }

        return inboundSalesOmni;
    }

    // Loops through all the campaign members.
    // 1. If campaign members has a contact id
    //    Query contact information
    @TestVisible
    private static Map<Id, Contact> getContactMap(List<CampaignMember> members) {
        Set<Id> contactIds = new Set<Id>();
        for (CampaignMember member : members) {
            if (member.ContactId != null) {
                contactIds.add(member.ContactId);
            }
        }
        return CDdCampaignMemberSelector.contactsByIds(contactIds);
    }

    // Removes Contact from CampaignMember is we have a Lead with the same
    // Email address
    public static void removeContacts(List<CampaignMember> members) {
        System.debug('removeContacts');
        // Remove existing Contact CampaignMembers for which new Leads were created
        Set<String> emails = new Set<String>();
        Set<Id> campaignIds = new Set<Id>();
        for (CampaignMember member : members) {
            if (member.LeadId != null && !String.isBlank(member.Email) ) {
                emails.add(member.Email);
                campaignIds.add(member.CampaignId);
                System.debug('Email:' + member.Email + ' CampaignId:' + member.CampaignId);
            }
        }
        System.debug('email list size:' + emails.size());

        delete [SELECT Id FROM CampaignMember WHERE Contact.Email in :emails AND CampaignId in :campaignIds];
    }

    public static void updatePrimaryCampaignSourceOnContact(List<CampaignMember> newCMs) {
        if (CDdCustomMetaData.isDisabled('CDdCMTriggerHelper_updatePCSOnContact')) return;

        List<String> errorMessages = new List<String>();
        Map<Id, Contact> idToContact = CDdCampaignMemberSelector.contactsByCampaignMembersMap(newCms);
        Map<Id, Lead> idToLead = CDdCampaignMemberSelector.leadsByCampaignMembersMap(newCms);

        for (CampaignMember cm : newCMs) {
            if (idToContact.containsKey(cm.ContactId)) {
                idToContact.get(cm.ContactId).Primary_Campaign_Source__c = cm.CampaignId;
            }
            if (idToLead.containsKey(cm.LeadId)) {
                idToLead.get(cm.LeadId).Primary_Campaign_Source__c = cm.CampaignId;
            }
        }

        try {
            List<Database.SaveResult> contactSaveResults = Database.update(idToContact.values(), false);
            List<Database.SaveResult> leadSaveResults = Database.update(idToLead.values(), false);
            errorMessages.addAll(CDdErrorUtilities.processSaveResults(contactSaveResults));
            errorMessages.addAll(CDdErrorUtilities.processSaveResults(leadSaveResults));
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdCampaignMemberTriggerHelper',
                    'updatePrimaryCampaignSourceOnContact', LoggingLevel.ERROR);
        } catch (Exception ex) {
            CDdErrorUtilities.createApexLogs(new List<String>{
                    'Contact/Lead update exception: ' + ex.getMessage()
            }, 'CDdCampaignMemberTriggerHelper',
                    'updatePrimaryCampaignSourceOnContact', LoggingLevel.ERROR);
            throw ex;
        }
    }

    public static void updateLeadInboundTimeAndOwner(List<CampaignMember> CMs, Boolean updateOwner){
        Boolean doNotRun = CDdCustomMetaData.isDisabled('CDdCMTriggerHelper_inboundLead')
                || !CDdRecursionUtils.isRunnable('CDdCMTriggerHelper_inboundLead');
        if (doNotRun && !Test.isRunningTest()) return;

        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();

        Set<Id> AGradeCampaignLead = new Set<Id>();
        if(updateOwner){
            AGradeCampaignLead.addAll(getAGradeCampaignLeads(CMs));
        }

        Map<Id, DateTime> leadRecentActivityTime = getLeadRecentActivityTime(CMs);
        Lead leadToUpdate;

        for(CampaignMember cm: CMs){
            if (cm.LeadId == null){
                continue;
            }

            leadToUpdate = new Lead(
                Id = cm.LeadId
            );

            // Potentially the Lead will not have a CampaignMember record
            // if the only CampaignMember record was deleted.
            if(leadRecentActivityTime.containsKey(cm.LeadId)){
                leadToUpdate.Last_Inbound_Date_Time__c = leadRecentActivityTime.get(cm.LeadId);
            } else {
                leadToUpdate.Last_Inbound_Date_Time__c = null;
            }

            if(AGradeCampaignLead.contains(cm.LeadId) && updateOwner){
                leadToUpdate.OwnerId = keyToQueueOrUserIds.get(inboundSalesOmniQueueName);
            }

            if (!leadsToUpdate.containsKey(cm.LeadId)) {
                leadsToUpdate.put(cm.LeadId, leadToUpdate);
            }
        }

        List<Database.SaveResult> results = Database.update(leadsToUpdate.values(), false);
        CDdErrorUtilities.createApexLogs(CDdErrorUtilities.processSaveResults(results),
            'CDdCampaignMemberTriggerHelper', 'updateLeadInboundTimeAndOwner',LoggingLevel.ERROR);
    }

    /**
     * Singles out all leads that belong to a campaign type A
     * and the owner of the lead is either bad lead queue or holding user
     */
    private static Set<Id> getAGradeCampaignLeads(List<CampaignMember> newCMs) {
        Set<Id> AGradeCampaignLead = new Set<Id>();
        Set<Id> badLeadHolderIds = new Set<Id>{
            keyToQueueOrUserIds.get(badLeadDataQueueName),
            keyToQueueOrUserIds.get(holdingUserAlias)
        };

        List<Lead> gradeACampaignLeads = [
            SELECT Id
            FROM Lead
            WHERE Id IN (SELECT LeadId
                FROM CampaignMember
                WHERE Id IN :newCMS
                AND Campaign.Type IN: campaignTypeToUpdateOwnership
                AND Campaign.Name LIKE '%AcqMktg%')
            AND OwnerId IN :badLeadHolderIds];

        for(Lead l: gradeACampaignLeads){
            AGradeCampaignLead.add(l.Id);
        }

        return AGradeCampaignLead;
    }

    /**
     * Returns Map of Lead Id to CreatedDate
     * Where CreatedDate is the most recent CampaignMember record.
     */
    private static Map<Id, DateTime> getLeadRecentActivityTime(List<CampaignMember> CMs) {
        Map<Id, DateTime> leadRecentActivity = new Map<Id, DateTime>();
        Set<Id> leadIds = new Set<Id>();

        // Loops through CM and generate Set of Lead Ids
        for(CampaignMember cm: CMs) {
            if (String.IsNotBlank(cm.LeadId)) {
                leadIds.add(cm.LeadId);
            }
        }

        // Gets all CampaignMember records related to all LeadsIds
        List<AggregateResult> cmCreatedDate = [
            SELECT MAX(CreatedDate), LeadId
                FROM CampaignMember
                WHERE LeadId IN :leadIds
                GROUP BY LeadId
        ];
        // Generates a Map of LeadId and their Latest CreatedDate
        for(AggregateResult cm: cmCreatedDate){
            Id leadId = Id.valueOf(String.valueOf(cm.get('LeadId')));
            DateTime createdCampaignMember = (DateTime)cm.get('expr0');
            leadRecentActivity.put(leadId, createdCampaignMember);
        }

        return leadRecentActivity;
    }

    public static void updateLeadContactPrimaryCampaignSource(List<CampaignMember> newCMs){
        List<Campaign_Member_Platform_Event__e> primaryCampaignSourceEventList = new List<Campaign_Member_Platform_Event__e>();
        for (CampaignMember campaignMember : newCMs) {
            primaryCampaignSourceEventList.add(new Campaign_Member_Platform_Event__e(Campaign_Member_Id__c=campaignMember.Id,Event_Type__c=CDdCampaignMemberEventHandler.PRIMARY_CAMPAIGN_SOURCE));
        }

        if (!primaryCampaignSourceEventList.isEmpty()) {
            EventBus.publish(primaryCampaignSourceEventList);
        }
    }

}