/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Batch job to create Master Lead from Opportunities that are lost and have a cool down period populated. 
 * The RecordTypeIds can be changed to include more values by updating the custom settings. 
 * Values should be in '<Value1>','<Value2>'.. format
 */
 
global class CDdBatchOpportunityCoolDown implements Database.Batchable<sObject> {
    
    String query;
    Opportunity_Inversion_Settings__c settings = Opportunity_Inversion_Settings__c.getInstance(); 
    List<String> errorMessages = new List<String> ();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        query = 'select id, Opportunity_Inversion_date__c, Account.of_CW_MP_Opps__c, Account.Name, ' 
                + ' Decision_Maker__r.FirstName,Decision_Maker__r.LastName, Decision_Maker__r.Email, ' 
                + 'Opportunity.Decision_Maker__r.Phone, LeadSource, Lead_Source_Detail__c, AccountId, ' 
                + 'Account.ParentId, Account.Deck_Rank__c, Account.Account_Type__c, OwnerId, ' 
                + 'Account.Last_Meeting_Ran__c, Account.BillingStreet, Account.BillingStateCode, Account.BillingState, '
                + 'Account.BillingPostalCode, Account.BillingLongitude, Account.BillingLatitude, ' 
                + 'Account.BillingCountryCode, Account.BillingCountry, Account.BillingCity , Amount ' 
                + 'From Opportunity  ' 
                + 'Where RecordtypeId in  ('+ settings.Opportunity_RT_Ids__c + ') '
                + 'AND IsClosed = TRUE '
                + 'AND Opportunity_Inversion_date__c = TODAY ' 
                + 'AND Cool_Down_Period__c != NULL ' 
                + 'AND Account.of_CW_MP_Opps__c = 0 ' 
                + 'AND Account.BillingPostalCode != null';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {

        Map<Id,Lead> leadsToInsert = CDdOpportunityInversionHelper.invertOpportunities(scope, 
                settings.New_Lead_Owner__c, settings.Reopened_Reason__c);
        try{
            if(!leadsToInsert.isEmpty()){
                List<Database.SaveResult> sResults = Database.insert(leadsToInsert.values(), false);
                for(Database.SaveResult sr : sResults) {
                    if(!sr.isSuccess() || Test.IsRunningTest()){
                        if((Test.IsRunningTest())){
                            errorMessages.add('Following records failed while processing "Opportunity Cool Down" job.');
                        }
                        for(Database.Error err : sr.getErrors()) {
                            errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' : Fields : ' + err.getFields()); 
                        }
                    } 
                }
            }
            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchOppCoolDown');
            }    
        } catch (Exception e) {
            errorMessages.add(e.getMessage());
            throw e;
        } finally {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchOppCoolDown');
        }
        

    }
    
    global void finish(Database.BatchableContext BC) {

    }
    
}