/**
 * @author Raju Lakshman
 * @date October 2020
 * @description Test class for the lwcDdGridReport component and framework. Note that this class is purely to makes sure code coverage exists.
 *              Project specific grid report helper classes (example CDdMxpUserReportHelper) should have its own test classes (example CDdMxpUserReportHelperTest)
 *              which takes care of ensuring that the query formed by the CDdGridReportHelper class is accurate and error free.
 */

 @isTest
public without sharing class CDdGridReportTest {

    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';

    /** 
     * @description Prepare and return the test running user
     */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, null)[0]; 
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }

    @isTest
    public static void increaseCodeCoverage_MultiSelectPicklist_OperatorIN() {
        increaseCodeCoverage_MultiSelectPicklist_helper('IN');
    }

    @isTest
    public static void increaseCodeCoverage_MultiSelectPicklist_OperatorLIKE() {
        increaseCodeCoverage_MultiSelectPicklist_helper('LIKE');
    }

    private static void increaseCodeCoverage_MultiSelectPicklist_helper(String operator) {
        List<CDdMultiSelectPicklistWrapper> wrapperList = new List<CDdMultiSelectPicklistWrapper>();
        wrapperList.add(getMultiSelectWrapper('a', 'Equals'));
        wrapperList.add(getMultiSelectWrapper('b', 'Equals'));
        wrapperList.add(getMultiSelectWrapper('c', 'Equals'));
        wrapperList.add(getMultiSelectWrapper('d', 'Does Not Equal'));
        wrapperList.add(getMultiSelectWrapper('e', 'Does Not Equal'));
        wrapperList.add(getMultiSelectWrapper('f', 'Does Not Equal'));
        wrapperList.add(getMultiSelectWrapper('', 'Is Blank'));
        wrapperList.add(getMultiSelectWrapper('', 'Is Not Blank'));

        CDdGridReportHelper.getMultiSelectPicklistQuery('abc__c',wrapperList,operator);
    }

    @isTest
    public static void increaseCodeCoverage_NumberFilter() {
        List<CDdNumberFilterWrapper> wrapperList = new List<CDdNumberFilterWrapper>();
        wrapperList.add(getNumberFilterWrapper(1,'='));
        wrapperList.add(getNumberFilterWrapper(2,'='));
        wrapperList.add(getNumberFilterWrapper(3,'>='));
        wrapperList.add(getNumberFilterWrapper(4,'<='));
        wrapperList.add(getNumberFilterWrapper(5,'<'));
        wrapperList.add(getNumberFilterWrapper(6,'>'));
        wrapperList.add(getNumberFilterWrapper(null,'IS BLANK'));
        wrapperList.add(getNumberFilterWrapper(null,'IS NOT BLANK'));
        wrapperList.add(getNumberFilterWrapper(10,20));

        CDdGridReportHelper.getNumberFilterQuery('abc__c',wrapperList);
    }

    @isTest
    public static void increaseCodeCoverage_DateFilter() {
        List<CDdDateFilterWrapper> wrapperList = new List<CDdDateFilterWrapper>();
        Datetime dt = System.now();

        wrapperList.add(getDateFilterWrapper(dt,'='));
        wrapperList.add(getDateFilterWrapper(dt.addDays(-1),'='));
        wrapperList.add(getDateFilterWrapper(dt.addDays(-2),'>='));
        wrapperList.add(getDateFilterWrapper(dt.addDays(-20),'<='));
        wrapperList.add(getDateFilterWrapper(dt.addDays(-2),'<'));
        wrapperList.add(getDateFilterWrapper(dt.addDays(-20),'>'));
        wrapperList.add(getDateFilterWrapper(null,'IS BLANK'));
        wrapperList.add(getDateFilterWrapper(null,'IS NOT BLANK'));
        wrapperList.add(getDateFilterWrapper(dt.addDays(-10),dt.addDays(-5)));

        CDdGridReportHelper.getDateFilterQuery('Datetime','abc__c',wrapperList);
    }

    @isTest
    public static void increaseCodeCoverage_ToggleFilter() {
        CDdGridReportHelper.getToggleQuery('abc__c', true);
    }

    @isTest
    public static void increaseCodeCoverage_Controller() {
        try {
            CDdGridReportCtrl.getRecordIds('ThisDoesNotExist', '[]', null);
            System.assert(false,'Should not come here');
        } catch (AuraHandledException ex) {
            System.assert(true,'Should come here');
        }

        try {
            CDdGridReportCtrl.getData('ThisDoesNotExist', new List<Id>());
            System.assert(false,'Should not come here');
        } catch (AuraHandledException ex) {
            System.assert(true,'Should come here');
        }
    }

    private static CDdMultiSelectPicklistWrapper getMultiSelectWrapper(String value,String operator) {
        CDdMultiSelectPicklistWrapper wrapper = new CDdMultiSelectPicklistWrapper();
        wrapper.value = value;
        wrapper.pillLabel = value;
        wrapper.dropDownLabel = value;
        wrapper.operator = operator;
        return wrapper;
    }

    @isTest
    public static void testGetDDGridReportSavedSearchForCurrentUser() {
        System.runAs(getTestRunUser()){
            DD_Grid_Report_Saved_Search__c savedSearch = new DD_Grid_Report_Saved_Search__c();
            savedSearch.Report_Name__c = 'MXP_User_Report';
            savedSearch.Config__c = 'Test Config';
            savedSearch.Name = 'Test Save Search';
            insert savedSearch;

            List<DD_Grid_Report_Saved_Search__c> expectedSaveSearch = CDdGridReportCtrl.getDDGridReportSavedSearchForCurrentUser('MXP_User_Report');
            System.assertEquals(1, expectedSaveSearch.size(), 'Number of Save Search records are not same as expected.');
            System.assertEquals(expectedSaveSearch[0].Id, savedSearch.Id, 'Save Search record Id is not same as expected.');
        }
    }

    private static CDdNumberFilterWrapper getNumberFilterWrapper(Decimal value,String operator) {
        CDdNumberFilterWrapper wrapper = new CDdNumberFilterWrapper();
        wrapper.value = value;
        wrapper.operator = operator;
        return wrapper;
    }

    private static CDdNumberFilterWrapper getNumberFilterWrapper(Decimal minValue,Decimal maxValue) {
        CDdNumberFilterWrapper wrapper = new CDdNumberFilterWrapper();
        wrapper.minValue = minValue;
        wrapper.maxValue = maxValue;
        wrapper.operator = 'BETWEEN';
        return wrapper;
    }

    private static CDdDateFilterWrapper getDateFilterWrapper(Datetime value,String operator) {
        CDdDateFilterWrapper wrapper = new CDdDateFilterWrapper();
        wrapper.value = value;
        wrapper.operator = operator;
        return wrapper;
    }

    private static CDdDateFilterWrapper getDateFilterWrapper(Datetime minValue,Datetime maxValue) {
        CDdDateFilterWrapper wrapper = new CDdDateFilterWrapper();
        wrapper.minValue = minValue;
        wrapper.maxValue = maxValue;
        wrapper.operator = 'BETWEEN';
        return wrapper;
    }
}