/**
 * CDdMissionControlExpressionTest
 *
 * @author     Nayana
 * @date  March 2022
 * @decription Test class to validate all active Mission control Custom Metadata
 */
@isTest(seeAllData=false)
public class CDdMissionControlValidationTest {
    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CDdIssueBasedRoutingHelper.class
    };

    private static final String TEST_OBJECT_CASE = 'Case';
    private static final String TEST_OBJECT_LCT = 'LiveChatTranscript';
    public static List<Routing_Configuration__mdt> lstRoutingConfig{
        get {
           lstRoutingConfig = new List<Routing_Configuration__mdt>();
           lstRoutingConfig = CDdIssueBasedRoutingHelper.getRoutingConfig(TEST_OBJECT_CASE);
           lstRoutingConfig.addAll(CDdIssueBasedRoutingHelper.getRoutingConfig(TEST_OBJECT_LCT));
            return lstRoutingConfig;
        }
        set;
    }

    /**
     * @author     Nayana
     * @date   2022 March
     * @decription Check for rule number is present for all routing criteria and it's unique across given routing configuration
     * @param   None
     * @return  None
    */
    public static void checkForRoutingCriteriaRuleNumberHelper(){
		Set<Decimal> setRuleNumbers = new Set<Decimal>();
        Set<Id> setCriteriaRuleNoBlank = new Set<Id>();
        for(Routing_Configuration__mdt routingConfigVar: lstRoutingConfig){
            setRuleNumbers = new Set<Decimal>();
            for (Routing_Criterion__mdt routingCriterionVar : routingConfigVar.Routing_Criteria__r) {
                //Check for Rule Number not blank
                if(routingCriterionVar.Rule_Number__c==null){
                    setCriteriaRuleNoBlank.add(routingCriterionVar.Id);
                }
                if(setRuleNumbers.contains(routingCriterionVar.Rule_Number__c)){
                    System.assert(false, 'Rule number can\'t be duplicate: '+routingCriterionVar.Id);
                }
                setRuleNumbers.add(routingCriterionVar.Rule_Number__c);
            }
        }
        if(!setCriteriaRuleNoBlank.isEmpty()){
            System.assert(false, 'Rule number can\'t be blank: '+setCriteriaRuleNoBlank);
        }
    }

    //Test method to test unique across given routing configuration
    static testMethod void checkForRoutingCriteriaRuleNumber() {
      checkForRoutingCriteriaRuleNumberHelper();
    }

     /**
     * @author     Nayana
     * @date   2022 March
     * @decription test to check if any extra active rule numbers which is not part of filter logic
     * If expression is 1 AND (2 OR 3) and we have criteria with rule numbers 1,2,3,4. Then rule 4 is extra
     * @param   None
     * @return  None
    */
    public static void validateExtraRuleNumberHelper() {
        Set<String> setRuleNoOnCriteria = new Set<String>();
        List<String> setRuleNoOnConfig = new List<String>();
        for(Routing_Configuration__mdt routingConfigVar: lstRoutingConfig){
        	if(String.isNotBlank(routingConfigVar.Filter_Logic__c)){
                String filterLogic = routingConfigVar.Filter_Logic__c.replaceAll('[^\\d]',' ');
                setRuleNoOnConfig = filterLogic.split(' ');
                setRuleNoOnCriteria = new Set<String>();
                for (Routing_Criterion__mdt routingCriterionVar : routingConfigVar.Routing_Criteria__r) {
                    if(routingCriterionVar.Rule_Number__c!=null){
                        setRuleNoOnCriteria.add(String.valueOf(Integer.valueOf(routingCriterionVar.Rule_Number__c)));
                    }
                }
                for(String str: setRuleNoOnConfig){
                    if(setRuleNoOnCriteria.contains(str)){
                        setRuleNoOnCriteria.remove(str);
                    }
                }
                if(!setRuleNoOnCriteria.isEmpty()){
                    System.assert(false,'There are extra active rules ' + setRuleNoOnCriteria+ ' which are not used in Expression for: '+routingConfigVar.Id);
                }else{
                    System.assert(true,'Good rule: '+routingConfigVar.Id);
                }
            }
        }
    }

	//Test method to check if any extra active rule numbers which is not part of filter logic
    static testMethod void validateExtraRuleNumber() {
        validateExtraRuleNumberHelper();
    }


     /**
     * @author     Nayana
     * @date   2022 March
     * @decription test to check if expression rule numbers are present in routing criteria
     * If expression is 1 AND (2 OR 3) AND 4 and we have criteria with rule numbers 1,2,3. Then rule 4 is missing
     * @param   None
     * @return  None
    */
    public static void validateMissinRuleCriteriaHelper() {
        Set<String> setRuleNoOnCriteria = new Set<String>();
        Set<String> setRuleNoOnConfig = new Set<String>();
        for(Routing_Configuration__mdt routingConfigVar: lstRoutingConfig){
        	if(String.isNotBlank(routingConfigVar.Filter_Logic__c)){
                setRuleNoOnConfig = new Set<String>();
                String filterLogic = routingConfigVar.Filter_Logic__c.replaceAll('[^\\d]',' ');
                for(String ruleNo : filterLogic.split(' ')){
                    if(ruleNo.isNumeric()){
                        setRuleNoOnConfig.add(ruleNo);
                    }
                }
                setRuleNoOnCriteria = new Set<String>();
                for (Routing_Criterion__mdt routingCriterionVar : routingConfigVar.Routing_Criteria__r) {
                    if(routingCriterionVar.Rule_Number__c!=null){
                        setRuleNoOnCriteria.add(String.valueOf(Integer.valueOf(routingCriterionVar.Rule_Number__c)));
                    }
                }
                for(String str: setRuleNoOnCriteria){
                    if(setRuleNoOnConfig.contains(str)){
                        setRuleNoOnConfig.remove(str);
                    }
                }
                if(!setRuleNoOnConfig.isEmpty()){
                    System.assert(false,'Rule number ' + setRuleNoOnConfig+ ' missing which is used in Expression for: '+routingConfigVar.Id);
                }else{
                    System.assert(true,'Good rule: '+routingConfigVar.Id);
                }
            }
        }
    }

    //Test method to check if expression rule numbers are present in routing criteria
    static testMethod void validateMissinRuleCriteria() {
        validateMissinRuleCriteriaHelper();
    }

    /**
     * @author     Nayana
     * @date   2022 March
     * @decription test to check if expression is having all paranthese added correctly
     * @param   None
     * @return  None
    */
    public static void validateExpressionParenthesisHelper() {
        Set<String> setOpening = new Set<String>{'('};
        Set<String> setClosing = new Set<String>{')'};
        Integer bracetCnt = 0;
        Set<Id> setInvalidExpression = new Set<Id>();
        for(Routing_Configuration__mdt routingConfigVar: lstRoutingConfig){
            bracetCnt = 0;
            if(String.isNotBlank(routingConfigVar.Filter_Logic__c)){
                for (String character : routingConfigVar.Filter_Logic__c.split(' ')) {
                    if (setOpening.contains(character)) {
                        bracetCnt++;
                    }else if(setClosing.contains(character)){
                        bracetCnt--;
                    }
                }
            }
            if(bracetCnt == 0 ){
                System.assert(true,'Good rule: '+routingConfigVar.Id);
            }else{
                setInvalidExpression.add(routingConfigVar.Id);
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
     * @author     Nayana
     * @date   2022 March
     * @decription test to check if Field_Name__r.QualifiedApiName = Field_API_Name__c or not
     * @param   None
     * @return  None
    */
    public static void validateFieldAPINameHelper() {
        Set<Id> setInvalidAPIName = new Set<Id>();
        List<Routing_Configuration__mdt> lstAllActiveConfig = [SELECT  Id, Is_Active__c, Object_API_Name__c,
                                                             (SELECT Id, DeveloperName, Compare_Type__c, Field_API_Name__c,
                                                             Field_Value__c, Field_Name__r.QualifiedApiName,
                                                             Is_Active__c, Object_API_Name__c,Routing_Configuration__c
                                                             FROM Routing_Criteria__r WHERE Is_Active__c = TRUE)
                                                             FROM Routing_Configuration__mdt
                                                             WHERE Is_Active__c = TRUE AND Is_Test_Record__c = FALSE
                                                             ORDER BY Sort_Order__c ASC];
        for(Routing_Configuration__mdt routingConfigVar: lstAllActiveConfig){
            for (Routing_Criterion__mdt routingCriterionVar : routingConfigVar.Routing_Criteria__r) {
                if(routingCriterionVar.Field_Name__r.QualifiedApiName!=routingCriterionVar.Field_API_Name__c){
                    setInvalidAPIName.add(routingCriterionVar.Id);
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
     * @author     Raju
     * @date       2022 April
     * @decription test to Validate field API Names of related object routing criterions.
     * @param   None
     * @return  None
    */
    public static void validateRelatedObjectFieldAPINamesHelper() {

        Map<String,Set<String>> relatedObjectFieldsMap = new Map<String,Set<String>>();

        for (Routing_Criterion__mdt rc :
            [SELECT Id, Related_Object__c,Related_Object_Field_API_Name__c
               FROM Routing_Criterion__mdt
              WHERE Is_Active__c = true
                AND Routing_Configuration__r.Is_Active__c = true
                AND Routing_Configuration__r.Is_Test_Record__c = false
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

    //test to Validate field API Names of related object routing criterions.
    static testMethod void validateRelatedObjectFieldAPINames() {
        validateRelatedObjectFieldAPINamesHelper();
    }

    /**
     * @author     Mahesh
     * @date       2022 July
     * @decription Validate Evaluation Criteria on Routing Configuration for 'Is Changed' Compare Type on Routing Criteria.
     * @param   None
     * @return  None
    */
    public static void validateRoutingConfigForIsChangedCompareTypeHelper() {

        Set<String> invalidRoutingConfigNames = new Set<String>();

        for (Routing_Criterion__mdt rc :
            [SELECT Id, Routing_Configuration__r.Evaluation_Criteria__c, Routing_Configuration__c
               FROM Routing_Criterion__mdt
              WHERE Is_Active__c = true
                AND Compare_Type__c = 'Is Changed'
                AND Routing_Configuration__r.Is_Active__c = true
                AND Routing_Configuration__r.Is_Test_Record__c = false]) {
                    if(rc.Routing_Configuration__r.Evaluation_Criteria__c.equals(CDdSupportConstants.CREATED))
                        invalidRoutingConfigNames.add(rc.Routing_Configuration__c);
        }

        if(invalidRoutingConfigNames.isEmpty()) {
            System.assert(true, 'All Routing Configurations are valid');
        }
        else {
            System.assert(false, 'Evaluation Criteria on these Routing Configuration should not be "Created" : ' + String.join(new List<String>(invalidRoutingConfigNames), ','));
        }
    }

    //test to Validate Evaluation Criteria on Routing Configuration for 'Is Changed' Compare Type on Routing Criterion.
    static testMethod void validateRoutingConfigForIsChangedCompareType() {
        validateRoutingConfigForIsChangedCompareTypeHelper();
    }

    /**
     * @author     Mahesh
     * @date       2022 July
     * @decription Validate Evaluation Criteria on Routing Configuration if 'Use Prior Value' is checked on Routing Criterion
     * @param   None
     * @return  None
    */
    public static void validateRoutingConfigForUsePriorValueHelper() {

        Set<String> invalidEvaluationCriteria = new Set<String>{CDdSupportConstants.CREATED, CDdSupportConstants.CREATED_UPDATED_SUBSEQUENTLY_MEET_CRITERIA,
            CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA};
        Set<String> invalidRoutingConfigNames = new Set<String>();

        for (Routing_Criterion__mdt rc :
            [SELECT Id, Routing_Configuration__c, Routing_Configuration__r.Evaluation_Criteria__c
               FROM Routing_Criterion__mdt
              WHERE Is_Active__c = true
                AND Use_Prior_Value__c = true
                AND Routing_Configuration__r.Is_Active__c = true
                AND Routing_Configuration__r.Is_Test_Record__c = false]) {
                    if(invalidEvaluationCriteria.contains(rc.Routing_Configuration__r.Evaluation_Criteria__c))
                        invalidRoutingConfigNames.add(rc.Routing_Configuration__c);
        }

        if(invalidRoutingConfigNames.isEmpty()) {
            System.assert(true, 'All Routing Configurations are valid');
        }
        else {
            System.assert(false, 'Evaluation Criteria on these Routing Configuration must be "Updated" or "Created and Updated" as "Use Prior Value" is checked on Routing Criterion : '
                + String.join(new List<String>(invalidRoutingConfigNames), ','));
        }
    }

    //test to Validate Evaluation Criteria on Routing Configuration if 'Use Prior Value' is checked on Routing Criterion
    static testMethod void validateRoutingConfigForUsePriorValue() {
        validateRoutingConfigForUsePriorValueHelper();
    }


    /**
     * @author     Nayana
     * @date       2023 July
     * @decription Validate Owner queue exists on Routing Configuration if vendor split = false
     * @param   None
     * @return  None
    */
    public static void validateRoutingConfigForOwnerQueueNameFieldNonVendorSplit() {
        List<Routing_Configuration__mdt> lstAllActiveConfig = [SELECT  Id,Owner_Queue_Name__c,(SELECT Id
                                                                FROM Routing_Field_Updates__r)
                                                                FROM Routing_Configuration__mdt
                                                                WHERE  Object_API_Name__c= : TEST_OBJECT_CASE
                                                                AND Do_Vendor_Split__c = FALSE
                                                                AND Is_Active__c = TRUE AND Is_Test_Record__c = FALSE
                                                                ORDER BY Sort_Order__c ASC];
        Map<Id,String> mapConfOwner = new Map<Id,String>();
        for(Routing_Configuration__mdt rConfig : lstAllActiveConfig){
            if(String.isBlank(rConfig.Owner_Queue_Name__c) && rConfig.Routing_Field_Updates__r.size()==0){
                System.assert(false,'Please check : '+rConfig.Id + ' as owner is not assigned.');
            }else if(String.isNotBlank(rConfig.Owner_Queue_Name__c)){
                Id qId = mapQueueDevNameId.get(rConfig.Owner_Queue_Name__c);
                if(qId==null){
                    System.assert(false,'Please check : '+rConfig.Id + ' Owner_Queue_Name__c queue not found. ' + rConfig.Owner_Queue_Name__c);
                }
            }
        }
    }

    //Test method to check if queue API name is valid
    static testMethod void validateOwnerForNonVendorSplit() {
        validateRoutingConfigForOwnerQueueNameFieldNonVendorSplit();
    }

    /**
     * @author     Nayana
     * @date       2023 July
     * @decription Validate Owner queue exists on Routing Configuration if vendor split = false
     * @param   None
     * @return  None
    */
    public static void validateRoutingConfigForOwnerQueueNameFieldVendorSplit() {
        List<Routing_Configuration__mdt> lstAllActiveConfig = [SELECT  Id,Owner_Queue_Name__c
                                                                FROM Routing_Configuration__mdt
                                                                WHERE  Object_API_Name__c= : TEST_OBJECT_CASE
                                                                AND Do_Vendor_Split__c = TRUE
                                                                AND Is_Active__c = TRUE AND Is_Test_Record__c = FALSE
                                                                AND Routing_Type__c = null
                                                                ORDER BY Sort_Order__c ASC];
        Set<String> vendorNames = CDdCrossSkillingFinderController.mapVendorUserMapping.keySet();
        Map<Id,String> mapConfOwner = new Map<Id,String>();
        for(Routing_Configuration__mdt rConfig : lstAllActiveConfig){
            if(String.isBlank(rConfig.Owner_Queue_Name__c)){
                System.assert(false,'Please check : '+rConfig.Id + ' as owner is not assigned.');
            }else{
                try{
                    Map<String,Object> mapFieldValue = (Map<String,Object>) JSON.deserializeUntyped(rConfig.Owner_Queue_Name__c);
                    for(String vendorName : mapFieldValue.keySet()){
                        if(vendorNames.contains(vendorName)){
                            Id vendorQueueId = mapQueueDevNameId.get(String.valueOf(mapFieldValue.get(vendorName)));
                            if(vendorQueueId==null){
                                System.assert(false,'Please check : '+rConfig.Id + ' Owner_Queue_Name__c queue not found ' + String.valueOf(mapFieldValue.get(vendorName)));
                            }
                        }else{
                            System.assert(false,'Please check : '+rConfig.Id + ' vendorName not found ' + vendorName);
                        }
                    }
                }catch(Exception e){
                    System.assert(false,'Please check : '+rConfig.Id + ' JSON format looks bad');
                }
            }
        }
    }

    //Test method to check if JSON and queue name/vendor name valid
    static testMethod void validateOwnerForVendorSplit() {
        validateRoutingConfigForOwnerQueueNameFieldVendorSplit();
    }

    /**
     * @author     Nayana
     * @date       2023 July
     * @decription Validate Owner queue exists on Routing Configuration if vendor split = false
     * @param   None
     * @return  None
    */
    public static void validateSkillNamesCorrect() {
        Set<String> allSkills = new Set<String>();
        Set<Id> setInvalidSkills = new Set<Id>();
        for (Skill objSkill : SkillsSelector.newInstance().selectAllSkills()){
            allSkills.add( objSkill.DeveloperName);
        }
        for(Routing_Attribute_Defination__mdt aDef : [SELECT  Id,Skill__c,Routing_Configuration__c
                                                    FROM Routing_Attribute_Defination__mdt
                                                    WHERE Is_Active__c = TRUE AND Routing_Configuration__r.Is_Test_Record__c = FALSE]){
            if(!allSkills.contains(aDef.Skill__c)){
                setInvalidSkills.add(aDef.Id);
            }
        }
        if(!setInvalidSkills.isEmpty()){
            System.assert(false, 'Not valid skill added here: '+setInvalidSkills);
        }
    }

    //Test method to check if JSON and queue name/vendor name valid
    static testMethod void validateSkillNames() {
        validateSkillNamesCorrect();
    }

    private static Map<String,Id> mapQueueDevNameId{
        get{
            if(mapQueueDevNameId==null){
                mapQueueDevNameId = new Map<String,Id>();
                for(Group grp : [SELECT Id,DeveloperName,(SELECT SobjectType FROM QueueSobjects WHERE
                                SobjectType =: TEST_OBJECT_CASE) FROM Group WHERE Type = 'Queue']){
                    mapQueueDevNameId.put(grp.DeveloperName,grp.Id);
                }
            }
            return mapQueueDevNameId;
        }
        set;
    }
}