/********************************************************************************************************************
* @author Lathika
* @date 04/15/2022
*
* @group Merchant Services
*
* @description Apex Batch scheduler class for CDdMxOrderBatch, BZAP-14359
* 
**************************************************************************************************************************************/
public class CDdMxOrderBatchScheduler implements Schedulable {
    private CDdMxOrderBatchEnum batchEnum;
    private CDdMxOrderBatchConfig config;
    /**
     * @description Default constructor
     */
    public CDdMxOrderBatchScheduler(CDdMxOrderBatchEnum batchEnum) {
      this.batchEnum = batchEnum;
      this.config = new CDdMxOrderBatchConfig(this.batchEnum);
    }    
    /** 
     * @description Execute the CDdMxOrderBatch Job for the specific Mx Order Batch Event
     * @param SchedulableContext - schedulable context
     * @return
     */	
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CDdMxOrderBatch(this.batchEnum), config.getBatchSize());       
    }            
}