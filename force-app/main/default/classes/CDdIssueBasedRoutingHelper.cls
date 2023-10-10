/**
 * CDdIssueBasedRoutingHelper
 *
 * @author     Sahil
 * @date  2021-05-05
 * @decription helper class to evaluate if the incoming record meets issue criteria for cases and chat transcripts
 *              BIZS-967 - Updated Code to use Text Object/Field Fields instead of lookup Object/Field Fields.
 *              BIZS-1076 - Raju L - Adding support for related object fields.
 */
public without sharing class CDdIssueBasedRoutingHelper {
    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    private static Map<String, CDdCriterionEvaluator> criterionEvaluatorImplementationByComparison =
        new Map<String, CDdCriterionEvaluator> {
            'Equals'        => new CDdEqualsCriterionEvaluator(),
            'Contains'      => new CDdContainsCriterionEvaluator(),
            'Not Equals'    => new CDdNotEqualsCriterionEvaluator(),
            'Not Contains'  => new CDdNotContainsCriterionEvaluator(),
            'Like'          => new CDdLikeCriterionEvaluator(),
            'Is Not Blank'  => new CDdIsNotBlankCriterionEvaluator(),
            'Is New'        => new CDdIsNewCriterionEvaluator(),
            'Is Changed'    => new CDdIsChangedCriterionEvaluator(),
            'Not Like'      => new CDdNotLikeCriterionEvaluator(),
            'Is Blank'      => new CDdIsBlankCriterionEvaluator(),
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

    @TestVisible
    private static List<Routing_Configuration__mdt> configsForTest = new List<Routing_Configuration__mdt>();
    private static Map<String,List<Routing_Configuration__mdt>> routingConfigMap = new Map<String,List<Routing_Configuration__mdt>>();
    private static Set<String> routingConfigCustomerType = new Set<String>{CDdCoreConstants.STRING_ALL};
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author     Sahil
     * @date  2021-05-05
     * @decription checks if field value of incoming record is equal to the desired parameter
     * @param   salesforce record
     * @return  RoutingResult instance
    */
    public static RoutingInfo getRoutingInfo(SObject record) {
        RoutingInfo routingResObj = new RoutingInfo();
        CDdBooleanExpressionEvaluator expEvaluator = new CDdBooleanExpressionEvaluator();
        try {
            String objectName;
            if (record != null) {
                objectName = String.valueOf(record.getSObjectType());
                if(objectName.equals(CDdSupportConstants.CASE_OBJECT_LABEL) && String.isNotEmpty((String) record.get('Customer_Type__c'))) {
                    routingConfigCustomerType.add((String) record.get('Customer_Type__c'));
                }
            }
            List<Routing_Configuration__mdt> routingConfigs = getRoutingConfig(objectName);
            Boolean overallCriteriaMatch = true;
            String filterLogic;
            Map<Integer,Boolean> mapRuleNoCriterion = new Map<Integer,Boolean>();
            SObject oldRecord = Trigger.oldMap != null && Trigger.oldMap.containsKey(record.Id) ? Trigger.oldMap.get(record.Id) : null;

            for (Routing_Configuration__mdt routingConfigVar : routingConfigs) {
                filterLogic = '';
                mapRuleNoCriterion = new Map<Integer,Boolean>();
                // Skip checking this routing config if the Business_Hours_Id__c is populated AND
                // if current time is not in business hours.
                if(!Test.isRunningTest()
                    && String.isNotBlank(routingConfigVar.Business_Hours_Id__c)
                    && !BusinessHours.isWithin(Id.valueOf(routingConfigVar.Business_Hours_Id__c), system.now())) {
                    continue;
                }
                //loop through inner list which are the routing criteria records
                //check criteria for all child records. final result should be a boolean
                //process the result (true/false) outside the loop.
                //RoutingResult will be set based on the result
                overallCriteriaMatch = !routingConfigVar.Routing_Criteria__r.isEmpty();

                if(String.isNotBlank(routingConfigVar.Filter_Logic__c)){
                    filterLogic = routingConfigVar.Filter_Logic__c;
                }
                for (Routing_Criterion__mdt routingCriterionVar : routingConfigVar.Routing_Criteria__r) {
                    CDdCriterionEvaluator criterionEvaluator =
                                        criterionEvaluatorImplementationByComparison.get(routingCriterionVar.Compare_Type__c);

                    Boolean criterionEvaluation = !routingCriterionVar.Use_Prior_Value__c ?
                                                criterionEvaluator.evaluateCriterion(routingCriterionVar,record) :
                                                oldRecord!=null ? criterionEvaluator.evaluateCriterion(routingCriterionVar,oldRecord) : true;
                    //Nayana:11/01/2021 BIZS-758: Mission Control to handle OR condition
                    //If filter logic is enabled then Criteria should have Rule number populated. elase the logical operator used will be AND
                    if (String.isNotBlank(filterLogic) && String.isNotBlank(String.valueOf(routingCriterionVar.Rule_Number__c))){
                        mapRuleNoCriterion.put(Integer.valueOf(routingCriterionVar.Rule_Number__c),criterionEvaluation);
                    } else {
                         //run for all records before evaluating
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
                //check adhoc evaluation criteria
                overallCriteriaMatch = overallCriteriaMatch && CDdAdhocCriteriaEvaluator.evaluateCriterion(routingConfigVar,record);
                //criteria matched, now assign values from routing config header to RoutingInfo
                //populate RoutingResult with the first match and return it
                if (overallCriteriaMatch) {
                    routingResObj.prioritizeVIP      = routingConfigVar.Prioritize_VIP__c;
                    routingResObj.routingDestination = routingConfigVar.Routing_Destination_Name__c;
                    routingResObj.doVendorSplit      = routingConfigVar.Do_Vendor_Split__c;
                    routingResObj.standardRouting    = false;
                    routingResObj.routingConfigLog = 'Applied following Routing Config: '+routingConfigVar.DeveloperName+'(Id: '+routingConfigVar.Id+')';
                    if(String.isBlank(routingConfigVar.Vendor_Chat_Button_Id__c)) {
                        routingConfigVar.Vendor_Chat_Button_Id__c = '';
                    }
                    routingResObj.vendorChatButtonId = routingConfigVar.Vendor_Chat_Button_Id__c;
                    routingResObj.evaluationCriteria = routingConfigVar.Evaluation_Criteria__c;
                    evaluateFieldUpdates(routingResObj, record, routingConfigVar.Routing_Field_Updates__r);
                    if(routingConfigVar.Routing_Case_Notes__r!=null){
                        prepareCaseNotes(routingResObj,routingConfigVar.Routing_Case_Notes__r);
                    }
                    routingResObj.routingType = routingConfigVar.Routing_Type__c;
                    routingResObj.ownerQueueName = routingConfigVar.Owner_Queue_Name__c;
                    routingResObj.routingConfigId = routingConfigVar.Id;
                    return routingResObj;
                }
            }
        } catch (Exception e) {
            if (Test.isRunningTest()) throw e;
            CDdErrorUtilities.publishException('CDdIssueBasedRoutingHelper','getRoutingInfo',e);
        }
        //if no criteria match, set standard routing and return RoutingResult
        routingResObj.prioritizeVIP = false;
        routingResObj.routingDestination = '';
        routingResObj.doVendorSplit = true;
        routingResObj.standardRouting = true;
        routingResObj.vendorChatButtonId = '';
        routingResObj.evaluationCriteria = '';
        return routingResObj;
    }

    /**
     * @author      Raju
     * @date        March 2022
     * @decription  Gets the Map with Related Object and the fields to add to the query
     * @param       objName {String}
     * @return      Map<String,List<String>> --- Map<Related Object Name,List<Related Object Field API Names>>
     */
    public static Map<String,List<String>> getRelatedObjectFieldsMap(String objName) {
        Map<String,List<String>> relatedObjectFieldsMap = new Map<String,List<String>>();

        for (Routing_Criterion__mdt rc :
            [SELECT Id, Related_Object__c,Related_Object_Field_API_Name__c
               FROM Routing_Criterion__mdt
              WHERE Is_Active__c = true
                AND Routing_Configuration__r.Is_Active__c = true
                AND Routing_Configuration__r.Is_Test_Record__c = :Test.isRunningTest()
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
     * @author Sahil
     * @date  05-06-2021
     * @decription gets routing config and criteria records
     * @param   Object name
     * @return  List<Routing_Configuration__mdt>
     */
    @TestVisible
    private static List<Routing_Configuration__mdt> getRoutingConfig(String objectName) {
        if (!configsForTest.isEmpty()) {
            //this means the current context is test. return test data in the list
            return configsForTest;
        }
        //check configs list and return - otherwise query from database
        if (routingConfigMap.containsKey(objectName)) {
            return routingConfigMap.get(objectName);
        }

        //get records from database and return the list
        List<Routing_Configuration__mdt> routingConfigList = getRoutingConfigHelper(objectName,false);
        routingConfigMap.put(objectName,routingConfigList);
        return routingConfigList;
    }

    /**
     * @author      Raju
     * @date        March 2022
     * @decription  gets routing config and criteria records
     * @param       objectName {String}
     * @param       isTestRunning {Boolean}
     * @return      List<Routing_Configuration__mdt>
     */
    public static List<Routing_Configuration__mdt> getRoutingConfigHelper(String objectName,Boolean isTestRunning) {
        List<String> evaluationCriteria = new List<String>();

        if(Trigger.isExecuting) {
            if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_UPDATE))) {
                evaluationCriteria = CDdSupportConstants.updateEvaluationCriteria;
            }
            if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_INSERT))) {
                evaluationCriteria = CDdSupportConstants.insertEvaluationCriteria;
            }
        }
        else {
            evaluationCriteria = new List<String>{CDdSupportConstants.CREATED, CDdSupportConstants.UPDATED, CDdSupportConstants.CREATED_UPDATED,
                CDdSupportConstants.CREATED_UPDATED_SUBSEQUENTLY_MEET_CRITERIA, CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA};
        }

        return [SELECT  Id, DeveloperName, Customer_Type__c, Is_Active__c, Object_API_Name__c,
                        Prioritize_VIP__c, Record_Type_Id__c, Routing_Destination_Name__c,
                        Sort_Order__c, Is_Test_Record__c, Vendor_Chat_Button_Id__c,
                        Do_Vendor_Split__c, Business_Hours_Id__c, Filter_Logic__c,
                        Evaluation_Criteria__c,Owner_Queue_Name__c,Routing_Type__c,
                        (SELECT Id, DeveloperName, Compare_Type__c, Field_API_Name__c,
                                Field_Value__c, Is_Active__c, Object_API_Name__c,
                                Routing_Configuration__c,Rule_Number__c,Use_Prior_Value__c,
                                Related_Object__c,Related_Object_Field_API_Name__c
                           FROM Routing_Criteria__r WHERE Is_Active__c = TRUE),
                        (SELECT Id, Date_Time_Value__c, Date_Value__c, Field_API_Name__c,
                                String_Value__c, Boolean_Value__c, Function__c, Type__c, Decimal_Value__c
                            FROM Routing_Field_Updates__r WHERE Is_Active__c = TRUE),
                        (SELECT Id,Note__c FROM Routing_Case_Notes__r WHERE Is_Active__c = TRUE)
                   FROM Routing_Configuration__mdt WHERE Object_API_Name__c =:objectName
                    AND Is_Active__c = TRUE AND Is_Test_Record__c = :isTestRunning
                    AND Evaluation_Criteria__c IN :evaluationCriteria
                    AND Customer_Type__c IN:routingConfigCustomerType
               ORDER BY Sort_Order__c ASC];
    }

    /**
     * @author      Mahesh Chouhan
     * @date        July 2022
     * @decription  Prepare a map of fields to be updated
     * @param       routingConfig {RoutingInfo}
     * @param       record {Sobject}
     * @param       routingFieldUpdateList {List<Routing_Field_Update__mdt>}
     */
    public static void evaluateFieldUpdates(RoutingInfo routingConfig, Sobject record, List<Routing_Field_Update__mdt> routingFieldUpdateList){
        Map<String, Object> fieldUpdates = new Map<String, Object>();
        for(Routing_Field_Update__mdt routingFieldUpdate : routingFieldUpdateList){
            if(String.isNotBlank(routingFieldUpdate.Type__c)){
                String fieldType = routingFieldUpdate.Type__c;
                switch on fieldType {
                    when 'DateTime' {
                        if(routingFieldUpdate.Date_Time_Value__c != null) {
                            fieldUpdates.put(routingFieldUpdate.Field_API_Name__c, routingFieldUpdate.Date_Time_Value__c);
                        }
                    }
                    when 'Date' {
                        if(routingFieldUpdate.Date_Value__c != null) {
                            fieldUpdates.put(routingFieldUpdate.Field_API_Name__c, routingFieldUpdate.Date_Value__c);
                        }
                    }
                    when 'Decimal' {
                        if(routingFieldUpdate.Decimal_Value__c != null) {
                            fieldUpdates.put(routingFieldUpdate.Field_API_Name__c, routingFieldUpdate.Decimal_Value__c);
                        }
                    }
                    when 'String' {
                        if(String.isNotBlank(routingFieldUpdate.String_Value__c)) {
                            String value = routingFieldUpdate.String_Value__c;
                            value = CDdUtilities.replaceMergeFields(record, routingFieldUpdate.String_Value__c);

                            fieldUpdates.put(routingFieldUpdate.Field_API_Name__c, value);
                        }
                    }
                    when 'Boolean' {
                        fieldUpdates.put(routingFieldUpdate.Field_API_Name__c, routingFieldUpdate.Boolean_Value__c);
                    }
                    when 'Null' {
                        fieldUpdates.put(routingFieldUpdate.Field_API_Name__c, null);
                    }
                    when 'Function' {
                        CDdFunctionEvaluator functionEvaluator = functionEvaluatorImplementationByFunction.get(routingFieldUpdate.Function__c);
                        fieldUpdates.put(routingFieldUpdate.Field_API_Name__c, functionEvaluator.getValue(routingFieldUpdate.Function__c));
                    }
                }
            }
        }
        routingConfig.fieldUpdates = fieldUpdates;
    }

    /**
     * @author      Nayana Kapse
     * @date        Nov 2022
     * @decription  Prepare a list of Case Note
     * @param       routingConfig {RoutingInfo}
     * @param       routingFieldUpdateList {List<Routing_Case_Notes__mdt>}
     */
    public static void prepareCaseNotes(RoutingInfo routingConfig, List<Routing_Case_Notes__mdt> lstCaseRoutingNotes){
        List<String> caseNotesToAdd = new List<String>();
        for(Routing_Case_Notes__mdt routingCaseNote : lstCaseRoutingNotes){
            caseNotesToAdd.add(routingCaseNote.Note__c);
        }
        routingConfig.lstCaseNotes = caseNotesToAdd;
    }

    public class RoutingInfo {
        public Boolean standardRouting;
        public Boolean prioritizeVIP;
        public String routingDestination;
        public Boolean doVendorSplit;
        public String vendorChatButtonId;
        public String evaluationCriteria;
        public String routingConfigLog;
        //Key is Field API Name and Value is Field Value
        public Map<String, Object> fieldUpdates;
        //For Case Notes
        public List<String> lstCaseNotes;
        public Map<String,Id> mapVendorQueueMap = new Map<String,Id>();
        public String ownerQueueName;
        public String routingType;
        public Id routingConfigId;
    }
}