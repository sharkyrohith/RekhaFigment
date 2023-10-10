/**
 * @author Mahesh Chouhan
 * @date Nov 2022
 * @description Test class for controller of lwcDdQuickLinkPanel Lightning Web Component
 */

@isTest
public class CDdQuickLinkPanelControllerTest {

    /**
     * @description Test method for getQuickLinkConfiguration method
     */
    static testMethod void testGetQuickLinkConfiguration(){
        Id accountId = Fake.generateId(Account.SObjectType);
        Account accountRecord = (Account) new Fake(Account.class)
            .setField(Account.Id, accountId)
            .setField(Account.Restaurant_ID__c, '12345')
            .setField(Account.Business_ID_text__c, '67891')
            .toSObject();
        
        Id contactId = Fake.generateId(Contact.SObjectType);
        Contact contactRecord = (Contact) new Fake(Contact.class)
            .setField(Contact.Id, contactId)
            .setField(Account.CustomerNo__pc, '1234')
            .setField(Account.DasherNo__pc, '5678')
            .toSObject();
        
        Id caseId = Fake.generateId(Case.SObjectType);
        Case caseRecord = (Case) new Fake(Case.class)
            .setField(Case.Id, caseId)
            .setField(Case.AccountId, accountId)
            .setField(Case.ContactId, contactId)
            .setField(Case.DeliveryUUID__c, '8c3e7902-6e4e-4abe-8ad4-bf5cbc8c293d')
            .toSObject();
        
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ICasesSelector casesSelectorMock = (ICasesSelector) mocks.mock(
            ICasesSelector.class
        );

        mocks.startStubbing();
        mocks.when(casesSelectorMock.sObjectType()).thenReturn(Case.SObjectType);
        mocks.when(casesSelectorMock.selectById(new Set<Id>{caseId}, new Set<String>{'Account.Restaurant_ID__c', 'Account.Business_ID_text__c',
            'Contact.CustomerNo__c', 'Contact.DasherNo__c', 'DeliveryUUID__c'})).thenReturn(new List<Case>{caseRecord});
        mocks.stopStubbing();
        
        Application.Selector.setMock(casesSelectorMock);

        List<CDdQuickLinkPanelController.QuickLink> quickLinkConfigList = CDdQuickLinkPanelController.getQuickLinkConfiguration('Case', caseId);
        System.assert(quickLinkConfigList.size() > 0, 'No Quick Link Configs found');
    }
}