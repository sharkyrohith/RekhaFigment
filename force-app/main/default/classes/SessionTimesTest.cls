/**
 * @author  Raju L
 * @date    August 2023
 * @description This is the test class for SessionTimes
 */
@isTest
public class SessionTimesTest {
	@isTest
    private static void testWhenClassInstantiatesThenRun() {
        List<Session_Time__c> recs = new List<Session_Time__c>();
        //Interface Instance Creation Call
        SessionTimes.newInstance(recs);
        //Default Constructor Call
        SessionTimes notification = new SessionTimes(recs);
        //fflib_IDomainConstructor call
        SessionTimes.Constructor constructorObject = new SessionTimes.Constructor();
        constructorObject.construct(recs);
        Assert.areNotEqual(
            SessionTimes.newInstance(recs),
            notification,
            'These objects should not be similar'
        );
    }

    @isTest
    private static void testCoverage() {
        Set<Id> ids = new Set<Id>();
        ids.add(Fake.generateId(Session_Time__c.SObjectType));
        //Interface Instance Creation Call
        SessionTimes.newInstance(ids);
        List<Session_Time__c> recs = SessionTimes.newInstance(ids).getRecords();
        Assert.areEqual(0, recs.size(), 'Should return empty list');
        List<Session_Time__c> recs2 = SessionTimes.newInstance(ids).getSessionTimes();
        Assert.areEqual(0, recs2.size(), 'Should return empty list');
    }
}