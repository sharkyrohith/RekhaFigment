/**
* @author: Tia Xuan
* @date: 2020-02
* @description Neverbound weekly batch
*/ 
public class CDdNeverbounceWeeklyBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts, Schedulable  {

    public static final Set<String> RECORD_TYPE_IDS = CDdNeverbounceHandler.leadRecordTypeIds;
    public static final String QUERY_SELECT = 'SELECT Id, Email '
                                            + ' FROM Lead '
                                            + ' WHERE RecordTypeId IN :RECORD_TYPE_IDS '
                                            + ' AND Email != null '
                                            + ' AND Email_Updated__c = true '
                                            + ' AND IsConverted = false ';
    public static String QUERY_FILTER_RECORD_IDS = ' AND (Id IN :recordIds) ';                                              
    public static final String QUERY_LIMIT = ' LIMIT ' + CDdNeverbounceHandler.TOTAL_SIZE;
    private Set<Id> recordIds;
    private Boolean singleCheckVerifyEmail = false;
    private String query;

    public void execute(SchedulableContext sc) {
        CDdNeverbounceWeeklyBatch batch = new CDdNeverbounceWeeklyBatch();
        Database.executeBatch(batch, CDdNeverbounceHandler.BATCH_SIZE);
    }

    public CDdNeverbounceWeeklyBatch(){
        setQuery();
    }

    public CDdNeverbounceWeeklyBatch(Set<Id> recordIds){
        this.recordIds = recordIds;
        this.singleCheckVerifyEmail = CDdNeverbounceHandler.ENABLED_SINGLE_CHECK_VERIFY_EMAIL && (this.recordIds!=null) && (this.recordIds.size() <= CDdNeverbounceHandler.PLATFORM_EVENT_VERIFY_EMAIL_SIZE);
        setQuery();
    }

    private void setQuery(){
        this.query = QUERY_SELECT 
                        + (this.recordIds != null && !this.recordIds.isEmpty() ? QUERY_FILTER_RECORD_IDS : '')
                        + QUERY_LIMIT;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext BC, List<Sobject> scope) {
        if (this.singleCheckVerifyEmail){
            CDdNeverbounceHandler.verifyEmails(scope);
        } else {
            Set<String> jobIds = new Set<String>();
            String jobId = CDdNeverbounceHandler.createJob(CDdNeverbounceHandler.getCreateJobRequestData(scope));
            if (String.isNotBlank(jobId)){
                jobIds.add(jobId);
            }
            if (!jobIds.isEmpty()){
                CDdNeverbounceHandler.insertNeverbounceTasks(jobIds, CDdNeverbounceHandler.SOBJECT_TYPE_LEAD, CDdNeverbounceHandler.NEVERBOUNCE_JOB_STATUS_CREATED);
            }             
        }
    }

    public void finish(Database.BatchableContext BC) {
    }
}