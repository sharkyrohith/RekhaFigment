/**
 * @author  Sanidhya Jain
 * @date    January 2023
 * @description This is the Batch which will close cases which were not modified from Last Six Months
 */
public class CloseOpenCaseOfLastSixMonBatch Implements Database.Batchable<Sobject>, Schedulable {
    /*****************************************************************************************************************************
    *
    * Public Variables & Fields
    *
    *****************************************************************************************************************************/
    public static final List<String> CUSTOMER_TYPE = new List<String>{'Consumer','Dasher','Merchant'};
    public static final List<String> REC_TYPE_DEV_NAME = new List<String>{'API','Customer'};
    public static final List<String> CASE_STATUS = new List<String>{'Open','Pending','Waiting for DD Internal Team'};
	public static final List<String> OWNER_LIST = new List<String>{'Legal Claims','Legal Escalations (Japan)','DE - T&S Legal Escalations Queue'};
    public List<String> error_Message = new List<String>();
    /*****************************************************************************************************************************
    *
    * Start
    *
    ****************************************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return CasesSelector.newInstance().selectOpenCasesFromLastSixMonths(REC_TYPE_DEV_NAME,CASE_STATUS,CUSTOMER_TYPE,OWNER_LIST);
    }

    /*****************************************************************************************************************************
    *
    * execute
    *
    ****************************************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<Case> scope) {
        List<String> errorList = new List<String>();
        try{
            errorList = CloseOpenCasesRequestService.updateOpenCasestoClose(scope);
        }catch(Exception e){
            CDdErrorUtilities.publishException('CloseOpenCaseOfLastSixMonBatch', 'execute', e);
        }
        if(errorList != null && errorList.size() > 0){
            error_Message.addAll(errorList);
            CDdErrorUtilities.createApexLogs(errorList,'CloseOpenCaseOfLastSixMonBatch');
        }
    }
    /*****************************************************************************************************************************
    *
    * Finish
    *
    ****************************************************************************************************************************/
    public void finish(Database.BatchableContext bc){
    }

    public void execute(SchedulableContext sc) {
        Integer batchSize = CDdCustomMetadata.getBatchSize('CloseOpenCaseOfLastSixMonBatch');
        if(batchSize != null && batchSize > 0){
        	Database.executeBatch(new CloseOpenCaseOfLastSixMonBatch(), batchSize);
        }
    }

}