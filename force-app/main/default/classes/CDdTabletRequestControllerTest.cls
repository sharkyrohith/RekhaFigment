/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 6/13/2020.
 *
 * Implements: BZAP-6766 Tablet Request Case Grid
 *
 * Display related tablet cases in a grid that can be used by Classic and Lightning
 */
@IsTest
public class CDdTabletRequestControllerTest {
    public static void setup() {
        
        List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();
        Account accountRec = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.parentAccountId());
        accountRec.name = 'Test Business Vertical Account 001';
        accountRec.Business_Vertical__c = bvList[0].Id;
        insert accountRec;

        Contact contact = TDdAccountFactory.createContacts(1, accountRec.Id)[0];
        insert contact;
        
        Opportunity opp = TDdOpportunityFactory.createOpportunity('Test', accountRec.Id, contact.Id, 'Closed Won');
        opp.Shopping_Protocol__c = 'Mx Pick';
        insert opp;

        List<Case> cases = TDdCaseFactory.createCases(2, accountRec.Id, opp.Id, CDdSchemaUtils.CASE_RT.tabletRequestsId());
        for (Case cas : cases) {
            cas.Tablet_Shipment_Status__c = 'Shipped';
            cas.Request_Type__c = 'Ship to Merchant (New Tablet)';
            cas.Tablet_Ship_Date2__c = System.today().addDays(-1);
            cas.Tablet_Received_Date_2__c = System.today();
            cas.Tablet_Tracking_UPS__c = '123456789';
            cas.Tablet_Serial_Number__c = '123456789';
            cas.Return_Shipping_Address_State__c = 'Florida';
        }

        cases.addAll(TDdCaseFactory.createCases(1, accountRec.Id, opp.Id, CDdSchemaUtils.CASE_RT.caviarOnboardingId()));
        TDdCaseFactory.createCaseRecords(1, 'Tablet Requests');

        insert cases;
    }

    @IsTest
    public static void testController() {
        setup();

        Case cas = [select Id from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.caviarOnboardingId()];

        Test.startTest();
        List<CDdTabletRequestController.CaseObject> cases = CDdTabletRequestController.getCases(cas.Id);
        Test.stopTest();

        System.assertEquals(2, cases.size(), 'Unexpected number of Cases');
    }
}