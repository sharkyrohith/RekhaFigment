/********************************************************************************************************************
* @author ebby
* @date 12/08/2021
*
* @group Merchant Services
*
* @description Class to schedule CDdMxSxBatchSegmentLogHandler batch class. The class will be scheduled evert 30/60 minutes to fetch the segment logs and re-process if needed
* 
**************************************************************************************************************************************/
public class CDdMxSxBatchSegmentLogScheduler implements Schedulable{
    private Integer batchSize;
    private Integer lastModifiedDays;
    private Integer lastModifiedTimeInMinutes;
    /** 
     * @description Default constructor
     */ 
    public CDdMxSxBatchSegmentLogScheduler() {
        batchSize = CDdMxSxSegmentConstants.DEFAULT_BATCH_SIZE;
        lastModifiedDays = CDdMxSxSegmentConstants.DEFAULT_BATCH_LAST_MODIFIED_DAYS;
        lastModifiedTimeInMinutes = CDdMxSxSegmentConstants.DEFAULT_MINUTES_FOR_LOG_HANDLER;
    }
    /** 
     * @description two argument constructor
     * @param Integer batchSize - Batch size for he batch class to be invoked
     * @param Integer lastModifiedDays - records to be fetched from (from the last Modified days)
     */
    public CDdMxSxBatchSegmentLogScheduler(Integer batchSize, Integer lastModifiedDays, Integer lastModifiedTimeInMinutes) {
        this.batchSize = (batchSize!=null)? batchSize:CDdMxSxSegmentConstants.DEFAULT_BATCH_SIZE;
        this.lastModifiedDays = (lastModifiedDays!=null)?lastModifiedDays:CDdMxSxSegmentConstants.DEFAULT_BATCH_LAST_MODIFIED_DAYS;
        this.lastModifiedTimeInMinutes = (lastModifiedTimeInMinutes!=null)?lastModifiedTimeInMinutes:CDdMxSxSegmentConstants.DEFAULT_MINUTES_FOR_LOG_HANDLER;
    }
    /** 
    * @description Execute method to call the batch class with the batch size and parameter specified
    * @param SchedulableContext sc 
    */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CDdMxSxBatchSegmentLogHandler(this.lastModifiedDays, this.lastModifiedTimeInMinutes), this.batchSize);       
    }    
}