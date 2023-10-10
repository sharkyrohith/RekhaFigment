@isTest
public class VFeedItemTriggerHandlerTest {
	
    public static testMethod void doInsert(){
        insert VTestUtil.createVeltigSettings();

        Id supportRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case testCase = new Case(RecordTypeId=supportRecTypeId,
                                 Subject='Test Case',
                                 Status='New',
                                 Origin='Web',
                                 Customer_Type__c='Consumer');
        insert testCase;
        
        FeedItem testFI = new FeedItem(ParentId=testCase.Id,
                                      Type='TextPost', Body='Test');
        insert testFI;
    }
}