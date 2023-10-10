/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Helper class for opportunity inversion. Accepts a list of opportunities and opportunity inversion settings 
 *  and returns a list of Leads. Does not insert leads. 
 * 
 */


public with sharing class CDdOpportunityInversionHelper {
    public Static Map<Id,Lead> invertOpportunities(List<Opportunity> opportunities, String ownerId, String reopenedReason) {
        Opportunity_Inversion_Settings__c settings = Opportunity_Inversion_Settings__c.getInstance(); 
        Map<Id,Lead> leadsToInsert = new map<Id,Lead>(); 
        Lead newLead; 
        Contact newContact;
        Id masterLeadRTId =  Schema.SObjectType.Lead.getRecordTypeInfosByName().get(settings.New_Lead_Recordtype__c).getRecordTypeId();
        Map<Id,Contact> accountContactMap =  getAccountContactMap(opportunities); 
        
        for(Opportunity currOpp : opportunities) {
            newLead = new Lead(); 
            
            newLead.Company = currOpp.Account.Name; 
            //BZAP-4142: use the newst contact created on an account if the Opportunity's DM is null. 
            if(currOpp.Decision_Maker__r == null 
                    && accountContactMap != null 
                    && accountContactMap.containsKey(currOpp.AccountId) ) {
                newContact = accountContactMap.get(currOpp.AccountId); 
                newLead.FirstName = newContact.FirstName; 
                newLead.LastName = newContact.LastName; 
                newLead.Phone = newContact.Phone; 
                newLead.Email = newContact.Email; 
            } else if( currOpp.Decision_Maker__r != null) {
                if(currOpp.Decision_Maker__r.LastName == null 
                        || currOpp.Decision_Maker__r.LastName == ''){
                    newLead.LastName = '[null]';
                } else {
                    newLead.LastName = currOpp.Decision_Maker__r.LastName; 
                }
                newLead.FirstName = currOpp.Decision_Maker__r.FirstName;
                newLead.Email = currOpp.Decision_Maker__r.Email; 
                newLead.Phone = currOpp.Decision_Maker__r.Phone; 
            } else {
                continue; 
            }
            newLead.LeadSource = currOpp.LeadSource; 
            newLead.Lead_Source_Detail__c = currOpp.Lead_Source_Detail__c;
            newLead.Status = settings.New_Lead_Status__c;
            newLead.Reopened_Reason__c = reopenedReason;
            newLead.Reopened_Lead__c = true; 
            newLead.Lead_Reopen_Date__c = System.Today(); 
            newLead.Account__c = currOpp.AccountId; 
            newLead.Parent_Account__c = currOpp.Account.ParentId; 
            newLead.Deck_Rank__c = currOpp.Account.Deck_Rank__c;
            if(currOpp.Account.Account_Type__c == 'Auto-Onboard') {
                newLead.Type__c = settings.New_Lead_Auto_Onboard_Valuee__c; 
            } else {
                newLead.Type__c = currOpp.Account.Account_Type__c; 
            }
            newLead.OwnerId = Id.valueof(ownerId);
            newLead.Last_Meeting_Ran__c = currOpp.Account.Last_Meeting_Ran__c; 
            newLead.Amount__c = currOpp.Amount; 
            newLead.RecordTypeId = masterLeadRTId; 
            newLead.Opportunity__c = currOpp.Id;
            newLead.Street = currOpp.Account.BillingStreet; 
            newLead.StateCode = currOpp.Account.BillingStateCode; 
            newLead.State = currOpp.Account.BillingState; 
            newLead.PostalCode = currOpp.Account.BillingPostalCode;
            newLead.Longitude = currOpp.Account.BillingLongitude;
            newLead.Latitude = currOpp.Account.BillingLatitude; 
            newLead.CountryCode = currOpp.Account.BillingCountryCode; 
            newLead.Country = currOpp.Account.BillingCountry; 
            newLead.City = currOpp.Account.BillingCity; 
            if(reopenedReason == settings.Never_Went_Live_Reopened_Reason__c) {
                newLead.Mx_Rescue_Original_Closed_Won_Date__c = currOpp.CloseDate; 
                newLead.Mx_Rescue_Original_Needs_Rescuing_Date__c = currOpp.Mx_Needs_Rescuing_Date__c;
            }
            leadsToInsert.put(currOpp.id, newLead);
        }
        return leadsToInsert; 
        
    }
    /**
    * @description  Get map of Account Id and Contact. Map contains the newest contact that has 
    *                 phone number and email.
    * @param        List of Opportunities
    */
    public Static Map<Id, Contact>  getAccountContactMap (List<Opportunity> opportunities){
        Set<Id> accountIds = new Set<Id>(); 
        Map<Id, Contact> accountContactMap = new Map<Id, Contact>(); 
        for(Opportunity currOppty : opportunities) {
            if(currOppty.Decision_Maker__c == null) {
                accountIds.add(currOppty.AccountId);
            }
        }

        List<Contact> contacts = [Select Id, FirstName, Lastname, Phone, Email, CreatedDate, AccountId
                                     FROM Contact 
                                     WHERE accountId in : accountIds];
        for(Contact con : contacts){ 
            if(con.Phone != NULL && con.email != NULL){    
                if(accountContactMap.containsKey(con.accountId)){ 
                    if(accountContactMap.get(con.accountId).CreatedDate < con.CreatedDate) {
                        accountContactMap.put(con.accountId, con);
                    }
                } else {
                    accountContactMap.put(con.accountId, con);
                }
            }
        }
        return accountContactMap;
    }
}