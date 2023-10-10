/**
 * @author Jegar
 * @date 08/2002
 * @description Test class for CDdCaseRedirectToDispatchController
 * 
 */

 @isTest 
public class CDdCaseRedirectToDispatchControllerTest {

    @TestSetup
    static void makeData(){
        Account acc = VTestUtil.createPersonAccount('Test', 'Test');
		acc.CustomerNo__pc = Integer.valueof((Math.random() * 10000));
        insert acc; 

        Account acc2 = VTestUtil.createPersonAccount('Test', 'Test');
		acc2.CustomerNo__pc = Integer.valueof((Math.random() * 10000));
        insert acc2; 


        Case caseWithDeliveryId = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        caseWithDeliveryId.AccountId = acc.id;
        caseWithDeliveryId.Customer_Type__c = 'Consumer';
        caseWithDeliveryId.Origin = 'Chat';
        caseWithDeliveryId.Chat_Issue__c = 'Cancel Order';
        caseWithDeliveryId.DeliveryNo__c = Integer.valueof((Math.random() * 10000));

        insert caseWithDeliveryId; 

        Case caseWithOutDeliveryId = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        caseWithOutDeliveryId.AccountId = acc2.id;
        caseWithOutDeliveryId.Customer_Type__c = 'Consumer';
        caseWithOutDeliveryId.Origin = 'Chat';
        caseWithOutDeliveryId.Chat_Issue__c = 'Never Delivered Order';

        insert caseWithOutDeliveryId; 
        
    }

    /**
     * Test method to test when the case has a delivery Id.
     */
    public static testMethod void testCaseWithDeliveryID() {

        List<Case> caseList = [SELECT Id, Pre_Chat_Category__c, Pre_chat_Sub_Category__c, DeliveryNo__c, RecordTypeId, Account.CustomerNo__pc,
                                    Issue__c, Issue_Type__c, Customer_Type__c, DeliveryUUID__c
                                FROM Case 
                                WHERE Origin = 'Chat' 
                                    AND Chat_Issue__c = 'Cancel Order' ];
        Case currentCase; 
        System.debug(' ><><> ' + caseList.Size()); 
        currentCase = caseList[0];
        Test.startTest(); 
        Test.setCurrentPageReference(new PageReference('Page.PDdCaseRedirectToDispatch')); 
        System.currentPageReference().getParameters().put('Id',currentCase.Id); 
        ApexPages.StandardController sc = new ApexPages.standardController(currentCase);
        CDdCaseRedirectToDispatchController controller = new CDdCaseRedirectToDispatchController(sc);
        PageReference returnedPageRef = controller.redirectPage(); 
        System.Assert(returnedPageRef.getUrl().contains('consumer_cancellation_v2'));
    
        Test.stopTest();         
    }
    
    /**
     * Test method to test when the case has a delivery Id.
     */
    
     public static testMethod void testCaseWithOutDeliveryID() {

        List<Case> caseList = [SELECT Id, Pre_Chat_Category__c, Pre_chat_Sub_Category__c, DeliveryNo__c, RecordTypeId, Account.CustomerNo__pc,
                                    Issue__c, Issue_Type__c, Customer_Type__c, DeliveryUUID__c
                                FROM Case 
                                WHERE Origin = 'Chat' 
                                    AND Chat_Issue__c = 'Never Delivered Order' ];
        Case currentCase; 
        System.debug(' ><><> ' + caseList.Size()); 
        currentCase = caseList[0];
        Test.startTest(); 
        Test.setCurrentPageReference(new PageReference('Page.PDdCaseRedirectToDispatch')); 
        System.currentPageReference().getParameters().put('Id',currentCase.Id); 
        ApexPages.StandardController sc = new ApexPages.standardController(currentCase);
        CDdCaseRedirectToDispatchController controller = new CDdCaseRedirectToDispatchController(sc);
        PageReference returnedPageRef = controller.redirectPage(); 
        System.debug(returnedPageRef.getUrl()); 
        System.Assert(!returnedPageRef.getUrl().contains('delivery'));
    
        Test.stopTest(); 
    }
}