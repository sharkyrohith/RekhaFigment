public class CDdScheduleCasesToSolved implements Schedulable {
    public void execute(SchedulableContext sc) {
        CDdBatchCaseToSolved batch = new CDdBatchCaseToSolved();
        Database.executeBatch(batch, 100);
    }
}