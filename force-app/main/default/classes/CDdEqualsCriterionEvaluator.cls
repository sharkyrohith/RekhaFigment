/**
 * CDdEqualsCriterionEvaluator
 *
 * @author      Sahil
 * @date        2021-05-05
 * @decription  Class which extends CDdCriterionEvaluator to evaluate Equals condition.
 *              BIZS-1076 - Updated the class to evaluate related entities.
 *
 */
public class CDdEqualsCriterionEvaluator extends CDdCriterionEvaluator{
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author     Sahil
     * @date  2021-05-05
     * @decription checks if field value of incoming record is equal to the desired parameter
     * @param   field name, field value, record
     * @return  boolean if there is a match
     */
    public override Boolean evaluateCriterion(String fieldName, String fieldValue, SObject record) {
        if (String.isBlank(fieldName) || String.isBlank(fieldValue) || record == null) {
            return false;
        }
        String actualFieldValue = String.valueOf(record.get(fieldName));
        return String.isNotBlank(actualFieldValue) && actualFieldValue.equals(fieldValue);
    }

    /**
     * @author      Raju Lakshman
     * @date        August 2022
     * @decription checks if field value of incoming record does not contain value from metadata
     * @param   field name, field value, record, caseSensitive
     * @return  boolean if field value contains metadata value
     */
    public override Boolean evaluateCriterion(String fieldName, String fieldValue, SObject record, Boolean caseSensitive) {
        if (String.isBlank(fieldName) || String.isBlank(fieldValue) || record == null) {
            return false;
        }
        String actualFieldValue = getActualFieldValue(fieldName,record);
        return String.isNotBlank(actualFieldValue) && (caseSensitive ? actualFieldValue.equals(fieldValue) : actualFieldValue.equalsIgnoreCase(fieldValue));
    }

    /**
     * @author      Raju
     * @date        March 2022
     * @decription  Checks for the related objects field matches is equal to the desired parameter
     * @param   routingCriterion {Routing_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if there is a match
     */
    public override Boolean evaluateCriterion(Routing_Criterion__mdt routingCriterion, SObject record) {
        if (record == null) {
            return false;
        }

        if(String.isBlank(routingCriterion.Related_Object__c) || String.isBlank(routingCriterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(routingCriterion.Field_API_Name__c,routingCriterion.Field_Value__c,record);
        }
        String actualFieldValue = getActualFieldValue(routingCriterion,record);
        return String.isNotBlank(actualFieldValue) && actualFieldValue.equals(routingCriterion.Field_Value__c);
    }

    /**
     * @author      Raju
     * @date        August 2022
     * @decription  checks if related objects field is like the value setup on metadata
     * @param   criterion {Case_Transfer_Validation_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Case record being evaluated
     * @return  boolean if there is a match
     */
    public override Boolean evaluateCriterion(Case_Transfer_Validation_Criterion__mdt criterion, Case record) {
        if (record == null) {
            return false;
        }

        // quick validation on incoming record data
        if (String.isBlank(criterion.Related_Object__c) || String.isBlank(criterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(criterion.Field_API_Name__c,criterion.Field_Value__c,record,criterion.Compare_Case_Sensitive__c);
        }

        // validation for 'Case Notes'
        if (criterion.Related_Object__c == 'Case Notes') {
            return (validateCaseNotes(record.Id,criterion.Compare_Type__c,criterion.Related_Object_Field_API_Name__c,criterion.Field_Value__c,criterion.Compare_Case_Sensitive__c));
        }

        // get actual and compare to values, to make comparison
        String actualFieldValue = getRelatedObjectFieldValue(criterion,record);	
        String compareToValue = getCompareToValue(criterion,record);

        // make final comparison
        return String.isNotBlank(actualFieldValue) && (criterion.Compare_Case_Sensitive__c ? actualFieldValue.equals(compareToValue) : actualFieldValue.equalsIgnoreCase(compareToValue));
    }


    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  checks if related objects field is like the value setup on metadata
     * @param   criterion {Proactive_Case_Creation_Config__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Case record being evaluated
     * @return  boolean if there is a match
     */
    public override Boolean evaluateCriterion(Proactive_Case_Creation_Criterion__mdt criterion, Case record) {
        if (record == null) {
            return false;
        }

        if (String.isBlank(criterion.Related_Object__c) || String.isBlank(criterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(criterion.Field_API_Name__c,criterion.Field_Value__c,record,criterion.Compare_Case_Sensitive__c);
        }
        String actualFieldValue = getRelatedObjectFieldValue(criterion,record);
        String compareToValue = getCompareToValue(criterion.Field_Value__c,record);
        return String.isNotBlank(actualFieldValue) && (criterion.Compare_Case_Sensitive__c ? actualFieldValue.equals(compareToValue) : actualFieldValue.equalsIgnoreCase(compareToValue));
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  checks if related objects field is like the value setup on metadata
     * @param   workflowCriterion {Workflow_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - SObject record being evaluated
     * @return  boolean if there is a match
     */
    public override Boolean evaluateCriterion(Workflow_Criterion__mdt workflowCriterion, SObject record) {
        if (record == null) {
            return false;
        }

        if(String.isBlank(workflowCriterion.Related_Object__c) || String.isBlank(workflowCriterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(workflowCriterion.Field_API_Name__c,workflowCriterion.Field_Value__c,record);
        }
        String actualFieldValue = getActualFieldValue(workflowCriterion,record);
        return String.isNotBlank(actualFieldValue) && actualFieldValue.equals(workflowCriterion.Field_Value__c);
    }
}