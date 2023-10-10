/**
 * @description       : Qualtrics Send Survery Platform Even Handler
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 04-04-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdQualtricsSurveyEventTriggerHandler {

    /**
    * @description Public events
    * @author Jose Vega | 03-24-2022 
    * @param List<Qualtrics_Send_Survery_Event__e> eventList 
    **/
    public static void publishEvents(List<Qualtrics_Send_Survery_Event__e> eventList) {
        EventBus.publish(eventList);
    }

    /**
    * @description  Helper function to create Qualtrics_Send_Survery_Event__e
    * @author Jose Vega | 03-24-2022 
    * @param Set<Id> sobjIds 
    * @param String payload 
    * @return List<Qualtrics_Send_Survery_Event__e> 
    **/
    public static List<Qualtrics_Send_Survery_Event__e> createEvents(Set<Id> sobjIds) {
        List<Qualtrics_Send_Survery_Event__e> eventList = new List<Qualtrics_Send_Survery_Event__e>();

        for (Id sobjId : sobjIds) {
            eventList.add(new Qualtrics_Send_Survery_Event__e(
                sObjectId__c = sobjId
            ));
        }

        return eventList;
    }
    
    public static void publishEvents(Set<Id> sobjIds) {
        publishEvents(createEvents(sobjIds));
    }

    /**
    * @description afterInsert handlers for Qualtrics_Send_Survery_Event__e
    * @author Jose Vega | 03-24-2022 
    * @param List<Qualtrics_Send_Survery_Event__e> newList 
    **/
    public static void afterInsert(List<Qualtrics_Send_Survery_Event__e> newList) {
        CDdSurveyHelper.createDelightedTaskRecords(newList);
    }
}