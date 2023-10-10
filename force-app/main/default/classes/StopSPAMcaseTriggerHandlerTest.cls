/**
 * @author      Schubert Tonarelli
 * @date        2023-06-13
 * @decription Test class for StopSPAMcaseTriggerHandler
 */
@isTest(seeAllData=false)
public class StopSPAMcaseTriggerHandlerTest {
    
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
     * @date        2023-06-20
     * @jira        https://doordash.atlassian.net/browse/BASD-49578
     * @description Method for testing refresh cache StopSpamCaseReference
    */ 
    @isTest
    static void StopSPAMcaseTriggerHandlerTest1() {
        List<Stop_Spam_Case_Reference__c> referenceList = CdStopSpamCaseReferenceService.getCachedStopSpamCaseReference();
        Integer initialSize = referenceList.size();
        insert new Stop_Spam_Case_Reference__c(
            Value__c = '@montevideo.com',// Contains
            Operator__c = 'contains',    // Operator
            Field__c = 'SuppliedEmail'  // Field
        );
		Test.startTest();
        StopSPAMcaseTriggerHandler handler = new StopSPAMcaseTriggerHandler();
        handler.afterInsert();
        handler.afterUpdate();
        handler.afterDelete();
        handler.afterUndelete();
        Test.stopTest();
        
        referenceList = CdStopSpamCaseReferenceService.getCachedStopSpamCaseReference();
        
        System.assert( referenceList.size() > initialSize );
    }
}