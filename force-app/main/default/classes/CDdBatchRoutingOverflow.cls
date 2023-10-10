// ===========================================================================
// Component: CDdBatchRoutingOverflow
// Author: Nayana Kapse
// Purpose: Batch job to find the queues whoes capcity is exhausted
// ===========================================================================
public with sharing class CDdBatchRoutingOverflow implements Database.Batchable<AggregateResult>,Schedulable {
    
  
    /*****************************************************************************************************************************
    *
    * Public Variables & Fields
    *
    *****************************************************************************************************************************/
    public static String queueIdsToRun = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Agent_Work_QueueIds') ? 
                                         CDdRoutingOverflowHelper.mapQueueMetadata.get('Agent_Work_QueueIds').Value__c : '';
    public List<Id> lstQueueIdsSpecified = String.isNotBlank(queueIdsToRun) ? 
                                queueIdsToRun.split(';') : new List<Id>();
     /**
     * Default Constructor
     * @return  None
     */
     public CDdBatchRoutingOverflow(){
     }
     
     /**
     * Overriden Constructor
     * This constructor can be called when we want to pass specific where clause
     * @return  None
     */
     public CDdBatchRoutingOverflow(List<Id> lstQueueIds){
        lstQueueIdsSpecified = lstQueueIds;
     }
 
     /*****************************************************************************************************************************
     *
     * Query Locator
     *
     ****************************************************************************************************************************/
     public Iterable<AggregateResult>  start(Database.BatchableContext bc) {
        String statusVals = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Agent_Work_Status') ? 
                            CDdRoutingOverflowHelper.mapQueueMetadata.get('Agent_Work_Status').Value__c : 'Assigned;Opened;';
        List<String> lstStatus = statusVals.split(';');
        String agentWorkQuery = 'SELECT AVG(CapacityWeight) queueCapacity ,Count(Id) numberOfPendingChats, AVG(SpeedToAnswer) avgWaitTime,OriginalQueueId' 
        +' FROM AgentWork WHERE CreatedDate = today AND Status IN: lstStatus' ;
        if(!lstQueueIdsSpecified.isEmpty()) {
            agentWorkQuery = agentWorkQuery + 'OriginalQueueId IN: lstQueueIdsSpecified';
        }
        agentWorkQuery = agentWorkQuery +' GROUP BY OriginalQueueId';
         //Query on UserPresence object to find out available agents
        if(Test.isRunningTest()){
            agentWorkQuery = agentWorkQuery + ' LIMIT 5';
        }
         try {
             List<AggregateResult> lstActiveAgentwork = Database.Query(agentWorkQuery);
             return lstActiveAgentwork;
         } catch (QueryException e) {
             //Catch QueryException any
             CDdErrorUtilities.publishException('CDdBatchRoutingOverflow', 'Start', e);
             return null;
         }
     }
 
     /*****************************************************************************************************************************
     *
     * Execute
     *
     ****************************************************************************************************************************/
     public void execute(Database.BatchableContext bc, List<AggregateResult> lstAgentWork) {
        Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper>  mapQueueInfoWrapper = new Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper>();
        CDdRoutingOverflowHelper cRoutingHelper = new CDdRoutingOverflowHelper();
       
        mapQueueInfoWrapper = cRoutingHelper.getQueueUsedCapacity(lstAgentWork);
        try{
            String queryWherClause = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Query_Filter') ? 
                                    CDdRoutingOverflowHelper.mapQueueMetadata.get('Query_Filter').Value__c : '';
            //Query on UserPresence object to find out available agents
            String queryStr = CDdRoutingOverflowHelper.getUserPresence(queryWherClause);
            List<UserServicePresence> lstUserServicePresence = Database.query(queryStr);

            //Get the Active Agents 
            Map<Id,Double> mapUserCapacity = cRoutingHelper.getUserCapacity(lstUserServicePresence);
            
            if(!mapUserCapacity.isEmpty()){
               //Get the groupId for the active agents
               Map<Id,List<Id>> mapUserIdQueueId = cRoutingHelper.getUserGroups(mapUserCapacity.keySet());

               //Get the available users per queue
               mapQueueInfoWrapper = cRoutingHelper.getQueueAvailableAgents(mapQueueInfoWrapper,mapUserCapacity.keySet(),mapUserIdQueueId);

               //Get the total Queue Capacity
               mapQueueInfoWrapper = cRoutingHelper.getQueueTotalCapacity(mapQueueInfoWrapper,mapUserCapacity);

               //Find Overflow Queues
               mapQueueInfoWrapper = cRoutingHelper.findOverflowQueue(mapQueueInfoWrapper);
               cRoutingHelper.createQueueConfig(mapQueueInfoWrapper);
            }
        }catch(Exception e){
           CDdErrorUtilities.publishException('CDdBatchRoutingOverflow', 'execute', e);
        }           
     }
 
     /*****************************************************************************************************************************
     *
     * Finish
     *
     ****************************************************************************************************************************/
     public void finish(Database.BatchableContext bc) {
         // Nothing to do...
         // Send an Email???
     }
     
     /*****************************************************************************************************************************
     *
     * Schedular Execute
     *
     ****************************************************************************************************************************/
     public void execute(SchedulableContext sc) {
         CDdBatchRoutingOverflow batch = new CDdBatchRoutingOverflow();
         Database.executeBatch(batch, 100);
     }
 }