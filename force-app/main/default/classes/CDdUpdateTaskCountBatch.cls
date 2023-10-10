/************************************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/05/2019
*
* @group Update Task Count
*
* @description The purpose of this Apex batch class is to update the task count on the SObject record (Example: Lead, Account etc.)
* 
**************************************************************************************************************************************/
public class CDdUpdateTaskCountBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private String sObjectType;
    private String query;
    public static final String SOBJECT_TYPE_LEAD = 'Lead';
    public static final String SOBJECT_TYPE_ACCOUNT = 'Account';    
    private static String QUERY_ACCOUNT = 'SELECT Id FROM Account ';
    private static String QUERY_LEAD = 'SELECT Id FROM Lead WHERE IsConverted = false ';
   /** 
    * @description 2 argument constructor
    * @param sObjectType What is the SObjectType - currently support Lead, Acount
    */
    public CDdUpdateTaskCountBatch(String sObjectType) {
        this.sObjectType = sObjectType;
        if (SOBJECT_TYPE_LEAD.equals(this.sObjectType)){
            this.query = QUERY_LEAD;
        }
        if (SOBJECT_TYPE_ACCOUNT.equals(this.sObjectType)){
            this.query = QUERY_ACCOUNT;
        }        
    }
    /** 
    * @description Start the batch operation and prepare the Query to locate the Account records for coverage check
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }
    /** 
    * @description Execute the batch operation to check for coverage on the scoped Account records
    */    
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        Set<Id> recordIds = new Set<Id>();
        for (SObject sObj : scope) {
            recordIds.add((Id)sObj.get('Id'));
        }
        if (SOBJECT_TYPE_LEAD.equals(this.sObjectType)){
            CDdTaskHelperMethods.applyTaskCountForLeads(recordIds);
        }
        if (SOBJECT_TYPE_ACCOUNT.equals(this.sObjectType)){
            CDdTaskHelperMethods.applyTaskCountForAccounts(recordIds);
        }
    }
    /** 
    * @description Finish the batch operation
    */  
    public void finish(Database.BatchableContext BC) {
    }
}