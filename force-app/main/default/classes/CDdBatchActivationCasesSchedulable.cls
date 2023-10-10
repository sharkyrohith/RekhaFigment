/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
 *
 * Implements BZAP-7492: Scheduled Batch Job for bulk activation cases
 * Implements BZAP-7352: Scheduled Batch Job for bulk deactivation case
 */
global class CDdBatchActivationCasesSchedulable implements Schedulable {
    global void execute(System.SchedulableContext ctx) {
        Database.executeBatch(new CDdBatchActivationCases());
        Database.executeBatch(new CDdBatchDeactivationCases());
    }
}