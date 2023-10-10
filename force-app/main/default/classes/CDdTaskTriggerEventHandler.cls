/**
 * @description       : 
 * @author            : Dinesh Annapareddy
 * @group             : 
 * @last modified on  : 01-14-2022
 * @last modified by  : Dinesh Annapareddy
**/
public with sharing class CDdTaskTriggerEventHandler {
    public static final String CLASS_INFO = 'Class Name: CDdTaskTriggerEventHandler';
    public static void afterInsert(List<TaskTriggerEvent__e> newTaskEvents)
    {
        List<TaskTriggerEvent__e> preSaleLeadEvents = new List<TaskTriggerEvent__e>();
        List<TaskTriggerEvent__e> lQActivity = new List<TaskTriggerEvent__e>();
        for(TaskTriggerEvent__e tskTrigger:newTaskEvents)
        {
            if(tskTrigger.EventType__c == CDdTaskTriggerContants.PRE_SALE_TASK )
            {
                preSaleLeadEvents.add(tskTrigger);
            }
            if(tskTrigger.EventType__c == CDdTaskTriggerContants.LATEST_Q_ACTIVITY)
            {
                lQActivity.add(tskTrigger);
            }
        }

        if(preSaleLeadEvents.size()>0)
        {
            preSaleTypeleadStatus(preSaleLeadEvents);
        }
        if(lQActivity.size()>0)
        {
            latestQActivity(lQActivity);
        }
    
    }
    public static void preSaleTypeleadStatus(List<TaskTriggerEvent__e> preSaleLeadEvents)
    {
        Map<String,List<String>> leadStatusMap = CDdTaskTriggerContants.leadStatusMap;
        Map<String,Map<String,String>> leadChangeMap =CDdTaskTriggerContants.setleadChangeMap();
        Map<String,Task> leadTaskMap= new Map<String,Task>();
        List<String> tskIds= new List<String>();
        List<Lead> leadsToUpdate = new List<Lead>();
        for(TaskTriggerEvent__e tskTriggerEvt: preSaleLeadEvents)
        {
            tskIds.add(tskTriggerEvt.TaskId__c);
        }

        for(Task tsk: [Select Id,WhoId,Type from Task where Id IN: tskIds])
        {
            leadTaskMap.put(tsk.WhoId,tsk);
        }
        List<Lead> leadRecords = new List<Lead>([SELECT Id,Converted__c,Status from Lead where Id IN: leadTaskMap.keySet() and Converted__c =: False]);

        for(Lead leadRecord:leadRecords)
        {
            String taskType = leadTaskMap.get(leadRecord.Id).Type;
            for(String tskStatus:CDdTaskTriggerContants.taskStatusMap.keySet())
            {
                if(CDdTaskTriggerContants.taskStatusMap.get(tskStatus).contains(taskType))
                {
                    if(! CDdTaskTriggerContants.leadStatusMap.get(tskStatus).contains(leadRecord.Status))
                    {
                        Lead recordToUpdate = new Lead();
                        recordToUpdate.put('Id',leadRecord.Id);
                        Map<String,String> fieldsToUpdate = leadChangeMap.get(tskStatus);
                        for(String field:fieldsToUpdate.KeySet()) {
                            if(CDdTaskTriggerContants.dateTimeFieldsOnLead.contains(field)) {
                                DateTime dtVal = DateTime.valueOf(fieldsToUpdate.get(field));
                                recordToUpdate.put(field, dtVal);
                            } else {
                                recordToUpdate.put(field,fieldsToUpdate.get(field));
                            }
                        }
                        leadsToUpdate.add(recordToUpdate);

                        break;
                    }
                }
            }

            
        }

        if(leadsToUpdate.size()>0)
        {
            List<Database.SaveResult> sResults=Database.update(leadsToUpdate,false);
            CDdErrorUtilities.publishException('Lead',CLASS_INFO +'.preSaleTypeleadStatus', sResults);
        }
    }


    public static void latestQActivity(List<TaskTriggerEvent__e> lQActivity)
    {
        List<String> accountIds  = new List<String>();
        List<String> leadIds  = new List<String>();
        List<String> tskIds = new List<String>();
        for(TaskTriggerEvent__e tskTriggerEvt: lQActivity)
        {
            tskIds.add(tskTriggerEvt.TaskId__c);
        }
        for(Task tsk: [Select Id,WhoId,Type from Task where Id IN: tskIds])
        {
            if((String.valueOf(tsk.whoId).substring(0,3) == CDdCoreConstants.LEAD_SOBJECT_PREFIX))
            {
                leadIds.add(tsk.whoId);
            }
            if((String.valueOf(tsk.whoId).substring(0,3) == CDdCoreConstants.ACCOUNT_SOBJECT_PREFIX))
            {
                accountIds.add(tsk.whoId);
            }
        }
        if(leadIds.size()>0)
        {
            lQUpdateLeads(leadIds);
        }
        if(accountIds.size()>0)
        {
            lQUpdateAccounts(accountIds);
        }


    }

    public static void lQUpdateAccounts(List<String> acctIds){
        List<Account> accountRecordsToUpdate = new List<Account>([Select Id from Account where Id IN:acctIds]);
        List<String> accountIds= new List<String>();
        for(Account accountRecord:accountRecordsToUpdate)
        {
            accountRecord.Latest_Qualified_Activity__c=Date.Today();
            accountRecord.BypassValidationForProcessBuilder__c = TRUE;
            accountIds.add(accountRecord.Id);
        }
        List<Database.SaveResult> sResults=Database.update(accountRecordsToUpdate,false);
        CDdErrorUtilities.publishException('Lead',CLASS_INFO +'.lQUpdateAccounts', sResults);
    }
    
    public static void lQUpdateLeads(List<String> leadIds){
        List<Lead> leadRecordsToUpdate = new List<Lead>([Select Id,First_Qualified_Activity_Date_Time__c from Lead where Id IN:leadIds]);
        for(Lead leadRecord:leadRecordsToUpdate)
        {
            leadRecord.Last_Qualified_Activity_Date_Time__c = datetime.now();
            leadRecord.Recent_Qualified_Activity_Date__c=Date.Today();
            leadRecord.Validation_Bypass__c = TRUE;
            if(leadRecord.First_Qualified_Activity_Date_Time__c == null)
            {
                leadRecord.First_Qualified_Activity_Date_Time__c= datetime.now();
            }
        }
        Database.update(leadRecordsToUpdate,false);
    }

}