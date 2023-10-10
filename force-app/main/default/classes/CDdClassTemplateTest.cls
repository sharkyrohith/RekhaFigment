/**
 * CDdClassTemplateTest
 *
 * @author     Sahil
 * @date  2020-03-29
 * @decription Test class for CDdClassTemplate
 */
@isTest
public with sharing class CDdClassTemplateTest {
    /**
   * @author     Sahil
   * @date  2020-03-29
   * @decription setup test data
   * @param   None 
   * @return  None
   */
    @TestSetup
    static void makeData(){
        //create test setup data here
    }

   /**
   * @author     Sahil
   * @date  2020-03-29
   * @decription method to test 
   * @param   None 
   * @return  None
   */
    @isTest
    static void testCallAllMethods() {
        CDdClassTemplate templateConst = new CDdClassTemplate();
        CDdClassTemplate.sampleMethod('Test String');
        //assert statement with message is required. eg:
        //System.assertEquals(expected , actual, 'add a message about what was expected')
        //System.assertNotEquals(1, 2, 'Expecting 1 but got a diff value')
    }
}