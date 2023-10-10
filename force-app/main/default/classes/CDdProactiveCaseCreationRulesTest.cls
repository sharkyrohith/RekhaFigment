/**
 * @author      Nayana
 * @date        Sept 2022
 * @decription Test class to validate all active Proactive Case Creation Custom Metadata
 *             Note - Test class methods calls a generic public static list, in case this method would need to be exposed to the UI/Execute anonymous
 */
@isTest(seeAllData=false)
public class CDdProactiveCaseCreationRulesTest {
    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CDdProactiveCaseCreationHelper.class
    };

    public static List<Proactive_Case_Creation_Config__mdt> configList = CDdProactiveCaseCreationHelper.getProactiveCaseConfig(false);

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  Check for rule number is present for all calidation criteria and it's unique across given validation configuration
     * @param       None
     * @return      List<String> errors
    */
    public static List<String> checkForValidationCriteriaRuleNumberHelper(){
        List<String> errors = new List<String>();
		Set<Id> setCriteriaRuleNoBlank = new Set<Id>();
        for (Proactive_Case_Creation_Config__mdt config : configList){
            Set<Decimal> setRuleNumbers = new Set<Decimal>();
            for (Proactive_Case_Creation_Criterion__mdt criterion : config.Proactive_Case_Creation_Criteria__r) {
                if(criterion.Rule_Number__c == null){
                    setCriteriaRuleNoBlank.add(criterion.Id);
                }
                if (setRuleNumbers.contains(criterion.Rule_Number__c)) {
                    errors.add('Rule number can\'t be duplicate: ' + criterion.Id);
                }
                setRuleNumbers.add(criterion.Rule_Number__c);
            }
        }
        if(!setCriteriaRuleNoBlank.isEmpty()){
            errors.add('Rule number can\'t be blank: '+setCriteriaRuleNoBlank);
        }
        return errors;
    }

    //Test method to test unique across given validation configuration
    static testMethod void checkForValidationCriteriaRuleNumber() {
        List<String> errors = checkForValidationCriteriaRuleNumberHelper();
        if (!errors.isEmpty()) {
            system.assert(false,errors[0]);
        }
    }

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  test to check if any extra active rule numbers which is not part of filter logic
     *              If expression is 1 AND (2 OR 3) and we have criteria with rule numbers 1,2,3,4. Then rule 4 is extra
     * @param       None
     * @return      List<String> errors
    */

    public static List<String> validateExtraRuleNumberHelper() {
        List<String> errors = new List<String>();
        for (Proactive_Case_Creation_Config__mdt config: configList){
            if (String.isBlank(config.Filter_Logic__c)){
                continue;
            }
            String filterLogic = config.Filter_Logic__c.replaceAll('[^\\d]',' ');
            List<String> setRuleNoOnConfig = filterLogic.split(' ');
            Set<String> setRuleNoOnCriteria = new Set<String>();
            for (Proactive_Case_Creation_Criterion__mdt criterion : config.Proactive_Case_Creation_Criteria__r) {
                if (criterion.Rule_Number__c != null){
                    setRuleNoOnCriteria.add(String.valueOf(Integer.valueOf(criterion.Rule_Number__c)));
                }
            }
            setRuleNoOnCriteria.removeAll(setRuleNoOnConfig);
            if (!setRuleNoOnCriteria.isEmpty()){
                errors.add('There are extra active rules ' + setRuleNoOnCriteria + ' which are not used in Expression for: ' + config.Id);
            }
        }
        return errors;
    }

	//Test method to check if any extra active rule numbers which is not part of filter logic
    static testMethod void validateExtraRuleNumber() {
        List<String> errors = validateExtraRuleNumberHelper();
        if (!errors.isEmpty()) {
            system.assert(false,errors[0]);
        }
    }

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  test to check if expression rule numbers are present in routing criteria
     *              If expression is 1 AND (2 OR 3) AND 4 and we have criteria with rule numbers 1,2,3. Then rule 4 is missing
     * @param       None
     * @return      List<String> errors
    */
    public static List<String> validateMissingRuleCriteriaHelper() {
        List<String> errors = new List<String>();
        for (Proactive_Case_Creation_Config__mdt config: configList){
        	if (String.isBlank(config.Filter_Logic__c)) {
                continue;
            }
            Set<String> setRuleNoOnConfig = new Set<String>();
            String filterLogic = config.Filter_Logic__c.replaceAll('[^\\d]',' ');
            for (String ruleNo : filterLogic.split(' ')) {
                if (ruleNo.isNumeric()){
                    setRuleNoOnConfig.add(ruleNo);
                }
            }
            Set<String> setRuleNoOnCriteria = new Set<String>();
            for (Proactive_Case_Creation_Criterion__mdt criterion : config.Proactive_Case_Creation_Criteria__r) {
                if (criterion.Rule_Number__c!=null) {
                    setRuleNoOnCriteria.add(String.valueOf(Integer.valueOf(criterion.Rule_Number__c)));
                }
            }
            setRuleNoOnConfig.removeAll(setRuleNoOnCriteria);
            if (!setRuleNoOnConfig.isEmpty()) {
                errors.add('Rule number ' + setRuleNoOnConfig+ ' missing which is used in Expression for: ' + config.Id);
            }
        }
        return errors;
    }

    //Test method to check if expression rule numbers are present in routing criteria
    static testMethod void validateMissingRuleCriteria() {
        List<String> errors = validateMissingRuleCriteriaHelper();
        if (!errors.isEmpty()) {
            system.assert(false,errors[0]);
        }
    }

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  test to check if expression is having all parantheses added correctly
     * @param       None
     * @return      List<String> errors
    */
    public static List<String> validateExpressionParenthesesHelper() {
        List<String> errors = new List<String>();
        Set<Id> setInvalidExpression = new Set<Id>();
        for(Proactive_Case_Creation_Config__mdt config: configList){
            if (String.isBlank(config.Filter_Logic__c)) {
                continue;
            }
            if ((CDdUtilities.getNumberOfCharacterInString(config.Filter_Logic__c,'(') - CDdUtilities.getNumberOfCharacterInString(config.Filter_Logic__c,')')) != 0 ){
                setInvalidExpression.add(config.Id);
            }
        }
        if (!setInvalidExpression.isEmpty()) {
            errors.add('Please check : ' + setInvalidExpression + ' for missing parantheses.');
        }
        return errors;
    }

    //Test method to check if expression is having all paranthese added correctly
    static testMethod void validateExpressionParentheses() {
        List<String> errors = validateExpressionParenthesesHelper();
        if (!errors.isEmpty()) {
            system.assert(false,errors[0]);
        }
    }

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  test to check if Case Field API Names are valid
     * @param       None
     * @return      String error
    */
    public static String validateFieldAPINameHelper() {
        Set<String> fieldApiNames = new Set<String>();
        String error = CDdCoreConstants.BLANK_STRING;
        for(Proactive_Case_Creation_Criterion__mdt rec:[SELECT Id, Field_API_Name__c
        FROM Proactive_Case_Creation_Criterion__mdt
       WHERE Is_Active__c = true
         AND Proactive_Case_Creation_Config__r.Is_Active__c = true
         AND Proactive_Case_Creation_Config__r.Is_Test_Record__c = false
         AND Related_Object__c = NULL
         AND Field_API_Name__c != null]) {
            fieldApiNames.add(rec.Field_API_Name__c.toLowerCase());
        }

        String queryFields = String.join(new List<String>(fieldApiNames),CDdCoreConstants.DELIMITER_COMMA);
        try {
            List<Case> objList = Database.query('SELECT ' + queryFields  + ' FROM Case LIMIT 1');
        } catch (Exception e) {
            error = 'Invalid field found for Case object \n\n == Fields (one or more of these fields are not valid): ' + queryFields;
        }
        return error;
    }

    //Test method to check if Case Field API Names in CMT are valid
    static testMethod void validateFieldAPIName() {
        String error = validateFieldAPINameHelper();
        if (String.isNotBlank(error)) {
            system.assert(false,error);
        }
    }

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  test to Validate field API Names of related object routing criterions.
     * @param       None
     * @return      List<String> error
    */
    public static List<String> validateRelatedObjectFieldAPINamesHelper() {
        List<String> errors = new List<String>();
        Map<String,Set<String>> relatedObjectFieldsMap = new Map<String,Set<String>>();
        for(Proactive_Case_Creation_Criterion__mdt rec: [SELECT Id, Related_Object__c,Related_Object_Field_API_Name__c
                                                        FROM Proactive_Case_Creation_Criterion__mdt
                                                        WHERE Is_Active__c = true
                                                        AND Proactive_Case_Creation_Config__r.Is_Active__c = true
                                                        AND Proactive_Case_Creation_Config__r.Is_Test_Record__c = false
                                                        AND Related_Object__c IN ('Account','Contact','Opportunity')
                                                        AND Related_Object_Field_API_Name__c != null]) {
            String relatedObject = rec.Related_Object__c;
            if (!relatedObjectFieldsMap.containsKey(relatedObject)) {
                relatedObjectFieldsMap.put(relatedObject,new Set<String>());
            }
            relatedObjectFieldsMap.get(relatedObject).add(rec.Related_Object_Field_API_Name__c.toLowerCase());
        }

        // SOQL in for loop is fine, max is 6 - the number of objects which are supported by related objects framework.
        for (String objectName : relatedObjectFieldsMap.keySet()) {
            List<String> fields = new List<String>(relatedObjectFieldsMap.get(objectName));
            String queryFields = String.join(fields,CDdCoreConstants.DELIMITER_COMMA);
            try {
                List<SObject> objList = Database.query('SELECT ' + queryFields  + ' FROM ' + objectName + ' LIMIT 1');
            } catch (Exception e) {
                errors.add('Invalid field found for related object logic -- Object:' + objectName + '\n\n == Fields (one or more of these fields are not valid): ' + queryFields);
            }
        }
        return errors;
    }

    //test to Validate field API Names of related object routing criterions.
    static testMethod void validateRelatedObjectFieldAPINames() {
        List<String> errors = validateRelatedObjectFieldAPINamesHelper();
        if (!errors.isEmpty()) {
            system.assert(false,errors[0]);
        }
    }
}