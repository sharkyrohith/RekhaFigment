/************************************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 5/16/2019
*
* @group Coverage Check
*
* @description The purpose of this Apex batch class is to query the 'Lead' records for coverage check
*
**************************************************************************************************************************************/
public class CDdLeadCoverageCheckBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private String query;
    private List<Id> recordIds;
    public Boolean callFromSched = false;
    private static String QUERY_BASE = 'SELECT Id, Address, In_Coverage__c ' +
                      'FROM Lead ' +
                      'WHERE IsConverted = false ' +
                      'AND Street != null ' +
                      'AND PostalCode != null ';
    public static String QUERY_FILTER_IN_COVERAGE_NULL_OR_UNKNOWN = ' AND (In_Coverage__c = null OR In_Coverage__c = \'Unknown\')';
    public static String QUERY_FILTER_IN_COVERAGE_YES_OR_NO = ' AND (In_Coverage__c = \'Yes\' OR In_Coverage__c = \'No\')';
    public static String QUERY_FILTER_IN_COVERAGE_NO = ' AND (In_Coverage__c = \'No\' AND Converted__c = false AND Primary_Campaign_Source__r.Name Like \'%AcqMktg%\' AND LeadSource = \'Merchant Inbound\')';
    public static String QUERY_FILTER_RECORD_IDS = ' AND (Id IN :recordIds)';
    public static String QUERY_FILTER_DAYS = 'AND LastModifiedDate <= LAST_N_DAYS:' + CDdCoverageCheckConstants.LAST_MODIFIED_DAYS;
   /**
    * @description 2 argument constructor
    * @param queryFilter valid values are string constants QUERY_FILTER_IN_COVERAGE_NULL_OR_UNKNOWN, QUERY_FILTER_IN_COVERAGE_NO
    * @param SOQL limit value - if zero, the limit will not be applied to the query
    */
    public CDdLeadCoverageCheckBatch(String queryFilter, Integer limitNum, Boolean callFromSched) {
        this.callFromSched = callFromSched;
        this.query = QUERY_BASE + queryFilter + ((callFromSched != True) ? QUERY_FILTER_DAYS : '') + ((limitNum!=null && limitNum!=0) ? ' LIMIT ' + String.valueOf(limitNum) : '');
    }
   /**
    * @description Constructor with input record identifiers
    * @param recordIds - a Collection of input record identifiers
    */
    public CDdLeadCoverageCheckBatch(List<Id> recordIds) {
        this.recordIds = recordIds;
        this.query = QUERY_BASE + QUERY_FILTER_DAYS + QUERY_FILTER_RECORD_IDS;
    }
    /**
    * @description Start the batch operation and prepare the Query to locate the Lead records for coverage check
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    /**
    * @description Execute the batch operation to check for coverage on the scoped Lead records
    */
    public void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Id> leadIds = new List<Id>();
        List<Id> emailLeads = new List<Id>();
        Map<String, Object> Params = new Map<String, Object>();

        for (Lead lead : scope) {
            leadIds.add(lead.Id);
        }

        if(callFromSched) {
            emailLeads = CDdCoverageCheckSvcV2.checkLeadCoverage(leadIds, callFromSched);
        } else {
            CDdCoverageCheckSvcV2.checkLeadCoverage(leadIds);
        }

        //BASD-16422 - Send email to leads which are back in coverage
        if(!emailLeads.isEmpty()){
            Params.put('leadIdList',emailLeads);
            Flow.Interview.Notify_Lead_in_Coverage_Now flow = new Flow.Interview.Notify_Lead_in_Coverage_Now(Params);
            flow.start();
        }
    }
    /**
    * @description Finish the batch operation
    */
    public void finish(Database.BatchableContext BC) {

    }
}