/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Batch job to Reopen the Leads that have status = 'Not Interested - Cool Down', 
 *  and record type = Master Lead and Lead Reopen Date = Today. Update the lead's status to Untouched 
 *  and change the owner to Holding User. The Status and RecordTypeIds can be changed to include more 
 *  values by updating the custom settings. Values should be in '<Value1>','<Value2>'.. format
 */
global class CDdBatchReopenLead implements Database.Batchable<sObject> {
    
    String query;
    Opportunity_Inversion_Settings__c settings = Opportunity_Inversion_Settings__c.getInstance();     
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        query = 'Select Id, Status, Lead_Reopen_Date__c ' +
                    ' From Lead ' + 
                    ' Where Status in (' +settings.Lead_Status__c + ') '  + 
                    ' AND recordTypeId in ('+settings.Lead_RT_Ids__c + ')' +
                    ' AND Lead_Reopen_Date__c = TODAY' ;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Lead> leadsToUpdate = new List<Lead>(); 
        for(Lead currLead : scope) {
            currLead.Status = settings.New_Lead_Status__c; 
            currLead.ownerid = settings.Reopened_Lead_Owner__c;
            currLead.Reopened_Lead__c = true;
            currLead.Reopened_Reason__c = settings.Reopened_Reason__c;
            currLead.Lead_Reopen_Date__c = System.today(); 
            leadsToUpdate.add(currLead);
        }

        if(leadsToUpdate.size() > 0) {
            List<Database.SaveResult> sResults = Database.update(leadsToUpdate,false);
        }
    }
    
    global void finish(Database.BatchableContext BC) {

    }
    
}