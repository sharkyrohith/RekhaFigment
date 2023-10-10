/**
* CDdCaseVendorSplitEventHelperTest
*
* @author      Sahil (sahil.chaudhry@doordash.com)
* @date        08/16/2021
* @decription  test class for CDdCaseVendorSplitEventHelper
*/
@isTest(seeAllData=false)
public with sharing class CDdCaseVendorSplitEventHelperTest {
     /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription test setup
   * @param   None
   * @return  None
   */
    @TestSetup
    static void makeData(){
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(5,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        insert casesToTest;
    }

    /**
    * @author     Sahil
    * @date  2021-03-30
    * @decription test setup
    * @param   None
    * @return  No
    */
    @isTest
    static void testPublishEvents() {
        List<Case> casesFromDB = [SELECT Id from Case];
        List<Id> caseIdList = new List<Id>();
        Set<Id> caseIdSet = new Set<Id>();
        for (Case caseVar : casesFromDB) {
            caseIdList.add(caseVar.Id);
            caseIdSet.add(caseVar.Id);
        }
        Test.startTest();
        CDdCaseVendorSplitEventHelper.OperationType oprType = CDdCaseVendorSplitEventHelper.OperationType.INCREMENT_VENDOR_CC;
        List<Case_Vendor_Split__e> eventList = CDdCaseVendorSplitEventHelper.createcvsEvents(
                                                    CDdCaseVendorSplitEventHelper.OperationType.INCREMENT_VENDOR_CC,caseIdSet,null);
        System.assertEquals(casesFromDB.size(), eventList.size(), 'No. of events should equal no. of records');
        CDdCaseVendorSplitEventHelper.publishEvents(eventList);
        Test.getEventBus().deliver();
        Test.stopTest();
    }
}