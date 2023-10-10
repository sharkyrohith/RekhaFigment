/********************************************************************************************************************
* @author Veera
* @date 04/26/2022
*
* @group Merchant Services
*
* @description Scheduler class for Merchant Support event Batch class (CDdMxSupportEventBatch)
* 
**************************************************************************************************************************************/
public class CDdMxSupportEventScheduler implements Schedulable {

    public void execute(SchedulableContext sc){
        CDdMxSupportEventEnum firstEvent = CDdMxSupportEventConfig.getFirstMxSupportEvent();
        if(firstEvent != null){
            CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(firstEvent);
            Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(firstEvent));
        }
    }
}