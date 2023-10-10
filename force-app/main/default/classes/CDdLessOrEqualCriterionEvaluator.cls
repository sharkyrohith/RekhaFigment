/**
 * CDdLessOrEqualCriterionEvaluator
 *
 * @author      Nayana
 * @date        August 2022
 * @decription  BIZS-1716 - Class which extends CDdCriterionEvaluator. It will evaluate <=
 *
 */
public class CDdLessOrEqualCriterionEvaluator extends CDdCriterionEvaluator{ 
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author     Nayana
     * @date   August 2022
     * @decription checks if field value of incoming record is <= to the desired parameter
     * @param   field name, field value, record
     * @return  boolean based on evaluation
     */
    public override Boolean evaluateCriterion(String fieldName, String fieldValue, SObject record) {
        if (String.isBlank(fieldName) || String.isBlank(fieldValue) || record == null) {
            return false;
        }
        String actualFieldValue = String.valueOf(record.get(fieldName));
        return String.isNotBlank(actualFieldValue) && Integer.valueOf(actualFieldValue) <= Integer.valueOf(fieldValue);
    }

    /**
     * @author      Nayana
     * @date        August 2022
     * @decription  Checks for the related objects field matches is <= to the desired parameter
     * @param   routingCriterion {Routing_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean based on evaluation
     */
    public override Boolean evaluateCriterion(Routing_Criterion__mdt routingCriterion, SObject record) {
        if (record == null) {
            return false;
        }

        if (String.isBlank(routingCriterion.Related_Object__c) || String.isBlank(routingCriterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(routingCriterion.Field_API_Name__c,routingCriterion.Field_Value__c,record);
        }
        String actualFieldValue = getActualFieldValue(routingCriterion,record);
        return String.isNotBlank(actualFieldValue) && Integer.valueOf(actualFieldValue) <= Integer.valueOf(routingCriterion.Field_Value__c);
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  Checks for the related objects field matches is <= to the desired parameter
     * @param   workflowCriterion {Workflow_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean based on evaluation
     */
    public override Boolean evaluateCriterion(Workflow_Criterion__mdt workflowCriterion, SObject record) {
        if (record == null) {
            return false;
        }

        if (String.isBlank(workflowCriterion.Related_Object__c) || String.isBlank(workflowCriterion.Related_Object_Field_API_Name__c)) {
            return evaluateCriterion(workflowCriterion.Field_API_Name__c,workflowCriterion.Field_Value__c,record);
        }
        String actualFieldValue = getActualFieldValue(workflowCriterion,record);
        return String.isNotBlank(actualFieldValue) && Integer.valueOf(actualFieldValue) <= Integer.valueOf(workflowCriterion.Field_Value__c);
    }
}