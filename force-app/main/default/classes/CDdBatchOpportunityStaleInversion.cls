/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Batch job to update Opportunity stage to close lost for stale opportunities, and create a new lead for that opportunity. 
 *
 *
 */
 
global class CDdBatchOpportunityStaleInversion implements Database.Batchable<sObject> {
    public static final Id OPP_MARKETPLACE_RT_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
                                                    .get('Marketplace').getRecordTypeId();
    String query; 
    Opportunity_Inversion_Settings__c settings = Opportunity_Inversion_Settings__c.getInstance(); 
    List<String> errorMessages = new List<String>(); 

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String createdDateStr = Test.IsRunningTest()
                                ? String.valueOf(Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'))
                                : 'LAST_90_DAYS';
        query =  ' SELECT id, StageName, Lost_Reason__c, Lost_Reason_Detail__c, Opportunity_Inversion_date__c, Account.of_CW_MP_Opps__c, Account.Name, Account.OwnerId, ' 
                +       ' Decision_Maker__r.FirstName,Decision_Maker__r.LastName, Decision_Maker__r.Email, ' 
                +       ' Opportunity.Decision_Maker__r.Phone, LeadSource, Lead_Source_Detail__c, AccountId, ' 
                +       ' Account.ParentId, Account.Deck_Rank__c, Account.Account_Type__c, OwnerId, Owner.ProfileId, ' 
                +       ' Account.Last_Meeting_Ran__c, Account.BillingStreet, Account.BillingStateCode, Account.BillingState, '
                +       ' Account.BillingPostalCode, Account.BillingLongitude, Account.BillingLatitude, Account.Parent.Owner.ProfileId, '
                +       ' Account.BillingCountryCode, Account.BillingCountry, Account.BillingCity , Amount, Account.Parent.OwnerId ' 
                +' FROM Opportunity ' 
                +' WHERE RecordTypeId = :OPP_MARKETPLACE_RT_ID' 
                +       ' AND isWon = FALSE ' 
                +       ' AND Lost_Reason__c != \'Lack of Activity\' ' 
                +       ' AND Opportunity_Inversion_Date__c = null ' 
                +       ' AND Reopened_Lead_Created__c = FALSE '
                +       ' AND createddate <  ' + createdDateStr
                +       ' AND (((Next_Step_Date__c < Today OR Next_Step_Date__c = null)' 
                +                 ' AND StageName NOT IN (\'Contract Signed\', \'Out for Signature\'))'
                +           ' OR (NextStep = NULL AND CloseDate < TODAY AND StageName = \'Out for Signature\'))';
        errorMessages.add('Query = ' + query);
        CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchOpportunityStaleInversion');
        errorMessages = new List<string>();
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        
        Map<Id, User> accountManagerIds = getAccountManagerIds(); 
        List<Opportunity> opportunitiesForInversion = new List<Opportunity>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>(); 
        Map<Id,Lead> oppIdLeadMap;
        for(Opportunity currOppty : scope) {
            //Do not Update opps where the account owner is active and is in the Account Manager profile
            if(!accountManagerIds.isEmpty() 
                && !accountManagerIds.containsKey(currOppty.Account.OwnerId) && currOppty.StageName != 'Closed Lost' && currOppty.Lost_Reason__c == null && currOppty.Lost_Reason_Detail__c == null){
                currOppty.StageName = 'Closed Lost'; 
                currOppty.Lost_Reason__c = 'Lack of Activity';
                currOppty.Lost_Reason_Detail__c = 'Auto Closed';
                opportunitiesToUpdate.add(currOppty);
                // If the Opportunity Owner or Opportunity.Account.Parent Account's Owner has account manager profile do not createa  lead. 
                // Since Email, Phone and Address are required to create a lead, do not attempt to create a lead Decision Maker, 
                // Billing postcode or phone are null. 
                if( !accountManagerIds.isEmpty() 
                        && !accountManagerIds.containsKey(currOppty.ownerId) 
                        && !accountManagerIds.containsKey(currOppty.Account.ownerId)
                        && !(currOppty.Account.ParentId != null 
                            && accountManagerIds.containsKey(currOppty.Account.Parent.ownerId))
                        && currOppty.Account.of_CW_MP_Opps__c == 0
                        && currOppty.Account.BillingPostalCode != null
                        ) {
                    opportunitiesForInversion.add(currOppty);
                } 
            }
        }
        

        if(opportunitiesForInversion.size() > 0 ) {
            oppIdLeadMap = CDdOpportunityInversionHelper.invertOpportunities(opportunitiesForInversion, 
                    settings.New_Lead_Owner__c, settings.Inversion_Lead_Reopened_Reason__c);
        }
        try{
            if(oppIdLeadMap != null && !oppIdLeadMap.isEmpty()){
                List<Database.SaveResult> sResults = Database.insert(oppIdLeadMap.values(), false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
            }
            // if a lead was created for the opportunity update the reopend lead created flag to true
            // and populate the id of the lead that was created for this opportunity. 
            for(Integer i = 0; i < opportunitiesToUpdate.size(); i ++) {
                if(oppIdLeadMap.containsKey(opportunitiesToUpdate[i].id)) {
                    opportunitiesToUpdate[i].Reopened_Lead_Created__c = true;
                    opportunitiesToUpdate[i].Reopened_Lead_Created_ID_18__c 
                        = String.valueof(oppIdLeadMap.get(opportunitiesToUpdate[i].id).Id); 
                }
            }
            if(!opportunitiesToUpdate.isEmpty()) {
                List<Database.SaveResult> sResults = Database.update(opportunitiesToUpdate, false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
            }                
        } catch (Exception e) {
            errorMessages.add(e.getMessage());
            throw e;
        }
        if(!errorMessages.isEmpty()){
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchOpportunityStaleInversion');
        }
    }

    global void finish(Database.BatchableContext BC) {
        
    }
    /**
    * @description Get all the users that have AccountManager profile
    * 
    */
    private Map<Id, User>  getAccountManagerIds (){
        Map<Id, User> managerMap = new Map<Id, User>([
                Select id, isActive
                FROM User 
                WHERE profileId =: settings.Profile_Id__c 
                    AND isActive = true
                    AND (NOT Name like '%Holding User%') ]); 
        return managerMap;
    }

}