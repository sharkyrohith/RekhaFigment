/*
 * 		Name:		sched_batchSendNPSEmails
 * 		Date:		3/2016
 * 		Author:		Cole Conroy - RoyCon Tech
 * 		Desc:		Schedules the batachable_SendNPSEmails class. 
 * 
 */

global class sched_batchSendNPSEmails implements Schedulable {
	global void execute(SchedulableContext ctx) {
		batch_SendNPSEmails batchable = new batch_SendNPSEmails();
		DataBase.executeBatch(batchable);
		System.abortJob(ctx.getTriggerId());
	}
}