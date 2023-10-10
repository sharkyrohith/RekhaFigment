/**
 * CDdBatchTemplateTest
 *
 * @author     Sahil
 * @date  2020-03-29
 * @decription Test class for CDdBatchTemplate
 */
@isTest
public with sharing class CDdBatchTemplateTest {
  /**
   * @author     Sahil
   * @date  2020-03-29
   * @decription setup test data
   * @param   None
   * @return  None
   */
  @TestSetup
  static void makeData() {
    List<Case> casesToInsert = TDdCaseFactory.createCaseRecords(
      2,
      CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER
    );
    insert casesToInsert;
  }

  /**
   * @author     Sahil
   * @date  2020-03-29
   * @decription test specific records in the batch
   * @param   None
   * @return  None
   */
  @isTest
  static void testBatch() {
    Test.startTest();
    Set<Id> caseIdSetTest = new Set<Id>();
    List<Case> caseList = TDdCaseFactory.createCaseRecords(
      2,
      CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER
    );
    insert caseList;
    for (Case caseVar : caseList) {
      caseIdSetTest.add(caseVar.Id);
    }
    //run on set of records
    Database.executeBatch(new CDdBatchTemplate(caseIdSetTest));
    Test.stopTest();
    //verify by asserting
    List<Case> caseListFromDB = [SELECT Id FROM Case WHERE Id IN :caseList];
    System.assertEquals(
      2,
      caseListFromDB.size(),
      'there should be 2 records inserted'
    );
    //other ways to assert:
    //System.assertNotEquals(expected, actual, msg);
  }

  /**
   * @author     Sahil
   * @date  2020-03-29
   * @decription test all records in the batch
   * @param   None
   * @return  None
   */
  @isTest
  static void testBatchAllRecords() {
    Test.startTest();
    //run on all records
    Database.executeBatch(new CDdBatchTemplate());
    Test.stopTest();
    //assert
    //System.assertEquals(expected, actual, msg);
  }

  /**
   * @author     Sahil
   * @date  2020-03-29
   * @decription test schedulable method
   * @param   None
   * @return  None
   */
  @isTest
  static void testSchedulable() {
    Test.startTest();
    CDdBatchTemplate batchTemplate = new CDdBatchTemplate();
    String timeScheduleString = '0 20 * * * ?'; // Apex Scheduler will run 20 minutes past every hour
    String schedulerJobID = System.schedule(
      'Scheduler Name String',
      timeScheduleString,
      batchTemplate
    );
    Test.stopTest();
    //verify by asserting
    List<Case> caseList = [SELECT Id FROM Case];
    System.assertEquals(
      2,
      caseList.size(),
      'there should be 2 records inserted'
    );
    //other ways to assert:
    //System.assertNotEquals(expected, actual, msg);
  }
}