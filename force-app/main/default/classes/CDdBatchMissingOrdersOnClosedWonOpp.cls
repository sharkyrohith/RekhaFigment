/**
 *
 * @author  Ayushi Agarwal
 * @date    May 10th, 2023
 * @decription BZAP-19868- A daily Batch which identifies all latest closed won opportunities with missing orders and
 * process them to create orders and send email notifications with results.
 */
global class CDdBatchMissingOrdersOnClosedWonOpp implements Database.Batchable<sObject>, Database.Stateful {

    String query;
    Integer totalOpp=0;
    Datetime dateRange;
    Integer lastNDays;
    Id oppPostSaleRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Post_Sale');
    Id oppMarketplaceRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('ML_Inside_Sales');
    Id oppMerchantPromotionRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Merchant_Promotion');
    final String orderCreated = 'Success';
    final String orderNotCreated = 'Order has not been created';
    List<String> errorMessages;
    Map<Id, String> resultMap= new Map<Id, String>();
    Map<Id, Id> quoteOppMap =new Map<Id, Id>();

    public CDdBatchMissingOrdersOnClosedWonOpp(Integer lastNDays){
        this.lastNDays = lastNDays;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        dateRange = System.today().addDays(lastNDays);

        query = 'SELECT Id, Name, Migrated_Record__c, SBQQ__Primary__c, SBQQ__Ordered__c,  SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.LastModifiedDate, '
            	+ '(SELECT Id FROM SBQQ__LineItems__r WHERE SBQQ__NetPrice__c = NULL) '
            	+ 'FROM SBQQ__Quote__c '
                + 'WHERE SBQQ__Primary__c = TRUE '
                + 'AND SBQQ__Opportunity2__r.StageName =\'closed won\' '
                + 'AND (SBQQ__Opportunity2__r.RecordTypeId = :oppMarketplaceRTId '
                + 'OR SBQQ__Opportunity2__r.RecordTypeId = :oppPostSaleRTId '
                + 'OR SBQQ__Opportunity2__r.RecordTypeId = :oppMerchantPromotionRTId '
                + 'OR Migrated_Record__c = TRUE) '
                + 'AND SBQQ__Opportunity2__r.LastModifiedDate >= :dateRange '
            	+ 'AND SBQQ__Opportunity2__c NOT IN (SELECT OpportunityId FROM Order) ';


        return Database.getQueryLocator(query);
    }


    global void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> scope) {
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quotesWithoutUnitPrice = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quotesOrderedFalse = new List<SBQQ__Quote__c>();
        errorMessages = new List<String>();

        if(scope.size() > 0 && scope != null ){
            for(SBQQ__Quote__c quote: scope){

                //Store Quote and associated Opp id, used for reporting purpose
                quoteOppMap.put(quote.id, quote.SBQQ__Opportunity2__c );

                //Do not process quotes for which one or more line items do not have net unit price
                if( quote.SBQQ__LineItems__r.size() > 0){
                    quotesWithoutUnitPrice.add(quote);
                    resultMap.put(quote.SBQQ__Opportunity2__c, 'Error: Order Products must have a Unit Price.: Unit Price');

                //For the quotes for which Ordered checkbox is true toggle it to false and then again to true to create orders
                } else if(quote.SBQQ__Ordered__c == True){
                    quote.SBQQ__Ordered__c = False;
                    quotesOrderedFalse.add(quote);

                }
                else{
                    quote.SBQQ__Ordered__c = True;
                    quotesToUpdate.add(quote);
                }
            }

        }

        totalOpp = totalOpp + scope.size();

        try{

            if(quotesOrderedFalse != null && quotesOrderedFalse.size() > 0 ){
                List<Database.SaveResult> saveResult = Database.update(quotesOrderedFalse, false);
                errorMessages = CDdErrorUtilities.processSaveResults(saveResult, errorMessages);
                for(Database.SaveResult result : saveResult){
                    for(SBQQ__Quote__c quoteOrdered : quotesOrderedFalse){
                        if(result.isSuccess() && result.getId() == quoteOrdered.id ){
                            quoteOrdered.SBQQ__Ordered__c=True;
                            quotesToUpdate.add(quoteOrdered);
                        }
                        else{
                            for(Database.Error err: result.getErrors()){
                                resultMap.put(quoteOppMap.get(result.getId()), 'Error: '+ err.getMessage() );

                            }
                        }
                    }
                }
            }
            if(quotesToUpdate != null && quotesToUpdate.size() > 0){
                List<Database.SaveResult> sResults = Database.update(quotesToUpdate, false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);

                //Save success and failed records in a map for reporting later
                for(Database.SaveResult sr : sResults){
                    if(sr.isSuccess()){
                        resultMap.put(quoteOppMap.get(sr.getId()), orderCreated);
                    }
                    else{
                        for( Database.Error err: sr.getErrors() ){
                            resultMap.put(quoteOppMap.get(sr.getId()), 'Error: '+ err.getMessage() );
                        }
                    }
                }
            }
        }catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw e;

        }finally {

            if(errorMessages != NULL && errorMessages.size()>0){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchMissingOrdersOnClosedWonOpp', 'Execute', LoggingLevel.ERROR);
            }
        }
    }


    global void finish(Database.BatchableContext BC) {

        Set<ID> opportunityIds = resultMap.keySet();
        Map<ID,ID> oppOrderMap = new Map<ID,ID>();
        Map<ID,SBQQ__Quote__c> oppQuoteMap = new Map<ID,SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quoteToBeUpdated = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quoteList = [Select Id,Name,SBQQ__Primary__c, SBQQ__ordered__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where SBQQ__Opportunity2__c in:opportunityIds AND SBQQ__Primary__c = true];
        List<Order> orderList = [Select Id, Name, OpportunityId  from Order where OpportunityId in :opportunityIds];

        if(orderList != null && orderList.size()>0){
            for(Order order : orderList) {
                oppOrderMap.put(order.OpportunityId, order.Id);
            }
        }

        if(quoteList != null && quoteList.size()>0){
            for(SBQQ__Quote__c quote : quoteList) {
                oppQuoteMap.put(quote.SBQQ__Opportunity2__c, quote);
            }
        }

        if(resultMap.size() > 0){
            for(ID oppId : opportunityIds){
                if(resultMap.get(oppId) == orderCreated && oppOrderMap.get(oppId) == null){
                    resultMap.put(oppId,orderNotCreated);
                    oppQuoteMap.get(oppId).SBQQ__ordered__c = false;
                    quoteToBeUpdated.add(oppQuoteMap.get(oppId));
                }
            }
        }
        Database.update(quoteToBeUpdated, false);

        List<C_W_Opp_Missing_Orders_Recipient_Group__mdt> recipientUsers = C_W_Opp_Missing_Orders_Recipient_Group__mdt.getAll().values();
        String mailSubject = Label.CDdBatchMissingOrdersOnClosedWonOpp_Email_Subject;
        List<String> toAddress = new List<String>();

        if(recipientUsers !=null && recipientUsers.size() > 0){
            for(C_W_Opp_Missing_Orders_Recipient_Group__mdt user : recipientUsers ){
            toAddress.add(user.Recipient_Email_Address__c);
            }
        }

        AsyncApexJob job =[SELECT Id, Status, CompletedDate, NumberOfErrors FROM AsyncApexJob WHERE Id = :BC.getJobId() ];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject(mailSubject + ' ' + job.CompletedDate.date().format());
        mail.setToAddresses(toAddress);
        mail.setHtmlBody(getTableEmailBody(resultMap, job, totalOpp, orderList.size()));
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

    }


    public static string getTableEmailBody(Map<id, string>resultMap, AsyncApexJob a, Integer totalOpp, Integer successOpp){

        String htmlBody = '';

        //open table
         htmlBody = 'The batch Apex job completed on : ' + a.CompletedDate + '<br>' +
             		'Job Status : ' + a.Status + '<br>'+
             		'Total Opportunities : ' + totalOpp + '<br>'+
             		'Number of Opportunity processed successfully : ' + successOpp + '<br>' +
        			'<table border="1" style="border-collapse: collapse"><caption>Summary Data</caption><tr><th>Opportunity Id</th><th>Status</th></tr>';

        //iterate over map and output columns/data into table rows
        for(id oppID :resultMap.keySet()){
            htmlBody += '<tr><td>' + oppID + '</td><td>' + resultMap.get(oppID) + '</td></tr>';
        }
        //close table
        htmlBody += '</table>';
        return htmlBody;
    }
}