/************************************************************************************************************************************
* @author Jitendra
* @date 27-04-23
*
* @group SBQQ_Quote Status Check
*
* @description BZAP-20031-The purpose of this Apex batch class is to query the 'Quote' records and check the status.
*
**************************************************************************************************************************************/
public class CDdQuoteStatusCheckBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    final String QUOTE_CREATEDBY_USER = 'mulesoft integration user';
    final String QUERY_BATCH = System.Label.Query_for_Batch_CDdQuoteStatusCheckBatch;
    List<Id> quoteIds = new List<Id>();
    List<String> errorMessages;

    /**
     * @description Schedulable execute method
     */
    public static void execute(SchedulableContext schedulecontext) {
        Database.executeBatch(new CDdQuoteStatusCheckBatch(), 5);
    }

    /**
     * @description Start the batch operation and prepare the Query to get the quote records those are in Approved Status.
     */
    public Database.QueryLocator start(Database.BatchableContext batchcontext) {
        return Database.getQueryLocator(QUERY_BATCH);
    }
    /**
     * @description Execute the batch operation to process the scoped Quote records
     */
    public void execute(Database.BatchableContext batchcontext, List<SBQQ__Quote__c> scope) {

        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        errorMessages = new List<String>();
        for (SBQQ__Quote__c quote : scope) {
            if(quote.Owner.Name.ToLowerCase() == QUOTE_CREATEDBY_USER
                && quote.CreatedBy.Name.ToLowerCase() == QUOTE_CREATEDBY_USER)
            {
                quote.Integration_Trial__c = !quote.Integration_Trial__c;
                quoteIds.add(quote.Id);
                quoteList.add(quote);
            }
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
                    CDdErrorUtilities.createApexLogs(errorMessages, 'CDdQuoteStatusCheckBatch', 'Execute', LoggingLevel.ERROR);
                }
            }
        }
    }
    /**
    * @description Finish the batch operation
    */
    public void finish(Database.BatchableContext batchcontext) {

        if(quoteIds.size() > 0)
        {
            Database.executeBatch(new CDdQuoteStatusUpdateBatch(quoteIds),5);
        }
    }
}