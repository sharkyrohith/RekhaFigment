/**
 * CDdProactiveCaseCreationHelper
 *
 * @author     Nayana
 * @date  	   Sept 2022
 * @decription helper class to evaluate if the incoming record meets issue criteria for cases and then decide if Proactive Case creation needed or not
 *             https://doordash.atlassian.net/browse/BIZS-1885
 */
public class CDdProactiveCaseCreationHelper {
  /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    private static Map<String, CDdCriterionEvaluator> criterionEvaluatorImplementationByComparison =
        new Map<String, CDdCriterionEvaluator> {
            'Equals'        => new CDdEqualsCriterionEvaluator(),
            'Not Equals'    => new CDdNotEqualsCriterionEvaluator(),
            'Actual value is one of (In)'      => new CDdContainsCriterionEvaluator(),
            'Actual value is not one of (Not In)'  => new CDdNotContainsCriterionEvaluator(),
            'Actual value contains string (Like)'          => new CDdLikeCriterionEvaluator(),
            'Actual value does not contain string (Not Like)'      => new CDdNotLikeCriterionEvaluator(),
            'Is Not Blank'  => new CDdIsNotBlankCriterionEvaluator(),
            'Is Changed'    => new CDdIsChangedCriterionEvaluator(),
            'Is Blank'      => new CDdIsBlankCriterionEvaluator()
        };

    /**
     * @author     Nayana
     * @date       Sept 2022
     * @decription checks if field value of incoming record is equal to the desired parameter
     * @return  List<Proactive_Case_Creation_Config__mdt> CMT records
    */
    public static List<Proactive_Case_Creation_Config__mdt> lstproactiveCaseConfig{
        get{
            if(lstproactiveCaseConfig==null){
                lstproactiveCaseConfig = new List<Proactive_Case_Creation_Config__mdt>();
                lstproactiveCaseConfig = getProactiveCaseConfig(Test.isRunningTest());
            }
            return lstproactiveCaseConfig;
        }
        set;
        
    }
    /**
     * @author     Nayana
     * @date       Sept 2022
     * @decription called from CDdCaseTriggerHelperV2
     * @param     newCaseList : Case List
     * @param     operationType : Operation insert/update...
     * @return  ProactiveCaseInfo : wrapper if criteria matches else null wrapper
    */
    public static void checkProactiveCaseCreationFlow(List<Case> newCaseList, System.TriggerOperation operationType) {
        List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo> lstProactiveCaseInfoWrapper = new List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo>();
        List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo> lstProactiveCaseWrapper = new List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo>();
        for (Case caseObj : newCaseList) {
            ProactiveCaseInfo wrapProactiveCase = isProactiveCaseCreation(caseObj);
            if (String.valueOf(operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.AFTER_UPDATE))) {
                if(!CDdSupportConstants.updateEvaluationCriteria.contains(wrapProactiveCase.evaluationCriteria)) {
                    continue;
                }
                if(wrapProactiveCase.evaluationCriteria.contains(CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA)){
                    Case oldCaseRecord = (Case) Trigger.oldMap.get(caseObj.Id);
                    CDdProactiveCaseCreationHelper.ProactiveCaseInfo oldWrapProactiveCase = CDdProactiveCaseCreationHelper.isProactiveCaseCreation(oldCaseRecord);

                    if(oldWrapProactiveCase.isProactiveCaseFlow == wrapProactiveCase.isProactiveCaseFlow ) {
                        continue;
                    }
                }
            }
            //need to check if need if else???
            if(wrapProactiveCase.isProactiveCaseFlow){
                if(wrapProactiveCase.isProactiveCaseInfoCreation){
                    wrapProactiveCase.originalCase = caseObj;
                    wrapProactiveCase.deliveryUUID = caseObj.DeliveryUUID__c;
                    lstProactiveCaseInfoWrapper.add(wrapProactiveCase);
                }else{
                    wrapProactiveCase.originalCase = caseObj;
                    lstProactiveCaseWrapper.add(wrapProactiveCase);
                }    
            }
        }
        if (!lstProactiveCaseInfoWrapper.isEmpty()){
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.PROACTIVE_CASE_INFO_RECORD_CREATION,
                                                        null,JSON.serialize(lstProactiveCaseInfoWrapper));
        }
        if (!lstProactiveCaseWrapper.isEmpty()){
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.PROACTIVE_CASE_CREATION,
                                                        null,JSON.serialize(lstProactiveCaseWrapper));
        }
    }
    

    /**
     * @author     Nayana
     * @date       03/07/2022
     * @decription checks if field value of incoming record is equal to the desired parameter
     * @param     salesforce record
     * @return  ProactiveCaseInfo : wrapper if criteria matches else null wrapper
    */
    public static ProactiveCaseInfo isProactiveCaseCreation(Case record) {
        ProactiveCaseInfo wrapProactiveCaseInfo = new ProactiveCaseInfo();
        CDdBooleanExpressionEvaluator expEvaluator = new CDdBooleanExpressionEvaluator();
        Boolean overallCriteriaMatch = false;
        try {
            String filterLogic;
            Map<Integer,Boolean> mapRuleNoCriterion = new Map<Integer,Boolean>();
            for (Proactive_Case_Creation_Config__mdt configRec : lstproactiveCaseConfig){
                filterLogic = '';
                mapRuleNoCriterion = new Map<Integer,Boolean>();
                overallCriteriaMatch = !configRec.Proactive_Case_Creation_Criteria__r.isEmpty();
                
                if(String.isNotBlank(configRec.Filter_Logic__c)){
                    filterLogic = configRec.Filter_Logic__c;
                }
                for (Proactive_Case_Creation_Criterion__mdt  confiCriterionVar : configRec.Proactive_Case_Creation_Criteria__r) {
                    CDdCriterionEvaluator criterionEvaluator =
                                        criterionEvaluatorImplementationByComparison.get(confiCriterionVar.Compare_Type__c);
                    //If filter logic is enabled then Criteria should have Rule number populated. elase the logical operator used will be AND
                    Boolean criterionEvaluation = criterionEvaluator.evaluateCriterion(confiCriterionVar,record);
                    if(String.isNotBlank(filterLogic) && String.isNotBlank(String.valueOf(confiCriterionVar.Rule_Number__c))){
                        mapRuleNoCriterion.put(Integer.valueOf(confiCriterionVar.Rule_Number__c),criterionEvaluation);
                    }else{
                        //run for all records before evaluating
                        overallCriteriaMatch = overallCriteriaMatch && criterionEvaluation;
                        if(!overallCriteriaMatch){
                            break;
                        }
                    }
                }
                if (String.isNotBlank(filterLogic)) {
                    overallCriteriaMatch = expEvaluator.evaluateExpression(filterLogic,mapRuleNoCriterion);
                }
                if(overallCriteriaMatch){
                    wrapProactiveCaseInfo.isProactiveCaseFlow = true;
                    wrapProactiveCaseInfo.caseType = configRec.Use_Case__c;
                    wrapProactiveCaseInfo.caseRecordType =configRec.Record_Type__c;
                    wrapProactiveCaseInfo.customerType = configRec.Customer_Type__c;
                    wrapProactiveCaseInfo.caseOrigin = configRec.Case_Origin__c;
                    wrapProactiveCaseInfo.evaluationCriteria = configRec.Evaluation_Criteria__c;
                    wrapProactiveCaseInfo.isProactiveCaseInfoCreation = configRec.Create_Proactive_Case_Info_record__c;
                    wrapProactiveCaseInfo.fieldsToCopyFromOriginalCase = configRec.Fields_to_copy_from_Original_Case__c;
                    return wrapProactiveCaseInfo;
                }
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdProactiveCaseCreationHelper','isProactiveCaseCreation',e);
        }
    	return wrapProactiveCaseInfo;
    }

    
    /**
     * @author 		Nayana
     * @date  		03/07/2022
     * @decription  gets case shadow config and criteria records
     * @param       None
     * @return   List<Proactive_Case_Creation_Config__mdt>
     */
    public static List<Proactive_Case_Creation_Config__mdt> getProactiveCaseConfig(Boolean isTestRunning) {
        List<String> evaluationCriteria = new List<String>();

        if(Trigger.isExecuting) {
            if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.AFTER_UPDATE))) {
                evaluationCriteria = CDdSupportConstants.updateEvaluationCriteria;
            }
            /*if (String.valueOf(Trigger.operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.AFTER_INSERT))) {
                evaluationCriteria = CDdSupportConstants.insertEvaluationCriteria;
            }*/
        }
        else {
            evaluationCriteria = new List<String>{CDdSupportConstants.CREATED, CDdSupportConstants.UPDATED, CDdSupportConstants.CREATED_UPDATED,
                CDdSupportConstants.CREATED_UPDATED_SUBSEQUENTLY_MEET_CRITERIA, CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA};
        }
        return [SELECT  Id, DeveloperName, Is_Active__c,Filter_Logic__c,Is_Test_Record__c,Sort_Order__c,
                                Customer_Type__c,Evaluation_Criteria__c,Record_Type__c,Use_Case__c,
                                Case_Origin__c,Create_Proactive_Case_Info_record__c,
                                Fields_to_copy_from_Original_Case__c,
                                (SELECT Id, DeveloperName, Compare_Type__c, Field_API_Name__c,
                                Field_Value__c, Is_Active__c, Object_API_Name__c,
                                Related_Object__c,Related_Object_Field_API_Name__c,
                                Proactive_Case_Creation_Config__c,Rule_Number__c,
                                Compare_Case_Sensitive__c
                                FROM Proactive_Case_Creation_Criteria__r WHERE Is_Active__c = TRUE)
                                FROM Proactive_Case_Creation_Config__mdt 
                                WHERE Is_Active__c = TRUE AND Is_Test_Record__c = :isTestRunning
                                AND Evaluation_Criteria__c IN :evaluationCriteria
                                ORDER BY Sort_Order__c ASC];
    }

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  Gets the Map with Related Object and the fields to add to the query
     * @param       objName {String}
     * @return      Map<String,List<String>> --- Map<Related Object Name,List<Related Object Field API Names>>
     */
    public static Map<String,List<String>> getRelatedObjectFieldsMap() {
        Map<String,List<String>> relatedObjectFieldsMap = new Map<String,List<String>>();

        for (Proactive_Case_Creation_Criterion__mdt rc :
            [SELECT Id, Related_Object__c,Related_Object_Field_API_Name__c
               FROM Proactive_Case_Creation_Criterion__mdt
              WHERE Is_Active__c = true
                AND Proactive_Case_Creation_Config__r.Is_Active__c = true
                AND Proactive_Case_Creation_Config__r.Is_Test_Record__c = :Test.isRunningTest()
                AND Related_Object__c != NULL
                AND Related_Object_Field_API_Name__c != null]) {
            if (!relatedObjectFieldsMap.containsKey(rc.Related_Object__c)) {
                relatedObjectFieldsMap.put(rc.Related_Object__c,new List<String>());
            }
            relatedObjectFieldsMap.get(rc.Related_Object__c).add(rc.Related_Object_Field_API_Name__c.toLowerCase());
        }
        return relatedObjectFieldsMap;
    }

     /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  Wrapper class
     */
    public class ProactiveCaseInfo {
        public Boolean isProactiveCaseFlow=false;
        public String caseType;
        public String caseRecordType;
        public String customerType;
        public String caseOrigin;
        public String evaluationCriteria;
        public Boolean isProactiveCaseInfoCreation = false;
        public String fieldsToCopyFromOriginalCase;
        public Case originalCase;
        public String deliveryUUID;
    }
}