/**
 * CdStopSpamCaseReferenceServiceTest
 *
 * @author      Schubert Tonarelli
 * @date        2023-06-13
 * @decription Test class for Stop Spam Case Reference Service
 */
@isTest(seeAllData=false)
public with sharing class CdStopSpamCaseReferenceServiceTest {
    
    @testSetup
    static void setup() {
        
        List<Stop_Spam_Case_Reference__c> newList = new List<Stop_Spam_Case_Reference__c>();
        
        newList.add( new Stop_Spam_Case_Reference__c(
            Value__c = 'chat',           // Contains
            Operator__c = 'contains',         // Operator
            Field__c = 'Description'  // Field
        ) );   
        
        newList.add( new Stop_Spam_Case_Reference__c(
            Value__c = '@hotmail.com',// Contains
            Operator__c = 'contains',      // Operator
            Field__c = 'SuppliedEmail'    // Field
        ) );   
        
        newList.add( new Stop_Spam_Case_Reference__c(
            Value__c = '@gmail.com',// Contains
            Operator__c = 'contains',    // Operator
            Field__c = 'SuppliedEmail'  // Field
        ) ); 
        
        insert newList;
    }
    
    /**
     * @author      Schubert Tonarelli
     * @date        2023-06-13
     * @jira        https://doordash.atlassian.net/browse/BASD-49578
     * @description Method for testing get from cache StopSpamCaseReference
    */ 
    @isTest
    static void CdStopSpamCaseReferenceServiceTest() {
		Test.startTest();
        List<Stop_Spam_Case_Reference__c> referenceList = CdStopSpamCaseReferenceService.getCachedStopSpamCaseReference();
        //run 2nd time to retrieve from cache
        referenceList = CdStopSpamCaseReferenceService.getCachedStopSpamCaseReference();
        Test.stopTest();
        System.assert( referenceList.size() == 3 );
    }    
    /**
     * @author      Schubert Tonarelli
     * @date        2023-06-20
     * @jira        https://doordash.atlassian.net/browse/BASD-49578
     * @description Method for testing refresh cache StopSpamCaseReference
    */ 
    @isTest
    static void CdStopSpamCaseReferenceServiceRefreshTest() {
        List<Stop_Spam_Case_Reference__c> referenceList = CdStopSpamCaseReferenceService.getCachedStopSpamCaseReference();
        Integer initialSize = referenceList.size();
        insert new Stop_Spam_Case_Reference__c(
            Value__c = '@montevideo.com',// Contains
            Operator__c = 'contains',    // Operator
            Field__c = 'SuppliedEmail'  // Field
        );
		Test.startTest();
        CdStopSpamCaseReferenceService.refreshStopSpamCaseReferenceCache(); // refresh
        referenceList = CdStopSpamCaseReferenceService.getCachedStopSpamCaseReference();
        Test.stopTest();
        
        System.assert( referenceList.size() > initialSize );
    }
}