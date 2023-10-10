/**
 * CDdProactiveInfoCaseCreationHelperTest
 *
 * @author     Nayana
 * @date  Sept 2022
 * @decription Test class for CDdProactiveInfoCaseCreationHelper
 */
@isTest
public class CDdProactiveInfoCaseCreationHelperTest {
    static List<String> lstExcludedMerchants = CDdNameValuePairHelper.getLongTextValue(CDdNameValuePairConstants.ITEM_UNAVAILABLE_EXCLUDED_MERCHANTIDS).split(CDdCoreConstants.DELIMITER_SEMICOLON);

    @testSetup static void testSetup() {
        List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 1, 'Marketplace');
        insert accs;
        Integer excludedMNo = 0;
        if(!lstExcludedMerchants.isEmpty()){
            excludedMNo = Integer.valueOf(lstExcludedMerchants[0]);
        }
        List<Delivery__c> lstDelivery = new List<Delivery__c>();
        lstDelivery.add(new Delivery__c(DeliveryUUID__c ='12344556',Merchant__c = accs[0].Id));
        lstDelivery.add(new Delivery__c(DeliveryUUID__c ='45678',Merchant__c = accs[0].Id,MerchantNo__c = excludedMNo));
        insert lstDelivery;
    }

    private static List<Case> setupCase(Boolean shouldInsert) {
        List<Case> cases = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case newCase = cases[0];
        newCase.Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
        newCase.Priority = 'High';
        newCase.Status = CDdSupportConstants.OPEN_STATUS;
        newCase.Routing_Reason__c = 'This is a test record';

        if (shouldInsert) {
            insert newCase;
        } else {
            newCase.Id = '500000000000000';
        }
        return cases;
    }

    private static CDdProactiveCaseCreationHelper.ProactiveCaseInfo setupWrapperData(Boolean createProactiveInfo ,String fldToCopy,String dUUID ) {
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo wrapProactiveCaseInfo = new CDdProactiveCaseCreationHelper.ProactiveCaseInfo();
        wrapProactiveCaseInfo.isProactiveCaseFlow = true;
        wrapProactiveCaseInfo.caseType = 'Item Unavailable';
        wrapProactiveCaseInfo.caseRecordType = 'Proactive_Outreach';
        wrapProactiveCaseInfo.customerType = 'Merchant';
        wrapProactiveCaseInfo.caseOrigin = 'API';
        wrapProactiveCaseInfo.evaluationCriteria = 'Updated';
        wrapProactiveCaseInfo.isProactiveCaseInfoCreation = createProactiveInfo;
        wrapProactiveCaseInfo.fieldsToCopyFromOriginalCase = fldToCopy;
        wrapProactiveCaseInfo.deliveryUUID = dUUID;
        return wrapProactiveCaseInfo;
    }

    public class TestContext
    {
        public List<Account> lstAccount;
        public TestContext(){
            lstAccount = [SELECT Id FROM Account WHERE CreatedDate = Today];
        }
    }

    @isTest
    public static void testProactiveInfoCreationFromWrapper() {
        List<Case> lstCases = setupCase(false);
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo wrapProactiveCaseInfo = setupWrapperData (true,'','12344556');
        wrapProactiveCaseInfo.originalCase = lstCases[0];
        Test.startTest();
        List<Proactive_Case_Info__c> proactiveInfo =  CDdProactiveInfoCaseCreationHelper.handleItemUnavailable(wrapProactiveCaseInfo);
        Test.stopTest();
        system.assertEquals(true,proactiveInfo.size()>0,'This case is valid for Proactive Case creation');
    }

    @isTest
    public static void testProactiveCaseCreationFromWrapper() {
        List<Case> lstCases = setupCase(false);
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo wrapProactiveCaseInfo = setupWrapperData (true,'','12344556');
        wrapProactiveCaseInfo.originalCase = lstCases[0];
        TestContext context = new TestContext();
        Proactive_Case_Info__c proactiveInfo = new Proactive_Case_Info__c();
        proactiveInfo.Proactive_Case_Created__c = false;
        proactiveInfo.Merchant__c = context.lstAccount[0].Id;
        proactiveInfo.Case_Type__c = 'Item Unavailable';
        insert proactiveInfo;
        Test.startTest();
        List<Proactive_Case_Info__c> proactiveInfoReload =  CDdProactiveInfoCaseCreationHelper.handleItemUnavailable(wrapProactiveCaseInfo);
        Test.stopTest();
        system.assertEquals(true,proactiveInfoReload[0].Proactive_Case_Created__c,'The case has been created so checkbox should be true');
    }


    @isTest
    public static void testProactiveCaseCreationForExlude() {
        List<Case> lstCases = setupCase(false);
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo wrapProactiveCaseInfo = setupWrapperData (true,'','45678');
        wrapProactiveCaseInfo.originalCase = lstCases[0];
        Test.startTest();
        List<Proactive_Case_Info__c> proactiveInfo =  CDdProactiveInfoCaseCreationHelper.handleItemUnavailable(wrapProactiveCaseInfo);
        Test.stopTest();
        if(!lstExcludedMerchants.isEmpty()){
            system.assert(proactiveInfo ==null);
        }else{
            system.assertEquals(true,proactiveInfo.size()>0,'This case is valid for Proactive Case creation');
        }

    }
}