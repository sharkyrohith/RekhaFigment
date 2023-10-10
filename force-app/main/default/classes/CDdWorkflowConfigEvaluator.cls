/**
 * CDdWorkflowConfigEvaluator
 *
 * @author      Mahesh Chouhan
 * @date        Jan 2023
 * @decription  Class to evaluate Project Horizon's Workflow Configuration metadata records and perform Workflow Action
 */
public class CDdWorkflowConfigEvaluator {
    /*****************************************************************************************************************************
     *
     * Public Variables
     *
    *****************************************************************************************************************************/
    public static Set<Id> recordsProcessed = new Set<Id>();
    public static Map<Id, SObject> relatedRecords = new Map<Id, SObject>();
    //Key is Related Record Id and Value is Set of Workflow_Configuration__mdt Ids which caused the update
    public static Map<Id, Set<String>> relatedRecordWorkflowConfigMap = new Map<Id, Set<String>>();

    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    private static Map<String, CDdCriterionEvaluator> criterionEvaluatorImplementationByComparison =
        new Map<String, CDdCriterionEvaluator> {
            'Equals'                                           => new CDdEqualsCriterionEvaluator(),
            'Actual value is one of (In)'                      => new CDdContainsCriterionEvaluator(),
            'Not Equals'                                       => new CDdNotEqualsCriterionEvaluator(),
            'Actual value is not one of (Not In)'              => new CDdNotContainsCriterionEvaluator(),
            'Actual value contains string (Like)'              => new CDdLikeCriterionEvaluator(),
            'Is Not Blank'                                     => new CDdIsNotBlankCriterionEvaluator(),
            'Is New'                                           => new CDdIsNewCriterionEvaluator(),
            'Is Changed'                                       => new CDdIsChangedCriterionEvaluator(),
            'Actual value does not contain string (Not Like)'  => new CDdNotLikeCriterionEvaluator(),
            'Is Blank'                                         => new CDdIsBlankCriterionEvaluator(),
            'Actual value less than field value'               => new CDdLessThanCriterionEvaluator(),
            'Actual value greater than field value'            => new CDdGreaterThanCriterionEvaluator(),
            'Actual value less than or equal field value'      => new CDdLessOrEqualCriterionEvaluator(),
            'Actual value greater than or equal field value'   => new CDdGreaterOrEqualCriterionEvaluator()
        };

    private static Map<String, CDdFunctionEvaluator> functionEvaluatorImplementationByFunction =
        new Map<String, CDdFunctionEvaluator> {
            'TODAY()'    => new CDdDateTimeFunctionEvaluator(),
            'NOW()'      => new CDdDateTimeFunctionEvaluator()
        };

    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  gets workflow config and criteria records
     * @param       objectName {String}
     * @param       isTestRunning {Boolean}
     * @return      List<Workflow_Configuration__mdt>
     */
    public static List<Workflow_Configuration__mdt> getWorkflowConfigHelper(String objectName,Boolean isTestRunning) {
        List<String> evaluationCriteria = new List<String>();
        Set<String> actionType = new Set<String>();

        if(Trigger.isExecuting) {
            if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_UPDATE))) {
                evaluationCriteria = CDdSupportConstants.updateEvaluationCriteria;
                actionType.add(CDdSupportConstants.WF_ACTION_FIELD_UPDATE);
            }
            if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_INSERT))) {
                evaluationCriteria = CDdSupportConstants.insertEvaluationCriteria;
                actionType.add(CDdSupportConstants.WF_ACTION_FIELD_UPDATE);
            }
            if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.AFTER_UPDATE))) {
                evaluationCriteria = CDdSupportConstants.updateEvaluationCriteria;
                actionType.add(CDdSupportConstants.WF_ACTION_EMAIL_ALERT);
                actionType.add(CDdSupportConstants.WF_ACTION_TASK_CREATION);
                actionType.add(CDdSupportConstants.WF_ACTION_FEED_NOTE_CREATION);
            }
            if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.AFTER_INSERT))) {
                evaluationCriteria = CDdSupportConstants.insertEvaluationCriteria;
                actionType.add(CDdSupportConstants.WF_ACTION_EMAIL_ALERT);
                actionType.add(CDdSupportConstants.WF_ACTION_TASK_CREATION);
                actionType.add(CDdSupportConstants.WF_ACTION_FEED_NOTE_CREATION);
            }
        }
        else {
            //Query all Workflow Configurations for Validating
            evaluationCriteria = new List<String>{CDdSupportConstants.CREATED, CDdSupportConstants.UPDATED, CDdSupportConstants.CREATED_UPDATED,
                CDdSupportConstants.CREATED_UPDATED_SUBSEQUENTLY_MEET_CRITERIA, CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA};
            actionType.add(CDdSupportConstants.WF_ACTION_FIELD_UPDATE);
            actionType.add(CDdSupportConstants.WF_ACTION_EMAIL_ALERT);
            actionType.add(CDdSupportConstants.WF_ACTION_TASK_CREATION);
        }

        return [SELECT  Id, DeveloperName, Is_Active__c, Object_API_Name__c, Filter_Logic__c,
            Evaluation_Criteria__c,
            (SELECT Id, DeveloperName, Compare_Type__c, Field_API_Name__c,
                    Field_Value__c, Is_Active__c, Object_API_Name__c,
                    Rule_Number__c,Use_Prior_Value__c,
                    Related_Object__c,Related_Object_Field_API_Name__c
               FROM Workflow_Criteria__r WHERE Is_Active__c = TRUE),
            (SELECT Id, Date_Time_Value__c, Date_Value__c, Field_API_Name__c, Object_API_Name__c,
                    String_Value__c, Boolean_Value__c, Function__c, Type__c, Decimal_Value__c,
                    Task_Comments__c, Task_Due_Date__c, Task_Priority__c, Task_Status__c, Task_Subject__c,
                    Field_Update_Type__c, Email_Alert_Name__c, Task_Owner__c, Re_evaluate_After_Field_Update__c,
                    Note_Parent__c, Note_Body__c, Related_Object_Id_Field__c, Related_Object_Field_API_Name__c,
                    Workflow_Configuration__c
                FROM Workflow_Actions__r WHERE Is_Active__c = TRUE AND Type__c IN :actionType)
       FROM Workflow_Configuration__mdt WHERE Object_API_Name__c =:objectName
       AND Is_Active__c = TRUE AND Is_Test_Record__c =:isTestRunning
       AND Evaluation_Criteria__c IN :evaluationCriteria];
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription Perform Project Horizon workflow actions on records
     * @param   List<SObject> newRecords
     * @param   Map<Id,SObject> oldRecordMap
     * @return  void
    */
    public static void executeWorkflows(List<SObject> newRecords, Map<Id, SObject> oldRecordMap){
        List<SObject> reEvaluateRecords = new List<SObject>();
        //List includes Email Alert and Task Creation actions
        List<CDdWorkflowConfigRequest> flowActions = new List<CDdWorkflowConfigRequest>();
        //List includes Field Update actions
        Map<SObject, List<Workflow_Action__mdt>> nonFlowActions = new Map<SObject, List<Workflow_Action__mdt>>();
        List<FeedItem> feedNotes = new List<FeedItem>();
        try{
                List<SObject> recordsToProcess = new List<SObject>();
                for(SObject record : newRecords){
                    //Salesforce Out of the box Workflow Field Updates will fire trigger multiple times
                    //To prevent that, marking record as processed to ignore evaluating project horizon
                    if(!recordsProcessed.contains(record.Id)) {
                        recordsToProcess.add(record);
                    }
                }
                //Key is sObject record and Value is Workflow Actions to be performed
                Map<SObject, List<Workflow_Action__mdt>> objectWorkflowActionMap = getWorkflowTask(recordsToProcess, oldRecordMap);

                for(SObject record : objectWorkflowActionMap.keySet()){
                    CDdWorkflowConfigRequest workflowConfigReq = new CDdWorkflowConfigRequest();
                    List<CDdWorkflowAction> flowTasks = new List<CDdWorkflowAction>();

                    for(Workflow_Action__mdt workflowAction : objectWorkflowActionMap.get(record)){
                        CDdWorkflowAction workTask = new CDdWorkflowAction();
                        if(workflowAction.Type__c == CDdSupportConstants.WF_ACTION_TASK_CREATION
                            || workflowAction.Type__c == CDdSupportConstants.WF_ACTION_EMAIL_ALERT){
                            workTask.type = workflowAction.Type__c;
                            workTask.taskStatus = workflowAction.Task_Status__c;
                            workTask.taskSubject = workflowAction.Task_Subject__c;
                            workTask.taskPriority = workflowAction.Task_Priority__c;
                            workTask.taskComments = workflowAction.Task_Comments__c;
                            //If No Due Date Specified, use Rule Trigger Date
                            workTask.taskDueDate = String.isEmpty(workflowAction.Task_Due_Date__c) ? System.today()
                                : Date.valueOf(CDdUtilities.replaceMergeFields(record, workflowAction.Task_Due_Date__c));

                            if(!String.isEmpty(workflowAction.Task_Owner__c)) {
                                String ownerId = CDdUtilities.replaceMergeFields(record, workflowAction.Task_Owner__c);
                                //If ownerId refers to Queue, assign task to current user
                                workTask.taskOwner = ownerId.startsWith('005') ? ownerId : UserInfo.getUserId();
                            }
                            workTask.emailAlertName = workflowAction.Email_Alert_Name__c;
                            workTask.objectApiName = workflowAction.Object_API_Name__c;
                            flowTasks.add(workTask);
                        }

                        if(workflowAction.Type__c == CDdSupportConstants.WF_ACTION_FIELD_UPDATE){
                            if(workflowAction.Re_evaluate_After_Field_Update__c){
                                reEvaluateRecords.add(record);
                            }
                            if(!nonFlowActions.containsKey(record)){
                                nonFlowActions.put(record, new List<Workflow_Action__mdt>());
                            }
                            nonFlowActions.get(record).add(workflowAction);
                        }

                        if(workflowAction.Type__c == CDdSupportConstants.WF_ACTION_FEED_NOTE_CREATION){
                            FeedItem cFeed = new FeedItem();
                            cFeed.ParentId = CDdUtilities.replaceMergeFields(record, workflowAction.Note_Parent__c);
                            cFeed.Body = CDdUtilities.replaceMergeFields(record, workflowAction.Note_Body__c);
                            feedNotes.add(cFeed);
                        }
                    }
                    if(flowTasks.size() > 0){
                        workflowConfigReq.recordId = record.Id;
                        workflowConfigReq.workflowTasks = flowTasks;
                        flowActions.add(workflowConfigReq);
                    }

                    //Mark Record Id as already processed
                    if(record.Id != null && Trigger.isAfter){
                        recordsProcessed.add(record.Id);
                    }
                }

                if(!feedNotes.isEmpty()){
                    CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.CREATE_CASE_FEED,
                        null,JSON.serialize(feedNotes));
                }

                if(!nonFlowActions.isEmpty()){
                    updateRecords(nonFlowActions);
                    if(!reEvaluateRecords.isEmpty()){
                        executeWorkflows(reEvaluateRecords, oldRecordMap);
                    }
                }

                if(flowActions.size() > 0){
                    Map<String, List<CDdWorkflowConfigRequest>> parameters = new Map<String, List<CDdWorkflowConfigRequest>>();
                    parameters.put('WorkflowConfigRequests', flowActions);
                    if(System.IsBatch() || System.isFuture()) {
                        executeFlow(parameters);
                    }
                    else {
                        executeFlowInFuture(JSON.serialize(parameters));
                    }
                }
            } catch (Exception e) {
            if (Test.isRunningTest()) throw e;
            CDdErrorUtilities.publishException('CDdWorkflowConfigEvaluator','executeWorkflows',e);
        }
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Feb 2023
     * @decription Execute flow to create Task and send emails
     * @param   String jsonString
     * @return  void
    */
    public static void executeFlow(Map<String, List<CDdWorkflowConfigRequest>> parameters){
        Flow.Interview.Workflow_Config_Evaluator stage = new Flow.Interview.Workflow_Config_Evaluator(parameters);
        stage.start();
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Feb 2023
     * @decription Execute flow to create Task and send emails using future method
     * @param   String jsonString
     * @return  void
    */
    @future
    public static void executeFlowInFuture(String jsonString){
        Map<String, List<CDdWorkflowConfigRequest>> parameters = (Map<String, List<CDdWorkflowConfigRequest>>)
            JSON.deserialize(jsonString, Map<String, List<CDdWorkflowConfigRequest>>.class);
        Flow.Interview.Workflow_Config_Evaluator stage = new Flow.Interview.Workflow_Config_Evaluator(parameters);
        stage.start();
    }
    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription Get Workflow Actions for records which met criteria
     * @param   List<SObject> newRecords
     * @param   Map<Id,SObject> oldRecordMap
     * @return  Map<SObject,List<Workflow_Action__mdt>> Workflow action for each record
    */
    public static Map<SObject, List<Workflow_Action__mdt>> getWorkflowTask(List<SObject> newRecords, Map<Id,SObject> oldRecordMap){
        //Key is sObject record and Value is Workflow Actions List to be performed
        Map<SObject, List<Workflow_Action__mdt>> objectWorkflowActionMap = new Map<SObject, List<Workflow_Action__mdt>>();
        for(SObject record : newRecords){
            List<Workflow_Action__mdt> workflowActions = new List<Workflow_Action__mdt>();
            for(Workflow_Configuration__mdt workflowConfig : getWorkflowConfigInfo(record, oldRecordMap)){
                workflowActions.addAll(workflowConfig.Workflow_Actions__r);
            }
            objectWorkflowActionMap.put(record, workflowActions);
        }
        return objectWorkflowActionMap;
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2022
     * @decription  Gets the Map with Related Object and the fields to add to the query
     * @param       objName {String}
     * @return      Map<String,List<String>> --- Map<Related Object Name,List<Related Object Field API Names>>
     */
    public static Map<String,List<String>> getRelatedObjectFieldsMap(String objName) {
        Map<String,List<String>> relatedObjectFieldsMap = new Map<String,List<String>>();

        for (Workflow_Criterion__mdt rc :
            [SELECT Id, Related_Object__c,Related_Object_Field_API_Name__c
               FROM Workflow_Criterion__mdt
              WHERE Is_Active__c = true
                AND Workflow_Configuration__r.Is_Active__c = true
                AND Workflow_Configuration__r.Is_Test_Record__c = :Test.isRunningTest()
                AND Related_Object__c != NULL
                AND Object_API_Name__c = :objName
                AND Related_Object_Field_API_Name__c != null]) {
            if (!relatedObjectFieldsMap.containsKey(rc.Related_Object__c)) {
                relatedObjectFieldsMap.put(rc.Related_Object__c,new List<String>());
            }
            relatedObjectFieldsMap.get(rc.Related_Object__c).add(rc.Related_Object_Field_API_Name__c.toLowerCase());
        }
        return relatedObjectFieldsMap;
    }

    /*****************************************************************************************************************************
     *
     * Private Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  Gets Workflow Config and Criteria
     * @param       String objectName
     * @return  List<Workflow_Configuration__mdt>
     */
    @TestVisible
    private static List<Workflow_Configuration__mdt> getWorkflowConfig(String objectName) {
        //get records from database and return the list
        List<Workflow_Configuration__mdt> workflowConfigList = getWorkflowConfigHelper(objectName, Test.isRunningTest());
        return workflowConfigList;
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  Update fields on record on the basis of workflowFieldUpdateList
     * @param       SObject record
     * @param       List<Workflow_Action__mdt> workflowFieldUpdateList
     * @return  void
     */
    private static void evaluateWorkflowFieldUpdates(SObject record, List<Workflow_Action__mdt> workflowFieldUpdateList){
        for(Workflow_Action__mdt workflowFieldUpdate : workflowFieldUpdateList){
            if(String.isNotBlank(workflowFieldUpdate.Related_Object_Id_Field__c)){
                Id relatedObjectId = (Id) record.get(workflowFieldUpdate.Related_Object_Id_Field__c);
                if(relatedObjectId != null){
                    if(!relatedRecords.containsKey(relatedObjectId)){
                        SObjectType relatedObjectType = relatedObjectId.getSobjectType();
                        relatedRecords.put(relatedObjectId, relatedObjectType.newSObject(relatedObjectId));
                    }
                    if(!relatedRecordWorkflowConfigMap.containsKey(relatedObjectId)){
                        relatedRecordWorkflowConfigMap.put(relatedObjectId, new Set<String>());
                    }
                    Sobject relatedObject = relatedRecords.get(relatedObjectId);
                    relatedRecordWorkflowConfigMap.get(relatedObjectId).add(workflowFieldUpdate.Workflow_Configuration__c);
                    populateFields(relatedObject, workflowFieldUpdate, workflowFieldUpdate.Related_Object_Field_API_Name__c, workflowFieldUpdate.Field_Update_Type__c);
                    relatedRecords.put(relatedObjectId, relatedObject);
                }
            }
            else {
                populateFields(record, workflowFieldUpdate, workflowFieldUpdate.Field_API_Name__c, workflowFieldUpdate.Field_Update_Type__c);
            }
        }
    }

    private static void populateFields(SObject record, Workflow_Action__mdt workflowFieldUpdate, String fieldApiName, String fieldType){
        switch on fieldType {
            when 'DateTime' {
                if(workflowFieldUpdate.Date_Time_Value__c != null) {
                    record.put(fieldApiName, workflowFieldUpdate.Date_Time_Value__c);
                }
            }
            when 'Date' {
                if(workflowFieldUpdate.Date_Value__c != null) {
                    record.put(fieldApiName, workflowFieldUpdate.Date_Value__c);
                }
            }
            when 'Decimal' {
                if(workflowFieldUpdate.Decimal_Value__c != null) {
                    record.put(fieldApiName, workflowFieldUpdate.Decimal_Value__c);
                }
            }
            when 'String' {
                if(String.isNotBlank(workflowFieldUpdate.String_Value__c)) {
                    String value = workflowFieldUpdate.String_Value__c;
                    value = CDdUtilities.replaceMergeFields(record, workflowFieldUpdate.String_Value__c);
                    record.put(fieldApiName, value);
                }
            }
            when 'Boolean' {
                record.put(fieldApiName, workflowFieldUpdate.Boolean_Value__c);
            }
            when 'Null' {
                record.put(fieldApiName, null);
            }
            when 'Function' {
                CDdFunctionEvaluator functionEvaluator = functionEvaluatorImplementationByFunction.get(workflowFieldUpdate.Function__c);
                record.put(fieldApiName, functionEvaluator.getValue(workflowFieldUpdate.Function__c));
            }
        }
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription Perform Project Horizon workflow field update action
     * @param   Map<SObject,List<Workflow_Action__mdt>> objectWorkflowActionMap Key is sObject record and Value is Field Update Action list
     * @return  void
    */
    private static void updateRecords(Map<SObject, List<Workflow_Action__mdt>> objectWorkflowActionMap){
        for(SObject record : objectWorkflowActionMap.keySet()){
            evaluateWorkflowFieldUpdates(record, objectWorkflowActionMap.get(record));
        }
        if(!relatedRecords.isEmpty()){
            System.enqueueJob(new CDdRetryQueueable(relatedRecords.values(), 'UPDATE', 'CDdWorkflowConfigEvaluator.updateRecords : ' + String.join(relatedRecordWorkflowConfigMap.values(), ',')));
        }
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription Workflow Config records which met the criteria
     * @param   SObject newRecord
     * @param   Map<Id,SObject> oldRecordMap
     * @return  List<Workflow_Configuration__mdt> All Workflow Config records for which criteria is met
    */
    private static List<Workflow_Configuration__mdt> getWorkflowConfigInfo(SObject newRecord, Map<Id, SObject> oldRecordMap) {
        List<Workflow_Configuration__mdt> workflowConfigs = new List<Workflow_Configuration__mdt>();
        CDdBooleanExpressionEvaluator expEvaluator = new CDdBooleanExpressionEvaluator();
        try {
            String objectName;
            if (newRecord != null) {
                objectName = String.valueOf(newRecord.getSObjectType());
            }
            List<Workflow_Configuration__mdt> workflowConfigList = getWorkflowConfig(objectName);
            Boolean overallCriteriaMatch = true;
            String filterLogic;
            Map<Integer,Boolean> mapRuleNoCriterion = new Map<Integer,Boolean>();
            for (Workflow_Configuration__mdt workflowConfigVar : workflowConfigList) {
                filterLogic = '';
                mapRuleNoCriterion = new Map<Integer,Boolean>();

                overallCriteriaMatch = !workflowConfigVar.Workflow_Criteria__r.isEmpty();

                if(String.isNotBlank(workflowConfigVar.Filter_Logic__c)){
                    filterLogic = workflowConfigVar.Filter_Logic__c;
                }
                for (Workflow_Criterion__mdt workflowCriterionVar : workflowConfigVar.Workflow_Criteria__r) {
                    CDdCriterionEvaluator criterionEvaluator =
                                        criterionEvaluatorImplementationByComparison.get(workflowCriterionVar.Compare_Type__c);

                    Boolean criterionEvaluation = false;
                    if(workflowCriterionVar.Use_Prior_Value__c){
                        //In case of Insert operation, return true
                        SObject oldRecord = oldRecordMap != null ? oldRecordMap.get(newRecord.Id) : null;
                        criterionEvaluation = oldRecord != null ? criterionEvaluator.evaluateCriterion(workflowCriterionVar, oldRecord) : true;
                    }
                    else {
                        criterionEvaluation = criterionEvaluator.evaluateCriterion(workflowCriterionVar,newRecord);
                    }

                    if (String.isNotBlank(filterLogic) && String.isNotBlank(String.valueOf(workflowCriterionVar.Rule_Number__c))){
                        mapRuleNoCriterion.put(Integer.valueOf(workflowCriterionVar.Rule_Number__c),criterionEvaluation);
                    } else {
                        overallCriteriaMatch = overallCriteriaMatch && criterionEvaluation;
                        //If one of the conditions is false then don't need to evaluate remaining as it's AND if no filter Logic added
                        if(!overallCriteriaMatch){
                            break;
                        }
                    }
                }
                //broke out of the inner loop, now in outer loop
                //now evaluate against filter logic field
                if(overallCriteriaMatch && String.isNotBlank(filterLogic)){
                    overallCriteriaMatch = expEvaluator.evaluateExpression(filterLogic,mapRuleNoCriterion);
                }

                if (overallCriteriaMatch) {
                    if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_UPDATE))
                        || String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.AFTER_UPDATE))) {
                        if(!CDdSupportConstants.updateEvaluationCriteria.contains(workflowConfigVar.Evaluation_Criteria__c)) {
                            continue;
                        }
                        if(workflowConfigVar.Evaluation_Criteria__c.contains(CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA)){
                            SObject oldRecord = oldRecordMap != null ? oldRecordMap.get(newRecord.Id) : null;
                            if(oldRecord == null || doesRecordMeetCriteria(oldRecord, workflowConfigVar)){
                                continue;
                            }
                        }
                    }
                    if ((String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_INSERT))
                        || String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.AFTER_INSERT)))
                        && !CDdSupportConstants.insertEvaluationCriteria.contains(workflowConfigVar.Evaluation_Criteria__c)) {
                            //in the insert context, do not process further if "run only on update" is true
                            continue;
                    }
                    workflowConfigs.add(workflowConfigVar);
                }
            }
        } catch (Exception e) {
            if (Test.isRunningTest()) throw e;
            CDdErrorUtilities.publishException('CDdWorkflowConfigEvaluator','getWorkflowConfigInfo',e);
        }
        return workflowConfigs;
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription Check if sObject record met specified criteria
     * @param   SObject newRecord
     * @param   Workflow_Configuration__mdt workflowConfigVar
     * @return  Boolean True, if record mets criteria otherwise false
    */
    private static Boolean doesRecordMeetCriteria(SObject newRecord, Workflow_Configuration__mdt workflowConfigVar) {
        CDdBooleanExpressionEvaluator expEvaluator = new CDdBooleanExpressionEvaluator();
        try {
                String filterLogic = '';
                Map<Integer,Boolean> mapRuleNoCriterion = new Map<Integer,Boolean>();
                Boolean overallCriteriaMatch = !workflowConfigVar.Workflow_Criteria__r.isEmpty();

                if(String.isNotBlank(workflowConfigVar.Filter_Logic__c)){
                    filterLogic = workflowConfigVar.Filter_Logic__c;
                }
                for (Workflow_Criterion__mdt workflowCriterionVar : workflowConfigVar.Workflow_Criteria__r) {
                    CDdCriterionEvaluator criterionEvaluator =
                                        criterionEvaluatorImplementationByComparison.get(workflowCriterionVar.Compare_Type__c);

                    Boolean criterionEvaluation = false;
                    criterionEvaluation = criterionEvaluator.evaluateCriterion(workflowCriterionVar,newRecord);

                    if (String.isNotBlank(filterLogic) && String.isNotBlank(String.valueOf(workflowCriterionVar.Rule_Number__c))){
                        mapRuleNoCriterion.put(Integer.valueOf(workflowCriterionVar.Rule_Number__c),criterionEvaluation);
                    } else {
                        overallCriteriaMatch = overallCriteriaMatch && criterionEvaluation;
                    }
                }
                //broke out of the inner loop, now in outer loop
                //now evaluate against filter logic field
                if(overallCriteriaMatch && String.isNotBlank(filterLogic)){
                    overallCriteriaMatch = expEvaluator.evaluateExpression(filterLogic,mapRuleNoCriterion);
                }

                if (overallCriteriaMatch) {
                    return true;
                }
        } catch (Exception e) {
            if (Test.isRunningTest()) throw e;
            CDdErrorUtilities.publishException('CDdWorkflowConfigEvaluator','doesRecordMeetCriteria',e);
        }
        return false;
    }
}