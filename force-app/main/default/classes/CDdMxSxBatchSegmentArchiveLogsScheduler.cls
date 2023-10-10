/********************************************************************************************************************
* @author ebby
* @date 12/08/2021
*
* @group Merchant Services
*
* @description Class to schedule CDdMxSxBatchSegmentArchiveLogsHandler batch class. The class will be scheduled once a day and olf segment record files will be deleted (older than 60 days)
* 
**************************************************************************************************************************************/
public class CDdMxSxBatchSegmentArchiveLogsScheduler implements Schedulable {
    private Integer batchSize;
    private Integer lastModifiedDays;
    /** 
     * @description Default constructor
     */ 
    public CDdMxSxBatchSegmentArchiveLogsScheduler() {
        this(CDdMxSxSegmentConstants.DEFAULT_BATCH_FOR_ARCHIVAL_SIZE, CDdMxSxSegmentConstants.DEFAULT_BATCH_FOR_ARCHIVAL_LAST_MODIFIED_DAYS);
    }
    /** 
     * @description two argument constructor
     * @param Integer batchSize - Batch size for he batch class to be invoked
     * @param Integer lastModifiedDays - records to be fetched from (from the last Modified days)
     */
    public CDdMxSxBatchSegmentArchiveLogsScheduler(Integer batchSize, Integer lastModifiedDays) {
        this.batchSize = (batchSize!=null)? batchSize:CDdMxSxSegmentConstants.DEFAULT_BATCH_FOR_ARCHIVAL_SIZE;
        this.lastModifiedDays = (lastModifiedDays!=null)?lastModifiedDays:CDdMxSxSegmentConstants.DEFAULT_BATCH_FOR_ARCHIVAL_LAST_MODIFIED_DAYS;
    }
    /** 
    * @description Execute method to call the batch class with the batch size and parameter specified
    * @param SchedulableContext sc 
    */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CDdMxSxBatchSegmentArchiveLogsHandler(this.lastModifiedDays), this.batchSize);       
    }   
}