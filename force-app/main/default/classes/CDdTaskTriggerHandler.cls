/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/12/2019
*
* @group Trigger Handler
*
* @description Trigger handler for task object

@author Dinesh Annapareddy (Critical River)
* @date 12/03/2021
*
* @group Trigger Handler
*
* @description Trigger handler for task object
**************************************************************************************************************************************/
public class CDdTaskTriggerHandler {
    public static boolean isCountingTask = false;
    /**
    * @description After insert trigger event
    */
    Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getInstance();
    public void afterInsert(List<Task> newList) {
        isCountingTask = true;
        CDdTaskHelperMethods.applyTaskCount(newList,null);
        if (Test.isRunningTest() || !CDdCustomMetaData.isDisabled('CDdTaskHelperMethods_updateTaskCount')){
            CDdTaskHelperMethods.updateLeadOrOpportunityDailyTaskCount(newList);
        }
        if (CDdTaskHelperMethods.useNewFramework) {
            CDdDMLBulkifier.processUpdateDMLRegistryRecords();
        }
        isCountingTask = false;
        CDdTaskHelperMethods.createTaskQualifiedTriggerEvents(newList);
        CDdTaskHelperMethods.createTaskTriggerEvents(newList,null);
        CDdTaskHelperMethods.updateOutreachEHT(newList);
    }
    /**
    * @description After update trigger event
    */
    public void afterUpdate(Map<Id, Task> newMap, Map<Id, Task> oldMap) {
        isCountingTask = true;
        CDdTaskHelperMethods.applyTaskCount(newMap.values(),oldMap);
        if (Test.isRunningTest() || !CDdCustomMetaData.isDisabled('CDdTaskHelperMethods_updateTaskCount')){
            CDdTaskHelperMethods.updateLeadOrOpportunityDailyTaskCount(newMap.values(), oldMap);
        }
        if (CDdTaskHelperMethods.useNewFramework) {
            CDdDMLBulkifier.processUpdateDMLRegistryRecords();
        }
        isCountingTask = false;
        CDdTaskHelperMethods.createTaskTriggerEvents(newMap.values(),oldMap);
    }
    /**
    * @description before delete trigger event
    */
    public void beforeDelete (List<Task> oldList) {
        Task_Trigger_Setting__c triggerSetting = Task_Trigger_Setting__c.getInstance();
        Boolean allowTaskDeletion = triggerSetting.Allow_Task_Deletion__c;
        if (!allowTaskDeletion) {
            CDdTaskHelperMethods.donotDeleteTask(oldList);
        }

     }
    /**
    * @description before Upsert trigger event
    */
    public void beforeUpsert(List<Task> newList)
    {
        for(Task tsk:newList)
        {
            if( tsk.Description != NULL
                && tsk.Description.length()>255) {
                CDdTaskHelperMethods.truncateTaskComments(tsk);
            }
            if(tsk.WhoId != null) {
                CDdTaskHelperMethods.updateLeadLookup(tsk);
            }
        }
    }

    public void beforeInsert(List<Task> newList)
    {
        Map<String,String> recordTypeMap=CDdTaskTriggerContants.getRecordTypeMap('Task');
        for(Task tsk:newList)
        {
            if (recordTypeMap.containsKey(tsk.RecordTypeId) &&
                CDdTaskTriggerContants.trustSafetyRecordType.contains(recordTypeMap.get(tsk.RecordTypeId))
                )
            {
                CDdTaskHelperMethods.updateDueDate(tsk,CDdTaskTriggerContants.trustSafetyTeam);

            }
        }
    }





}