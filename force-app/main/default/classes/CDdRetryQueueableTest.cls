/**
 *
 * @author: Mahesh Chouhan
 * @date: 2022-09
 * @description BASD-36580 Test class for CDdRetryQueueable class
 *
 */
@isTest
public class CDdRetryQueueableTest {

    /**
     * @author Mahesh Chouhan
     * @date Sept 2022
     *
     * @description: Test method for insert of records with Errors
     */
    @isTest
    static void testInsert(){
        List<Case> cases = CDdTestDataFactory.createSObjectList('Case', 1, false);
        cases[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_DASHER;
        cases[0].Issue_Type__c = CDdSupportConstants.ISSUE_TYPE_PAY_MANAGEMENT_MX;
        cases[0].BusinessHours = null;

        Boolean exceptionFound;
        try{
            Test.startTest();
            System.enqueueJob(new CDdRetryQueueable(cases, 'INSERT', 'CDdRetryQueueableTest'));
            Test.stopTest();
        }
        catch(Exception ex){
            exceptionFound = true;
        }
        List<Case> expectedCases = [SELECT ID FROM Case];
        System.assert(exceptionFound, 'Exception is expected.');
        System.assertEquals(0, expectedCases.size(), 'Case is not created as expected.');
    }
    
    /**
     * @author Mahesh Chouhan
     * @date Sept 2022
     *
     * @description: Test method for update of records
     */
    @isTest
    static void testUpdate(){
        List<Case> cases = CDdTestDataFactory.createSObjectList('Case', 1, false);
        cases[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        cases[0].BusinessHours = null;
        insert cases;
        
        cases[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_DASHER;
        
        Test.startTest();
        System.enqueueJob(new CDdRetryQueueable(cases, 'UPDATE', 'CDdRetryQueueableTest'));
        Test.stopTest();

        List<Case> expectedCases = [SELECT ID, Customer_Type__c FROM Case];
        System.assertEquals(CDdSupportConstants.CUSTOMER_TYPE_DASHER, expectedCases[0].Customer_Type__c, 'Customer Type on Case is not same as expected.');
    }

    /**
     * @author Mahesh Chouhan
     * @date Sept 2022
     *
     * @description: Test method for Upsert of records
     */ 
    @isTest
    static void testUpsert(){
        List<Case> cases = CDdTestDataFactory.createSObjectList('Case', 1, false);
        cases[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        cases[0].BusinessHours = null;
        
        Test.startTest();
        System.enqueueJob(new CDdRetryQueueable(cases, 'UPSERT', 'CDdRetryQueueableTest'));
        Test.stopTest();

        List<Case> expectedCases = [SELECT ID, Customer_Type__c FROM Case];
        System.assertEquals(CDdSupportConstants.CUSTOMER_TYPE_MERCHANT, expectedCases[0].Customer_Type__c, 'Customer Type on Case is not same as expected.');
    }

    /**
     * @author Mahesh Chouhan
     * @date Sept 2022
     *
     * @description: Test method for Deletion of records
     */
    @isTest
    static void testDelete(){
        List<Case> cases = CDdTestDataFactory.createSObjectList('Case', 1, false);
        cases[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        cases[0].BusinessHours = null;
        insert cases;
        
        Test.startTest();
        System.enqueueJob(new CDdRetryQueueable(cases, 'DELETE', 'CDdRetryQueueableTest'));
        Test.stopTest();

        List<Case> expectedCases = [SELECT ID, Customer_Type__c FROM Case];
        System.assertEquals(0, expectedCases.size(), 'No cases should exists.');
    }
}