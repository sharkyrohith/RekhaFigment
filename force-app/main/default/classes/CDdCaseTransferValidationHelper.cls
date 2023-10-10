public with sharing class CDdCaseTransferValidationHelper {
    public static Boolean BYPASS_CASE_TRANSFER_VALIDATION_FOR_THIS_TXN = CDdExperimentSvc.getSupportFeatureFlag('Bypass_Case_Transfer_Validation__c');

    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    private static Map<String, CDdCriterionEvaluator> criterionEvaluatorImplementationByComparison =
        new Map<String, CDdCriterionEvaluator> {
            'Equals' => new CDdEqualsCriterionEvaluator(),
            'Not Equals' => new CDdNotEqualsCriterionEvaluator(),
            'Actual value is one of (In)' => new CDdContainsCriterionEvaluator(),
            'Actual value is not one of (Not In)' => new CDdNotContainsCriterionEvaluator(),
            'Actual value contains string (Like)' => new CDdLikeCriterionEvaluator(),
            'Actual value does not contain string (Not Like)' => new CDdNotLikeCriterionEvaluator(),
            'Is Blank' => new CDdIsBlankCriterionEvaluator(),
            'Is Not Blank' => new CDdIsNotBlankCriterionEvaluator(),
            'Case Notes exist' => new CDdCaseNoteExistsCriterionEvaluator(),
            'Business Hours Is Within' => new CDdBusinessHoursCriterionEvaluator(),
            'Is Changed' => new CDdIsChangedCriterionEvaluator(),
            'Has Transfer Queue' => new CDdAcConTraceHasQueueCriterionEvaluator()
        };

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the validation config records Map
     * @param       None
     * @return      Map<Id,List<Case_Transfer_Validation_Config__mdt>> --- Key is the target queue id
     */
    private static Map<Id,List<Case_Transfer_Validation_Config__mdt>> validationConfigMap = new Map<Id,List<Case_Transfer_Validation_Config__mdt>>();
    public static Map<Id,List<Case_Transfer_Validation_Config__mdt>> getValidationConfig() {
        if (!validationConfigMap.isEmpty()) {
            return validationConfigMap;
        }
        validationConfigMap = getValidationConfigHelper(Test.isRunningTest());
        return validationConfigMap;
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the queues which need case notes / queue mapping query
     * @param       None
     * @return      Map<String,Set<String>> --- Key is the Related Object, Value is the set of queues config which need additional queries in related object
     */
    @TestVisible
    private static Map<String,Set<String>> queuesNeedingRelatedObjectsQueryMap = new Map<String,Set<String>>();
    public static Map<String,Set<String>> getQueuesNeedingRelatedObjectsHelper() {
        if (!queuesNeedingRelatedObjectsQueryMap.isEmpty()) {
            return queuesNeedingRelatedObjectsQueryMap;
        }
        queuesNeedingRelatedObjectsQueryMap = getQueuesNeedingRelatedObjectsQueryHelper(Test.isRunningTest());
        return queuesNeedingRelatedObjectsQueryMap;
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the queues which need case notes query
     * @param       isTestRunning {Boolean}
     * @return      Map<String,Set<String>> --- Key is the Related Object, Value is the set of queues config which need additional queries in related object
     */
    public static Map<String,Set<String>> getQueuesNeedingRelatedObjectsQueryHelper(Boolean isTestRunning) {
        Map<String,Set<String>> retVal = new Map<String,Set<String>>();
        for (Case_Transfer_Validation_Criterion__mdt rec :
            [SELECT Id, Related_Object__c, Parent__r.Target_Queue_Id__c
               FROM Case_Transfer_Validation_Criterion__mdt
              WHERE isActive__c = true
                AND Parent__r.isActive__c = true
                AND Parent__r.Is_Test_Record__c = :isTestRunning
                AND Related_Object__c in ('Latest Case Note','Case Notes','AC Contact Trace Record','Previous Queue Mapping','Target Queue Mapping')]) {
            if (!retVal.containsKey(rec.Related_Object__c)) {
                retVal.put(rec.Related_Object__c,new Set<String>());
            }
            retVal.get(rec.Related_Object__c).add(rec.Parent__r.Target_Queue_Id__c);
        }
        return retVal;
    }

    /**
     * @author      Raju
     * @date        March 2022
     * @decription  Gets Validation Config and the related criteria records
     * @param       isTestRunning {Boolean}
     * @return      Map<Id,List<Case_Transfer_Validation_Config__mdt>> --- Key is the target queue id
     */
    public static Map<Id,List<Case_Transfer_Validation_Config__mdt>> getValidationConfigHelper(Boolean isTestRunning) {
        Map<Id,List<Case_Transfer_Validation_Config__mdt>> retVal = new Map<Id,List<Case_Transfer_Validation_Config__mdt>>();

        for (Case_Transfer_Validation_Config__mdt caseValidationConfig : getValidationConfigs(isTestRunning)) {
            if (!retVal.containsKey(caseValidationConfig.Target_Queue_Id__c))    {
                retVal.put(caseValidationConfig.Target_Queue_Id__c, new List<Case_Transfer_Validation_Config__mdt>());
            }
            retVal.get(caseValidationConfig.Target_Queue_Id__c).add(caseValidationConfig);
        }
        return retVal;
    }

    /**
     * @author      Raju
     * @date        March 2022
     * @decription  Gets Validation Config and the related criteria records
     * @param       isTestRunning {Boolean}
     * @return      List<Case_Transfer_Validation_Config__mdt>
     */
    public static List<Case_Transfer_Validation_Config__mdt> getValidationConfigs(Boolean isTestRunning) {
        return [SELECT Id, DeveloperName, isActive__c, Criteria_Behavior__c,
                        Error_Message__c, Filter_Logic__c, Is_Test_Record__c, Sort_Order__c, Target_Queue_Id__c,
                        Bypass_Trigger_Case_Insert__c,
                        (SELECT Id, DeveloperName, isActive__c, Business_Hours_Id__c,
                                Field_API_Name__c, Compare_Type__c,Compare_Case_Sensitive__c, Field_Value__c  ,
                                Related_Object__c,Related_Object_Field_API_Name__c,Rule_Number__c,
                                Use_Prior_Value__c,AC_Contact_Trace_Queue_Name__c
                           FROM Case_Transfer_Validation_Criteria__r
                          WHERE isActive__c = TRUE)
                   FROM Case_Transfer_Validation_Config__mdt
                  WHERE isActive__c = TRUE
                    AND Is_Test_Record__c = :isTestRunning
               ORDER BY Sort_Order__c ASC];
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the Map with Related Object and the fields to add to the query
     * @param       None
     * @return      Map<String,List<String>> --- Map<Related Object Name,List<Related Object Field API Names>>
     */
    private static Map<String,List<String>> relatedObjectFieldsMap = null;
    public static Map<String,List<String>> getRelatedObjectFieldsMap() {
        if (relatedObjectFieldsMap != null) {
            return relatedObjectFieldsMap;
        }

        relatedObjectFieldsMap = new Map<String,List<String>>();
        for (Case_Transfer_Validation_Criterion__mdt rec :
            [SELECT Id, Related_Object__c,Related_Object_Field_API_Name__c
               FROM Case_Transfer_Validation_Criterion__mdt
              WHERE isActive__c = true
                AND Parent__r.isActive__c = true
                AND Parent__r.Is_Test_Record__c = :Test.isRunningTest()
                AND Related_Object__c IN ('Account','Contact','Opportunity','Current User','Current Owner (User)','Previous Queue Mapping','Target Queue Mapping')
                AND Related_Object_Field_API_Name__c != null]) {
            String relatedObject = rec.Related_Object__c;
            switch on rec.Related_Object__c {
                when 'Current Owner (User)','Current User' {
                    relatedObject = 'User';
                }
                when 'Previous Queue Mapping','Target Queue Mapping' {
                    relatedObject = 'Queue_Mapping__c';
                }
            }
            if (!relatedObjectFieldsMap.containsKey(relatedObject)) {
                relatedObjectFieldsMap.put(relatedObject,new List<String>());
            }
            relatedObjectFieldsMap.get(relatedObject).add(rec.Related_Object_Field_API_Name__c.toLowerCase());
        }
        return relatedObjectFieldsMap;
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Executes the Project Shield Transfer/Escalation validation
     * @param       caseList - List<Case>
     * @param       caseOldMap - Map<Id,Case>
     * @return      None
     */
    public static void executeTransferValidation(List<Case> caseList, Map<Id,Case> caseOldMap) {
        if (BYPASS_CASE_TRANSFER_VALIDATION_FOR_THIS_TXN) {
            return;
        }
        // This data structure will ensure that only target queues needing extra case notes/queue mapping queries will be considered,
        // We dont want to be fetching those records if its not gonna be used.
        Map<String,Set<String>> queuesNeedingRelatedObjectsQuery = getQueuesNeedingRelatedObjectsHelper();
        Map<Id,List<Case_Transfer_Validation_Config__mdt>> validationConfig = getValidationConfig();

        List<Case> toProcess = new List<Case>();
        Set<Id> casesToGetCaseNotes = new Set<Id>();
        Set<Id> casesToGetAcContactTraceRecords = new Set<Id>();
        Set<Id> queueIdsToGetQueueMapping = new Set<Id>();

        for (Case c : caseList) {
            String oldOwnerId = caseOldMap.get(c.Id).OwnerId;
            // if the case owner is changed to a queue and there exists validation configs for that target queue
            if (c.OwnerId != oldOwnerId && CDdUtilities.idIsGroup(c.OwnerId) && validationConfig.containsKey(c.OwnerId)) {
                toProcess.add(c);

                // Add to the case notes and queue mapping query logic, only if the validation criterion for the target queue needs it.
                Set<String> queuesNeedingCaseNotes = queuesNeedingRelatedObjectsQuery.get('Case Notes');
                if (queuesNeedingCaseNotes != null && queuesNeedingCaseNotes.contains(c.OwnerId)) {
                    casesToGetCaseNotes.add(c.Id);
                }
                Set<String> queuesNeedingLatestCaseNote = queuesNeedingRelatedObjectsQuery.get('Latest Case Note');
                if (queuesNeedingLatestCaseNote != null && queuesNeedingLatestCaseNote.contains(c.OwnerId)) {
                    casesToGetCaseNotes.add(c.Id);
                }
                Set<String> queuesNeedingTargetQueueMapping = queuesNeedingRelatedObjectsQuery.get('Target Queue Mapping');
                if (queuesNeedingTargetQueueMapping != null && queuesNeedingTargetQueueMapping.contains(c.OwnerId)) {
                    queueIdsToGetQueueMapping.add(c.OwnerId);
                }
                if (String.isNotBlank(c.Previous_Queue_ID__c) && CDdUtilities.idIsGroup(c.Previous_Queue_ID__c)) {
                    Set<String> queuesNeedingSourceQueueMapping = queuesNeedingRelatedObjectsQuery.get('Previous Queue Mapping');
                    if (queuesNeedingSourceQueueMapping != null && queuesNeedingSourceQueueMapping.contains(c.OwnerId)) {
                        queueIdsToGetQueueMapping.add(c.Previous_Queue_ID__c);
                    }
                }
                Set<String> queuesNeedingAcContactTrace = queuesNeedingRelatedObjectsQuery.get('AC Contact Trace Record');
                if (queuesNeedingAcContactTrace != null && queuesNeedingAcContactTrace.contains(c.OwnerId)) {
                    casesToGetAcContactTraceRecords.add(c.Id);
                }
            }
        }
        if (toProcess.isEmpty()) {
            return;
        }
        // Use optimization framework to get and cache the query of related objects.
        if (!casesToGetCaseNotes.isEmpty()) {
            CDdCaseTriggerOptimizationHelper.setCaseFeedMap(casesToGetCaseNotes);
        }
        if (!queueIdsToGetQueueMapping.isEmpty()) {
            CDdGenericTriggerOptimizationHelper.setQueueMappingMap(queueIdsToGetQueueMapping);
        }
        if (!casesToGetAcContactTraceRecords.isEmpty()) {
            CDdCaseTriggerOptimizationHelper.setAcContactTraceTransferMap(casesToGetAcContactTraceRecords);
        }

        CDdBooleanExpressionEvaluator expEvaluator = new CDdBooleanExpressionEvaluator();
        for (Case record : toProcess) {
            Case oldRecord = caseOldMap.get(record.Id);
            for (Case_Transfer_Validation_Config__mdt vc : validationConfig.get(record.OwnerId)) {
                if (vc.Case_Transfer_Validation_Criteria__r == null || vc.Case_Transfer_Validation_Criteria__r.isEmpty()) {
                    continue;
                }
                if(CDdCaseTriggerHandlerV2.IS_CASE_INSERT && vc.Bypass_Trigger_Case_Insert__c) {
                    continue;
                }
                String filterLogic = String.isBlank(vc.Filter_Logic__c) ? CDdCoreConstants.BLANK_STRING : vc.Filter_Logic__c;
                Boolean overallCriteriaMatch = true;
                Map<Integer,Boolean> mapRuleNoCriterion = new Map<Integer,Boolean>();
                for (Case_Transfer_Validation_Criterion__mdt criterion : vc.Case_Transfer_Validation_Criteria__r) {
                    CDdCriterionEvaluator criterionEvaluator = criterionEvaluatorImplementationByComparison.get(criterion.Compare_Type__c);
                    Boolean criterionEvaluation = criterionEvaluator.evaluateCriterion(criterion,(criterion.Use_Prior_Value__c ? oldRecord : record));
                    if (String.isNotBlank(filterLogic) && criterion.Rule_Number__c != null) {
                        mapRuleNoCriterion.put(Integer.valueOf(criterion.Rule_Number__c),criterionEvaluation);
                    } else {
                         //run for all records before evaluating
                        overallCriteriaMatch = overallCriteriaMatch && criterionEvaluation;
                    }
                }

                if (String.isNotBlank(filterLogic)) {
                    overallCriteriaMatch = expEvaluator.evaluateExpression(filterLogic,mapRuleNoCriterion);
                }

                Boolean showError = false;
                switch on vc.Criteria_Behavior__c {
                    when 'Prevent transfer if criteria is met' {
                        showError = overallCriteriaMatch;
                    }
                    when 'Allow transfer only if criteria is met' {
                        showError = !overallCriteriaMatch;
                    }
                }

                if (showError) {
                    String errorMsg = vc.Error_Message__c;
                    errorMsg = getCustomQueueMergeText(errorMsg, record.Previous_Queue_Id__c, '{Previous Queue Name}');
                    errorMsg = getCustomQueueMergeText(errorMsg, record.OwnerId, '{Target Queue Name}');
                    errorMsg = CDdUtilities.replaceMergeFields(record, errorMsg);
                    record.addError(errorMsg + ' -- Error Id: (' + vc.Id + ')');
                    break;
                }
            }
        }
    }

    private static String getCustomQueueMergeText(String text, String queueId,String textToMerge) {
        if (text.contains(textToMerge)) {
            String queueName = CDdCoreConstants.BLANK_STRING;
            if (String.isNotBlank(queueId)) {
                Group queue = CDdGenericTriggerOptimizationHelper.getQueue(queueId);
                queueName = queue != null ? queue.Name : CDdCoreConstants.BLANK_STRING;
            }
            while (text.contains(textToMerge)) {
                text = text.replace(textToMerge, queueName);
            }
        }
        return text;
    }
}