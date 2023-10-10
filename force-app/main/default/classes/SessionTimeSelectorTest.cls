@isTest
public without sharing class SessionTimeSelectorTest {
    @TestSetup
    static void makeData(){
        List<Case> caseRecord = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        insert caseRecord;

        Session_Time__c st1 = new Session_Time__c(
            Case__c  = caseRecord[0].Id,
            Date__c = System.today(),
            Duration__c = 200,
            Agent__c = UserINFO.getUserId(),
            Manual_Entry__c  = false,
            Name = 'Test Class Record 1',
            Case_Status__c = 'Open',
            Omni_Status__c = 'Available'
        );

        Session_Time__c st2 = new Session_Time__c(
            Case__c  = caseRecord[0].Id,
            Date__c = System.today(),
            Duration__c = 100,
            Agent__c = UserINFO.getUserId(),
            Manual_Entry__c  = false,
            Name = 'Test Class Record 2',
            Case_Status__c = 'Open',
            Omni_Status__c = 'Available'
        );
        insert new List<Session_Time__c>{st1,st2};
    }

    public class TestContext
    {
        public Id caseId;
        public Map<Id,Session_Time__c> sessionTimeMap;
        public TestContext(){
            caseId = [SELECT Id FROM Case WHERE CreatedDate =Today].Id;
            sessionTimeMap = new Map<Id,Session_Time__c>([SELECT Id,Duration__c FROM Session_Time__c]);
        }
    }

    @IsTest
    static void testSelectById(){
        TestContext tc = new TestContext();
        List<Session_Time__c> st = SessionTimeSelector.newInstance().selectById(tc.sessionTimeMap.keySet());
        Assert.areEqual(tc.sessionTimeMap.keySet().size(), st.size(), 'Did not get expected number of session time records');
    }

    @IsTest
    static void testSelectByCaseId(){
        TestContext tc = new TestContext();
        List<Session_Time__c> st = SessionTimeSelector.newInstance().selectByCaseId(tc.caseId);
        Assert.areEqual(tc.sessionTimeMap.keySet().size(), st.size(), 'Did not get expected number of session time records');
    }

    @IsTest
    static void testGetTotalTimeForCaseId(){
        TestContext tc = new TestContext();
        List<Aggregate> result = SessionTimeSelector.newInstance().getTotalTimeForCaseId(new Set<Id>{tc.caseId});
        Assert.areEqual(1, result.size(), 'Did not get expected number of aggregate records');
        Assert.areEqual(300,result[0].get('TotalDuration'), 'Total Duration not as expected');
    }
}