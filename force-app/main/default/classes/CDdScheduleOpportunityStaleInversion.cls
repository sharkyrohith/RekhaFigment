/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Schedule class for Scheduling CDdBatchOpportunityStaleInversion batch job. 
 *
 */
global class CDdScheduleOpportunityStaleInversion implements Schedulable {
    global void execute(SchedulableContext sc) {
        CDdBatchOpportunityStaleInversion staleOpportunityInversionBatch = new CDdBatchOpportunityStaleInversion();
        database.executebatch(staleOpportunityInversionBatch, 20);
    } 
}