// ===========================================================================
// Component: CDdBatchRoutingOverflow
// Author: Nayana Kapse
// Purpose: Batch job to find the queues whoes capcity is exhausted
// ===========================================================================
public class CDdBatchRoutingOverflowV2 implements Database.Batchable<Aggregate>,Schedulable {


    /*****************************************************************************************************************************
    *
    * Public Variables & Fields
    *
    *****************************************************************************************************************************/
    public static String queueIdsToRun = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Agent_Work_QueueIds') ?
                                         CDdRoutingOverflowHelper.mapQueueMetadata.get('Agent_Work_QueueIds').Value__c : '';
    public List<Id> lstQueueIdsSpecified = String.isNotBlank(queueIdsToRun) ?
                                queueIdsToRun.split(';') : new List<Id>();
    private List<Aggregate> mockAgentList;
    private List<Aggregate> mockPresenceServiceList;

     /**
     * Default Constructor
     * @return  None
     */
    public CDdBatchRoutingOverflowV2(){
    }

    public void setMockAgentAggregateList(List<Aggregate> mockAggregateResult) {
        this.mockAgentList = mockAggregateResult;
    }

    public void setMockPendingServiceAggregateList(List<Aggregate> mockAggregateResult) {
        this.mockPresenceServiceList = mockAggregateResult;
    }

     /**
     * Overriden Constructor
     * This constructor can be called when we want to pass specific where clause
     * @return  None
     */
    public CDdBatchRoutingOverflowV2(List<Id> lstQueueIds){
        lstQueueIdsSpecified = lstQueueIds;
    }

    /*****************************************************************************************************************************
     *
     * Query Locator
     *
    ****************************************************************************************************************************/
    public Iterable<Aggregate>  start(Database.BatchableContext bc) {
        String statusVals = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Agent_Work_Status') ?
                            CDdRoutingOverflowHelper.mapQueueMetadata.get('Agent_Work_Status').Value__c : 'Assigned;Opened;';
        List<String> lstStatus = statusVals.split(';');
        String agentWorkQuery = 'SELECT OriginalQueueId qId, CreatedByID agentId, Count(Id) totalPerQueue, AVG(SpeedToAnswer) avgWaitTime'
        +' FROM AgentWork WHERE CreatedDate = today AND Status IN: lstStatus' ;
        if(!lstQueueIdsSpecified.isEmpty()) {
            agentWorkQuery = agentWorkQuery + 'OriginalQueueId IN: lstQueueIdsSpecified';
        }
        agentWorkQuery = agentWorkQuery +' GROUP BY CreatedByID,OriginalQueueId';
         //Query on UserPresence object to find out available agents
        try {
            List<Aggregate> lstActiveAgentwork = Test.isRunningTest() ? this.mockAgentList : Aggregate.convertResults(Database.Query(agentWorkQuery));
            return lstActiveAgentwork;
        }
        catch (QueryException e) {
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
    public void execute(Database.BatchableContext bc, List<Aggregate> lstAgentWork) {
        CDdRoutingOverflowHelper cRoutingHelper = new CDdRoutingOverflowHelper();
        QueueInfoWrapper  qInfo = new QueueInfoWrapper();
        UserInfoWrapper uInfo = new UserInfoWrapper();

        Map<Id,QueueInfoWrapper>  mapQueueInfoWrapper = new Map<Id,QueueInfoWrapper>();
        Map<Id,UserInfoWrapper> mapUserInfoWrapper = new Map<Id,UserInfoWrapper>();

        Id qId ;
        Id uId;
        Integer recordPerQueue;
        Decimal qWeight;
        Decimal userCapacityUsed ;
        String objectNames = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Omni_Object_Names') ?
        CDdRoutingOverflowHelper.mapQueueMetadata.get('Omni_Object_Names').Value__c : CDdSupportConstants.CASE_OBJECT_LABEL;
        Set<String> setObjectName = new Set<String>();
        setObjectName.addAll(objectNames.split(';'));
        Map<Id,Group> mapQueueIdName = CDdRoutingOverflowHelper.getOmniEnabledGroups(setObjectName);

        String queryWherClause = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Query_Filter') ?
        CDdRoutingOverflowHelper.mapQueueMetadata.get('Query_Filter').Value__c : '';

        String queryStr = CDdRoutingOverflowHelper.getUserPresence(queryWherClause);
        List<UserServicePresence> lstUserServicePresence = Database.query(queryStr);
        //Get the Active Agents Capacity
        Map<Id,Double> mapUserCapacity = cRoutingHelper.getUserCapacity(lstUserServicePresence);

        //Get the count of items per queue which need to be routed
        Map<Id,Integer> mapQueuePendingCaseCount = new Map<Id,Integer>();
        List<Aggregate> listPendingServiceRouting = Test.isRunningTest() ? this.mockPresenceServiceList : Aggregate.convertResults([SELECT count(Id) pendingCound , QueueId queueId
        FROM PendingServiceRouting WHERE IsPushed = FALSE AND QueueId IN:mapQueueInfoWrapper.keySet()
        AND IsReadyForRouting = TRUE GROUP BY QueueId]);
        for(Aggregate pServiceResult : listPendingServiceRouting){
            mapQueuePendingCaseCount.put((Id) pServiceResult.get('queueId'),(Integer) pServiceResult.get('pendingCound'));

        }

        //Get the groupId for the active agents
        Map<Id,List<Id>> mapUserIdQueueId = cRoutingHelper.getUserGroups(mapUserCapacity.keySet());
        Map<Id,QueueRoutingConfig> mapQueuConfigCapacity = new Map<Id,QueueRoutingConfig>([SELECT Id,CapacityWeight FROM QueueRoutingConfig]);

        Map<Id,Set<Id>> mapQueueAvailableAgent = new Map<Id,Set<Id>>();

        //Find out how many Agents are available on Omni for a Queue
        for(Id userId: mapUserCapacity.keySet()){
            if(mapUserIdQueueId.containsKey(userId)){
                for(Id queueId : mapUserIdQueueId.get(userId)){
                    if(!mapQueueAvailableAgent.containsKey(queueId)){
                        mapQueueAvailableAgent.put(queueId,new Set<Id>());
                    }
                    mapQueueAvailableAgent.get(queueId).add(userId);
                }
            }
        }

        for(Aggregate aResult: lstAgentWork){
            qId = (Id) aResult.get('qId');
            uId = (Id) aResult.get('agentId');
            recordPerQueue = (Integer) aResult.get('totalPerQueue');
            Id qConfigId = mapQueueIdName.get(qId).QueueRoutingConfigId;
            qWeight = mapQueuConfigCapacity.get(qConfigId).CapacityWeight;
            //Wrapper having Queue Info.
            if(qWeight!=null){
                if(!mapQueueInfoWrapper.containsKey(qId)){
                    qInfo =  new QueueInfoWrapper();
                    qInfo.queueId =  qId;
                    if(mapQueueIdName.containsKey(qInfo.queueId)){
                        qInfo.queueName = mapQueueIdName.get(qInfo.queueId).Name;
                        qInfo.queueDevName = mapQueueIdName.get(qInfo.queueId).DeveloperName;
                        qInfo.queueWeight = qWeight;
                        qInfo.agentWorkCount = recordPerQueue;
                    }

                    if(mapQueueAvailableAgent.containsKey(qId)){
                        qInfo.totalAvailableAgentIds = mapQueueAvailableAgent.get(qId);
                        qInfo.totalAvailableAgentsCount = mapQueueAvailableAgent.get(qId).size();
                    }
                    if(mapQueuePendingCaseCount.containsKey(qId)){
                        qInfo.noItemsPendingRouting = mapQueuePendingCaseCount.get(qId);
                    }
                }else{
                    qInfo.agentWorkCount =qInfo.agentWorkCount + recordPerQueue;
                    qInfo.totalWaitTime = qInfo.totalWaitTime + (Decimal) aResult.get('avgWaitTime');
                }

                mapQueueInfoWrapper.put(qInfo.queueId,qInfo);
                //Wrapprt having User Info.
                if(mapUserCapacity.containsKey(uId)){
                    if(!mapUserInfoWrapper.containsKey(uId)){
                        uInfo = new UserInfoWrapper();
                        uInfo.userId = uId;
                        uInfo.userCapcityUsed = Integer.valueOf(recordPerQueue * qWeight); //(2 *5 or 1 *5 etc)
                        uInfo.userConfiguredCapacity = Integer.valueOf(mapUserCapacity.get(uId));
                        uInfo.userPartOfqueueId = mapUserIdQueueId.get(uId);
                    }else{
                        uInfo = mapUserInfoWrapper.get(uId);
                        uInfo.userCapcityUsed =+ Integer.valueOf(recordPerQueue * qWeight);
                    }
                    uInfo.userCapacityRemaining = uInfo.userConfiguredCapacity - uInfo.userCapcityUsed;
                    mapUserInfoWrapper.put(uId,uInfo);
                }
            }
        }
        Set<Id> uIdsWithCapacityRemaining = new Set<Id>();
        Integer qUsedCapacity;
        Integer qTotalCapacity;
        Integer qCanTakeMoreWorkCount;
        for(Id queueId: mapQueueInfoWrapper.keySet()){
            qTotalCapacity = 0;
            qUsedCapacity = 0;
            qCanTakeMoreWorkCount = 0;
            qInfo = mapQueueInfoWrapper.get(queueId);
            for(Id availableAgent: qInfo.totalAvailableAgentIds){
                if(mapUserInfoWrapper.containsKey(availableAgent)){
                    uInfo = mapUserInfoWrapper.get(availableAgent);
                    if(uInfo.userCapacityRemaining >= qInfo.queueWeight){
                        qCanTakeMoreWorkCount =qCanTakeMoreWorkCount + Integer.valueOf(uInfo.userCapacityRemaining/qInfo.queueWeight);
                        uIdsWithCapacityRemaining.add(availableAgent);
                    }
                    qUsedCapacity =qUsedCapacity + uInfo.userCapcityUsed;
                    qTotalCapacity =qTotalCapacity +  uInfo.userConfiguredCapacity;
                }
            }
            //Users who still have bandwidth to take more
            qInfo.userIdsCanAcceptMoreWork = uIdsWithCapacityRemaining;
            qInfo.usersCanAcceptMoreCount = uIdsWithCapacityRemaining.size();
            //Total Queue Capacity Used
            qInfo.queueUsedCapacity = qUsedCapacity;
            //Total Queue Capacity can handle
            qInfo.queueTotalCapacity = qTotalCapacity;
            //How many more workItem a queue can handle
            qInfo.noItemsQueueCanHandleMore =  qCanTakeMoreWorkCount;
            mapQueueInfoWrapper = findOverflowQueue(mapQueueInfoWrapper);
            createQueueConfig(mapQueueInfoWrapper);
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

    /**
    * @author  Nayana
    * @date    05/2023
    * @decription  Wrapper class to hold Queue Information
    * @param   None
    * @return  None
    */
    public class QueueInfoWrapper {
        public Id queueId;
        public Set<Id> totalAvailableAgentIds= new Set<Id>();
        public Integer totalAvailableAgentsCount=0;
        public Set<Id> userIdsCanAcceptMoreWork = new Set<Id>();
        public Integer usersCanAcceptMoreCount=0;
        public String queueName;
        public String queueDevName;

        //Count of Items queue can handle. Addition of all users (UserWeight/QueueWeight)
        public Integer queueTotalWorkCount = 0 ;
        //No. of Items queue can handle * queue Weight
        public Integer queueTotalCapacity = 0 ;
        //No. of AgentworkItem * Queue Weight
        public Integer queueUsedCapacity = 0 ;
        //Count of AgentworkItem
        public Integer agentWorkCount = 0 ;
        //Count of AgentworkItem queue Can pick more
        public Integer noItemsQueueCanHandleMore = 0 ;
        //No of items in pending to route
        public Integer noItemsPendingRouting = 0;
        //Avg wait time
        public Decimal avgWaitTime = 0;
        //Total wait time
        public Decimal totalWaitTime = 0;
        public Decimal queueWeight = 0;
        public Boolean queueOverflow = false;
        public QueueInfoWrapper(){
        }
    }

    /**
    * @author  Nayana
    * @date    05/2023
    * @decription  Wrapper class to hold User Information
    * @param   None
    * @return  None
    */
    public class UserInfoWrapper {
        public Id userId;
        public List<Id> userPartOfqueueId = new List<Id>();
        public Integer userConfiguredCapacity;
        public Integer userCapcityUsed;
        public Integer userCapacityRemaining;
        public UserInfoWrapper(){
        }
    }

    /**
    * @author  Nayana
    * @date    05/2023
    * @decription  Find the overflow queue
    * @param   Map<Id,QueueInfoWrapper>
    * @return  Map<Id,QueueInfoWrapper>
    */
    public Map<Id,QueueInfoWrapper> findOverflowQueue(Map<Id,QueueInfoWrapper> mapQueueInfoWrapper){
        QueueInfoWrapper  qWrap = new QueueInfoWrapper();
        Map<Id,Queue_Overflow_Configuration__c> mapExistingQueueSetup = new Map<Id,Queue_Overflow_Configuration__c>();
        List<Queue_Overflow_Configuration__c> lstExistingData = new CDdRoutingOverflowHelper().getExisitngConfigData(mapQueueInfoWrapper.keySet());
        for(Queue_Overflow_Configuration__c qConfig : lstExistingData){
            mapExistingQueueSetup.put(qConfig.Queue_Id__c,qConfig);
        }
        Integer queueThreshold = 0 ;
        Integer avgWaitTimeThreshold = 0 ;
        Queue_Overflow_Configuration__c qMapping = new Queue_Overflow_Configuration__c();
        Boolean isQueueThreshold = false;
        Boolean isTimeThreshold = false;
        for(Id qId:mapQueueInfoWrapper.keySet()){
            qWrap = mapQueueInfoWrapper.get(qId);
            queueThreshold = 0 ;
            isQueueThreshold = false;
            isTimeThreshold = false;
            avgWaitTimeThreshold = 0;
            qWrap.avgWaitTime  = qWrap.totalAvailableAgentsCount!=0 ? qWrap.totalWaitTime/qWrap.totalAvailableAgentsCount : 99999;
            if(mapExistingQueueSetup.containsKey(qId)){
                qMapping = mapExistingQueueSetup.get(qId);
                queueThreshold = qMapping.Threshold_over_capacity__c!=null ?
                                Integer.valueOf(qMapping.Threshold_over_capacity__c): 0;
                avgWaitTimeThreshold = qMapping.Threshold_Avg_Wait_Time__c!=null ?
                                Integer.valueOf(qMapping.Threshold_Avg_Wait_Time__c): 0;
                if(qMapping.Threshold_Type__c == 'Queue Based'){
                    isQueueThreshold = true;
                }else{
                    isTimeThreshold = true;
                }
            }else{
                isQueueThreshold = true;
            }
            //if capacity needed >= total queue capcity + threshold then it's a overflow
            if(isQueueThreshold && (qWrap.noItemsPendingRouting >= qWrap.noItemsQueueCanHandleMore + queueThreshold)) {
                qWrap.queueOverflow = true;
            }
            else if(isTimeThreshold && (qWrap.avgWaitTime >=avgWaitTimeThreshold)){
                qWrap.queueOverflow = true;
            }
        }
        return mapQueueInfoWrapper;
    }

    /**
    * @author  Nayana
    * @date    05/2023
    * @decription  Upsert the Queue Overflow config record
    * @param   Map<Id,QueueInfoWrapper>
    * @return  none
    */
    public void createQueueConfig(Map<Id,QueueInfoWrapper> mapQueueInfoWrapper){
        List<Queue_Overflow_Configuration__c> lstOverflowConfigsToUpsert = new List<Queue_Overflow_Configuration__c>();
        Queue_Overflow_Configuration__c qConfig = new Queue_Overflow_Configuration__c();
        QueueInfoWrapper qWrap = new QueueInfoWrapper();
        List<Queue_Overflow_Configuration__c> lstQueueDataToUpdate = new List<Queue_Overflow_Configuration__c>();
        //This is to reset the Is_Queue_At_Capacity__c.
        for(Queue_Overflow_Configuration__c qOverflow :new CDdRoutingOverflowHelper().getExisitngConfigData(new Set<Id>())){
            if(qOverflow.Is_Queue_At_Capacity__c){
                qOverflow.Is_Queue_At_Capacity__c = false;
                lstQueueDataToUpdate.add(qOverflow);
            }
        }

        if(!lstQueueDataToUpdate.isEmpty()){
            List<Database.SaveResult> lstUpdateRecs = Database.update(lstQueueDataToUpdate,false);
            List<String> errorMessages = CDdErrorUtilities.processSaveResults(lstUpdateRecs, new List<String>());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdRoutingOverflowHelper', 'UpdateConfigRecs', LoggingLevel.ERROR);
        }
        //This is to update the records with current information.
        for(Id qId: mapQueueInfoWrapper.keySet()){
            qWrap = mapQueueInfoWrapper.get(qId);
            qConfig = new Queue_Overflow_Configuration__c();
            qConfig.Queue_Id__c = qId;
            qConfig.Queue_Developer_Name__c = qWrap.queueDevName;
            qConfig.Queue_Capacity_Total__c = qWrap.queueTotalCapacity;
            qConfig.Occupied_Queue_Capacity__c = qWrap.queueUsedCapacity;
            qConfig.Agent_Work_Count__c = qWrap.agentWorkCount;
            qConfig.Max_Queue_Work_Item_Count__c = qWrap.agentWorkCount +  qWrap.noItemsQueueCanHandleMore;
            qConfig.Queue_Weight__c = qWrap.queueWeight;
 			qConfig.Average_Wait_Time__c = qWrap.avgWaitTime;
            qConfig.Is_Queue_At_Capacity__c = qWrap.queueOverflow;
            lstOverflowConfigsToUpsert.add(qConfig);
        }
        if(!lstOverflowConfigsToUpsert.isEmpty()){
            Schema.SObjectField qIdExtKey = Queue_Overflow_Configuration__c.Fields.Queue_Id__c;
            List<Database.UpsertResult> resList = Database.Upsert(lstOverflowConfigsToUpsert,qIdExtKey,false);
            List<String> errorMessages = CDdErrorUtilities.processUpsertResults(resList, new List< String>());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdRoutingOverflowHelper', 'UpsertQueueConfig', LoggingLevel.ERROR);
            new CDdRoutingOverflowHelper().refreshOverflowCache(mapQueueInfoWrapper.keySet());
        }
    }
}