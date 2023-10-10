/**
* @author: Sriram
* @date: 2021-02
* @description Neverbounce Process Jobs
*/ 
public class CDdNeverbounceProcessJobsBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts  {

    private Set<String> jobIds = new Set<String>();

    public CDdNeverbounceProcessJobsBatch(Set<String> jobIds){
        this.jobIds = jobIds;
    }    

    public Iterable<String> start(Database.BatchableContext BC) {
        return (Iterable<String>)jobIds;
    }

    public void execute(Database.BatchableContext BC, String[] scope) {
        List<Lead> leads = new List<Lead>();
        List<String> errorMessages = new List<String>();
        for (String jobId : scope){
            String jobStatus = CDdNeverbounceHandler.getJobStatus(jobId);
            switch on jobStatus {
                when 'complete' {            
                    Map<String, String> results = CDdNeverbounceHandler.getJobResults(jobId);
                    if (results != null){
                        for (String key : results.keySet()){
                            leads.add(new Lead(
                                Id = Id.valueOf(key),
                                Email_Verification_Status__c = results.get(key),
                                Email_Updated__c = false
                            ));
                        }
                    }
                }
                when else {}
            }
        }
        if (!leads.isEmpty()){
            Database.SaveResult[] updateResults = Database.update(leads, false);
            errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdNeverbounceProcessJobsBatch');
            }     
        }
    }

    public void finish(Database.BatchableContext BC) {
    }
}