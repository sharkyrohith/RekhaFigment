public class CDdBatchQueueMapping implements Database.Batchable<sObject>,Schedulable{
    /*****************************************************************************************************************************
    *
    * Public Variables & Fields
    *
    *****************************************************************************************************************************/
    public String recordStatus;
    public Boolean overrideStatus = false;
    public final static Set<String> queueObj = new Set<String>{'Case','LiveChatTranscript'};
    public final static String OMNI_QUEUE_TYPE = 'Omni';
    public final static String PHONE_QUEUE_TYPE = 'Phone';
    public final static String NEW_STATUS = 'New';
    public final static String CHAT_ORIGIN = 'Chat';
    public final static String WEB_ORIGIN = 'Web';
    public final static String API_ORIGIN = 'API';
    public final static String SOCIAL_ORIGIN = 'Social';
    public final static Map<String,String> mapQueueOrigin =
    new Map<String,String>{CHAT_ORIGIN=>CHAT_ORIGIN,WEB_ORIGIN=>WEB_ORIGIN,API_ORIGIN=>API_ORIGIN,SOCIAL_ORIGIN=>SOCIAL_ORIGIN};
    private static Map<String,Queue_Mapping__c> mapExistingData = new Map<String,Queue_Mapping__c>();
    private static List<Support_Assignment_Mapping__c> listOfSAM = Support_Assignment_Mapping__c.getAll().values();
    private static Set<Id> setVendorSplitQueues = new Set<Id>();
    /*****************************************************************************************************************************
    * Default Constructor
    * @return  None
    ******************************************************************************************************************************/
    public CDdBatchQueueMapping() {
        overrideStatus = false;
         //Get the existing Queue Mapping Data.
         for(Queue_Mapping__c qMap:[SELECT Id,Queue_Id__c,Queue_Name__c,Queue_Developer_Name__c FROM Queue_Mapping__c]){
            mapExistingData.put(qMap.Queue_Id__c,qMap);
        }
        /*This is used to determine Vendor Split.
        If a queue is present in Support Assignment Mapping where preferred vendor is added
        then it's part of vendor split.*/
        //This for loop wil give LiveChat Ids
        for (Support_Assignment_Mapping__c sam : listOfSAM){
            if(String.IsNotBlank(sam.Preferred_Vendor__c)){
                setVendorSplitQueues.add(sam.Queue_Id__c);
            }
        }
        //This will give case Ids
        CDdGenericTriggerOptimizationHelper.setQueueMap(CDdSupportHelper.lstCaseVendorQueueDevName);
        setVendorSplitQueues.addAll(CDdGenericTriggerOptimizationHelper.getQueueDevNameToIdMap().values());

    }
    /*****************************************************************************************************************************
    * Overriden Constructor
    * This constructor can be called when we want to pass specific Status value.
    * For first load we can assign Status ='Ready for ETL' and run
    * @return  None
    ******************************************************************************************************************************/
    public CDdBatchQueueMapping(String status){
        this();
        recordStatus = status;
        overrideStatus = true;
    }

    /*****************************************************************************************************************************
    *
    * Start
    *
    ****************************************************************************************************************************/
	public Database.QueryLocator start(Database.BatchableContext BC) {
        String queryStr = 'SELECT Id,Name,DeveloperName,QueueRoutingConfigId,' +
                          ' (SELECT SobjectType FROM QueueSobjects)' +
            	 		  ' FROM Group WHERE Type = \'Queue\'';
        return Database.getQueryLocator(queryStr + (Test.isRunningTest() ? ' LIMIT 50' : CDdCoreConstants.BLANK_STRING));
    }

    /*****************************************************************************************************************************
    *
    * Execute
    *
    ****************************************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<Group> scope) {
        List<Queue_Mapping__c> lstQueueMappingUpsert = new List<Queue_Mapping__c>();
        List<Group> lstSupportQueues = new List<Group>();
        Set<Id> setRoutingConfigIds = new Set<Id>();
        try{
            //Loop over scope to find out queues enabled for Live Chat and Case routing
            for(Group grpInfo: scope){
                for(QueueSobject obj: grpInfo.QueueSobjects){
                    if(queueObj.contains(obj.SobjectType)){
                        if(grpInfo.QueueRoutingConfigId!=null){
                            setRoutingConfigIds.add(grpInfo.QueueRoutingConfigId);
                        }
                        lstSupportQueues.add(grpInfo);
                        break;
                    }
                }
            }
            //Loop over Support Queues
            if(!lstSupportQueues.isEmpty()){
                String queueOrigin = CDdCoreConstants.BLANK_STRING;
                Decimal queueWeight = 0.0;
                Integer routingPriority = 0;
                String chatButtons;
                //Get all QueueRoutingConfig for queues in the context
                Map<Id,QueueRoutingConfig> mapRoutingConfig = new Map<Id,QueueRoutingConfig>(
                    [SELECT Id, capacityWeight, RoutingPriority FROM QueueRoutingConfig WHERE Id = :setRoutingConfigIds]
                );
                //Get all LiveChatButton for queues in the context
                Map<Id,Set<LiveChatButton>> mapQueueLiveChatButton = new Map<Id,Set<LiveChatButton>>();
                for(LiveChatButton chatButton:[SELECT ID,QueueId FROM LiveChatButton WHERE QueueId IN:lstSupportQueues]){
                    if(!mapQueueLiveChatButton.containsKey(chatButton.QueueId)){
                        mapQueueLiveChatButton.put(chatButton.QueueId,new Set<LiveChatButton>());
                    }
                    mapQueueLiveChatButton.get(chatButton.QueueId).add(chatButton);
                }
                //Loop over the support queues
                for(Group grpInfo: lstSupportQueues){
                    Queue_Mapping__c qMap = new Queue_Mapping__c();
                    queueOrigin = CDdCoreConstants.BLANK_STRING;
                    queueWeight = 0.0;
                    routingPriority = 0;
                    chatButtons = CDdCoreConstants.BLANK_STRING;
                    //Find out queue weight and priority from Routing Config
                    if(grpInfo.QueueRoutingConfigId!=null){
                        queueWeight = mapRoutingConfig.get(grpInfo.QueueRoutingConfigId).capacityWeight;
                        routingPriority = mapRoutingConfig.get(grpInfo.QueueRoutingConfigId).RoutingPriority;
                    }
                    //Find out Chat button Ids which are used in LiveChatButton
                    if(mapQueueLiveChatButton.containsKey(grpInfo.Id)){
                        for(LiveChatButton chatButton:mapQueueLiveChatButton.get(grpInfo.Id)){
                            chatButtons += (String.isBlank(chatButtons) ? CDdCoreConstants.BLANK_STRING : CDdCoreConstants.DELIMITER_SEMICOLON) + chatButton.Id;
                        }
                    }
                    //Group name is used to determine Group Origin
                    String grpName = grpInfo.Name;
                    if(grpName.contains(CHAT_ORIGIN)){
                        queueOrigin = mapQueueOrigin.get(CHAT_ORIGIN);
                    }else if(grpName.contains(WEB_ORIGIN)){
                        queueOrigin =mapQueueOrigin.get(WEB_ORIGIN);
                    }else if(grpName.contains(API_ORIGIN)){
                        queueOrigin =mapQueueOrigin.get(API_ORIGIN);
                    }else if(grpName.contains(SOCIAL_ORIGIN)){
                        queueOrigin =mapQueueOrigin.get(SOCIAL_ORIGIN);
                    }
                    //If queue is already in Mapping object just refresh data for few fields
                    if(mapExistingData.containsKey(grpInfo.Id)){
                        qMap = new Queue_Mapping__c (Queue_Id__c =grpInfo.Id,Queue_Name__c =grpInfo.Name,
                                                     Queue_Developer_Name__c = grpInfo.DeveloperName,
                                                     Queue_Priority__c = routingPriority,
                                                     Work_Size_Unit__c = queueWeight,
                                                     Chat_Button_Id__c  = chatButtons);
                    }else{
                        qMap = new Queue_Mapping__c (Queue_Id__c =grpInfo.Id,Queue_Name__c =grpInfo.Name,
                                                     Is_Support_Queue__c =true,Queue_Developer_Name__c = grpInfo.DeveloperName,
                                                     Queue_Type__c =OMNI_QUEUE_TYPE, Queue_Origin__c = queueOrigin,
                                                     Queue_Priority__c =routingPriority,Work_Size_Unit__c = queueWeight,
                                                     Chat_Button_Id__c  = chatButtons,
                                                     Is_Vendor_Split__c = setVendorSplitQueues.contains(grpInfo.ID));
                    }

                    if(overrideStatus){
                        qMap.Status__c = recordStatus;
                    }
                    lstQueueMappingUpsert.add(qMap);
                }
                //This is for Phone Queues
                for(amazonconnect__AC_QueueMetrics__c phoneQueue: [SELECT Id,Name,amazonconnect__Queue_Id__c
                                                                   FROM amazonconnect__AC_QueueMetrics__c ]){
                    Queue_Mapping__c qMap = new Queue_Mapping__c();
                	if(mapExistingData.containsKey(phoneQueue.amazonconnect__Queue_Id__c)){
                        Queue_Mapping__c existingRec = mapExistingData.get(phoneQueue.amazonconnect__Queue_Id__c);
                        if(existingRec.Queue_Name__c!=phoneQueue.Name || existingRec.Queue_Developer_Name__c!=phoneQueue.Name){
                             qMap = new Queue_Mapping__c (Queue_Id__c =phoneQueue.amazonconnect__Queue_Id__c,
                                                          Queue_Name__c =phoneQueue.Name,
                                                          Queue_Developer_Name__c = phoneQueue.Name);
                        }
                    }else{
                        qMap = new Queue_Mapping__c (Queue_Id__c =phoneQueue.amazonconnect__Queue_Id__c,Queue_Name__c =phoneQueue.Name,
                                                     Is_Support_Queue__c =true,Queue_Developer_Name__c = phoneQueue.Name,
                                                     Queue_Type__c =PHONE_QUEUE_TYPE);
                    }
                    if(overrideStatus){
                        qMap.Status__c = recordStatus;
                    }

                    lstQueueMappingUpsert.add(qMap);

                }
                if(!lstQueueMappingUpsert.isEmpty()){
                    Schema.SObjectField qIdExtKey = Queue_Mapping__c.Fields.Queue_Id__c;
                    List<Database.UpsertResult> resList = Database.upsert(lstQueueMappingUpsert,qIdExtKey, false);
                    List<String> errorMessages = CDdErrorUtilities.processUpsertResults(resList, new List< String>());
                    CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchQueueMapping', 'Execute Method', LoggingLevel.ERROR);
                }
            }
        }catch(Exception e){
            CDdErrorUtilities.publishException('CDdBatchQueueMapping', 'execute', e);
        }

    }

    /*****************************************************************************************************************************
    *
    * Finish
    *
    ****************************************************************************************************************************/
    public void finish(Database.BatchableContext BC) {
		List<Approval.ProcessSubmitRequest> lstApprovalReqs = new List<Approval.ProcessSubmitRequest> ();
        for(Queue_Mapping__c qMap:[SELECT Id FROM Queue_Mapping__c WHERE Status__c=:NEW_STATUS]){
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitted for approval. Please approve.');
            req.setObjectId(qMap.Id);
            lstApprovalReqs.add(req);
        }
        if(!lstApprovalReqs.isEmpty()){
            try {
                Approval.ProcessResult[] processResults  = Approval.process(lstApprovalReqs, false);
            }catch (System.DmlException e) {
                CDdErrorUtilities.publishException('CDdBatchQueueMapping', 'finish', e);
            }
        }
    }

    /*****************************************************************************************************************************
     *
     * Schedular Execute
     *
     ****************************************************************************************************************************/
     public void execute(SchedulableContext sc) {
         CDdBatchQueueMapping batch = new CDdBatchQueueMapping();
         Database.executeBatch(batch, 150);
     }
}