/************************************************************************************************************************************
* @author Jitendra
* @date 27-04-23
*
* @group SBQQ_Quote Status Update
*
* @description BZAP-20031-The purpose of this Apex batch class is to query the 'Quote' records and update the status.
*
**************************************************************************************************************************************/
public class CDdQuoteStatusUpdateBatch implements Database.Batchable<sObject> {
    final string STATUS_CONTRACT_SIGNED = 'Contract Signed';
    final string QUERY_BATCH = System.Label.Query_for_Batch_CDdQuoteStatusUpdateBatch;
    List<Id> quoteIdsToUpdate = new List<Id>();
    List<String> errorMessages;

    public CDdQuoteStatusUpdateBatch(List<Id> quoteIds)
    {
        this.quoteIdsToUpdate = quoteIds;
    }
    /**
    * @description Start the batch operation and prepare the Query to get the quote records those are in Approved Status.
    */
    public Database.QueryLocator start(Database.BatchableContext batchcontext) {
        String strQuery = QUERY_BATCH +' WHERE Id=:quoteIdsToUpdate';
        return Database.getQueryLocator(strQuery);
    }

    /**
    * @description Execute the batch operation to process the scoped Quote records
    */
    public void execute(Database.BatchableContext batchcontext, List<SBQQ__Quote__c> scope) {
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        errorMessages = new List<String>();
        for (SBQQ__Quote__c quote : scope) {
            quote.SBQQ__Status__c = STATUS_CONTRACT_SIGNED;
            quoteList.add(quote);
        }
        if(quoteList.size() > 0)
        {
            try{
                Database.SaveResult[] updateResults = Database.update(quoteList, false);
                errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
            }
            catch(Exception ex) {
                errorMessages.add(ex.getStackTraceString());
            }
            finally {
                if(errorMessages != NULL && errorMessages.size() > 0){
                    CDdErrorUtilities.createApexLogs(errorMessages, 'CDdQuoteStatusUpdateBatch', 'Execute', LoggingLevel.ERROR);
                }
            }
        }
    }
    /**
    * @description Finish the batch operation
    */
    public void finish(Database.BatchableContext batchcontext) {

    }
}