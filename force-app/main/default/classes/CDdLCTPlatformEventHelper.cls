/**
 * @author Mahesh Chouhan
 * @date 07-16-2021
 * @description Handler for Live Chat Transcript Platform Event                            
**/
public class CDdLCTPlatformEventHelper {
    
    /**
    * @author Mahesh Chouhan
    * @description Extend the Exception class for usage by this class
    **/
    public class CDdLCTPlatformEventException extends Exception {}
    
    /**
    * @author Mahesh Chouhan
    * @description Define the Platform Event Types used by the system
    **/
    public enum PlatformEventType {
        LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD,        
        INCREMENT_VENDORCHATCOUNT               //used to increment vendor chat count
    }
    
    public static final Map<PlatformEventType, String> platformEventMap = new Map<PlatformEventType, String> {
        PlatformEventType.LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD  =>  'LCT TrueUp Vendor Dist',
        PlatformEventType.INCREMENT_VENDORCHATCOUNT  =>  'LCT Increment VendorCC'
    };
    
    public static String strEventType(PlatformEventType eType) {        
        String eventString = platformEventMap.containsKey(eType) ? platformEventMap.get(eType): null;
        if (eventString != null) return eventString;
        throw new CDdLCTPlatformEventException('Platform Event Type: ' + eType + ' not found in platformEventMap.');
    }
   
   	/**
    * @author Mahesh Chouhan
    * @description Create Platform Events from a Set<Id>
    **/
    public static List<Live_Chat_Transcript_Platform_Event__e> createEvents(PlatformEventType eType, Set<Id> sobjIds, String payload) {
        String eventString = strEventType(eType);
        List<Live_Chat_Transcript_Platform_Event__e> eventList = new List<Live_Chat_Transcript_Platform_Event__e>();
        if(sobjIds == null || sobjIds.isEmpty()) {
            eventList.add(new Live_Chat_Transcript_Platform_Event__e(
                sObjectId__c = null,
                Event_Type__c = eventString,
                Payload__c = payload
            ));
        } else {
            for (Id sobjId : sobjIds) {
                eventList.add(new Live_Chat_Transcript_Platform_Event__e(
                    sObjectId__c = sobjId,
                    Event_Type__c = eventString,
                    Payload__c = payload
                ));
            }
        }
        return eventList;
    }
    
   	/**
    * @author Mahesh Chouhan
    * @description Publish Platform Events
    **/
    public static void publishEvents(List<Live_Chat_Transcript_Platform_Event__e> eventList) {
        EventBus.publish(eventList);
    }
    
   	/**
    * @author Mahesh Chouhan
    * @description Create and Publish Platform Events from a Set<Id>
    **/
    public static List<Live_Chat_Transcript_Platform_Event__e> createEvents(PlatformEventType eType, List<Id> sobjIds) {
        return createEvents(eType, new Set<Id>(sobjIds), (String)null);
    }
    
    /**
    * @author Mahesh Chouhan
    * @description Create and Publish Platform Events from a Set<Id>
    **/
    public static void publishEvents(PlatformEventType eType, Set<Id> sobjIds) {
        publishEvents(createEvents(eType, sobjIds,(String)null));
    }
    
    /**
    * @author Mahesh Chouhan
    * @description Create and Publish Platform Events from a Payload
    **/
    public static void publishEvents(PlatformEventType eType, Set<Id> sobjIds, String payload) {
        publishEvents(createEvents(eType,sobjIds,payload));
    }
    
    /**
    * @author Mahesh Chouhan
    * @description Handle LCT Platform Events
    **/
    public static void handleEvents(List<Live_Chat_Transcript_Platform_Event__e > eventList) {
        for (PlatformEventType eType : platformEventMap.keySet()) {
            String strEvent = strEventType(eType);
            List<Live_Chat_Transcript_Platform_Event__e> typeEvents = new List<Live_Chat_Transcript_Platform_Event__e>();
            for (Live_Chat_Transcript_Platform_Event__e event : eventList)
                if (event.Event_Type__c == strEvent)
                    typeEvents.add(event);
            if (typeEvents.size() > 0) {
                if (eType == PlatformEventType.LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD) {
                    CDdLiveChatTransEventTriggerHandler.trueUpVendorDistributions(typeEvents[0].sObjectId__c);
                }
                else if (eType == PlatformEventType.INCREMENT_VENDORCHATCOUNT) {
                    Boolean runV2Trigger = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_LCT_Trigger_Optimization__c');
                    if (runV2Trigger) {
                        CDdLiveChatTransTriggerHandlerV2.handleIncrementVendorCCPE(typeEvents);
                    } else {
                        CDdLiveChatTranscriptTriggerHandler.handleIncrementVendorCCPE(typeEvents);
                    }
                }               
            }
        }
    }
}