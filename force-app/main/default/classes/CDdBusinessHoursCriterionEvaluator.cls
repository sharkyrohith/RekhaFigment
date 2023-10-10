/**
 * @author      Raju L
 * @date        August 2022
 * @decription  Class which extends CDdCriterionEvaluator. It will check if business hours is within
 *
 */
public class CDdBusinessHoursCriterionEvaluator extends CDdCriterionEvaluator{
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
     * @return  boolean - If business hours is within
     */
    public override Boolean evaluateCriterion(Case_Transfer_Validation_Criterion__mdt criterion, Case record) {
        if (record == null) {
            return false;
        }

        String fieldValue = String.isNotBlank(criterion.Field_Value__c) && BOOLEAN_FIELD_VALUE_OPTIONS.contains(criterion.Field_Value__c.toLowerCase()) ?
            criterion.Field_Value__c.toLowerCase() : 'true';

        Id businessHoursId = String.isNotBlank(criterion.Business_Hours_Id__c) ? Id.valueOf(criterion.Business_Hours_Id__c) :
            CDdGenericTriggerOptimizationHelper.getDefaultBusinessHour()?.Id;

        Boolean retVal = fieldValue != 'true';
        if (businessHoursId != null && !Test.isRunningTest()) {
            retVal = (fieldValue == 'true' ? BusinessHours.isWithin(businessHoursId, system.now()) : !BusinessHours.isWithin(businessHoursId, system.now()));
        }
        return retVal;
    }
}