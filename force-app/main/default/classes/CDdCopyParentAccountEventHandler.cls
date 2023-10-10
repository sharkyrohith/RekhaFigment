/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/22/2019
*
* @group Trigger Handler
*
* @description This trigger handler is a subscriber to the 'Copy Parent Account' platform event
* 
**************************************************************************************************************************************/
public class CDdCopyParentAccountEventHandler {
  /**
    * @description A static constant variable to hold the Account sObject type value
    **/ 
    private static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    /**
    * @description A static constant variable to hold the Lead sObject type value
    **/ 
    private static final String SOBJECT_TYPE_LEAD = 'Lead';    
    /**
    * @description A static constant variable to hold the Lead sObject type value
    **/ 
    private static final String SOBJECT_TYPE_OPPORTUNITY = 'Opportunity';
    /**
    * @description A static constant variable to maintain Opportunity stages closed
    **/ 
    private static final Set<String> OPPORTUNITY_STAGES_CLOSED = new Set<String>{'Closed Won','Closed Lost'};         
    /**
    * @description fire this method after the 'Copy Parent Account' event is published
    */
    public void afterInsert(List<Copy_Parent_Account_Event__e> newList) {
        List<Id> parentAccountIds = new List<Id>();
        List<Id> parentAccountIdsOpportunity = new List<Id>();
    	for (Copy_Parent_Account_Event__e e : newList){
            if (e.Copy_To_Opportunity__c){
                parentAccountIdsOpportunity.add((Id)e.Parent_Account_Id__c);
            } else {
                parentAccountIds.add((Id)e.Parent_Account_Id__c);
            }
        }
        if (parentAccountIds.size() > 0){
            performCopyAccountToAccount(parentAccountIds);
            performCopyAccountToLead(parentAccountIds);
        }

        if (parentAccountIdsOpportunity.size() > 0){
            performCopyAccountToOpportunity(parentAccountIdsOpportunity);
        }
    }
    /**
    * @description Perform copy of account to other account records
    */    
    private void performCopyAccountToAccount(List<Id> recordIds){
        Integer THRESHOLD_SIZE = new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_ACCOUNT);
        Integer BATCH_SIZE = new CDdSObjectCopyConfigObj().getBatchSize(SOBJECT_TYPE_ACCOUNT);
        CDdSObjectFieldCopyObj fieldCopyObj = new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT).getFieldCopyObj(SOBJECT_TYPE_ACCOUNT); 
        Set<String> targetRecordTypeDeveloperNames = fieldCopyObj.targetRecordTypeDeveloperNames;
        Integer recordCount =   [SELECT count()
                                FROM Account 
                                WHERE RecordType.DeveloperName IN :targetRecordTypeDeveloperNames  
                                AND (Id IN :recordIds OR ParentId IN :recordIds)];
        if (recordCount > THRESHOLD_SIZE){             
            Database.executeBatch(new CDdAccountFieldCopyToAccountBatch(recordIds), BATCH_SIZE);
        } else {
            List<Account> records = new List<Account>();
            for (Account record : [SELECT Id, ParentId
                                        FROM Account
                                        WHERE RecordType.DeveloperName IN :targetRecordTypeDeveloperNames
                                        AND (Id IN :recordIds OR ParentId IN :recordIds)]){
                records.add(record);
            }
            performCopy(fieldCopyObj, records, 'ParentId', 'Id');
        }     
    }
    /**
    * @description Perform copy of account to lead records
    */    
    private void performCopyAccountToLead(List<Id> recordIds){
        Integer THRESHOLD_SIZE = new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_LEAD);
        Integer BATCH_SIZE = new CDdSObjectCopyConfigObj().getBatchSize(SOBJECT_TYPE_LEAD);        
        CDdSObjectFieldCopyObj fieldCopyObj = new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT).getFieldCopyObj(SOBJECT_TYPE_LEAD); 
        Set<String> targetRecordTypeDeveloperNames = fieldCopyObj.targetRecordTypeDeveloperNames;
        Integer recordCount =   [SELECT count()
                                FROM Lead 
                                WHERE RecordType.DeveloperName IN :targetRecordTypeDeveloperNames
                                AND IsConverted = false  
                                AND Parent_Account__c IN :recordIds];
        if (recordCount > THRESHOLD_SIZE){             
            Database.executeBatch(new CDdAccountFieldCopyToLeadBatch(recordIds), BATCH_SIZE);
        } else {
            List<Lead> records = new List<Lead>();
            for (Lead record : [SELECT Id, Parent_Account__c
                                        FROM Lead
                                        WHERE RecordType.DeveloperName IN :targetRecordTypeDeveloperNames
                                        AND IsConverted = false  
                                        AND Parent_Account__c IN :recordIds]){
                records.add(record);
            }
            performCopy(fieldCopyObj, records, 'Parent_Account__c', 'Id');
        }       
    }        
    /**
    * @description Perform copy of account to opportunity records
    */    
    private void performCopyAccountToOpportunity(List<Id> recordIds){
        Integer THRESHOLD_SIZE = new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_OPPORTUNITY);
        Integer BATCH_SIZE = new CDdSObjectCopyConfigObj().getBatchSize(SOBJECT_TYPE_OPPORTUNITY);        
        CDdSObjectFieldCopyObj fieldCopyObj = new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT).getFieldCopyObj(SOBJECT_TYPE_OPPORTUNITY); 
        Set<String> targetRecordTypeDeveloperNames = fieldCopyObj.targetRecordTypeDeveloperNames;
        Integer recordCount =   [SELECT count()  
                                FROM Opportunity
                                WHERE RecordType.DeveloperName IN :targetRecordTypeDeveloperNames
                                AND StageName NOT IN :OPPORTUNITY_STAGES_CLOSED
                                AND AccountId IN :recordIds];
        if (recordCount > THRESHOLD_SIZE){             
            Database.executeBatch(new CDdAccountFieldCopyToOpportunityBatch(recordIds), BATCH_SIZE);
        } else {
            List<Opportunity> records = new List<Opportunity>();
            for (Opportunity record : [SELECT Id, AccountId  
                                        FROM Opportunity
                                        WHERE RecordType.DeveloperName IN :targetRecordTypeDeveloperNames
                                        AND StageName NOT IN :OPPORTUNITY_STAGES_CLOSED
                                        AND AccountId IN :recordIds]){
                records.add(record);
            }
            performCopy(fieldCopyObj, records, 'AccountId', 'Id');
        }        
    }
    /**
    * @description Perform copy of account to opportunity records
    */    
    private void performCopy(CDdSObjectFieldCopyObj fieldCopyObj, List<sObject> scope, String sourceKeyFieldName, String targetKeyFieldName){
        Set<Id> sourceRecordIds = new Set<Id>();
        Set<Id> targetRecordIds = new Set<Id>();
        List<String> errorMessages = new List<String>();
        for (SObject obj : scope){
            sourceRecordIds.add((Id)obj.get(sourceKeyFieldName));
            targetRecordIds.add((Id)obj.get(targetKeyFieldName));
        }
        List<sObject> targetRecords = new CDdSObjectFieldCopyProcessor(fieldCopyObj, sourceRecordIds, targetRecordIds).targetRecords;
        Savepoint savePointBeforeUpdate = Database.setSavepoint();
        try{
            Database.SaveResult[] updateResults = Database.update(targetRecords, false);
            errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
        } catch(Exception ex) {
            Database.rollback(savePointBeforeUpdate);
        }
        if(!errorMessages.isEmpty()){
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdCopyParentAccountEventHandlerBatch');
        }         
    }
}