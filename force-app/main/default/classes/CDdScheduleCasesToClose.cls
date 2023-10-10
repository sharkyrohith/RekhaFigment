public class CDdScheduleCasesToClose implements Schedulable {
    public void execute(SchedulableContext sc) {
        CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
        Database.executeBatch(batch, 100);
    }
}