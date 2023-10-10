/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Schedule class for Scheduling CDdBatchOppCoolDown batch job. 
 *
 */
global class CDdScheduleOpportunityCoolDown implements Schedulable {
    global void execute(SchedulableContext sc) {
        CDdBatchOpportunityCoolDown coolDownBatch = new CDdBatchOpportunityCoolDown();
        database.executebatch(coolDownBatch);
    } 
}