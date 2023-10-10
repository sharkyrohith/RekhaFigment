/**
 * 
 * @author: Jeegar Brahmakshatriya
 * @date: 2019-12
 * @description Trigger for Service_Task__c
 *              Checks for Only one Active task in progress at a time on a Case
 *              Calculate Time spent on the Case when a Service Task is updated. 
 *              Create a new task after a task is Completed. 
 */

public with sharing class CDdServiceTaskHandler{
    public static void handleBeforeInsert (List<Service_Task__c> newList) {
        CDdServiceTaskHelper.checkForActiveTasks(newList);
    }
    public static void handleBeforeUpdate(List<Service_Task__c> newList, Map<Id, Service_Task__c> oldMap) {
        CDdServiceTaskHelper.calculateTimeSpent(newList, oldMap);
    }
    public static void handleAfterUpdate(List<Service_Task__c> newList, Map<Id, Service_Task__c> oldMap) {
        CDdServiceTaskHelper.createNextTasks(newList,oldMap);
    }
}