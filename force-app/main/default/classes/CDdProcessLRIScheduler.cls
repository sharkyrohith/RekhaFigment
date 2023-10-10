/**
 * CDdProcessLRIScheduler
 *
 * @author     Sahil (sahil.chaudhry@doordash.com)
 * @date       2022-05-17
 * @decription scheduler for CDdProcessLRIBatch
 */
public class CDdProcessLRIScheduler implements Schedulable {
    /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/
    public static Support_Settings__c SUPPORT_SETTINGS = Support_Settings__c.getInstance() == null ? 
                                                            new Support_Settings__c() : Support_Settings__c.getInstance();
    public static Integer CASE_UPDATE_BATCH_SIZE = Integer.valueOf(SUPPORT_SETTINGS.Case_Bulk_Update_Batch_Size__c != null ? 
                                                        SUPPORT_SETTINGS.Case_Bulk_Update_Batch_Size__c : 30);
     /*****************************************************************************************************************************
     *
     * Schedular Execute
     *
     ****************************************************************************************************************************/
    public void execute(SchedulableContext sc) {
        CDdProcessLRIBatch batch = new CDdProcessLRIBatch(CDdSupportConstants.OPERATION_CASE_UPDATES);
        Database.executeBatch(batch, CASE_UPDATE_BATCH_SIZE);
    }
}