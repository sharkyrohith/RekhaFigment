/**
 * CDdAdhocCriteriaEvaluator
 *
 * @author      Sahil
 * @date        2022-02-28
 * @decription  evaluate mission control criteria for adhoc requests
 *
 *              Raju L - This class was added as an interim fix while we built the cross-object logic (BIZS-1076). However, i do
 *                       see benefit in keeping this class and its call from CDdIssueBasedRoutingHelper for any urgent needs in the future.
 *                       Keeping the switch code there with the test cmt.
 */
public class CDdAdhocCriteriaEvaluator {
     /**
     * @author Sahil
     * @date  2022-02-28
     * @decription gets routing config and criteria records
     * @param
     * @return
     */
    public static Boolean evaluateCriterion(Routing_Configuration__mdt routingConfig, SObject record) {
        switch on routingConfig.DeveloperName {
            when 'Test_Live_Delivery_Support'  {
                return record != null;
            }
        }
        return true;
    }
}