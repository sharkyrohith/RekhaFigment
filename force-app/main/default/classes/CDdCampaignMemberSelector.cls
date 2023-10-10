/**
 * @author j.johnson on 12/28/2020.
 *
 * @description
 *
 * @example
 */

public inherited sharing class CDdCampaignMemberSelector {

    public static Map<Id, Contact> contactsByCampaignMembersMap(List<CampaignMember> campaignMembers) {
        return new Map<Id, Contact>([
                SELECT Id, Primary_Campaign_Source__c
                FROM Contact
                WHERE Id IN (
                        SELECT ContactId
                        FROM CampaignMember
                        WHERE Id IN :campaignMembers AND CampaignId != null)]
        );
    }

    public static Map<Id, Lead> leadsByCampaignMembersMap(List<CampaignMember> campaignMembers) {
        return new Map<Id, Lead>([
                SELECT Id, Primary_Campaign_Source__c
                FROM Lead
                WHERE Id IN (
                        SELECT LeadId
                        FROM CampaignMember
                        WHERE Id IN :campaignMembers AND CampaignId != null)
        ]);
    }

    /**
     * @param accountIds A list of account Ids for which to get Opportunities
     * @return Lists of Opportunities keyed by Account.Id
     */
    public static Map<Id, List<Opportunity>> workDriveOpportunitiesByAccountIdMap(Set<Id> accountIds) {
        Map<Id, List<Opportunity>> oppsByAccountId = new Map<Id, List<Opportunity>>();
        List<Opportunity> opps = workDriveOpportunitiesByAccountId(accountIds);
        for (Opportunity opp : workDriveOpportunitiesByAccountId(accountIds)) {
            if (oppsByAccountId.containsKey(opp.AccountId)) {
                oppsByAccountId.get(opp.AccountId).add(opp);
            } else {
                oppsByAccountId.put(opp.AccountId, new List<Opportunity> { opp });
            }
        }
        return oppsByAccountId;
    }


    public static List<Opportunity> workDriveOpportunitiesByAccountId(Set<Id> accountIds) {
        return [
                select
                    AccountId,
                    RecordTypeId
                from Opportunity
                where
                    AccountId = :accountIds
                        and RecordTypeId in (
                            :CDdSchemaUtils.OPPORTUNITY_RT.doorDashDriveId(),
                            :CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId(),
                            :CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId())
                        and StageName not in ('Closed Won', 'Closed Lost')];
    }

    public static Set<Id> accountIdsByContact(List<Contact> contacts) {
        Set<Id> accountsIds = new Set<Id>();
        for (Contact c: contacts) {
            if (c.AccountId != null) {
                accountsIds.add(c.AccountId);
            }
        }
        return accountsIds;
    }

    public static Map<Id, Contact> contactsByIds(Set<Id> contactIds) {
        return new Map<Id, Contact>([
                select
                    Id,
                    FirstName,
                    LastName,
                    Phone,
                    Email,
                    MailingStreet,
                    MailingCity,
                    MailingState,
                    MailingCountry,
                    MailingPostalCode,
                    AccountId,
                    Account.Name,
                    Account.Website,
                    Title,
                    MobilePhone,
                    Account.AnnualRevenue,
                    Account_Industry__c,
                    Account.NumberOfEmployees,
                    Account.IsPersonAccount,
                    DOZISF__ZoomInfo_Company_ID__c,
                    DOZISF__ZoomInfo_Id__c,
                    Notes__c,
                    Owner.IsActive,
                    OwnerId,
                    Primary_Merchant_Category__c,
                    Account.PersonLeadSource,
            		Description,
                    LeadSource,
                    Current_Delivery_Provider__c,
            		Industry__c,
            		Language__c,
                    Referrer_Account_Manager_Email__c,
                    Referrer_Store_ID__c
                from Contact
                where Id = :contactIds]);
    }

    public static Id insideSalesOmniId() {
        return [
                select
                    Id,
                    DeveloperName,
                    Type
                from Group
                where DeveloperName = 'Inbound_Sales_Omni' and Type = 'Queue']?.Id;
    }

    /**
     * For a given set of contacts, find unconverted Leads with matching email addresses.
     *
     * @param contacts A list of Contacts for which to get leads
     * @return A set of lead email addresses matching contact email addresses
     */
    public static Set<String> leadEmailsByContact(List<Contact> contacts) {
        Set<String> leadEmails = new Set<String>();
        for (Lead lead : [
                select
                    Id,
                    Email
                from Lead
                where
                    IsConverted = false
                        and Email = :objectsToFieldList(contacts, 'Email')]) {

            leadEmails.add(lead.Email);
        }
        return leadEmails;
    }

    public static Map<Id, Campaign> campaignsByIdMap(List<CampaignMember> members) {
        Set<Id> campaignIds = new Set<Id>();
        for (CampaignMember member: members) {
            campaignIds.add(member.CampaignId);
        }

        return new Map<Id, Campaign>([select RecordTypeId, Name from Campaign where Id = :campaignIds]);
    }

    private static List<String> objectsToFieldList(List<SObject> sobjs, String field) {
        List<String> objList = new List<String>();
        for (SObject sobj : sobjs) {
            if (sobj.get(field) != null) {
                objList.add((String) sobj.get(field));
            }
        }
        return objList;
    }
}