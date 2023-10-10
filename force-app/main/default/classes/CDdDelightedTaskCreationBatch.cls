/**
 * @description       : 
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 10-17-2022
 * @last modified by  : Jose Vega
**/
public class CDdDelightedTaskCreationBatch implements Database.Batchable<SObject>, Schedulable{
    public CDdDelightedTaskCreationBatch() {

    }
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CDdDelightedTaskCreationBatch(), CDdCustomMetadata.getBatchSize('CDdDelightedTaskCreationBatch'));

    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Map<String, RecordTypeInfo> CASE_RT_INFO = Schema.SObjectType.Case.getRecordTypeInfosByName();
        String query = 'Select id, Delighted_Task_Created__c, Language__c, Customer_Type__c, Resolution__c, Issue__c, '
                            + ' Communities_Dependent_Dx_Category__c, Status, recordTypeId, Survey_Taken_Date__c, ChatKey__c, '
                            + ' Origin, ContactId, ContactEmail, SuppliedEmail, ParentId, Do_Not_Sent_Survey__c '
                        + ' FROM Case'
                        + ' WHERE CreatedDate = last_N_days:' + CDdCustomMetadata.getCustomNumber('CDdDelightedTaskCreationBatch')
                            + ' AND recordTypeId = \'' +  CASE_RT_INFO.get(CDdSupportConstants.RECORDTYPE_NAME_SUPPORT).getRecordTypeId() + '\''
                            + ' AND Status = \'Solved\''
                            + ' AND Delighted_Task_Created__c = NULL'
                            + ' AND Survey_Taken_Date__c = NULL'
                            + ' AND Do_Not_Sent_Survey__c = FALSE';
        CDdErrorUtilities.publishException('CDdDelightedTaskCreationBatch', 'Start', null, query);
        System.debug('CDdDelightedTaskCreationBatch + query = '+query);
        return Database.getQueryLocator(query);

    }

    public void execute(Database.BatchableContext BC, List<Case> scope) {
        system.debug('CDdDelightedTaskCreationBatch: execute: scope: ' + scope);
        CDdCaseTriggerHelperV2.sendSurvey(scope, null, !CDdCustomMetadata.isDisabled('Platform_Event_Send_Survey_Batch'));
    }
    public void finish(Database.BatchableContext BC) {

    }
}