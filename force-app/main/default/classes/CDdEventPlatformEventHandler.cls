/********************************************************************************************************************
* @author Venkat D
* @date 08/02/2022
*
*
* @description This is handler class for 'Event' platform events
* BZAP-15836 - Convert "Pre-Sale Event Outcome updates Lead Status" Process Builder to Trigger to improve performance
* New Platform event Event_Trigger_Platform_Event__e has been created for event. The Generic platform event has been used in many places and reached its limits.
* 
********************************************************************************************************************/
public class CDdEventPlatformEventHandler {
    
    public static final String PRE_SALE_EVENT_TYPE = 'Pre Sale';
    public static final String LEAD_STATUS_MEETING_RAN_NEGOTOATED = 'Meeting Ran / Negotiated';
    public static final String LEAD_STATUS_DM_FOUND = 'DM Found';
    public static final String LEAD_STATUS_MEETING_SET = 'Meeting Set';

    public static final String EVENT_OUTCOME_HELD_DM_PITCH = 'Held - DM Pitch';
    public static final String EVENT_OUTCOME_HELD_INFLUENCER_PITCH = 'Held - Influencer Pitch';
    public static final String EVENT_OUTCOME_NO_SHOW = 'No-Show';
    public static final String EVENT_OUTCOME_UNQUALIFIED = 'Unqualified';
    

    public void afterInsert(List<Event_Trigger_Platform_Event__e> newList) {
        Map<String,List<Event_Trigger_Platform_Event__e>> eventMap = new Map<String,List<Event_Trigger_Platform_Event__e>>();

        for (Event_Trigger_Platform_Event__e e : newList) {
            if (!eventMap.containsKey(e.Event_Type__c)) {
                eventMap.put(e.Event_Type__c, new List<Event_Trigger_Platform_Event__e>());
            }
            eventMap.get(e.Event_Type__c).add(e);
        }

        for (String eType : eventMap.keySet()) {
            List<Event_Trigger_Platform_Event__e> typeEvents = eventMap.get(eType);
            if(eType == PRE_SALE_EVENT_TYPE) {
                processPreSaleEvents(typeEvents);
            }
        }
    }

    public void processPreSaleEvents(List<Event_Trigger_Platform_Event__e> eventList){
        List<String> eventIdList = new List<String>();
        for(Event_Trigger_Platform_Event__e eventEntry:eventList){
            eventIdList.add(eventEntry.Event_Id__c);
        }

        List<Event> eventRecordList = [SELECT Id,WhoId,Event_Outcome__c,Parent_Account__c,Parent_Account__r.of_leads_on_parent__c FROM EVENT WHERE Id IN :eventIdList];
        Map<Id,List<Lead>> accountLeadMap = getLeadsByAccount(eventRecordList);

        Map<Id,Lead> leadsToBeUpdated = new Map<Id,Lead>();
        Map<Id,Account> accountsToBeUpdated = new Map<Id,Account>();

        for(Event eventRecord:eventRecordList){
            Id leadId = eventRecord.WhoId;
            
            if((eventRecord.Event_Outcome__c ==  EVENT_OUTCOME_HELD_DM_PITCH || eventRecord.Event_Outcome__c == EVENT_OUTCOME_HELD_INFLUENCER_PITCH) && eventRecord.Parent_Account__c == null){
                setLeadValues(leadsToBeUpdated,leadId,LEAD_STATUS_MEETING_RAN_NEGOTOATED,System.now(),null);
            }else if((eventRecord.Event_Outcome__c ==  EVENT_OUTCOME_HELD_DM_PITCH || eventRecord.Event_Outcome__c == EVENT_OUTCOME_HELD_INFLUENCER_PITCH) && eventRecord.Parent_Account__c != null && eventRecord.Parent_Account__r.of_leads_on_parent__c <= 500){
                setLeadValues(leadsToBeUpdated,leadId,LEAD_STATUS_MEETING_RAN_NEGOTOATED,System.now(),null);

                accountsToBeUpdated.put(eventRecord.Parent_Account__c,new Account(Id=eventRecord.Parent_Account__c,Last_Meeting_Ran__c = System.now()));
                if(accountLeadMap.containsKey(eventRecord.Parent_Account__c)){
                    for(Lead relatedLeadRec:accountLeadMap.get(eventRecord.Parent_Account__c)){
                        setLeadValues(leadsToBeUpdated,relatedLeadRec.Id,LEAD_STATUS_MEETING_RAN_NEGOTOATED,System.now(),null);
                    }
                }
            }else if((eventRecord.Event_Outcome__c == EVENT_OUTCOME_NO_SHOW || eventRecord.Event_Outcome__c == EVENT_OUTCOME_UNQUALIFIED) && eventRecord.Parent_Account__c == null){
                setLeadValues(leadsToBeUpdated,leadId,LEAD_STATUS_DM_FOUND,null,null);
            }else if((eventRecord.Event_Outcome__c == EVENT_OUTCOME_NO_SHOW || eventRecord.Event_Outcome__c == EVENT_OUTCOME_UNQUALIFIED) && eventRecord.Parent_Account__c != null && eventRecord.Parent_Account__r.of_leads_on_parent__c <= 500){
                if(accountLeadMap.containsKey(eventRecord.Parent_Account__c)){
                    for(Lead relatedLeadRec:accountLeadMap.get(eventRecord.Parent_Account__c)){
                        setLeadValues(leadsToBeUpdated,relatedLeadRec.Id,LEAD_STATUS_DM_FOUND,null,null);
                    }
                }
            }else if(String.isBlank(eventRecord.Event_Outcome__c) && eventRecord.Parent_Account__c == null){
                setLeadValues(leadsToBeUpdated,leadId,LEAD_STATUS_MEETING_SET,null,System.now());
            }else if(String.isBlank(eventRecord.Event_Outcome__c) && eventRecord.Parent_Account__c != null && eventRecord.Parent_Account__r.of_leads_on_parent__c <= 500){
                setLeadValues(leadsToBeUpdated,leadId,LEAD_STATUS_MEETING_SET,null,System.now());
                accountsToBeUpdated.put(eventRecord.Parent_Account__c,new Account(Id=eventRecord.Parent_Account__c,Last_Meeting_Set__c = System.now()));
                if(accountLeadMap.containsKey(eventRecord.Parent_Account__c)){
                    for(Lead relatedLeadRec:accountLeadMap.get(eventRecord.Parent_Account__c)){
                        if(relatedLeadRec.Status != LEAD_STATUS_MEETING_RAN_NEGOTOATED){
                            setLeadValues(leadsToBeUpdated,relatedLeadRec.Id,LEAD_STATUS_MEETING_SET,null,System.now());
                        }
                    }
                }
            }
        }

        List<String> errorMessages = new List<String>();
        if(!leadsToBeUpdated.isEmpty()){
            Database.SaveResult[] leadUpdateResults = Database.update(leadsToBeUpdated.values(),false);
            CDdErrorUtilities.processSaveResults(leadUpdateResults, errorMessages);
        }
        if(!accountsToBeUpdated.isEmpty()){
            Database.SaveResult[] accountUpdateResults = Database.update(accountsToBeUpdated.values(),false);
            CDdErrorUtilities.processSaveResults(accountUpdateResults, errorMessages);
        }
        CDdErrorUtilities.createApexLogs(errorMessages, 'CDdEventPlatformEventHandler','processPreSaleEvents',LoggingLevel.ERROR);

    }

    private void setLeadValues(Map<Id,Lead> leadsToBeUpdated,Id leadId,String statusValue,DateTime lastMeetingRan, DateTime lastMeetingSet){
        Lead leadRec = new Lead(Id=leadId,Status = statusValue);
        if(lastMeetingRan != null){
            leadRec.Last_Meeting_Ran__c = lastMeetingRan;
        }
        if(lastMeetingSet != null){
            leadRec.Last_Meeting_Set__c = lastMeetingSet;
        }
        leadsToBeUpdated.put(leadId,leadRec);
    }
	
    private Map<Id,List<Lead>> getLeadsByAccount(List<Event> eventRecordList){
        Map<Id,List<Lead>> accountLeadMap = new Map<Id,List<Lead>>();
        Set<Id> accountIdSet = new Set<Id>();
        for(Event eventRecord:eventRecordList){
            if(eventRecord.Parent_Account__c != null && eventRecord.Parent_Account__r.of_leads_on_parent__c <= 500){
                accountIdSet.add(eventRecord.Parent_Account__c);
            }
        }

        for(Lead leadRec:[SELECT Id,Status,Parent_Account__c FROM Lead WHERE Converted__c = FALSE AND Parent_Account__c IN :accountIdSet]){
            if(!accountLeadMap.containsKey(leadRec.Parent_Account__c)){
                accountLeadMap.put(leadRec.Parent_Account__c,new List<Lead>());
            }

            accountLeadMap.get(leadRec.Parent_Account__c).add(leadRec);
        }

        return accountLeadMap;
    }
    
}