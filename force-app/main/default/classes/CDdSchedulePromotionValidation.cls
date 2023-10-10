public class CDdSchedulePromotionValidation implements Schedulable {
    public void execute(SchedulableContext sc) {
        CDdBatchPromotionValidation batch = new CDdBatchPromotionValidation();
        Database.executeBatch(batch, 100);
    }
}