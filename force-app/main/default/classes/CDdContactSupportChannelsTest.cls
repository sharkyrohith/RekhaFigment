/**
* @author Tia Xuan	
* @date 2019-08
*
* @description Test class for CDdContactSupportChannelsController
*/
@isTest
public class CDdContactSupportChannelsTest {

    /**
	* @description test getWaitTimes
	**/
	@isTest static void testgetWaitTimes() {

        Service_Statistics__c stat = new Service_Statistics__c();
        stat.Five9_Skill_Name__c = 'Dx';
        stat.Five9_Current_Longest_Queue_Time__c = 60000;
        stat.Five9_Type__c = 'ACDStatus';
        stat.RecordTypeId = Schema.SObjectType.Service_Statistics__c.getRecordTypeInfosByName().get('Five 9').getRecordTypeId();
        insert stat;

        stat = new Service_Statistics__c();
        stat.Live_Agent_Estimated_Wait_Time__c = 60000;
        stat.Live_Agent_Community__c = 'dasher';
        stat.Live_Agent_Language__c = 'en';
        stat.RecordTypeId = Schema.SObjectType.Service_Statistics__c.getRecordTypeInfosByName().get('Live Agent').getRecordTypeId();
        insert stat;

        Test.startTest();
        String res = CDdContactSupportChannelsController.getWaitTimes('en', 'dasher');
        System.assert(res != null);
        Test.stopTest();

    }

    /**
	* @description test getWaitTimes with no records
	**/
	@isTest static void testgetWaitTimesNoRecord() {

        Test.startTest();
        String res = CDdContactSupportChannelsController.getWaitTimes('en', 'dasher');
        System.assert(res != null);
        Test.stopTest();

    }
    
}