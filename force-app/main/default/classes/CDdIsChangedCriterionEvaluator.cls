/**
 * CDdIsChangedCriterionEvaluator
 *
 * @author      Mahesh Chouhan
 * @date        22-06-2022
 * @decription  BIZS-1411 - Class which extends CDdCriterionEvaluator. It will check if record's field is changed.
 *
 */
public class CDdIsChangedCriterionEvaluator extends CDdCriterionEvaluator{
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author      Mahesh Chouhan
     * @date        22-06-2022
     * @decription checks if record's field is changed
     * @param   field record
     * @return  boolean if record's field is changed then true otherwise false
     */
    public override Boolean evaluateCriterion(String fieldName, SObject record) {
        if (String.isBlank(fieldName) || record == null) {
            return false;
        }

        String priorValue = null;
        if(Trigger.oldMap != null && Trigger.oldMap.containsKey(record.Id)) {
            priorValue = String.valueOf(Trigger.oldMap.get(record.Id).get(fieldName));
        }
        String actualFieldValue = record.get(fieldName) != null ? String.valueOf(record.get(fieldName)) : null;

        return actualFieldValue != null && priorValue != null && !actualFieldValue.equals(priorValue);
    }

    /**
     * @author      Mahesh Chouhan
     * @date        22-06-2022
     * @decription  checks if Parent record's field is changed
     * @param   routingCriterion {Routing_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if Parent record's field is changed then true otherwise false
     */
    public override Boolean evaluateCriterion(Routing_Criterion__mdt routingCriterion, SObject record) {
        if (record == null ||(Trigger.isInsert != null && Trigger.isInsert)) {
            return false;
        }

        return evaluateCriterion(routingCriterion.Field_API_Name__c, record);
    }

    /**
     * @author      Raju
     * @date        August 2022
     * @decription  checks if Parent record's field is changed
     * @param   criterion {Case_Transfer_Validation_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if Parent record's field is changed then true otherwise false
     */
    public override Boolean evaluateCriterion(Case_Transfer_Validation_Criterion__mdt criterion, Case record) {
        if (record == null ||(Trigger.isInsert != null && Trigger.isInsert)) {
            return false;
        }

        return evaluateCriterion(criterion.Field_API_Name__c, record);
    }

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  checks if Parent record's field is changed
     * @param   criterion {Case_Transfer_Validation_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if Parent record's field is changed then true otherwise false
     */
    public override Boolean evaluateCriterion(Proactive_Case_Creation_Criterion__mdt criterion, Case record) {
        if (record == null ||(Trigger.isInsert != null && Trigger.isInsert)) {
            return false;
        }

        return evaluateCriterion(criterion.Field_API_Name__c, record);
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  checks if Parent record's field is changed
     * @param   workflowCriterion {Workflow_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if Parent record's field is changed then true otherwise false
     */
    public override Boolean evaluateCriterion(Workflow_Criterion__mdt workflowCriterion, SObject record) {
        if (record == null ||(Trigger.isInsert != null && Trigger.isInsert)) {
            return false;
        }

        return evaluateCriterion(workflowCriterion.Field_API_Name__c, record);
    }
}