/********************************************************************************************************************
* @author Sriram
* @date 11/17/2021
*
* @group Merchant Services
*
* @description Apex Batch scheduler class that will retry the Merchant Services events that had an error/exception in the prior attempt
*
* MxSx events with errors are written to the logs. The scheduled batch job will read from the log object and reprocess
* 
**************************************************************************************************************************************/
public class CDdMxSxBatchEventExceptionSched implements Schedulable {
    private Integer batchSize;
    private Integer lastModifiedDays;
   /** 
    * @description Default constructor
    */
    public CDdMxSxBatchEventExceptionSched() {
        this(CDdMxSxConstants.DEFAULT_BATCH_LAST_MODIFIED_DAYS);
    }    
   /** 
    * @description A single argument constructor
    * @param lastModifiedDays - How many days do you go in the past, to read for the error entries that were recorded in the log?
    */
    public CDdMxSxBatchEventExceptionSched(Integer lastModifiedDays) {
        this(CDdMxSxConstants.DEFAULT_BATCH_SIZE, lastModifiedDays);
    }
   /** 
    * @description A two argument constructor
    * @param batchSize - What is the batch size?    
    * @param lastModifiedDays - How many days do you go in the past, to read for the error entries that were recorded in the log?
    */
    public CDdMxSxBatchEventExceptionSched(Integer batchSize, Integer lastModifiedDays) {
        this.batchSize = (batchSize != null ? batchSize : CDdMxSxConstants.DEFAULT_BATCH_SIZE);
        this.lastModifiedDays = (lastModifiedDays != null ? lastModifiedDays : CDdMxSxConstants.DEFAULT_BATCH_LAST_MODIFIED_DAYS);
    }
    /** 
    * @description Execute the MxSx Batch Job to retry the MxSx events that failed in the prior execution
    * @param SchedulableContext - schedulable context
    */	
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CDdMxSxBatchEventExceptionHandler(this.lastModifiedDays), this.batchSize);       
    }    
}