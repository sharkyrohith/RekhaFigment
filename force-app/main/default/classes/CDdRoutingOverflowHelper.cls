/**
 * CDdRoutingOverflowHelper
 *
 * @author  Nayana Kapse
 * @date  09/08/2021
 * @decription This is used for Routing overflow logic
 */

public with sharing class CDdRoutingOverflowHelper {

    /*****************************************************************************************************************************
    *
    * Private Variables
    *
    *****************************************************************************************************************************/
    private static final String QUEUE_CONFIG_CACHE_KEY = 'local.DoorDash.QueueOverflow';
    /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/
    //Get the Queue Ids which we need to exclude from the metadta
    public static String queueIdExclude= mapQueueMetadata.containsKey('Excluded_Queues') ?
                                         mapQueueMetadata.get('Excluded_Queues').Value__c : '';
    public static List<Id> lstQueueIdExclude = String.isNotBlank(queueIdExclude) ?
                                         queueIdExclude.split(';') : new List<Id>();
    //support feature flag - Disable Apex Logging default == false
    public static Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getInstance();

    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Get the custom metadata values
    * @param    None
    * @return  Map<String,Queue_Overflow_Metadata__mdt> Map of developer Name vs Queue Overflow metadata
    */
    public static Map<String,Queue_Overflow_Metadata__mdt> mapQueueMetadata{
        get{
            if(mapQueueMetadata==null){
                mapQueueMetadata = new Map<String,Queue_Overflow_Metadata__mdt>();
                for(Queue_Overflow_Metadata__mdt qMdt: Queue_Overflow_Metadata__mdt.getAll().values()){
                    mapQueueMetadata.put(qMdt.DeveloperName,qMdt);
                }
            }
            return mapQueueMetadata;
        }
        set;

    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Get the Agents who are online
    * @param    filterStr
    * @return  String Query String
    */
    public static String getUserPresence(String filterStr){
        String userPresenceQuery = 'SELECT configuredCapacity,AtCapacityDuration,AverageCapacity,Id,Name,'
                                + ' User_Role__c,UserId FROM UserServicePresence';
        if(String.isNotBlank(filterStr)){
            userPresenceQuery = userPresenceQuery + ' WHERE ' + filterStr;
        }
        return userPresenceQuery;
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Get the Agents who are online
    * @param    filterStr
    * @return  String Query String
    */
    public Map<Id,Double> getUserCapacity(List<UserServicePresence> lstUserServicePresence){
        Map<Id,Double> mapUserCapacity = new Map<Id,Double>();
        for(UserServicePresence uPresence : lstUserServicePresence){
            mapUserCapacity.put(uPresence.userId,Double.valueOf(uPresence.configuredCapacity));
        }
        return mapUserCapacity;
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Get the Queues which are enabled for Omni
    * @param    setObjectName : Object names for which need to find Queues
    * @return  Map<Id,Group> : Map of Queue Id vs Queue
    */
    public static Map<Id,Group> getOmniEnabledGroups(Set<String> setObjectName){
        Map<Id,Group> mapQueueIdName = new Map<Id,Group>();
        for(Group grp : [SELECT DeveloperName, Id, Name, QueueRoutingConfigId FROM Group
                        WHERE QueueRoutingConfigId != null AND type =: CDdCoreConstants.QUEUE_TYPE
                        AND Id IN (SELECT QueueId FROM QueueSobject WHERE SobjectType IN :setObjectName)]){
            mapQueueIdName.put(grp.Id,grp);
        }
        return mapQueueIdName;
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Get the Queue information for given userIds
    * @param    setUserIds : User ids for which need to find which queues they are part of
    * @return  Map<Id,Group> : Map of Queue Id vs Queue
    */
    public Map<Id,List<Id>> getUserGroups(Set<Id> setUserIds){
        Map<Id,List<Id>> mapUserIdQueueId = new Map<Id,List<Id>>();
        for(GroupMember  gMember : [SELECT GroupId, Id, SystemModstamp, UserOrGroupId
                                    FROM GroupMember WHERE UserOrGroupId IN: setUserIds]){
            if(!lstQueueIdExclude.isEmpty() && lstQueueIdExclude.contains(gMember.GroupId)) {
                continue;
            }
            if(!mapUserIdQueueId.containsKey(gMember.UserOrGroupId)){
                mapUserIdQueueId.put(gMember.UserOrGroupId,new List<Id>());
            }
            mapUserIdQueueId.get(gMember.UserOrGroupId).add(gMember.GroupId);
        }
        return mapUserIdQueueId;
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Prepare Queue Wrapper to populate Available Agents info
    * @param    mapQueueInfoWrapper:  Map of Queue Id vs Queuewrapper
    *           setUserIds : User ids
    *           mapUserIdQueueId : map of QueueId vs List of userIds
    * @return  Map<Id,QueueInfoWrapper>: Map of Queue Id vs Queuewrapper
    */
    public Map<Id,QueueInfoWrapper> getQueueAvailableAgents(Map<Id,QueueInfoWrapper> mapQueueInfoWrapper,Set<Id> setUserIds,Map<Id,List<Id>> mapUserIdQueueId){
        QueueInfoWrapper  qInfo = new QueueInfoWrapper();
        Map<Id,Set<Id>> mapQueueAvailableAgent = new Map<Id,Set<Id>>();

        for(Id uId: setUserIds){
            if(mapUserIdQueueId.containsKey(uId)){
                for(Id qId : mapUserIdQueueId.get(uId)){
                    if(mapQueueInfoWrapper.containsKey(qId)){
                        if(!mapQueueAvailableAgent.containsKey(qId)){
                            mapQueueAvailableAgent.put(qId,new Set<Id>());
                        }
                        mapQueueAvailableAgent.get(qId).add(uId);
                    }
               }
            }
        }

        for(Id qId: mapQueueAvailableAgent.keySet()){
            qInfo = mapQueueInfoWrapper.get(qId);
            qInfo.queueActiveUserId = mapQueueAvailableAgent.get(qId);
            qInfo.queueAvailableAgentsCount = mapQueueAvailableAgent.get(qId).size();
        }
        return mapQueueInfoWrapper;
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Get the Queue Total Capacity
    * @param   mapQueueInfoWrapper : Map of Queue Id vs Queuewrapper
    *          mapUserCapacity : Map of User Id vs User capcity
    * @return   Map<Id,QueueInfoWrapper> : Map of Queue Id vs Queuewrapper
    */
    public Map<Id,QueueInfoWrapper> getQueueTotalCapacity(Map<Id,QueueInfoWrapper> mapQueueInfoWrapper,Map<Id,Double> mapUserCapacity){
        Integer totalWorkItem = 0;
        QueueInfoWrapper  qInfo = new QueueInfoWrapper();
        Integer queueWeight;
        Integer userCapacity;
        for(Id qId : mapQueueInfoWrapper.keySet()){
            qInfo = mapQueueInfoWrapper.get(qId);
            queueWeight = Integer.valueOf(qInfo.queueWeight);
            for(Id uId: qInfo.queueActiveUserId){
                if(mapUserCapacity.containsKey(uId)){
                    userCapacity = Integer.valueOf(mapUserCapacity.get(uId));
                    if(queueWeight!=0){
                        totalWorkItem = totalWorkItem + (userCapacity/queueWeight);
                    }
                }
            }
            qInfo.queueTotalCapacity = totalWorkItem*queueWeight;
            qInfo.queueTotalWorkCount = totalWorkItem;
            totalWorkItem = 0;
        }
        return mapQueueInfoWrapper;
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Get the Queue Used Capacity
    * @param   lstAgentWorkResult :List of aggregate result
    * @return   Map<Id,QueueInfoWrapper> : Map of Queue Id vs Queuewrapper
    */

    public Map<Id,QueueInfoWrapper> getQueueUsedCapacity(List<AggregateResult> lstAgentWorkResult){
        Map<Id,QueueInfoWrapper> mapQueueInfoWrapper = new Map<Id,QueueInfoWrapper> ();
        QueueInfoWrapper  qInfo = new QueueInfoWrapper();
        String objectNames = mapQueueMetadata.containsKey('Omni_Object_Names') ?
        mapQueueMetadata.get('Omni_Object_Names').Value__c : CDdSupportConstants.CASE_OBJECT_LABEL;
        Set<String> setObjectName = new Set<String>();
        setObjectName.addAll(objectNames.split(';'));
        Map<Id,Group> mapQueueIdName = getOmniEnabledGroups(setObjectName);
        Id qId;
        List<String> queueIdforApexLog = new List<String>();

        for(AggregateResult aResult: lstAgentWorkResult){
            qInfo = new CDdRoutingOverflowHelper.QueueInfoWrapper();
            qId = (Id) aResult.get('OriginalQueueId');
            if(!lstQueueIdExclude.isEmpty() && lstQueueIdExclude.contains(qId)) {
                continue;
            }
            //BIZS-2663 : Null pointer check for queue capacity & number of pernding chats
            if(aResult.get('queueCapacity') == null || aResult.get('numberOfPendingChats') == null){
                String str = '';
                if(aResult.get('queueCapacity') == null){
                    str += qId + ' has ' + 'queueCapacity set as null \n';
                }
                if(aResult.get('numberOfPendingChats') == null){
                    str += qId + ' has ' + 'numberOfPendingChats set as null \n';
                }
                if(featureFlag.Disable_Apex_Log_CDdBatchRoutingOverflow__c && !queueIdforApexLog.contains(str)){
                    queueIdforApexLog.add(str);
                }
                continue;
            }
            //Map of Queue Id and required Capacity
            qInfo.queueId =  qId;
            qInfo.queueUsedCapacity =  Integer.valueOf((Decimal) aResult.get('queueCapacity') * (Integer) aResult.get('numberOfPendingChats'));
            qInfo.agentWorkCount = (Integer) aResult.get('numberOfPendingChats');
            qInfo.queueWeight = (Decimal) aResult.get('queueCapacity');
            qInfo.avgWaitTime = (Decimal) aResult.get('avgWaitTime');
            qInfo.queueActiveUserId = new Set<Id>();
            if(mapQueueIdName.containsKey(qInfo.queueId)){
                qInfo.queueName = mapQueueIdName.get(qInfo.queueId).Name;
                qInfo.queueDevName = mapQueueIdName.get(qInfo.queueId).DeveloperName;
            }
            mapQueueInfoWrapper.put(qInfo.queueId,qInfo);
        }
        if(!queueIdforApexLog.isEmpty()){
            CDdErrorUtilities.createApexLogs(queueIdforApexLog,'CDdRoutingOverflowHelper','getQueueUsedCapacity',LoggingLevel.ERROR);
        }
        return mapQueueInfoWrapper;
    }


    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Find the overflow queue.(Total Capacity < Used Capacity)
    * @param   mapQueueInfoWrapper : Map of Queue Id vs Queuewrapper
    * @return   Map<Id,QueueInfoWrapper> : Map of Queue Id vs Queuewrapper
    */
    public Map<Id,QueueInfoWrapper> findOverflowQueue(Map<Id,QueueInfoWrapper> mapQueueInfoWrapper){
        QueueInfoWrapper  qWrap = new QueueInfoWrapper();
        Map<Id,Queue_Overflow_Configuration__c> mapExistingQueueSetup = new Map<Id,Queue_Overflow_Configuration__c>();
        List<Queue_Overflow_Configuration__c> lstExistingData = getExisitngConfigData(mapQueueInfoWrapper.keySet());
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
            if(isQueueThreshold && (qWrap.agentWorkCount >= qWrap.queueTotalWorkCount + queueThreshold)) {
                qWrap.queueOverflow = true;
            }
            else if(isTimeThreshold && (qWrap.avgWaitTime >=avgWaitTimeThreshold)){
                qWrap.queueOverflow = true;
            }

            System.debug('<--QId==>'+qWrap.queueId+'<--QName==>'+qWrap.queueName+'<--QDName==>'
            +qWrap.queueDevName+'<---Qweight==>'+qWrap.queueWeight+'<---AvailableAgents==>'+qWrap.queueAvailableAgentsCount
            +'<---MaxQCapacity==>'+qWrap.queueTotalWorkCount+'<---UsedQCapacity==>'+qWrap.agentWorkCount+
            '<---Threshold-==>'+(queueThreshold*qWrap.queueWeight)+'<--Isoverflow==>'+qWrap.queueOverflow);
        }
        return mapQueueInfoWrapper;
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Create the Queue Overflow Config records
    * @param   mapQueueInfoWrapper : Map of Queue Id vs Queuewrapper
    * @return   None
    */
    public void createQueueConfig(Map<Id,QueueInfoWrapper> mapQueueInfoWrapper){
        List<Queue_Overflow_Configuration__c> lstOverflowConfigsToUpsert = new List<Queue_Overflow_Configuration__c>();
        Queue_Overflow_Configuration__c qConfig = new Queue_Overflow_Configuration__c();
        QueueInfoWrapper qWrap = new QueueInfoWrapper();
        List<Queue_Overflow_Configuration__c> lstQueueDataToUpdate = new List<Queue_Overflow_Configuration__c>();
        //This is to reset the Is_Queue_At_Capacity__c.
        for(Queue_Overflow_Configuration__c qOverflow :getExisitngConfigData(new Set<Id>())){
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
            qConfig.Max_Queue_Work_Item_Count__c = qWrap.queueTotalWorkCount;
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
            refreshOverflowCache(mapQueueInfoWrapper.keySet());
        }

    }

     /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Refresh the overflowCache
    * @param   setQueueIds : set of queue Ids
    * @return   None
    */
    public void refreshOverflowCache(Set<Id> setQueueIds){
        List<Queue_Overflow_Configuration__c> lstQueueData = getExisitngConfigData(setQueueIds);
        builOverflowCache(lstQueueData);
    }

     /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Create the Queue Overflow Config cache
    * @param   mapQueueInfoWrapper : Map of Queue Id vs Queuewrapper
    * @return   None
    */
    @TestVisible private static Map<Id,QueueCacheWrapper> builOverflowCache(List<Queue_Overflow_Configuration__c> lstExistingData){
        Map<Id,QueueCacheWrapper> mapQueueCache = new Map<Id,QueueCacheWrapper>();
        for(Queue_Overflow_Configuration__c qConfig:lstExistingData){
            //Create cache only if the config is active and queue is at capacity
            if(qConfig.Is_Active__c && qConfig.Is_Queue_At_Capacity__c && String.isNotBlank(qConfig.Overflow_Queue_Id__c)){
                QueueCacheWrapper  qCache = new QueueCacheWrapper();
                qCache.isQueueOverflow = true;
                qCache.overflowQueueId = qConfig.Overflow_Queue_Id__c;
                mapQueueCache.put(qConfig.Queue_Id__c,qCache);
            }
        }
        if(!mapQueueCache.isEmpty()){
            CDdCacheService.putInOrgCache(QUEUE_CONFIG_CACHE_KEY, mapQueueCache,300);
        }
        return mapQueueCache;
    }

     /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Check if Queue Cache present if not create one
    * @param   Map<Id,QueueCacheWrapper> : Map of Queue Id vs Queuewrapper
    * @return   None
    */
    public static Map<Id,QueueCacheWrapper> getQueueCacheData(){
        Map<Id,QueueCacheWrapper> mapQueueCache = new Map<Id,QueueCacheWrapper>();
        Object cachedData = CDdCacheService.getFromOrgCache(QUEUE_CONFIG_CACHE_KEY);
        if (cachedData == null) {
            List<Queue_Overflow_Configuration__c> lstQueueData = new CDdRoutingOverflowHelper().getExisitngConfigData(new Set<Id>());
            mapQueueCache = builOverflowCache(lstQueueData);
        }else{
            mapQueueCache = (Map<Id,CDdRoutingOverflowHelper.QueueCacheWrapper>) cachedData;
        }
        return mapQueueCache;
    }
     /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Create the Queue Overflow Config records
    * @param   setQueueIds : Set of QueuIds to get the data for
    * @return   List<Queue_Overflow_Configuration__c> : List of Overflow Config Data
    */
    public List<Queue_Overflow_Configuration__c> getExisitngConfigData(Set<Id>setQueueIds){
        String userPresenceQuery = 'SELECT Id,Queue_Id__c,Is_Active__c,Overflow_Queue_Id__c,Threshold_Avg_Wait_Time__c,'
                                + ' Overflow_Queue_Developer_Name__c,Threshold_over_capacity__c,Is_Queue_At_Capacity__c,Threshold_Type__c'
                                + ' FROM Queue_Overflow_Configuration__c';
        if(!setQueueIds.isEmpty()){
            userPresenceQuery += ' WHERE Queue_Id__c IN : setQueueIds';
        }
        return Database.query(userPresenceQuery);
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Wrapper class to hold Queue Information
    * @param   None
    * @return  None
    */
    public class QueueInfoWrapper {
        public Id queueId;
        public Set<Id> queueActiveUserId;
        public String queueName;
        public String queueDevName;
        public Integer queueAvailableAgentsCount=0;
        //Count of Items queue can handle. Addition of all users (UserWeight/QueueWeight)
        public Integer queueTotalWorkCount = 0 ;
        //No. of Items queue can handle * queue Weight
        public Integer queueTotalCapacity = 0 ;
        //No. of AgentworkItem * Queue Weight
        public Integer queueUsedCapacity = 0 ;
        //Count of AgentworkItem
        public Integer agentWorkCount = 0 ;
        //Avg wait time
        public Decimal avgWaitTime = 0;
        public Decimal queueWeight = 0;
        public Boolean queueOverflow = false;
        public QueueInfoWrapper(){
        }
    }

    /**
    * @author  Nayana
    * @date    09/2021
    * @decription  Wrapper class to hold Queue Information
    * @param   None
    * @return  None
    */
    public class QueueCacheWrapper {
        public Id overflowQueueId;
        public Boolean isQueueOverflow =false;
    }
}