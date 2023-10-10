/**
 * @author Mahesh Chouhan
 * @date   Oct 2021
 * @decription Test class for CDdGridReportQuickViewPanelCtrl
 */
@isTest
public without sharing class CDdGridReportQuickViewPanelCtrlTest {

    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
     *****************************************************************************************************************************/
    private static final String ACCOUNT_OBJECT_NAME = 'Account';
    private static final String ACCOUNT_ICON_NAME = 'standard:account';
    private static final String DELIVERY_OBJECT_NAME = 'Delivery__c';
    private static final String DELIVERY_ICON_NAME = 'custom:custom13';

    /**
     * @author     Mahesh Chouhan
     * @date  Oct 2021
     * @decription test to check if sobject details for standard object
     * @param   None
     * @return  None
     */
    @isTest
    static void testgetSObjectDetailsPositive() {
        List<Account> testAccount = TDdAccountFactory.createAccounts('Test Account', 1);
        insert testAccount;

        Test.startTest();
        CDdGridReportQuickViewPanelCtrl.CDdGridReportQuickViewWrapper quickViewWrapper = CDdGridReportQuickViewPanelCtrl.getSObjectDetails(testAccount[0].Id, 'MXP_User_Report_Account_Quick_View');
        Test.stopTest();

        System.assertEquals(ACCOUNT_OBJECT_NAME, quickViewWrapper.objectName, 'The object name is not same as expected.');
        System.assertEquals(ACCOUNT_OBJECT_NAME, quickViewWrapper.objectLabel, 'The object label is not same as expected.');
        System.assert(quickViewWrapper.fields.size() > 0, 'The fields list is empty.');
    }

    /**
     * @author     Mahesh Chouhan
     * @date  Oct 2021
     * @decription test to check Exception message on providing invalid Field Set Name
     * @param   None
     * @return  None
     */
    @isTest
    static void testgetSObjectDetailsNegative() {
        List<Account> testAccount = TDdAccountFactory.createAccounts('Test Account', 1);
        insert testAccount;

        try {
            Test.startTest();
            CDdGridReportQuickViewPanelCtrl.CDdGridReportQuickViewWrapper quickViewWrapper = CDdGridReportQuickViewPanelCtrl.getSObjectDetails(testAccount[0].Id, 'InvalidFieldSetName');
            Test.stopTest();
        }
        catch(AuraException ex) {
            System.assertEquals(CDdGridReportQuickViewPanelCtrl.INVALID_FIELD_SET_NAME_ERROR, ex.getMessage(), 'Exception message is not same as expected.');
        }
    }
}