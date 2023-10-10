/********************************************************************************************************************
* @author ebby
* @date 12/08/2021
*
* @group Merchant Services
*
* @description Apex Batch to delete the old segment log records
* -  Based on the Number of days old - parameter to be passed or chosen from constants file
* - Based ont he status of the log records
* 
**************************************************************************************************************************************/
global class CDdMxSxBatchSegmentArchiveLogsHandler implements Database.Batchable<sObject>{
    private Integer lastModifiedDays;
    public static String QUERY = ' SELECT Id from Segment_Logs__c ' 
                                     + 'WHERE LastModifiedDate <= :lastUpdatedDate '
                                     + 'AND Status__c Not In :excludeLogStatus' ;
    /** 
     * @description Default constructor
     */                                 
    public CDdMxSxBatchSegmentArchiveLogsHandler() {
        this(CDdMxSxSegmentConstants.DEFAULT_BATCH_FOR_ARCHIVAL_LAST_MODIFIED_DAYS);
    }
    /** 
     * @description Single argument constructor
     * @param Integer lastModifiedDays - records to be fetched from (from the last Modified days)
     */
    public CDdMxSxBatchSegmentArchiveLogsHandler(Integer lastModifiedDays) {
        this.lastModifiedDays = lastModifiedDays!=null?lastModifiedDays:CDdMxSxSegmentConstants.DEFAULT_BATCH_FOR_ARCHIVAL_LAST_MODIFIED_DAYS;
    }
    /** 
    * @description Start the batch operation and prepare the Query to fetch the Segment Logs to delete
    */ 
    global Database.QueryLocator start(Database.BatchableContext bC) {
        DateTime lastUpdatedDate = System.Now().addDays(- this.lastModifiedDays);
        Set<String> excludeLogStatus = CDdMxSxSegmentConstants.LOG_STATUS_NOT_TO_DELETE ;
        return Database.getQueryLocator(QUERY);
    }
    /** 
    * @description Execute the logic to delete the fetched records based on the condition
    */ 
    global void execute(Database.BatchableContext bC, List<sObject> scope) {
        try{
            Database.Delete(scope, false);
        }
        catch(Exception e){
            insert CDdMxSxException.createErrorLog('CDdMxSxBatchSegmentArchiveLogsHandler', 'CDdMxSxBatchSegmentArchiveLogsHandler.execute', '', Logginglevel.ERROR, 'Milestone__c,',  null, e.getStackTraceString() + ' '+ e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bC){}
}