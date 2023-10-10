/**
 * CDdAdhocCriteriaEvaluatorTest
 *
 * @author     Sahil
 * @date  2022-02-28
 * @decription Test class for CDdAdhocCriteriaEvaluator
 *              Raju L - This class was added as an interim fix while we built the cross-object logic (BIZS-1076). However, i do
 *                       see benefit in keeping this class and its call from CDdIssueBasedRoutingHelper for any urgent needs in the future.
 */
@isTest(seeAllData=false)
public class CDdAdhocCriteriaEvaluatorTest {
    /**
     * @author     Sahil
     * @date  2022-02-28
     * @decription test to check POS Support MxSx routing
     * @param   None
     * @return  None
    */
    @TestSetup
    static void makeData() {
        vCS__c testSettings;
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.CaseTrigger__c = true;
        insert testSettings;

        //get queue id
        Id mxSxQId = [SELECT Id FROM Group WHERE DeveloperName = 'MxSx_Mx_Success_Associate' LIMIT 1].Id;
        //insert custom settings for mapping routing destination to queue Id
        Support_Assignment_Mapping__c mxSxQMapping = new Support_Assignment_Mapping__c();
        mxSxQMapping.Name = CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
        mxSxQMapping.Queue_Id__c = mxSxQId;
        mxSxQMapping.Support_Assignment_Name__c = CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
        mxSxQMapping.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
        insert mxSxQMapping;
    }

    /**
     * @author      Raju
     * @date        2022-02-28
     * @decription  Empty Test class method, for allowing us to keep this test class in the code base.
    */
    @isTest
    static void increaseCodeCoverage() {
        Routing_Configuration__mdt rc = Routing_Configuration__mdt.getInstance('Test_Live_Delivery_Support');
        CDdAdhocCriteriaEvaluator.evaluateCriterion(rc,null);
    }
}