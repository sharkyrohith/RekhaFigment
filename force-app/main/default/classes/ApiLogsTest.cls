/**
 * @author  Raju
 * @date    Jan 2023
 * @description This is the test class for ApiLogs
 */
@isTest
public class ApiLogsTest {
    @isTest
    private static void testWhenClassInstantiatesThenRun() {
        List<API_Log__c> recList = new List<API_Log__c>();
        //Interface Instance Creation Call
        ApiLogs.newInstance(recList);
        //Default Constructor Call
        ApiLogs obj = new ApiLogs(recList);
        //fflib_IDomainConstructor call
        ApiLogs.Constructor constructorObject = new ApiLogs.Constructor();
        constructorObject.construct(recList);
        System.assertNotEquals(
            ApiLogs.newInstance(recList),
            obj,
            'These objects should not be similar'
        );
    }
}