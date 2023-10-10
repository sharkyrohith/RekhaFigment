/**
 *
 * @author  Ayushi Agarwal
 * @date    May 10th, 2023
 * @decription BZAP-19868- A scheduler class for CDdBatchMissingOrdersOnClosedWonOpp batch class.
 */
public class CDdScheduleMissingOrdersOnClosedWonOpp implements Schedulable {

    Integer lastNDays;

    public void execute(SchedulableContext sc) {
        lastNDays = Integer.valueOf(System.Label.Filter_Records_by_Number_of_Days);
        CDdBatchMissingOrdersOnClosedWonOpp batch = new CDdBatchMissingOrdersOnClosedWonOpp(lastNDays);
        Database.executeBatch(batch, CDdCustomMetadata.getBatchSize('CDdBatchMissingOrdersOnClosedWonOpp'));
    }
}