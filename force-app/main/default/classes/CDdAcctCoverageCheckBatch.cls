/************************************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 5/16/2019
*
* @group Coverage Check
*
* @description The purpose of this Apex batch class is to query the 'Account' records for coverage check
*
**************************************************************************************************************************************/
public class CDdAcctCoverageCheckBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private String query;
    private List<Id> recordIds;
    private static String QUERY_BASE = 'SELECT Id, BillingAddress, In_Coverage__c ' +
                      'FROM Account ' +
                      'WHERE RecordType.DeveloperName IN (\'Prospect\', \'Enterprise_Marketplace\', \'DoorDash_Drive\', \'Enterprise_Drive\', \'Vendor\') ' +
                      'AND BillingStreet != null ' +
                      'AND BillingPostalCode != null ' +
                      'AND LastModifiedDate <= LAST_N_DAYS:' + CDdCoverageCheckConstants.LAST_MODIFIED_DAYS + ' ';
    public static String QUERY_FILTER_IN_COVERAGE_NULL_OR_UNKNOWN = ' AND (In_Coverage__c = null OR In_Coverage__c = \'Unknown\')';
    public static String QUERY_FILTER_IN_COVERAGE_YES_OR_NO = ' AND (In_Coverage__c = \'Yes\' OR In_Coverage__c = \'No\')';
    public static String QUERY_FILTER_IN_COVERAGE_NO = ' AND (In_Coverage__c = \'No\')';
    public static String QUERY_FILTER_RECORD_IDS = ' AND (Id IN :recordIds)';
   /**
    * @description 2 argument constructor
    * @param queryFilter valid values are string constants QUERY_FILTER_IN_COVERAGE_NULL_OR_UNKNOWN, QUERY_FILTER_IN_COVERAGE_NO
    * @param SOQL limit value - if zero, the limit will not be applied to the query
    */
    public CDdAcctCoverageCheckBatch(String queryFilter, Integer limitNum) {
        this.query = QUERY_BASE + queryFilter + ((limitNum!=null && limitNum!=0) ? 'LIMIT ' + String.valueOf(limitNum) : '');
    }
   /**
    * @description Constructor with input record identifiers
    * @param recordIds - a Collection of input record identifiers
    */
    public CDdAcctCoverageCheckBatch(List<Id> recordIds) {
        this.recordIds = recordIds;
        this.query = QUERY_BASE + QUERY_FILTER_RECORD_IDS;
    }
    /**
    * @description Start the batch operation and prepare the Query to locate the Account records for coverage check
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    /**
    * @description Execute the batch operation to check for coverage on the scoped Account records
    */
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Id> acctIds = new List<Id>();
        for (Account acct : scope) {
            acctIds.add(acct.Id);
        }
        CDdCoverageCheckSvcV2.checkAcctCoverage(acctIds);
    }
    /**
    * @description Finish the batch operation
    */
    public void finish(Database.BatchableContext BC) {

    }
}