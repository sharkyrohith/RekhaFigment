/**
 * @author  Mahesh Chouhan
 * @date    April 2023
 * @description Batch job to close or resassign cases held by inactive agents
 */
public class ProcessInactiveCaseBatch implements Database.Batchable<SObject>, Schedulable{

    @TestVisible
    public static final Set<String> CASE_ORIGINS = new Set<String>{CDdSupportConstants.CASE_ORIGIN_PHONE, CDdSupportConstants.CASE_ORIGIN_CHAT,
        CDdSupportConstants.CASE_ORIGIN_WEB, CDdSupportConstants.CASE_ORIGIN_EMAIL, CDdSupportConstants.RECORDTYPE_NAME_API};
    /*****************************************************************************************************************************
    *
    * Start
    *
    ****************************************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return CasesSelector.newInstance().selectOpenCasesWithInactiveOwner(CASE_ORIGINS);
    }

    /*****************************************************************************************************************************
    *
    * Start
    *
    ****************************************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<Case> scope) {
        List<String> errorList = new List<String>();
        try{
            errorList = CloseOpenCasesRequestService.handleCasesWithInactiveOwner(scope);
        }catch(Exception e){
            CDdErrorUtilities.publishException('ProcessInactiveCaseBatch', 'execute', e);
        }
        if(errorList != null && errorList.size() > 0){
            CDdErrorUtilities.createApexLogs(errorList,'ProcessInactiveCaseBatch');
        }
    }

    /*****************************************************************************************************************************
    *
    * Finish
    *
    ****************************************************************************************************************************/
    public void finish(Database.BatchableContext BC) {

    }

    /*****************************************************************************************************************************
     *
     * Scheduler Execute
     *
     ****************************************************************************************************************************/
    public void execute(SchedulableContext sc) {
        Integer batchSize = CDdCustomMetadata.getBatchSize('ProcessInactiveCaseBatch');
        if(batchSize != null && batchSize > 0){
            Database.executeBatch(new ProcessInactiveCaseBatch(), batchSize);
        }
    }
}