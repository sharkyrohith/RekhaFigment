/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/26/2019
*
* @group Trigger Handler
*
* @description trigger handler for custom object Trigger__c
* 
**************************************************************************************************************************************/
public class CDdTriggerHistoryTriggerHandler {

    public static final Map<String, Schema.RecordTypeInfo> CASE_RECORD_TYPE_INFO_BY_DEV_NAME 
                                                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
    public static final String RECORD_TYPE_DEV_NAME_CASE_POST_SALE_TRIGGERS = 'Post_Sale_Triggers'; 
    public static final Set<String> CASE_STATUS_CLOSED = new Set<String>{'Closed'}; 

    public void beforeInsert(List<Trigger__c> newList) {
        populateCase(newList);
    }
    /**
    *   @description Populate the Case reference on the Trigger History records
    *
    *   ETL records are uploaded weekly into Salesforce. 
    *   Hence, the incoming records are grouped by trigger date at the highest level in the caseMap collection
    *   For a given trigger date, there may be one or more trigger history records associated with any Parent Acount
    *   So the second level of grouping is by Parent Account record identifier in the caseMap Collection
    *   And, finally for a given trigger date and a parent account, 
    *       there may be one or more trigger history records with unique names
    *       the unique names of the trigger history record translate to a Case reason 
    *
    *   Given the above, the Case match is based on Trigger date, Parent Account and Case Reason
    *
    *   Since the Case record(s) have a high volume within Salesforce, the Case record(s) are filtered to narrow down the processing size.
    *   Case filter is as follows:
    *       - Process Case records of record type 'Post Sales Triggers' 
    *       - Within that Collection, filter further by
    *           - Parent Account(s)
    *           - Case record(s) NOT Closed
    *           - Case Trigger Date should fall within the range of trigger dates uploaded by the ETL process
    *           - Case Reason should align with the names of the incoming trigger history records (refer to custom metadata) 
    *
    *   Note: Processing of Trigger History records is restricted to Trigger History record names as found in the 
    *   custom metadata Trigger_History_Reason_Mapping__mdt. If a specific Trigger History record name is not being 
    *   processed (for Case match), it is most likely that the trigger history record is not configured within custom metadata. 
    *   When a Trigger History name is configured, you are expected to map it to an existing Case reason. 
    *   This is critical to matching the Trigger History record to a specific Case record  
    **/
    public static void populateCase(List<Trigger__c> newList) {  
        List<Trigger__c> recordsToProcess = new List<Trigger__c>();
        Map<Date, Map<Id, Map<String, Case>>> caseMap = new   Map<Date, Map<Id, Map<String, Case>>>();

        Set<Id> caseAccountIds = new Set<Id>();
        Date triggerDateFrom = null;
        Date triggerDateTo = null;
        
        // Prepare from custom metadata
        Map<String, String> triggerHistoryNameReasonMap = getTriggerHistoryNameReasonMap();

        for (Trigger__c t : newList){
            if (String.isBlank(t.Case__c)){
                if (String.isNotBlank(t.Parent_Account__c) && triggerHistoryNameReasonMap.containsKey(t.Name) && t.Trigger_Date__c != null){
                    caseAccountIds.add(t.Parent_Account__c);
                    triggerDateFrom = ((triggerDateFrom == null) ? t.Trigger_Date__c : (t.Trigger_Date__c < triggerDateFrom ? t.Trigger_Date__c : triggerDateFrom));
                    triggerDateTo = ((triggerDateTo == null) ? t.Trigger_Date__c : (t.Trigger_Date__c > triggerDateTo ? t.Trigger_Date__c : triggerDateTo));
                    recordsToProcess.add(t);                    
                }
            }
        }

        Id postSaleTriggersRecordTypeId = CASE_RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_CASE_POST_SALE_TRIGGERS).getRecordTypeId();
        for (Case c : [ SELECT Id, AccountId, OwnerId, Reason, Trigger_Date__c 
                        FROM Case
                        WHERE RecordTypeId = :postSaleTriggersRecordTypeId
                        AND AccountId IN :caseAccountIds
                        AND Status NOT IN :CASE_STATUS_CLOSED
                        AND Trigger_Date__c >= :triggerDateFrom
                        AND Trigger_Date__c <= :triggerDateTo
                        AND Reason IN :triggerHistoryNameReasonMap.values()
                    ]){
            Map<String, Case> caseReasonMap = new Map<String, Case>{c.Reason => c};
            Map<Id, Map<String, Case>> caseAccountIdMap = new Map<Id, Map<String, Case>>{c.AccountId => caseReasonMap};

            if (caseMap.containsKey(c.Trigger_Date__c)){
                Map<Id, Map<String, Case>> existingCaseAccountIdMap = caseMap.get(c.Trigger_Date__c);
                if (existingCaseAccountIdMap.containsKey(c.AccountId)){
                    Map<String, Case> existingCaseReasonMap = existingCaseAccountIdMap.get(c.AccountId);
                    existingCaseReasonMap.put(c.Reason, c);
                } else {
                    existingCaseAccountIdMap.put(c.AccountId, caseReasonMap);
                }
            } else {
                caseMap.put(c.Trigger_Date__c, caseAccountIdMap);
            } 
        }
        for (Trigger__c t : recordsToProcess){
            if (caseMap.containsKey(t.Trigger_Date__c)){
                if (caseMap.get(t.Trigger_Date__c).containsKey(t.Parent_Account__c)){
                    Map<String, Case> caseReasonMap = caseMap.get(t.Trigger_Date__c).get(t.Parent_Account__c);
                    if (triggerHistoryNameReasonMap.containsKey(t.Name)){
                        if (caseReasonMap.containsKey(triggerHistoryNameReasonMap.get(t.Name))){
                            Case c = caseReasonMap.get(triggerHistoryNameReasonMap.get(t.Name));
                            t.Case__c = c.Id;
                            t.OwnerId = c.OwnerId;
                        }
                    }
                }
            }
        }
    }
    /**
    *   @description Return the distinct Trigger History Name to Case Reason Map collection
    *   Note: Trigger history names are associated to a Case reason in the metadata object 'Trigger_History_Reason_Mapping__mdt'
    **/      
    private static Map<String, String> getTriggerHistoryNameReasonMap() {
        Map<String, String> triggerHistoryNameReasonMap = new Map<String, String>();
        for (Trigger_History_Reason_Mapping__mdt mdt 
                        : [SELECT DeveloperName, MasterLabel, Case_Reason__c
                            FROM Trigger_History_Reason_Mapping__mdt
                            ORDER BY Case_Reason__c ASC  
                        ]){
            triggerHistoryNameReasonMap.put(mdt.MasterLabel, mdt.Case_Reason__c);
        }
        return triggerHistoryNameReasonMap;        
    }
}