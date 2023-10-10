/**
 * @author      Mahesh Chouhan
 * @date        Jan 2023
 * @decription Test class to validate all active project horizon (workflow rule framework) Custom Metadata
 */
@isTest(seeAllData=false)
public class CDdWorkflowRulesValidationTest {

    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CDdWorkflowConfigEvaluator.class
    };

    private static final String TEST_OBJECT_CASE = 'Case';
    public static List<Workflow_Configuration__mdt> lstWorkflowConfig{
        get {
           lstWorkflowConfig = new List<Workflow_Configuration__mdt>();
           lstWorkflowConfig = CDdWorkflowConfigEvaluator.getWorkflowConfigHelper(TEST_OBJECT_CASE, false);
           return lstWorkflowConfig;
        }
        set;
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription Check for rule number is present for all workflow criteria and it's unique across given workflow configuration
     * @param   None
     * @return  None
    */
    public static void checkForWorkflowCriteriaRuleNumberHelper(){
		Set<Decimal> setRuleNumbers = new Set<Decimal>();
        Set<Id> setCriteriaRuleNoBlank = new Set<Id>();
        for(Workflow_Configuration__mdt workflowConfigVar: lstWorkflowConfig){
            setRuleNumbers = new Set<Decimal>();
            for (Workflow_Criterion__mdt workflowCriterionVar : workflowConfigVar.Workflow_Criteria__r) {
                //Check for Rule Number not blank
                if(workflowCriterionVar.Rule_Number__c==null){
                    setCriteriaRuleNoBlank.add(workflowCriterionVar.Id);
                }
                if(setRuleNumbers.contains(workflowCriterionVar.Rule_Number__c)){
                    System.assert(false, 'Rule number can\'t be duplicate: '+workflowCriterionVar.Id);
                }
                setRuleNumbers.add(workflowCriterionVar.Rule_Number__c);
            }
        }
        if(!setCriteriaRuleNoBlank.isEmpty()){
            System.assert(false, 'Rule number can\'t be blank: '+setCriteriaRuleNoBlank);
        }
    }

    //Test method to test unique across given Workflow Configuration
    static testMethod void checkForWorkflowCriteriaRuleNumber() {
      checkForWorkflowCriteriaRuleNumberHelper();
    }

     /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription test to check if any extra active rule numbers which is not part of filter logic
     * If expression is 1 AND (2 OR 3) and we have criteria with rule numbers 1,2,3,4. Then rule 4 is extra
     * @param   None
     * @return  None
    */
    public static void validateExtraRuleNumberHelper() {
        Set<String> setRuleNoOnCriteria = new Set<String>();
        List<String> setRuleNoOnConfig = new List<String>();
        for(Workflow_Configuration__mdt workflowConfigVar: lstWorkflowConfig){
        	if(String.isNotBlank(workflowConfigVar.Filter_Logic__c)){
                String filterLogic = workflowConfigVar.Filter_Logic__c.replaceAll('[^\\d]',' ');
                setRuleNoOnConfig = filterLogic.split(' ');
                setRuleNoOnCriteria = new Set<String>();
                for (Workflow_Criterion__mdt workflowCriterionVar : workflowConfigVar.Workflow_Criteria__r) {
                    if(workflowCriterionVar.Rule_Number__c!=null){
                        setRuleNoOnCriteria.add(String.valueOf(Integer.valueOf(workflowCriterionVar.Rule_Number__c)));
                    }
                }
                for(String str: setRuleNoOnConfig){
                    if(setRuleNoOnCriteria.contains(str)){
                        setRuleNoOnCriteria.remove(str);
                    }
                }
                if(!setRuleNoOnCriteria.isEmpty()){
                    System.assert(false,'There are extra active rules ' + setRuleNoOnCriteria+ ' which are not used in Expression for: '+workflowConfigVar.Id);
                }else{
                    System.assert(true,'Good rule: '+workflowConfigVar.Id);
                }
            }
        }
    }

	//Test method to check if any extra active rule numbers which is not part of filter logic
    static testMethod void validateExtraRuleNumber() {
        validateExtraRuleNumberHelper();
    }


     /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription test to check if expression rule numbers are present in Workflowcriteria
     * If expression is 1 AND (2 OR 3) AND 4 and we have criteria with rule numbers 1,2,3. Then rule 4 is missing
     * @param   None
     * @return  None
    */
    public static void validateMissinRuleCriteriaHelper() {
        Set<String> setRuleNoOnCriteria = new Set<String>();
        Set<String> setRuleNoOnConfig = new Set<String>();
        for(Workflow_Configuration__mdt workflowConfigVar: lstWorkflowConfig){
        	if(String.isNotBlank(workflowConfigVar.Filter_Logic__c)){
                setRuleNoOnConfig = new Set<String>();
                String filterLogic = workflowConfigVar.Filter_Logic__c.replaceAll('[^\\d]',' ');
                for(String ruleNo : filterLogic.split(' ')){
                    if(ruleNo.isNumeric()){
                        setRuleNoOnConfig.add(ruleNo);
                    }
                }
                setRuleNoOnCriteria = new Set<String>();
                for (Workflow_Criterion__mdt workflowCriterionVar : workflowConfigVar.Workflow_Criteria__r) {
                    if(workflowCriterionVar.Rule_Number__c!=null){
                        setRuleNoOnCriteria.add(String.valueOf(Integer.valueOf(workflowCriterionVar.Rule_Number__c)));
                    }
                }
                for(String str: setRuleNoOnCriteria){
                    if(setRuleNoOnConfig.contains(str)){
                        setRuleNoOnConfig.remove(str);
                    }
                }
                if(!setRuleNoOnConfig.isEmpty()){
                    System.assert(false,'Rule number ' + setRuleNoOnConfig+ ' missing which is used in Expression for: '+workflowConfigVar.Id);
                }else{
                    System.assert(true,'Good rule: '+workflowConfigVar.Id);
                }
            }
        }
    }

    //Test method to check if expression rule numbers are present in Workflowcriteria
    static testMethod void validateMissinRuleCriteria() {
        validateMissinRuleCriteriaHelper();
    }

    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription test to check if expression is having all paranthese added correctly
     * @param   None
     * @return  None
    */
    public static void validateExpressionParenthesisHelper() {
        Set<String> setOpening = new Set<String>{'('};
        Set<String> setClosing = new Set<String>{')'};
        Integer bracetCnt = 0;
        Set<Id> setInvalidExpression = new Set<Id>();
        for(Workflow_Configuration__mdt workflowConfigVar: lstWorkflowConfig){
            bracetCnt = 0;
            if(String.isNotBlank(workflowConfigVar.Filter_Logic__c)){
                for (String character : workflowConfigVar.Filter_Logic__c.split(' ')) {
                    if (setOpening.contains(character)) {
                        bracetCnt++;
                    }else if(setClosing.contains(character)){
                        bracetCnt--;
                    }
                }
            }
            if(bracetCnt == 0 ){
                System.assert(true,'Good rule: '+workflowConfigVar.Id);
            }else{
                setInvalidExpression.add(workflowConfigVar.Id);
            }
        }
        if(!setInvalidExpression.isEmpty()){
            System.assert(false,'Please check : '+setInvalidExpression + ' for missing paranthese.');
        }
    }

    //Test method to check if expression is having all paranthese added correctly
    static testMethod void validateExpressionParenthesis() {
        validateExpressionParenthesisHelper();
    }

    //Field API NAme check as validation rule was removed
    /**
     * @author     Mahesh Chouhan
     * @date       Jan 2023
     * @decription test to check if Field_Name__r.QualifiedApiName = Field_API_Name__c or not
     * @param   None
     * @return  None
    */
    public static void validateFieldAPINameHelper() {
        Set<Id> setInvalidAPIName = new Set<Id>();
        List<Workflow_Configuration__mdt> lstAllActiveConfig = [SELECT  Id, Is_Active__c, Object_API_Name__c,
                                                             (SELECT Id, DeveloperName, Compare_Type__c, Field_API_Name__c,
                                                             Field_Value__c, Field_Name__r.QualifiedApiName,
                                                             Is_Active__c, Object_API_Name__c,Workflow_Configuration__c
                                                             FROM Workflow_Criteria__r WHERE Is_Active__c = TRUE)
                                                             FROM Workflow_Configuration__mdt
                                                             WHERE Is_Active__c = TRUE AND Is_Test_Record__c = FALSE];
        for(Workflow_Configuration__mdt workflowConfigVar: lstAllActiveConfig){
            for (Workflow_Criterion__mdt workflowCriterionVar : workflowConfigVar.Workflow_Criteria__r) {
                if(workflowCriterionVar.Field_Name__r.QualifiedApiName!=workflowCriterionVar.Field_API_Name__c){
                    setInvalidAPIName.add(workflowCriterionVar.Id);
                }
            }
        }

        if(!setInvalidAPIName.isEmpty()){
            System.assert(false,'Please check : '+setInvalidAPIName + 'Field API Name is not correct.');
        }
    }

    //Test method to check if Field_Name__r.QualifiedApiName = Field_API_Name__c or not
    static testMethod void validateFieldAPIName() {
        validateFieldAPINameHelper();
    }

    /**
     * @author     Mahesh
     * @date       Jan 2023
     * @decription test to Validate field API Names of related object Workflow criterions.
     * @param   None
     * @return  None
    */
    public static void validateRelatedObjectFieldAPINamesHelper() {

        Map<String,Set<String>> relatedObjectFieldsMap = new Map<String,Set<String>>();

        for (Workflow_Criterion__mdt rc :
            [SELECT Id, Related_Object__c,Related_Object_Field_API_Name__c
               FROM Workflow_Criterion__mdt
              WHERE Is_Active__c = true
                AND Workflow_Configuration__r.Is_Active__c = true
                AND Workflow_Configuration__r.Is_Test_Record__c = false
                AND Related_Object__c != NULL AND Related_Object__c!='DispatchCallout' AND Related_Object__c!='Current User']) {
            if (!relatedObjectFieldsMap.containsKey(rc.Related_Object__c)) {
                relatedObjectFieldsMap.put(rc.Related_Object__c,new Set<String>());
            }
            relatedObjectFieldsMap.get(rc.Related_Object__c).add(rc.Related_Object_Field_API_Name__c.toLowerCase());
        }

        // SOQL in for loop is fine, max is 4 - the number of objects which are supported by related objects framework.
        for (String objectName : relatedObjectFieldsMap.keySet()) {
            List<String> fields = new List<String>(relatedObjectFieldsMap.get(objectName));
            String queryFields = String.join(fields,CDdCoreConstants.DELIMITER_COMMA);
            try {
                List<SObject> objList = Database.query('SELECT ' + queryFields  + ' FROM ' + objectName + ' LIMIT 1');
                System.assert(true,'All fields are valid');
            } catch (Exception e) {
                System.assert(false,'Invalid field found for related object logic -- Object:' + objectName + '\n\n == Fields (one or more of these fields are not valid): ' + queryFields);
            }
        }
    }

    //test to Validate field API Names of related object Workflow criterions.
    static testMethod void validateRelatedObjectFieldAPINames() {
        validateRelatedObjectFieldAPINamesHelper();
    }

    /**
     * @author     Mahesh
     * @date       Jan 2023
     * @decription Validate Evaluation Criteria on Workflow Configuration for 'Is Changed' Compare Type on WorkflowCriteria.
     * @param   None
     * @return  None
    */
    public static void validateRoutingConfigForIsChangedCompareTypeHelper() {

        Set<String> invalidRoutingConfigNames = new Set<String>();

        for (Workflow_Criterion__mdt rc :
            [SELECT Id, Workflow_Configuration__r.Evaluation_Criteria__c, Workflow_Configuration__c
               FROM Workflow_Criterion__mdt
              WHERE Is_Active__c = true
                AND Compare_Type__c = 'Is Changed'
                AND Workflow_Configuration__r.Is_Active__c = true
                AND Workflow_Configuration__r.Is_Test_Record__c = false]) {
                    if(rc.Workflow_Configuration__r.Evaluation_Criteria__c.equals(CDdSupportConstants.CREATED))
                        invalidRoutingConfigNames.add(rc.Workflow_Configuration__c);
        }

        if(invalidRoutingConfigNames.isEmpty()) {
            System.assert(true, 'All Workflow Configurations are valid');
        }
        else {
            System.assert(false, 'Evaluation Criteria on these Workflow Configuration should not be "Created" : ' + String.join(new List<String>(invalidRoutingConfigNames), ','));
        }
    }

    //test to Validate Evaluation Criteria on Workflow Configuration for 'Is Changed' Compare Type on Workflow Criterion.
    static testMethod void validateRoutingConfigForIsChangedCompareType() {
        validateRoutingConfigForIsChangedCompareTypeHelper();
    }

    /**
     * @author     Mahesh
     * @date       Jan 2023
     * @decription Validate Evaluation Criteria on Workflow Configuration if 'Use Prior Value' is checked on Workflow Criterion
     * @param   None
     * @return  None
    */
    public static void validateRoutingConfigForUsePriorValueHelper() {

        Set<String> invalidEvaluationCriteria = new Set<String>{CDdSupportConstants.CREATED, CDdSupportConstants.CREATED_UPDATED_SUBSEQUENTLY_MEET_CRITERIA,
            CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA};
        Set<String> invalidRoutingConfigNames = new Set<String>();

        for (Workflow_Criterion__mdt rc :
            [SELECT Id, Workflow_Configuration__c, Workflow_Configuration__r.Evaluation_Criteria__c
               FROM Workflow_Criterion__mdt
              WHERE Is_Active__c = true
                AND Use_Prior_Value__c = true
                AND Workflow_Configuration__r.Is_Active__c = true
                AND Workflow_Configuration__r.Is_Test_Record__c = false]) {
                    if(invalidEvaluationCriteria.contains(rc.Workflow_Configuration__r.Evaluation_Criteria__c))
                        invalidRoutingConfigNames.add(rc.Workflow_Configuration__c);
        }

        if(invalidRoutingConfigNames.isEmpty()) {
            System.assert(true, 'All Workflow Configurations are valid');
        }
        else {
            System.assert(false, 'Evaluation Criteria on these Workflow Configuration must be "Updated" or "Created and Updated" as "Use Prior Value" is checked on Workflow Criterion : '
                + String.join(new List<String>(invalidRoutingConfigNames), ','));
        }
    }

    //test to Validate Evaluation Criteria on Workflow Configuration if 'Use Prior Value' is checked on Workflow Criterion
    static testMethod void validateRoutingConfigForUsePriorValue() {
        validateRoutingConfigForUsePriorValueHelper();
    }
}