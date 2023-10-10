/**
 * @author      Raju L
 * @date        August 2022
 * @decription  Class which extends CDdCriterionEvaluator. It will check if AC Contact Trace has/does not have the transfer queue
 *
 */
public class CDdAcConTraceHasQueueCriterionEvaluator extends CDdCriterionEvaluator{
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author      Raju
     * @date        August 2022
     * @decription  checks if related objects field is like the value setup on metadata
     * @param   criterion {Case_Transfer_Validation_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Case record being evaluated
     * @return  boolean - If Transfer queue exists in AC Contact Trace Records
     */
    public override Boolean evaluateCriterion(Case_Transfer_Validation_Criterion__mdt criterion, Case record) {
        if (record == null) {
            return false;
        }

        Set<String> transferQueues = CDdCaseTriggerOptimizationHelper.getAcContactTraceTransfers(record.Id);
        if (transferQueues == null) {
            transferQueues = new Set<String>();
        }

        String fieldValue = String.isNotBlank(criterion.Field_Value__c) && BOOLEAN_FIELD_VALUE_OPTIONS.contains(criterion.Field_Value__c.toLowerCase()) ? criterion.Field_Value__c.toLowerCase() : 'true';
        return fieldValue == 'true' ? transferQueues.contains(criterion.AC_Contact_Trace_Queue_Name__c) : !transferQueues.contains(criterion.AC_Contact_Trace_Queue_Name__c);
    }
}