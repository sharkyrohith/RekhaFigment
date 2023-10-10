/**
* @author: Sriram
* @date: 2019-05-06
* @description Trigger handler for Contact.
*/
public class CDdContactTriggerHandler {

    public static final String DEVELOPER_NAME_ACCOUNT_PARENT_ACCOUNT = 'Account_Parent_Account';
    public static final String RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT;
    public static Boolean ranOutreachContactCorrectSequence = false;
    public static Boolean ranFormstackUpdateDM = false;
    public static final ID RECORD_TYPE_ID_CAMPAIGN;
    public static final String NAME_CAMPAIGN = System.label.CampaignNameMxAcqMktg;
    public static String hubspotIntegrationUserEmail = 'hubspot@doordash.com';
    
    static {
        for (Record_Type_Values__mdt recordTypeValue : [SELECT DeveloperName, Record_Type_Id_18__c 
                                                        FROM Record_Type_Values__mdt 
                                                        WHERE DeveloperName = :DEVELOPER_NAME_ACCOUNT_PARENT_ACCOUNT]){
            RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT = recordTypeValue.Record_Type_Id_18__c;
        }
        if (RECORD_TYPE_ID_CAMPAIGN == null) {
            List<Campaign> campaigns = [SELECT ID, Name FROM Campaign WHERE Name = :NAME_CAMPAIGN Limit 1];
            RECORD_TYPE_ID_CAMPAIGN = campaigns.isEmpty() ? null : campaigns[0].ID;
        }
    }    
    public static Set<String> excludeCountryCodePhoneFormatting = new Set<String> {'CA', 'US', 'JP'};

    public void beforeInsert(List<Contact> newList) {
        updateContactOwner(newList, null);
        matchOnFormstackStoreId(newList);
        updateInternationalPhoneNumbers(newList, null);
        outreachContactCorrectSequence(newList);
        CDdGDPRCreateContactHelper.updateMuelsoftExtId(newList);
    }

    public void beforeUpdate(Map<Id, Contact> newMap, Map<Id, Contact> oldMap) {
        updateContactOwner(newMap.values(), oldMap);
        updateInternationalPhoneNumbers(newMap.values(), oldMap); 
        outreachContactCorrectSequence(newMap.values());
        
         // GDPR Email CMS
         CDdGDPRCreateContactHelper.treatChangedEmailAudit(newMap.values(),oldMap);
         CDdGDPRCreateContactHelper.updateMuelsoftExtId(newMap.values());
    }

	public void afterInsert(List<Contact> newList) {
        formstackUpdateDM(newList);

        // GDPR Email CMS 
        CDdGDPRCreateContactHelper.createGDPREmailCreateContactEvent(Trigger.New,null);
    }
    
    public void afterUpdate(Map<Id, Contact> newMap, Map<Id, Contact> oldMap) {
        updateLeadCreatedFromContact(newMap,oldMap);

        // GDPR Email CMS 
        CDdGDPRCreateContactHelper.createGDPREmailCreateContactEvent(Trigger.New,oldMap);
    }
    
    /**
    * @author Sriram
    * @date 2019-05-06
    * @description Update Owner on the Contact record to match up with either one of the following
    *   - ADR_Owner_Actual__c from the Account record (only if the ADR Owner value is valid)
    *   - Or Owner from the Account record
    *   [BZAP-4137 - Create ADR field and use for contact ownership assignment]
    *   [BZAP-17721 - adding oldMap parameter to method, so that uow does not run on insert]
    */
    @testvisible
    private static void updateContactOwner(List<Contact> newList, Map<Id, Contact> oldMap) {
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        Map<Id, Id> contactOwnerByAccountId = new Map<Id, Id>();
        for (Contact c : newList){
            if (String.isNotBlank(c.AccountId)){
                if (contactsByAccountId.containsKey(c.AccountId)){
                    contactsByAccountId.get(c.AccountId).add(c);
                } else {
                    contactsByAccountId.put(c.AccountId, new List<Contact>{c});
                }
            }
        }
        for (Account a: AccountsSelector.newInstance().selectById(contactsByAccountId.keySet())) {
            contactOwnerByAccountId.put(a.Id, (String.isNotBlank(a.ADR_Owner_Actual__c) ? a.ADR_Owner_Actual__c : a.OwnerId));
        }
        for (Id accountId : contactsByAccountId.keySet()){
            Id newContactOwnerId = contactOwnerByAccountId.get(accountId);
            for (Contact c : contactsByAccountId.get(accountId)){
                if (!c.OwnerId.equals(newContactOwnerId)){
                    c.OwnerId = newContactOwnerId;
                }
            }
        }
    }

   /** @author Nathalie Mendezona
    * @description Parses phone numbers and returns a string without spaces. This applies to non-US phone numbers
    */ 
    private void updateInternationalPhoneNumbers(List<Contact> newList, Map<Id, Contact> oldMap) {
        Boolean isInsert = oldMap == null ? true : false;

        CDdI18nUtility.updateInternationalPhoneNumbers(newList, oldMap, 'Contact', isInsert);
    }

    /**
    * @description BZAP-5095 - Match contacts to accounts based on Formstack Store ID
    */
    public static void matchOnFormstackStoreId(List<Contact> newList) {
        Map<String, Contact> storeToContactIdMap = new Map<String, Contact>();
        Map<String, Id> storeToAccountIdMap = new Map<String, Id>();
        Set<Id> recordTypeIdFilterSet = new Set<Id>{RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT};        
        for (Contact c : newList){
            if (String.isNotBlank(c.Formstack_Store_ID__c)){
                storeToContactIdMap.put(c.Formstack_Store_ID__c.trim(), c);
            }
        }
        for (Account a : [  SELECT Id, Restaurant_ID__c
                            FROM Account
                            WHERE Restaurant_ID__c IN :storeToContactIdMap.keySet()
                            AND RecordTypeId NOT IN :recordTypeIdFilterSet
                        ]){
            storeToAccountIdMap.put(a.Restaurant_ID__c.trim(), a.Id);
        }
        for (String storeId : storeToAccountIdMap.keySet()){
            if (storeToContactIdMap.containsKey(storeId)){
                storeToContactIdMap.get(storeId).AccountId = storeToAccountIdMap.get(storeId);
            }
        }
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-11448, BASD-28825: Update Lead Created from Contact whenever State, PMC Fields values change
    * @param Map<Id, Contact> new Contact Map
    * @param Map<Id, Contact> old Contact Map
    */
	public static void updateLeadCreatedFromContact(Map<Id, Contact> newMap, Map<Id, Contact> oldMap) {
        Set<id> conIdSet = new Set<id>();
        Set<id> updateAddressSet = new Set<id>();
        List<Lead> leadList = new List<Lead>();

        for(Contact currCon : newMap.values()){
            Contact oldCon = (oldMap != null && oldMap.containsKey(currCon.id)) ? oldMap.get(currCon.id) : null;

            if (oldCon != null && (currCon.MailingCity != oldCon.MailingCity ||
              	currCon.MailingCountry != oldCon.MailingCountry ||
                currCon.MailingPostalCode != oldCon.MailingPostalCode ||
                currCon.MailingState != oldCon.MailingState ||
                currCon.MailingStreet != oldCon.MailingStreet) && 
                UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)) {
                   updateAddressSet.add(currCon.id);
                   conIdSet.add(currCon.id);
               }
            if (oldCon != null && currCon.Primary_Merchant_Category__c != oldCon.Primary_Merchant_Category__c && 
                    UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)) {
                conIdSet.add(currCon.id);
            }
        }
        
        if(!conIdSet.isEmpty()) {
            leadList = LeadsSelector.newInstance().selectLeadsByCreatedFromContact(conIdSet);
        }

        if(!leadList.isEmpty()){
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
            for(Lead currLead : leadList){
                if (newMap != null && updateAddressSet.contains(currLead.Created_from_Contact__c) && UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)) {
                    currLead.City = newMap.get(currLead.Created_from_Contact__c).MailingCity;
                    currLead.Country = newMap.get(currLead.Created_from_Contact__c).MailingCountry;
                    currLead.PostalCode = newMap.get(currLead.Created_from_Contact__c).MailingPostalCode;
                    currLead.State = newMap.get(currLead.Created_from_Contact__c).MailingState;
                    currLead.Street = newMap.get(currLead.Created_from_Contact__c).MailingStreet;
                }
                if (newMap.get(currLead.Created_from_Contact__c).Primary_Merchant_Category__c != oldMap.get(currLead.Created_from_Contact__c).Primary_Merchant_Category__c && 
                        UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)) {
                    currLead.Primary_Merchant_Category__c = newMap.get(currLead.Created_from_Contact__c).Primary_Merchant_Category__c;
                }
                uow.registerDirty(currLead);
            }
            uow.commitWork();
        }
    }

    /**
    * @author Lathika
    * @date 2022-01
    * @description BZAP - 13013 Convert PB to Trigger (Outreach Contact Correct Sequence)
    * @param List<Contact> newContactList
    */
    public static void outreachContactCorrectSequence(List<Contact> newContactList){
        if (ranOutreachContactCorrectSequence) {
            return;
        } 
        for(Contact con : newContactList){
            if(String.isBlank(con.Initial_Sequence_Name__c) && String.isNotBlank(con.Name_of_Currently_Active_Sequence__c)){
                con.Initial_Sequence_Date__c = System.today();
                con.Initial_Sequence_ID__c = con.ID_of_Currently_Active_Sequence__c;
                con.Initial_Sequence_Name__c = con.Name_of_Currently_Active_Sequence__c;
            }
        } 
        ranOutreachContactCorrectSequence = true;   
    }

    /**
   * @author Lathika
   * @date 2022-01
   * @description BZAP - 13013 Convert PB to Trigger (Formstack - Update DM)
   * @param List<Contact> newContactList
   */

    public static void formstackUpdateDM(List<Contact> newContactList){
    if (ranFormstackUpdateDM) {
        return;
    }
    try{
        Map<Id, Contact> accountIDByContactMap = new Map<Id, Contact>();
        List<CampaignMember> campaignMemberToInsert = new List<CampaignMember>();
        List<Account> accountToUpdate = new List<Account>();
        for (Contact con : newContactList){
            if (String.isNotBlank(con.AccountId) && (con.Lead_Source_Detail__c == CDdCoreConstants.LEADSOURCE_DETAIL_FORMSTACK || con.Lead_Source_Detail__c == CDdCoreConstants.LEADSOURCE_DETAIL_SSMO)){ 
                accountIDByContactMap.put(con.AccountId, con);
            } else if (con.Current_Sequence_User_Name__c == 'c'){
                campaignMemberToInsert.add(createCampaignMemberRecord(con.Id));
            }
        }
        if (accountIDByContactMap.keySet().size() > 0){ 
            accountToUpdate = [select Id,
                                      Decision_Maker__c
                              from Account
                              where Id =: accountIDByContactMap.keySet() and Decision_Maker__c = null];                                      
            for (Account acc: accountToUpdate){
                acc.Decision_Maker__c = accountIDByContactMap.get(acc.Id).Id;
            }      
            if (accountToUpdate.size() > 0){
                update accountToUpdate;
            }
        }  
        if (campaignMemberToInsert.size()> 0){
            insert campaignMemberToInsert;
        }
    } catch (Exception e){
        CDdErrorUtilities.publishException('Contact','formstackUpdateDM', e);       
    }
        ranFormstackUpdateDM = true;
    } 

     /**
   * @author Lathika
   * @date 2022-01
   * @description BZAP - 13013 Return CampaignMember
   * @param Id conId ContactID
   */
    private static CampaignMember createCampaignMemberRecord(Id conId) {
        CampaignMember campaignMember = new CampaignMember();
        campaignMember.CampaignId = RECORD_TYPE_ID_CAMPAIGN;
        campaignMember.ContactId = conId;
        campaignMember.Status = 'Responded';
        return campaignMember;
    } 
}