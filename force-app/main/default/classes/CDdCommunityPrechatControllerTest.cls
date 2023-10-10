/**
* @author Tia Xuan	
* @date 2020-01
*
* @description Test class for CDdCommunityPrechatController
*/
@isTest
public with sharing class CDdCommunityPrechatControllerTest {
     /**
	* @description test getWaitTimes
	**/
	@isTest static void testgetDependentPicklist() {
        Test.startTest();
        
        CDdCommunityPrechatController.initCommunityPrechat('Case', 'Customer_Type__c', 'Resolution_Type__c');

        Test.stopTest();
        
    }

}