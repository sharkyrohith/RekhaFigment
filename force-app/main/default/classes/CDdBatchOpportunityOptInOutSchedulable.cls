/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
 *
 * Implements BZAP-7091: Scheduled Batch job for opted-in franchise opps (Closed Won)
 * Implements BZAP-7214: Scheduled Batch job for opted-out franchise opps (Closed Lost)
 */
global class CDdBatchOpportunityOptInOutSchedulable implements Schedulable {
    global void execute(System.SchedulableContext ctx) {
        Database.executeBatch(new CDdBatchOpportunityOptInOut());
    }
}