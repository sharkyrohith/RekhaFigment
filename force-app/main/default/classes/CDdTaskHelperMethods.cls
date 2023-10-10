/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/12/2019
*
* @group Trigger Handler
*
* @description Trigger handler helper methods for task object
**************************************************************************************************************************************/
public class CDdTaskHelperMethods {
    public static final Boolean useNewFramework = !CDdCustomMetadata.getBatchAndTriggerMetadata('TDdTaskTrigger_NewFramework').Disabled__c;

    public static final Schema.sObjectType LEAD_SOBJECT_TYPE = LEAD.sObjectType;
    public static final Schema.sObjectType ACCOUNT_SOBJECT_TYPE = Account.sObjectType;
    public static final Schema.sObjectType Opportunity_SOBJECT_TYPE = Opportunity.sObjectType;
    public static final String OUTREACH_INTEGRATION_USER_PRESALE  = 'Outreach Integration User PreSale';

    public enum TaskType {Call, Email}

    public static final Set<String> TASK_TYPES_CALL;
    public static final Set<String> TASK_TYPES_EMAIL;
    public static final Set<String> TASK_TYPES_FOR_CALL_AND_EMAIL;

    static {
        TASK_TYPES_FOR_CALL_AND_EMAIL = new Set<String>();
        TASK_TYPES_CALL = new Set<String>();
        TASK_TYPES_EMAIL = new Set<String>();
        for (Task_Type__mdt t : [SELECT MasterLabel, Type__c FROM Task_Type__mdt]){
            if (TaskType.Call.name().equals(t.Type__c)){
                TASK_TYPES_CALL.add(t.MasterLabel);
                TASK_TYPES_FOR_CALL_AND_EMAIL.add(t.MasterLabel);
            }
            if (TaskType.Email.name().equals(t.Type__c)){
                TASK_TYPES_EMAIL.add(t.MasterLabel);
                TASK_TYPES_FOR_CALL_AND_EMAIL.add(t.MasterLabel);
            }
        }
    }
    /**
    * @description Apply task count
    */
    public static void applyTaskCount(List<Task> newList,Map<Id, Task> oldMap) {
        applyTaskCountForLeads(getAssociatedRecordIds(LEAD_SOBJECT_TYPE, newList,oldMap));
        applyTaskCountForAccounts(getAssociatedRecordIds(ACCOUNT_SOBJECT_TYPE, newList,oldMap));
        applyTaskCountForOpportunities(getAssociatedRecordIds(Opportunity_SOBJECT_TYPE, newList,oldMap));
    }
    /**
    * @description Apply task count for Leads
    */
    public static void applyTaskCountForLeads(Set<Id> leadIds) {
        List<Lead> leads = new List<Lead>();
        List<String> errorMessages = new List<String>();
        for (Lead l : [ SELECT Id, OwnerId, (SELECT Id, OwnerId, Type FROM Tasks WHERE Type IN :TASK_TYPES_FOR_CALL_AND_EMAIL)
                        FROM Lead
                        WHERE Id IN :leadIds ]){
            Integer taskCallCount = 0;
            Integer taskCallOwnerCount = 0;
            Integer taskEmailCount = 0;
            Integer taskEmailOwnerCount = 0;
            for (Task t : l.Tasks){
                if (TASK_TYPES_CALL.contains(t.Type)){
                    ++taskCallCount;
                    if (l.OwnerId.equals(t.OwnerId)){
                        ++taskCallOwnerCount;
                    }
                }
                if (TASK_TYPES_EMAIL.contains(t.Type)){
                    ++taskEmailCount;
                    if (l.OwnerId.equals(t.OwnerId)){
                        ++taskEmailOwnerCount;
                    }
                }
            }
            leads.add(new Lead(Id = l.Id, Task_Call_Count__c = taskCallCount, Task_Call_Owner_Count__c = taskCallOwnerCount,
                Task_Email_Count__c = taskEmailCount, Task_Email_Owner_Count__c = taskEmailOwnerCount));
        }

        if (useNewFramework) {
            CDdDMLBulkifier.enqueueDML(leads, CDdDMLBulkifier.DML.UPDATE_DML);

        } else {
             Savepoint savePointBeforeUpdate = Database.setSavepoint();
             try{
                 Database.SaveResult[] updateResults = Database.update(leads, false);
                 errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
             } catch(Exception ex) {
                 Database.rollback(savePointBeforeUpdate);
             }
             if(!errorMessages.isEmpty()){
                 CDdErrorUtilities.createApexLogs(errorMessages, 'CDdTaskHelperMethods');
             }
        }
    }
    /**
    * @description Apply task count for Accounts
    */
    public static void applyTaskCountForAccounts(Set<Id> accountIds) {
        List<Account> accounts = new List<Account>();
        List<String> errorMessages = new List<String>();
        for (Account a : [  SELECT Id, OwnerId, (SELECT Id, OwnerId, Type FROM Tasks WHERE Type IN :TASK_TYPES_FOR_CALL_AND_EMAIL)
                        FROM Account
                        WHERE Id IN :accountIds ]){
            Integer taskCallCount = 0;
            Integer taskCallOwnerCount = 0;
            Integer taskEmailCount = 0;
            Integer taskEmailOwnerCount = 0;
            for (Task t : a.Tasks){
                if (TASK_TYPES_CALL.contains(t.Type)){
                    ++taskCallCount;
                    if (a.OwnerId.equals(t.OwnerId)){
                        ++taskCallOwnerCount;
                    }
                }
                if (TASK_TYPES_EMAIL.contains(t.Type)){
                    ++taskEmailCount;
                    if (a.OwnerId.equals(t.OwnerId)){
                        ++taskEmailOwnerCount;
                    }
                }
            }
            accounts.add(new Account(Id = a.Id, Task_Call_Count__c = taskCallCount, Task_Call_Owner_Count__c = taskCallOwnerCount,
                Task_Email_Count__c = taskEmailCount, Task_Email_Owner_Count__c = taskEmailOwnerCount));
        }

        if (useNewFramework) {
            CDdDMLBulkifier.enqueueDML(accounts, CDdDMLBulkifier.DML.UPDATE_DML);

        } else {
            Savepoint savePointBeforeUpdate = Database.setSavepoint();
            try{
                Database.SaveResult[] updateResults = Database.update(accounts, false);
                errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
            } catch(Exception ex) {
                Database.rollback(savePointBeforeUpdate);
            }
            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdTaskHelperMethods');
            }
        }
    }
   /**
    * @description Apply task count for Opportunities
    */
    public static void applyTaskCountForOpportunities(Set<Id> oppIds) {
        List<Opportunity> opportunities = new List<Opportunity>();
        List<String> errorMessages = new List<String>();
        for (Opportunity l : [ SELECT Id, OwnerId, (SELECT Id, OwnerId, Type FROM Tasks WHERE Type IN :TASK_TYPES_CALL)
                        FROM Opportunity
                        WHERE Id IN :oppIds ]){
            Integer taskCallOwnerCount = 0;
            for (Task t : l.Tasks){
                if (TASK_TYPES_CALL.contains(t.Type)){
                    if (l.OwnerId.equals(t.OwnerId)){
                        ++taskCallOwnerCount;
                    }
                }
            }
            opportunities.add(new Opportunity(Id = l.Id,Task_Call_Owner_Count__c = taskCallOwnerCount));
        }
        if (useNewFramework) {
            CDdDMLBulkifier.enqueueDML(opportunities, CDdDMLBulkifier.DML.UPDATE_DML);
        } else {
             Savepoint savePointBeforeUpdate = Database.setSavepoint();
             try{
                 Database.SaveResult[] updateResults = Database.update(opportunities, false);
                 errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
             } catch(Exception ex) {
                 Database.rollback(savePointBeforeUpdate);
             }
             if(!errorMessages.isEmpty()){
                 CDdErrorUtilities.createApexLogs(errorMessages, 'CDdTaskHelperMethods');
             }
        }
    }
    /**
    * @description Return the Record Identifiers of the SObjects to which the tasks are associated to
    */
    private static Set<Id> getAssociatedRecordIds(Schema.sObjectType newSObjectType, List<Task> newList,Map<Id, Task> oldMap){
        Set<Id> identifiers = new Set<Id>();
        for (Task t : newList){
            if(oldMap == null || oldMap.get(t.Id).Type != t.Type || oldMap.get(t.Id).OwnerId != t.OwnerId){
                if (String.isNotBlank(t.WhoId) && (t.WhoId.getSobjectType() == newSObjectType)){
                    identifiers.add(t.WhoId);
                }
                if (String.isNotBlank(t.AccountId) && (ACCOUNT_SOBJECT_TYPE == newSObjectType)){
                    identifiers.add(t.AccountId);
                }
                if (String.isNotBlank(t.WhatId) && (t.WhatId.getSobjectType() == newSObjectType)){
                    identifiers.add(t.WhatId);
                }
            }
        }
        return identifiers;
    }

    public static void updateLeadOrOpportunityDailyTaskCount(List<Task> newRecs, Map<Id, Task> oldRecs){
        Set<Id> whatOrwhoOrOwnerIds = new Set<Id>();
        for(Task task: newRecs){
            whatOrwhoOrOwnerIds.add(task.WhatId);
            whatOrwhoOrOwnerIds.add(task.WhoId);
            whatOrwhoOrOwnerIds.add(task.OwnerId);
            whatOrwhoOrOwnerIds.add(oldRecs.get(task.Id).WhatId);
            whatOrwhoOrOwnerIds.add(oldRecs.get(task.Id).WhoId);
            whatOrwhoOrOwnerIds.add(oldRecs.get(task.Id).OwnerId);
        }
        updateLeadOrOpportunityDailyTaskCount(whatOrwhoOrOwnerIds);
    }

    public static void updateLeadOrOpportunityDailyTaskCount(List<Task> newRecs){
        Set<Id> whatOrwhoOrOwnerIds = new Set<Id>();
        for(Task task: newRecs){
            whatOrwhoOrOwnerIds.add(task.WhatId);
            whatOrwhoOrOwnerIds.add(task.WhoId);
            whatOrwhoOrOwnerIds.add(task.OwnerId);
        }
        updateLeadOrOpportunityDailyTaskCount(whatOrwhoOrOwnerIds);
    }
    @testVisible static void updateLeadOrOpportunityDailyTaskCount(Set<Id> whatOrwhoOrOwnerIds){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Lead> leadsToUpdate = new List<Lead>();
        for(Opportunity opp:[SELECT Id, OwnerId, Task_Call_Owner_Count_Today__c, Task_Email_Owner_Count_Today__c,
                (SELECT Id, OwnerId, Type FROM Tasks WHERE CreatedDate = TODAY
                    AND Type IN :TASK_TYPES_FOR_CALL_AND_EMAIL AND Owner.Type = 'User')
                 FROM Opportunity WHERE Id IN :whatOrwhoOrOwnerIds]){
            setTaskCount(opp, opp.tasks);
            oppsToUpdate.add(new Opportunity(Id = opp.Id,
                Task_Call_Owner_Count_Today__c = opp.Task_Call_Owner_Count_Today__c,
                Task_Email_Owner_Count_Today__c = opp.Task_Email_Owner_Count_Today__c));
        }
        for(Lead lead:[SELECT Id, OwnerId, Task_Call_Owner_Count_Today__c, Task_Email_Owner_Count_Today__c,
                (SELECT Id, OwnerId, Type FROM Tasks WHERE CreatedDate = TODAY
                    AND Type IN :TASK_TYPES_FOR_CALL_AND_EMAIL AND Owner.Type = 'User')
                FROM Lead WHERE Id IN :whatOrwhoOrOwnerIds AND Owner.Type = 'User']){
            setTaskCount(lead, lead.tasks);
            leadsToUpdate.add(new Lead(Id = lead.Id,
                Task_Call_Owner_Count_Today__c = lead.Task_Call_Owner_Count_Today__c,
                Task_Email_Owner_Count_Today__c = lead.Task_Email_Owner_Count_Today__c));
        }

        if (useNewFramework) {
            CDdDMLBulkifier.enqueueDML(leadsToUpdate, CDdDMLBulkifier.DML.UPDATE_DML);
            CDdDMLBulkifier.enqueueDML(oppsToUpdate, CDdDMLBulkifier.DML.UPDATE_DML);
        } else {
             List<String> saveResultMessages = new List<String>();
             Database.SaveResult[] leadsUpdateResults = Database.update(leadsToUpdate, false);
             Database.SaveResult[] oppsUpdateResults = Database.update(oppsToUpdate, false);
             saveResultMessages.addAll(CDdErrorUtilities.processSaveResults(leadsUpdateResults, new List<String>()));
             saveResultMessages.addAll(CDdErrorUtilities.processSaveResults(oppsUpdateResults, new List<String>()));
             CDdErrorUtilities.createApexLogs(saveResultMessages, 'CDdTaskHelperMethods');
        }
    }

    @testVisible static void setTaskCount(SObject obj, List<Task> tasks){
        Decimal callCount = 0, emailCount = 0;
        for(Task task: tasks){
            if(task.OwnerId  != obj.get('OwnerId') ){
                continue;
            }
            if(TASK_TYPES_CALL.contains(task.Type)){
                callCount++;
                continue;
            }
            emailCount++;
        }
        obj.put('Task_Email_Owner_Count_Today__c',emailCount);
        obj.put('Task_Call_Owner_Count_Today__c',callCount);
    }

    /**
    * @description Don't allow deletion of tasks
    */
    public static void donotDeleteTask(List <Task> oldList){
        for (Task currentTask : oldList){
            currentTask.addError('You cannot delete this record');
        }
    }
/*
*@author .......Dinesh Annapareddy (Critical River)
*@date .........12/07/2021
*@Description :.Method inserts platform events to execute LeadStatus update
*
*/

//Replace Show all versionsPre-Sale Task Type updates Lead Status
    public static void createTaskTriggerEvents(List<Task> newList,Map<Id, Task> oldMap){
        List<String> taskIds = new List<String>();
        List<TaskTriggerEvent__e> tskEvntsToInsert = new List<TaskTriggerEvent__e>();
        for(Task tsk: newList)
        {
            if(tsk.whoId != NULL &&
                String.valueOf(tsk.whoId).substring(0,3) == CDdCoreConstants.LEAD_SOBJECT_PREFIX &&
                CDdTaskTriggerContants.getAllTaskStatusValues().contains(tsk.Type) &&
                (oldMap == null || tsk.Type != oldMap.get(tsk.Id).Type))
            {
                taskIds.add(tsk.Id);
                TaskTriggerEvent__e tskEvntToInsert = new TaskTriggerEvent__e();
                tskEvntToInsert.TaskId__c = tsk.Id;
                tskEvntToInsert.EventType__c = CDdTaskTriggerContants.PRE_SALE_TASK;
                tskEvntsToInsert.add(tskEvntToInsert);
            }
        }
        if(tskEvntsToInsert.size()>0)
        {
            List<Database.SaveResult> results = EventBus.publish(tskEvntsToInsert);
            CDdErrorUtilities.publishException('CDdTaskHelperMethods', 'createTaskTriggerEvents', results);
        }


    }


    //Replace Show all Lastest Qualified Activity
    public static void createTaskQualifiedTriggerEvents(List<Task> newList){
        List<String> taskIds = new List<String>();
        List<TaskTriggerEvent__e> tskEvntsToInsert = new List<TaskTriggerEvent__e>();
        for(Task tsk: newList)
        {
            if(tsk.whoId != NULL && (String.valueOf(tsk.whoId).substring(0,3) == CDdCoreConstants.LEAD_SOBJECT_PREFIX ||
                String.valueOf(tsk.whoId).substring(0,3) == CDdCoreConstants.ACCOUNT_SOBJECT_PREFIX) &&
                !CDdTaskTriggerContants.latestQActivity.contains(tsk.Type))
            {
                taskIds.add(tsk.Id);
                TaskTriggerEvent__e tskEvntToInsert = new TaskTriggerEvent__e();
                tskEvntToInsert.TaskId__c = tsk.Id;
                tskEvntToInsert.EventType__c = CDdTaskTriggerContants.LATEST_Q_ACTIVITY;
                tskEvntsToInsert.add(tskEvntToInsert);
            }
        }
        if(tskEvntsToInsert.size()>0)
            {
                List<Database.SaveResult> results = EventBus.publish(tskEvntsToInsert);
                CDdErrorUtilities.publishException('CDdTaskHelperMethods', 'createTaskQualifiedTriggerEvents', results);
            }

    }
// truncate to match the Task Comments character limit
    public static void truncateTaskComments(Task tsk)
    {
        tsk.Task_Comments__c = tsk.Description.left(252)+CDdSupportConstants.CONTINUED;
    }

    public static void updateLeadLookup(Task tsk)
    {
        if(String.valueOf(tsk.whoId).substring(0,3) == CDdCoreConstants.LEAD_SOBJECT_PREFIX)
        {
            tsk.Lead__c = tsk.WhoId;
        }
    }

    public static void updateDueDate(Task tsk, List<String> trustSafetyTeam)
    {
        if(trustSafetyTeam.contains(tsk.Team__c))
        {
            tsk.activitydate = Date.today().addDays(CDdTaskTriggerContants.DUE_DATE_THRESHOLD);
        }
    }
    /**
     * @author Swedhaa Sri M
     * @date 01/2023
     * @description: BASD-43678 Update Outreach_EHT__c field when TaskSubType is Email or Call
     */
    public static void updateOutreachEHT(List<Task> newRecs){
        List<Task> newTasks = [SELECT Id, TaskSubtype, CreatedBy.Name From Task
                               WHERE Id IN: newRecs
                               AND CreatedBy.Name =: OUTREACH_INTEGRATION_USER_PRESALE AND (TaskSubtype = 'Call' OR TaskSubtype = 'Email')];
        List<Task> taskstoUpdate = new List<Task>();
        for(Task task: newTasks){
            String tskSubType = task.TaskSubtype;
            task.Outreach_EHT__c = tskSubType.equalsIgnoreCase('Call')? 15 : 5;
            taskstoUpdate.add(task);
        }
        if(!taskstoUpdate.isEmpty()){
            update taskstoUpdate;
        }
    }
}