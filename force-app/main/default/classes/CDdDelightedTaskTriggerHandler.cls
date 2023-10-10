/**
 * 
 * @author: Tia Xuan
 * @date: 2020-04
 * @description class for Delighted Task Trigger
 * 
 */ 
public class CDdDelightedTaskTriggerHandler {
    public void beforeInsert(List<Delighted_Tasks__c> newList){
        CDdDelightedTaskHelper.updateSubscriptionLink(newList);
        CDdDelightedTaskHelper.updateDelightedTaskSendTime(newList, null);
    }

    public void beforeUpdate(List<Delighted_Tasks__c> newList, Map<Id, Delighted_Tasks__c> oldMap){
        CDdDelightedTaskHelper.updateDelightedTaskSendTime(newList, oldMap);
        CDdDelightedTaskHelper.updateSubscriptionLink(newList);
    }

    public void afterInsert(List<Delighted_Tasks__c> newList){
        CDdDelightedTaskHelper.updateCases(newList,null);
        CDdDelightedTaskHelper.sendQualtricSurvey(newList);
        CDdDelightedTaskHelper.sendCSATSurvey(newList);
    }

    public void afterUpdate(List<Delighted_Tasks__c> newList, Map<Id, Delighted_Tasks__c> oldMap){
        CDdDelightedTaskHelper.updateCases(newList,oldMap);
    }
}