global class CDdScheduleReopenLead implements Schedulable {
	global void execute(SchedulableContext sc) {
		CDdBatchReopenLead reopenBatch = new CDdBatchReopenLead();
		database.executebatch(reopenBatch);
	}
}