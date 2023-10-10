/**
 * @author      Raju L
 * @date        August 2022
 * @decription  Class which extends CDdCriterionEvaluator. It will check if case note exists
 *
 */
public class CDdCaseNoteExistsCriterionEvaluator extends CDdCriterionEvaluator{
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
     * @return  boolean - If Case Notes exist
     */
    public override Boolean evaluateCriterion(Case_Transfer_Validation_Criterion__mdt criterion, Case record) {
        if (record == null) {
            return false;
        }
        return (validateCaseNotes(record.Id,criterion.Compare_Type__c,criterion.Related_Object_Field_API_Name__c,criterion.Field_Value__c,criterion.Compare_Case_Sensitive__c));
    }
}