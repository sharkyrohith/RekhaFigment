/**
 * CDdIsBlankCriterionEvaluator
 *
 * @author      Mahesh Chouhan
 * @date        17-06-2022
 * @decription  BIZS-1413 - Class which extends CDdCriterionEvaluator. It will check if field is blank
 *
 */
public class CDdIsBlankCriterionEvaluator extends CDdCriterionEvaluator{
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author      Mahesh Chouhan
     * @date        17-06-2022
     * @decription checks if field is blank
     * @param   field name, record
     * @return  boolean if field is blank true otherwise false
     */
    public override Boolean evaluateCriterion(String fieldName, SObject record) {
        if (String.isBlank(fieldName) || record == null) {
            return false;
        }
        String actualFieldValue = record.get(fieldName) != null ? String.valueOf(record.get(fieldName)) : CDdCoreConstants.BLANK_STRING;
        return String.isBlank(actualFieldValue);
    }

    /**
     * @author      Mahesh Chouhan
     * @date        17-06-2022
     * @decription  checks if field of incoming record of related objects is blank
     * @param   routingCriterion {Routing_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if field is blank true otherwise false
     */
    public override Boolean evaluateCriterion(Routing_Criterion__mdt routingCriterion, SObject record) {
        if (record == null) {
            return false;
        }

        if (String.isBlank(routingCriterion.Related_Object__c) || String.isBlank(routingCriterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(routingCriterion.Field_API_Name__c,record);
        }

        String actualFieldValue = getActualFieldValue(routingCriterion,record);
        return String.isBlank(actualFieldValue);
    }

    /**
     * @author      Raju
     * @date        August 2022
    * @decription  checks if field of incoming record of related objects is blank
     * @param   criterion {Case_Transfer_Validation_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if field is blank true otherwise false
     */
    public override Boolean evaluateCriterion(Case_Transfer_Validation_Criterion__mdt criterion, Case record) {
        if (record == null) {
            return false;
        }
        if (String.isBlank(criterion.Related_Object__c) || String.isBlank(criterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(criterion.Field_API_Name__c,record);
        }
        if (criterion.Related_Object__c == 'Case Notes') {
            return (validateCaseNotes(record.Id,criterion.Compare_Type__c,criterion.Related_Object_Field_API_Name__c,criterion.Field_Value__c,criterion.Compare_Case_Sensitive__c));
        }
        String actualFieldValue = getRelatedObjectFieldValue(criterion,record);
        return String.isBlank(actualFieldValue);
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
            return evaluateCriterion(criterion.Field_API_Name__c,record);
        }
        String actualFieldValue = getRelatedObjectFieldValue(criterion,record);
        return String.isBlank(actualFieldValue);
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  checks if related objects field is like the value setup on metadata
     * @param   workflowCriterion {Workflow_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Sobject record being evaluated
     * @return  boolean if there is a match
     */
    public override Boolean evaluateCriterion(Workflow_Criterion__mdt workflowCriterion, SObject record) {
        if (record == null) {
            return false;
        }

        if (String.isBlank(workflowCriterion.Related_Object__c) || String.isBlank(workflowCriterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(workflowCriterion.Field_API_Name__c,record);
        }

        String actualFieldValue = getActualFieldValue(workflowCriterion,record);
        return String.isBlank(actualFieldValue);
    }
}