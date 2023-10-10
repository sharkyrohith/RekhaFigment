/********************************************************************************************************************
* @author Venkat D
* @date 08/02/2022
*
* @group Trigger Handler
*
* @description Trigger handler helper methods for Event object
**********************************************************************************************************************/
public class CDdEventHelper {
    
    public static final List<String> EVENT_PRE_SALE_OUTCOME_LIST = new List<String>{'Held - DM Pitch','Held - Influencer Pitch','No-Show','Unqualified'};

    public static void processPreSaleEvents(Map<Id, Event> newMap){
        List<Event_Trigger_Platform_Event__e> preSaleEventList = new List<Event_Trigger_Platform_Event__e>();

        for(Id eventId:newMap.keySet()){
            Event eventRecord = newMap.get(eventId);
            if((String.isBlank(eventRecord.Event_Outcome__c) || EVENT_PRE_SALE_OUTCOME_LIST.contains(eventRecord.Event_Outcome__c)) && 
                        String.isNotBlank(eventRecord.WhoId) && String.valueOf(eventRecord.WhoId).startsWith(CDdCoreConstants.LEAD_SOBJECT_PREFIX)){
                preSaleEventList.add(new Event_Trigger_Platform_Event__e(Event_Type__c=CDdEventPlatformEventHandler.PRE_SALE_EVENT_TYPE,Event_Id__c = eventId));
            }
        }

        if(!preSaleEventList.isEmpty()){
            EventBus.publish(preSaleEventList);
        }
    }
}