/**
 * @author Mahesh Chouhan
 * @date  June 2023
 * @description Handler for Case Event Platform Event
 **/
public class CDdCaseEventTriggerHelper {
    private static Map<String,PlatformEventType> eventNameToEnumMap = null;

    public CDdCaseEventTriggerHelper(List<Case_Event__e> caseEvents){
        Set<Id> accIds = new Set<Id>();
        for(Case_Event__e event : caseEvents){
            Case caseRecord = (Case) JSON.deserialize(event.New_Case_Payload__c, Case.class);
            if(caseRecord.AccountId != null){
                accIds.add(caseRecord.AccountId);
            }
        }

        CDdCaseTriggerOptimizationHelper.setAccountMap(accIds);
    }

    /**
    * @author Mahesh Chouhan
    * @description Extend the Exception class for usage by this class
    **/
    public class CDdCaseEventException extends Exception {}

    /**
    * @author Mahesh Chouhan
    * @description Define the Platform Event Types used by the system
    **/
    public enum PlatformEventType {
        CHECK_DISASTER_ESCALATION
    }

    public static final Map<PlatformEventType, String> platformEventMap = new Map<PlatformEventType, String> {
        PlatformEventType.CHECK_DISASTER_ESCALATION  =>  'Check Disaster Escalation'
    };

    public static String strEventType(PlatformEventType eType) {
        String eventString = platformEventMap.containsKey(eType) ? platformEventMap.get(eType): null;
        if (eventString != null){
            return eventString;
        }
        throw new CDdCaseEventException('Platform Event Type: ' + eType + ' not found in platformEventMap.');
    }
   	/**
     * @author Mahesh Chouhan
     * @description Publish Case Event Platform Events
     * @param   List<Case_Event__e> eventList
     * @return
     **/
    public static void publishEvents(List<Case_Event__e> eventList){
        EventBus.publish(eventList);
    }

    /**
     * @author Mahesh Chouhan
     * @description Create and Publish Platform Events for New Case List and Old Case Map
     * @param   List<Case> newCaseList - Case in trigger.new
     * @param   Map<Id, Case> oldCaseMap - trigger.oldMap
     * @return
     **/
    public static void publishEvents(PlatformEventType eventType, List<Case> newCaseList, Map<Id,Case> oldCaseMap){
        publishEvents(createEvents(eventType, newCaseList, oldCaseMap));
    }

    /**
     * @author Mahesh Chouhan
     * @description Create Platform Events for New Case List and Old Case Map
     * @param   List<Case> newCaseList - Case in trigger.new
     * @param   Map<Id, Case> oldCaseMap - trigger.oldMap
     * @return  List<Case_Event__e>
     **/
    public static List<Case_Event__e> createEvents(PlatformEventType eventType, List<Case> newCaseList, Map<Id,Case> oldCaseMap){
        List<Case_Event__e> caseEventList = new List<Case_Event__e>();

        for(Case newCase : newCaseList){
            Case_Event__e caseEvent = new Case_Event__e();
            caseEvent.New_Case_Payload__c = JSON.serialize(newCase);
            caseEvent.Event_Type__c = strEventType(eventType);

            if(oldCaseMap.containsKey(newCase.Id)){
                caseEvent.Case_Id__c = newCase.Id;
                caseEvent.Old_Case_Payload__c = JSON.serialize(oldCaseMap.get(newCase.Id));
            }
            caseEventList.add(caseEvent);
        }

        return caseEventList;
    }

    public static Map<String,PlatformEventType> getEventNameToEnumMap() {
        if (eventNameToEnumMap != null) {
            return eventNameToEnumMap;
        }
        eventNameToEnumMap = new Map<String,PlatformEventType>();
        for (PlatformEventType pType : platformEventMap.keySet()) {
            eventNameToEnumMap.put(platformEventMap.get(pType),pType);
        }
        return eventNameToEnumMap;
    }

    public static PlatformEventType typeOf(String strEventType) {
        PlatformEventType eType = getEventNameToEnumMap().get(strEventType);
        if (eType != null) {
            return eType;
        }
        throw new CDdCaseEventException('Platform Event Type not found in platformEventMap for: ' + strEventType + '.');
    }

    /**
     * @description Apex Class Entry point for Merchant Services Event Trigger
     * @param List<Case_Event__e> caseEvents
     * @return
    */
    public void handleEvents(List<Case_Event__e> caseEvents) {
        Map<PlatformEventType, List<Case_Event__e>> eventMap = new Map<PlatformEventType, List<Case_Event__e>>();

        for (Case_Event__e e : caseEvents) {
            PlatformEventType eType = typeOf(e.Event_Type__c);
            if (!eventMap.containsKey(eType)) {
                eventMap.put(eType, new List<Case_Event__e>());
            }
            eventMap.get(eType).add(e);
        }

        for (PlatformEventType eType : eventMap.keySet()) {
            List<Case_Event__e> typeEvents = eventMap.get(eType);
            switch on eType {
                when CHECK_DISASTER_ESCALATION {
                    CDdCaseEventHelper.checkForDisasterPreventionCase(typeEvents);
                }
            }
        }
    }
}