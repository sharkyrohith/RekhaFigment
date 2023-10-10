global class CDdBatchConvertLeadsToOpp implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    global string query;
    global static final string MASTER_LEAD_RT = 'Master_Lead';
    global static final string DOORDASH_DRIVE_LEAD_RT = 'DoorDash_Drive_Leads';
    global static final string DOORDASH_DRIVE_OPPORTUNITY_RT = 'DoorDash_Drive';
    global static final Set<String> INTEGRATION_USERS = new Set<String>{'Formstack Integration User','Mulesoft Integration User','Nintex Integration User'};
    global DateTime filterDateTime = System.now().addHours(-12);
    
    global void execute(SchedulableContext sc) {
        
        Database.executeBatch(new CDdBatchConvertLeadsToOpp(), CDdCustomMetadata.getBatchSize('CDdBatchConvertLeadsToOpp'));
    }
    
    global CDdBatchConvertLeadsToOpp(string q){
        this.query = q;
        //run below script to run for all existing records
        /*
        string q = 'SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = :DOORDASH_DRIVE_OPPORTUNITY_RT'
                                            +' AND CreatedBy.Name IN:INTEGRATION_USERS';
        Database.executeBatch(new CDdBatchConvertLeadsToOpp(q), CDdCustomMetadata.getBatchSize('CDdBatchConvertLeadsToOpp'));
        */
    }
    
    global CDdBatchConvertLeadsToOpp(){
        this.query = 'SELECT Id FROM Opportunity WHERE CreatedDate>:filterDateTime'
                                            +' AND RecordType.DeveloperName = :DOORDASH_DRIVE_OPPORTUNITY_RT'
                                            +' AND CreatedBy.Name IN:INTEGRATION_USERS';
    }
 
    global Database.QueryLocator start(Database.BatchableContext BC) {
                
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> processOpportunities) {
                
        List<Opportunity> opportunityList = [SELECT id, Name, IsClosed, DM_Email__c,Account.Name, 
                                            Accounting_Contact__c, Accounting_Contact_Email__c, Decision_Maker__c 
                                            FROM Opportunity WHERE id IN:processOpportunities];
                                                
        Set<String> accountNameMatchSet = new Set<String>();        
        Set<String> emailMatchSet = new Set<String>();

        for(Opportunity opp : opportunityList){
            
            if(string.isNotBlank(opp.DM_Email__c)){
                emailMatchSet.add(opp.DM_Email__c);
            }
            if(string.isNotBlank(opp.Account.Name)){
                accountNameMatchSet.add(opp.Account.Name);
            }
            if(string.isNotBlank(opp.Accounting_Contact_Email__c)){
                emailMatchSet.add(opp.Accounting_Contact_Email__c);
            }
        }
            
        List<Database.LeadConvert> leadConvertList = new List<Database.LeadConvert>();
        
        Map<String, Id> matchingLeads = getMatchingLeads(accountNameMatchSet,emailMatchSet);
        
        for(Opportunity opp : opportunityList){
            Id leadId = getMatchedLeadId(matchingLeads,opp);
            
            if(leadId == null){
                continue ;
            }
            
            Id contactId;
            if(opp.Decision_Maker__c != null){
                contactId = opp.Decision_Maker__c;
            }else if(opp.Accounting_Contact__c != null){
                contactId = opp.Accounting_Contact__c;
            }
            
            Database.LeadConvert objLC = new Database.LeadConvert();
            objLC.setLeadId(leadId);
            objLC.setAccountId(opp.AccountId);
            if(opp.IsClosed == True){
                objLC.setDoNotCreateOpportunity(true);
            }else{
                objLC.setOpportunityId(opp.Id);
            }
            objLC.setOwnerId(Userinfo.getUserId());
            objLC.setContactId(contactId);                    
            objLC.setConvertedStatus(Label.Lead_Convert_Status);//Meeting Set

            leadConvertList.add(objLC);            
            
        }
        if(!leadConvertList.isEmpty()){
            List<Database.Error> errors = new List<Database.Error>();
            List<Database.LeadConvertResult> cdlSaveResults = Database.convertLead(leadConvertList, false);
            for (Database.LeadConvertResult cdlSaveResult : cdlSaveResults) {
                errors.addAll(cdlSaveResult.getErrors());
            }
    
            insertApexLogs(errors);
        }
    }
    
    private Id getMatchedLeadId(Map<String, Id> matchingLeads, Opportunity opp){
        Id leadId = null;
        if(matchingLeads.containsKey(opp.DM_Email__c)){
            leadId = matchingLeads.get(opp.DM_Email__c);
            
        }else if(matchingLeads.containsKey(opp.Accounting_Contact_Email__c)){
            leadId = matchingLeads.get(opp.Accounting_Contact_Email__c);
            
        }else if(matchingLeads.containsKey(opp.Account.Name)){
            leadId = matchingLeads.get(opp.Account.Name);
            
        }
        return leadId;
    }
    
    private Map<String, Id> getMatchingLeads(Set<string> accountNameMatchSet, Set<string> emailMatchSet){
        Map<String, Id> matchingLeads = new Map<String, Id>();
        
        List<Lead> lstLead = [SELECT id, Name, Company, Street, City, State, PostalCode, Country, Email, Phone 
                                FROM Lead WHERE isConverted = false 
                                AND Primary_Campaign_Source__r.Name =:Label.CampaignNameMxAcqMktg_BOFU
                                AND (RecordType.DeveloperName =:MASTER_LEAD_RT
                                    OR RecordType.DeveloperName = :DOORDASH_DRIVE_LEAD_RT)                                
                                AND (Company IN:accountNameMatchSet
                                OR Email IN:emailMatchSet) order by CreatedDate];
                
        for(Lead objLead : lstLead){
            matchingLeads.put(objLead.Company, objLead.Id); 
            matchingLeads.put(objLead.Email, objLead.Id);            
        }
        
        return matchingLeads;
    }
    
    private void insertApexLogs(List<Database.Error> errors) {
        List<Apex_Log__c> logs = new List<Apex_Log__c>();
        for (Database.Error error : errors) {
            Apex_Log__c log = new Apex_Log__c();
            log.Class_Name__c = 'CDdBatchConvertLeadsToOpp';
            log.Method_Name__c = 'execute';
            log.Log_Level__c = 'Error';
            log.Log__c = error.getMessage();
            logs.add(log);
        }
        insert logs;
    }
    
    global void finish(Database.BatchableContext BC) {

    }
}