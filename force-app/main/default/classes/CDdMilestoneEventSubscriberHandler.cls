/********************************************************************************************************************
* @author Sriram
* @date 08/09/2021
*
* @group Trigger Handler
*
* @description This trigger handler is invoked by TDdMilestoneEventSubscriberTrigger 
*              TDdMilestoneEventSubscriberTrigger is a subscriber to the 'Milestone Event' platform event
* 
**************************************************************************************************************************************/
public class CDdMilestoneEventSubscriberHandler {
    private static final String OPERATION_INSERT = 'INSERT';
    private static final String OPERATION_UPDATE = 'UPDATE';
    private static final String MILESTONE_EVENT_FIELD_USER_ID = 'User_Id__c';
    private static final String MILESTONE_EVENT_FIELD_PARENT_SOBJECT_TYPE = 'Parent_SObject_Type__c';
    private static final String MILESTONE_EVENT_FIELD_PARENT_SOBJECT_ID = 'Parent_SObject_Id__c';
    /**
    * @description Apex Class Entry point for Milestone Event Subscriber Trigger
     * @param List<Milestone_Event__e> newList
     * @return    
    */
    public void afterInsert(List<Milestone_Event__e> newList) {
        List<Milestone_Event__e> insertMilestoneEvents = getMilestoneEventsForOperation(OPERATION_INSERT, newList);
        if (!insertMilestoneEvents.isEmpty()){
            insertMilestones(insertMilestoneEvents);
        }
        // Perform Update Deliver Tablet Milestone Operation
        List<Milestone_Event__e> updateDeliverTabletMilestoneEvents = getMilestoneEventsForOperation(CDdMxSxConstants.MILESTONE_EVENT_OPERATION_UPDATE_DELIVER_TABLET, newList);
        if (!updateDeliverTabletMilestoneEvents.isEmpty()){
            Boolean success = CDdCaseMilestone.handleUpdateDeliverTabletMilestoneEvents(updateDeliverTabletMilestoneEvents);
            if (success){
                setMilestoneEventResumeCheckpoint(updateDeliverTabletMilestoneEvents);
            }
        }
    }
    /**
     * @description Return a collection of milestone events for input operation
     * @param String operation 
     * @param List<Milestone_Event__e> newList
     * @return List<Milestone_Event__e> a Collection of Milestone Events
     */      
    public List<Milestone_Event__e> getMilestoneEventsForOperation(String operation, List<Milestone_Event__e> newList){
        List<Milestone_Event__e> eventsByOperation = new List<Milestone_Event__e>();
        for (Milestone_Event__e event : newList){
            if (operation.equalsIgnoreCase(event.Operation__c)){
                eventsByOperation.add(event);
            }
        }
        return eventsByOperation;
    }
    /**
     * @description Insert the milestones for published insert milestone events 
     * @param List<Milestone_Event__e> insertMilestoneEvents
     * @return 
     */          
    public void insertMilestones(List<Milestone_Event__e> insertMilestoneEvents){
        Map<String, Map<String, List<Milestone_Event__e>>> milestoneEventsByUserIdAndParentSObjectType 
                                        = getMilestoneEventsByUserIdAndParentSObjectType(insertMilestoneEvents);
        for (String userId : milestoneEventsByUserIdAndParentSObjectType.keySet()){
            Map<String, List<Milestone_Event__e>> milestoneEventsByParentSObjectType = milestoneEventsByUserIdAndParentSObjectType.get(userId);
            for (String parentSObjectType : milestoneEventsByParentSObjectType.keySet()){
                Set<Id> parentSObjectIds = new Set<Id>();
                for (Milestone_Event__e milestoneEvent : milestoneEventsByParentSObjectType.get(parentSObjectType)){
                    parentSObjectIds.add((Id)milestoneEvent.get(MILESTONE_EVENT_FIELD_PARENT_SOBJECT_ID));
                }
                CDdMilestoneGeneratorSetting.generateMilestones(userId, parentSObjectType, parentSObjectIds);
                setMilestoneEventResumeCheckpoint(milestoneEventsByParentSObjectType.get(parentSObjectType));
            }
        }        
    }
    /**
     * @description Set the Replay ID of the last successfully processed Milestone Event message. 
     * @param List<Milestone_Event__e> milestoneEvents
     * @return
     */       
    public void setMilestoneEventResumeCheckpoint(List<Milestone_Event__e> milestoneEvents){
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(milestoneEvents[milestoneEvents.size()-1].ReplayId);
    }
    /**
     * @description Return the milestone events 
     * - where outer collection is grouped by User_Id__c 
     * - and the inner collection is grouped by Parent_SObject_Type__c
     * @param List<Milestone_Event__e> milestoneEvents
     * @return Map<String, Map<String, List<Milestone_Event__e>>> Return a Collection grouped by User Id and Parent SObject Type
     */     
    public Map<String, Map<String, List<Milestone_Event__e>>> getMilestoneEventsByUserIdAndParentSObjectType(List<Milestone_Event__e> milestoneEvents){
        Map<String, Map<String, List<Milestone_Event__e>>> eventsByUserAndParentSObjectType = new Map<String, Map<String, List<Milestone_Event__e>>>();
        Map<String, List<Milestone_Event__e>> milestoneEventsByUserId = groupMilestoneEventsByMilestoneProperty(MILESTONE_EVENT_FIELD_USER_ID, milestoneEvents);
        for (String userId : milestoneEventsByUserId.keySet()){
            eventsByUserAndParentSObjectType.put(   userId, 
                                                    groupMilestoneEventsByMilestoneProperty(
                                                        MILESTONE_EVENT_FIELD_PARENT_SOBJECT_TYPE, 
                                                        milestoneEventsByUserId.get(userId)
                                                    )
                                                );
        }
        return eventsByUserAndParentSObjectType;
    }
    /**
     * @description Group the Milestone Events by the Milestone Event property - Example: User_Id__c, Parent_SObject_Type__c
     * @param String milestoneEventProperty
     * @param List<Milestone_Event__e> milestoneEvents
     * @return Map<String, Set<Id>> Return a Collection of Milestone Events grouped by input milestoneEventProperty
     */    
    public Map<String, List<Milestone_Event__e>> groupMilestoneEventsByMilestoneProperty(String milestoneEventProperty, List<Milestone_Event__e> milestoneEvents){
        Map<String, List<Milestone_Event__e>> milestoneEventsByMilestoneProperty = new Map<String, List<Milestone_Event__e>>();
        for (Milestone_Event__e event : milestoneEvents){
            String value = (String)event.get(milestoneEventProperty);            
            if (milestoneEventsByMilestoneProperty.containsKey(value)){
                milestoneEventsByMilestoneProperty.get(value).add(event);
            } else {
                milestoneEventsByMilestoneProperty.put(value, new List<Milestone_Event__e>{event});
            }
        }
        return milestoneEventsByMilestoneProperty;
    }
}