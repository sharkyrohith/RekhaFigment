@isTest
public class CDdAttributeBasedRoutingTest {
    @testSetup
    static void testSetup() {
        Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        insert testAcct;
        Routing_Configuration__mdt mc = Routing_Configuration__mdt.getInstance('TEST_DO_NOT_DELETE_AttributeBasedRoute');

        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        testCaseList[0].AccountId = testAcct.Id;
        testCaseList[0].Routing_Destination__c = mc.Id;
        insert testCaseList;
    }


    public class TestContext
    {
        public List<Case> lstCase;
        public TestContext(){
            lstCase = [SELECT Id,Routing_Destination__c,Preferred_Vendor__c FROM Case];
        }
    }

    @isTest
	static void testPushSkillRequirements() {
        List <CDdAttributeBasedRouting.MissionCallInput> lstAttributeBasedRouting = new List<CDdAttributeBasedRouting.MissionCallInput>();
        Set<Id> caseId = new Set<Id>();
        for(Case c: new TestContext().lstCase){
            CDdAttributeBasedRouting.MissionCallInput objAttributeBasedRouting = new CDdAttributeBasedRouting.MissionCallInput();
            objAttributeBasedRouting.caseRec = c;
            lstAttributeBasedRouting.add(objAttributeBasedRouting);
        }
        Test.startTest();
        try{
            CDdAttributeBasedRouting.pushSkillRequirements(lstAttributeBasedRouting);
            List<PendingServiceRouting> lstPSR = [Select Id FROM PendingServiceRouting WHERE WorkItemId IN: caseId];
            System.assertEquals(caseId.size(),lstPSR.size(),'PSR record should get created');
        }catch(Exception e){
            System.assert(false);
        }
        Test.stopTest();
    }
}