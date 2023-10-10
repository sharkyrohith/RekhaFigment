/**
* @author: Cory Bartholomew (ATG)
* @date: 2021-04
* @description:  Batch class to clone Opportunities and Quotes for stores under a parent account
*/
public class CDdCloneOppAndQuoteBatch implements Database.Batchable<Account>{
    private static final String SUCCESSFULLY_CLONED_OPPORTUNITY = 'Successfully cloned Opportunity of Id ';
    private static final String SUCCESSFULLY_CLONED_QUOTE = 'Successfully cloned Quote of Id ';
    private static final String FAILED_TO_CLONE_OPPORTUNITY = 'Failed to clone Opportunity of Account Id ';
    private static final String CLASS_NAME = 'CDdCloneOppAndQuoteBatch';
    private static final String METHOD_NAME_EXECUTE = 'execute';

    @testVisible private CDdCloneOppAndQuote.BatchContext context;

    private CDdCloneOppAndQuote.CloneResult cloneResult;
    private List<Id> successRecordIds;
    private List<String> oppErrors = new List<String>();
    private List<String> currencyMismatchErrors = new List<String>();
    private List<String> quoteErrors = new List<String>();
    private List<String> quoteLineErrors = new List<String>();
    private List<String> oppLineErrors = new List<String>();
    private List<String> orderQuoteErrors = new List<String>();

    public CDdCloneOppAndQuoteBatch(
        CDdCloneOppAndQuote.BatchContext context
    ) {
        this.context = context;
        this.cloneResult = new CDdCloneOppAndQuote.CloneResult();
        this.successRecordIds = new List<Id>();
    }       
    
    //return the cloned opps to insert them and 
    public Iterable<Account> start(Database.BatchableContext context) {
        return this.context.accounts;
    }

    public void execute(Database.BatchableContext systemContext, List<Account> accounts) {
        List<Opportunity> opps = new List<Opportunity>();
        List<Opportunity> allOpps = new List<Opportunity>();
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();   
        
        //Bypass trigger order creation because this process will generate one if required
        Batch_and_Trigger_Setting__mdt orderSetting = [
                        SELECT Id, Label, DeveloperName, Batch_Size__c, Custom_Number__c, Disabled__c, Recursion__c
                        FROM Batch_and_Trigger_Setting__mdt
                        WHERE DeveloperName = 'CDdQuoteTrigger_generateOrders' LIMIT 1
                    ];

        if(!orderSetting.Disabled__c){
            orderSetting.Disabled__c = true;
        }
        
        //BZAP-12718 Reset Clone Result Status before each iteration
        this.cloneResult.status = CDdCloneOppAndQuote.STATUS_OK;
        
        //Clone Opportunity 
        allOpps.addAll(CDdCloneOppAndQuote.cloneOpportunity(this.context.sourceOpp, accounts));
        this.context.oppsToClone.addAll(allOpps); // for reporting later

        //BZAP-16395 : Do not clone opportunities if there is a currency mismatch on Source Opp and Target Account or SourceOpp and cloned Opportunity Billing Country
        if(!allOpps.isEmpty())
        {
        	for(Opportunity opp :allOpps)
        	{   
                if(opp.CurrencyIsoCode !=opp.account.CurrencyIsoCode || this.context.sourceOpp.Account_Billing_Country__c != opp.account.BillingCountry){
                    this.context.oppAccCurrencyMismatch.add(opp);
                    //Reset currencyMismatchErrors list from previous batch executions
                    currencyMismatchErrors.clear();
                    currencyMismatchErrors.add('Opportunity was not cloned for account '+ opp.accountid + ' due to currency or billing country mismatch');
                }    
            	else {
                    opps.add(opp);
                }
        	}
        }

        if(!currencyMismatchErrors.isEmpty()){
            addErrorsToList(this.cloneResult, currencyMismatchErrors , 'Error Inserting Opportunities. No data was created.');
        }

        List<Database.SaveResult> oppResults = Database.insert(opps, false);
        oppErrors = CDdErrorUtilities.processSaveResults(oppResults);
        if(!oppErrors.isEmpty()){
            addErrorsToList(this.cloneResult, oppErrors, 'Error Inserting Opportunities. No data was created.');
            this.context.failedOpps.addAll(opps);
        } else {
            this.context.clonedOpps.addAll(opps);
        }            
        
        //If Opportunity was successful, clone quotes
        if(this.cloneResult.status != CDdCloneOppAndQuote.STATUS_ERROR){
            quotes = CDdCloneOppAndQuote.cloneQuote(this.context.sourceQuote, opps);
           
            List<Database.SaveResult> quoteResults = Database.insert(quotes, false);            
            quoteErrors = CDdErrorUtilities.processSaveResults(quoteResults);
            if(!quoteErrors.isEmpty()){
                addErrorsToList(this.cloneResult, quoteErrors, 'Error Inserting Quotes.');
            } else {
                this.context.clonedQuotes.addAll(quotes);
            }  
           
            
            //If quote was sucessful clone quote lines
            List<SBQQ__QuoteLine__c> clonedQuoteLines = new List<SBQQ__QuoteLine__c>();
            Map<Id,Id> qlCloneReferenceMap = new Map<Id,Id>();
            if(this.cloneResult.status != CDdCloneOppAndQuote.STATUS_ERROR){
                clonedQuoteLines = CDdCloneOppAndQuote.processQuoteLineClone(this.context.sourceQuoteLines, quotes, this.cloneResult);
                qlCloneReferenceMap = CDdCloneOppAndQuote.getCloneReferenceIds(clonedQuoteLines);
                this.context.clonedQuoteLines.addAll(clonedQuoteLines);
            }

             //If quote lines were sucessful clone opp Products
             if(this.cloneResult.status != CDdCloneOppAndQuote.STATUS_ERROR){
                this.context.clonedOppLineItems = CDdCloneOppAndQuote.processOppLineClone(this.context.sourceOppLineItems, opps, qlCloneReferenceMap, this.cloneResult);
             }

             
             //FIX-081321 Update BypassValidationForPB__c to false
             if(this.cloneResult.status != CDdCloneOppAndQuote.STATUS_ERROR) {
                List<Opportunity> oppsToUpd1 = new List<Opportunity> ();
                for (Opportunity opp : opps) {
                    oppsToUpd1.add(new Opportunity (Id = opp.Id, BypassValidationForPB__c = false));
                }

                if (!opps.isEmpty()) {
                    List<Database.SaveResult> oppUpdResults = Database.update(oppsToUpd1, false);
                    oppErrors = CDdErrorUtilities.processSaveResults(oppUpdResults);
                    if(!oppErrors.isEmpty()){
                        addErrorsToList(this.cloneResult, oppErrors, 'Error Updating Opportunities.');
                        CDdErrorUtilities.createApexLogs(oppErrors,'CDdCloneOppAndQuoteBatch', 'execute > Opportunity 1st Update',LoggingLevel.INFO);
                    }
                }
             }
             
             //Generate and order from the cloned quotes if the original was ordered
            if(this.cloneResult.status != CDdCloneOppAndQuote.STATUS_ERROR){
                if(this.context.sourceQuote.SBQQ__Ordered__c == true){
                    for(SBQQ__Quote__c quote : quotes){
                        quote.SBQQ__Ordered__c = true;
                    }
                    List<Database.SaveResult> orderQuoteResults = Database.update(quotes, false);
                    orderQuoteErrors = CDdErrorUtilities.processSaveResults(orderQuoteResults);
                    if(!orderQuoteErrors.isEmpty()){
                        addErrorsToList(this.cloneResult, orderQuoteErrors, 'Error ordering quotes. Please manually order failed quotes');
                        CDdErrorUtilities.createApexLogs(oppErrors, 'CDdCloneOppAndQuoteBatch', 'execute > Order Quotes',LoggingLevel.INFO);
                    }
                }
            }

            //BZAP-12147 Set Stage to Closed Won.
            if (this.context.stageName == CDdCpqBillingConstants.OPP_STAGENAME_CLOSED_WON) {
                if (this.cloneResult.status != CDdCloneOppAndQuote.STATUS_ERROR) {
                    List<Opportunity> oppsToUpd1 = new List<Opportunity> ();
                    for (Opportunity opp : opps) {
                        oppsToUpd1.add(new Opportunity (Id = opp.Id, StageName = CDdCpqBillingConstants.OPP_STAGENAME_CLOSED_WON));
                    }

                    if (!opps.isEmpty()) {
                        List<Database.SaveResult> oppUpdResults = Database.update(oppsToUpd1, false);
                        oppErrors = CDdErrorUtilities.processSaveResults(oppUpdResults);
                        if(!oppErrors.isEmpty()){
                            addErrorsToList(this.cloneResult, oppErrors, 'Errors setting Opportunities to stage Closed Won.');
                            CDdErrorUtilities.createApexLogs(oppErrors,'CDdCloneOppAndQuoteBatch', 'execute > Setting to Closed Won',LoggingLevel.INFO);
                        }
                    }
                }           
            }
        }

        writeContext(this.context, systemContext.getJobId());
    }

    public void finish(Database.BatchableContext context) {
        CDdCloneOppAndQuote.BatchContext finalContext = getContext(context.getJobId());

        finalContext.emailBody = String.format(
            '<p> {0} of {1} Opportunities were cloned with {2} error(s).</p>',
            new List<Integer> {
                finalContext.clonedOpps.size(), // successes
                finalContext.clonedOpps.size() + finalContext.failedOpps.size(), // total opportunities
                this.cloneResult.messages.size() // updated locally in getContext() method
            }
        );
        
        for(String message : this.cloneResult.messages){
            System.debug(message);
        }           
        String errors = CDdCloneOppAndQuote.buildErrorString(this.cloneResult.messages, 'Opportunity and Quote');
        finalContext.emailBody += errors;
        
        finalContext.emailBody += '<h3>Opportunities Created (' + finalContext.clonedOpps.size() + ')</h3>';
        
        finalContext.emailBody += buildHTMLForSuccessesTable(finalContext);

        if(!finalContext.failedOpps.isEmpty() || !finalContext.oppAccCurrencyMismatch.isEmpty()){
            finalContext.emailBody += buildHTMLForFailuresTable(finalContext);
        }

        finalContext.emailBody += '<h3>Quote Ids (' + finalContext.clonedQuotes.size() + ')</h3>';
        finalContext.emailBody += '<p></p><table style="width:30ch" border="1"><tr><th style="text-align:left">Id</th></tr>';
        for(SBQQ__Quote__c quote : finalContext.clonedQuotes){
            finalContext.emailBody += '<tr><td>' + quote.Id + '</td></tr>';
        }                
        finalContext.emailBody += '</table>';

        //BZAP-17747 report timing and heap size
        finalContext.emailBody += '<p>Time since clone process kicked off: ' +
            (DateTime.now().millisecond() - this.context.startTime) +
            ' milliseconds.</p>';
        finalContext.emailBody += '<p>Heap size used: ' + limits.getHeapSize() +
            ' out of ' + limits.getLimitHeapSize() +
            ' (this may only represent the last batch)</p>';

        CDdCloneOppAndQuote.sendEmail(this.context.sourceOpp, finalContext.emailBody);
    }

    public static void addErrorsToList(CDdCloneOppAndQuote.CloneResult cloneResult, List<String> errorMessages, String errorDescription){
        cloneResult.status = CDdCloneOppAndQuote.STATUS_ERROR;
        cloneResult.messages.add(errorDescription);
        cloneResult.messages.addAll(errorMessages);
    }

    @testVisible
    private String buildHTMLForSuccessesTable(CDdCloneOppAndQuote.BatchContext jobContext){
        // Need to read the Opps from the DB to get the Store ID
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : jobContext.clonedOpps){
            oppIds.add(opp.Id);
        }
        List<Opportunity> oppsFromDb =  [
            SELECT Id, Store_ID__c, AccountId
            FROM Opportunity
            WHERE Id IN :oppIds
        ];

        String successTable = '';

        successTable += '<p></p><table style="width:60ch" border="1"><tr><th style="text-align:left">Id</th><th style="text-align:center">Store Id</th><th style="text-align:right">Account Id</th></tr>';
        for(Opportunity opp : oppsFromDb){
            successTable += '<tr><td>' + opp.Id + '</td><td style="text-align:center">' + opp.Store_ID__c + '</td><td style="text-align:right">' + opp.AccountId + '</td></tr>';
        }
        successTable += '</table>';

        return successTable;
    }

    @testVisible
    private String buildHTMLForFailuresTable(CDdCloneOppAndQuote.BatchContext jobContext){
        String failureTable = '';
        // query accounts
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity failedOpportunity : jobContext.failedOpps){
            if(failedOpportunity.AccountId != null){
                accountIds.add(failedOpportunity.AccountId);
            }
        }

        Map<Id,Account> parentAccountsById = new Map<Id,Account>();
        if(!accountIds.isEmpty()){
            parentAccountsById = new Map<Id,Account>(
                [SELECT Restaurant_ID__c,CurrencyIsoCode,BillingCountry FROM Account WHERE Id IN :accountIds]
            );
        }

        failureTable += '<h3>Failed Opportunities (' + jobContext.failedOpps.size() + ')</h3>';
        failureTable += '<p></p><table style="width:60ch" border="1"><tr><th style="text-align:left">Store Id</th><th style="text-align:left">Account Currency</th><th style="text-align:left">Account Billing Country</th><th style="text-align:center">Account Id</th></tr>';
        if(!parentAccountsById.isEmpty() && !jobContext.failedOpps.isEmpty()){
        	for(Opportunity opp : jobContext.failedOpps){
                Account parentAccount;
                
                if(opp.AccountId != null && parentAccountsById.get(opp.AccountId) != null){
                    parentAccount = parentAccountsById.get(opp.AccountId);
                } else {
                    parentAccount = new Account(
                        Restaurant_ID__c = null,
                        CurrencyIsoCode = null
                    );
                }

            	failureTable += '<tr><td style="text-align:left">' + parentAccount.Restaurant_ID__c + '</td><td style="text-align:left">' + parentAccount.CurrencyIsoCode + '</td><td style="text-align:left">' + parentAccount.BillingCountry + '</td><td style="text-align:center">' + opp.AccountId + '</td></tr>';
        	}
        }
        failureTable += '</table>';

        return failureTable;
    }

    /**
     * @description BZAP-17747. Retrieves Apex_Log__c records created during execution of batches to reconstruct
     *  a CDdCloneOppAndQuote.BatchContext object representing the full execution of the batch job
     *  for email reporting. Previously (before BZAP-17747) this job used Database.Stateful to
     *  maintain those records but that proved to be too CPU-intensive and eventually led to
     *  heap-size overflows.
     *
     * @param jobId (Id); the unique context Id of this job as retreived from Database.BatchableContext.
     * @return CDdCloneOppAndQuote.BatchContext
     *
     * @see CDdCloneOppAndQuoteBatch.writeContext(); the method that writes the Apex_Log__c records.
     * @see https://help.salesforce.com/s/articleView?id=000383707&type=1
     */
    private CDdCloneOppAndQuote.BatchContext getContext(Id jobId){
        CDdCloneOppAndQuote.BatchContext retrievedContext = new CDdCloneOppAndQuote.BatchContext();

        List<Apex_Log__c> jobLogs = [
            SELECT Log__c,Record_ID__c,Reference_Id__c
            FROM Apex_Log__c WHERE Reference_Id__c = :jobId
        ];

        for(Apex_Log__c currentLog : jobLogs){
            if(currentLog.Log__c.startsWith(SUCCESSFULLY_CLONED_OPPORTUNITY)){
                retrievedContext.clonedOpps.add(
                    new Opportunity(Id=currentLog.Record_ID__c)
                );
            } else if(currentLog.Log__c.startsWith(SUCCESSFULLY_CLONED_QUOTE)){
                retrievedContext.clonedQuotes.add(
                    new SBQQ__Quote__c(Id=currentLog.Record_ID__c)
                );
            } else if(currentLog.Log__c.startsWith(FAILED_TO_CLONE_OPPORTUNITY)){
                retrievedContext.failedOpps.add(
                    new Opportunity(AccountId=currentLog.Record_ID__c)
                );
            } else { // assume it's an error message
                this.cloneResult.messages.add(currentLog.Log__c);
            }
        }

        return retrievedContext;
    }

    /**
     * @description BZAP-17747. Writes the results of this batch to Apex_Log__c so the finish method
     *  (and more specifically CDdCloneOppAndQuoteBatch.getContext()) can retrieve them later for reporting.
     *
     * @param contextToWrite (CDdCloneOppAndQuote.BatchContext); the results of the current batch run to be serialized.
     * @param jobId (Id); the unique context Id of this job as retreived from Database.BatchableContext.
     * @return List<Apex_Log__c>
     *
     * @see CDdCloneOppAndQuoteBatch.getContext()
     * @see https://help.salesforce.com/s/articleView?id=000383707&type=1
     */
    private List<Apex_Log__c> writeContext(CDdCloneOppAndQuote.BatchContext contextToWrite, Id jobId){
        List<Apex_Log__c> contextLogs = new List<Apex_Log__c>();

        //messages
        for(String currentMessage : this.cloneResult.messages){
            contextLogs.add(
                CDdErrorUtilities.createApexLog(
                    currentMessage,
                    CLASS_NAME,
                    METHOD_NAME_EXECUTE,
                    null,
                    jobId,
                    LoggingLevel.INFO
                )
            );
        }

        //clonedOpps
        for(Opportunity clonedOpportunity : contextToWrite.clonedOpps){
            contextLogs.add(
                CDdErrorUtilities.createApexLog(
                    SUCCESSFULLY_CLONED_OPPORTUNITY + clonedOpportunity.Id,
                    CLASS_NAME,
                    METHOD_NAME_EXECUTE,
                    clonedOpportunity.Id,
                    jobId,
                    LoggingLevel.INFO
                )
            );
        }

        //failedOpps, oppAccCurrencyMismatch (opportunity errors)
        List<Opportunity> failedOpportunities = new List<Opportunity>();
        failedOpportunities.addAll(contextToWrite.failedOpps);
        failedOpportunities.addAll(contextToWrite.oppAccCurrencyMismatch);
        for(Opportunity failedOpportunity : failedOpportunities){
            contextLogs.add(
                CDdErrorUtilities.createApexLog(
                    FAILED_TO_CLONE_OPPORTUNITY + failedOpportunity.AccountId,
                    CLASS_NAME,
                    METHOD_NAME_EXECUTE,
                    failedOpportunity.AccountId,
                    jobId,
                    LoggingLevel.INFO
                )
            );
        }

        //clonedQuotes
        for(SBQQ__Quote__c clonedQuote : contextToWrite.clonedQuotes){
            contextLogs.add(
                CDdErrorUtilities.createApexLog(
                    SUCCESSFULLY_CLONED_QUOTE + clonedQuote.Id,
                    CLASS_NAME,
                    METHOD_NAME_EXECUTE,
                    clonedQuote.Id,
                    jobId,
                    LoggingLevel.INFO
                )
            );
        }

        if(!contextLogs.isEmpty()){
            insert contextLogs;
        }

        return contextLogs;
    }
}