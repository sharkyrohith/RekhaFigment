/**
 * CDdCaseDetailCreationHelper
 *
 * @author     Nayana
 * @date  	   03/07/2022
 * @decription helper class to evaluate if the incoming record meets issue criteria for cases and then auto create Case Shadow record
 *              https://doordash.atlassian.net/browse/BIZS-1051
 */
public class CDdCaseDetailCreationHelper {
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
            'Is Blank'      => new CDdIsBlankCriterionEvaluator()
        };
	@TestVisible
    private static List<Case_Shadow_Creation_Config__mdt> configsForTest = new List<Case_Shadow_Creation_Config__mdt>();
    private static List<Case_Shadow_Creation_Config__mdt> lstShadowConfig = new List<Case_Shadow_Creation_Config__mdt>();
   
    /**
     * @author     Nayana
     * @date       03/07/2022
     * @decription checks if field value of incoming record is equal to the desired parameter
     * @param     salesforce record
     * @return  Boolean : true if criteria matches else false
    */
    public static Boolean isAutoCreateShadowRecord(Case record) {
        CDdBooleanExpressionEvaluator expEvaluator = new CDdBooleanExpressionEvaluator();
        Boolean overallCriteriaMatch = false;
        try {
            String filterLogic;
            Map<Integer,Boolean> mapRuleNoCriterion = new Map<Integer,Boolean>();
            if(record.RecordTypeId!=null && record.Case_Detail__c==null){
                for (Case_Shadow_Creation_Config__mdt configRec : getCaseShadowConfig(CDdGenericTriggerOptimizationHelper.getCaseRecordTypeDevNameById(record.RecordTypeId))){
                    filterLogic = '';
                    mapRuleNoCriterion = new Map<Integer,Boolean>();
                    overallCriteriaMatch = !configRec.Case_Shadow_Creation_Criteria__r.isEmpty();
                    
                    if(String.isNotBlank(configRec.Filter_Logic__c)){
                        filterLogic = configRec.Filter_Logic__c;
                    }
                    for (Case_Shadow_Creation_Criterion__mdt  confiCriterionVar : configRec.Case_Shadow_Creation_Criteria__r) {
                        CDdCriterionEvaluator criterionEvaluator =
                                            criterionEvaluatorImplementationByComparison.get(confiCriterionVar.Compare_Type__c);
                        //If filter logic is enabled then Criteria should have Rule number populated. elase the logical operator used will be AND
                        if(String.isNotBlank(filterLogic) && String.isNotBlank(String.valueOf(confiCriterionVar.Rule_Number__c))){
                            overallCriteriaMatch = criterionEvaluator.evaluateCriterion(confiCriterionVar.Field_API_Name__c,
                            confiCriterionVar.Field_Value__c,record);
                            mapRuleNoCriterion.put(Integer.valueOf(confiCriterionVar.Rule_Number__c),overallCriteriaMatch);
                        }else{
                             //run for all records before evaluating
                            overallCriteriaMatch = overallCriteriaMatch &&
                            criterionEvaluator.evaluateCriterion(confiCriterionVar.Field_API_Name__c,
                            confiCriterionVar.Field_Value__c,
                            record);
                        }
                    }
                    if(overallCriteriaMatch){
                        return overallCriteriaMatch;
                    }
                }
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdCaseDetailCreationHelper','isAutoCreateShadowRecord',e);
        }
    	return overallCriteriaMatch;
    }
    
    
    /**
     * @author 		Nayana
     * @date  		03/07/2022
     * @decription  gets case shadow config and criteria records
     * @param       None
     * @return   List<Case_Shadow_Creation_Config__mdt>
     */
    private static List<Case_Shadow_Creation_Config__mdt> getCaseShadowConfig(String caseRTAPIName) {
        if (!configsForTest.isEmpty()) {
            //this means the current context is test. return test data in the list
            return configsForTest;
        }
        //check configs list and return - otherwise query from database
        if (!lstShadowConfig.isEmpty()) {
            return lstShadowConfig;
        } else {
            //get records from database and return the listq
            lstShadowConfig = [SELECT  Id, DeveloperName, Is_Active__c,Filter_Logic__c,Is_Test_Record__c,Sort_Order__c,
                                (SELECT Id, DeveloperName, Compare_Type__c, Field_API_Name__c,
                                Field_Value__c, Is_Active__c, Object_API_Name__c,
                                Case_Shadow_Creation_Config__c,Rule_Number__c
                                FROM Case_Shadow_Creation_Criteria__r WHERE Is_Active__c = TRUE)
                                FROM Case_Shadow_Creation_Config__mdt 
                                WHERE Is_Active__c = TRUE AND Is_Test_Record__c = FALSE AND Record_Type_Name__c = :caseRTAPIName
                                ORDER BY Sort_Order__c ASC];
            //return the list
            return lstShadowConfig;
        }
    }
}