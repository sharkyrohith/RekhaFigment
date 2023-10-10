/**
 * CDdDomainsControllerTest
 *
 * @author     Sahil
 * @date  2022-06-17
 * @decription Test class for CDdDomainsController
 */
@isTest(seeAllData=false)
public with sharing class CDdDomainsControllerTest {
    /**
    * @author     Sahil
    * @date  2022-06-17
    * @decription test getting visualforce origin
    * @param   None  
    * @return  None
    */
    @isTest
    static void testOrigin() {
        CDdDomainsController instance = new CDdDomainsController();
        String lexOrigin = instance.lexOrigin;
        System.assertNotEquals(null, lexOrigin,'lex origin should be returned');
        String vfOrigin = CDdDomainsController.getVisualforceOrigin();
        System.assertNotEquals(null, vfOrigin, 'Visualforce origin should be returned');
    }
}