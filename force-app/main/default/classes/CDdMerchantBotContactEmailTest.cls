// ===========================================================================
// Component: CDdMerchantBotContactEmailTest
// Author: Nayana Kapse
// Purpose: Test class for CDdMerchantBotContactEmail
// ===========================================================================
@isTest
public with sharing class CDdMerchantBotContactEmailTest {
    /**
     * @author      Nayana
     * @date        Jan 2022
     * @description Data setup method
     */
	@testSetup
    static void testSetup() {
        Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        testAcct.MerchantNo__c = 1234;
        insert testAcct;
        List <Contact> lstContact = new List<Contact>();
        Contact ctc = VTestUtil.createContact('Test Contact', 'Contact1', testAcct);
        ctc.Email = 'test@test.com';
        lstContact.add(ctc);
        Contact ctc2 = VTestUtil.createContact('Test Contact2', 'Contact2', testAcct);
        ctc2.Email = 'test1234@test.com';
        lstContact.add(ctc2);
        insert lstContact;

        testAcct.Decision_Maker__c = lstContact[0].Id;
        update testAcct;

        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        testCaseList[0].AccountId = testAcct.Id;
        testCaseList[0].ContactId = lstContact[1].Id;
        insert testCaseList;
    }


    @isTest
	static void testFetchOrderDetails() {
        CDdMerchantBotContactEmail.MerchantAccountIdInput objMerchantId = new CDdMerchantBotContactEmail.MerchantAccountIdInput();
        List <CDdMerchantBotContactEmail.MerchantAccountIdInput> lstMerchantInput = new List<CDdMerchantBotContactEmail.MerchantAccountIdInput>();
        objMerchantId.merchantId = 1234.0;
        lstMerchantInput.add(objMerchantId);
        Test.startTest();
        CDdMerchantBotContactEmail.fetchMerchantContacts(lstMerchantInput);
        Test.stopTest();
    }
}