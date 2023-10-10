/**
 * CDdIsNewCriterionEvaluator
 *
 * @author      Mahesh Chouhan
 * @date        21-06-2022
 * @decription  BIZS-1411 - Class which extends CDdCriterionEvaluator. It will check if record is newly created
 *
 */
public class CDdIsNewCriterionEvaluator extends CDdCriterionEvaluator{
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author      Mahesh Chouhan
     * @date        21-06-2022
     * @decription  checks if record is newly created
     * @param   routingCriterion {Routing_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if record is newly created then true otherwise false
     */
    public override Boolean evaluateCriterion(Routing_Criterion__mdt routingCriterion, SObject record) {
        if (record == null) {
            return false;
        }
        return Trigger.isInsert != null ? Trigger.isInsert : false;
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  checks if record is newly created
     * @param   workflowCriterion {Workflow_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  boolean if record is newly created then true otherwise false
     */
    public override Boolean evaluateCriterion(Workflow_Criterion__mdt workflowCriterion, SObject record) {
        if (record == null) {
            return false;
        }
        return Trigger.isInsert != null ? Trigger.isInsert : false;
    }
}