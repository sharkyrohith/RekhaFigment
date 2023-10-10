/*
 * @component: CDdBatchDeleteSupportTrainingCaseRec
 * @author: Ashutosh Anand
 * @date: 2021-10-15
 * @description: Batch class is responsible to delete Case records for Support Training Record type.
 * The Batch class is also Schedulable and will be scheduled once to Run daily
 */
global class CDdBatchDeleteSupportTrainingCaseRec implements Database.Batchable<sObject>, Database.Stateful{
    // variables
    private static final String USER_ROLE_NAME = String.valueOf(System.Label.Support_Training_Records_User_Role);
    private static final Integer BATCH_CYCLE_DAYS_LIMIT = Integer.valueOf(System.Label.Support_Training_Records_Deletion_Cycle); 
    private static final Id CASE_SUPPORT_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Training').getRecordTypeId();
    private static final Integer SCHINTERVAL = 1440;
    private static final String ERROR_MSG1 = 'Provided a numeric value in Custom Label Support_Training_Records_Deletion_Cycle: Should be Days interval.';
    private static final String JOB_NAME = 'Case TrainingSupport Delete Job';
    
    global String schJobName;
    global String createdDateLimit;
    global Boolean isFirstCall;    
    global Date initialStartDate;
    global Boolean isSchedulable;
    global Integer totalNoOfRecords = 0;
    global Integer noOfRecordsDeleted = 0;
    global List<String> errorMessages = new List<String>();
    
    // Constructor
    global CDdBatchDeleteSupportTrainingCaseRec(Date batchStartDate, Integer executionInterval, Boolean isFirstCall, Boolean needReRun, String jobName) {
        this.initialStartDate = batchStartDate;
        this.isFirstCall = isFirstCall;
        this.isSchedulable = needReRun;
        this.createdDateLimit = String.valueOf(BATCH_CYCLE_DAYS_LIMIT);
        this.schJobName = jobName;
        if (needReRun && !isFirstCall && executionInterval != BATCH_CYCLE_DAYS_LIMIT) {
            this.isFirstCall = true;
            this.initialStartDate = System.today();
            
            // If Custom Label value changes, Run the Query per previous interval value for the Last time
            this.createdDateLimit = String.valueOf(executionInterval);
        }
    }

    // Constructor for single Batch Run & nonSchedulable.
    // Param should be Support_Training_Records_Deletion_Cycle Custom label
    global CDdBatchDeleteSupportTrainingCaseRec(String createdBefore) {
        this.isSchedulable = false;
        this.createdDateLimit = createdBefore;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        if (createdDateLimit.isNumeric()) {
            query = 'SELECT ID, Owner.UserRole.Name FROM CASE WHERE RecordTypeId =: CASE_Support_RECORDTYPEID '
                    + 'AND Owner.UserRole.Name !=: USER_ROLE_NAME AND CreatedDate < LAST_N_DAYS:' + Integer.valueOf(createdDateLimit);
            
        } else {
            errorMessages.add(ERROR_MSG1);
        }
        
        // if errors create apex logs 
        if(!errorMessages.isEmpty()){
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchDeleteSupportTrainingCaseRec');
            errorMessages.clear();
            System.abortJob(bc.getJobId());
            return null;
            
        }
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext bc, List<Sobject> scope) {
        try {
            if (!isSchedulable || isFirstCall || initialStartDate.daysBetween(System.today()) == BATCH_CYCLE_DAYS_LIMIT) {
                
                List<Database.DeleteResult> drList = Database.delete(scope, false);
                List<string> deleteIds = new List<string>();
                
                // Iterate through each returned result
                for(Database.DeleteResult dr : drList) {
                    if (dr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        deleteIds.add(dr.getId());
                    } else {
                        // get the error details 
                        for(Database.Error err : dr.getErrors()) {
                            errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' : Fields : ' + err.getFields()); 
                        }
                    }
                    
                }
                // if errors create apex logs 
                if(!errorMessages.isEmpty()) {
                    CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchDeleteSupportTrainingCaseRec');
                    errorMessages.clear();
                }  
                
                noOfRecordsDeleted = noOfRecordsDeleted + deleteIds.size(); 
                totalNoOfRecords = totalNoOfRecords + scope.size();
            }
            
        } catch( exception e) {
            system.debug('error message '+e.getMessage());
            
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        if (isSchedulable) {
            if (!isFirstCall && initialStartDate.daysBetween(System.today()) == BATCH_CYCLE_DAYS_LIMIT) {
                initialStartDate = System.today();
            }
            
            List<CronTrigger> ct = [
                SELECT Id,
                CronExpression,
                TimesTriggered,
                NextFireTime,
                CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name =: schJobName
            ];
            if(ct.size() == 0){
                CDdBatchDeleteSupportTrainingCaseRec deleteBatch = new CDdBatchDeleteSupportTrainingCaseRec(initialStartDate, BATCH_CYCLE_DAYS_LIMIT, false, true, schJobName);
                System.scheduleBatch(deleteBatch, schJobName, SCHINTERVAL);   
            }
        }
    }
}